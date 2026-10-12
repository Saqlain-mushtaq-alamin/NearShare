import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../domain/transfer_progress.dart';
import '../domain/transfer_request.dart';
import '../domain/transfer_session.dart';
import 'chunk_manager.dart';
import 'file_storage_service.dart';
import 'transfer_session_repository.dart';

class _ProgressState {
  final DateTime startedAt;
  DateTime lastEmit;
  int lastBytes;
  double speed;

  _ProgressState(this.startedAt, this.lastBytes)
      : lastEmit = startedAt,
        speed = 0;
}

/// Receiver side of the resumable transfer protocol.
///
/// Chunks arrive out of order via `POST /api/v1/transfer/chunk`, are staged on
/// disk by [ChunkManager] and tracked in a [TransferSessionRepository] so a
/// sender can query `GET /api/v1/transfer/resume/...` after a disconnect.
class TransferServer {
  final FileStorageService _storageService;
  final TransferSessionRepository _sessionRepository;
  late final ChunkManager _chunkManager;

  final StreamController<TransferRequest> _incomingRequestController =
      StreamController<TransferRequest>.broadcast();
  final StreamController<TransferProgress> _progressController =
      StreamController<TransferProgress>.broadcast();

  final Map<String, Completer<bool>> _pendingDecisions = {};
  final Map<String, TransferRequest> _activeTransfers = {};
  final Map<String, TransferProgress> _transferProgressMap = {};
  final Map<String, Set<String>> _receivedFilePaths = {};
  final Map<String, _ProgressState> _progressStates = {};
  final Set<String> _cancelledTransfers = {};
  final Set<String> _resumedTransfers = {};

  HttpServer? _server;
  int? _boundPort;

  TransferServer({
    FileStorageService? storageService,
    TransferSessionRepository? sessionRepository,
  })  : _storageService = storageService ?? FileStorageService(),
        _sessionRepository = sessionRepository ??
            InMemoryTransferSessionRepository() {
    _chunkManager = ChunkManager(
      repository: _sessionRepository,
      storageService: _storageService,
    );
  }

  Stream<TransferRequest> get onIncomingRequest =>
      _incomingRequestController.stream;
  Stream<TransferProgress> get onProgress => _progressController.stream;
  int? get boundPort => _boundPort;
  bool get isRunning => _server != null;
  TransferSessionRepository get sessionRepository => _sessionRepository;
  FileStorageService get storageService => _storageService;
  ChunkManager get chunkManager => _chunkManager;

  Handler get handler => _buildRouter().call;

  Router _buildRouter() {
    final router = Router();

    router.post('/api/v1/transfer/prepare', _handlePrepare);

    router.post(
      '/api/v1/transfer/chunk/<transferId>/<fileIndex>',
      _handleChunk,
    );

    router.post(
      '/api/v1/transfer/finalize/<transferId>/<fileIndex>',
      _handleFinalize,
    );

    router.get('/api/v1/transfer/resume/<transferId>', _handleResumeAll);
    router.get(
      '/api/v1/transfer/resume/<transferId>/<fileIndex>',
      _handleResume,
    );

    router.get('/api/v1/transfer/status/<transferId>', _handleStatus);

    router.post('/api/v1/transfer/cancel/<transferId>', _handleCancel);

    return router;
  }

  Future<int> start({int? port}) async {
    if (kIsWeb) {
      debugPrint('[TransferServer] HTTP server skipped on Web');
      _boundPort = port ?? 53317;
      return _boundPort!;
    }

    await stop();

    final preferredPort = port ?? 53317;
    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(handler);

    try {
      _server = await shelf_io.serve(
        pipeline,
        InternetAddress.anyIPv4,
        preferredPort,
      );
      _boundPort = _server!.port;
      debugPrint(
        '[TransferServer] Listening on http://${_server!.address.host}:$_boundPort',
      );
      return _boundPort!;
    } catch (e) {
      debugPrint(
        '[TransferServer] Port $preferredPort busy, binding to any free port (0)',
      );
      _server = await shelf_io.serve(pipeline, InternetAddress.anyIPv4, 0);
      _boundPort = _server!.port;
      debugPrint('[TransferServer] Listening on dynamic port: $_boundPort');
      return _boundPort!;
    }
  }

  Future<void> stop() async {
    for (final completer in _pendingDecisions.values) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }
    _pendingDecisions.clear();
    _activeTransfers.clear();
    _transferProgressMap.clear();
    _progressStates.clear();
    _resumedTransfers.clear();

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _boundPort = null;
  }

  void respondToRequest(String transferId, bool accept) {
    final completer = _pendingDecisions.remove(transferId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(accept);
    }
  }

  Future<Response> _handlePrepare(Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final transferRequest = TransferRequest.fromJson(data);

      final transferId = transferRequest.transferId;
      if (transferId.isEmpty) {
        return _jsonError(400, 'Missing transferId');
      }

      // A transfer we already accepted (possibly in a previous process) is
      // resumed silently so the sender never has to be prompted twice.
      final existing = await _sessionRepository.getSession(transferId);
      if (existing != null &&
          existing.direction == TransferDirection.receiving &&
          existing.status != TransferSessionStatus.failed &&
          existing.status != TransferSessionStatus.cancelled) {
        return _acceptResumed(transferId, transferRequest);
      }
      if (existing != null) {
        await _sessionRepository.deleteSession(transferId);
      }

      var completer = _pendingDecisions[transferId];
      if (completer == null) {
        completer = Completer<bool>();
        _pendingDecisions[transferId] = completer;
        _activeTransfers[transferId] = transferRequest;
        _progressStates[transferId] = _ProgressState(DateTime.now(), 0);
        _cancelledTransfers.remove(transferId);
        _resumedTransfers.remove(transferId);
        _receivedFilePaths[transferId] = {};

        await _sessionRepository.saveSession(
          TransferSession(
            transferId: transferId,
            peerId: transferRequest.senderId,
            peerName: transferRequest.senderName,
            direction: TransferDirection.receiving,
            status: TransferSessionStatus.pending,
            files: transferRequest.files,
            chunkSize: transferRequest.chunkSize,
            startedAt: DateTime.now(),
            lastActivityAt: DateTime.now(),
          ),
        );

        await _emitProgress(
          transfer: transferRequest,
          statusOverride: TransferStatus.pending,
          force: true,
        );

        _incomingRequestController.add(transferRequest);
      } else {
        // A retry of a prepare that is still waiting for the user decision.
        _activeTransfers[transferId] = transferRequest;
      }

      final accepted = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => false,
      );

      if (accepted) {
        await _saveSessionState(
          transferId,
          status: TransferSessionStatus.inProgress,
        );
        await _emitProgress(
          transfer: transferRequest,
          statusOverride: TransferStatus.accepted,
          force: true,
        );

        return Response.ok(
          jsonEncode({
            'status': 'accepted',
            'transferId': transferId,
          }),
          headers: _jsonHeaders,
        );
      } else {
        _activeTransfers.remove(transferId);
        _progressStates.remove(transferId);
        await _sessionRepository.deleteSession(transferId);
        await _emitProgress(
          transfer: transferRequest,
          statusOverride: TransferStatus.rejected,
          force: true,
        );

        return Response(
          403,
          body: jsonEncode({
            'status': 'rejected',
            'transferId': transferId,
          }),
          headers: _jsonHeaders,
        );
      }
    } catch (e, stack) {
      debugPrint('[TransferServer] Error handling prepare: $e\n$stack');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: _jsonHeaders,
      );
    }
  }

  Future<Response> _acceptResumed(
    String transferId,
    TransferRequest transferRequest,
  ) async {
    _activeTransfers[transferId] = transferRequest;
    _cancelledTransfers.remove(transferId);
    _resumedTransfers.add(transferId);
    _receivedFilePaths.putIfAbsent(transferId, () => {});
    _progressStates.putIfAbsent(
      transferId,
      () => _ProgressState(DateTime.now(), 0),
    );

    await _emitProgress(
      transfer: transferRequest,
      statusOverride: TransferStatus.accepted,
      phase: TransferPhase.resuming,
      force: true,
    );

    return Response.ok(
      jsonEncode({
        'status': 'accepted',
        'transferId': transferId,
        'resumed': true,
      }),
      headers: _jsonHeaders,
    );
  }

  Future<Response> _handleChunk(
    Request request,
    String transferId,
    String fileIndexStr,
  ) async {
    final transfer = await _ensureActiveTransfer(transferId);
    if (transfer == null) {
      return _jsonError(404, 'Transfer $transferId not found');
    }
    if (_cancelledTransfers.contains(transferId)) {
      return _jsonError(409, 'Transfer was cancelled');
    }

    final fileIndex = int.tryParse(fileIndexStr) ?? -1;
    if (fileIndex < 0 || fileIndex >= transfer.files.length) {
      return _jsonError(400, 'Invalid file index $fileIndexStr');
    }

    final chunkIndex = int.tryParse(request.headers['x-chunk-index'] ?? '');
    if (chunkIndex == null) {
      return _jsonError(400, 'Missing X-Chunk-Index header');
    }

    final totalChunksHeader =
        int.tryParse(request.headers['x-total-chunks'] ?? '');
    final sessionBefore = await _sessionRepository.getSession(transferId);
    if (sessionBefore == null) {
      return _jsonError(404, 'Transfer $transferId not found');
    }
    final expectedTotal = sessionBefore.totalChunksForFile(fileIndex);
    if (totalChunksHeader != null && totalChunksHeader != expectedTotal) {
      return _jsonError(
        400,
        'Chunk size mismatch: sender expects $totalChunksHeader chunks, '
        'receiver expects $expectedTotal',
      );
    }

    final rangeError = _validateContentRange(
      request.headers['content-range'],
      sessionBefore,
      fileIndex,
      chunkIndex,
    );
    if (rangeError != null) {
      return _jsonError(400, rangeError);
    }

    final bytes = await _readBody(request);
    final declaredSize = int.tryParse(request.headers['x-chunk-size'] ?? '');
    if (declaredSize != null && declaredSize != bytes.length) {
      return _jsonError(
        400,
        'X-Chunk-Size declares $declaredSize bytes but body has ${bytes.length}',
      );
    }

    try {
      await _chunkManager.writeChunk(
        transferId: transferId,
        fileIndex: fileIndex,
        chunkIndex: chunkIndex,
        bytes: bytes,
      );
    } on StateError catch (e) {
      return _jsonError(404, e.message);
    } on RangeError catch (e) {
      return _jsonError(400, e.message ?? 'Chunk index out of range');
    } on ArgumentError catch (e) {
      return _jsonError(400, e.message.toString());
    }

    final session = await _sessionRepository.getSession(transferId);
    if (session == null) {
      return _jsonError(404, 'Transfer $transferId not found');
    }

    final received = session.receivedChunksForFile(fileIndex);
    final missing = session.missingChunksForFile(fileIndex);
    final total = session.totalChunksForFile(fileIndex);

    await _emitProgress(
      transfer: transfer,
      fileIndex: fileIndex,
      currentChunk: chunkIndex,
      totalChunks: total,
    );

    return Response.ok(
      jsonEncode({
        'status': 'received',
        'transferId': transferId,
        'fileIndex': fileIndex,
        'chunkIndex': chunkIndex,
        'receivedChunks': received,
        'missingChunks': missing,
        'totalChunksExpected': total,
        'fileComplete': missing.isEmpty,
      }),
      headers: _jsonHeaders,
    );
  }

  Future<Response> _handleFinalize(
    Request request,
    String transferId,
    String fileIndexStr,
  ) async {
    final transfer = await _ensureActiveTransfer(transferId);
    if (transfer == null) {
      return _jsonError(404, 'Transfer $transferId not found');
    }
    if (_cancelledTransfers.contains(transferId)) {
      return _jsonError(409, 'Transfer was cancelled');
    }

    final fileIndex = int.tryParse(fileIndexStr) ?? -1;
    if (fileIndex < 0 || fileIndex >= transfer.files.length) {
      return _jsonError(400, 'Invalid file index $fileIndexStr');
    }

    final complete = await _chunkManager.isFileComplete(transferId, fileIndex);
    if (!complete) {
      final missing =
          await _chunkManager.getMissingChunks(transferId, fileIndex);
      return Response(
        409,
        body: jsonEncode({
          'status': 'incomplete',
          'transferId': transferId,
          'fileIndex': fileIndex,
          'missingChunks': missing,
        }),
        headers: _jsonHeaders,
      );
    }

    String savePath;
    try {
      final assembled = await _chunkManager.assembleFile(transferId, fileIndex);
      savePath = assembled.path;
    } on StateError catch (e) {
      return Response(
        409,
        body: jsonEncode({
          'status': 'incomplete',
          'transferId': transferId,
          'fileIndex': fileIndex,
          'error': e.message,
        }),
        headers: _jsonHeaders,
      );
    }

    final session = await _sessionRepository.getSession(transferId);
    final isLastFile = session != null &&
        session.fileSavePaths.length >= session.files.length;

    _receivedFilePaths.putIfAbsent(transferId, () => {}).add(savePath);

    await _emitProgress(
      transfer: transfer,
      fileIndex: fileIndex,
      statusOverride:
          isLastFile ? TransferStatus.completed : TransferStatus.inProgress,
      force: true,
    );

    return Response.ok(
      jsonEncode({
        'status': 'completed',
        'transferId': transferId,
        'fileIndex': fileIndex,
        'savePath': savePath,
        'isLastFile': isLastFile,
      }),
      headers: _jsonHeaders,
    );
  }

  Future<Response> _handleResume(
    Request request,
    String transferId,
    String fileIndexStr,
  ) async {
    final session = await _sessionRepository.getSession(transferId);
    if (session == null || session.direction != TransferDirection.receiving) {
      return Response.ok(
        jsonEncode({
          'transferId': transferId,
          'known': false,
          'receivedChunks': const <int>[],
          'totalChunksExpected': 0,
          'fileComplete': false,
          'savePath': null,
        }),
        headers: _jsonHeaders,
      );
    }

    final fileIndex = int.tryParse(fileIndexStr) ?? -1;
    if (fileIndex < 0 || fileIndex >= session.files.length) {
      return _jsonError(400, 'Invalid file index $fileIndexStr');
    }

    await _resetIfDestinationVanished(transferId, fileIndex);
    await _chunkManager.reconcileFile(transferId, fileIndex);

    final refreshed = await _sessionRepository.getSession(transferId);
    if (refreshed == null) {
      return _jsonError(404, 'Transfer $transferId not found');
    }

    final savePath = refreshed.fileSavePaths[fileIndex];
    return Response.ok(
      jsonEncode({
        'transferId': transferId,
        'fileIndex': fileIndex,
        'known': true,
        'receivedChunks': refreshed.receivedChunksForFile(fileIndex),
        'totalChunksExpected': refreshed.totalChunksForFile(fileIndex),
        'fileComplete': refreshed.fileSavePaths.containsKey(fileIndex),
        'savePath': savePath,
      }),
      headers: _jsonHeaders,
    );
  }

  Future<Response> _handleResumeAll(Request request, String transferId) async {
    final session = await _sessionRepository.getSession(transferId);
    if (session == null || session.direction != TransferDirection.receiving) {
      return Response.ok(
        jsonEncode({
          'transferId': transferId,
          'known': false,
          'files': const <dynamic>[],
          'allComplete': false,
        }),
        headers: _jsonHeaders,
      );
    }

    final files = <Map<String, dynamic>>[];
    var allComplete = true;
    for (var i = 0; i < session.files.length; i++) {
      await _resetIfDestinationVanished(transferId, i);
      await _chunkManager.reconcileFile(transferId, i);
      final refreshed = await _sessionRepository.getSession(transferId);
      if (refreshed == null) break;
      final complete = refreshed.fileSavePaths.containsKey(i);
      if (!complete) allComplete = false;
      files.add({
        'fileIndex': i,
        'receivedChunks': refreshed.receivedChunksForFile(i),
        'totalChunksExpected': refreshed.totalChunksForFile(i),
        'fileComplete': complete,
        'savePath': refreshed.fileSavePaths[i],
      });
    }

    return Response.ok(
      jsonEncode({
        'transferId': transferId,
        'known': true,
        'files': files,
        'allComplete': allComplete,
      }),
      headers: _jsonHeaders,
    );
  }

  Future<Response> _handleStatus(Request request, String transferId) async {
    final progress = _transferProgressMap[transferId];
    if (progress == null) {
      final session = await _sessionRepository.getSession(transferId);
      if (session == null) {
        return _jsonError(404, 'Transfer $transferId not found');
      }
      return Response.ok(
        jsonEncode({
          'transferId': transferId,
          'status': session.status.name,
          'bytesTransferred': session.receivedByteCount,
          'totalBytes': session.totalSizeBytes,
        }),
        headers: _jsonHeaders,
      );
    }
    return Response.ok(
      jsonEncode(progress.toJson()),
      headers: _jsonHeaders,
    );
  }

  Future<Response> _handleCancel(Request request, String transferId) async {
    _cancelledTransfers.add(transferId);
    respondToRequest(transferId, false);

    await _chunkManager.discardTransfer(transferId);
    await _sessionRepository.deleteSession(transferId);

    final paths = _receivedFilePaths.remove(transferId) ?? <String>{};
    for (final path in paths) {
      await _storageService.deleteIncompleteFile(path);
    }

    final current = _transferProgressMap[transferId];
    if (current != null) {
      final cancelled = current.copyWith(
        status: TransferStatus.cancelled,
        clearCurrentChunk: true,
        clearTotalChunks: true,
      );
      _transferProgressMap[transferId] = cancelled;
      _progressController.add(cancelled);
    }

    return Response.ok(
      jsonEncode({
        'status': 'cancelled',
        'transferId': transferId,
      }),
      headers: _jsonHeaders,
    );
  }

  Future<TransferRequest?> _ensureActiveTransfer(String transferId) async {
    final active = _activeTransfers[transferId];
    if (active != null) return active;

    final session = await _sessionRepository.getSession(transferId);
    if (session == null || session.direction != TransferDirection.receiving) {
      return null;
    }

    final request = TransferRequest(
      transferId: session.transferId,
      senderId: session.peerId,
      senderName: session.peerName,
      files: session.files,
      totalSizeBytes: session.totalSizeBytes,
      timestamp: session.startedAt,
      chunkSize: session.chunkSize,
    );
    _activeTransfers[transferId] = request;
    _progressStates.putIfAbsent(
      transferId,
      () => _ProgressState(DateTime.now(), session.receivedByteCount),
    );
    return request;
  }

  Future<void> _saveSessionState(
    String transferId, {
    TransferSessionStatus? status,
  }) async {
    final session = await _sessionRepository.getSession(transferId);
    if (session == null) return;
    await _sessionRepository.saveSession(
      session.copyWith(
        status: status,
        lastActivityAt: DateTime.now(),
        clearErrorMessage: status == TransferSessionStatus.inProgress,
      ),
    );
  }

  Future<void> _resetIfDestinationVanished(String transferId, int fileIndex) async {
    final session = await _sessionRepository.getSession(transferId);
    if (session == null) return;

    final savePath = session.fileSavePaths[fileIndex];
    if (savePath != null && !await File(savePath).exists()) {
      final paths = Map<int, String>.from(session.fileSavePaths)
        ..remove(fileIndex);
      final chunks = Map<int, List<int>>.from(session.receivedChunksPerFile)
        ..[fileIndex] = <int>[];
      await _sessionRepository.saveSession(
        session.copyWith(
          fileSavePaths: paths,
          receivedChunksPerFile: chunks,
          lastActivityAt: DateTime.now(),
        ),
      );
    }
  }

  String? _validateContentRange(
    String? header,
    TransferSession session,
    int fileIndex,
    int chunkIndex,
  ) {
    if (header == null || header.isEmpty) return null;
    final match = RegExp(r'^bytes\s+(\d+)-(\d+)/(\d+|\*)$').firstMatch(header);
    if (match == null) return 'Malformed Content-Range header: $header';

    final plan = chunkManager.chunkPlanFor(session, fileIndex);
    if (chunkIndex < 0 || chunkIndex >= plan.length) {
      return 'Chunk index $chunkIndex out of range';
    }

    final expected = plan[chunkIndex];
    final start = int.parse(match.group(1)!);
    final end = int.parse(match.group(2)!);
    final total = match.group(3);

    if (start != expected.startByte || end != expected.endByte) {
      return 'Content-Range $header does not match expected '
          '${expected.startByte}-${expected.endByte}';
    }
    if (total != '*' && int.tryParse(total!) != session.files[fileIndex].sizeInBytes) {
      return 'Content-Range total $total does not match file size '
          '${session.files[fileIndex].sizeInBytes}';
    }
    return null;
  }

  Future<List<int>> _readBody(Request request) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<TransferProgress> _emitProgress({
    required TransferRequest transfer,
    int? fileIndex,
    TransferStatus? statusOverride,
    TransferPhase phase = TransferPhase.normal,
    int? currentChunk,
    int? totalChunks,
    bool force = false,
  }) async {
    final transferId = transfer.transferId;
    final session = await _sessionRepository.getSession(transferId);
    final bytes = session?.receivedByteCount ?? 0;

    final now = DateTime.now();
    final state = _progressStates.putIfAbsent(
      transferId,
      () => _ProgressState(now, bytes),
    );

    final elapsedMs = now.difference(state.lastEmit).inMilliseconds;
    if (elapsedMs >= 150) {
      final deltaBytes = bytes - state.lastBytes;
      final deltaSeconds = elapsedMs / 1000.0;
      if (deltaSeconds > 0 && deltaBytes >= 0) {
        final instant = deltaBytes / deltaSeconds;
        state.speed = state.speed <= 0 ? instant : state.speed * 0.6 + instant * 0.4;
      }
      state.lastEmit = now;
      state.lastBytes = bytes;
    }

    if (!force &&
        elapsedMs < 150 &&
        _transferProgressMap[transferId] != null) {
      return _transferProgressMap[transferId]!;
    }

    var index = fileIndex ?? 0;
    if (fileIndex == null && session != null) {
      for (var i = 0; i < session.files.length; i++) {
        if (!session.isFileComplete(i)) {
          index = i;
          break;
        }
        index = i;
      }
    }

    final totalFiles = transfer.files.length;
    final safeIndex =
        totalFiles == 0 ? 0 : index.clamp(0, totalFiles - 1).toInt();
    final fileName =
        safeIndex < transfer.files.length ? transfer.files[safeIndex].name : null;

    final effectivePhase = phase;
    final allCaughtUp = session != null && session.areAllFilesComplete;
    final displayPhase = effectivePhase == TransferPhase.normal &&
            _resumedTransfers.contains(transferId) &&
            !allCaughtUp
        ? TransferPhase.resuming
        : effectivePhase;

    final progress = TransferProgress(
      transferId: transferId,
      currentFileIndex: safeIndex,
      totalFiles: totalFiles,
      bytesTransferred: bytes,
      totalBytes: transfer.totalSizeBytes,
      speedBps: state.speed,
      status: statusOverride ?? TransferStatus.inProgress,
      currentFileName: fileName,
      phase: displayPhase,
      currentChunk: currentChunk,
      totalChunks: totalChunks,
    );

    _transferProgressMap[transferId] = progress;
    _progressController.add(progress);
    return progress;
  }

  static const Map<String, String> _jsonHeaders = {
    'content-type': 'application/json',
  };

  Response _jsonError(int status, String message) {
    return Response(
      status,
      body: jsonEncode({'error': message}),
      headers: _jsonHeaders,
    );
  }

  Future<void> dispose() async {
    await stop();
    _receivedFilePaths.clear();
    _cancelledTransfers.clear();
    _resumedTransfers.clear();
    await _incomingRequestController.close();
    await _progressController.close();
  }
}

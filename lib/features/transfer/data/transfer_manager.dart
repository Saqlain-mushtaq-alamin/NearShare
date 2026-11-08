import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/security/content_security.dart';
import '../../history/data/history_repository.dart';
import '../../history/domain/transfer_record.dart';
import '../../discovery/domain/device.dart';
import '../domain/chunk_info.dart';
import '../domain/transfer_file.dart';
import '../domain/transfer_progress.dart';
import '../domain/transfer_request.dart';
import '../domain/transfer_session.dart';
import 'chunk_manager.dart';
import 'connection_monitor.dart';
import 'file_storage_service.dart';
import 'retry_policy.dart';
import 'transfer_client.dart';
import 'transfer_server.dart';
import 'transfer_session_repository.dart';

/// Raised when the user cancels an active transfer.
class TransferCancelledException implements Exception {
  const TransferCancelledException();

  @override
  String toString() => 'Transfer cancelled';
}

/// Raised when the peer stopped responding and the transfer should pause.
class TransferConnectionLostException implements Exception {
  const TransferConnectionLostException();

  @override
  String toString() => 'Connection lost';
}

class _SpeedTracker {
  DateTime lastEmit;
  int lastBytes;
  double speed;

  _SpeedTracker(this.lastBytes)
      : lastEmit = DateTime.now(),
        speed = 0;

  double update(int bytes) {
    final now = DateTime.now();
    final elapsedMs = now.difference(lastEmit).inMilliseconds;
    if (elapsedMs >= 200) {
      final instant = (bytes - lastBytes) / (elapsedMs / 1000.0);
      if (instant >= 0) {
        speed = speed <= 0 ? instant : speed * 0.6 + instant * 0.4;
      }
      lastEmit = now;
      lastBytes = bytes;
    }
    return speed;
  }
}

/// Coordinates the chunked transfer protocol across client, server,
/// repository and connection monitor.
class TransferManager {
  late final TransferServer _server;
  late final TransferClient _client;
  late final FileStorageService _storageService;
  late final TransferSessionRepository _sessionRepository;
  late final ChunkManager _chunkManager;
  late final ConnectionMonitor _connectionMonitor;
  late final HistoryRepository _historyRepository;

  final Uuid _uuid;
  final int maxParallelChunks;

  final StreamController<TransferProgress> _progressStreamController =
      StreamController<TransferProgress>.broadcast();

  final Map<String, CancelToken> _activeCancelTokens = {};
  final Map<String, Device> _activeSendingTargets = {};
  final Map<String, TransferRequest> _activeRequests = {};
  final Set<String> _runningTransfers = {};
  final Set<String> _connectionLostSignals = {};
  final Map<String, DateTime> _lastResumeAttempt = {};

  StreamSubscription<TransferProgress>? _serverProgressSub;
  StreamSubscription<ConnectionEvent>? _connectionSub;
  Timer? _maintenanceTimer;
  bool _disposed = false;

  TransferManager({
    TransferServer? server,
    TransferClient? client,
    FileStorageService? storageService,
    Uuid? uuid,
    TransferSessionRepository? sessionRepository,
    ChunkManager? chunkManager,
    ConnectionMonitor? connectionMonitor,
    HistoryRepository? historyRepository,
    this.maxParallelChunks = 4,
  }) : _uuid = uuid ?? const Uuid() {
    _storageService = storageService ??
        (server != null ? server.storageService : FileStorageService());
    _sessionRepository = sessionRepository ??
        server?.sessionRepository ??
        InMemoryTransferSessionRepository();
    _historyRepository = historyRepository ??
        server?.historyRepository ??
        InMemoryHistoryRepository();
    _server = server ??
        TransferServer(
          storageService: _storageService,
          sessionRepository: _sessionRepository,
          historyRepository: _historyRepository,
        );
    _client = client ?? TransferClient();
    _chunkManager = chunkManager ??
        ChunkManager(
          repository: _sessionRepository,
          storageService: _storageService,
        );
    _connectionMonitor = connectionMonitor ??
        ConnectionMonitor(
          probe: (target, transferId) async {
            final status = await _client.getTransferStatus(target, transferId);
            return status != null;
          },
        );

    _serverProgressSub = _server.onProgress.listen((progress) {
      if (!_disposed && !_progressStreamController.isClosed) {
        _progressStreamController.add(progress);
      }
    });
    _connectionSub = _connectionMonitor.onEvents.listen(_onConnectionEvent);
  }

  TransferServer get server => _server;
  TransferClient get client => _client;
  FileStorageService get storageService => _storageService;
  TransferSessionRepository get sessionRepository => _sessionRepository;
  ChunkManager get chunkManager => _chunkManager;
  ConnectionMonitor get connectionMonitor => _connectionMonitor;
  HistoryRepository get historyRepository => _historyRepository;

  Stream<TransferRequest> get onIncomingRequest => _server.onIncomingRequest;
  Stream<TransferProgress> get onProgress => _progressStreamController.stream;

  /// Loads persisted state so interrupted transfers can be resumed.
  ///
  /// Called once during app start-up.
  Future<void> initialize() async {
    await markInterruptedSessions();
    await cleanupStaleSessions();
  }

  /// Moves every `inProgress` session to `paused`.
  ///
  /// Sessions are written continuously, so a process that died mid-transfer
  /// leaves an `inProgress` row behind that no one is driving anymore.
  Future<void> markInterruptedSessions() async {
    final sessions = await _sessionRepository.getAllSessions();
    for (final session in sessions) {
      if (session.status == TransferSessionStatus.inProgress) {
        await _sessionRepository.saveSession(
          session.copyWith(status: TransferSessionStatus.paused),
        );
      }
    }
  }

  /// Starts a repeating stale-session sweep.
  void startPeriodicMaintenance({
    Duration interval = const Duration(hours: 1),
  }) {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(interval, (_) {
      unawaited(cleanupStaleSessions());
    });
  }

  /// Removes sessions idle for longer than [maxAge] together with their data.
  Future<List<TransferSession>> cleanupStaleSessions({
    Duration maxAge = const Duration(hours: 24),
    DateTime? now,
  }) async {
    final stale = await _sessionRepository.deleteStaleSessions(
      maxAge: maxAge,
      now: now,
    );
    for (final session in stale) {
      await _storageService.deleteTempDataFor(session.transferId);
    }
    return stale;
  }

  /// Sessions that still have work left, most recent first.
  Future<List<TransferSession>> getIncompleteSessions() {
    return _sessionRepository.getIncompleteSessions();
  }

  /// Starts the embedded receiver HTTP server.
  Future<int> startServer({int? port}) async {
    return _server.start(port: port);
  }

  /// Stops the receiver HTTP server.
  Future<void> stopServer() async {
    await _server.stop();
  }

  /// Sends a list of files to a remote target device.
  Future<TransferProgress> sendFiles({
    required Device target,
    required List<TransferFile> files,
    required Device localDevice,
    String? transferId,
  }) async {
    final id = transferId ?? _uuid.v4();
    final now = DateTime.now();

    final session = TransferSession(
      transferId: id,
      peerId: target.id,
      peerName: target.name,
      peerIp: target.ipAddress,
      peerPort: target.port,
      direction: TransferDirection.sending,
      status: TransferSessionStatus.pending,
      files: await _normalizeFiles(files),
      chunkSize: kDefaultChunkSize,
      localDeviceId: localDevice.id,
      localDeviceName: localDevice.name,
      startedAt: now,
      lastActivityAt: now,
    );

    await _sessionRepository.saveSession(session);
    return _runTransfer(session: session, target: target, isResume: false);
  }

  /// Continues a previously interrupted send using its persisted session.
  Future<TransferProgress> resumeSession(
    TransferSession session,
    Device target,
  ) async {
    if (session.direction != TransferDirection.sending) {
      throw ArgumentError(
        'Only sending sessions can be resumed by this device',
      );
    }

    final resumed = session.copyWith(
      peerId: target.id,
      peerName: target.name,
      peerIp: target.ipAddress,
      peerPort: target.port,
      status: TransferSessionStatus.inProgress,
      lastActivityAt: DateTime.now(),
      clearErrorMessage: true,
    );
    await _sessionRepository.saveSession(resumed);
    return _runTransfer(session: resumed, target: target, isResume: true);
  }

  /// Finds a paused send targeting [peer] and continues it.
  ///
  /// Returns `null` when there is nothing to resume or a cooldown is active.
  Future<TransferSession?> resumeTransferForPeer(
    Device peer, {
    Duration cooldown = const Duration(seconds: 3),
  }) async {
    final sessions = await _sessionRepository.getIncompleteSessions();
    for (final session in sessions) {
      if (session.direction != TransferDirection.sending) continue;
      if (session.status != TransferSessionStatus.paused &&
          session.status != TransferSessionStatus.pending) {
        continue;
      }
      final matches = session.peerId == peer.id ||
          (session.peerIp != null && session.peerIp == peer.ipAddress);
      if (!matches) continue;
      if (_runningTransfers.contains(session.transferId)) continue;

      final lastAttempt = _lastResumeAttempt[session.transferId];
      if (lastAttempt != null &&
          DateTime.now().difference(lastAttempt) < cooldown) {
        continue;
      }
      _lastResumeAttempt[session.transferId] = DateTime.now();

      debugPrint(
        '[TransferManager] Resuming ${session.transferId} with ${peer.name}',
      );
      final future = resumeSession(session, peer);
      unawaited(future);
      return session;
    }
    return null;
  }

  Future<TransferProgress> _runTransfer({
    required TransferSession session,
    required Device target,
    required bool isResume,
  }) async {
    final transferId = session.transferId;
    var current = session;
    final totalBytes = current.totalSizeBytes;
    final totalFiles = current.files.length;

    _activeSendingTargets[transferId] = target;
    _activeRequests[transferId] = _requestFromSession(current);
    final cancelToken = CancelToken();
    _activeCancelTokens[transferId] = cancelToken;
    _connectionLostSignals.remove(transferId);
    _runningTransfers.add(transferId);
    _connectionMonitor.watch(target: target, transferId: transferId);

    final tracker = _SpeedTracker(current.receivedByteCount);
    var phase =
        isResume ? TransferPhase.resuming : TransferPhase.normal;
    var currentFileIndex = _firstIncompleteFile(current);
    var currentFileName = currentFileIndex < totalFiles
        ? current.files[currentFileIndex].name
        : null;
    var lastProgress = _progressOf(
      current,
      status: TransferStatus.pending,
      tracker: tracker,
      phase: phase,
      currentFileIndex: currentFileIndex,
      currentFileName: currentFileName,
      totalFiles: totalFiles,
      totalBytes: totalBytes,
    );

    void emit({
      TransferStatus? status,
      int? chunkIndex,
      int? totalChunks,
      TransferPhase? nextPhase,
      String? errorMessage,
      bool clearChunk = false,
    }) {
      if (nextPhase != null) phase = nextPhase;
      lastProgress = _progressOf(
        current,
        status: status ?? TransferStatus.inProgress,
        tracker: tracker,
        phase: phase,
        currentFileIndex: currentFileIndex,
        currentFileName: currentFileName,
        totalFiles: totalFiles,
        totalBytes: totalBytes,
        chunkIndex: clearChunk ? null : chunkIndex,
        totalChunks: clearChunk ? null : totalChunks,
        errorMessage: errorMessage,
      );
      if (!_progressStreamController.isClosed) {
        _progressStreamController.add(lastProgress);
      }
    }

    emit(status: isResume ? TransferStatus.inProgress : TransferStatus.pending);

    try {
      final accepted = await _client.prepareTransfer(
        target,
        _requestFromSession(current),
      );
      if (!accepted) {
        debugPrint('[TransferManager] Transfer was rejected by ${target.name}');
        await _recordHistory(current, TransferRecordStatus.cancelled);
        await _sessionRepository.deleteSession(transferId);
        emit(status: TransferStatus.rejected, clearChunk: true);
        _cleanup(transferId);
        return lastProgress;
      }

      current = current.copyWith(
        status: TransferSessionStatus.inProgress,
        peerIp: target.ipAddress,
        peerPort: target.port,
        clearErrorMessage: true,
      );
      await _persist(current);
      emit(status: TransferStatus.inProgress, clearChunk: true);

      for (var fileIndex = 0; fileIndex < current.files.length; fileIndex++) {
        if (cancelToken.isCancelled) {
          throw const TransferCancelledException();
        }
        if (_connectionLostSignals.contains(transferId)) {
          throw const TransferConnectionLostException();
        }

        currentFileIndex = fileIndex;
        currentFileName = current.files[fileIndex].name;

        if (current.fileSavePaths.containsKey(fileIndex)) {
          emit();
          continue;
        }

        final file = current.files[fileIndex];
        final resume = await _client.getResumeState(target, transferId, fileIndex);

        if (resume.fileComplete && resume.savePath != null) {
          current = _withSavePath(
            _withChunks(current, fileIndex, resume.receivedChunks),
            fileIndex,
            resume.savePath,
          );
          await _persist(current);
          emit(clearChunk: true);
          continue;
        }

        current = _withChunks(current, fileIndex, resume.receivedChunks);
        await _persist(current);
        emit(clearChunk: true);

        final plan = chunkManager.chunkPlanFor(current, fileIndex);
        final alreadySent = resume.receivedChunks.toSet();
        final missing = [
          for (final chunk in plan)
            if (!alreadySent.contains(chunk.index)) chunk.index,
        ];

        if (plan.isNotEmpty) {
          await _sendChunks(
            target: target,
            transferId: transferId,
            fileIndex: fileIndex,
            file: file,
            plan: plan,
            chunkIndices: missing,
            cancelToken: cancelToken,
            onProgress: (chunkIndex, sent, total) {
              emit(chunkIndex: chunkIndex, totalChunks: plan.length);
            },
            onChunkSent: (chunkIndex) {
              current = _withChunks(current, fileIndex, [chunkIndex]);
            },
          );
          await _persist(current);
        }

        final savePath = await _finalizeWithRepair(
          target: target,
          transferId: transferId,
          fileIndex: fileIndex,
          file: file,
          plan: plan,
          cancelToken: cancelToken,
          onChunkSent: (chunkIndex) {
            current = _withChunks(current, fileIndex, [chunkIndex]);
          },
          onProgress: (chunkIndex) {
            emit(chunkIndex: chunkIndex, totalChunks: plan.length);
          },
        );

        current = _withSavePath(current, fileIndex, savePath);
        await _persist(current);
        emit(clearChunk: true);
      }

      current = current.copyWith(
        status: TransferSessionStatus.completed,
        completedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        clearErrorMessage: true,
      );
      await _sessionRepository.saveSession(current);
      await _recordHistory(
        current,
        TransferRecordStatus.completed,
        completedAt: current.completedAt,
      );

      final completed = lastProgress.copyWith(
        status: TransferStatus.completed,
        bytesTransferred: totalBytes,
        clearCurrentChunk: true,
        clearTotalChunks: true,
        clearErrorMessage: true,
      );
      lastProgress = completed;
      if (!_progressStreamController.isClosed) {
        _progressStreamController.add(completed);
      }

      _cleanup(transferId);
      return completed;
    } catch (error) {
      final isCancelled = cancelToken.isCancelled ||
          error is TransferCancelledException;
      // isConnectionError keyword-matches "clientexception", which our own
      // TransferClientException name contains — but that type is only thrown
      // for HTTP error responses or local file problems, never for transport
      // failures (those surface as DioException/SocketException). Treating it
      // as connection-lost would pause the transfer instead of failing it.
      final isConnectionLost = error is TransferConnectionLostException ||
          (error is! TransferClientException &&
              isConnectionError(error) &&
              !isCancelled);

      debugPrint(
        '[TransferManager] Transfer $transferId stopped: $error '
        '(cancelled: $isCancelled, connectionLost: $isConnectionLost)',
      );

      if (isCancelled) {
        await _recordHistory(current, TransferRecordStatus.cancelled);
        await _sessionRepository.deleteSession(transferId);
        emit(status: TransferStatus.cancelled, clearChunk: true);
      } else if (isConnectionLost) {
        current = current.copyWith(
          status: TransferSessionStatus.paused,
          errorMessage: 'Connection lost',
          lastActivityAt: DateTime.now(),
        );
        await _sessionRepository.saveSession(current);
        emit(
          status: TransferStatus.inProgress,
          nextPhase: TransferPhase.connectionLost,
          errorMessage: 'Connection lost',
          clearChunk: true,
        );
      } else {
        current = current.copyWith(
          status: TransferSessionStatus.failed,
          errorMessage: error.toString(),
          lastActivityAt: DateTime.now(),
        );
        await _sessionRepository.saveSession(current);
        await _recordHistory(current, TransferRecordStatus.failed);
        emit(
          status: TransferStatus.failed,
          errorMessage: error.toString(),
          clearChunk: true,
        );
        try {
          await _client.cancelTransfer(target, transferId);
        } catch (_) {}
      }

      _cleanup(transferId);
      return lastProgress;
    }
  }

  Future<void> _sendChunks({
    required Device target,
    required String transferId,
    required int fileIndex,
    required TransferFile file,
    required List<ChunkInfo> plan,
    required List<int> chunkIndices,
    required CancelToken cancelToken,
    required void Function(int chunkIndex, int sent, int total) onProgress,
    required void Function(int chunkIndex) onChunkSent,
  }) async {
    if (chunkIndices.isEmpty) return;

    final int workerCount =
        maxParallelChunks.clamp(1, 16).clamp(1, chunkIndices.length);
    var nextIndex = 0;
    Object? failure;
    StackTrace? failureStack;

    Future<void> worker() async {
      while (failure == null) {
        final int position = nextIndex++;
        if (position >= chunkIndices.length) return;
        final int chunkIndex = chunkIndices[position];

        try {
          if (cancelToken.isCancelled) {
            throw const TransferCancelledException();
          }
          if (_connectionLostSignals.contains(transferId)) {
            throw const TransferConnectionLostException();
          }

          final chunk = plan[chunkIndex];
          final bytes = await TransferClient.readChunk(
            file.localPath,
            chunk.startByte,
            chunk.endByteExclusive,
          );

          await _client.uploadChunk(
            target: target,
            transferId: transferId,
            fileIndex: fileIndex,
            chunkIndex: chunkIndex,
            bytes: bytes,
            startByte: chunk.startByte,
            endByte: chunk.endByte,
            fileSize: file.sizeInBytes,
            totalChunks: plan.length,
            cancelToken: cancelToken,
            onProgress: (sent, total) => onProgress(chunkIndex, sent, total),
          );

          onChunkSent(chunkIndex);
          onProgress(chunkIndex, bytes.length, bytes.length);
        } catch (error, stack) {
          failure ??= error;
          failureStack ??= stack;
        }
      }
    }

    await Future.wait<void>(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );
    if (failure != null) {
      Error.throwWithStackTrace(failure!, failureStack!);
    }
  }

  Future<String?> _finalizeWithRepair({
    required Device target,
    required String transferId,
    required int fileIndex,
    required TransferFile file,
    required List<ChunkInfo> plan,
    required CancelToken cancelToken,
    required void Function(int chunkIndex) onChunkSent,
    required void Function(int chunkIndex) onProgress,
  }) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final result = await _client.finalizeFile(target, transferId, fileIndex);
        return result['savePath'] as String?;
      } on TransferClientException catch (e) {
        if (e.statusCode != 409 || e.missingChunks.isEmpty || plan.isEmpty) {
          rethrow;
        }
        debugPrint(
          '[TransferManager] Receiver still misses ${e.missingChunks} '
          'chunks for $transferId/$fileIndex, resending',
        );
        await _sendChunks(
          target: target,
          transferId: transferId,
          fileIndex: fileIndex,
          file: file,
          plan: plan,
          chunkIndices: e.missingChunks,
          cancelToken: cancelToken,
          onProgress: (chunkIndex, sent, total) => onProgress(chunkIndex),
          onChunkSent: onChunkSent,
        );
      }
    }
    return null;
  }

  TransferProgress _progressOf(
    TransferSession session, {
    required TransferStatus status,
    required _SpeedTracker tracker,
    required TransferPhase phase,
    required int currentFileIndex,
    required String? currentFileName,
    required int totalFiles,
    required int totalBytes,
    int? chunkIndex,
    int? totalChunks,
    String? errorMessage,
  }) {
    final bytes = session.receivedByteCount;
    return TransferProgress(
      transferId: session.transferId,
      currentFileIndex: currentFileIndex,
      totalFiles: totalFiles,
      bytesTransferred: bytes,
      totalBytes: totalBytes,
      speedBps: tracker.update(bytes),
      status: status,
      currentFileName: currentFileName,
      phase: phase,
      currentChunk: chunkIndex,
      totalChunks: totalChunks,
      errorMessage: errorMessage,
    );
  }

  TransferSession _withChunks(
    TransferSession session,
    int fileIndex,
    List<int> chunks,
  ) {
    final merged = <int>{...session.receivedChunksForFile(fileIndex), ...chunks};
    final updatedChunks =
        Map<int, List<int>>.from(session.receivedChunksPerFile);
    updatedChunks[fileIndex] = merged.toList()..sort();
    return session.copyWith(receivedChunksPerFile: updatedChunks);
  }

  TransferSession _withSavePath(
    TransferSession session,
    int fileIndex,
    String? savePath,
  ) {
    if (savePath == null) return session;
    final paths = Map<int, String>.from(session.fileSavePaths)
      ..[fileIndex] = savePath;
    return session.copyWith(fileSavePaths: paths);
  }

  TransferRequest _requestFromSession(TransferSession session) {
    return TransferRequest(
      transferId: session.transferId,
      senderId: session.localDeviceId ?? session.peerId,
      senderName: session.localDeviceName ?? session.peerName,
      files: session.files,
      totalSizeBytes: session.totalSizeBytes,
      timestamp: session.startedAt,
      chunkSize: session.chunkSize,
    );
  }

  int _firstIncompleteFile(TransferSession session) {
    for (var i = 0; i < session.files.length; i++) {
      if (!session.fileSavePaths.containsKey(i)) return i;
    }
    return session.files.isEmpty ? 0 : session.files.length - 1;
  }

  Future<List<TransferFile>> _normalizeFiles(List<TransferFile> files) async {
    final normalized = <TransferFile>[];
    for (final file in files) {
      if (file.localPath.isEmpty) {
        normalized.add(file);
        continue;
      }
      final onDisk = File(file.localPath);
      if (!await onDisk.exists()) {
        normalized.add(file);
        continue;
      }

      final size = await onDisk.length();
      if (size != file.sizeInBytes) {
        debugPrint(
          '[TransferManager] ${file.name}: adjusting size '
          '${file.sizeInBytes} -> $size',
        );
      }
      final String hash =
          file.sha256 ?? await FileChecksum.sha256OfFile(file.localPath);
      normalized.add(file.copyWith(sizeInBytes: size, sha256: hash));
    }
    return normalized;
  }

  Future<void> _persist(TransferSession session) {
    return _sessionRepository.saveSession(
      session.copyWith(lastActivityAt: DateTime.now()),
    );
  }

  /// Appends a terminal outcome to the local history log.
  ///
  /// History is best-effort: a storage hiccup must never turn a successful
  /// transfer into a user-visible failure, so errors are only logged.
  Future<void> _recordHistory(
    TransferSession session,
    TransferRecordStatus status, {
    DateTime? completedAt,
  }) async {
    if (session.files.isEmpty) return;
    try {
      await _historyRepository.saveTransferRecord(
        TransferRecord.fromSession(
          session,
          status,
          completedAt: completedAt ?? DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('[TransferManager] Failed to record history: $e');
    }
  }

  void _onConnectionEvent(ConnectionEvent event) {
    if (event.kind == ConnectionEventKind.lost) {
      if (_activeSendingTargets.containsKey(event.transferId) ||
          _runningTransfers.contains(event.transferId)) {
        debugPrint(
          '[TransferManager] Peer unreachable for ${event.transferId}, pausing',
        );
        _connectionLostSignals.add(event.transferId);
      }
    } else {
      _connectionLostSignals.remove(event.transferId);
    }
  }

  /// Receiver: accept incoming transfer request.
  void acceptTransfer(String transferId) {
    _server.respondToRequest(transferId, true);
  }

  /// Receiver: reject incoming transfer request.
  void rejectTransfer(String transferId) {
    _server.respondToRequest(transferId, false);
    final request = _activeRequests.remove(transferId);
    if (request != null) {
      final progress = TransferProgress(
        transferId: transferId,
        currentFileIndex: 0,
        totalFiles: request.files.length,
        bytesTransferred: 0,
        totalBytes: request.totalSizeBytes,
        speedBps: 0,
        status: TransferStatus.rejected,
      );
      _emitProgress(progress);
    }
  }

  /// Cancels an in-progress transfer (either sender or receiver).
  Future<void> cancelTransfer(String transferId) async {
    final cancelToken = _activeCancelTokens[transferId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Cancelled by user');
    }
    _connectionLostSignals.remove(transferId);

    // When _runTransfer is mid-flight it owns the terminal bookkeeping and
    // has already written the history entry. Only record here for cancels
    // that never reached that loop (receiver side, paused or pending sends).
    final isDriving = _runningTransfers.contains(transferId);
    final session = await _sessionRepository.getSession(transferId);

    final target = _activeSendingTargets[transferId];
    if (target != null) {
      try {
        await _client.cancelTransfer(target, transferId);
      } catch (_) {}
    }

    _server.respondToRequest(transferId, false);
    await _chunkManager.discardTransfer(transferId);
    await _sessionRepository.deleteSession(transferId);
    if (!isDriving && session != null) {
      await _recordHistory(session, TransferRecordStatus.cancelled);
    }

    final req = _activeRequests[transferId];
    final progress = TransferProgress(
      transferId: transferId,
      currentFileIndex: 0,
      totalFiles: req?.files.length ?? 0,
      bytesTransferred: 0,
      totalBytes: req?.totalSizeBytes ?? 0,
      speedBps: 0,
      status: TransferStatus.cancelled,
    );
    _emitProgress(progress);
    _cleanup(transferId);
    // Flush the broadcast progress event so callers observing [onProgress]
    // have seen the cancellation before this future completes.
    await Future<void>.microtask(() {});
  }

  /// Discards a persisted session and everything staged for it.
  ///
  /// The abandoned transfer is logged as cancelled so the user can still see
  /// and resend it from history. The session row is removed before the
  /// filesystem cleanup so the UI is unblocked even if temp deletion is slow
  /// (and so widget tests, which run under FakeAsync, are not stalled by real
  /// IO). Temp cleanup is best-effort: `deleteTempDataFor` already swallows
  /// errors, and leftover scratch data is ignored on the next launch.
  Future<void> discardSession(String transferId) async {
    final session = await _sessionRepository.getSession(transferId);
    await _sessionRepository.deleteSession(transferId);
    unawaited(_chunkManager.discardTransfer(transferId));
    if (session != null) {
      await _recordHistory(session, TransferRecordStatus.cancelled);
    }
  }

  TransferRequest? getActiveRequest(String transferId) {
    return _activeRequests[transferId];
  }

  void _emitProgress(TransferProgress progress) {
    if (!_progressStreamController.isClosed) {
      _progressStreamController.add(progress);
    }
  }

  void _cleanup(String transferId) {
    _activeCancelTokens.remove(transferId);
    _activeSendingTargets.remove(transferId);
    _activeRequests.remove(transferId);
    _runningTransfers.remove(transferId);
    _connectionLostSignals.remove(transferId);
    _connectionMonitor.stop(transferId);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _maintenanceTimer?.cancel();
    await _serverProgressSub?.cancel();
    await _connectionSub?.cancel();
    await _connectionMonitor.dispose();
    await _server.dispose();
    await _progressStreamController.close();
  }
}

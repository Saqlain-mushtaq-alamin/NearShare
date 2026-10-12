import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import '../domain/transfer_file.dart';
import '../domain/transfer_progress.dart';
import '../domain/transfer_request.dart';
import 'file_storage_service.dart';

class TransferServer {
  final FileStorageService _storageService;
  final StreamController<TransferRequest> _incomingRequestController =
      StreamController<TransferRequest>.broadcast();
  final StreamController<TransferProgress> _progressController =
      StreamController<TransferProgress>.broadcast();

  final Map<String, Completer<bool>> _pendingDecisions = {};
  final Map<String, TransferRequest> _activeTransfers = {};
  final Map<String, TransferProgress> _transferProgressMap = {};
  final Map<String, List<String>> _receivedFilePaths = {};
  final Set<String> _cancelledTransfers = {};

  HttpServer? _server;
  int? _boundPort;

  TransferServer({FileStorageService? storageService})
      : _storageService = storageService ?? FileStorageService();

  Stream<TransferRequest> get onIncomingRequest =>
      _incomingRequestController.stream;
  Stream<TransferProgress> get onProgress => _progressController.stream;
  int? get boundPort => _boundPort;
  bool get isRunning => _server != null;

  Handler get handler => _buildRouter().call;

  Router _buildRouter() {
    final router = Router();

    // Prepare route
    router.post('/api/v1/transfer/prepare', _handlePrepare);

    // Upload route
    router.post(
      '/api/v1/transfer/upload/<transferId>/<fileIndex>',
      _handleUpload,
    );

    // Status route
    router.get('/api/v1/transfer/status/<transferId>', _handleStatus);

    // Cancel route
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
        return Response(
          400,
          body: jsonEncode({'error': 'Missing transferId'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final completer = Completer<bool>();
      _pendingDecisions[transferId] = completer;
      _activeTransfers[transferId] = transferRequest;
      _cancelledTransfers.remove(transferId);
      _receivedFilePaths[transferId] = [];

      final initialProgress = TransferProgress(
        transferId: transferId,
        currentFileIndex: 0,
        totalFiles: transferRequest.files.length,
        bytesTransferred: 0,
        totalBytes: transferRequest.totalSizeBytes,
        speedBps: 0,
        status: TransferStatus.pending,
        currentFileName: transferRequest.files.isNotEmpty
            ? transferRequest.files.first.name
            : null,
      );
      _transferProgressMap[transferId] = initialProgress;
      _progressController.add(initialProgress);

      // Emit to UI
      _incomingRequestController.add(transferRequest);

      // Wait for user prompt response (max 60 seconds)
      final accepted = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => false,
      );

      if (accepted) {
        final acceptedProgress = initialProgress.copyWith(
          status: TransferStatus.accepted,
        );
        _transferProgressMap[transferId] = acceptedProgress;
        _progressController.add(acceptedProgress);

        return Response.ok(
          jsonEncode({
            'status': 'accepted',
            'transferId': transferId,
          }),
          headers: {'content-type': 'application/json'},
        );
      } else {
        _activeTransfers.remove(transferId);
        final rejectedProgress = initialProgress.copyWith(
          status: TransferStatus.rejected,
        );
        _transferProgressMap[transferId] = rejectedProgress;
        _progressController.add(rejectedProgress);

        return Response(
          403,
          body: jsonEncode({
            'status': 'rejected',
            'transferId': transferId,
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    } catch (e, stack) {
      debugPrint('[TransferServer] Error handling prepare: $e\n$stack');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _handleUpload(
    Request request,
    String transferId,
    String fileIndexStr,
  ) async {
    final fileIndex = int.tryParse(fileIndexStr) ?? 0;
    final transfer = _activeTransfers[transferId];

    if (transfer == null) {
      return Response(
        404,
        body: jsonEncode({'error': 'Transfer $transferId not found'}),
        headers: {'content-type': 'application/json'},
      );
    }

    if (_cancelledTransfers.contains(transferId)) {
      return Response(
        409,
        body: jsonEncode({'error': 'Transfer was cancelled'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final fileMeta = fileIndex < transfer.files.length
        ? transfer.files[fileIndex]
        : TransferFile(
            name: 'file_$fileIndex',
            sizeInBytes: 0,
            mimeType: 'application/octet-stream',
            localPath: '',
          );

    File? destinationFile;
    IOSink? fileSink;

    try {
      destinationFile =
          await _storageService.prepareDestinationFile(fileMeta.name);
      fileSink = destinationFile.openWrite();

      int bytesForThisFile = 0;
      final startTime = DateTime.now();
      DateTime lastProgressEmit = DateTime.now();

      final form = request.formData();
      if (form != null) {
        await for (final data in form.formData) {
          if (data.name == 'file') {
            await for (final chunk in data.part) {
              if (_cancelledTransfers.contains(transferId)) {
                throw Exception('Transfer cancelled');
              }
              fileSink.add(chunk);
              bytesForThisFile += chunk.length;

              final now = DateTime.now();
              if (now.difference(lastProgressEmit).inMilliseconds > 200) {
                lastProgressEmit = now;
                _updateProgress(
                  transfer: transfer,
                  fileIndex: fileIndex,
                  fileName: fileMeta.name,
                  bytesForThisFile: bytesForThisFile,
                  startTime: startTime,
                );
              }
            }
          }
        }
      } else {
        // Direct stream or non-form multipart
        final mp = request.multipart();
        if (mp != null) {
          await for (final part in mp.parts) {
            await for (final chunk in part) {
              if (_cancelledTransfers.contains(transferId)) {
                throw Exception('Transfer cancelled');
              }
              fileSink.add(chunk);
              bytesForThisFile += chunk.length;

              final now = DateTime.now();
              if (now.difference(lastProgressEmit).inMilliseconds > 200) {
                lastProgressEmit = now;
                _updateProgress(
                  transfer: transfer,
                  fileIndex: fileIndex,
                  fileName: fileMeta.name,
                  bytesForThisFile: bytesForThisFile,
                  startTime: startTime,
                );
              }
            }
          }
        } else {
          // Raw stream
          await for (final chunk in request.read()) {
            if (_cancelledTransfers.contains(transferId)) {
              throw Exception('Transfer cancelled');
            }
            fileSink.add(chunk);
            bytesForThisFile += chunk.length;

            final now = DateTime.now();
            if (now.difference(lastProgressEmit).inMilliseconds > 200) {
              lastProgressEmit = now;
              _updateProgress(
                transfer: transfer,
                fileIndex: fileIndex,
                fileName: fileMeta.name,
                bytesForThisFile: bytesForThisFile,
                startTime: startTime,
              );
            }
          }
        }
      }

      await fileSink.flush();
      await fileSink.close();
      fileSink = null;

      _receivedFilePaths[transferId]?.add(destinationFile.path);

      // Check if all files are complete
      final isLastFile = fileIndex >= transfer.files.length - 1;
      final status =
          isLastFile ? TransferStatus.completed : TransferStatus.inProgress;

      _updateProgress(
        transfer: transfer,
        fileIndex: fileIndex,
        fileName: fileMeta.name,
        bytesForThisFile: bytesForThisFile,
        startTime: startTime,
        statusOverride: status,
      );

      return Response.ok(
        jsonEncode({
          'status': 'completed',
          'transferId': transferId,
          'fileIndex': fileIndex,
          'savePath': destinationFile.path,
          'isLastFile': isLastFile,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      if (fileSink != null) {
        await fileSink.close();
      }
      if (destinationFile != null) {
        await _storageService.deleteIncompleteFile(destinationFile.path);
      }

      final isCancelled = _cancelledTransfers.contains(transferId);
      final failedProgress = (_transferProgressMap[transferId] ??
              TransferProgress(
                transferId: transferId,
                currentFileIndex: fileIndex,
                totalFiles: transfer.files.length,
                bytesTransferred: 0,
                totalBytes: transfer.totalSizeBytes,
                speedBps: 0,
                status: isCancelled
                    ? TransferStatus.cancelled
                    : TransferStatus.failed,
              ))
          .copyWith(
        status: isCancelled ? TransferStatus.cancelled : TransferStatus.failed,
        errorMessage: e.toString(),
      );

      _transferProgressMap[transferId] = failedProgress;
      _progressController.add(failedProgress);

      return Response.internalServerError(
        body: jsonEncode({'error': e.toString(), 'cancelled': isCancelled}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  TransferProgress _updateProgress({
    required TransferRequest transfer,
    required int fileIndex,
    required String fileName,
    required int bytesForThisFile,
    required DateTime startTime,
    TransferStatus? statusOverride,
  }) {
    int priorBytes = 0;
    for (int i = 0; i < fileIndex && i < transfer.files.length; i++) {
      priorBytes += transfer.files[i].sizeInBytes;
    }
    final totalTransferred = priorBytes + bytesForThisFile;

    final elapsedSeconds =
        DateTime.now().difference(startTime).inMilliseconds / 1000.0;
    final speed =
        elapsedSeconds > 0.1 ? (bytesForThisFile / elapsedSeconds) : 0.0;

    final progress = TransferProgress(
      transferId: transfer.transferId,
      currentFileIndex: fileIndex,
      totalFiles: transfer.files.length,
      bytesTransferred: totalTransferred,
      totalBytes: transfer.totalSizeBytes,
      speedBps: speed,
      status: statusOverride ?? TransferStatus.inProgress,
      currentFileName: fileName,
    );

    _transferProgressMap[transfer.transferId] = progress;
    _progressController.add(progress);
    return progress;
  }

  Future<Response> _handleStatus(Request request, String transferId) async {
    final progress = _transferProgressMap[transferId];
    if (progress == null) {
      return Response(
        404,
        body: jsonEncode({'error': 'Transfer $transferId not found'}),
        headers: {'content-type': 'application/json'},
      );
    }
    return Response.ok(
      jsonEncode(progress.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _handleCancel(Request request, String transferId) async {
    _cancelledTransfers.add(transferId);
    respondToRequest(transferId, false);

    final paths = _receivedFilePaths[transferId] ?? [];
    for (final path in paths) {
      await _storageService.deleteIncompleteFile(path);
    }
    _receivedFilePaths.remove(transferId);

    final current = _transferProgressMap[transferId];
    if (current != null) {
      final cancelled = current.copyWith(
        status: TransferStatus.cancelled,
      );
      _transferProgressMap[transferId] = cancelled;
      _progressController.add(cancelled);
    }

    return Response.ok(
      jsonEncode({
        'status': 'cancelled',
        'transferId': transferId,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<void> dispose() async {
    await stop();
    await _incomingRequestController.close();
    await _progressController.close();
  }
}

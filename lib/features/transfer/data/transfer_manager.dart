import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../discovery/domain/device.dart';
import '../domain/transfer_file.dart';
import '../domain/transfer_progress.dart';
import '../domain/transfer_request.dart';
import 'file_storage_service.dart';
import 'transfer_client.dart';
import 'transfer_server.dart';

class TransferManager {
  final TransferServer _server;
  final TransferClient _client;
  final FileStorageService _storageService;
  final Uuid _uuid;

  final StreamController<TransferProgress> _progressStreamController =
      StreamController<TransferProgress>.broadcast();

  final Map<String, CancelToken> _activeCancelTokens = {};
  final Map<String, Device> _activeSendingTargets = {};
  final Map<String, TransferRequest> _activeRequests = {};
  StreamSubscription<TransferProgress>? _serverProgressSub;

  TransferManager({
    TransferServer? server,
    TransferClient? client,
    FileStorageService? storageService,
    Uuid? uuid,
  })  : _server = server ?? TransferServer(),
        _client = client ?? TransferClient(),
        _storageService = storageService ?? FileStorageService(),
        _uuid = uuid ?? const Uuid() {
    _serverProgressSub = _server.onProgress.listen((progress) {
      _progressStreamController.add(progress);
    });
  }

  TransferServer get server => _server;
  TransferClient get client => _client;
  FileStorageService get storageService => _storageService;

  Stream<TransferRequest> get onIncomingRequest => _server.onIncomingRequest;
  Stream<TransferProgress> get onProgress => _progressStreamController.stream;

  /// Starts the embedded receiver HTTP server.
  Future<int> startServer({int? port}) async {
    return await _server.start(port: port);
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
  }) async {
    final transferId = _uuid.v4();
    final totalSizeBytes = files.fold(0, (sum, f) => sum + f.sizeInBytes);

    final request = TransferRequest(
      transferId: transferId,
      senderId: localDevice.id,
      senderName: localDevice.name,
      files: files,
      totalSizeBytes: totalSizeBytes,
      timestamp: DateTime.now(),
    );

    _activeRequests[transferId] = request;
    _activeSendingTargets[transferId] = target;

    final cancelToken = CancelToken();
    _activeCancelTokens[transferId] = cancelToken;

    var currentProgress = TransferProgress(
      transferId: transferId,
      currentFileIndex: 0,
      totalFiles: files.length,
      bytesTransferred: 0,
      totalBytes: totalSizeBytes,
      speedBps: 0,
      status: TransferStatus.pending,
      currentFileName: files.isNotEmpty ? files.first.name : null,
    );

    _emitProgress(currentProgress);

    try {
      debugPrint('[TransferManager] Sending prepare request to ${target.name} (${target.ipAddress}:${target.port})');
      final accepted = await _client.prepareTransfer(target, request);

      if (!accepted) {
        debugPrint('[TransferManager] Transfer was rejected by ${target.name}');
        currentProgress = currentProgress.copyWith(
          status: TransferStatus.rejected,
        );
        _emitProgress(currentProgress);
        _cleanup(transferId);
        return currentProgress;
      }

      currentProgress = currentProgress.copyWith(
        status: TransferStatus.inProgress,
      );
      _emitProgress(currentProgress);

      int cumulativeBytes = 0;
      final startTime = DateTime.now();

      for (int i = 0; i < files.length; i++) {
        if (cancelToken.isCancelled) {
          throw Exception('Transfer cancelled by user');
        }

        final file = files[i];
        final fileStartTime = DateTime.now();

        currentProgress = currentProgress.copyWith(
          currentFileIndex: i,
          currentFileName: file.name,
          status: TransferStatus.inProgress,
        );
        _emitProgress(currentProgress);

        int fileTransferred = 0;
        await _client.uploadFile(
          target,
          transferId,
          i,
          file,
          cancelToken: cancelToken,
          onProgress: (sentBytes, totalBytes) {
            fileTransferred = sentBytes;
            final overallTransferred = cumulativeBytes + fileTransferred;
            final elapsed = DateTime.now().difference(fileStartTime).inMilliseconds / 1000.0;
            final speed = elapsed > 0.1 ? (fileTransferred / elapsed) : 0.0;

            currentProgress = currentProgress.copyWith(
              bytesTransferred: overallTransferred,
              speedBps: speed,
            );
            _emitProgress(currentProgress);
          },
        );

        cumulativeBytes += file.sizeInBytes > 0 ? file.sizeInBytes : fileTransferred;
      }

      final totalElapsed = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      final avgSpeed = totalElapsed > 0 ? (totalSizeBytes / totalElapsed) : 0.0;

      currentProgress = currentProgress.copyWith(
        bytesTransferred: totalSizeBytes,
        speedBps: avgSpeed,
        status: TransferStatus.completed,
      );
      _emitProgress(currentProgress);
      _cleanup(transferId);
      return currentProgress;
    } catch (e) {
      final isCancelled = cancelToken.isCancelled;
      debugPrint('[TransferManager] Transfer failed/cancelled: $e (isCancelled: $isCancelled)');

      currentProgress = currentProgress.copyWith(
        status: isCancelled ? TransferStatus.cancelled : TransferStatus.failed,
        errorMessage: e.toString(),
      );
      _emitProgress(currentProgress);

      if (!isCancelled) {
        // Notify target of abort
        try {
          await _client.cancelTransfer(target, transferId);
        } catch (_) {}
      }

      _cleanup(transferId);
      return currentProgress;
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
    // If sender side
    final cancelToken = _activeCancelTokens[transferId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Cancelled by user');
    }

    final target = _activeSendingTargets[transferId];
    if (target != null) {
      try {
        await _client.cancelTransfer(target, transferId);
      } catch (_) {}
    }

    // If receiver side
    _server.respondToRequest(transferId, false);

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
  }

  TransferRequest? getActiveRequest(String transferId) {
    return _activeRequests[transferId];
  }

  void _emitProgress(TransferProgress progress) {
    _progressStreamController.add(progress);
  }

  void _cleanup(String transferId) {
    _activeCancelTokens.remove(transferId);
    _activeSendingTargets.remove(transferId);
  }

  Future<void> dispose() async {
    await _serverProgressSub?.cancel();
    await _server.dispose();
    await _progressStreamController.close();
  }
}

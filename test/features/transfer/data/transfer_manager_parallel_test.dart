import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/retry_policy.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:nearshare/features/transfer/domain/resume_state.dart';

class _ConcurrencyTrackingClient extends TransferClient {
  int activeUploads = 0;
  int maxObservedUploads = 0;

  @override
  Future<bool> prepareTransfer(Device target, TransferRequest request) async {
    return true;
  }

  @override
  Future<ResumeState> getResumeState(
    Device target,
    String transferId,
    int fileIndex,
  ) async {
    return const ResumeState.unknown();
  }

  @override
  Future<Map<String, dynamic>> uploadChunk({
    required Device target,
    required String transferId,
    required int fileIndex,
    required int chunkIndex,
    required Uint8List bytes,
    required int startByte,
    required int endByte,
    required int fileSize,
    required int totalChunks,
    CancelToken? cancelToken,
    void Function(int sentBytes, int totalBytes)? onProgress,
    RetryPolicy? retryPolicyOverride,
  }) async {
    activeUploads++;
    if (activeUploads > maxObservedUploads) {
      maxObservedUploads = activeUploads;
    }
    onProgress?.call(bytes.length, bytes.length);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    activeUploads--;
    return <String, dynamic>{'status': 'received'};
  }

  @override
  Future<Map<String, dynamic>> finalizeFile(
    Device target,
    String transferId,
    int fileIndex,
  ) async {
    return <String, dynamic>{
      'status': 'completed',
      'savePath': '/tmp/received.bin',
    };
  }
}

void main() {
  test('sendFiles uploads chunks with bounded parallelism', () async {
    final tempDir = await Directory.systemTemp.createTemp('nearshare_parallel_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final file = File('${tempDir.path}${Platform.pathSeparator}large.bin');
    await file.writeAsBytes(Uint8List(3 * 1024 * 1024 + 17));
    final client = _ConcurrencyTrackingClient();
    final server = TransferServer(
      storageService: FileStorageService(customDownloadPath: tempDir.path),
    );
    final manager = TransferManager(
      server: server,
      client: client,
      storageService: FileStorageService(customDownloadPath: tempDir.path),
      maxParallelChunks: 3,
    );
    addTearDown(manager.dispose);

    final result = await manager.sendFiles(
      target: Device(
        id: 'receiver',
        name: 'Receiver',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: 1,
        discoveredAt: DateTime.now(),
      ),
      files: <TransferFile>[
        TransferFile(
          name: 'large.bin',
          sizeInBytes: await file.length(),
          mimeType: 'application/octet-stream',
          localPath: file.path,
        ),
      ],
      localDevice: Device(
        id: 'sender',
        name: 'Sender',
        platform: 'windows',
        ipAddress: '127.0.0.1',
        port: 2,
        discoveredAt: DateTime.now(),
      ),
    );

    expect(result.status, TransferStatus.completed);
    expect(client.maxObservedUploads, greaterThan(1));
    expect(client.maxObservedUploads, lessThanOrEqualTo(3));
  });
}

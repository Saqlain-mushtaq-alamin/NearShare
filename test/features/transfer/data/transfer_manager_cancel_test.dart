import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';

void main() {
  group('TransferManager Cancel Tests', () {
    late Directory tempDir;
    late FileStorageService storageService;
    late TransferServer server;
    late TransferManager manager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mgr_cancel_test_');
      storageService = FileStorageService(customDownloadPath: tempDir.path);
      server = TransferServer(storageService: storageService);
      manager = TransferManager(
        server: server,
        storageService: storageService,
      );
      await manager.startServer(port: 0);
    });

    tearDown(() async {
      await manager.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('cancelTransfer emits cancelled progress', () async {
      TransferProgress? progressUpdate;
      manager.onProgress.listen((p) {
        progressUpdate = p;
      });

      await manager.cancelTransfer('custom-cancel-id');

      expect(progressUpdate, isNotNull);
      expect(progressUpdate!.transferId, 'custom-cancel-id');
      expect(progressUpdate!.status, TransferStatus.cancelled);
    });
  });
}

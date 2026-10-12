import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TransferManager Receive Flow Tests', () {
    late Directory tempDir;
    late FileStorageService storageService;
    late TransferServer server;
    late TransferManager manager;
    late TransferClient client;
    late int serverPort;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mgr_recv_test_');
      storageService = FileStorageService(customDownloadPath: tempDir.path);
      server = TransferServer(storageService: storageService);
      manager = TransferManager(
        server: server,
        storageService: storageService,
      );
      serverPort = await manager.startServer(port: 0);
      client = TransferClient();
    });

    tearDown(() async {
      await manager.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('acceptTransfer accepts incoming request and processes uploads', () async {
      TransferRequest? incoming;
      manager.onIncomingRequest.listen((req) {
        incoming = req;
        // Accept via manager
        manager.acceptTransfer(req.transferId);
      });

      final localFile = File(p.join(tempDir.path, 'source.txt'));
      await localFile.writeAsString('Receiver test file payload');

      final target = Device(
        id: 'target-manager',
        name: 'Target Receiver',
        platform: 'windows',
        ipAddress: '127.0.0.1',
        port: serverPort,
        discoveredAt: DateTime.now(),
      );

      final transferFile = TransferFile(
        name: 'source.txt',
        sizeInBytes: await localFile.length(),
        mimeType: 'text/plain',
        localPath: localFile.path,
      );

      final req = TransferRequest(
        transferId: 'recv-mgr-1',
        senderId: 'remote-sender',
        senderName: 'Remote Peer',
        files: [transferFile],
        totalSizeBytes: transferFile.sizeInBytes,
        timestamp: DateTime.now(),
      );

      final accepted = await client.prepareTransfer(target, req);
      expect(accepted, isTrue);
      expect(incoming, isNotNull);
      expect(incoming!.transferId, 'recv-mgr-1');

      final uploadResult = await client.uploadFile(
        target,
        'recv-mgr-1',
        0,
        transferFile,
      );
      expect(uploadResult['status'], 'completed');
    });

    test('rejectTransfer declines incoming request', () async {
      manager.onIncomingRequest.listen((req) {
        // Reject via manager
        manager.rejectTransfer(req.transferId);
      });

      final target = Device(
        id: 'target-manager',
        name: 'Target Receiver',
        platform: 'windows',
        ipAddress: '127.0.0.1',
        port: serverPort,
        discoveredAt: DateTime.now(),
      );

      final req = TransferRequest(
        transferId: 'reject-mgr-1',
        senderId: 'remote-sender',
        senderName: 'Remote Peer',
        files: const [
          TransferFile(
            name: 'nope.txt',
            sizeInBytes: 50,
            mimeType: 'text/plain',
            localPath: '/nope.txt',
          ),
        ],
        totalSizeBytes: 50,
        timestamp: DateTime.now(),
      );

      final accepted = await client.prepareTransfer(target, req);
      expect(accepted, isFalse);
    });
  });
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TransferManager Send Flow Tests', () {
    late Directory clientTempDir;
    late Directory serverTempDir;
    late TransferServer receiverServer;
    late TransferManager senderManager;
    late Device targetDevice;
    late Device localSenderDevice;

    setUp(() async {
      clientTempDir = await Directory.systemTemp.createTemp('mgr_send_client_');
      serverTempDir = await Directory.systemTemp.createTemp('mgr_send_server_');

      final receiverStorage = FileStorageService(customDownloadPath: serverTempDir.path);
      receiverServer = TransferServer(storageService: receiverStorage);
      final receiverPort = await receiverServer.start(port: 0);

      final senderStorage = FileStorageService(customDownloadPath: clientTempDir.path);
      final senderServer = TransferServer(storageService: senderStorage);
      final senderClient = TransferClient();

      senderManager = TransferManager(
        server: senderServer,
        client: senderClient,
        storageService: senderStorage,
      );

      targetDevice = Device(
        id: 'receiver-dev',
        name: 'Receiver Device',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: receiverPort,
        discoveredAt: DateTime.now(),
      );

      localSenderDevice = Device(
        id: 'sender-dev',
        name: 'Sender Device',
        platform: 'windows',
        ipAddress: '127.0.0.1',
        port: 53317,
        discoveredAt: DateTime.now(),
      );
    });

    tearDown(() async {
      await receiverServer.dispose();
      await senderManager.dispose();
      if (await clientTempDir.exists()) {
        await clientTempDir.delete(recursive: true);
      }
      if (await serverTempDir.exists()) {
        await serverTempDir.delete(recursive: true);
      }
    });

    test('sendFiles orchestrates full prepare -> upload -> completed flow', () async {
      // Create 2 local test files
      final f1 = File(p.join(clientTempDir.path, 'file1.txt'));
      await f1.writeAsString('File 1 data content');

      final f2 = File(p.join(clientTempDir.path, 'file2.txt'));
      await f2.writeAsString('File 2 longer data content here!');

      final transferFiles = [
        TransferFile(
          name: 'file1.txt',
          sizeInBytes: await f1.length(),
          mimeType: 'text/plain',
          localPath: f1.path,
        ),
        TransferFile(
          name: 'file2.txt',
          sizeInBytes: await f2.length(),
          mimeType: 'text/plain',
          localPath: f2.path,
        ),
      ];

      // Auto-accept on receiver
      receiverServer.onIncomingRequest.listen((req) {
        receiverServer.respondToRequest(req.transferId, true);
      });

      final progressEvents = <TransferProgress>[];
      senderManager.onProgress.listen((p) {
        progressEvents.add(p);
      });

      final finalProgress = await senderManager.sendFiles(
        target: targetDevice,
        files: transferFiles,
        localDevice: localSenderDevice,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(finalProgress.status, TransferStatus.completed);
      expect(progressEvents.any((p) => p.status == TransferStatus.pending), isTrue);
      expect(progressEvents.any((p) => p.status == TransferStatus.inProgress), isTrue);
      expect(progressEvents.any((p) => p.status == TransferStatus.completed), isTrue);

      // Verify both files saved on receiver
      final savedF1 = File(p.join(serverTempDir.path, 'file1.txt'));
      final savedF2 = File(p.join(serverTempDir.path, 'file2.txt'));
      expect(await savedF1.exists(), isTrue);
      expect(await savedF2.exists(), isTrue);
    });
  });
}

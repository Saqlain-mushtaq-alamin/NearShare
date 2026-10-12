import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TransferClient Upload Tests', () {
    late Directory clientTempDir;
    late Directory serverTempDir;
    late TransferServer server;
    late TransferClient client;
    late Device targetDevice;

    setUp(() async {
      clientTempDir = await Directory.systemTemp.createTemp('nearshare_client_temp_');
      serverTempDir = await Directory.systemTemp.createTemp('nearshare_server_temp_');

      final serverStorage = FileStorageService(customDownloadPath: serverTempDir.path);
      server = TransferServer(storageService: serverStorage);
      final port = await server.start(port: 0);

      client = TransferClient();
      targetDevice = Device(
        id: 'target-server',
        name: 'Receiver Phone',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: port,
        discoveredAt: DateTime.now(),
      );
    });

    tearDown(() async {
      await server.dispose();
      if (await clientTempDir.exists()) {
        await clientTempDir.delete(recursive: true);
      }
      if (await serverTempDir.exists()) {
        await serverTempDir.delete(recursive: true);
      }
    });

    test('uploadFile sends multipart file data with progress reporting', () async {
      // Create local file to send
      final localFile = File(p.join(clientTempDir.path, 'upload_me.txt'));
      const content = 'Hello NearShare Upload Test File!';
      await localFile.writeAsString(content);

      final transferFile = TransferFile(
        name: 'upload_me.txt',
        sizeInBytes: await localFile.length(),
        mimeType: 'text/plain',
        localPath: localFile.path,
      );

      final request = TransferRequest(
        transferId: 'client-upload-tx-1',
        senderId: 'client-id',
        senderName: 'Sender Device',
        files: [transferFile],
        totalSizeBytes: transferFile.sizeInBytes,
        timestamp: DateTime.now(),
      );

      // Auto-accept
      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, true);
      });

      final prepared = await client.prepareTransfer(targetDevice, request);
      expect(prepared, isTrue);

      bool progressReported = false;
      final result = await client.uploadFile(
        targetDevice,
        'client-upload-tx-1',
        0,
        transferFile,
        onProgress: (sent, total) {
          if (sent > 0) progressReported = true;
        },
      );

      expect(result['status'], 'completed');
      expect(progressReported, isTrue);

      final savedPath = result['savePath'] as String;
      final savedFile = File(savedPath);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.readAsString(), content);
    });
  });
}

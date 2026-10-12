import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:shelf/shelf.dart';

void main() {
  group('TransferServer Upload Tests', () {
    late Directory tempDir;
    late FileStorageService storageService;
    late TransferServer server;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nearshare_upload_test_');
      storageService = FileStorageService(customDownloadPath: tempDir.path);
      server = TransferServer(storageService: storageService);
    });

    tearDown(() async {
      await server.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('POST /api/v1/transfer/upload streams file to disk and finishes transfer', () async {
      final request = TransferRequest(
        transferId: 'upload-tx-1',
        senderId: 'dev-sender',
        senderName: 'Sender',
        files: const [
          TransferFile(
            name: 'hello.txt',
            sizeInBytes: 13,
            mimeType: 'text/plain',
            localPath: '/hello.txt',
          ),
        ],
        totalSizeBytes: 13,
        timestamp: DateTime.now(),
      );

      // Prepare & accept
      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, true);
      });

      final prepReq = Request(
        'POST',
        Uri.parse('http://localhost:53317/api/v1/transfer/prepare'),
        body: jsonEncode(request.toJson()),
        headers: {'content-type': 'application/json'},
      );
      final prepRes = await server.handler(prepReq);
      expect(prepRes.statusCode, 200);

      // Now upload file bytes
      const fileContent = 'Hello World!!';
      final uploadReq = Request(
        'POST',
        Uri.parse('http://localhost:53317/api/v1/transfer/upload/upload-tx-1/0'),
        body: Stream.value(utf8.encode(fileContent)),
        headers: {'content-type': 'application/octet-stream'},
      );

      TransferProgress? completedProgress;
      server.onProgress.listen((p) {
        if (p.status == TransferStatus.completed) {
          completedProgress = p;
        }
      });

      final uploadRes = await server.handler(uploadReq);
      expect(uploadRes.statusCode, 200);

      final body = jsonDecode(await uploadRes.readAsString()) as Map<String, dynamic>;
      expect(body['status'], 'completed');
      expect(body['fileIndex'], 0);
      expect(body['isLastFile'], true);

      final savedPath = body['savePath'] as String;
      final savedFile = File(savedPath);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.readAsString(), fileContent);

      expect(completedProgress, isNotNull);
      expect(completedProgress!.status, TransferStatus.completed);
    });
  });
}

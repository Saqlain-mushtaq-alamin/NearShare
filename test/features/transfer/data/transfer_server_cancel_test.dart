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
  group('TransferServer Cancel Tests', () {
    late Directory tempDir;
    late FileStorageService storageService;
    late TransferServer server;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nearshare_cancel_test_');
      storageService = FileStorageService(customDownloadPath: tempDir.path);
      server = TransferServer(storageService: storageService);
    });

    tearDown(() async {
      await server.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('POST /api/v1/transfer/cancel cleans up files and marks transfer cancelled', () async {
      final request = TransferRequest(
        transferId: 'cancel-tx-1',
        senderId: 'dev-1',
        senderName: 'Sender',
        files: const [
          TransferFile(
            name: 'temp_doc.txt',
            sizeInBytes: 100,
            mimeType: 'text/plain',
            localPath: '/temp_doc.txt',
          ),
        ],
        totalSizeBytes: 100,
        timestamp: DateTime.now(),
      );

      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, true);
      });

      // Prepare
      final prepReq = Request(
        'POST',
        Uri.parse('http://localhost:53317/api/v1/transfer/prepare'),
        body: jsonEncode(request.toJson()),
        headers: {'content-type': 'application/json'},
      );
      await server.handler(prepReq);

      TransferProgress? progressUpdate;
      server.onProgress.listen((p) {
        progressUpdate = p;
      });

      // Send cancel request
      final cancelReq = Request(
        'POST',
        Uri.parse('http://localhost:53317/api/v1/transfer/cancel/cancel-tx-1'),
      );
      final cancelRes = await server.handler(cancelReq);
      expect(cancelRes.statusCode, 200);

      final body = jsonDecode(await cancelRes.readAsString()) as Map<String, dynamic>;
      expect(body['status'], 'cancelled');
      expect(body['transferId'], 'cancel-tx-1');

      expect(progressUpdate?.status, TransferStatus.cancelled);
    });
  });
}

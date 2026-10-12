import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:shelf/shelf.dart';

void main() {
  group('TransferServer Rejection Tests', () {
    late TransferServer server;

    setUp(() {
      server = TransferServer();
    });

    tearDown(() async {
      await server.dispose();
    });

    test('POST /api/v1/transfer/prepare returns 403 when user rejects', () async {
      final request = TransferRequest(
        transferId: 'reject-tx-1',
        senderId: 'dev-2',
        senderName: 'Windows Desktop',
        files: const [
          TransferFile(
            name: 'photo.png',
            sizeInBytes: 2048,
            mimeType: 'image/png',
            localPath: '/photo.png',
          ),
        ],
        totalSizeBytes: 2048,
        timestamp: DateTime.now(),
      );

      TransferProgress? lastProgress;
      server.onProgress.listen((p) {
        lastProgress = p;
      });

      server.onIncomingRequest.listen((req) {
        // User rejects the transfer
        server.respondToRequest(req.transferId, false);
      });

      final shelfRequest = Request(
        'POST',
        Uri.parse('http://localhost:53317/api/v1/transfer/prepare'),
        body: jsonEncode(request.toJson()),
        headers: {'content-type': 'application/json'},
      );

      final response = await server.handler(shelfRequest);
      expect(response.statusCode, 403);

      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['status'], 'rejected');
      expect(body['transferId'], 'reject-tx-1');

      expect(lastProgress, isNotNull);
      expect(lastProgress!.status, TransferStatus.rejected);
    });
  });
}

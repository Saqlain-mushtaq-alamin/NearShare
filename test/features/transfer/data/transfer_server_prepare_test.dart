import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:shelf/shelf.dart';

void main() {
  group('TransferServer Prepare Request Tests', () {
    late TransferServer server;

    setUp(() {
      server = TransferServer();
    });

    tearDown(() async {
      await server.dispose();
    });

    test('POST /api/v1/transfer/prepare emits incoming request and responds when accepted', () async {
      final request = TransferRequest(
        transferId: 'prep-tx-1',
        senderId: 'dev-1',
        senderName: 'MacBook Pro',
        files: const [
          TransferFile(
            name: 'sample.txt',
            sizeInBytes: 1024,
            mimeType: 'text/plain',
            localPath: '/sample.txt',
          ),
        ],
        totalSizeBytes: 1024,
        timestamp: DateTime.now(),
      );

      TransferRequest? receivedRequest;
      server.onIncomingRequest.listen((req) {
        receivedRequest = req;
        // Accept the incoming transfer
        server.respondToRequest(req.transferId, true);
      });

      final shelfRequest = Request(
        'POST',
        Uri.parse('http://localhost:53317/api/v1/transfer/prepare'),
        body: jsonEncode(request.toJson()),
        headers: {'content-type': 'application/json'},
      );

      final response = await server.handler(shelfRequest);
      expect(response.statusCode, 200);

      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['status'], 'accepted');
      expect(body['transferId'], 'prep-tx-1');

      expect(receivedRequest, isNotNull);
      expect(receivedRequest!.transferId, 'prep-tx-1');
      expect(receivedRequest!.senderName, 'MacBook Pro');
    });
  });
}

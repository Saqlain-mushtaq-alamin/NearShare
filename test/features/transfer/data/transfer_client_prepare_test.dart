import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';

void main() {
  group('TransferClient Prepare Tests', () {
    late TransferServer server;
    late TransferClient client;
    late Device targetDevice;

    setUp(() async {
      server = TransferServer();
      final port = await server.start(port: 0);
      client = TransferClient();
      targetDevice = Device(
        id: 'target-1',
        name: 'Target Phone',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: port,
        discoveredAt: DateTime.now(),
      );
    });

    tearDown(() async {
      await server.dispose();
    });

    test('prepareTransfer returns true when recipient accepts', () async {
      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, true);
      });

      final request = TransferRequest(
        transferId: 'client-prep-1',
        senderId: 'client-sender',
        senderName: 'Client Device',
        files: const [
          TransferFile(
            name: 'doc.pdf',
            sizeInBytes: 1024,
            mimeType: 'application/pdf',
            localPath: '/doc.pdf',
          ),
        ],
        totalSizeBytes: 1024,
        timestamp: DateTime.now(),
      );

      final accepted = await client.prepareTransfer(targetDevice, request);
      expect(accepted, isTrue);
    });
  });
}

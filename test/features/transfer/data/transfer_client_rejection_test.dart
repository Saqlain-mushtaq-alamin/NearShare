import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';

void main() {
  group('TransferClient Rejection Tests', () {
    late TransferServer server;
    late TransferClient client;
    late Device targetDevice;

    setUp(() async {
      server = TransferServer();
      final port = await server.start(port: 0);
      client = TransferClient();
      targetDevice = Device(
        id: 'target-reject',
        name: 'Declining Device',
        platform: 'ios',
        ipAddress: '127.0.0.1',
        port: port,
        discoveredAt: DateTime.now(),
      );
    });

    tearDown(() async {
      await server.dispose();
    });

    test('prepareTransfer returns false when receiver rejects', () async {
      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, false);
      });

      final request = TransferRequest(
        transferId: 'client-reject-tx-1',
        senderId: 'client-id',
        senderName: 'Client Device',
        files: const [
          TransferFile(
            name: 'secret.pdf',
            sizeInBytes: 100,
            mimeType: 'application/pdf',
            localPath: '/secret.pdf',
          ),
        ],
        totalSizeBytes: 100,
        timestamp: DateTime.now(),
      );

      final accepted = await client.prepareTransfer(targetDevice, request);
      expect(accepted, isFalse);
    });
  });
}

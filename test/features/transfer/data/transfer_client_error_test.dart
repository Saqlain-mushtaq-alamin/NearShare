import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';

void main() {
  group('TransferClient Network Error Tests', () {
    test('prepareTransfer throws or returns false on unreachable device', () async {
      final client = TransferClient();
      final unreachableDevice = Device(
        id: 'unreachable',
        name: 'Dead Device',
        platform: 'windows',
        ipAddress: '127.0.0.1',
        port: 59998, // Closed port
        discoveredAt: DateTime.now(),
      );

      final request = TransferRequest(
        transferId: 'err-tx-1',
        senderId: 'client-1',
        senderName: 'Client',
        files: const [
          TransferFile(
            name: 'test.dat',
            sizeInBytes: 10,
            mimeType: 'application/octet-stream',
            localPath: '',
          ),
        ],
        totalSizeBytes: 10,
        timestamp: DateTime.now(),
      );

      expect(
        () async => await client.prepareTransfer(unreachableDevice, request),
        throwsA(anything),
      );
    });
  });
}

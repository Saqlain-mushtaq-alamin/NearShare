import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';

void main() {
  group('TransferRequest Domain Model Tests', () {
    final testDate = DateTime(2026, 9, 18, 12, 0, 0);
    const files = [
      TransferFile(
        name: 'a.txt',
        sizeInBytes: 100,
        mimeType: 'text/plain',
        localPath: '/a.txt',
      ),
      TransferFile(
        name: 'b.png',
        sizeInBytes: 250,
        mimeType: 'image/png',
        localPath: '/b.png',
      ),
    ];

    test('Constructs TransferRequest with all properties', () {
      final request = TransferRequest(
        transferId: 'uuid-1234',
        senderId: 'dev-sender',
        senderName: 'Sender MacBook',
        files: files,
        totalSizeBytes: 350,
        timestamp: testDate,
      );

      expect(request.transferId, 'uuid-1234');
      expect(request.senderId, 'dev-sender');
      expect(request.senderName, 'Sender MacBook');
      expect(request.files.length, 2);
      expect(request.totalSizeBytes, 350);
      expect(request.timestamp, testDate);
    });

    test('toJson and fromJson serialize and restore accurately', () {
      final request = TransferRequest(
        transferId: 'req-99',
        senderId: 'sender-01',
        senderName: 'Pixel 8',
        files: files,
        totalSizeBytes: 350,
        timestamp: testDate,
      );

      final json = request.toJson();
      final restored = TransferRequest.fromJson(json);

      expect(restored.transferId, 'req-99');
      expect(restored.senderName, 'Pixel 8');
      expect(restored.files.length, 2);
      expect(restored.files.first.name, 'a.txt');
      expect(restored.totalSizeBytes, 350);
      expect(restored.timestamp.isAtSameMomentAs(testDate), isTrue);
    });

    test('fromJson computes totalSizeBytes if missing', () {
      final json = {
        'transferId': 'req-auto',
        'senderId': 'sender-auto',
        'senderName': 'Auto Calc',
        'files': [
          {
            'name': 'f1.dat',
            'sizeInBytes': 500,
            'mimeType': 'application/octet-stream',
            'localPath': '/f1.dat',
          },
          {
            'name': 'f2.dat',
            'sizeInBytes': 300,
            'mimeType': 'application/octet-stream',
            'localPath': '/f2.dat',
          },
        ],
      };

      final req = TransferRequest.fromJson(json);
      expect(req.totalSizeBytes, 800);
    });

    test('copyWith creates modified clone', () {
      final request = TransferRequest(
        transferId: 'id-1',
        senderId: 's-1',
        senderName: 'Origin',
        files: files,
        totalSizeBytes: 350,
        timestamp: testDate,
      );

      final modified = request.copyWith(
        senderName: 'Updated Sender',
      );

      expect(modified.senderName, 'Updated Sender');
      expect(modified.transferId, 'id-1');
    });
  });
}

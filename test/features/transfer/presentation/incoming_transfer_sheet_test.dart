import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:nearshare/features/transfer/presentation/widgets/incoming_transfer_sheet.dart';

TransferRequest _request() {
  return TransferRequest(
    transferId: 'sheet-1',
    senderId: 'sender-device-99',
    senderName: 'John Phone',
    files: const [
      TransferFile(
        name: 'holiday_photo.jpg',
        sizeInBytes: 3145728, // 3 MB
        mimeType: 'image/jpeg',
        localPath: '/holiday_photo.jpg',
      ),
      TransferFile(
        name: 'notes.pdf',
        sizeInBytes: 1048576, // 1 MB
        mimeType: 'application/pdf',
        localPath: '/notes.pdf',
      ),
    ],
    totalSizeBytes: 4194304, // 4 MB
    timestamp: DateTime.now(),
  );
}

void main() {
  group('IncomingTransferSheet', () {
    testWidgets('Renders sender, files, countdown, Accept and Decline',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingTransferSheet(
              request: _request(),
              onAccept: () {},
              onReject: () {},
            ),
          ),
        ),
      );

      expect(find.text('John Phone'), findsOneWidget);
      expect(find.text('wants to send you 2 files'), findsOneWidget);
      expect(find.text('2 files · 4.0 MB'), findsOneWidget);
      expect(find.text('holiday_photo.jpg'), findsOneWidget);
      expect(find.text('notes.pdf'), findsOneWidget);
      expect(find.textContaining('Auto-declines in'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('Accept fires the accept callback', (tester) async {
      var accepted = false;
      var rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingTransferSheet(
              request: _request(),
              onAccept: () => accepted = true,
              onReject: () => rejected = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Accept'));

      expect(accepted, isTrue);
      expect(rejected, isFalse);
    });

    testWidgets('Decline fires the reject callback', (tester) async {
      var accepted = false;
      var rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingTransferSheet(
              request: _request(),
              onAccept: () => accepted = true,
              onReject: () => rejected = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Decline'));

      expect(rejected, isTrue);
      expect(accepted, isFalse);
    });

    testWidgets('Auto-declines after 60 untouched seconds', (tester) async {
      var rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingTransferSheet(
              request: _request(),
              onAccept: () {},
              onReject: () => rejected = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 59));
      expect(rejected, isFalse);

      await tester.pump(const Duration(seconds: 2));
      expect(rejected, isTrue);
    });
  });
}

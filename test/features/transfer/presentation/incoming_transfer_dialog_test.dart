import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:nearshare/features/transfer/presentation/widgets/incoming_transfer_dialog.dart';

void main() {
  group('IncomingTransferDialog Widget Tests', () {
    testWidgets('Renders sender name, file details, Accept and Decline buttons', (tester) async {
      bool accepted = false;
      bool rejected = false;

      final request = TransferRequest(
        transferId: 'dlg-1',
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingTransferDialog(
              request: request,
              onAccept: () => accepted = true,
              onReject: () => rejected = true,
            ),
          ),
        ),
      );

      expect(find.text('Incoming Transfer'), findsOneWidget);
      expect(find.text('From John Phone'), findsOneWidget);
      expect(find.text('2 files'), findsOneWidget);
      expect(find.text('4.0 MB'), findsOneWidget);
      expect(find.text('holiday_photo.jpg'), findsOneWidget);
      expect(find.text('notes.pdf'), findsOneWidget);

      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);

      // Tap Accept
      await tester.tap(find.text('Accept'));
      expect(accepted, isTrue);

      // Tap Decline
      await tester.tap(find.text('Decline'));
      expect(rejected, isTrue);
    });
  });
}

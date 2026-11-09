import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';
import 'package:nearshare/features/history/presentation/history_item_widget.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';
import 'package:nearshare/shared/utils/formatters.dart';

TransferRecord record({
  required String transferId,
  required String peerName,
  TransferDirection direction = TransferDirection.sending,
  TransferRecordStatus status = TransferRecordStatus.completed,
  int totalFiles = 3,
  int totalSizeBytes = 5 * 1024 * 1024,
  DateTime? timestamp,
}) {
  return TransferRecord(
    transferId: transferId,
    direction: direction,
    peerDeviceId: 'peer-1',
    peerDeviceName: peerName,
    totalFiles: totalFiles,
    totalSizeBytes: totalSizeBytes,
    status: status,
    timestamp: timestamp ?? DateTime(2026, 1, 1, 14, 30),
    completedAt: DateTime(2026, 1, 1, 14, 31),
    files: List.generate(
      totalFiles,
      (i) => TransferFileRecord(
        fileName: 'file-$i.bin',
        fileSizeBytes: totalSizeBytes ~/ totalFiles,
        mimeType: 'application/octet-stream',
        localPath: '/tmp/file-$i.bin',
        status: TransferRecordStatus.completed,
      ),
    ),
  );
}

Future<void> pumpItem(
  WidgetTester tester,
  TransferRecord record, {
  bool canResend = true,
  VoidCallback? onTap,
  VoidCallback? onDelete,
  VoidCallback? onResend,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HistoryItemWidget(
          record: record,
          canResend: canResend,
          onTap: onTap,
          onDelete: onDelete,
          onResend: onResend,
        ),
      ),
    ),
  );
}

void main() {
  group('HistoryItemWidget', () {
    testWidgets('shows the direction, device name and file count',
        (tester) async {
      await pumpItem(tester, record(transferId: 'i1', peerName: 'Sara'));

      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('Sent · 3 files · 5.0 MB'), findsOneWidget);
      expect(find.text('Completed · 01/01/2026'), findsOneWidget);
      expect(find.byIcon(Icons.north_east), findsOneWidget);
    });

    testWidgets('uses the received styling for inbound transfers',
        (tester) async {
      await pumpItem(
        tester,
        record(
          transferId: 'i2',
          peerName: 'Omar',
          direction: TransferDirection.receiving,
          totalFiles: 1,
          totalSizeBytes: 2048,
        ),
      );

      expect(find.text('Omar'), findsOneWidget);
      expect(find.text('Received · 1 file · 2.0 KB'), findsOneWidget);
      expect(find.byIcon(Icons.south_west), findsOneWidget);
    });

    testWidgets('labels failed and cancelled transfers', (tester) async {
      await pumpItem(
        tester,
        record(
          transferId: 'i3',
          peerName: 'Broken',
          status: TransferRecordStatus.failed,
        ),
      );
      expect(find.text('Failed · 01/01/2026'), findsOneWidget);

      await pumpItem(
        tester,
        record(
          transferId: 'i4',
          peerName: 'Cancelled',
          status: TransferRecordStatus.cancelled,
        ),
      );
      expect(find.text('Cancelled · 01/01/2026'), findsOneWidget);
    });

    testWidgets('tapping the row fires onTap', (tester) async {
      var tapped = 0;
      await pumpItem(
        tester,
        record(transferId: 'i5', peerName: 'Tap'),
        onTap: () => tapped++,
      );

      await tester.tap(find.byType(HistoryItemWidget));
      expect(tapped, 1);
    });

    testWidgets('swiping left asks for confirmation then deletes',
        (tester) async {
      var deleted = 0;
      await pumpItem(
        tester,
        record(transferId: 'i6', peerName: 'Deletable'),
        onDelete: () => deleted++,
      );

      await tester.drag(find.byType(HistoryItemWidget), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete transfer history?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(deleted, 0);

      await tester.drag(find.byType(HistoryItemWidget), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('swiping right triggers resend without dismissing the row',
        (tester) async {
      var resent = 0;
      await pumpItem(
        tester,
        record(transferId: 'i7', peerName: 'Resend'),
        onResend: () => resent++,
      );

      await tester.drag(find.byType(HistoryItemWidget), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(resent, 1);
      expect(find.byType(HistoryItemWidget), findsOneWidget);
    });

    testWidgets('exposes a descriptive semantics label and actions',
        (tester) async {
      final item = record(transferId: 'i9', peerName: 'Sara');
      final semantics = tester.ensureSemantics();
      await pumpItem(
        tester,
        item,
        onTap: () {},
        onDelete: () {},
        onResend: () {},
      );

      final label = 'Sent to Sara, '
          '${fileCountLabel(item.totalFiles, item.totalSizeBytes)}, '
          'Completed, ${formatTimestamp(item.timestamp)}';
      expect(find.bySemanticsLabel(label), findsOneWidget);

      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      semantics.dispose();
    });

    testWidgets('received rows cannot be swiped to resend', (tester) async {
      var resent = 0;
      await pumpItem(
        tester,
        record(
          transferId: 'i8',
          peerName: 'Inbound',
          direction: TransferDirection.receiving,
        ),
        canResend: false,
        onResend: () => resent++,
      );

      await tester.drag(find.byType(HistoryItemWidget), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(resent, 0);
      expect(find.byType(HistoryItemWidget), findsOneWidget);
    });
  });
}

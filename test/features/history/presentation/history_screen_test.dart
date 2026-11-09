import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/history/data/history_repository.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';
import 'package:nearshare/features/history/presentation/history_screen.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

TransferRecord record({
  required String transferId,
  required String peerName,
  required DateTime timestamp,
  TransferDirection direction = TransferDirection.sending,
  int totalFiles = 2,
  int totalSizeBytes = 5 * 1024 * 1024,
  TransferRecordStatus status = TransferRecordStatus.completed,
  String peerId = 'peer-1',
  List<TransferFileRecord>? files,
}) {
  return TransferRecord(
    transferId: transferId,
    direction: direction,
    peerDeviceId: peerId,
    peerDeviceName: peerName,
    totalFiles: totalFiles,
    totalSizeBytes: totalSizeBytes,
    status: status,
    timestamp: timestamp,
    completedAt: timestamp.add(const Duration(minutes: 1)),
    files: files ??
        List.generate(
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

Future<void> pumpHistory(
  WidgetTester tester,
  InMemoryHistoryRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        historyRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: HistoryScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('HistoryScreen', () {
    late InMemoryHistoryRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = InMemoryHistoryRepository();
    });

    testWidgets('shows the empty state when there is no history',
        (tester) async {
      await pumpHistory(tester, repository);

      expect(find.text('No transfer history yet'), findsOneWidget);
      expect(
        find.text('Files you send or receive will show up here.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('history-list')), findsNothing);
    });

    testWidgets('renders every record with its peer, count and size',
        (tester) async {
      await repository.saveTransferRecord(
        record(
          transferId: 'h1',
          peerName: 'Laptop',
          timestamp: DateTime(2026, 1, 2, 14, 30),
        ),
      );
      await repository.saveTransferRecord(
        record(
          transferId: 'h2',
          peerName: 'Tablet',
          direction: TransferDirection.receiving,
          totalFiles: 1,
          totalSizeBytes: 2048,
          timestamp: DateTime(2026, 1, 1, 9),
        ),
      );

      await pumpHistory(tester, repository);

      expect(find.byKey(const Key('history-list')), findsOneWidget);
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Sent · 2 files · 5.0 MB'), findsOneWidget);
      expect(find.text('Received · 1 file · 2.0 KB'), findsOneWidget);
      expect(find.text('Completed · 02/01/2026'), findsOneWidget);
      expect(find.text('No transfer history yet'), findsNothing);
    });

    testWidgets('filter chips narrow the list to sent or received',
        (tester) async {
      await repository.saveTransferRecord(
        record(transferId: 's1', peerName: 'Laptop', timestamp: DateTime(2026, 1, 2)),
      );
      await repository.saveTransferRecord(
        record(
          transferId: 'r1',
          peerName: 'Tablet',
          direction: TransferDirection.receiving,
          timestamp: DateTime(2026, 1, 1),
        ),
      );

      await pumpHistory(tester, repository);
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Tablet'), findsOneWidget);

      await tester.tap(find.text('Sent'));
      await tester.pumpAndSettle();
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);

      await tester.tap(find.text('Received'));
      await tester.pumpAndSettle();
      expect(find.text('Laptop'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Tablet'), findsOneWidget);
    });

    testWidgets('search matches a file name and shows the filtered empty state',
        (tester) async {
      await repository.saveTransferRecord(
        record(
          transferId: 's1',
          peerName: 'Laptop',
          timestamp: DateTime(2026, 1, 1),
          totalFiles: 1,
          files: const [
            TransferFileRecord(
              fileName: 'holiday.jpg',
              fileSizeBytes: 100,
              mimeType: 'image/jpeg',
              localPath: '/tmp/holiday.jpg',
              status: TransferRecordStatus.completed,
            ),
          ],
        ),
      );

      await pumpHistory(tester, repository);

      await tester.enterText(
        find.byKey(const Key('history-search-field')),
        'holiday',
      );
      await tester.pumpAndSettle();
      expect(find.text('Laptop'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('history-search-field')),
        'nothing-matches',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching transfers'), findsOneWidget);
      expect(find.text('Laptop'), findsNothing);
    });

    testWidgets('swiping a record deletes it from the list and the store',
        (tester) async {
      await repository.saveTransferRecord(
        record(transferId: 'del', peerName: 'Laptop', timestamp: DateTime(2026, 1, 1)),
      );
      await repository.saveTransferRecord(
        record(
          transferId: 'keep',
          peerName: 'Tablet',
          timestamp: DateTime(2026, 1, 2),
        ),
      );

      await pumpHistory(tester, repository);
      expect(find.text('Laptop'), findsOneWidget);

      await tester.drag(find.byKey(const Key('item-del')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete transfer history?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await repository.getRecordById('del'), isNull);
      expect(find.text('Laptop'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
    });

    testWidgets('clearing all history brings back the empty state',
        (tester) async {
      await repository.saveTransferRecord(
        record(transferId: 'a', peerName: 'Laptop', timestamp: DateTime(2026, 1, 1)),
      );
      await repository.saveTransferRecord(
        record(transferId: 'b', peerName: 'Tablet', timestamp: DateTime(2026, 1, 2)),
      );

      await pumpHistory(tester, repository);
      expect(find.byKey(const Key('history-list')), findsOneWidget);

      await tester.tap(find.byTooltip('History options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear all history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(await repository.getAllRecords().first, isEmpty);
      expect(find.text('No transfer history yet'), findsOneWidget);
      expect(find.byKey(const Key('history-list')), findsNothing);
    });

    testWidgets('a received transfer does not offer a resend affordance',
        (tester) async {
      await repository.saveTransferRecord(
        record(
          transferId: 'recv-1',
          peerName: 'Tablet',
          direction: TransferDirection.receiving,
          timestamp: DateTime(2026, 1, 1),
        ),
      );

      await pumpHistory(tester, repository);

      await tester.drag(find.byKey(const Key('item-recv-1')), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Refresh'), findsNothing);
      expect(find.byKey(const Key('item-recv-1')), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/history/data/history_providers.dart';
import 'package:nearshare/features/history/data/history_repository.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';
import 'package:nearshare/features/history/presentation/history_detail_screen.dart';
import 'package:nearshare/shared/utils/file_launcher.dart';

class _RecordingLauncher implements FileLauncher {
  final List<String> openedFiles = [];
  final List<String> openedFolders = [];

  @override
  Future<bool> openFile(String path) async {
    openedFiles.add(path);
    return true;
  }

  @override
  Future<bool> openFolder(String path) async {
    openedFolders.add(path);
    return true;
  }
}

TransferRecord sentRecord({
  String transferId = 'detail-1',
  List<TransferFileRecord>? files,
}) {
  return TransferRecord(
    transferId: transferId,
    direction: TransferDirection.sending,
    peerDeviceId: 'peer-1',
    peerDeviceName: 'Laptop',
    totalFiles: files?.length ?? 2,
    totalSizeBytes: 3072,
    status: TransferRecordStatus.completed,
    timestamp: DateTime(2026, 1, 1, 14, 30),
    completedAt: DateTime(2026, 1, 1, 14, 31),
    files: files ??
        const [
          TransferFileRecord(
            fileName: 'report.pdf',
            fileSizeBytes: 1024,
            mimeType: 'application/pdf',
            localPath: '/tmp/report.pdf',
            status: TransferRecordStatus.completed,
          ),
          TransferFileRecord(
            fileName: 'holiday.jpg',
            fileSizeBytes: 2048,
            mimeType: 'image/jpeg',
            localPath: '/tmp/holiday.jpg',
            status: TransferRecordStatus.completed,
          ),
        ],
  );
}

TransferRecord receivedRecord() {
  return TransferRecord(
    transferId: 'detail-recv',
    direction: TransferDirection.receiving,
    peerDeviceId: 'peer-2',
    peerDeviceName: 'Tablet',
    totalFiles: 1,
    totalSizeBytes: 512,
    status: TransferRecordStatus.completed,
    timestamp: DateTime(2026, 1, 2, 9),
    completedAt: DateTime(2026, 1, 2, 9, 1),
    files: const [
      TransferFileRecord(
        fileName: 'photo.png',
        fileSizeBytes: 512,
        mimeType: 'image/png',
        localPath: '/downloads/photo.png',
        status: TransferRecordStatus.completed,
      ),
    ],
  );
}

Future<void> pumpDetail(
  WidgetTester tester,
  InMemoryHistoryRepository repository, {
  required String transferId,
  FileLauncher? launcher,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [historyRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: HistoryDetailScreen(
          transferId: transferId,
          launcher: launcher ?? const FileLauncher(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('HistoryDetailScreen', () {
    late InMemoryHistoryRepository repository;

    setUp(() {
      repository = InMemoryHistoryRepository();
    });

    testWidgets('lists every file with its size and type', (tester) async {
      await repository.saveTransferRecord(sentRecord());

      await pumpDetail(tester, repository, transferId: 'detail-1');

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.text('holiday.jpg'), findsOneWidget);
      expect(find.text('1.0 KB · Document'), findsOneWidget);
      expect(find.text('2.0 KB · Image'), findsOneWidget);
      expect(find.text('Sent · 2 files · 3.0 KB'), findsOneWidget);
    });

    testWidgets('a sent record offers a Resend button', (tester) async {
      await repository.saveTransferRecord(sentRecord());

      await pumpDetail(tester, repository, transferId: 'detail-1');

      expect(find.text('Resend'), findsOneWidget);
      expect(find.text('Open File'), findsNothing);
      expect(find.text('Open Folder'), findsNothing);
    });

    testWidgets('a received record offers Open File and Open Folder',
        (tester) async {
      await repository.saveTransferRecord(receivedRecord());
      final launcher = _RecordingLauncher();

      await pumpDetail(
        tester,
        repository,
        transferId: 'detail-recv',
        launcher: launcher,
      );

      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('photo.png'), findsOneWidget);
      expect(find.text('Open File'), findsOneWidget);
      expect(find.text('Open Folder'), findsOneWidget);
      expect(find.text('Resend'), findsNothing);

      await tester.tap(find.text('Open File'));
      await tester.pumpAndSettle();
      expect(launcher.openedFiles, ['/downloads/photo.png']);

      await tester.tap(find.text('Open Folder'));
      await tester.pumpAndSettle();
      expect(launcher.openedFolders, ['/downloads/photo.png']);
    });

    testWidgets('shows the status badge and timestamps', (tester) async {
      await repository.saveTransferRecord(sentRecord());

      await pumpDetail(tester, repository, transferId: 'detail-1');

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Started 01/01/2026'), findsOneWidget);
      expect(find.text('Finished 01/01/2026'), findsOneWidget);
    });

    testWidgets('an unknown transfer id reports that it is gone',
        (tester) async {
      await pumpDetail(tester, repository, transferId: 'does-not-exist');

      expect(find.text('This transfer no longer exists.'), findsOneWidget);
    });

    testWidgets('a failed file is labelled as incomplete', (tester) async {
      await repository.saveTransferRecord(
        sentRecord(
          files: const [
            TransferFileRecord(
              fileName: 'broken.bin',
              fileSizeBytes: 100,
              mimeType: 'application/octet-stream',
              localPath: '/tmp/broken.bin',
              status: TransferRecordStatus.failed,
            ),
          ],
        ),
      );

      await pumpDetail(tester, repository, transferId: 'detail-1');

      expect(find.text('100 B · File · incomplete'), findsOneWidget);
    });
  });
}

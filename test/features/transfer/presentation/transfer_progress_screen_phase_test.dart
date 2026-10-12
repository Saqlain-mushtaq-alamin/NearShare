import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_session_repository.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';
import 'package:nearshare/features/transfer/presentation/transfer_progress_screen.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';
import 'package:nearshare/features/transfer/presentation/transfer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestTransferNotifier extends TransferNotifier {
  _TestTransferNotifier(super.manager, super.identityService);

  void seed(TransferState next) => state = next;
}

void main() {
  group('TransferProgressScreen resumable phases', () {
    late Directory tempDir;
    late TransferManager manager;
    late _TestTransferNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('progress_phase_');
      manager = TransferManager(
        client: TransferClient(),
        storageService: FileStorageService(customDownloadPath: tempDir.path),
        sessionRepository: InMemoryTransferSessionRepository(),
      );
      final identityService =
          DeviceIdentityService(prefs: await SharedPreferences.getInstance());
      notifier = _TestTransferNotifier(manager, identityService);
    });

    tearDown(() async {
      notifier.dispose();
      await manager.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    TransferProgress buildProgress({
      TransferPhase phase = TransferPhase.normal,
      TransferStatus status = TransferStatus.inProgress,
      int? currentChunk,
      int? totalChunks,
    }) {
      return TransferProgress(
        transferId: 'phase-1',
        currentFileIndex: 0,
        totalFiles: 2,
        bytesTransferred: 2048,
        totalBytes: 4096,
        speedBps: 1024,
        status: status,
        currentFileName: 'holiday.mp4',
        phase: phase,
        currentChunk: currentChunk,
        totalChunks: totalChunks,
      );
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transferStateProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: TransferProgressScreen(transferId: 'phase-1'),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the resuming state while chunks are being replayed',
        (tester) async {
      notifier.seed(
        TransferState(
          activeProgress: buildProgress(
            phase: TransferPhase.resuming,
            currentChunk: 2,
            totalChunks: 8,
          ),
        ),
      );
      await pumpScreen(tester);

      expect(find.text('Resuming'), findsOneWidget);
      expect(find.text('Resuming transfer...'), findsOneWidget);
      expect(find.text('Chunk 3/8'), findsOneWidget);
    });

    testWidgets('shows the connection lost state and keeps the transfer open',
        (tester) async {
      notifier.seed(
        TransferState(
          activeProgress: buildProgress(phase: TransferPhase.connectionLost),
        ),
      );
      await pumpScreen(tester);

      expect(find.text('Paused'), findsOneWidget);
      expect(
        find.text('Connection lost â€” will resume when device is found'),
        findsOneWidget,
      );
      // The screen must stay on the transfer instead of navigating away.
      expect(find.byType(TransferProgressScreen), findsOneWidget);
      expect(find.text('Cancel Transfer'), findsOneWidget);
    });

    testWidgets('normal transfers keep the plain transferring label',
        (tester) async {
      notifier.seed(TransferState(activeProgress: buildProgress()));
      await pumpScreen(tester);

      expect(find.text('Transferring'), findsOneWidget);
      expect(find.textContaining('Chunk '), findsNothing);
    });
  });
}

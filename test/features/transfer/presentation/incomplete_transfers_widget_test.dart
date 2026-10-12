import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_session_repository.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';
import 'package:nearshare/features/transfer/presentation/transfer_state.dart';
import 'package:nearshare/features/transfer/presentation/widgets/incomplete_transfers_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestTransferNotifier extends TransferNotifier {
  _TestTransferNotifier(super.manager, super.identityService);

  void seed(TransferState next) => state = next;
}

void main() {
  group('IncompleteTransfersWidget', () {
    late Directory tempDir;
    late InMemoryTransferSessionRepository repository;
    late TransferManager manager;
    late _TestTransferNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('incomplete_widget_');
      repository = InMemoryTransferSessionRepository();
      manager = TransferManager(
        client: TransferClient(),
        storageService: FileStorageService(customDownloadPath: tempDir.path),
        sessionRepository: repository,
      );
      final identityService =
          DeviceIdentityService(prefs: await SharedPreferences.getInstance());
      notifier = _TestTransferNotifier(manager, identityService);
    });

    tearDown(() async {
      // ProviderScope owns the notifier lifecycle.
      await manager.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    TransferSession pausedSend({String transferId = 'inc-1', String peer = 'Sara'}) {
      return TransferSession(
        transferId: transferId,
        peerId: 'peer-$peer',
        peerName: peer,
        peerIp: '192.168.1.15',
        peerPort: 53317,
        direction: TransferDirection.sending,
        status: TransferSessionStatus.paused,
        files: const [
          TransferFile(
            name: 'holiday.mp4',
            sizeInBytes: 5 * 1024 * 1024,
            mimeType: 'video/mp4',
            localPath: '/holiday.mp4',
          ),
          TransferFile(
            name: 'notes.txt',
            sizeInBytes: 2048,
            mimeType: 'text/plain',
            localPath: '/notes.txt',
          ),
        ],
        chunkSize: 1024 * 1024,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        lastActivityAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
    }

    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transferStateProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: Scaffold(body: IncompleteTransfersWidget()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders nothing when there are no incomplete transfers',
        (tester) async {
      await pumpWidget(tester);

      expect(find.text('Unfinished transfers'), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('lists every resumable send with its peer and size',
        (tester) async {
      final session = pausedSend();
      await repository.saveSession(session);
      notifier.seed(TransferState(incompleteSessions: [session]));
      await pumpWidget(tester);

      expect(find.text('Unfinished transfers'), findsOneWidget);
      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('2 file(s) · 5.0 MB · Paused'), findsOneWidget);
    });

    testWidgets('hides receiving sessions that the peer still owns',
        (tester) async {
      final incoming = pausedSend(transferId: 'inc-2').copyWith(
        direction: TransferDirection.receiving,
      );
      notifier.seed(TransferState(incompleteSessions: [incoming]));
      await pumpWidget(tester);

      expect(find.text('Unfinished transfers'), findsNothing);
    });

    testWidgets('discard asks for confirmation and deletes the session',
        (tester) async {
      final session = pausedSend();
      await repository.saveSession(session);
      notifier.seed(TransferState(incompleteSessions: [session]));
      await pumpWidget(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Discard transfer?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(await repository.getSession(session.transferId), isNull);
      expect(find.text('Unfinished transfers'), findsNothing);
    });

    testWidgets('keeping the transfer leaves the session alone',
        (tester) async {
      final session = pausedSend();
      await repository.saveSession(session);
      notifier.seed(TransferState(incompleteSessions: [session]));
      await pumpWidget(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      expect(await repository.getSession(session.transferId), isNotNull);
      expect(find.text('Unfinished transfers'), findsOneWidget);
    });

    testWidgets('resume button is shown for a session with a known address',
        (tester) async {
      final session = pausedSend();
      notifier.seed(TransferState(incompleteSessions: [session]));
      await pumpWidget(tester);

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}

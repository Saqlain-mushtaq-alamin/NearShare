import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/discovery/domain/discovery_state.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:nearshare/features/history/data/history_repository.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';
import 'package:nearshare/features/home/presentation/home_screen.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';
import 'package:nearshare/features/transfer/presentation/transfer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/presentation_stubs.dart';

Device _localDevice() => Device(
      id: 'local-1',
      name: 'My Test Phone',
      platform: 'android',
      ipAddress: '192.168.1.10',
      port: 53317,
      discoveredAt: DateTime(2026, 1, 1),
    );

DiscoveryState _homeDiscoveryState({
  bool broadcasting = true,
  List<Device> devices = const [],
}) {
  return DiscoveryState(
    status: DiscoveryStatus.scanning,
    isBroadcasting: broadcasting,
    localDevice: _localDevice(),
    devices: devices,
  );
}

TransferRecord _historyRecord() {
  return TransferRecord(
    transferId: 'home-1',
    direction: TransferDirection.sending,
    peerDeviceId: 'peer-1',
    peerDeviceName: 'Sara\u2019s Laptop',
    totalFiles: 2,
    totalSizeBytes: 5 * 1024 * 1024,
    status: TransferRecordStatus.completed,
    timestamp: DateTime(2026, 1, 1, 9, 30),
    completedAt: DateTime(2026, 1, 1, 9, 31),
    files: const [],
  );
}

TransferSession _pausedSend() {
  return TransferSession(
    transferId: 'paused-1',
    peerId: 'peer-1',
    peerName: 'Sara\u2019s Laptop',
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
    ],
    chunkSize: 1024 * 1024,
    startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    lastActivityAt: DateTime.now().subtract(const Duration(minutes: 1)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryHistoryRepository repository;
  late TestTransferHarness harness;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = InMemoryHistoryRepository();
    harness = await createTestTransferHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    DiscoveryState? discoveryState,
    TransferState? transferState,
    bool seedHistory = false,
  }) async {
    if (transferState != null) {
      harness.notifier.seed(transferState);
    }
    if (seedHistory) {
      await repository.saveTransferRecord(_historyRecord());
    }

    // Tall surface so off-screen ListView sections (recent transfers) are built.
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryStateProvider.overrideWith(
            (ref) => StaticDiscoveryNotifier(
              discoveryState ?? _homeDiscoveryState(),
            ),
          ),
          historyRepositoryProvider.overrideWithValue(repository),
          transferStateProvider.overrideWith((ref) => harness.notifier),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('HomeScreen', () {
    testWidgets(
        'renders the send card, receive indicator, local device, and devices section',
        (tester) async {
      await pumpHome(tester);

      expect(find.text('Send files'), findsOneWidget);
      expect(find.text('Ready to receive'), findsOneWidget);
      expect(find.text('My Test Phone'), findsOneWidget);
      expect(find.text('This device · ANDROID'), findsOneWidget);
      expect(find.text('Nearby Devices'), findsOneWidget);
      expect(find.text('Recent transfers'), findsNothing);
    });

    testWidgets('lists recent transfers with a See all link', (tester) async {
      await pumpHome(tester, seedHistory: true);

      expect(find.text('Recent transfers'), findsOneWidget);
      expect(find.text('Sara\u2019s Laptop'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('shows the paused-transfer banner when a send is incomplete',
        (tester) async {
      await pumpHome(
        tester,
        transferState: TransferState(
          incompleteSessions: [_pausedSend()],
        ),
      );

      expect(
        find.text('1 transfer paused — resume or discard below'),
        findsOneWidget,
      );
      expect(find.text('Unfinished transfers'), findsOneWidget);
    });

    testWidgets('no banner when everything is finished', (tester) async {
      await pumpHome(tester, transferState: const TransferState());

      expect(find.textContaining('paused'), findsNothing);
    });

    testWidgets('shows the scanning empty state when no devices are nearby',
        (tester) async {
      await pumpHome(tester);

      expect(find.text('Scanning local Wi-Fi...'), findsOneWidget);
      expect(
        find.text(
          'Ensure other devices are connected to the same Wi-Fi network and have NearShare open.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('receiving indicator reflects a paused server', (tester) async {
      await pumpHome(tester, discoveryState: _homeDiscoveryState(broadcasting: false));

      expect(find.text('Receiving is paused'), findsOneWidget);
      expect(find.text('Ready to receive'), findsNothing);
    });
  });
}

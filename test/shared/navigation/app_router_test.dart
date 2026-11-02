import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/app.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:nearshare/features/history/data/history_repository.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';
import 'package:nearshare/features/onboarding/application/onboarding_provider.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/merge_space_test_helpers.dart';
import '../../helpers/presentation_stubs.dart';

TransferRecord historyEntry() {
  return TransferRecord(
    transferId: 'nav-1',
    direction: TransferDirection.sending,
    peerDeviceId: 'peer-1',
    peerDeviceName: 'Laptop',
    totalFiles: 1,
    totalSizeBytes: 1024,
    status: TransferRecordStatus.completed,
    timestamp: DateTime(2026, 1, 1, 12),
    completedAt: DateTime(2026, 1, 1, 12, 1),
    files: const [
      TransferFileRecord(
        fileName: 'nav.txt',
        fileSizeBytes: 1024,
        mimeType: 'text/plain',
        localPath: '/tmp/nav.txt',
        status: TransferRecordStatus.completed,
      ),
    ],
  );
}

/// Finds a destination icon scoped to the bottom [NavigationBar] so screen
/// content (empty-state icons, AppBar titles) cannot collide.
Finder navIcon(IconData icon) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byIcon(icon),
  );
}

void main() {
  group('App navigation', () {
    late InMemoryHistoryRepository repository;
    late TestTransferHarness harness;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        OnboardingKeys.complete: true,
      });
      repository = InMemoryHistoryRepository();
      harness = await createTestTransferHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      // Tall phone surface so Settings' off-screen rows are built.
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWithValue(repository),
            discoveryStateProvider.overrideWith(
              (ref) => StaticDiscoveryNotifier(emptyDiscoveryState()),
            ),
            transferStateProvider.overrideWith((ref) => harness.notifier),
            deviceIdentityServiceProvider
                .overrideWithValue(FakeDeviceIdentityService()),
            mergeSpaceTestOverride(),
          ],
          child: const NearShareApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows a bottom navigation bar with five tabs', (tester) async {
      await pumpApp(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('Merge'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tapping History opens the history screen', (tester) async {
      await pumpApp(tester);

      await tester.tap(navIcon(Icons.history_outlined));
      await tester.pumpAndSettle();

      expect(find.text('No transfer history yet'), findsOneWidget);
    });

    testWidgets('tapping a history entry opens its detail screen',
        (tester) async {
      await repository.saveTransferRecord(historyEntry());
      await pumpApp(tester);

      await tester.tap(navIcon(Icons.history_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Laptop'), findsOneWidget);

      await tester.tap(find.text('Laptop'));
      await tester.pumpAndSettle();

      expect(find.text('nav.txt'), findsOneWidget);
      expect(find.text('Resend'), findsOneWidget);
    });

    testWidgets('Rooms and Settings tabs render their screens',
        (tester) async {
      await pumpApp(tester);

      await tester.tap(navIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Share with the whole room'), findsOneWidget);
      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('Join Room'), findsOneWidget);

      await tester.tap(navIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Transfer history'), findsOneWidget);
      expect(find.text('Clear transfer history'), findsOneWidget);
    });

    testWidgets('Settings links through to the history screen', (tester) async {
      await pumpApp(tester);

      await tester.tap(navIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transfer history'));
      await tester.pumpAndSettle();

      expect(find.text('No transfer history yet'), findsOneWidget);
    });
  });

  group('Onboarding redirect', () {
    late InMemoryHistoryRepository repository;
    late TestTransferHarness harness;

    setUp(() async {
      repository = InMemoryHistoryRepository();
      harness = await createTestTransferHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWithValue(repository),
            discoveryStateProvider.overrideWith(
              (ref) => StaticDiscoveryNotifier(emptyDiscoveryState()),
            ),
            transferStateProvider.overrideWith((ref) => harness.notifier),
            deviceIdentityServiceProvider
                .overrideWithValue(FakeDeviceIdentityService()),
            mergeSpaceTestOverride(),
          ],
          child: const NearShareApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('first launch is redirected to onboarding', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await pumpApp(tester);

      expect(find.byKey(const Key('onboarding-get-started')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('a completed onboarding is bypassed', (tester) async {
      SharedPreferences.setMockInitialValues({
        OnboardingKeys.complete: true,
      });

      await pumpApp(tester);

      expect(find.byKey(const Key('onboarding-get-started')), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Send files'), findsOneWidget);
    });
  });
}

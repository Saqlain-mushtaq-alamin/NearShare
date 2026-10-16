import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/app.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:nearshare/features/history/data/history_repository.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/presentation_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NearShareApp', () {
    late TestTransferHarness harness;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'nearshare_onboarding_complete': true,
      });
      // Real IO (temp dir) must happen outside the test body's FakeAsync zone.
      harness = await createTestTransferHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    testWidgets('renders the home shell', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider
                .overrideWithValue(InMemoryHistoryRepository()),
            discoveryStateProvider.overrideWith(
              (ref) => StaticDiscoveryNotifier(emptyDiscoveryState()),
            ),
            transferStateProvider.overrideWith((ref) => harness.notifier),
            deviceIdentityServiceProvider
                .overrideWithValue(FakeDeviceIdentityService()),
          ],
          child: const NearShareApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NearShare'), findsWidgets);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Send files'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:nearshare/features/history/data/history_providers.dart';
import 'package:nearshare/features/history/data/history_repository.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';
import 'package:nearshare/features/settings/application/settings_provider.dart';
import 'package:nearshare/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/presentation_stubs.dart';

TransferRecord _record() {
  return TransferRecord(
    transferId: 'set-1',
    direction: TransferDirection.sending,
    peerDeviceId: 'peer-1',
    peerDeviceName: 'Laptop',
    totalFiles: 1,
    totalSizeBytes: 2048,
    status: TransferRecordStatus.completed,
    timestamp: DateTime(2026, 1, 1, 12),
    completedAt: DateTime(2026, 1, 1, 12, 1),
    files: const [
      TransferFileRecord(
        fileName: 'notes.txt',
        fileSizeBytes: 2048,
        mimeType: 'text/plain',
        localPath: '/tmp/notes.txt',
        status: TransferRecordStatus.completed,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen', () {
    late InMemoryHistoryRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = InMemoryHistoryRepository();
    });

    Future<ProviderContainer> pumpSettings(WidgetTester tester) async {
      // A phone-tall surface so the whole settings list is built at once —
      // the lazy ListView otherwise drops off-screen rows between finds.
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWithValue(repository),
            deviceIdentityServiceProvider
                .overrideWithValue(FakeDeviceIdentityService()),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
    }

    testWidgets('renders every settings section', (tester) async {
      await pumpSettings(tester);

      for (final section in [
        'DEVICE',
        'STORAGE',
        'TRANSFER',
        'APP',
        'DATA',
        'ABOUT',
      ]) {
        expect(find.text(section), findsOneWidget);
      }
      expect(find.text('Device name'), findsOneWidget);
      expect(find.text('Save location'), findsOneWidget);
      expect(find.text('Auto-accept known devices'), findsOneWidget);
      expect(find.text('Encrypt transfers'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Transfer history'), findsOneWidget);
      expect(find.text('Clear transfer history'), findsOneWidget);
      expect(find.text('Clear cache'), findsOneWidget);
      expect(
        find.text('We don\u2019t collect your data. Full stop.'),
        findsOneWidget,
      );
      expect(find.text('Version'), findsOneWidget);
    });

    testWidgets('Appearance dialog switches the theme preference',
        (tester) async {
      final container = await pumpSettings(tester);
      expect(
        container.read(settingsProvider).themePreference,
        ThemePreference.system,
      );

      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(
        container.read(settingsProvider).themePreference,
        ThemePreference.dark,
      );
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('Encrypt transfers switch toggles immediately', (tester) async {
      final container = await pumpSettings(tester);
      expect(container.read(settingsProvider).transferEncryption, isTrue);

      await tester.tap(find.text('Encrypt transfers'));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).transferEncryption, isFalse);
    });

    testWidgets('Clear transfer history asks for confirmation', (tester) async {
      await repository.saveTransferRecord(_record());
      await pumpSettings(tester);

      await tester.tap(find.text('Clear transfer history'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all history?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Clear all history?'), findsNothing);
    });

    testWidgets('Confirming clear history wipes records and confirms',
        (tester) async {
      await repository.saveTransferRecord(_record());
      final container = await pumpSettings(tester);

      await tester.tap(find.text('Clear transfer history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(find.text('Transfer history cleared.'), findsOneWidget);
      final records = await repository.getAllRecords().first;
      expect(records, isEmpty);
      // Keep the container "used" for the analyzer.
      expect(container.read(settingsProvider).isLoading, isFalse);
    });
  });
}

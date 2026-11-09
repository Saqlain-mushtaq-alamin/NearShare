import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/core/utils/permission_service.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/settings/application/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsNotifier', () {
    late SharedPreferences prefs;
    late List<String> nameChanges;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      nameChanges = [];
    });

    SettingsNotifier buildNotifier({AppPlatform platform = AppPlatform.windows}) {
      return SettingsNotifier(
        prefs: prefs,
        identity: DeviceIdentityService(prefs: prefs),
        platform: platform,
        onDeviceNameChanged: nameChanges.add,
      );
    }

    test('load exposes defaults on a fresh install', () async {
      final notifier = buildNotifier();
      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.themePreference, ThemePreference.system);
      expect(notifier.state.themeMode, ThemeMode.system);
      expect(notifier.state.autoAcceptKnownDevices, isFalse);
      expect(notifier.state.transferEncryption, isTrue);
      expect(notifier.state.customSaveLocation, isNull);
      expect(notifier.state.lastUsedDeviceId, isNull);
      expect(notifier.state.deviceId, isNotEmpty);
    });

    test('theme preference changes propagate to state and persist', () async {
      final notifier = buildNotifier();
      await notifier.load();

      await notifier.setThemePreference(ThemePreference.dark);

      expect(notifier.state.themePreference, ThemePreference.dark);
      expect(notifier.state.themeMode, ThemeMode.dark);
      expect(prefs.getString(SettingsKeys.themePreference), 'dark');

      // Reload from disk — the choice survives.
      final reopened = buildNotifier();
      await reopened.load();
      expect(reopened.state.themePreference, ThemePreference.dark);
    });

    test('toggle settings save and reload', () async {
      final notifier = buildNotifier();
      await notifier.load();

      await notifier.setAutoAcceptKnownDevices(true);
      await notifier.setTransferEncryption(false);

      expect(notifier.state.autoAcceptKnownDevices, isTrue);
      expect(notifier.state.transferEncryption, isFalse);
      expect(prefs.getBool(SettingsKeys.autoAccept), isTrue);
      expect(prefs.getBool(SettingsKeys.encryption), isFalse);

      final reopened = buildNotifier();
      await reopened.load();
      expect(reopened.state.autoAcceptKnownDevices, isTrue);
      expect(reopened.state.transferEncryption, isFalse);
    });

    test('device name updates identity, state, and notifies discovery',
        () async {
      final notifier = buildNotifier();
      await notifier.load();

      await notifier.setDeviceName('Studio MacBook');

      expect(notifier.state.deviceName, 'Studio MacBook');
      expect(prefs.getString('nearshare_device_name'), 'Studio MacBook');
      expect(nameChanges, ['Studio MacBook']);
    });

    test('blank device name is ignored', () async {
      final notifier = buildNotifier();
      await notifier.load();
      final original = notifier.state.deviceName;

      await notifier.setDeviceName('   ');

      expect(notifier.state.deviceName, original);
      expect(nameChanges, isEmpty);
    });

    test('save location can be set and reset to default', () async {
      final notifier = buildNotifier();
      await notifier.load();

      await notifier.setSaveLocation('/mnt/nas/transfer');
      expect(notifier.state.customSaveLocation, '/mnt/nas/transfer');
      expect(prefs.getString(SettingsKeys.saveLocation), '/mnt/nas/transfer');

      await notifier.setSaveLocation(null);
      expect(notifier.state.customSaveLocation, isNull);
      expect(prefs.containsKey(SettingsKeys.saveLocation), isFalse);
    });

    test('last used device persists for the "Last used" tag', () async {
      final notifier = buildNotifier();
      await notifier.load();

      final device = Device(
        id: 'peer-9',
        name: 'Sara\u2019s iPhone',
        platform: 'ios',
        ipAddress: '192.168.1.9',
        port: 53317,
        discoveredAt: DateTime(2026, 1, 1),
      );
      await notifier.setLastUsedDevice(device);

      expect(notifier.state.lastUsedDeviceId, 'peer-9');
      expect(notifier.state.lastUsedDeviceName, 'Sara\u2019s iPhone');

      final reopened = buildNotifier();
      await reopened.load();
      expect(reopened.state.lastUsedDeviceId, 'peer-9');
      expect(reopened.state.lastUsedDeviceName, 'Sara\u2019s iPhone');
    });

    test('needsRuntimePermissions is platform-aware', () {
      expect(
        buildNotifier(platform: AppPlatform.android).needsRuntimePermissions,
        isTrue,
      );
      expect(
        buildNotifier(platform: AppPlatform.ios).needsRuntimePermissions,
        isTrue,
      );
      expect(
        buildNotifier(platform: AppPlatform.windows).needsRuntimePermissions,
        isFalse,
      );
    });
  });

  group('ThemePreference', () {
    test('fromStorage falls back to system for junk values', () {
      expect(ThemePreference.fromStorage(null), ThemePreference.system);
      expect(ThemePreference.fromStorage('nope'), ThemePreference.system);
      expect(ThemePreference.fromStorage('light'), ThemePreference.light);
      expect(ThemePreference.fromStorage('dark'), ThemePreference.dark);
    });
  });
}

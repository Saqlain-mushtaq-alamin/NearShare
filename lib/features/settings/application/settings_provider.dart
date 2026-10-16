import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/permission_service.dart';
import '../../discovery/data/device_identity_service.dart';
import '../../discovery/domain/device.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../../transfer/data/file_storage_service.dart';

abstract final class SettingsKeys {
  static const String themePreference = 'settings_theme_preference';
  static const String autoAccept = 'settings_auto_accept_known_devices';
  static const String encryption = 'settings_transfer_encryption';
  static const String saveLocation = 'settings_save_location';
  static const String lastDeviceId = 'settings_last_device_id';
  static const String lastDeviceName = 'settings_last_device_name';
}

enum ThemePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode {
    switch (this) {
      case ThemePreference.system:
        return ThemeMode.system;
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  String get label {
    switch (this) {
      case ThemePreference.system:
        return 'System';
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
    }
  }

  static ThemePreference fromStorage(String? value) {
    return ThemePreference.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemePreference.system,
    );
  }
}

@immutable
class SettingsState {
  const SettingsState({
    this.isLoading = true,
    this.deviceName = '',
    this.deviceId = '',
    this.themePreference = ThemePreference.system,
    this.autoAcceptKnownDevices = false,
    this.transferEncryption = true,
    this.customSaveLocation,
    this.lastUsedDeviceId,
    this.lastUsedDeviceName,
  });

  final bool isLoading;
  final String deviceName;
  final String deviceId;
  final ThemePreference themePreference;
  final bool autoAcceptKnownDevices;
  final bool transferEncryption;

  /// Null means "use the app-managed default folder".
  final String? customSaveLocation;

  final String? lastUsedDeviceId;
  final String? lastUsedDeviceName;

  ThemeMode get themeMode => themePreference.themeMode;

  SettingsState copyWith({
    bool? isLoading,
    String? deviceName,
    String? deviceId,
    ThemePreference? themePreference,
    bool? autoAcceptKnownDevices,
    bool? transferEncryption,
    String? customSaveLocation,
    bool clearSaveLocation = false,
    String? lastUsedDeviceId,
    bool clearLastUsedDeviceId = false,
    String? lastUsedDeviceName,
    bool clearLastUsedDeviceName = false,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      themePreference: themePreference ?? this.themePreference,
      autoAcceptKnownDevices:
          autoAcceptKnownDevices ?? this.autoAcceptKnownDevices,
      transferEncryption: transferEncryption ?? this.transferEncryption,
      customSaveLocation: clearSaveLocation
          ? null
          : (customSaveLocation ?? this.customSaveLocation),
      lastUsedDeviceId: clearLastUsedDeviceId
          ? null
          : (lastUsedDeviceId ?? this.lastUsedDeviceId),
      lastUsedDeviceName: clearLastUsedDeviceName
          ? null
          : (lastUsedDeviceName ?? this.lastUsedDeviceName),
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier({
    SharedPreferences? prefs,
    DeviceIdentityService? identity,
    AppPlatform? platform,
    void Function(String name)? onDeviceNameChanged,
  })  : _prefs = prefs,
        _identity = identity ?? DeviceIdentityService(),
        _platform = platform ?? AppPlatform.unknown,
        _onDeviceNameChanged = onDeviceNameChanged,
        super(const SettingsState());

  final SharedPreferences? _prefs;
  final DeviceIdentityService _identity;
  final AppPlatform _platform;
  final void Function(String name)? _onDeviceNameChanged;

  /// Desktop needs no runtime permissions; surfaces a graceful row instead.
  bool get needsRuntimePermissions =>
      _platform == AppPlatform.android || _platform == AppPlatform.ios;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<void> load() async {
    final prefs = await _ensurePrefs();
    String name = '';
    String id = '';
    try {
      name = await _identity.getOrCreateDeviceName();
      id = await _identity.getOrCreateDeviceId();
    } catch (_) {
      // Identity store unavailable (e.g. headless test host) — leave blank.
    }
    if (!mounted) return;
    state = SettingsState(
      isLoading: false,
      deviceName: name,
      deviceId: id,
      themePreference:
          ThemePreference.fromStorage(prefs.getString(SettingsKeys.themePreference)),
      autoAcceptKnownDevices:
          prefs.getBool(SettingsKeys.autoAccept) ?? false,
      transferEncryption: prefs.getBool(SettingsKeys.encryption) ?? true,
      customSaveLocation: prefs.getString(SettingsKeys.saveLocation),
      lastUsedDeviceId: prefs.getString(SettingsKeys.lastDeviceId),
      lastUsedDeviceName: prefs.getString(SettingsKeys.lastDeviceName),
    );
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    state = state.copyWith(themePreference: preference);
    final prefs = await _ensurePrefs();
    await prefs.setString(SettingsKeys.themePreference, preference.name);
  }

  Future<void> setAutoAcceptKnownDevices(bool value) async {
    state = state.copyWith(autoAcceptKnownDevices: value);
    final prefs = await _ensurePrefs();
    await prefs.setBool(SettingsKeys.autoAccept, value);
  }

  Future<void> setTransferEncryption(bool value) async {
    state = state.copyWith(transferEncryption: value);
    final prefs = await _ensurePrefs();
    await prefs.setBool(SettingsKeys.encryption, value);
  }

  Future<void> setDeviceName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == state.deviceName) return;
    await _identity.setDeviceName(trimmed);
    state = state.copyWith(deviceName: trimmed);
    _onDeviceNameChanged?.call(trimmed);
  }

  Future<void> setSaveLocation(String? path) async {
    final prefs = await _ensurePrefs();
    if (path == null || path.trim().isEmpty) {
      state = state.copyWith(clearSaveLocation: true);
      await prefs.remove(SettingsKeys.saveLocation);
    } else {
      state = state.copyWith(customSaveLocation: path);
      await prefs.setString(SettingsKeys.saveLocation, path);
    }
  }

  Future<void> setLastUsedDevice(Device device) async {
    state = state.copyWith(
      lastUsedDeviceId: device.id,
      lastUsedDeviceName: device.name,
    );
    final prefs = await _ensurePrefs();
    await prefs.setString(SettingsKeys.lastDeviceId, device.id);
    await prefs.setString(SettingsKeys.lastDeviceName, device.name);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final identity = ref.watch(deviceIdentityServiceProvider);
  final platform = ref.watch(permissionServiceProvider).platform;
  return SettingsNotifier(
    identity: identity,
    platform: platform,
    onDeviceNameChanged: (name) {
      // Keep mDNS broadcast in sync with the new name.
      ref.read(discoveryStateProvider.notifier).updateLocalDeviceName(name);
    },
  )..load();
});

/// Total size of everything received into the NearShare folder.
final nearShareStorageUsageProvider = FutureProvider.autoDispose<int>((ref) async {
  final directory =
      Directory(await FileStorageService().getDownloadDirectory());
  if (!await directory.exists()) return 0;

  var total = 0;
  await for (final entity in directory.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      total += await entity.length();
    }
  }
  return total;
});

/// "1.0.0 (1)" style version string for the About section.
final appVersionProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  } catch (_) {
    return '1.0.0 (1)';
  }
});

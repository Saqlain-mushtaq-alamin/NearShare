import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// The platforms NearShare ships on today.
enum AppPlatform { android, ios, windows, macos, linux, web, unknown }

/// A single permission the app may need, with copy the UI can show verbatim.
@immutable
class PermissionRequirement {
  const PermissionRequirement({
    required this.permission,
    required this.title,
    required this.description,
    this.isCritical = true,
  });

  final Permission permission;
  final String title;
  final String description;

  /// Critical permissions gate the core send/receive flow; the rest degrade
  /// gracefully (e.g. photos denied → user can still share documents).
  final bool isCritical;
}

/// Thin seam over `permission_handler` so the mapping logic is unit-testable
/// without a device behind it.
abstract class PermissionGateway {
  Future<PermissionStatus> check(Permission permission);
  Future<PermissionStatus> request(Permission permission);
  Future<bool> openAppSettings();
}

/// Top-level escape hatch: inside [PermissionHandlerGateway] an unqualified
/// `openAppSettings()` would resolve to the (recursive) instance method.
Future<bool> _openSystemAppSettings() => openAppSettings();

/// Production gateway — straight through to the platform channels.
class PermissionHandlerGateway implements PermissionGateway {
  const PermissionHandlerGateway();

  @override
  Future<PermissionStatus> check(Permission permission) => permission.status;

  @override
  Future<PermissionStatus> request(Permission permission) => permission.request();

  @override
  Future<bool> openAppSettings() => _openSystemAppSettings();
}

/// Knows which permissions each platform needs and how to ask for them.
class PermissionService {
  PermissionService({
    PermissionGateway? gateway,
    AppPlatform? platform,
  })  : _gateway = gateway ?? const PermissionHandlerGateway(),
        _platformOverride = platform;

  final PermissionGateway _gateway;
  final AppPlatform? _platformOverride;

  AppPlatform get platform => _platformOverride ?? _currentPlatform();

  static AppPlatform _currentPlatform() {
    if (kIsWeb) return AppPlatform.web;
    try {
      if (Platform.isAndroid) return AppPlatform.android;
      if (Platform.isIOS) return AppPlatform.ios;
      if (Platform.isWindows) return AppPlatform.windows;
      if (Platform.isMacOS) return AppPlatform.macos;
      if (Platform.isLinux) return AppPlatform.linux;
    } catch (_) {
      // Unit tests on the VM without a full platform binding.
    }
    return AppPlatform.unknown;
  }

  /// Everything the app will ask for on this platform, critical first.
  List<PermissionRequirement> requirements() {
    switch (platform) {
      case AppPlatform.android:
        return const [
          PermissionRequirement(
            permission: Permission.nearbyWifiDevices,
            title: 'Nearby devices',
            description: 'Find and connect to devices on your Wi-Fi network.',
          ),
          PermissionRequirement(
            permission: Permission.photos,
            title: 'Photos and videos',
            description: 'Pick photos and videos to send.',
            isCritical: false,
          ),
          PermissionRequirement(
            permission: Permission.storage,
            title: 'Files',
            description: 'Save files you receive and pick documents to send.',
            isCritical: false,
          ),
        ];
      case AppPlatform.ios:
        return const [
          PermissionRequirement(
            permission: Permission.accessLocalNetwork,
            title: 'Local network',
            description: 'Talk to other NearShare devices on your Wi-Fi.',
          ),
          PermissionRequirement(
            permission: Permission.photos,
            title: 'Photos',
            description: 'Pick photos and videos to send.',
            isCritical: false,
          ),
        ];
      case AppPlatform.windows:
      case AppPlatform.macos:
      case AppPlatform.linux:
      case AppPlatform.web:
      case AppPlatform.unknown:
        // Desktop and web handle file access through native pickers; there is
        // nothing to pre-request. Callers get an empty list and continue.
        return const [];
    }
  }

  List<PermissionRequirement> criticalRequirements() =>
      requirements().where((r) => r.isCritical).toList();

  /// Status for every requirement, in the same order as [requirements].
  Future<Map<Permission, PermissionStatus>> statuses() async {
    final result = <Permission, PermissionStatus>{};
    for (final requirement in requirements()) {
      result[requirement.permission] = await _gateway.check(requirement.permission);
    }
    return result;
  }

  /// Requests every not-yet-granted permission. Returns the resulting status
  /// map so the UI can mark which ones succeeded.
  Future<Map<Permission, PermissionStatus>> requestAll() async {
    final result = <Permission, PermissionStatus>{};
    for (final requirement in requirements()) {
      final current = await _gateway.check(requirement.permission);
      result[requirement.permission] = current.isGranted
          ? current
          : await _gateway.request(requirement.permission);
    }
    return result;
  }

  /// True when every critical permission is granted (or when the platform
  /// requires nothing at all — desktop).
  Future<bool> hasAllCritical() async {
    final critical = criticalRequirements();
    for (final requirement in critical) {
      final status = await _gateway.check(requirement.permission);
      if (!status.isGranted) return false;
    }
    return true;
  }

  /// Whether a permission was denied with "don't ask again" — the UI should
  /// point the user at system settings instead of re-requesting.
  Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await _gateway.check(permission);
    return status.isPermanentlyDenied;
  }

  /// Opens the OS settings screen. Returns true if the platform handled it.
  Future<bool> openSettings() => _gateway.openAppSettings();
}

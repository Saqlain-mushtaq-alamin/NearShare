import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/core/utils/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

class _FakeGateway implements PermissionGateway {
  _FakeGateway({Map<Permission, PermissionStatus>? statuses})
      : statuses = {
          for (final permission in _all)
            permission: statuses?[permission] ?? PermissionStatus.denied,
        };

  static const _all = [
    Permission.nearbyWifiDevices,
    Permission.accessLocalNetwork,
    Permission.photos,
    Permission.storage,
  ];

  final Map<Permission, PermissionStatus> statuses;
  final List<Permission> requested = [];
  var openSettingsCalls = 0;

  void grant(Permission permission) {
    statuses[permission] = PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> check(Permission permission) async =>
      statuses[permission] ?? PermissionStatus.denied;

  @override
  Future<PermissionStatus> request(Permission permission) async {
    requested.add(permission);
    final next = statuses[permission] == PermissionStatus.permanentlyDenied
        ? PermissionStatus.permanentlyDenied
        : PermissionStatus.granted;
    statuses[permission] = next;
    return next;
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalls++;
    return true;
  }
}

void main() {
  group('PermissionService requirements', () {
    test('Android maps to nearby Wi-Fi (critical) plus photos and storage',
        () async {
      final service = PermissionService(
        gateway: _FakeGateway(),
        platform: AppPlatform.android,
      );

      final requirements = service.requirements();
      final critical = service.criticalRequirements();

      expect(requirements, hasLength(3));
      expect(critical, hasLength(1));
      expect(critical.single.permission, Permission.nearbyWifiDevices);
      expect(
        requirements.map((r) => r.permission),
        containsAll([Permission.photos, Permission.storage]),
      );
      expect(
        requirements.where((r) => !r.isCritical).map((r) => r.title),
        containsAll(['Photos and videos', 'Files']),
      );
    });

    test('iOS maps to local network (critical) plus photos', () {
      final service = PermissionService(
        gateway: _FakeGateway(),
        platform: AppPlatform.ios,
      );

      final requirements = service.requirements();
      expect(requirements, hasLength(2));
      expect(
        service.criticalRequirements().single.permission,
        Permission.accessLocalNetwork,
      );
      expect(requirements.map((r) => r.title), contains('Photos'));
    });

    test('desktop platforms require nothing', () {
      for (final platform in [
        AppPlatform.windows,
        AppPlatform.macos,
        AppPlatform.linux,
      ]) {
        final service = PermissionService(
          gateway: _FakeGateway(),
          platform: platform,
        );
        expect(service.requirements(), isEmpty, reason: '$platform');
        expect(service.criticalRequirements(), isEmpty, reason: '$platform');
      }
    });
  });

  group('PermissionService status handling', () {
    test('hasAllCritical is true when every critical permission is granted',
        () async {
      final gateway = _FakeGateway();
      gateway.grant(Permission.nearbyWifiDevices);
      final service =
          PermissionService(gateway: gateway, platform: AppPlatform.android);

      expect(await service.hasAllCritical(), isTrue);
    });

    test('hasAllCritical is false while a critical permission is denied',
        () async {
      final service = PermissionService(
        gateway: _FakeGateway(),
        platform: AppPlatform.android,
      );

      expect(await service.hasAllCritical(), isFalse);
    });

    test('requestAll only asks for permissions that are not yet granted',
        () async {
      final gateway = _FakeGateway();
      gateway.grant(Permission.photos);
      final service =
          PermissionService(gateway: gateway, platform: AppPlatform.android);

      final result = await service.requestAll();

      expect(gateway.requested, isNot(contains(Permission.photos)));
      expect(gateway.requested, contains(Permission.nearbyWifiDevices));
      expect(gateway.requested, contains(Permission.storage));
      expect(result[Permission.photos], PermissionStatus.granted);
      expect(result[Permission.nearbyWifiDevices], PermissionStatus.granted);
    });

    test('isPermanentlyDenied reflects a blocked permission', () async {
      final gateway = _FakeGateway(
        statuses: {
          Permission.nearbyWifiDevices: PermissionStatus.permanentlyDenied,
        },
      );
      final service =
          PermissionService(gateway: gateway, platform: AppPlatform.android);

      expect(
        await service.isPermanentlyDenied(Permission.nearbyWifiDevices),
        isTrue,
      );
      expect(await service.isPermanentlyDenied(Permission.photos), isFalse);
    });

    test('openSettings forwards to the gateway', () async {
      final gateway = _FakeGateway();
      final service =
          PermissionService(gateway: gateway, platform: AppPlatform.android);

      expect(await service.openSettings(), isTrue);
      expect(gateway.openSettingsCalls, 1);
    });
  });
}

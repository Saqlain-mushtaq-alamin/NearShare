import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/core/security/app_lock.dart';

class _FakeAppLockGateway implements AppLockGateway {
  _FakeAppLockGateway({this.supported = true});

  bool supported;
  bool authenticationSucceeds = true;
  bool enabled = false;
  int authenticationCalls = 0;

  @override
  Future<bool> authenticate(String reason) async {
    authenticationCalls++;
    return authenticationSucceeds;
  }

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
  }
}

void main() {
  group('AppLockController', () {
    test('locks on launch when enabled', () async {
      final gateway = _FakeAppLockGateway()..enabled = true;
      final controller = AppLockController(gateway);
      await controller.initialize();

      expect(controller.state.isEnabled, isTrue);
      expect(controller.state.isLocked, isTrue);
      expect(controller.state.isLoading, isFalse);
    });

    test('unlock succeeds after authentication', () async {
      final gateway = _FakeAppLockGateway()..enabled = true;
      final controller = AppLockController(gateway);
      await controller.initialize();

      expect(await controller.unlock(), isTrue);
      expect(controller.state.isLocked, isFalse);
      expect(gateway.authenticationCalls, 1);
    });

    test('failed authentication keeps the app locked', () async {
      final gateway = _FakeAppLockGateway()
        ..enabled = true
        ..authenticationSucceeds = false;
      final controller = AppLockController(gateway);
      await controller.initialize();

      expect(await controller.unlock(), isFalse);
      expect(controller.state.isLocked, isTrue);
      expect(controller.state.errorMessage, isNotNull);
    });

    test('cannot enable on a device without authentication', () async {
      final gateway = _FakeAppLockGateway(supported: false);
      final controller = AppLockController(gateway);
      await controller.initialize();

      expect(await controller.setEnabled(true), isFalse);
      expect(controller.state.isEnabled, isFalse);
      expect(gateway.enabled, isFalse);
    });

    test('enabling requires authentication and persists', () async {
      final gateway = _FakeAppLockGateway();
      final controller = AppLockController(gateway);
      await controller.initialize();

      expect(await controller.setEnabled(true), isTrue);
      expect(controller.state.isEnabled, isTrue);
      expect(gateway.enabled, isTrue);
      expect(gateway.authenticationCalls, 1);
    });

    test('lock() is a no-op when app lock is disabled', () async {
      final gateway = _FakeAppLockGateway();
      final controller = AppLockController(gateway);
      await controller.initialize();

      controller.lock();
      expect(controller.state.isLocked, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceIdentityService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Generates and persists unique device ID on first call', () async {
      final service = DeviceIdentityService();
      final id1 = await service.getOrCreateDeviceId();
      expect(id1, isNotEmpty);

      // Subsequent call returns same persisted ID
      final id2 = await service.getOrCreateDeviceId();
      expect(id2, equals(id1));
    });

    test('Persists and updates custom device name', () async {
      final service = DeviceIdentityService();
      final defaultName = await service.getOrCreateDeviceName();
      expect(defaultName, isNotEmpty);

      await service.setDeviceName('Work Surface Laptop');
      final updatedName = await service.getOrCreateDeviceName();
      expect(updatedName, equals('Work Surface Laptop'));
    });

    test('getLocalDevice returns fully initialized Device model', () async {
      final service = DeviceIdentityService();
      final localDevice = await service.getLocalDevice();

      expect(localDevice.id, isNotEmpty);
      expect(localDevice.name, isNotEmpty);
      expect(localDevice.port, equals(DeviceIdentityService.defaultPort));
      expect(localDevice.platform, isNotEmpty);
    });
  });
}

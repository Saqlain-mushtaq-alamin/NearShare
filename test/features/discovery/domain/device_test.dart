import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';

void main() {
  group('Device Model Tests', () {
    final testDate = DateTime(2026, 1, 1, 12, 0, 0);
    final device1 = Device(
      id: 'dev-123',
      name: 'Pixel 9 Pro',
      platform: 'android',
      ipAddress: '192.168.1.100',
      port: 53317,
      discoveredAt: testDate,
    );

    final device1Identical = Device(
      id: 'dev-123',
      name: 'Pixel 9 Pro',
      platform: 'android',
      ipAddress: '192.168.1.100',
      port: 53317,
      discoveredAt: testDate,
    );

    final device2 = Device(
      id: 'dev-456',
      name: 'iPhone 16',
      platform: 'ios',
      ipAddress: '192.168.1.101',
      port: 53317,
      discoveredAt: testDate,
    );

    test('Device equality and hashCode', () {
      expect(device1, equals(device1Identical));
      expect(device1.hashCode, equals(device1Identical.hashCode));
      expect(device1 == device2, isFalse);
    });

    test('Device copyWith modifies specified attributes', () {
      final updated = device1.copyWith(name: 'Renamed Pixel', port: 60000);
      expect(updated.id, 'dev-123');
      expect(updated.name, 'Renamed Pixel');
      expect(updated.port, 60000);
      expect(updated.ipAddress, '192.168.1.100');
    });

    test('Device toJson and fromJson serialization', () {
      final json = device1.toJson();
      expect(json['id'], 'dev-123');
      expect(json['name'], 'Pixel 9 Pro');
      expect(json['platform'], 'android');
      expect(json['ipAddress'], '192.168.1.100');
      expect(json['port'], 53317);

      final fromJson = Device.fromJson(json);
      expect(fromJson.id, device1.id);
      expect(fromJson.name, device1.name);
      expect(fromJson.platform, device1.platform);
      expect(fromJson.ipAddress, device1.ipAddress);
      expect(fromJson.port, device1.port);
    });
  });
}

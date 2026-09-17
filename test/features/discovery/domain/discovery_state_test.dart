import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/discovery/domain/discovery_state.dart';

void main() {
  group('DiscoveryState Domain Tests', () {
    final sampleDevice = Device(
      id: 'd-1',
      name: 'Test Device',
      platform: 'windows',
      ipAddress: '192.168.1.50',
      port: 53317,
      discoveredAt: DateTime(2026, 1, 1),
    );

    test('Initial default values', () {
      const state = DiscoveryState();
      expect(state.status, DiscoveryStatus.idle);
      expect(state.devices, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isBroadcasting, isFalse);
      expect(state.localDevice, isNull);
    });

    test('copyWith updates state correctly', () {
      const initial = DiscoveryState();
      final updated = initial.copyWith(
        status: DiscoveryStatus.scanning,
        devices: [sampleDevice],
        isBroadcasting: true,
      );

      expect(updated.status, DiscoveryStatus.scanning);
      expect(updated.devices.length, 1);
      expect(updated.devices.first, sampleDevice);
      expect(updated.isBroadcasting, isTrue);
    });

    test('copyWith clearErrorMessage works', () {
      final errorState = const DiscoveryState().copyWith(
        status: DiscoveryStatus.error,
        errorMessage: 'Network error',
      );
      expect(errorState.errorMessage, 'Network error');

      final cleared = errorState.copyWith(
        clearErrorMessage: true,
        status: DiscoveryStatus.scanning,
      );
      expect(cleared.errorMessage, isNull);
      expect(cleared.status, DiscoveryStatus.scanning);
    });

    test('Equality and hashCode', () {
      final stateA = DiscoveryState(
        status: DiscoveryStatus.scanning,
        devices: [sampleDevice],
        isBroadcasting: true,
      );
      final stateB = DiscoveryState(
        status: DiscoveryStatus.scanning,
        devices: [sampleDevice],
        isBroadcasting: true,
      );

      expect(stateA, equals(stateB));
      expect(stateA.hashCode, equals(stateB.hashCode));
    });
  });
}

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:nearshare/features/discovery/data/mdns_discovery_service.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/discovery/domain/discovery_state.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeMdnsDiscoveryService implements MdnsDiscoveryService {
  final StreamController<Device> _discoveredController =
      StreamController<Device>.broadcast();
  final StreamController<String> _lostController =
      StreamController<String>.broadcast();

  bool _broadcasting = false;
  bool _scanning = false;

  @override
  Stream<Device> get onDeviceDiscovered => _discoveredController.stream;

  @override
  Stream<String> get onDeviceLost => _lostController.stream;

  @override
  bool get isBroadcasting => _broadcasting;

  @override
  bool get isScanning => _scanning;

  @override
  Future<void> startBroadcast({
    required String deviceId,
    required String deviceName,
    required String platform,
    required int port,
    String? tlsFingerprint,
  }) async {
    _broadcasting = true;
  }

  @override
  Future<void> stopBroadcast() async {
    _broadcasting = false;
  }

  @override
  Future<void> startDiscovery() async {
    _scanning = true;
  }

  @override
  Future<void> stopDiscovery() async {
    _scanning = false;
  }

  @override
  Future<void> dispose() async {
    await _discoveredController.close();
    await _lostController.close();
  }

  void emitDeviceDiscovered(Device device) {
    _discoveredController.add(device);
  }

  void emitDeviceLost(String id) {
    _lostController.add(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeMdnsDiscoveryService fakeDiscovery;
  late DeviceIdentityService identityService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeDiscovery = FakeMdnsDiscoveryService();
    identityService = DeviceIdentityService();
  });

  tearDown(() {
    fakeDiscovery.dispose();
  });

  group('DiscoveryNotifier Tests', () {
    test('Initializes, broadcasts, and starts scanning', () async {
      final notifier = DiscoveryNotifier(identityService, fakeDiscovery);
      // Wait for async initialization
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.localDevice, isNotNull);
      expect(notifier.state.status, DiscoveryStatus.scanning);
      expect(notifier.state.isBroadcasting, isTrue);

      notifier.dispose();
    });

    test('Adds discovered peer and removes on lost event', () async {
      final notifier = DiscoveryNotifier(identityService, fakeDiscovery);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final peer = Device(
        id: 'peer-99',
        name: 'Galaxy Tab',
        platform: 'android',
        ipAddress: '192.168.1.88',
        port: 53317,
        discoveredAt: DateTime.now(),
      );

      fakeDiscovery.emitDeviceDiscovered(peer);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(notifier.state.devices.length, 1);
      expect(notifier.state.devices.first.id, 'peer-99');

      // Now emit peer lost
      fakeDiscovery.emitDeviceLost('peer-99');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(notifier.state.devices, isEmpty);

      notifier.dispose();
    });

    test('Updating local device name updates state', () async {
      final notifier = DiscoveryNotifier(identityService, fakeDiscovery);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.updateLocalDeviceName('Custom iPad Name');
      expect(notifier.state.localDevice?.name, 'Custom iPad Name');

      notifier.dispose();
    });

    test('Stop scanning sets status to idle', () async {
      final notifier = DiscoveryNotifier(identityService, fakeDiscovery);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.stopScanning();
      expect(notifier.state.status, DiscoveryStatus.idle);

      notifier.dispose();
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:nearshare/features/discovery/data/mdns_discovery_service.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/discovery/domain/discovery_state.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_session_repository.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';
import 'package:nearshare/features/transfer/presentation/transfer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [DiscoveryNotifier] that never touches bonsoir or device_info and keeps
/// whatever state the test seeded (the parent's `_initialize` would
/// auto-start broadcast/scanning and overwrite it).
class StaticDiscoveryNotifier extends DiscoveryNotifier {
  StaticDiscoveryNotifier(DiscoveryState initialState)
      : super(FakeDeviceIdentityService(), _NoopMdnsService()) {
    state = initialState;
  }

  @override
  bool get autoInitialize => false;

  @override
  Future<void> startBroadcast() async {}

  @override
  Future<void> stopBroadcast() async {}

  @override
  Future<void> startScanning() async {}

  @override
  Future<void> stopScanning() async {}

  @override
  Future<void> refresh() async {}
}

/// A [DeviceIdentityService] that answers immediately.
///
/// The real one awaits device_info_plus, which never resolves inside the
/// test binding's fake-async zone and hangs `pumpAndSettle`.
class FakeDeviceIdentityService extends DeviceIdentityService {
  FakeDeviceIdentityService({
    String deviceName = 'NearShare Test Device',
    String deviceId = 'test-device-1',
  })  : _deviceName = deviceName,
        _deviceId = deviceId;

  String _deviceName;
  final String _deviceId;

  @override
  Future<String> getOrCreateDeviceId() async => _deviceId;

  @override
  Future<String> getOrCreateDeviceName() async => _deviceName;

  @override
  Future<void> setDeviceName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isNotEmpty) _deviceName = trimmed;
  }

  @override
  Future<int> getDevicePort() async => DeviceIdentityService.defaultPort;

  @override
  Future<void> setDevicePort(int port) async {}

  @override
  Future<Device> getLocalDevice({String ipAddress = '127.0.0.1'}) async {
    return Device(
      id: _deviceId,
      name: _deviceName,
      platform: 'android',
      ipAddress: ipAddress,
      port: DeviceIdentityService.defaultPort,
      discoveredAt: DateTime(2026, 1, 1),
    );
  }
}

class _NoopMdnsService extends Fake implements MdnsDiscoveryService {
  @override
  Stream<Device> get onDeviceDiscovered => const Stream.empty();

  @override
  Stream<String> get onDeviceLost => const Stream.empty();

  @override
  bool get isBroadcasting => false;

  @override
  bool get isScanning => false;

  @override
  Future<void> startBroadcast({
    required String deviceId,
    required String deviceName,
    required String platform,
    required int port,
  }) async {}

  @override
  Future<void> stopBroadcast() async {}

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> dispose() async {}
}

/// A [TransferNotifier] backed by in-memory collaborators only.
///
/// Constructing the real one opens sockets and the SQLite file, which widget
/// tests must not do.
class TestTransferNotifier extends TransferNotifier {
  TestTransferNotifier(super.manager, super.identityService);

  void seed(TransferState next) => state = next;
}

/// Builds a [TestTransferNotifier] plus the temp directory backing it, so the
/// caller can dispose both. Callers seed [SharedPreferences.setMockInitialValues]
/// themselves before invoking this.
Future<TestTransferHarness> createTestTransferHarness() async {
  final tempDir = await Directory.systemTemp.createTemp('transfer_harness_');
  final manager = TransferManager(
    client: TransferClient(),
    storageService: FileStorageService(customDownloadPath: tempDir.path),
    sessionRepository: InMemoryTransferSessionRepository(),
  );
  final identity = DeviceIdentityService(
    prefs: await SharedPreferences.getInstance(),
  );
  return TestTransferHarness(
    notifier: TestTransferNotifier(manager, identity),
    manager: manager,
    tempDir: tempDir,
  );
}

class TestTransferHarness {
  final TestTransferNotifier notifier;
  final TransferManager manager;
  final Directory tempDir;

  const TestTransferHarness({
    required this.notifier,
    required this.manager,
    required this.tempDir,
  });

  Future<void> dispose() async {
    await manager.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

DiscoveryState emptyDiscoveryState() {
  return const DiscoveryState(
    status: DiscoveryStatus.idle,
    isBroadcasting: false,
    localDevice: null,
    devices: <Device>[],
  );
}

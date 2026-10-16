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

/// A [DiscoveryNotifier] that never touches bonsoir.
class StaticDiscoveryNotifier extends DiscoveryNotifier {
  StaticDiscoveryNotifier(DiscoveryState initialState)
      : super(DeviceIdentityService(), _NoopMdnsService()) {
    state = initialState;
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
/// caller can dispose both.
Future<TestTransferHarness> createTestTransferHarness() async {
  SharedPreferences.setMockInitialValues({});
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

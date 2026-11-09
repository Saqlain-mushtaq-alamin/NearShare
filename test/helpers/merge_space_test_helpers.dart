import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearshare/features/merge_space/data/group_credential_store.dart';
import 'package:nearshare/features/merge_space/data/merge_discovery_service.dart';
import 'package:nearshare/features/merge_space/data/merge_space_repository.dart';
import 'package:nearshare/features/merge_space/data/merge_space_storage.dart';
import 'package:nearshare/features/merge_space/data/merge_space_client.dart';
import 'package:nearshare/features/merge_space/domain/paired_device.dart';
import 'package:nearshare/features/merge_space/presentation/merge_space_provider.dart';

import 'presentation_stubs.dart';

class FakeMergeDiscoveryService implements MergeDiscoveryService {
  final StreamController<MergePeerAnnouncement> _controller =
      StreamController<MergePeerAnnouncement>.broadcast();
  final StreamController<String> _lostController =
      StreamController<String>.broadcast();

  bool isBroadcasting = false;
  bool isDiscovering = false;
  String? groupId;
  int startBroadcastCalls = 0;

  @override
  Stream<MergePeerAnnouncement> get onPeerDiscovered => _controller.stream;

  @override
  Stream<String> get onPeerLost => _lostController.stream;

  @override
  Future<void> startBroadcast({
    required String groupId,
    required String deviceId,
    required String deviceName,
    required String platform,
    required String hostIp,
    required int port,
  }) async {
    this.groupId = groupId;
    isBroadcasting = true;
    startBroadcastCalls++;
  }

  @override
  Future<void> stopBroadcast() async {
    isBroadcasting = false;
  }

  @override
  Future<void> startDiscovery({required String groupId}) async {
    this.groupId = groupId;
    isDiscovering = true;
  }

  @override
  Future<void> stopDiscovery() async {
    isDiscovering = false;
  }

  void emit(MergePeerAnnouncement announcement) {
    _controller.add(announcement);
  }

  void emitLost(String deviceId) {
    _lostController.add(deviceId);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
    await _lostController.close();
  }
}

class FakeMergeSpaceClient extends MergeSpaceClient {
  DeviceGroup? pairResult;
  final List<String> pairedHosts = [];

  @override
  Future<DeviceGroup> pair({
    required String host,
    required int port,
    required String groupId,
    required String groupKey,
    required PairedDevice localDevice,
  }) async {
    pairedHosts.add('$host:$port');
    return pairResult ??
        DeviceGroup(
          groupId: groupId,
          groupKey: groupKey,
          devices: [localDevice],
          createdAt: DateTime(2026, 1, 1),
        );
  }
}

Override mergeSpaceTestOverride() {
  return mergeSpaceProvider.overrideWith(
    (ref) => MergeSpaceNotifier(
      repository: InMemoryMergeSpaceRepository(),
      storage: MergeSpaceStorage(customRootPath: 'unused-in-widget-test'),
      credentialStore: InMemoryGroupCredentialStore(),
      discovery: FakeMergeDiscoveryService(),
      identityService: FakeDeviceIdentityService(),
      client: FakeMergeSpaceClient(),
      autoStartRuntime: false,
    ),
  );
}

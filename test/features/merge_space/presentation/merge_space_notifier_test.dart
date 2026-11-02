import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/data/group_credential_store.dart';
import 'package:nearshare/features/merge_space/data/merge_space_repository.dart';
import 'package:nearshare/features/merge_space/data/merge_space_storage.dart';
import 'package:nearshare/features/merge_space/data/pairing_service.dart';
import 'package:nearshare/features/merge_space/domain/paired_device.dart';
import 'package:nearshare/features/merge_space/presentation/merge_space_provider.dart';

import '../../../helpers/merge_space_test_helpers.dart';
import '../../../helpers/presentation_stubs.dart';

void main() {
  late InMemoryMergeSpaceRepository repository;
  late InMemoryGroupCredentialStore credentials;
  late FakeMergeDiscoveryService discovery;
  late FakeMergeSpaceClient client;
  late MergeSpaceNotifier notifier;
  late PairingService pairing;

  setUp(() {
    repository = InMemoryMergeSpaceRepository();
    credentials = InMemoryGroupCredentialStore();
    discovery = FakeMergeDiscoveryService();
    client = FakeMergeSpaceClient();
    pairing = PairingService();
    notifier = MergeSpaceNotifier(
      repository: repository,
      storage: MergeSpaceStorage(customRootPath: 'unused-in-unit-test'),
      credentialStore: credentials,
      discovery: discovery,
      identityService: FakeDeviceIdentityService(),
      client: client,
      pairingService: pairing,
      autoStartRuntime: false,
    );
  });

  tearDown(() {
    notifier.dispose();
    discovery.dispose();
  });

  Future<void> settleInit() => Future<void>.delayed(Duration.zero);

  test('creates a group and persists credentials plus the local device',
      () async {
    await settleInit();

    await notifier.createGroup();

    expect(notifier.state.hasGroup, isTrue);
    expect(notifier.state.localDevice!.deviceId, 'test-device-1');
    expect(credentials.credentials, isNotNull);
    expect(await repository.getDevices(), hasLength(1));
  });

  test('joins a group from a pairing link and stores the host', () async {
    await settleInit();
    final group = pairing.createGroup(now: DateTime(2026, 1, 1));
    final host = PairedDevice(
      deviceId: 'host-1',
      deviceName: 'Laptop',
      platform: 'windows',
      groupId: group.groupId,
      pairedAt: DateTime(2026, 1, 1),
      syncStatus: SyncStatus.synced,
    );
    client.pairResult = group.addOrUpdateDevice(host);
    final link = pairing.buildUri(
      group: group,
      hostAddress: '192.168.1.20',
      port: 48484,
    );

    final joined = await notifier.joinWithLink(link);

    expect(joined, isTrue);
    expect(client.pairedHosts, ['192.168.1.20:48484']);
    expect(notifier.state.group!.groupId, group.groupId);
    expect(
      notifier.state.devices.map((device) => device.deviceId),
      contains('host-1'),
    );
    expect(credentials.credentials!.groupKey, group.groupKey);
  });

  test('rejects an invalid pairing link without changing state', () async {
    await settleInit();

    final joined = await notifier.joinWithLink('https://example.com');

    expect(joined, isFalse);
    expect(notifier.state.hasGroup, isFalse);
    expect(credentials.credentials, isNull);
  });

  test('removes a paired device from the group', () async {
    await settleInit();
    final group = pairing.createGroup();
    final host = PairedDevice(
      deviceId: 'host-1',
      deviceName: 'Laptop',
      platform: 'windows',
      groupId: group.groupId,
      pairedAt: DateTime(2026, 1, 1),
    );
    client.pairResult = group.addOrUpdateDevice(host);
    await notifier.joinWithLink(
      pairing.buildUri(group: group, hostAddress: '192.168.1.20', port: 1234),
    );

    await notifier.removeDevice('host-1');

    expect(notifier.state.devices, isEmpty);
    expect(notifier.state.group!.deviceById('host-1'), isNull);
    expect(
      (await repository.getDevices())
          .where((device) => device.deviceId == 'host-1'),
      isEmpty,
    );
  });

  test('unpair wipes credentials, index and devices', () async {
    await settleInit();
    await notifier.createGroup();
    expect(notifier.state.hasGroup, isTrue);

    await notifier.unpair();

    expect(notifier.state.hasGroup, isFalse);
    expect(credentials.credentials, isNull);
    expect(await repository.getDevices(), isEmpty);
  });
}

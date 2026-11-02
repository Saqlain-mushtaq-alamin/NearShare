import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as sha;
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/data/merge_protocol.dart';
import 'package:nearshare/features/merge_space/data/merge_space_client.dart';
import 'package:nearshare/features/merge_space/data/merge_space_repository.dart';
import 'package:nearshare/features/merge_space/data/merge_space_storage.dart';
import 'package:nearshare/features/merge_space/data/merge_sync_service.dart';
import 'package:nearshare/features/merge_space/data/pairing_service.dart';
import 'package:nearshare/features/merge_space/domain/merge_space_file.dart';
import 'package:nearshare/features/merge_space/domain/paired_device.dart';

class _FakeClient extends MergeSpaceClient {
  final List<MergeSpaceFile> remoteIndex;
  final Map<String, List<int>> remoteFiles;
  final bool fail;
  final Map<String, List<int>> uploaded = {};

  _FakeClient({
    this.remoteIndex = const [],
    this.remoteFiles = const {},
    this.fail = false,
  });

  @override
  Future<List<MergeSpaceFile>> exchangeIndex({
    required String host,
    required int port,
    required String groupId,
    required String groupKey,
    required String deviceId,
    required List<MergeSpaceFile> files,
  }) async {
    if (fail) throw const MergeClientException('Peer is offline');
    return remoteIndex;
  }

  @override
  Future<void> uploadFile({
    required String host,
    required int port,
    required String groupId,
    required String groupKey,
    required String deviceId,
    required MergeSpaceFile file,
    required List<int> bytes,
  }) async {
    uploaded[file.relativePath] = bytes;
  }

  @override
  Future<Uint8List> downloadFile({
    required String host,
    required int port,
    required String groupId,
    required String groupKey,
    required String deviceId,
    required String relativePath,
  }) async {
    final bytes = remoteFiles[relativePath];
    if (bytes == null) {
      throw const MergeClientException('File is missing');
    }
    return Uint8List.fromList(bytes);
  }
}

void main() {
  late Directory temp;
  late MergeSpaceStorage storage;
  late InMemoryMergeSpaceRepository repository;
  late DeviceGroup group;
  late PairedDevice local;
  late PairedDevice peer;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('merge_sync_service_test_');
    storage = MergeSpaceStorage(customRootPath: temp.path);
    repository = InMemoryMergeSpaceRepository();
    group = PairingService().createGroup(now: DateTime(2026, 1, 1));
    local = PairedDevice(
      deviceId: 'local-device',
      deviceName: 'Laptop',
      platform: 'windows',
      groupId: group.groupId,
      pairedAt: DateTime(2026, 1, 1),
      syncStatus: SyncStatus.synced,
    );
    peer = PairedDevice(
      deviceId: 'peer-device',
      deviceName: 'Pixel 8',
      platform: 'android',
      groupId: group.groupId,
      pairedAt: DateTime(2026, 1, 1),
    );
    group = group.addOrUpdateDevice(local).addOrUpdateDevice(peer);
    await repository.saveDevice(local);
    await repository.saveDevice(peer);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('marks both devices synced after a successful pass', () async {
    await storage.writeBytes('note.txt', 'hello'.codeUnits);
    final client = _FakeClient();
    final service = MergeSyncService(
      repository: repository,
      storage: storage,
      client: client,
    );

    final report = await service.sync(
      group: group,
      localDevice: local,
      peers: [
        MergePeerEndpoint(
          deviceId: peer.deviceId,
          deviceName: peer.deviceName,
          host: '127.0.0.1',
          port: 1,
        ),
      ],
    );

    expect(report.transfers, 1);
    expect(client.uploaded['note.txt'], 'hello'.codeUnits);

    final devices = await repository.getDevices();
    final savedPeer = devices.firstWhere((d) => d.deviceId == peer.deviceId);
    final savedLocal = devices.firstWhere((d) => d.deviceId == local.deviceId);
    expect(savedPeer.syncStatus, SyncStatus.synced);
    expect(savedPeer.lastSyncedAt, isNotNull);
    expect(savedLocal.syncStatus, SyncStatus.synced);
    expect(savedLocal.lastSyncedAt, isNotNull);
  });

  test('downloads a new remote file and indexes it', () async {
    final bytes = 'from peer'.codeUnits;
    final hash = sha.sha256.convert(bytes).toString();
    final remoteFile = MergeSpaceFile(
      relativePath: 'incoming.txt',
      hash: hash,
      baseHash: hash,
      sizeBytes: bytes.length,
      modifiedAt: DateTime(2026, 1, 2),
      originDeviceId: peer.deviceId,
    );
    final client = _FakeClient(
      remoteIndex: [remoteFile],
      remoteFiles: {'incoming.txt': bytes},
    );
    final service = MergeSyncService(
      repository: repository,
      storage: storage,
      client: client,
    );

    final report = await service.sync(
      group: group,
      localDevice: local,
      peers: [
        MergePeerEndpoint(
          deviceId: peer.deviceId,
          deviceName: peer.deviceName,
          host: '127.0.0.1',
          port: 1,
        ),
      ],
    );

    expect(report.downloads, 1);
    expect(await storage.readBytes('incoming.txt'), bytes);
    final indexed = await repository.getFile('incoming.txt');
    expect(indexed!.hash, hash);
    expect(indexed.baseHash, hash);
  });

  test('rejects a corrupt download without writing it', () async {
    final remoteFile = MergeSpaceFile(
      relativePath: 'corrupt.txt',
      hash: 'not-the-real-hash',
      sizeBytes: 9,
      modifiedAt: DateTime(2026, 1, 2),
      originDeviceId: peer.deviceId,
    );
    final client = _FakeClient(
      remoteIndex: [remoteFile],
      remoteFiles: {'corrupt.txt': 'tampered!'.codeUnits},
    );
    final service = MergeSyncService(
      repository: repository,
      storage: storage,
      client: client,
    );

    final report = await service.sync(
      group: group,
      localDevice: local,
      peers: [
        MergePeerEndpoint(
          deviceId: peer.deviceId,
          deviceName: peer.deviceName,
          host: '127.0.0.1',
          port: 1,
        ),
      ],
    );

    expect(report.unreachable, 1);
    expect(await storage.exists('corrupt.txt'), isFalse);
    expect(await repository.getFile('corrupt.txt'), isNull);
  });

  test('marks only the unreachable peer offline', () async {
    final client = _FakeClient(fail: true);
    final service = MergeSyncService(
      repository: repository,
      storage: storage,
      client: client,
    );

    final report = await service.sync(
      group: group,
      localDevice: local,
      peers: [
        MergePeerEndpoint(
          deviceId: peer.deviceId,
          deviceName: peer.deviceName,
          host: '127.0.0.1',
          port: 1,
        ),
      ],
    );

    expect(report.unreachable, 1);
    final devices = await repository.getDevices();
    expect(
      devices.firstWhere((d) => d.deviceId == peer.deviceId).syncStatus,
      SyncStatus.offline,
    );
    expect(
      devices.firstWhere((d) => d.deviceId == local.deviceId).syncStatus,
      SyncStatus.synced,
    );
  });
}

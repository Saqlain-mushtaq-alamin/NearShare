import 'dart:io';

import 'package:crypto/crypto.dart' as sha;
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/data/file_index_service.dart';
import 'package:nearshare/features/merge_space/data/merge_protocol.dart';
import 'package:nearshare/features/merge_space/data/merge_space_client.dart';
import 'package:nearshare/features/merge_space/data/merge_space_repository.dart';
import 'package:nearshare/features/merge_space/data/merge_space_server.dart';
import 'package:nearshare/features/merge_space/data/merge_space_storage.dart';
import 'package:nearshare/features/merge_space/data/pairing_service.dart';
import 'package:nearshare/features/merge_space/domain/merge_space_file.dart';
import 'package:nearshare/features/merge_space/domain/paired_device.dart';

void main() {
  late Directory temp;
  late MergeSpaceStorage storage;
  late DriftMergeSpaceRepository repository;
  late MergeSpaceServer server;
  late MergeSpaceClient client;
  late DeviceGroup deviceGroup;
  late PairedDevice host;
  late PairedDevice guest;
  var port = 0;
  final received = <MergeSpaceFile>[];
  final deleted = <String>[];

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('merge_server_test_');
    storage = MergeSpaceStorage(customRootPath: temp.path);
    repository = DriftMergeSpaceRepository.inMemory();
    received.clear();
    deleted.clear();

    final pairing = PairingService();
    deviceGroup = pairing.createGroup(now: DateTime(2026, 1, 1));
    host = PairedDevice(
      deviceId: 'host-device',
      deviceName: 'Host',
      platform: 'windows',
      groupId: deviceGroup.groupId,
      pairedAt: DateTime(2026, 1, 1),
    );
    guest = PairedDevice(
      deviceId: 'guest-device',
      deviceName: 'Guest',
      platform: 'android',
      groupId: deviceGroup.groupId,
      pairedAt: DateTime(2026, 1, 1),
    );
    deviceGroup = deviceGroup.addOrUpdateDevice(host).addOrUpdateDevice(guest);

    server = MergeSpaceServer(
      groupProvider: () => deviceGroup,
      onPair: (device) async {
        deviceGroup = deviceGroup.addOrUpdateDevice(device);
        await repository.saveDevice(device);
        return deviceGroup;
      },
      buildIndex: () async {
        final previous = await repository.getAllFiles(includeDeleted: true);
        final files = await FileIndexService(storage: storage).scan(
          localDeviceId: host.deviceId,
          previous: previous,
        );
        await repository.saveFiles(files);
        return files;
      },
      onFileReceived: (file) async {
        received.add(file);
        await repository.saveFile(file);
      },
      onRemoteDelete: (path, deviceId) async {
        deleted.add(path);
        final existing = await repository.getFile(path);
        if (existing != null) {
          await repository.saveFile(
            existing.copyWith(isDeleted: true, baseHash: existing.hash),
          );
        }
      },
      storage: storage,
      localDeviceId: () => host.deviceId,
    );
    port = await server.start();
    client = MergeSpaceClient();
  });

  tearDown(() async {
    await server.stop();
    await repository.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  group('Merge Space LAN protocol', () {
    test('pairs a guest and returns the trusted group', () async {
      final joined = await client.pair(
        host: '127.0.0.1',
        port: port,
        groupId: deviceGroup.groupId,
        groupKey: deviceGroup.groupKey,
        localDevice: guest,
      );

      expect(joined.groupId, deviceGroup.groupId);
      expect(
        joined.devices.map((device) => device.deviceId),
        contains('host-device'),
      );
      expect(
        joined.devices.map((device) => device.deviceId),
        contains('guest-device'),
      );
      expect(await repository.getDevices(), hasLength(1));
    });

    test('rejects pairing with the wrong group key', () async {
      await expectLater(
        client.pair(
          host: '127.0.0.1',
          port: port,
          groupId: deviceGroup.groupId,
          groupKey: PairingService().createGroup().groupKey,
          localDevice: guest,
        ),
        throwsA(isA<MergeClientException>()),
      );
    });

    test('rejects a device that was removed from the group', () async {
      deviceGroup = deviceGroup.removeDevice(guest.deviceId);

      await expectLater(
        client.exchangeIndex(
          host: '127.0.0.1',
          port: port,
          groupId: deviceGroup.groupId,
          groupKey: deviceGroup.groupKey,
          deviceId: guest.deviceId,
          files: const [],
        ),
        throwsA(isA<MergeClientException>()),
      );
    });

    test('exchanges encrypted indexes', () async {
      await storage.writeBytes('server.txt', 'from host'.codeUnits);
      await repository.saveFiles(
        await FileIndexService(storage: storage).scan(
          localDeviceId: host.deviceId,
          previous: const [],
        ),
      );

      final remote = await client.exchangeIndex(
        host: '127.0.0.1',
        port: port,
        groupId: deviceGroup.groupId,
        groupKey: deviceGroup.groupKey,
        deviceId: guest.deviceId,
        files: [
          MergeSpaceFile(
            relativePath: 'client.txt',
            hash: 'hash-client',
            sizeBytes: 10,
            modifiedAt: DateTime(2026, 1, 1),
            originDeviceId: guest.deviceId,
          ),
        ],
      );

      expect(remote.single.relativePath, 'server.txt');
      expect(
        remote.single.hash,
        sha.sha256.convert('from host'.codeUnits).toString(),
      );
    });

    test('uploads, downloads and deletes encrypted files', () async {
      final bytes = 'shared secret'.codeUnits;
      final hash = sha.sha256.convert(bytes).toString();
      final file = MergeSpaceFile(
        relativePath: 'notes/shared.txt',
        hash: hash,
        sizeBytes: bytes.length,
        modifiedAt: DateTime(2026, 1, 2),
        originDeviceId: guest.deviceId,
      );

      await client.uploadFile(
        host: '127.0.0.1',
        port: port,
        groupId: deviceGroup.groupId,
        groupKey: deviceGroup.groupKey,
        deviceId: guest.deviceId,
        file: file,
        bytes: bytes,
      );

      expect(await storage.readBytes('notes/shared.txt'), bytes);
      expect(received.single.baseHash, hash);

      final downloaded = await client.downloadFile(
        host: '127.0.0.1',
        port: port,
        groupId: deviceGroup.groupId,
        groupKey: deviceGroup.groupKey,
        deviceId: guest.deviceId,
        relativePath: 'notes/shared.txt',
      );
      expect(downloaded, bytes);

      await client.deleteRemoteFile(
        host: '127.0.0.1',
        port: port,
        groupId: deviceGroup.groupId,
        deviceId: guest.deviceId,
        relativePath: 'notes/shared.txt',
      );

      expect(await storage.exists('notes/shared.txt'), isFalse);
      expect(deleted, ['notes/shared.txt']);
    });

    test('rejects a tampered upload via the hash header', () async {
      final file = MergeSpaceFile(
        relativePath: 'bad.txt',
        hash: 'not-the-hash',
        sizeBytes: 3,
        modifiedAt: DateTime(2026, 1, 2),
        originDeviceId: guest.deviceId,
      );

      await expectLater(
        client.uploadFile(
          host: '127.0.0.1',
          port: port,
          groupId: deviceGroup.groupId,
          groupKey: deviceGroup.groupKey,
          deviceId: guest.deviceId,
          file: file,
          bytes: [1, 2, 3],
        ),
        throwsA(isA<MergeClientException>()),
      );
    });
  });
}

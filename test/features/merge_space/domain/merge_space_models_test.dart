import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/domain/merge_space_file.dart';
import 'package:nearshare/features/merge_space/domain/paired_device.dart';

void main() {
  group('Merge Space models', () {
    test('MergeSpaceFile round-trips through JSON', () {
      final file = MergeSpaceFile(
        relativePath: 'notes/today.txt',
        hash: 'abc',
        baseHash: 'def',
        sizeBytes: 42,
        modifiedAt: DateTime.utc(2026, 1, 2, 3, 4),
        isDeleted: true,
        originDeviceId: 'device-a',
      );

      expect(MergeSpaceFile.fromJson(file.toJson()), file);
    });

    test('PairedDevice round-trips through JSON', () {
      final device = PairedDevice(
        deviceId: 'device-b',
        deviceName: 'Pixel 8',
        platform: 'android',
        groupId: 'group-1',
        pairedAt: DateTime.utc(2026, 1, 1),
        lastSyncedAt: DateTime.utc(2026, 1, 2),
        syncStatus: SyncStatus.synced,
      );

      expect(PairedDevice.fromJson(device.toJson()), device);
    });

    test('DeviceGroup adds, updates and removes devices', () {
      final group = DeviceGroup(
        groupId: 'group-1',
        groupKey: 'key',
        devices: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final first = PairedDevice(
        deviceId: 'a',
        deviceName: 'A',
        platform: 'windows',
        groupId: group.groupId,
        pairedAt: DateTime.utc(2026, 1, 1),
      );
      final second = PairedDevice(
        deviceId: 'b',
        deviceName: 'B',
        platform: 'android',
        groupId: group.groupId,
        pairedAt: DateTime.utc(2026, 1, 1),
      );

      final withDevices =
          group.addOrUpdateDevice(first).addOrUpdateDevice(second);
      expect(withDevices.devices, hasLength(2));
      expect(withDevices.deviceById('b')!.deviceName, 'B');

      final renamed = withDevices.addOrUpdateDevice(
        second.copyWith(deviceName: 'B2'),
      );
      expect(renamed.devices, hasLength(2));
      expect(renamed.deviceById('b')!.deviceName, 'B2');

      expect(renamed.removeDevice('a').devices.single.deviceId, 'b');
    });

    test('DeviceGroup round-trips through JSON', () {
      final group = DeviceGroup(
        groupId: 'group-1',
        groupKey: 'key',
        devices: [
          PairedDevice(
            deviceId: 'a',
            deviceName: 'A',
            platform: 'windows',
            groupId: 'group-1',
            pairedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final decoded = DeviceGroup.fromJson(group.toJson());
      expect(decoded.groupId, group.groupId);
      expect(decoded.groupKey, group.groupKey);
      expect(decoded.devices.single, group.devices.single);
      expect(decoded.createdAt, group.createdAt);
    });

    test('SyncStatus parses names and falls back to pendingSync', () {
      expect(SyncStatus.fromName('offline'), SyncStatus.offline);
      expect(SyncStatus.fromName('nonsense'), SyncStatus.pendingSync);
      expect(SyncStatus.fromName(null), SyncStatus.pendingSync);
    });
  });
}

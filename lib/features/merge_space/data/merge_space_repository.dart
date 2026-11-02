import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/merge_space_file.dart' as domain;
import '../domain/paired_device.dart' as domain;
import '../domain/sync_conflict.dart' as domain;
import 'local_database.dart';

/// Persistence contract for the Merge Space index, paired devices and
/// unresolved conflicts.
abstract class MergeSpaceRepository {
  Future<void> saveFile(domain.MergeSpaceFile file);

  Future<void> saveFiles(List<domain.MergeSpaceFile> files);

  Future<domain.MergeSpaceFile?> getFile(
    String relativePath, {
    bool includeDeleted = true,
  });

  Future<List<domain.MergeSpaceFile>> getAllFiles({
    bool includeDeleted = false,
  });

  Future<void> deleteFile(String relativePath);

  Future<void> clearFiles();

  Future<void> saveDevice(domain.PairedDevice device);

  Future<List<domain.PairedDevice>> getDevices();

  Future<void> removeDevice(String deviceId);

  Future<void> clearDevices();

  Future<domain.SyncConflict> saveConflict(domain.SyncConflict conflict);

  Future<List<domain.SyncConflict>> getConflicts({
    bool unresolvedOnly = true,
  });

  Future<void> resolveConflict(int id);

  Future<void> clearConflicts();

  Future<void> close();
}

class DriftMergeSpaceRepository implements MergeSpaceRepository {
  final MergeSpaceDatabase _db;
  final bool _ownsDatabase;

  DriftMergeSpaceRepository(this._db, {bool ownsDatabase = false})
      : _ownsDatabase = ownsDatabase;

  factory DriftMergeSpaceRepository.inMemory() {
    return DriftMergeSpaceRepository(
      openInMemoryMergeSpaceDatabase(),
      ownsDatabase: true,
    );
  }

  @override
  Future<void> saveFile(domain.MergeSpaceFile file) async {
    await _db.into(_db.mergeSpaceFiles).insertOnConflictUpdate(
          _fileCompanion(file),
        );
  }

  @override
  Future<void> saveFiles(List<domain.MergeSpaceFile> files) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.mergeSpaceFiles,
        files.map(_fileCompanion).toList(),
      );
    });
  }

  @override
  Future<domain.MergeSpaceFile?> getFile(
    String relativePath, {
    bool includeDeleted = true,
  }) async {
    final query = _db.select(_db.mergeSpaceFiles)
      ..where((t) => t.relativePath.equals(relativePath));
    if (!includeDeleted) {
      query.where((t) => t.isDeleted.equals(false));
    }
    final row = await query.getSingleOrNull();
    return row == null ? null : _fileFromRow(row);
  }

  @override
  Future<List<domain.MergeSpaceFile>> getAllFiles({
    bool includeDeleted = false,
  }) async {
    final query = _db.select(_db.mergeSpaceFiles)
      ..orderBy([(t) => OrderingTerm.asc(t.relativePath)]);
    if (!includeDeleted) {
      query.where((t) => t.isDeleted.equals(false));
    }
    final rows = await query.get();
    return rows.map(_fileFromRow).toList();
  }

  @override
  Future<void> deleteFile(String relativePath) async {
    await (_db.delete(_db.mergeSpaceFiles)
          ..where((t) => t.relativePath.equals(relativePath)))
        .go();
  }

  @override
  Future<void> clearFiles() async {
    await _db.delete(_db.mergeSpaceFiles).go();
  }

  @override
  Future<void> saveDevice(domain.PairedDevice device) async {
    await _db.into(_db.pairedDevices).insertOnConflictUpdate(
          _deviceCompanion(device),
        );
  }

  /// Persists a whole group in one batch.
  Future<void> saveDevices(List<domain.PairedDevice> devices) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.pairedDevices,
        devices.map(_deviceCompanion).toList(),
      );
    });
  }

  PairedDevicesCompanion _deviceCompanion(domain.PairedDevice device) {
    return PairedDevicesCompanion(
      deviceId: Value(device.deviceId),
      deviceName: Value(device.deviceName),
      platform: Value(device.platform),
      groupId: Value(device.groupId),
      pairedAt: Value(device.pairedAt),
      lastSyncedAt: Value(device.lastSyncedAt),
      syncStatus: Value(device.syncStatus.name),
    );
  }

  @override
  Future<List<domain.PairedDevice>> getDevices() async {
    final rows = await (_db.select(_db.pairedDevices)
          ..orderBy([(t) => OrderingTerm.asc(t.deviceName)]))
        .get();
    return rows
        .map(
          (row) => domain.PairedDevice(
            deviceId: row.deviceId,
            deviceName: row.deviceName,
            platform: row.platform,
            groupId: row.groupId,
            pairedAt: row.pairedAt,
            lastSyncedAt: row.lastSyncedAt,
            syncStatus: domain.SyncStatus.fromName(row.syncStatus),
          ),
        )
        .toList();
  }

  @override
  Future<void> removeDevice(String deviceId) async {
    await (_db.delete(_db.pairedDevices)
          ..where((t) => t.deviceId.equals(deviceId)))
        .go();
  }

  @override
  Future<void> clearDevices() async {
    await _db.delete(_db.pairedDevices).go();
  }

  @override
  Future<domain.SyncConflict> saveConflict(
    domain.SyncConflict conflict,
  ) async {
    final id = await _db.into(_db.syncConflicts).insert(
          SyncConflictsCompanion.insert(
            relativePath: conflict.relativePath,
            localHash: conflict.localVersion.hash,
            remoteHash: conflict.remoteVersion.hash,
            localVersionJson: jsonEncode(conflict.localVersion.toJson()),
            remoteVersionJson: jsonEncode(conflict.remoteVersion.toJson()),
            remoteDeviceId: conflict.remoteDeviceId,
            detectedAt: conflict.detectedAt,
            resolved: Value(conflict.resolved),
          ),
        );
    return conflict.copyWith(id: id);
  }

  @override
  Future<List<domain.SyncConflict>> getConflicts({
    bool unresolvedOnly = true,
  }) async {
    final query = _db.select(_db.syncConflicts)
      ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)]);
    if (unresolvedOnly) {
      query.where((t) => t.resolved.equals(false));
    }
    final rows = await query.get();
    return rows
        .map(
          (row) => domain.SyncConflict(
            id: row.id,
            relativePath: row.relativePath,
            localVersion: domain.MergeSpaceFile.fromJson(
              jsonDecode(row.localVersionJson) as Map<String, dynamic>,
            ),
            remoteVersion: domain.MergeSpaceFile.fromJson(
              jsonDecode(row.remoteVersionJson) as Map<String, dynamic>,
            ),
            remoteDeviceId: row.remoteDeviceId,
            detectedAt: row.detectedAt,
            resolved: row.resolved,
          ),
        )
        .toList();
  }

  @override
  Future<void> resolveConflict(int id) async {
    await (_db.update(_db.syncConflicts)
          ..where((t) => t.id.equals(id)))
        .write(const SyncConflictsCompanion(resolved: Value(true)));
  }

  @override
  Future<void> clearConflicts() async {
    await _db.delete(_db.syncConflicts).go();
  }

  @override
  Future<void> close() async {
    if (_ownsDatabase) await _db.close();
  }

  MergeSpaceFilesCompanion _fileCompanion(domain.MergeSpaceFile file) {
    return MergeSpaceFilesCompanion(
      relativePath: Value(file.relativePath),
      hash: Value(file.hash),
      baseHash: Value(file.baseHash),
      sizeBytes: Value(file.sizeBytes),
      modifiedAt: Value(file.modifiedAt),
      isDeleted: Value(file.isDeleted),
      originDeviceId: Value(file.originDeviceId),
    );
  }

  domain.MergeSpaceFile _fileFromRow(MergeSpaceFile row) {
    return domain.MergeSpaceFile(
      relativePath: row.relativePath,
      hash: row.hash,
      baseHash: row.baseHash,
      sizeBytes: row.sizeBytes,
      modifiedAt: row.modifiedAt,
      isDeleted: row.isDeleted,
      originDeviceId: row.originDeviceId,
    );
  }
}

class InMemoryMergeSpaceRepository implements MergeSpaceRepository {
  final Map<String, domain.MergeSpaceFile> _files = {};
  final Map<String, domain.PairedDevice> _devices = {};
  final Map<int, domain.SyncConflict> _conflicts = {};
  int _nextConflictId = 1;

  @override
  Future<void> saveFile(domain.MergeSpaceFile file) async {
    _files[file.relativePath] = file;
  }

  @override
  Future<void> saveFiles(List<domain.MergeSpaceFile> files) async {
    for (final file in files) {
      _files[file.relativePath] = file;
    }
  }

  @override
  Future<domain.MergeSpaceFile?> getFile(
    String relativePath, {
    bool includeDeleted = true,
  }) async {
    final file = _files[relativePath];
    if (file == null) return null;
    if (!includeDeleted && file.isDeleted) return null;
    return file;
  }

  @override
  Future<List<domain.MergeSpaceFile>> getAllFiles({
    bool includeDeleted = false,
  }) async {
    final files = _files.values
        .where((f) => includeDeleted || !f.isDeleted)
        .toList()
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return files;
  }

  @override
  Future<void> deleteFile(String relativePath) async {
    _files.remove(relativePath);
  }

  @override
  Future<void> clearFiles() async {
    _files.clear();
  }

  @override
  Future<void> saveDevice(domain.PairedDevice device) async {
    _devices[device.deviceId] = device;
  }

  @override
  Future<List<domain.PairedDevice>> getDevices() async {
    final devices = _devices.values.toList()
      ..sort((a, b) => a.deviceName.compareTo(b.deviceName));
    return devices;
  }

  @override
  Future<void> removeDevice(String deviceId) async {
    _devices.remove(deviceId);
  }

  @override
  Future<void> clearDevices() async {
    _devices.clear();
  }

  @override
  Future<domain.SyncConflict> saveConflict(
    domain.SyncConflict conflict,
  ) async {
    final id = conflict.id ?? _nextConflictId++;
    final stored = conflict.copyWith(id: id);
    _conflicts[id] = stored;
    return stored;
  }

  @override
  Future<List<domain.SyncConflict>> getConflicts({
    bool unresolvedOnly = true,
  }) async {
    final conflicts = _conflicts.values
        .where((c) => !unresolvedOnly || !c.resolved)
        .toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return conflicts;
  }

  @override
  Future<void> resolveConflict(int id) async {
    final conflict = _conflicts[id];
    if (conflict == null) return;
    _conflicts[id] = conflict.copyWith(resolved: true);
  }

  @override
  Future<void> clearConflicts() async {
    _conflicts.clear();
  }

  @override
  Future<void> close() async {
    _files.clear();
    _devices.clear();
    _conflicts.clear();
  }
}

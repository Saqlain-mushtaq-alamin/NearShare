import 'dart:io';

import 'package:crypto/crypto.dart' as sha;
import 'package:flutter/foundation.dart';

import '../domain/merge_space_file.dart';
import '../domain/paired_device.dart';
import '../domain/sync_conflict.dart';
import '../domain/sync_engine.dart';
import 'file_index_service.dart';
import 'merge_protocol.dart';
import 'merge_space_client.dart';
import 'merge_space_repository.dart';
import 'merge_space_storage.dart';

enum MergeConflictResolution { keepLocal, keepRemote, keepBoth }

class MergePeerEndpoint {
  final String deviceId;
  final String deviceName;
  final String host;
  final int port;

  const MergePeerEndpoint({
    required this.deviceId,
    required this.deviceName,
    required this.host,
    required this.port,
  });
}

class MergePeerSyncResult {
  final String deviceId;
  final String deviceName;
  final bool reachable;
  final int uploads;
  final int downloads;
  final int localDeletes;
  final int remoteDeletes;
  final int conflicts;

  const MergePeerSyncResult({
    required this.deviceId,
    required this.deviceName,
    required this.reachable,
    this.uploads = 0,
    this.downloads = 0,
    this.localDeletes = 0,
    this.remoteDeletes = 0,
    this.conflicts = 0,
  });
}

class MergeSyncReport {
  final List<MergePeerSyncResult> peers;

  const MergeSyncReport(this.peers);

  int get uploads => peers.fold(0, (sum, peer) => sum + peer.uploads);
  int get downloads => peers.fold(0, (sum, peer) => sum + peer.downloads);
  int get conflicts => peers.fold(0, (sum, peer) => sum + peer.conflicts);
  int get unreachable => peers.where((peer) => !peer.reachable).length;
  int get transfers => uploads + downloads;

  bool get hasChanges => peers.any(
        (peer) =>
            peer.uploads > 0 ||
            peer.downloads > 0 ||
            peer.localDeletes > 0 ||
            peer.remoteDeletes > 0 ||
            peer.conflicts > 0,
      );
}

/// Drives bidirectional diff-and-transfer runs and resolves conflicts.
class MergeSyncService {
  final MergeSpaceRepository repository;
  final MergeSpaceStorage storage;
  final FileIndexService indexService;
  final MergeSpaceClient client;
  final SyncEngine engine;

  MergeSyncService({
    required this.repository,
    required this.storage,
    FileIndexService? indexService,
    MergeSpaceClient? client,
    SyncEngine? engine,
  })  : indexService = indexService ?? FileIndexService(storage: storage),
        client = client ?? MergeSpaceClient(),
        engine = engine ?? const SyncEngine();

  Future<List<MergeSpaceFile>> scanLocal(String localDeviceId) async {
    final previous = await repository.getAllFiles(includeDeleted: true);
    final scanned = await indexService.scan(
      localDeviceId: localDeviceId,
      previous: previous,
    );
    await repository.saveFiles(scanned);
    return scanned;
  }

  Future<MergeSyncReport> sync({
    required DeviceGroup group,
    required PairedDevice localDevice,
    required List<MergePeerEndpoint> peers,
  }) async {
    final localIndex = await scanLocal(localDevice.deviceId);
    final results = <MergePeerSyncResult>[];

    for (final peer in peers) {
      var uploads = 0;
      var downloads = 0;
      var localDeletes = 0;
      var remoteDeletes = 0;
      var conflicts = 0;

      final peerDevice = group.deviceById(peer.deviceId);
      try {
        final remoteIndex = await client.exchangeIndex(
          host: peer.host,
          port: peer.port,
          groupId: group.groupId,
          groupKey: group.groupKey,
          deviceId: localDevice.deviceId,
          files: localIndex,
        );

        final plan = engine.buildPlan(
          localDeviceId: localDevice.deviceId,
          peerDeviceId: peer.deviceId,
          localFiles: localIndex,
          remoteFiles: remoteIndex,
        );

        for (final decision in plan.decisions) {
          switch (decision.kind) {
            case SyncDecisionKind.uploadLocal:
              final file = decision.local!;
              final bytes = await storage.readBytes(file.relativePath);
              await client.uploadFile(
                host: peer.host,
                port: peer.port,
                groupId: group.groupId,
                groupKey: group.groupKey,
                deviceId: localDevice.deviceId,
                file: file,
                bytes: bytes,
              );
              await repository.saveFile(file.copyWith(baseHash: file.hash));
              uploads++;
              break;
            case SyncDecisionKind.downloadRemote:
              final file = decision.remote!;
              final bytes = await _downloadVerified(
                peer: peer,
                group: group,
                localDeviceId: localDevice.deviceId,
                relativePath: file.relativePath,
                expectedHash: file.hash,
              );
              await storage.writeBytes(file.relativePath, bytes);
              await repository.saveFile(file.copyWith(baseHash: file.hash));
              downloads++;
              break;
            case SyncDecisionKind.deleteLocal:
              final local = decision.local!;
              await storage.delete(local.relativePath);
              await repository.saveFile(
                local.copyWith(isDeleted: true, baseHash: local.hash),
              );
              localDeletes++;
              break;
            case SyncDecisionKind.deleteRemote:
              final local = decision.local!;
              await client.deleteRemoteFile(
                host: peer.host,
                port: peer.port,
                groupId: group.groupId,
                deviceId: localDevice.deviceId,
                relativePath: local.relativePath,
              );
              await repository.saveFile(
                local.copyWith(
                  isDeleted: true,
                  baseHash: decision.remote?.hash ?? local.baseHash,
                ),
              );
              remoteDeletes++;
              break;
            case SyncDecisionKind.conflict:
              final conflict = decision.conflict!;
              if (await _isNewConflict(conflict)) {
                await repository.saveConflict(conflict);
                conflicts++;
              }
              break;
            case SyncDecisionKind.markSynced:
              final local = decision.local;
              if (local != null && local.baseHash != local.hash) {
                await repository.saveFile(local.copyWith(baseHash: local.hash));
              }
              break;
          }
        }

        final syncedAt = DateTime.now();
        await repository.saveDevice(
          localDevice.copyWith(
            lastSyncedAt: syncedAt,
            syncStatus: SyncStatus.synced,
          ),
        );
        if (peerDevice != null) {
          await repository.saveDevice(
            peerDevice.copyWith(
              lastSyncedAt: syncedAt,
              syncStatus: SyncStatus.synced,
            ),
          );
        }

        results.add(
          MergePeerSyncResult(
            deviceId: peer.deviceId,
            deviceName: peer.deviceName,
            reachable: true,
            uploads: uploads,
            downloads: downloads,
            localDeletes: localDeletes,
            remoteDeletes: remoteDeletes,
            conflicts: conflicts,
          ),
        );
      } catch (error, stack) {
        debugPrint(
          '[MergeSyncService] Sync with ${peer.deviceName} failed: $error\n$stack',
        );
        if (peerDevice != null) {
          await repository.saveDevice(
            peerDevice.copyWith(syncStatus: SyncStatus.offline),
          );
        }
        results.add(
          MergePeerSyncResult(
            deviceId: peer.deviceId,
            deviceName: peer.deviceName,
            reachable: false,
          ),
        );
      }
    }

    return MergeSyncReport(results);
  }

  Future<void> resolveConflict({
    required SyncConflict conflict,
    required MergeConflictResolution resolution,
    required DeviceGroup group,
    required PairedDevice localDevice,
    required MergePeerEndpoint peer,
  }) async {
    final local = conflict.localVersion;
    final remote = conflict.remoteVersion;
    final id = conflict.id;

    switch (resolution) {
      case MergeConflictResolution.keepLocal:
        if (local.isDeleted) {
          await client.deleteRemoteFile(
            host: peer.host,
            port: peer.port,
            groupId: group.groupId,
            deviceId: localDevice.deviceId,
            relativePath: local.relativePath,
          );
          await repository.saveFile(
            local.copyWith(isDeleted: true, baseHash: remote.hash),
          );
        } else {
          if (!await storage.exists(local.relativePath)) {
            throw FileSystemException(
              'Local version no longer exists',
              local.relativePath,
            );
          }
          final bytes = await storage.readBytes(local.relativePath);
          await client.uploadFile(
            host: peer.host,
            port: peer.port,
            groupId: group.groupId,
            groupKey: group.groupKey,
            deviceId: localDevice.deviceId,
            file: local,
            bytes: bytes,
          );
          await repository.saveFile(local.copyWith(baseHash: local.hash));
        }
        break;
      case MergeConflictResolution.keepRemote:
        if (remote.isDeleted) {
          await storage.delete(local.relativePath);
          await repository.saveFile(
            local.copyWith(
              isDeleted: true,
              baseHash: remote.baseHash ?? remote.hash,
            ),
          );
        } else {
          final bytes = await _downloadVerified(
            peer: peer,
            group: group,
            localDeviceId: localDevice.deviceId,
            relativePath: remote.relativePath,
            expectedHash: remote.hash,
          );
          await storage.writeBytes(remote.relativePath, bytes);
          await repository.saveFile(remote.copyWith(baseHash: remote.hash));
        }
        break;
      case MergeConflictResolution.keepBoth:
        if (local.isDeleted || remote.isDeleted) {
          await resolveConflict(
            conflict: conflict,
            resolution: local.isDeleted
                ? MergeConflictResolution.keepRemote
                : MergeConflictResolution.keepLocal,
            group: group,
            localDevice: localDevice,
            peer: peer,
          );
          if (id != null) await repository.resolveConflict(id);
          return;
        }
        final localBytes = await storage.readBytes(local.relativePath);
        final remoteBytes = await _downloadVerified(
          peer: peer,
          group: group,
          localDeviceId: localDevice.deviceId,
          relativePath: remote.relativePath,
          expectedHash: remote.hash,
        );
        final copyPath = await _uniqueConflictPath(
          local.relativePath,
          peer.deviceName,
        );
        await storage.writeBytes(remote.relativePath, remoteBytes);
        await storage.writeBytes(copyPath, localBytes);
        await repository.saveFile(remote.copyWith(baseHash: remote.hash));
        await repository.saveFile(
          local.copyWith(
            relativePath: copyPath,
            clearBaseHash: true,
            modifiedAt: DateTime.now(),
          ),
        );
        break;
    }

    if (id != null) {
      await repository.resolveConflict(id);
    }
  }

  Future<List<int>> _downloadVerified({
    required MergePeerEndpoint peer,
    required DeviceGroup group,
    required String localDeviceId,
    required String relativePath,
    required String expectedHash,
  }) async {
    final bytes = await client.downloadFile(
      host: peer.host,
      port: peer.port,
      groupId: group.groupId,
      groupKey: group.groupKey,
      deviceId: localDeviceId,
      relativePath: relativePath,
    );
    final actualHash = sha.sha256.convert(bytes).toString();
    if (actualHash != expectedHash) {
      throw MergeClientException('Downloaded copy of $relativePath is corrupt');
    }
    return bytes;
  }

  Future<String> _uniqueConflictPath(
    String relativePath,
    String deviceName,
  ) async {
    var candidate = SyncEngine.conflictCopyPath(relativePath, deviceName);
    var index = 2;
    while (await storage.exists(candidate) ||
        await repository.getFile(candidate) != null) {
      candidate = SyncEngine.conflictCopyPath(
        relativePath,
        '$deviceName $index',
      );
      index++;
    }
    return candidate;
  }

  Future<bool> _isNewConflict(SyncConflict conflict) async {
    final existing = await repository.getConflicts();
    for (final item in existing) {
      if (item.relativePath == conflict.relativePath &&
          item.localVersion.hash == conflict.localVersion.hash &&
          item.remoteVersion.hash == conflict.remoteVersion.hash) {
        return false;
      }
    }
    return true;
  }
}

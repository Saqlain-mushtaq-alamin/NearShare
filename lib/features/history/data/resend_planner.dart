import 'dart:io';

import 'package:flutter/foundation.dart' show immutable;

import '../../discovery/domain/device.dart';
import '../../transfer/domain/transfer_file.dart';
import '../domain/transfer_record.dart';

/// What a resend attempt would actually be able to send.
@immutable
class ResendPlan {
  /// The history entry the plan was derived from.
  final TransferRecord record;

  /// Files that still exist on disk and can be re-sent right now.
  final List<TransferFile> availableFiles;

  /// Files whose logged path is gone, empty or no longer a regular file.
  final List<TransferFileRecord> missingFiles;

  const ResendPlan({
    required this.record,
    required this.availableFiles,
    required this.missingFiles,
  });

  /// Nothing left to send.
  bool get isUnusable => availableFiles.isEmpty;

  /// Every original file is still reachable.
  bool get allFilesAvailable => missingFiles.isEmpty;

  int get availableSizeBytes =>
      availableFiles.fold(0, (sum, f) => sum + f.sizeInBytes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResendPlan &&
          runtimeType == other.runtimeType &&
          record.transferId == other.record.transferId;

  @override
  int get hashCode => record.transferId.hashCode;

  @override
  String toString() {
    return 'ResendPlan(${availableFiles.length} available, '
        '${missingFiles.length} missing)';
  }
}

/// Checks that a history entry can still be sent, and finds its old peer.
@immutable
class ResendPlanner {
  const ResendPlanner();

  /// Verifies every file in [record] is still on disk.
  ///
  /// Missing, empty or unreadable paths are reported instead of failing the
  /// whole resend, so the user can still send whatever survived.
  Future<ResendPlan> buildPlan(TransferRecord record) async {
    final available = <TransferFile>[];
    final missing = <TransferFileRecord>[];

    for (final file in record.files) {
      if (await _isPresent(file.localPath)) {
        available.add(
          TransferFile(
            name: file.fileName,
            sizeInBytes: file.fileSizeBytes,
            mimeType: file.mimeType,
            localPath: file.localPath!,
          ),
        );
      } else {
        missing.add(file);
      }
    }

    return ResendPlan(
      record: record,
      availableFiles: available,
      missingFiles: missing,
    );
  }

  /// Finds the peer this transfer went to among the currently discovered
  /// devices, so the send flow can be pre-selected.
  ///
  /// Matches on the stable device id first, then falls back to the name, which
  /// is what a user would recognise.
  Device? matchDevice(TransferRecord record, List<Device> devices) {
    for (final device in devices) {
      if (device.id == record.peerDeviceId) return device;
    }
    final wanted = record.peerDeviceName.toLowerCase().trim();
    if (wanted.isEmpty) return null;
    for (final device in devices) {
      if (device.name.toLowerCase().trim() == wanted) return device;
    }
    return null;
  }

  Future<bool> _isPresent(String? path) async {
    if (path == null || path.trim().isEmpty) return false;
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      return await file.stat().then((s) => s.type == FileSystemEntityType.file);
    } catch (_) {
      return false;
    }
  }
}

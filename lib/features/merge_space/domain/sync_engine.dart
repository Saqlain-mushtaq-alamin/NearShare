import 'merge_space_file.dart';
import 'sync_conflict.dart';

enum SyncDecisionKind {
  uploadLocal,
  downloadRemote,
  deleteLocal,
  deleteRemote,
  conflict,
  markSynced,
}

/// One resolved action for a single relative path.
class SyncDecision {
  final SyncDecisionKind kind;
  final String relativePath;
  final MergeSpaceFile? local;
  final MergeSpaceFile? remote;
  final SyncConflict? conflict;

  const SyncDecision({
    required this.kind,
    required this.relativePath,
    this.local,
    this.remote,
    this.conflict,
  });

  bool get hasTransfer =>
      kind == SyncDecisionKind.uploadLocal ||
      kind == SyncDecisionKind.downloadRemote;

  @override
  String toString() => 'SyncDecision(${kind.name}: $relativePath)';
}

/// Everything that has to happen to bring two devices in line.
class SyncPlan {
  final List<SyncDecision> decisions;

  const SyncPlan(this.decisions);

  static const SyncPlan empty = SyncPlan([]);

  List<SyncDecision> get uploads => _of(SyncDecisionKind.uploadLocal);
  List<SyncDecision> get downloads => _of(SyncDecisionKind.downloadRemote);
  List<SyncDecision> get localDeletions => _of(SyncDecisionKind.deleteLocal);
  List<SyncDecision> get remoteDeletions => _of(SyncDecisionKind.deleteRemote);
  List<SyncDecision> get conflicts => _of(SyncDecisionKind.conflict);
  List<SyncDecision> get synced => _of(SyncDecisionKind.markSynced);

  List<SyncDecision> _of(SyncDecisionKind kind) =>
      decisions.where((d) => d.kind == kind).toList();

  bool get hasWork => decisions.any(
        (d) => d.kind != SyncDecisionKind.markSynced,
      );

  bool get hasConflicts => conflicts.isNotEmpty;

  int get transferCount => uploads.length + downloads.length;
}

/// Pure diff calculation between the local and a peer's file index.
///
/// The engine never touches the network or the filesystem so every rule is
/// directly unit-testable.
class SyncEngine {
  const SyncEngine();

  SyncPlan buildPlan({
    required String localDeviceId,
    required String peerDeviceId,
    required List<MergeSpaceFile> localFiles,
    required List<MergeSpaceFile> remoteFiles,
  }) {
    final local = {for (final f in localFiles) f.relativePath: f};
    final remote = {for (final f in remoteFiles) f.relativePath: f};
    final paths = <String>{...local.keys, ...remote.keys};

    final decisions = <SyncDecision>[];
    for (final path in paths) {
      final decision = _decide(
        path: path,
        local: local[path],
        remote: remote[path],
        localDeviceId: localDeviceId,
        peerDeviceId: peerDeviceId,
      );
      if (decision != null) decisions.add(decision);
    }

    decisions.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return SyncPlan(decisions);
  }

  SyncDecision? _decide({
    required String path,
    required MergeSpaceFile? local,
    required MergeSpaceFile? remote,
    required String localDeviceId,
    required String peerDeviceId,
  }) {
    if (local == null && remote == null) return null;

    if (local == null) {
      if (remote!.isDeleted) return null;
      return SyncDecision(
        kind: SyncDecisionKind.downloadRemote,
        relativePath: path,
        remote: remote,
      );
    }

    if (remote == null) {
      if (local.isDeleted) return null;
      return SyncDecision(
        kind: SyncDecisionKind.uploadLocal,
        relativePath: path,
        local: local,
      );
    }

    if (local.isDeleted && remote.isDeleted) {
      return SyncDecision(
        kind: SyncDecisionKind.markSynced,
        relativePath: path,
        local: local,
        remote: remote,
      );
    }

    if (local.isDeleted || remote.isDeleted) {
      final surviving = local.isDeleted ? remote : local;
      if (!_changedSinceBase(surviving)) {
        return SyncDecision(
          kind: local.isDeleted
              ? SyncDecisionKind.deleteLocal
              : SyncDecisionKind.deleteRemote,
          relativePath: path,
          local: local,
          remote: remote,
        );
      }
      return _conflict(path, local, remote, peerDeviceId);
    }

    if (local.hash == remote.hash) {
      return SyncDecision(
        kind: SyncDecisionKind.markSynced,
        relativePath: path,
        local: local,
        remote: remote,
      );
    }

    final baseline = local.baseHash ?? remote.baseHash;
    final localChanged = baseline == null || local.hash != baseline;
    final remoteChanged = baseline == null || remote.hash != baseline;

    if (localChanged && remoteChanged) {
      return _conflict(path, local, remote, peerDeviceId);
    }
    if (localChanged) {
      return SyncDecision(
        kind: SyncDecisionKind.uploadLocal,
        relativePath: path,
        local: local,
        remote: remote,
      );
    }
    if (remoteChanged) {
      return SyncDecision(
        kind: SyncDecisionKind.downloadRemote,
        relativePath: path,
        remote: remote,
        local: local,
      );
    }
    return SyncDecision(
      kind: SyncDecisionKind.markSynced,
      relativePath: path,
      local: local,
      remote: remote,
    );
  }

  bool _changedSinceBase(MergeSpaceFile file) {
    if (file.isDeleted) return true;
    if (file.baseHash == null) return true;
    return file.hash != file.baseHash;
  }

  SyncDecision _conflict(
    String path,
    MergeSpaceFile local,
    MergeSpaceFile remote,
    String peerDeviceId,
  ) {
    return SyncDecision(
      kind: SyncDecisionKind.conflict,
      relativePath: path,
      local: local,
      remote: remote,
      conflict: SyncConflict(
        relativePath: path,
        localVersion: local,
        remoteVersion: remote,
        remoteDeviceId: peerDeviceId,
        detectedAt: DateTime.now(),
      ),
    );
  }

  /// Builds the preserved copy path used by "Keep Both", e.g.
  /// `notes (Pixel 8).txt` or `docs/notes (Laptop).txt`.
  static String conflictCopyPath(String relativePath, String deviceName) {
    final safeDevice = deviceName
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    final suffix = safeDevice.isEmpty ? 'Device' : safeDevice;

    final slash = relativePath.lastIndexOf('/');
    final directory = slash < 0 ? '' : relativePath.substring(0, slash + 1);
    final fileName = slash < 0 ? relativePath : relativePath.substring(slash + 1);

    final dot = fileName.lastIndexOf('.');
    final hasExtension = dot > 0;
    final base = hasExtension ? fileName.substring(0, dot) : fileName;
    final extension = hasExtension ? fileName.substring(dot) : '';

    return '$directory$base ($suffix)$extension';
  }
}

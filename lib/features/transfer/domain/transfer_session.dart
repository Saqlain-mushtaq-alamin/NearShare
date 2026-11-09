import 'chunk_info.dart';
import 'transfer_file.dart';

/// Which side of a transfer the local device is on.
enum TransferDirection {
  sending,
  receiving;

  static TransferDirection fromName(String? value) {
    return TransferDirection.values.firstWhere(
      (d) => d.name == value,
      orElse: () => TransferDirection.sending,
    );
  }
}

/// Lifecycle of a (possibly resumable) transfer session.
enum TransferSessionStatus {
  pending,
  inProgress,
  paused,
  completed,
  failed,
  cancelled;

  /// Sessions that are not in a terminal state and can still progress.
  bool get isIncomplete =>
      this != TransferSessionStatus.completed &&
      this != TransferSessionStatus.failed &&
      this != TransferSessionStatus.cancelled;

  static TransferSessionStatus fromName(String? value) {
    return TransferSessionStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => TransferSessionStatus.pending,
    );
  }
}

/// Persisted state for a transfer that can be interrupted and resumed.
///
/// Both sides keep a session: the sender tracks what it still has to push, the
/// receiver tracks which chunks it has already durable-written to disk. The
/// receiver's copy is the source of truth for the resume endpoint.
class TransferSession {
  static const int defaultChunkSize = kDefaultChunkSize;

  final String transferId;
  final String peerId;
  final String peerName;
  final String? peerIp;
  final int? peerPort;
  final TransferDirection direction;
  final TransferSessionStatus status;
  final List<TransferFile> files;
  final int chunkSize;
  final String? localDeviceId;
  final String? localDeviceName;
  final DateTime startedAt;
  final DateTime? lastActivityAt;
  final DateTime? completedAt;
  final String? errorMessage;

  /// Map of file index to the chunk indices that have been received.
  final Map<int, List<int>> receivedChunksPerFile;

  /// Map of file index to the final destination path once assembled.
  final Map<int, String> fileSavePaths;

  const TransferSession({
    required this.transferId,
    required this.peerId,
    required this.peerName,
    required this.direction,
    required this.status,
    required this.files,
    required this.chunkSize,
    required this.startedAt,
    this.peerIp,
    this.peerPort,
    this.localDeviceId,
    this.localDeviceName,
    this.lastActivityAt,
    this.completedAt,
    this.errorMessage,
    this.receivedChunksPerFile = const {},
    this.fileSavePaths = const {},
  });

  int get totalSizeBytes => files.fold(0, (sum, f) => sum + f.sizeInBytes);

  /// Most recent timestamp that reflects user-visible activity of this session.
  DateTime get lastActivityAtOrStart => lastActivityAt ?? startedAt;

  /// Number of chunks the file at [fileIndex] is split into.
  int totalChunksForFile(int fileIndex) {
    if (fileIndex < 0 || fileIndex >= files.length) return 0;
    return totalChunksForSize(files[fileIndex].sizeInBytes, chunkSize);
  }

  /// Total number of chunks across every file in this session.
  int get totalChunksAcrossFiles {
    var total = 0;
    for (var i = 0; i < files.length; i++) {
      total += totalChunksForFile(i);
    }
    return total;
  }

  /// Chunk indices already received for [fileIndex], always ascending.
  List<int> receivedChunksForFile(int fileIndex) {
    final chunks = receivedChunksPerFile[fileIndex];
    if (chunks == null) return const [];
    final sorted = List<int>.from(chunks)..sort();
    return sorted;
  }

  /// Chunk indices the sender still has to transmit for [fileIndex].
  List<int> missingChunksForFile(int fileIndex) {
    final total = totalChunksForFile(fileIndex);
    final received = receivedChunksForFile(fileIndex).toSet();
    final missing = <int>[];
    for (var i = 0; i < total; i++) {
      if (!received.contains(i)) missing.add(i);
    }
    return missing;
  }

  bool isFileComplete(int fileIndex) {
    if (fileIndex < 0 || fileIndex >= files.length) return false;
    if (fileSavePaths.containsKey(fileIndex)) return true;
    final total = totalChunksForFile(fileIndex);
    if (total == 0) return true;
    return missingChunksForFile(fileIndex).isEmpty;
  }

  bool get areAllFilesComplete {
    for (var i = 0; i < files.length; i++) {
      if (!isFileComplete(i)) return false;
    }
    return true;
  }

  /// Bytes already accounted for in [fileIndex], derived from received chunks.
  int receivedByteCountForFile(int fileIndex) {
    if (fileIndex < 0 || fileIndex >= files.length) return 0;
    if (fileSavePaths.containsKey(fileIndex)) return files[fileIndex].sizeInBytes;

    final total = totalChunksForFile(fileIndex);
    if (total == 0) return files[fileIndex].sizeInBytes;

    final chunkInfo = chunkRangesForSize(files[fileIndex].sizeInBytes, chunkSize);
    final received = receivedChunksForFile(fileIndex).toSet();
    var bytes = 0;
    for (final chunk in chunkInfo) {
      if (received.contains(chunk.index)) bytes += chunk.size;
    }
    return bytes;
  }

  /// Total bytes accounted for across all files.
  int get receivedByteCount {
    var bytes = 0;
    for (var i = 0; i < files.length; i++) {
      bytes += receivedByteCountForFile(i);
    }
    return bytes;
  }

  /// 0.0 - 1.0 completion of this session based on acknowledged bytes.
  double get progressFraction {
    if (totalSizeBytes <= 0) {
      return status == TransferSessionStatus.completed ? 1.0 : 0.0;
    }
    final fraction = receivedByteCount / totalSizeBytes;
    if (fraction < 0) return 0;
    if (fraction > 1) return 1;
    return fraction;
  }

  TransferSession copyWith({
    String? transferId,
    String? peerId,
    String? peerName,
    String? peerIp,
    int? peerPort,
    TransferDirection? direction,
    TransferSessionStatus? status,
    List<TransferFile>? files,
    int? chunkSize,
    String? localDeviceId,
    String? localDeviceName,
    DateTime? startedAt,
    DateTime? lastActivityAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<int, List<int>>? receivedChunksPerFile,
    Map<int, String>? fileSavePaths,
    bool clearPeerIp = false,
    bool clearPeerPort = false,
    bool clearErrorMessage = false,
    bool clearLastActivityAt = false,
    bool clearCompletedAt = false,
  }) {
    return TransferSession(
      transferId: transferId ?? this.transferId,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerIp: clearPeerIp ? null : (peerIp ?? this.peerIp),
      peerPort: clearPeerPort ? null : (peerPort ?? this.peerPort),
      direction: direction ?? this.direction,
      status: status ?? this.status,
      files: files ?? this.files,
      chunkSize: chunkSize ?? this.chunkSize,
      localDeviceId: localDeviceId ?? this.localDeviceId,
      localDeviceName: localDeviceName ?? this.localDeviceName,
      startedAt: startedAt ?? this.startedAt,
      lastActivityAt: clearLastActivityAt
          ? null
          : (lastActivityAt ?? this.lastActivityAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      receivedChunksPerFile: receivedChunksPerFile ?? this.receivedChunksPerFile,
      fileSavePaths: fileSavePaths ?? this.fileSavePaths,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'peerId': peerId,
      'peerName': peerName,
      'peerIp': peerIp,
      'peerPort': peerPort,
      'direction': direction.name,
      'status': status.name,
      'files': files.map((f) => f.toJson()).toList(),
      'chunkSize': chunkSize,
      'localDeviceId': localDeviceId,
      'localDeviceName': localDeviceName,
      'startedAt': startedAt.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'receivedChunksPerFile': receivedChunksPerFile.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'fileSavePaths': fileSavePaths.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  factory TransferSession.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'] as List<dynamic>? ?? [];
    final parsedFiles = rawFiles
        .map((f) => TransferFile.fromJson(f as Map<String, dynamic>))
        .toList();

    final rawChunks = json['receivedChunksPerFile'] as Map<String, dynamic>? ?? {};
    final chunks = <int, List<int>>{};
    rawChunks.forEach((key, value) {
      final index = int.tryParse(key);
      if (index == null) return;
      chunks[index] = (value as List<dynamic>? ?? []).map((c) => c as int).toList();
    });

    final rawPaths = json['fileSavePaths'] as Map<String, dynamic>? ?? {};
    final paths = <int, String>{};
    rawPaths.forEach((key, value) {
      final index = int.tryParse(key);
      if (index == null) return;
      paths[index] = value as String;
    });

    return TransferSession(
      transferId: json['transferId'] as String? ?? '',
      peerId: json['peerId'] as String? ?? '',
      peerName: json['peerName'] as String? ?? '',
      peerIp: json['peerIp'] as String?,
      peerPort: json['peerPort'] as int?,
      direction: TransferDirection.fromName(json['direction'] as String?),
      status: TransferSessionStatus.fromName(json['status'] as String?),
      files: parsedFiles,
      chunkSize: json['chunkSize'] as int? ?? TransferSession.defaultChunkSize,
      localDeviceId: json['localDeviceId'] as String?,
      localDeviceName: json['localDeviceName'] as String?,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.tryParse(json['lastActivityAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      receivedChunksPerFile: chunks,
      fileSavePaths: paths,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferSession &&
          runtimeType == other.runtimeType &&
          transferId == other.transferId &&
          peerId == other.peerId &&
          peerName == other.peerName &&
          peerIp == other.peerIp &&
          peerPort == other.peerPort &&
          direction == other.direction &&
          status == other.status &&
          chunkSize == other.chunkSize &&
          startedAt.isAtSameMomentAs(other.startedAt);

  @override
  int get hashCode =>
      transferId.hashCode ^
      peerId.hashCode ^
      peerName.hashCode ^
      peerIp.hashCode ^
      peerPort.hashCode ^
      direction.hashCode ^
      status.hashCode ^
      chunkSize.hashCode ^
      startedAt.hashCode;

  @override
  String toString() {
    return 'TransferSession(id: $transferId, $direction, $status, files: ${files.length}, '
        'progress: ${(progressFraction * 100).toStringAsFixed(1)}%)';
  }
}

/// Number of chunks a file of [fileSize] bytes is split into.
int totalChunksForSize(int fileSize, int chunkSize) {
  if (fileSize <= 0 || chunkSize <= 0) return 0;
  return (fileSize + chunkSize - 1) ~/ chunkSize;
}

/// Byte range of every chunk of a file of [fileSize] bytes.
List<ChunkInfo> chunkRangesForSize(int fileSize, int chunkSize) {
  final total = totalChunksForSize(fileSize, chunkSize);
  final ranges = <ChunkInfo>[];
  for (var i = 0; i < total; i++) {
    final start = i * chunkSize;
    final endExclusive =
        (start + chunkSize) > fileSize ? fileSize : (start + chunkSize);
    ranges.add(
      ChunkInfo(
        index: i,
        startByte: start,
        endByte: endExclusive - 1,
        size: endExclusive - start,
      ),
    );
  }
  return ranges;
}

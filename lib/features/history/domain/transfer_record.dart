import 'package:collection/collection.dart' show DeepCollectionEquality;
import 'package:flutter/foundation.dart' show immutable;

import '../../transfer/domain/transfer_session.dart'
    show TransferDirection, TransferSession;

/// Terminal outcome of a whole transfer, as shown in history.
///
/// Unlike [TransferSessionStatus] this only tracks what the user cares about
/// once the transfer is over: it finished, it broke, or it was abandoned.
enum TransferRecordStatus {
  completed,
  failed,
  cancelled;

  static TransferRecordStatus fromName(String? value) {
    return TransferRecordStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => TransferRecordStatus.failed,
    );
  }
}

/// A single file inside a finished transfer.
@immutable
class TransferFileRecord {
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;

  /// Where the file lives on this device.
  ///
  /// For a received file this is the download destination; for a sent file it
  /// is the original source path, which resend needs to re-read the bytes.
  final String? localPath;
  final TransferRecordStatus status;

  const TransferFileRecord({
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    this.localPath,
    required this.status,
  });

  bool get isCompleted => status == TransferRecordStatus.completed;

  /// Path a user would open to view the file, preferring the saved copy.
  String? get displayPath => localPath;

  /// Very small extension used to pick an icon or thumbnail.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'localPath': localPath,
      'status': status.name,
    };
  }

  factory TransferFileRecord.fromJson(Map<String, dynamic> json) {
    return TransferFileRecord(
      fileName: json['fileName'] as String? ?? 'unnamed',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      localPath: json['localPath'] as String?,
      status: TransferRecordStatus.fromName(json['status'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferFileRecord &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          fileSizeBytes == other.fileSizeBytes &&
          mimeType == other.mimeType &&
          localPath == other.localPath &&
          status == other.status;

  @override
  int get hashCode =>
      fileName.hashCode ^
      fileSizeBytes.hashCode ^
      mimeType.hashCode ^
      localPath.hashCode ^
      status.hashCode;

  @override
  String toString() {
    return 'TransferFileRecord($fileName, $fileSizeBytes bytes, $status)';
  }
}

/// An immutable entry in the local transfer history.
///
/// History is 100% on-device and never leaves the phone.
@immutable
class TransferRecord {
  final String transferId;
  final TransferDirection direction;
  final String peerDeviceId;
  final String peerDeviceName;
  final int totalFiles;
  final int totalSizeBytes;
  final TransferRecordStatus status;
  final DateTime timestamp;
  final DateTime? completedAt;
  final List<TransferFileRecord> files;

  const TransferRecord({
    required this.transferId,
    required this.direction,
    required this.peerDeviceId,
    required this.peerDeviceName,
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.status,
    required this.timestamp,
    this.completedAt,
    required this.files,
  });

  /// Summarises a finished [TransferSession] for the history log.
  ///
  /// A file counts as delivered when the session recorded a save path for it,
  /// which both sides write once the receiver has acknowledged the last chunk.
  ///
  /// Note that `fileSavePaths` means different things per side: on the
  /// receiver it is where the file landed on local disk, but on the sender it
  /// is the *receiver's* save path (echoed back by finalize). Only the
  /// receiver should surface it as `localPath`; the sender keeps the original
  /// source path so "Open File" and "Resend" still work.
  factory TransferRecord.fromSession(
    TransferSession session,
    TransferRecordStatus status, {
    DateTime? completedAt,
  }) {
    final isReceiving = session.direction == TransferDirection.receiving;
    final files = <TransferFileRecord>[];
    for (var i = 0; i < session.files.length; i++) {
      final file = session.files[i];
      final delivered = session.fileSavePaths.containsKey(i);
      final savedHere = isReceiving && delivered
          ? (session.fileSavePaths[i] ?? file.localPath)
          : file.localPath;
      files.add(
        TransferFileRecord(
          fileName: file.name,
          fileSizeBytes: file.sizeInBytes,
          mimeType: file.mimeType,
          localPath: savedHere,
          status: delivered
              ? TransferRecordStatus.completed
              : TransferRecordStatus.failed,
        ),
      );
    }

    return TransferRecord(
      transferId: session.transferId,
      direction: session.direction,
      peerDeviceId: session.peerId,
      peerDeviceName: session.peerName,
      totalFiles: session.files.length,
      totalSizeBytes: session.totalSizeBytes,
      status: status,
      timestamp: session.startedAt,
      completedAt: completedAt ?? session.completedAt,
      files: files,
    );
  }

  /// Files the user could actually open right now, regardless of outcome.
  List<TransferFileRecord> get completedFiles =>
      files.where((f) => f.isCompleted).toList();

  bool get isSent => direction == TransferDirection.sending;
  bool get isReceived => direction == TransferDirection.receiving;

  /// Human readable direction used by filter chips.
  String get directionLabel => isSent ? 'Sent' : 'Received';

  /// Case-insensitive match over the peer name and every file name.
  bool matchesSearch(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    if (peerDeviceName.toLowerCase().contains(needle)) return true;
    return files.any((f) => f.fileName.toLowerCase().contains(needle));
  }

  TransferRecord copyWith({
    String? transferId,
    TransferDirection? direction,
    String? peerDeviceId,
    String? peerDeviceName,
    int? totalFiles,
    int? totalSizeBytes,
    TransferRecordStatus? status,
    DateTime? timestamp,
    DateTime? completedAt,
    List<TransferFileRecord>? files,
    bool clearCompletedAt = false,
  }) {
    return TransferRecord(
      transferId: transferId ?? this.transferId,
      direction: direction ?? this.direction,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      peerDeviceName: peerDeviceName ?? this.peerDeviceName,
      totalFiles: totalFiles ?? this.totalFiles,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      files: files ?? this.files,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'direction': direction.name,
      'peerDeviceId': peerDeviceId,
      'peerDeviceName': peerDeviceName,
      'totalFiles': totalFiles,
      'totalSizeBytes': totalSizeBytes,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'files': files.map((f) => f.toJson()).toList(),
    };
  }

  factory TransferRecord.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'] as List<dynamic>? ?? [];
    return TransferRecord(
      transferId: json['transferId'] as String? ?? '',
      direction: json['direction'] == TransferDirection.receiving.name
          ? TransferDirection.receiving
          : TransferDirection.sending,
      peerDeviceId: json['peerDeviceId'] as String? ?? '',
      peerDeviceName: json['peerDeviceName'] as String? ?? '',
      totalFiles: json['totalFiles'] as int? ?? 0,
      totalSizeBytes: json['totalSizeBytes'] as int? ?? 0,
      status: TransferRecordStatus.fromName(json['status'] as String?),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      files: rawFiles
          .map((f) => TransferFileRecord.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferRecord &&
          runtimeType == other.runtimeType &&
          transferId == other.transferId &&
          direction == other.direction &&
          peerDeviceId == other.peerDeviceId &&
          peerDeviceName == other.peerDeviceName &&
          totalFiles == other.totalFiles &&
          totalSizeBytes == other.totalSizeBytes &&
          status == other.status &&
          timestamp.isAtSameMomentAs(other.timestamp) &&
          const DeepCollectionEquality().equals(files, other.files);

  @override
  int get hashCode => Object.hash(
        transferId,
        direction,
        peerDeviceId,
        peerDeviceName,
        totalFiles,
        totalSizeBytes,
        status,
        timestamp,
        const DeepCollectionEquality().hash(files),
      );

  @override
  String toString() {
    return 'TransferRecord($transferId, $direction, ${files.length} files, '
        '$totalSizeBytes bytes, $status)';
  }
}

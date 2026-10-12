import 'transfer_file.dart';

class TransferRequest {
  final String transferId;
  final String senderId;
  final String senderName;
  final List<TransferFile> files;
  final int totalSizeBytes;
  final DateTime timestamp;

  const TransferRequest({
    required this.transferId,
    required this.senderId,
    required this.senderName,
    required this.files,
    required this.totalSizeBytes,
    required this.timestamp,
  });

  TransferRequest copyWith({
    String? transferId,
    String? senderId,
    String? senderName,
    List<TransferFile>? files,
    int? totalSizeBytes,
    DateTime? timestamp,
  }) {
    return TransferRequest(
      transferId: transferId ?? this.transferId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      files: files ?? this.files,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'senderId': senderId,
      'senderName': senderName,
      'files': files.map((f) => f.toJson()).toList(),
      'totalSizeBytes': totalSizeBytes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransferRequest.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'] as List<dynamic>? ?? [];
    final parsedFiles = rawFiles
        .map((f) => TransferFile.fromJson(f as Map<String, dynamic>))
        .toList();

    return TransferRequest(
      transferId: json['transferId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown Sender',
      files: parsedFiles,
      totalSizeBytes: json['totalSizeBytes'] as int? ??
          parsedFiles.fold(0, (sum, f) => sum + f.sizeInBytes),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferRequest &&
          runtimeType == other.runtimeType &&
          transferId == other.transferId &&
          senderId == other.senderId &&
          senderName == other.senderName &&
          totalSizeBytes == other.totalSizeBytes &&
          timestamp.isAtSameMomentAs(other.timestamp);

  @override
  int get hashCode =>
      transferId.hashCode ^
      senderId.hashCode ^
      senderName.hashCode ^
      totalSizeBytes.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'TransferRequest(id: $transferId, from: $senderName, files: ${files.length}, total: $totalSizeBytes bytes)';
  }
}

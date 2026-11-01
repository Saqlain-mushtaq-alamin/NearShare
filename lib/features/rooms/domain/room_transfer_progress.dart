import 'room_member.dart';

/// Per-member state while the host broadcasts files to the room.
enum RoomMemberTransferStatus {
  idle,
  sending,
  completed,
  failed;

  bool get isFinished => this == completed || this == failed;
}

/// Progress of one member during a room broadcast.
class RoomMemberProgress {
  final String deviceId;
  final String deviceName;
  final RoomMemberTransferStatus status;
  final int bytesTransferred;
  final int totalBytes;
  final int filesCompleted;
  final int totalFiles;
  final String? errorMessage;

  const RoomMemberProgress({
    required this.deviceId,
    required this.deviceName,
    this.status = RoomMemberTransferStatus.idle,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.filesCompleted = 0,
    this.totalFiles = 0,
    this.errorMessage,
  });

  double get percentage {
    if (totalBytes <= 0) {
      if (status == RoomMemberTransferStatus.completed) return 1.0;
      return 0.0;
    }
    final value = bytesTransferred / totalBytes;
    if (value < 0) return 0.0;
    if (value > 1) return 1.0;
    return value;
  }

  RoomMemberProgress copyWith({
    String? deviceId,
    String? deviceName,
    RoomMemberTransferStatus? status,
    int? bytesTransferred,
    int? totalBytes,
    int? filesCompleted,
    int? totalFiles,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RoomMemberProgress(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      status: status ?? this.status,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      filesCompleted: filesCompleted ?? this.filesCompleted,
      totalFiles: totalFiles ?? this.totalFiles,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'status': status.name,
      'bytesTransferred': bytesTransferred,
      'totalBytes': totalBytes,
      'filesCompleted': filesCompleted,
      'totalFiles': totalFiles,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  factory RoomMemberProgress.fromJson(Map<String, dynamic> json) {
    return RoomMemberProgress(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Unknown Device',
      status: RoomMemberTransferStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => RoomMemberTransferStatus.idle,
      ),
      bytesTransferred: json['bytesTransferred'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      filesCompleted: json['filesCompleted'] as int? ?? 0,
      totalFiles: json['totalFiles'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Snapshot of a whole room broadcast.
class RoomTransferSummary {
  final List<RoomMemberProgress> members;

  const RoomTransferSummary({this.members = const []});

  factory RoomTransferSummary.forMembers(
    List<RoomMember> members, {
    int totalBytes = 0,
    int totalFiles = 0,
  }) {
    return RoomTransferSummary(
      members: [
        for (final member in members)
          RoomMemberProgress(
            deviceId: member.deviceId,
            deviceName: member.deviceName,
            totalBytes: totalBytes,
            totalFiles: totalFiles,
          ),
      ],
    );
  }

  int get totalMembers => members.length;

  int get completedCount => members
      .where((m) => m.status == RoomMemberTransferStatus.completed)
      .length;

  int get failedCount => members
      .where((m) => m.status == RoomMemberTransferStatus.failed)
      .length;

  int get sendingCount =>
      members.where((m) => m.status == RoomMemberTransferStatus.sending).length;

  bool get isFinished =>
      members.isNotEmpty && members.every((m) => m.status.isFinished);

  bool get allSucceeded =>
      members.isNotEmpty && completedCount == members.length;

  bool get hasFailures => failedCount > 0;

  double get overallPercentage {
    if (members.isEmpty) return 0.0;
    final sum = members.fold<double>(0, (total, m) => total + m.percentage);
    return sum / members.length;
  }

  RoomTransferSummary updateMember(RoomMemberProgress progress) {
    final updated = List<RoomMemberProgress>.from(members);
    final index = updated.indexWhere((m) => m.deviceId == progress.deviceId);
    if (index < 0) {
      updated.add(progress);
    } else {
      updated[index] = progress;
    }
    return RoomTransferSummary(members: updated);
  }

  Map<String, dynamic> toJson() {
    return {
      'members': members.map((member) => member.toJson()).toList(),
    };
  }

  factory RoomTransferSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['members'] as List<dynamic>? ?? const [];
    return RoomTransferSummary(
      members: raw
          .map(
            (item) => RoomMemberProgress.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  @override
  String toString() =>
      'RoomTransferSummary($completedCount/$totalMembers complete, '
      '$failedCount failed)';
}

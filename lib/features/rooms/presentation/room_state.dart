import '../../transfer/domain/transfer_file.dart';
import '../domain/room.dart';
import '../domain/room_transfer_progress.dart';

/// Which side of a room this device is on.
enum RoomRole {
  none,
  host,
  member;

  bool get isHost => this == host;
  bool get isMember => this == member;
}

class RoomState {
  final Room? room;
  final RoomRole role;
  final bool isBusy;
  final String? errorMessage;
  final RoomTransferSummary? transferSummary;
  final List<TransferFile> selectedFiles;

  const RoomState({
    this.room,
    this.role = RoomRole.none,
    this.isBusy = false,
    this.errorMessage,
    this.transferSummary,
    this.selectedFiles = const [],
  });

  bool get isInRoom => room != null && role != RoomRole.none;

  bool get isHost => role == RoomRole.host;

  bool get isMember => role == RoomRole.member;

  bool get isWaiting => room?.status == RoomStatus.waiting;

  bool get isTransferring =>
      room?.status == RoomStatus.transferring ||
      (transferSummary != null && !transferSummary!.isFinished);

  int get selectedSizeBytes =>
      selectedFiles.fold(0, (sum, file) => sum + file.sizeInBytes);

  RoomState copyWith({
    Room? room,
    RoomRole? role,
    bool? isBusy,
    String? errorMessage,
    RoomTransferSummary? transferSummary,
    List<TransferFile>? selectedFiles,
    bool clearRoom = false,
    bool clearError = false,
    bool clearTransferSummary = false,
  }) {
    return RoomState(
      room: clearRoom ? null : (room ?? this.room),
      role: clearRoom ? RoomRole.none : (role ?? this.role),
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      transferSummary: clearTransferSummary
          ? null
          : (transferSummary ?? this.transferSummary),
      selectedFiles: selectedFiles ?? this.selectedFiles,
    );
  }
}

import '../../discovery/domain/device.dart';
import '../domain/transfer_file.dart';
import '../domain/transfer_progress.dart';
import '../domain/transfer_request.dart';
import '../domain/transfer_session.dart';

class TransferState {
  final TransferProgress? activeProgress;
  final TransferRequest? activeRequest;
  final TransferRequest? pendingIncomingRequest;
  final List<TransferFile> selectedFiles;
  final Device? selectedTargetDevice;
  final int? serverPort;
  final bool isServerRunning;
  final String? errorMessage;
  final List<TransferSession> incompleteSessions;
  final TransferSession? activeSession;

  const TransferState({
    this.activeProgress,
    this.activeRequest,
    this.pendingIncomingRequest,
    this.selectedFiles = const [],
    this.selectedTargetDevice,
    this.serverPort,
    this.isServerRunning = false,
    this.errorMessage,
    this.incompleteSessions = const [],
    this.activeSession,
  });

  int get totalSelectedSizeBytes =>
      selectedFiles.fold(0, (sum, f) => sum + f.sizeInBytes);

  /// Incomplete sends that have not been resumed yet.
  List<TransferSession> get resumableSessions => [
        for (final session in incompleteSessions)
          if (session.direction == TransferDirection.sending &&
              (session.status == TransferSessionStatus.paused ||
                  session.status == TransferSessionStatus.pending))
            session,
      ];

  TransferState copyWith({
    TransferProgress? activeProgress,
    bool clearActiveProgress = false,
    TransferRequest? activeRequest,
    bool clearActiveRequest = false,
    TransferRequest? pendingIncomingRequest,
    bool clearPendingIncomingRequest = false,
    List<TransferFile>? selectedFiles,
    Device? selectedTargetDevice,
    bool clearSelectedTargetDevice = false,
    int? serverPort,
    bool? isServerRunning,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<TransferSession>? incompleteSessions,
    TransferSession? activeSession,
    bool clearActiveSession = false,
  }) {
    return TransferState(
      activeProgress: clearActiveProgress
          ? null
          : (activeProgress ?? this.activeProgress),
      activeRequest: clearActiveRequest
          ? null
          : (activeRequest ?? this.activeRequest),
      pendingIncomingRequest: clearPendingIncomingRequest
          ? null
          : (pendingIncomingRequest ?? this.pendingIncomingRequest),
      selectedFiles: selectedFiles ?? this.selectedFiles,
      selectedTargetDevice: clearSelectedTargetDevice
          ? null
          : (selectedTargetDevice ?? this.selectedTargetDevice),
      serverPort: serverPort ?? this.serverPort,
      isServerRunning: isServerRunning ?? this.isServerRunning,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      incompleteSessions: incompleteSessions ?? this.incompleteSessions,
      activeSession: clearActiveSession
          ? null
          : (activeSession ?? this.activeSession),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferState &&
          runtimeType == other.runtimeType &&
          activeProgress == other.activeProgress &&
          activeRequest == other.activeRequest &&
          pendingIncomingRequest == other.pendingIncomingRequest &&
          selectedTargetDevice == other.selectedTargetDevice &&
          serverPort == other.serverPort &&
          isServerRunning == other.isServerRunning &&
          errorMessage == other.errorMessage &&
          incompleteSessions == other.incompleteSessions &&
          activeSession == other.activeSession;

  @override
  int get hashCode =>
      activeProgress.hashCode ^
      activeRequest.hashCode ^
      pendingIncomingRequest.hashCode ^
      selectedTargetDevice.hashCode ^
      serverPort.hashCode ^
      isServerRunning.hashCode ^
      errorMessage.hashCode ^
      incompleteSessions.hashCode ^
      activeSession.hashCode;
}


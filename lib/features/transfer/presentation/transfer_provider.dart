import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../discovery/data/device_identity_service.dart';
import '../../discovery/domain/device.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../data/file_storage_service.dart';
import '../data/transfer_client.dart';
import '../data/transfer_manager.dart';
import '../data/transfer_server.dart';
import '../data/transfer_session_repository.dart';
import '../domain/transfer_file.dart';
import '../domain/transfer_progress.dart';
import '../domain/transfer_request.dart';
import '../domain/transfer_session.dart';
import 'transfer_state.dart';

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final transferSessionRepositoryProvider =
    Provider<TransferSessionRepository>((ref) {
  final repository = DriftTransferSessionRepository.openDefault();
  ref.onDispose(repository.close);
  return repository;
});

final transferServerProvider = Provider<TransferServer>((ref) {
  final storage = ref.watch(fileStorageServiceProvider);
  final repository = ref.watch(transferSessionRepositoryProvider);
  final server = TransferServer(
    storageService: storage,
    sessionRepository: repository,
  );
  ref.onDispose(() => server.dispose());
  return server;
});

final transferClientProvider = Provider<TransferClient>((ref) {
  return TransferClient();
});

final transferManagerProvider = Provider<TransferManager>((ref) {
  final server = ref.watch(transferServerProvider);
  final client = ref.watch(transferClientProvider);
  final storage = ref.watch(fileStorageServiceProvider);
  final repository = ref.watch(transferSessionRepositoryProvider);
  final manager = TransferManager(
    server: server,
    client: client,
    storageService: storage,
    sessionRepository: repository,
  );
  ref.onDispose(() => manager.dispose());
  return manager;
});

final transferStateProvider =
    StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  final manager = ref.watch(transferManagerProvider);
  final identityService = ref.watch(deviceIdentityServiceProvider);
  final notifier = TransferNotifier(manager, identityService);

  // Rediscovered peers are the natural moment to continue paused sends.
  ref.listen<List<Device>>(
    discoveryStateProvider.select((s) => s.devices),
    (previous, next) {
      notifier.onDevicesDiscovered(next);
    },
  );

  return notifier;
});

class TransferNotifier extends StateNotifier<TransferState> {
  final TransferManager _manager;
  final DeviceIdentityService _identityService;

  StreamSubscription<TransferRequest>? _incomingRequestSub;
  StreamSubscription<TransferProgress>? _progressSub;
  bool _isInitialized = false;
  bool _autoResuming = false;

  TransferNotifier(this._manager, this._identityService)
      : super(const TransferState()) {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _incomingRequestSub =
        _manager.onIncomingRequest.listen(_handleIncomingRequest);
    _progressSub = _manager.onProgress.listen(_handleProgressUpdate);

    try {
      await _manager.initialize();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to restore previous transfers: $e',
      );
    }
    await refreshIncompleteSessions();
    await initializeServer();
  }

  Future<void> initializeServer() async {
    try {
      final preferredPort = await _identityService.getDevicePort();
      final boundPort = await _manager.startServer(port: preferredPort);
      await _identityService.setDevicePort(boundPort);

      state = state.copyWith(
        serverPort: boundPort,
        isServerRunning: true,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isServerRunning: false,
        errorMessage: 'Failed to start transfer server: $e',
      );
    }
  }

  void _handleIncomingRequest(TransferRequest request) {
    state = state.copyWith(
      pendingIncomingRequest: request,
      activeRequest: request,
    );
  }

  void _handleProgressUpdate(TransferProgress progress) {
    final finished = progress.status.isFinished;
    state = state.copyWith(activeProgress: progress);
    if (finished) {
      unawaited(refreshIncompleteSessions());
    }
  }

  Future<void> refreshIncompleteSessions() async {
    try {
      final sessions = await _manager.getIncompleteSessions();
      state = state.copyWith(incompleteSessions: sessions);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load sessions: $e');
    }
  }

  /// Called whenever discovery reports new peers.
  void onDevicesDiscovered(List<Device> devices) {
    if (devices.isEmpty || _autoResuming) return;
    if (state.resumableSessions.isEmpty) return;
    unawaited(_autoResume(devices));
  }

  Future<void> _autoResume(List<Device> devices) async {
    _autoResuming = true;
    try {
      for (final device in devices) {
        final resumed = await _manager.resumeTransferForPeer(device);
        if (resumed != null) {
          state = state.copyWith(
            activeSession: resumed,
            clearActiveProgress: false,
          );
          await refreshIncompleteSessions();
          return;
        }
      }
    } finally {
      _autoResuming = false;
    }
  }

  void setSelectedFiles(List<TransferFile> files) {
    state = state.copyWith(selectedFiles: files);
  }

  void addSelectedFiles(List<TransferFile> files) {
    final updated = List<TransferFile>.from(state.selectedFiles)..addAll(files);
    state = state.copyWith(selectedFiles: updated);
  }

  void removeSelectedFile(int index) {
    if (index >= 0 && index < state.selectedFiles.length) {
      final updated = List<TransferFile>.from(state.selectedFiles)
        ..removeAt(index);
      state = state.copyWith(selectedFiles: updated);
    }
  }

  void clearSelectedFiles() {
    state = state.copyWith(selectedFiles: const []);
  }

  void setSelectedTargetDevice(Device? device) {
    state = state.copyWith(
      selectedTargetDevice: device,
      clearSelectedTargetDevice: device == null,
    );
  }

  Future<TransferProgress?> sendFiles({
    Device? targetDevice,
    List<TransferFile>? files,
  }) async {
    final target = targetDevice ?? state.selectedTargetDevice;
    final filesToSend = files ?? state.selectedFiles;

    if (target == null) {
      state = state.copyWith(errorMessage: 'No recipient device selected');
      return null;
    }
    if (filesToSend.isEmpty) {
      state = state.copyWith(errorMessage: 'No files selected for transfer');
      return null;
    }

    try {
      final localDevice = await _identityService.getLocalDevice();
      final progress = await _manager.sendFiles(
        target: target,
        files: filesToSend,
        localDevice: localDevice,
      );
      await refreshIncompleteSessions();
      return progress;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Send files error: $e');
      return null;
    }
  }

  /// Continues a persisted send against [device].
  Future<TransferProgress?> resumeTransfer(
    TransferSession session,
    Device device,
  ) async {
    try {
      state = state.copyWith(activeSession: session);
      final progress = await _manager.resumeSession(session, device);
      await refreshIncompleteSessions();
      return progress;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Resume error: $e');
      return null;
    }
  }

  Future<void> discardIncompleteSession(String transferId) async {
    await _manager.discardSession(transferId);
    await refreshIncompleteSessions();
  }

  void acceptIncomingTransfer(String transferId) {
    state = state.copyWith(clearPendingIncomingRequest: true);
    _manager.acceptTransfer(transferId);
  }

  void rejectIncomingTransfer(String transferId) {
    state = state.copyWith(clearPendingIncomingRequest: true);
    _manager.rejectTransfer(transferId);
  }

  Future<void> cancelTransfer(String transferId) async {
    await _manager.cancelTransfer(transferId);
    await refreshIncompleteSessions();
  }

  void clearActiveTransfer() {
    state = state.copyWith(
      clearActiveProgress: true,
      clearActiveRequest: true,
      clearPendingIncomingRequest: true,
      clearSelectedTargetDevice: true,
      clearActiveSession: true,
      selectedFiles: const [],
      clearErrorMessage: true,
    );
  }

  @override
  void dispose() {
    _incomingRequestSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }
}

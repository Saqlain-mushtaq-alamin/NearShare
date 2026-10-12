import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../discovery/data/device_identity_service.dart';
import '../../discovery/domain/device.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../data/file_storage_service.dart';
import '../data/transfer_client.dart';
import '../data/transfer_manager.dart';
import '../data/transfer_server.dart';
import '../domain/transfer_file.dart';
import '../domain/transfer_progress.dart';
import '../domain/transfer_request.dart';
import 'transfer_state.dart';

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final transferServerProvider = Provider<TransferServer>((ref) {
  final storage = ref.watch(fileStorageServiceProvider);
  final server = TransferServer(storageService: storage);
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
  final manager = TransferManager(
    server: server,
    client: client,
    storageService: storage,
  );
  ref.onDispose(() => manager.dispose());
  return manager;
});

final transferStateProvider =
    StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  final manager = ref.watch(transferManagerProvider);
  final identityService = ref.watch(deviceIdentityServiceProvider);
  return TransferNotifier(manager, identityService);
});

class TransferNotifier extends StateNotifier<TransferState> {
  final TransferManager _manager;
  final DeviceIdentityService _identityService;

  StreamSubscription<TransferRequest>? _incomingRequestSub;
  StreamSubscription<TransferProgress>? _progressSub;
  bool _isInitialized = false;

  TransferNotifier(this._manager, this._identityService)
      : super(const TransferState()) {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _incomingRequestSub = _manager.onIncomingRequest.listen(_handleIncomingRequest);
    _progressSub = _manager.onProgress.listen(_handleProgressUpdate);

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
    state = state.copyWith(
      activeProgress: progress,
    );
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
      final updated = List<TransferFile>.from(state.selectedFiles)..removeAt(index);
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
      return progress;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Send files error: $e');
      return null;
    }
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
  }

  void clearActiveTransfer() {
    state = state.copyWith(
      clearActiveProgress: true,
      clearActiveRequest: true,
      clearPendingIncomingRequest: true,
      clearSelectedTargetDevice: true,
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

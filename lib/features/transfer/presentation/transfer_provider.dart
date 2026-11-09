import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/network_security.dart';
import '../../discovery/data/device_identity_service.dart';
import '../../discovery/domain/device.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../../history/data/history_providers.dart';
import '../../history/data/resend_planner.dart';
import '../../history/domain/transfer_record.dart';
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

export '../../history/data/history_providers.dart'
    show nearShareDatabaseProvider, historyRepositoryProvider;

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final transferSessionRepositoryProvider =
    Provider<TransferSessionRepository>((ref) {
  return DriftTransferSessionRepository.fromDatabase(
    ref.watch(nearShareDatabaseProvider),
  );
});

final resendPlannerProvider = Provider<ResendPlanner>((ref) {
  return const ResendPlanner();
});

final transferServerProvider = Provider<TransferServer>((ref) {
  final storage = ref.watch(fileStorageServiceProvider);
  final repository = ref.watch(transferSessionRepositoryProvider);
  final history = ref.watch(historyRepositoryProvider);
  final identityService = ref.watch(deviceIdentityServiceProvider);
  final tlsService = ref.watch(tlsIdentityServiceProvider);
  final server = TransferServer(
    storageService: storage,
    sessionRepository: repository,
    historyRepository: history,
    securityConfig: const ServerSecurityConfig(),
    localDeviceIdProvider: identityService.getOrCreateDeviceId,
    tlsIdentityProvider: () async {
      final local = await identityService.getLocalDevice();
      return tlsService.loadOrCreate(commonName: local.name);
    },
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
  final history = ref.watch(historyRepositoryProvider);
  final manager = TransferManager(
    server: server,
    client: client,
    storageService: storage,
    sessionRepository: repository,
    historyRepository: history,
  );
  ref.onDispose(() => manager.dispose());
  return manager;
});

final transferStateProvider =
    StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  final manager = ref.watch(transferManagerProvider);
  final identityService = ref.watch(deviceIdentityServiceProvider);
  final resendPlanner = ref.watch(resendPlannerProvider);
  final notifier = TransferNotifier(
    manager,
    identityService,
    resendPlanner: resendPlanner,
  );
  unawaited(notifier.ensureInitialized());

  // Rediscovered peers are the natural moment to continue paused sends.
  ref.listen<List<Device>>(
    discoveryStateProvider.select((s) => s.devices),
    (previous, next) {
      notifier.onDevicesDiscovered(next);
    },
  );

  return notifier;
});

/// Result of preparing a resend from history.
class ResendOutcome {
  final ResendPlan plan;
  final Device? matchedDevice;

  const ResendOutcome({required this.plan, required this.matchedDevice});

  /// True when there is at least one file left to send.
  bool get canSend => !plan.isUnusable;

  /// Some original paths are gone but others still work.
  bool get hasMissingFiles => plan.missingFiles.isNotEmpty;

  String get missingFilesMessage =>
      'Some files are no longer available at their original locations.';
}

class TransferNotifier extends StateNotifier<TransferState> {
  final TransferManager _manager;
  final DeviceIdentityService _identityService;
  final ResendPlanner _resendPlanner;

  StreamSubscription<TransferRequest>? _incomingRequestSub;
  StreamSubscription<TransferProgress>? _progressSub;
  bool _isInitialized = false;
  bool _autoResuming = false;

  TransferNotifier(
    TransferManager manager,
    DeviceIdentityService identityService, {
    ResendPlanner resendPlanner = const ResendPlanner(),
  })  : _manager = manager,
        _identityService = identityService,
        _resendPlanner = resendPlanner,
        super(const TransferState()) {
    _incomingRequestSub =
        _manager.onIncomingRequest.listen(_handleIncomingRequest);
    _progressSub = _manager.onProgress.listen(_handleProgressUpdate);
  }

  /// Restores persisted sessions and starts the receiver server.
  ///
  /// Called once by the provider. Tests construct the notifier directly and
  /// skip this so they do not open sockets or touch the real database.
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    _isInitialized = true;

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

  /// Prepares the send flow from a history entry.
  ///
  /// Re-attaches every original file that is still on disk and, when the old
  /// peer is currently discovered, pre-selects it. Returns what the UI needs
  /// to warn the user about missing files.
  Future<ResendOutcome> startResend(
    TransferRecord record, {
    List<Device> availableDevices = const [],
  }) async {
    final plan = await _resendPlanner.buildPlan(record);
    final device = _resendPlanner.matchDevice(record, availableDevices);

    if (plan.isUnusable) {
      state = state.copyWith(
        errorMessage:
            'Some files are no longer available at their original locations.',
        clearSelectedTargetDevice: true,
        selectedFiles: const [],
      );
      return ResendOutcome(plan: plan, matchedDevice: device);
    }

    state = state.copyWith(
      selectedFiles: plan.availableFiles,
      selectedTargetDevice: device,
      clearSelectedTargetDevice: device == null,
      clearActiveProgress: true,
      clearActiveRequest: true,
      clearPendingIncomingRequest: true,
      clearActiveSession: true,
      clearErrorMessage: true,
    );
    return ResendOutcome(plan: plan, matchedDevice: device);
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
    if (!mounted) return;
    _incomingRequestSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }
}

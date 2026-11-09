import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/network_security.dart';
import '../../discovery/data/device_identity_service.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../../transfer/domain/transfer_file.dart';
import '../../transfer/presentation/transfer_provider.dart';
import '../data/qr_code_service.dart';
import '../data/room_client.dart';
import '../data/room_discovery_service.dart';
import '../data/room_manager.dart';
import '../data/room_server.dart';
import '../data/room_transfer_service.dart';
import '../domain/room.dart';
import '../domain/room_event.dart';
import '../domain/room_member.dart';
import '../domain/room_transfer_progress.dart';
import 'room_state.dart';

final qrCodeServiceProvider = Provider<QrCodeService>((ref) {
  return QrCodeService();
});

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  final manager = RoomManager();
  final identity = ref.watch(deviceIdentityServiceProvider);
  final transfer = RoomTransferService.withManager(
    ref.watch(transferManagerProvider),
  );

  return RoomNotifier(
    identityService: identity,
    roomClient: RoomClient(),
    discoveryService: BonsoirRoomDiscoveryService(),
    transferService: transfer,
    manager: manager,
    server: RoomServer(
      manager: manager,
      securityConfig: const ServerSecurityConfig(),
    ),
  );
});

/// Orchestrates hosting, joining and broadcasting for room mode.
class RoomNotifier extends StateNotifier<RoomState> {
  final DeviceIdentityService _identityService;
  final RoomClient _roomClient;
  final RoomDiscoveryService _discoveryService;
  final RoomTransferService _transferService;
  final RoomManager _manager;
  final QrCodeService _qrCodeService;
  late final RoomServer _server;

  StreamSubscription<Room>? _roomSubscription;
  StreamSubscription<RoomTransferSummary>? _summarySubscription;
  Timer? _pollTimer;
  bool _disposed = false;

  RoomNotifier({
    required DeviceIdentityService identityService,
    RoomClient? roomClient,
    RoomDiscoveryService? discoveryService,
    RoomTransferService? transferService,
    RoomManager? manager,
    RoomServer? server,
    QrCodeService? qrCodeService,
  })  : _identityService = identityService,
        _roomClient = roomClient ?? RoomClient(),
        _discoveryService = discoveryService ?? BonsoirRoomDiscoveryService(),
        _transferService = transferService ??
            RoomTransferService(sender: (_, __, ___) async {}),
        _manager = manager ?? RoomManager(),
        _qrCodeService = qrCodeService ?? QrCodeService(),
        super(const RoomState()) {
    _server = server ??
        RoomServer(
          manager: _manager,
          securityConfig: const ServerSecurityConfig(),
        );
    _roomSubscription = _manager.onRoomUpdated.listen((room) {
      if (_disposed) return;
      state = state.copyWith(room: room);
    });
    _summarySubscription = _transferService.onProgress.listen((summary) {
      if (_disposed) return;
      state = state.copyWith(transferSummary: summary);
    });
  }

  QrCodeService get qrCodeService => _qrCodeService;

  String? get joinUri {
    final room = state.room;
    if (room == null || room.hostIpAddress.isEmpty || room.hostPort <= 0) {
      return null;
    }
    return _qrCodeService.buildRoomUri(room);
  }

  // ---------------------------------------------------------------------------
  // Host
  // ---------------------------------------------------------------------------

  /// Creates a room, starts the host HTTP server and advertises it via mDNS.
  Future<void> createRoom() async {
    if (state.isBusy) return;
    if (state.isInRoom) {
      state = state.copyWith(
        errorMessage: 'Leave the current room before creating another.',
      );
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final localDevice = await _identityService.getLocalDevice();
      final localIp = await _resolveLocalIp();
      final port = await _server.start();

      final room = _manager.createRoom(
        hostDeviceId: localDevice.id,
        hostDeviceName: localDevice.name,
        hostIpAddress: localIp,
        hostPort: port,
      );

      try {
        await _discoveryService.startBroadcast(
          roomId: room.roomId,
          roomCode: room.roomCode,
          hostName: room.hostDeviceName,
          hostIp: room.hostIpAddress,
          port: room.hostPort,
        );
      } catch (error) {
        debugPrint('[RoomNotifier] mDNS broadcast failed: $error');
      }

      state = state.copyWith(
        room: room,
        role: RoomRole.host,
        isBusy: false,
        clearError: true,
      );
    } catch (error) {
      debugPrint('[RoomNotifier] createRoom failed: $error');
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Could not create room: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Member
  // ---------------------------------------------------------------------------

  /// Joins a room by its 6-digit code, discovering the host via mDNS.
  Future<void> joinRoomByCode(String rawCode) async {
    final code = rawCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      state = state.copyWith(errorMessage: 'Enter a valid 6-digit room code.');
      return;
    }
    if (state.isBusy) return;

    state = state.copyWith(isBusy: true, clearError: true);
    await _discoveryService.startDiscovery();
    final completer = Completer<RoomAnnouncement?>();
    late final StreamSubscription<RoomAnnouncement> subscription;
    subscription = _discoveryService.onRoomDiscovered.listen((announcement) {
      if (announcement.roomCode == code && !completer.isCompleted) {
        completer.complete(announcement);
      }
    });

    RoomAnnouncement? announcement;
    try {
      announcement = await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
    } finally {
      await subscription.cancel();
      await _discoveryService.stopDiscovery();
    }

    if (announcement == null) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Room not found. Check the code and try again.',
      );
      return;
    }

    await _joinHost(
      hostIp: announcement.hostIp,
      port: announcement.port,
      roomCode: code,
    );
  }

  /// Joins a room directly from a scanned QR link.
  Future<void> joinRoomWithLink(RoomJoinLink link) async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true, clearError: true);
    await _joinHost(
      hostIp: link.host,
      port: link.port,
      roomCode: link.roomCode,
    );
  }

  Future<void> _joinHost({
    required String hostIp,
    required int port,
    required String roomCode,
  }) async {
    try {
      final local = await _identityService.getLocalDevice();
      final localIp = await _resolveLocalIp();
      final self = RoomMember(
        deviceId: local.id,
        deviceName: local.name,
        platform: local.platform,
        ipAddress: localIp,
        port: local.port,
        joinedAt: DateTime.now(),
      );

      final room = await _roomClient.join(
        hostIp: hostIp,
        port: port,
        roomCode: roomCode,
        self: self,
      );

      state = state.copyWith(
        room: room,
        role: RoomRole.member,
        isBusy: false,
        clearError: true,
        clearTransferSummary: true,
      );
      _startPolling(hostIp: hostIp, port: port);
    } on RoomClientException catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: error.message,
      );
    } catch (error) {
      debugPrint('[RoomNotifier] join failed: $error');
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Could not join room: $error',
      );
    }
  }

  void _startPolling({required String hostIp, required int port}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_disposed) return;
      final room = await _roomClient.fetchRoom(hostIp: hostIp, port: port);
      if (_disposed || !mounted) return;

      if (room == null) {
        _pollTimer?.cancel();
        state = state.copyWith(
          errorMessage: 'Lost connection to the room.',
        );
        return;
      }

      state = state.copyWith(room: room);
      if (room.isClosed) {
        _pollTimer?.cancel();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Shared lifecycle
  // ---------------------------------------------------------------------------

  /// Leaves the room. On the host this also closes it for everyone.
  Future<void> leaveRoom() async {
    _pollTimer?.cancel();
    final room = state.room;
    final role = state.role;

    if (room != null && role == RoomRole.host) {
      await _discoveryService.stopBroadcast();
      await _manager.closeRoom();
      await _server.stop();
    } else if (room != null && role == RoomRole.member) {
      final local = await _identityService.getLocalDevice();
      await _roomClient.leave(
        hostIp: room.hostIpAddress,
        port: room.hostPort,
        deviceId: local.id,
      );
    }

    if (!mounted) return;
    state = const RoomState();
  }

  Future<void> closeRoom() => leaveRoom();

  // ---------------------------------------------------------------------------
  // Broadcasting files
  // ---------------------------------------------------------------------------

  void setSelectedFiles(List<TransferFile> files) {
    state = state.copyWith(selectedFiles: files);
  }

  void addSelectedFiles(List<TransferFile> files) {
    state = state.copyWith(selectedFiles: [...state.selectedFiles, ...files]);
  }

  void removeSelectedFile(int index) {
    if (index < 0 || index >= state.selectedFiles.length) return;
    final updated = List<TransferFile>.from(state.selectedFiles)
      ..removeAt(index);
    state = state.copyWith(selectedFiles: updated);
  }

  void clearSelectedFiles() {
    state = state.copyWith(selectedFiles: const []);
  }

  /// Sends [files] to every member in parallel. Returns the final summary.
  Future<RoomTransferSummary?> sendFilesToAll([
    List<TransferFile>? files,
  ]) async {
    final room = state.room;
    final filesToSend = files ?? state.selectedFiles;
    if (room == null || state.role != RoomRole.host) {
      state = state.copyWith(errorMessage: 'Only the host can send files.');
      return null;
    }
    if (room.members.isEmpty) {
      state = state.copyWith(errorMessage: 'Wait for someone to join first.');
      return null;
    }
    if (filesToSend.isEmpty) {
      state = state.copyWith(errorMessage: 'Choose files to send.');
      return null;
    }

    final totalBytes =
        filesToSend.fold<int>(0, (sum, file) => sum + file.sizeInBytes);
    _manager.updateStatus(RoomStatus.transferring);
    _manager.emitEvent(
      RoomEvent(
        type: RoomEventType.transferStarted,
        roomId: room.roomId,
        data: {
          'fileCount': filesToSend.length,
          'totalBytes': totalBytes,
          'memberCount': room.members.length,
        },
      ),
    );

    try {
      final local = await _identityService.getLocalDevice();
      final summary = await _transferService.sendToAll(
        members: room.members,
        files: filesToSend,
        localDevice: local,
      );

      _manager.updateStatus(RoomStatus.completed);
      _manager.emitEvent(
        RoomEvent(
          type: RoomEventType.transferCompleted,
          roomId: room.roomId,
          data: summary.toJson(),
        ),
      );

      state = state.copyWith(
        transferSummary: summary,
        selectedFiles: const [],
        clearError: true,
      );
      return summary;
    } catch (error) {
      debugPrint('[RoomNotifier] broadcast failed: $error');
      state = state.copyWith(errorMessage: 'Broadcast failed: $error');
      return null;
    }
  }

  Future<String> _resolveLocalIp() async {
    if (kIsWeb) return '127.0.0.1';
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) return address.address;
        }
      }
    } catch (error) {
      debugPrint('[RoomNotifier] Could not resolve LAN address: $error');
    }
    return '127.0.0.1';
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _roomSubscription?.cancel();
    _summarySubscription?.cancel();
    unawaited(_server.dispose());
    unawaited(_discoveryService.dispose());
    unawaited(_manager.dispose());
    unawaited(_transferService.dispose());
    super.dispose();
  }
}

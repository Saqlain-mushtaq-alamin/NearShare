import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../discovery/domain/device.dart';
import '../../transfer/data/transfer_manager.dart';
import '../../transfer/domain/transfer_file.dart';
import '../domain/room_member.dart';
import '../domain/room_transfer_progress.dart';

/// Sends one room broadcast to a single member.
///
/// The default implementation delegates to [TransferManager], so every member
/// receives the files through the same resumable chunk protocol used for 1:1
/// transfers.
typedef RoomMemberSender = Future<void> Function(
  RoomMember member,
  List<TransferFile> files,
  Device localDevice,
);

/// Broadcasts files to every member of a room in parallel.
///
/// Failures are contained per member: one unreachable device never prevents
/// the others from receiving the files.
class RoomTransferService {
  final RoomMemberSender _sender;

  final StreamController<RoomTransferSummary> _progressController =
      StreamController<RoomTransferSummary>.broadcast();

  RoomTransferService({required RoomMemberSender sender}) : _sender = sender;

  /// Builds a service backed by the app's resumable transfer stack.
  factory RoomTransferService.withManager(TransferManager manager) {
    return RoomTransferService(
      sender: (member, files, localDevice) async {
        await manager.sendFiles(
          target: member.toDevice(),
          files: files,
          localDevice: localDevice,
        );
      },
    );
  }

  Stream<RoomTransferSummary> get onProgress => _progressController.stream;

  Future<RoomTransferSummary> sendToAll({
    required List<RoomMember> members,
    required List<TransferFile> files,
    required Device localDevice,
  }) async {
    final totalBytes = files.fold<int>(0, (sum, file) => sum + file.sizeInBytes);
    var summary = RoomTransferSummary.forMembers(
      members,
      totalBytes: totalBytes,
      totalFiles: files.length,
    );
    _emit(summary);

    await Future.wait(
      members.map((member) async {
        final offline = member.status == RoomMemberStatus.disconnected;
        if (offline) {
          summary = summary.updateMember(
            _progressFor(
              member,
              RoomMemberTransferStatus.failed,
              totalBytes: totalBytes,
              totalFiles: files.length,
              errorMessage: 'Device disconnected',
            ),
          );
          _emit(summary);
          return;
        }

        summary = summary.updateMember(
          _progressFor(
            member,
            RoomMemberTransferStatus.sending,
            totalBytes: totalBytes,
            totalFiles: files.length,
          ),
        );
        _emit(summary);

        try {
          await _sender(member, files, localDevice);
          summary = summary.updateMember(
            _progressFor(
              member,
              RoomMemberTransferStatus.completed,
              totalBytes: totalBytes,
              filesCompleted: files.length,
              totalFiles: files.length,
            ),
          );
        } catch (error) {
          debugPrint(
            '[RoomTransferService] Send to ${member.deviceName} failed: $error',
          );
          summary = summary.updateMember(
            _progressFor(
              member,
              RoomMemberTransferStatus.failed,
              totalBytes: totalBytes,
              totalFiles: files.length,
              errorMessage: error.toString(),
            ),
          );
        }
        _emit(summary);
      }),
    );

    _emit(summary);
    return summary;
  }

  RoomMemberProgress _progressFor(
    RoomMember member,
    RoomMemberTransferStatus status, {
    required int totalBytes,
    required int totalFiles,
    int filesCompleted = 0,
    String? errorMessage,
  }) {
    return RoomMemberProgress(
      deviceId: member.deviceId,
      deviceName: member.deviceName,
      status: status,
      bytesTransferred:
          status == RoomMemberTransferStatus.completed ? totalBytes : 0,
      totalBytes: totalBytes,
      filesCompleted: filesCompleted,
      totalFiles: totalFiles,
      errorMessage: errorMessage,
    );
  }

  void _emit(RoomTransferSummary summary) {
    if (!_progressController.isClosed) _progressController.add(summary);
  }

  Future<void> dispose() => _progressController.close();
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/data/qr_code_service.dart';
import 'package:nearshare/features/rooms/domain/room.dart';
import 'package:nearshare/features/rooms/domain/room_member.dart';
import 'package:nearshare/features/rooms/domain/room_transfer_progress.dart';
import 'package:nearshare/features/rooms/presentation/room_provider.dart';
import 'package:nearshare/features/rooms/presentation/room_state.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';

import 'presentation_stubs.dart';

/// A [RoomNotifier] that keeps whatever state the test seeded and never opens
/// sockets, starts mDNS or touches the network.
class StaticRoomNotifier extends RoomNotifier {
  StaticRoomNotifier(RoomState initialState)
      : super(identityService: FakeDeviceIdentityService()) {
    state = initialState;
  }

  @override
  Future<void> createRoom() async {}

  @override
  Future<void> joinRoomByCode(String rawCode) async {}

  @override
  Future<void> joinRoomWithLink(RoomJoinLink link) async {}

  @override
  Future<void> leaveRoom() async {}

  @override
  Future<void> closeRoom() async {}

  @override
  Future<RoomTransferSummary?> sendFilesToAll([
    List<TransferFile>? files,
  ]) async {
    return state.transferSummary;
  }
}

RoomMember sampleMember(
  String id, {
  String? name,
  RoomMemberStatus status = RoomMemberStatus.connected,
  String platform = 'android',
}) {
  return RoomMember(
    deviceId: id,
    deviceName: name ?? 'Device $id',
    platform: platform,
    ipAddress: '192.168.1.10',
    port: 53317,
    joinedAt: DateTime(2026, 1, 1),
    status: status,
  );
}

Room sampleRoom({
  String roomId = 'room-1',
  String roomCode = '123456',
  List<RoomMember> members = const [],
  RoomStatus status = RoomStatus.waiting,
  String hostIpAddress = '192.168.1.5',
  int hostPort = 8080,
}) {
  return Room(
    roomId: roomId,
    roomCode: roomCode,
    hostDeviceId: 'host-1',
    hostDeviceName: 'Host Device',
    hostIpAddress: hostIpAddress,
    hostPort: hostPort,
    members: members,
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

RoomState hostRoomState({
  Room? room,
  List<TransferFile> selectedFiles = const [],
  RoomTransferSummary? transferSummary,
}) {
  return RoomState(
    room: room ?? sampleRoom(),
    role: RoomRole.host,
    selectedFiles: selectedFiles,
    transferSummary: transferSummary,
  );
}

/// Uses a tall test surface so lazily-built `ListView` children below the
/// default 600px viewport are actually laid out and findable.
void useTallTestSurface(
  WidgetTester tester, {
  double width = 1080,
  double height = 2400,
}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget wrapRoomScreen(Widget child, RoomState state) {
  return ProviderScope(
    overrides: [
      roomProvider.overrideWith((ref) => StaticRoomNotifier(state)),
    ],
    child: MaterialApp(home: child),
  );
}

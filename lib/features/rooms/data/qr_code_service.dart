import '../domain/room.dart';
import 'room_code_generator.dart';

/// Decoded content of a room QR code.
class RoomJoinLink {
  final String roomCode;
  final String host;
  final int port;

  const RoomJoinLink({
    required this.roomCode,
    required this.host,
    required this.port,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomJoinLink &&
          runtimeType == other.runtimeType &&
          roomCode == other.roomCode &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode => roomCode.hashCode ^ host.hashCode ^ port.hashCode;

  @override
  String toString() => 'RoomJoinLink($roomCode, $host:$port)';
}

/// Builds and parses `nearshare://room/join` links shown as QR codes.
class QrCodeService {
  static const String scheme = 'nearshare';
  static const String host = 'room';
  static const String path = '/join';

  /// `nearshare://room/join?code=123456&host=192.168.1.5&port=8080`
  String buildJoinUri({
    required String roomCode,
    required String hostAddress,
    required int port,
  }) {
    if (!RoomCodeGenerator.isValid(roomCode)) {
      throw ArgumentError.value(roomCode, 'roomCode', 'Must be 6 digits');
    }
    if (hostAddress.trim().isEmpty) {
      throw ArgumentError.value(hostAddress, 'hostAddress', 'Must not be empty');
    }
    if (port <= 0 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Must be between 1 and 65535');
    }

    return Uri(
      scheme: scheme,
      host: host,
      path: path,
      queryParameters: {
        'code': roomCode,
        'host': hostAddress.trim(),
        'port': '$port',
      },
    ).toString();
  }

  String buildRoomUri(Room room) {
    return buildJoinUri(
      roomCode: room.roomCode,
      hostAddress: room.hostIpAddress,
      port: room.hostPort,
    );
  }

  /// Parses a scanned QR payload. Returns `null` when the payload is not a
  /// valid room link so scanners can simply ignore unrelated codes.
  RoomJoinLink? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.scheme != scheme) return null;
    if (uri.host != host) return null;
    if (uri.path != path) return null;

    final code = uri.queryParameters['code'];
    final hostAddress = uri.queryParameters['host'];
    final port = int.tryParse(uri.queryParameters['port'] ?? '');

    if (code == null || !RoomCodeGenerator.isValid(code)) return null;
    if (hostAddress == null || hostAddress.trim().isEmpty) return null;
    if (port == null || port <= 0 || port > 65535) return null;

    return RoomJoinLink(
      roomCode: code,
      host: hostAddress.trim(),
      port: port,
    );
  }
}

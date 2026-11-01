import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/data/qr_code_service.dart';
import 'package:nearshare/features/rooms/domain/room.dart';

final _fixedDate = DateTime(2026, 1, 1);

final _room = Room(
  roomId: 'room-1',
  roomCode: '123456',
  hostDeviceId: 'host-1',
  hostDeviceName: 'Host',
  hostIpAddress: '192.168.1.5',
  hostPort: 8080,
  members: const [],
  status: RoomStatus.waiting,
  createdAt: _fixedDate,
);

void main() {
  final service = QrCodeService();

  group('QrCodeService', () {
    test('encodes a room join URI', () {
      final uri = service.buildJoinUri(
        roomCode: '123456',
        hostAddress: '192.168.1.5',
        port: 8080,
      );
      expect(
        uri,
        'nearshare://room/join?code=123456&host=192.168.1.5&port=8080',
      );
    });

    test('builds a URI from a room model', () {
      expect(
        service.buildRoomUri(_room),
        'nearshare://room/join?code=123456&host=192.168.1.5&port=8080',
      );
    });

    test('parses its own payload back into a link', () {
      final uri = service.buildRoomUri(_room);
      final link = service.parse(uri);
      expect(link, const RoomJoinLink(roomCode: '123456', host: '192.168.1.5', port: 8080));
    });

    test('rejects unrelated or malformed payloads', () {
      expect(service.parse('https://example.com'), isNull);
      expect(service.parse('nearshare://room/join?code=12&host=a&port=1'), isNull);
      expect(service.parse('nearshare://other/join?code=123456&host=a&port=1'), isNull);
      expect(service.parse('nearshare://room/join?code=123456&host=a&port=0'), isNull);
      expect(service.parse(''), isNull);
    });

    test('refuses to build invalid links', () {
      expect(
        () => service.buildJoinUri(roomCode: 'abc', hostAddress: 'a', port: 1),
        throwsArgumentError,
      );
      expect(
        () => service.buildJoinUri(roomCode: '123456', hostAddress: '', port: 1),
        throwsArgumentError,
      );
      expect(
        () => service.buildJoinUri(roomCode: '123456', hostAddress: 'a', port: 0),
        throwsArgumentError,
      );
    });
  });
}

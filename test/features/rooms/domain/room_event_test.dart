import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/data/room_event_service.dart';
import 'package:nearshare/features/rooms/domain/room_event.dart';

void main() {
  group('RoomEvent', () {
    test('round-trips through JSON', () {
      final event = RoomEvent(
        type: RoomEventType.memberJoined,
        roomId: 'room-1',
        timestamp: DateTime(2026, 1, 1, 12),
        data: {'deviceId': 'a', 'memberCount': 1},
      );

      final restored = RoomEvent.fromJson(event.toJson());

      expect(restored, event);
      expect(restored.type, RoomEventType.memberJoined);
      expect(restored.data['deviceId'], 'a');
    });

    test('decodes unknown event types as a memberJoined fallback', () {
      final event = RoomEvent.fromJson({
        'type': 'futureEvent',
        'roomId': 'room-1',
        'data': <String, dynamic>{},
      });
      expect(event.type, RoomEventType.memberJoined);
    });
  });

  group('RoomEventService', () {
    test('broadcasts events and encodes the SSE wire format', () async {
      final service = RoomEventService();
      final received = <RoomEvent>[];
      final sub = service.events.listen(received.add);
      addTearDown(sub.cancel);

      final event = RoomEvent(
        type: RoomEventType.roomClosed,
        roomId: 'room-1',
        data: {'memberIds': ['a', 'b']},
      );
      service.emit(event);
      await pumpEventQueue();

      expect(received.single, event);

      final sse = RoomEventService.encodeSse(event);
      expect(sse, startsWith('event: roomClosed\n'));
      final dataLine = sse
          .split('\n')
          .firstWhere((line) => line.startsWith('data: '))
          .substring('data: '.length);
      expect(jsonDecode(dataLine), event.toJson());

      await service.close();
    });
  });
}

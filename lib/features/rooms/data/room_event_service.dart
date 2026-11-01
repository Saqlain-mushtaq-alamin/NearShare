import 'dart:async';
import 'dart:convert';

import '../domain/room_event.dart';

/// In-process pub/sub for room events.
///
/// The same events feed the host UI and the SSE endpoint served by
/// `RoomServer`, so there is only one source of truth for room activity.
class RoomEventService {
  final StreamController<RoomEvent> _controller =
      StreamController<RoomEvent>.broadcast();

  Stream<RoomEvent> get events => _controller.stream;

  bool get isClosed => _controller.isClosed;

  void emit(RoomEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  /// Serializes an event using the Server-Sent Events wire format.
  static String encodeSse(RoomEvent event) {
    return 'event: ${event.type.name}\n'
        'data: ${jsonEncode(event.toJson())}\n\n';
  }

  Stream<String> get ssePayloads => events.map(encodeSse);

  Future<void> close() => _controller.close();
}

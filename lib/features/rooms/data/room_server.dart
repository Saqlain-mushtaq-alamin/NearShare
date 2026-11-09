import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../../core/security/network_security.dart';
import '../domain/room_member.dart';
import 'room_event_service.dart';
import 'room_manager.dart';

/// HTTP endpoint exposed by the host while a room is open.
///
/// Shares the room state with [RoomManager] and streams [RoomEvent]s over
/// Server-Sent Events at `GET /api/v1/room/events`.
class RoomServer {
  final RoomManager _manager;
  final ServerSecurityConfig? _securityConfig;

  HttpServer? _server;
  int? _boundPort;

  RoomServer({
    required RoomManager manager,
    ServerSecurityConfig? securityConfig,
  })  : _manager = manager,
        _securityConfig = securityConfig;

  int? get boundPort => _boundPort;

  bool get isRunning => _server != null;

  Handler get handler => _buildRouter().call;

  Router _buildRouter() {
    final router = Router();
    router.post('/api/v1/room/join', _handleJoin);
    router.get('/api/v1/room/info', _handleInfo);
    router.post('/api/v1/room/leave', _handleLeave);
    router.delete('/api/v1/room', _handleClose);
    router.get('/api/v1/room/events', _handleEvents);
    return router;
  }

  Future<int> start({int? port}) async {
    if (kIsWeb) {
      debugPrint('[RoomServer] HTTP server skipped on Web');
      _boundPort = port ?? 0;
      return _boundPort!;
    }

    await stop();

    final securityConfig = _securityConfig;
    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(
          securityConfig == null
              ? (inner) => inner
              : (inner) => securityMiddleware(inner, config: securityConfig),
        )
        .addHandler(handler);

    try {
      _server = await shelf_io.serve(
        pipeline,
        InternetAddress.anyIPv4,
        port ?? 0,
      );
    } catch (e) {
      debugPrint('[RoomServer] Preferred port $port unavailable: $e');
      _server = await shelf_io.serve(pipeline, InternetAddress.anyIPv4, 0);
    }

    _boundPort = _server!.port;
    debugPrint('[RoomServer] Listening on port $_boundPort');
    return _boundPort!;
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _boundPort = null;
  }

  Future<void> dispose() => stop();

  Future<Response> _handleJoin(Request request) async {
    try {
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final code = data['roomCode'] as String? ?? '';
      final member = RoomMember.fromJson(data);

      final result = _manager.handleJoinRequest(
        roomCode: code,
        member: member,
      );

      if (result.accepted) {
        return _json(200, {
          'accepted': true,
          'reason': null,
          'room': result.room!.toJson(),
        });
      }
      return _json(403, {
        'accepted': false,
        'reason': result.reason!.name,
        'message': result.message,
      });
    } catch (e, stack) {
      debugPrint('[RoomServer] Join error: $e\n$stack');
      return _jsonError(400, 'Invalid join request');
    }
  }

  Response _handleInfo(Request request) {
    final room = _manager.currentRoom;
    if (room == null) {
      return _jsonError(404, 'No active room');
    }
    return _json(200, {'room': room.toJson()});
  }

  Future<Response> _handleLeave(Request request) async {
    try {
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final deviceId = data['deviceId'] as String? ?? '';
      final removed = _manager.leaveRoom(deviceId);
      return _json(200, {'left': removed, 'deviceId': deviceId});
    } catch (e) {
      return _jsonError(400, 'Invalid leave request');
    }
  }

  Future<Response> _handleClose(Request request) async {
    final room = _manager.currentRoom;
    await _manager.closeRoom();
    return _json(200, {
      'closed': true,
      'roomId': room?.roomId ?? '',
    });
  }

  Future<Response> _handleEvents(Request request) async {
    final controller = StreamController<List<int>>();
    late final StreamSubscription subscription;

    subscription = _manager.events.listen(
      (event) {
        if (!controller.isClosed) {
          controller.add(
            utf8.encode(RoomEventService.encodeSse(event)),
          );
        }
      },
      onError: (Object error) {
        if (!controller.isClosed) controller.addError(error);
      },
    );

    controller.onCancel = () async {
      await subscription.cancel();
      await controller.close();
    };

    return Response.ok(
      controller.stream,
      headers: const {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
        'connection': 'keep-alive',
      },
    );
  }

  static const Map<String, String> _jsonHeaders = {
    'content-type': 'application/json',
  };

  Response _json(int status, Map<String, dynamic> body) {
    return Response(status, body: jsonEncode(body), headers: _jsonHeaders);
  }

  Response _jsonError(int status, String message) {
    return _json(status, {'error': message});
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/room.dart';
import '../domain/room_member.dart';
import 'room_manager.dart';

class RoomClientException implements Exception {
  final String message;
  final int? statusCode;
  final JoinRejectionReason? rejectionReason;

  const RoomClientException(
    this.message, {
    this.statusCode,
    this.rejectionReason,
  });

  @override
  String toString() => 'RoomClientException: $message';
}

/// Member-side HTTP client for talking to a host's [RoomServer].
class RoomClient {
  final Dio _dio;

  RoomClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
              ),
            );

  String _base(String hostIp, int port) => 'http://$hostIp:$port';

  /// Asks the host to join a room. Throws [RoomClientException] when rejected.
  Future<Room> join({
    required String hostIp,
    required int port,
    required String roomCode,
    required RoomMember self,
  }) async {
    final response = await _dio.post(
      '${_base(hostIp, port)}/api/v1/room/join',
      data: {
        ...self.toJson(),
        'roomCode': roomCode,
      },
      options: Options(
        headers: {'content-type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final rawRoom = data['room'];
      if (rawRoom is Map<String, dynamic>) {
        return Room.fromJson(rawRoom);
      }
      throw const RoomClientException('Host returned an invalid room payload');
    }

    if (response.statusCode == 403 && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final reason = JoinRejectionReason.values.firstWhere(
        (value) => value.name == data['reason'],
        orElse: () => JoinRejectionReason.invalidCode,
      );
      throw RoomClientException(
        reason.message,
        statusCode: response.statusCode,
        rejectionReason: reason,
      );
    }

    throw RoomClientException(
      'Join failed with status ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  /// Fetches the latest room snapshot. Returns `null` when the host no longer
  /// knows the room (closed or unreachable).
  Future<Room?> fetchRoom({
    required String hostIp,
    required int port,
  }) async {
    try {
      final response = await _dio.get(
        '${_base(hostIp, port)}/api/v1/room/info',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic>) {
        final rawRoom = (response.data as Map<String, dynamic>)['room'];
        if (rawRoom is Map<String, dynamic>) return Room.fromJson(rawRoom);
      }
      return null;
    } catch (e) {
      debugPrint('[RoomClient] Fetch info error: $e');
      return null;
    }
  }

  Future<bool> leave({
    required String hostIp,
    required int port,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post(
        '${_base(hostIp, port)}/api/v1/room/leave',
        data: {'deviceId': deviceId},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[RoomClient] Leave error: $e');
      return false;
    }
  }

  Future<bool> close({
    required String hostIp,
    required int port,
  }) async {
    try {
      final response = await _dio.delete(
        '${_base(hostIp, port)}/api/v1/room',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[RoomClient] Close error: $e');
      return false;
    }
  }
}

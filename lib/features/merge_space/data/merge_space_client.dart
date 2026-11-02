import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/merge_space_file.dart';
import '../domain/paired_device.dart';
import 'merge_crypto.dart';
import 'merge_protocol.dart';

/// Device-side HTTP client for a Merge Space peer.
class MergeSpaceClient {
  final Dio _dio;
  final MergeCrypto _crypto;

  MergeSpaceClient({Dio? dio, MergeCrypto? crypto})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
              ),
            ),
        _crypto = crypto ?? MergeCrypto();

  /// Registers this device with a peer that owns [groupId].
  Future<DeviceGroup> pair({
    required String host,
    required int port,
    required String groupId,
    required String groupKey,
    required PairedDevice localDevice,
  }) async {
    final response = await _dio.post(
      '${MergeProtocol.baseUrl(host, port)}${MergeProtocol.pairPath}',
      data: {
        'groupId': groupId,
        'keyHash': MergeCrypto.fingerprint(groupKey),
        'device': localDevice.toJson(),
      },
      options: Options(
        headers: const {'content-type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final rawGroup = (response.data as Map<String, dynamic>)['group'];
      if (rawGroup is Map<String, dynamic>) {
        return DeviceGroup.fromJson(rawGroup);
      }
    }
    throw MergeClientException(
      _errorMessage(response.data, 'Pairing was rejected'),
      statusCode: response.statusCode,
    );
  }

  /// Sends this device's index and returns the peer's index.
  Future<List<MergeSpaceFile>> exchangeIndex({
    required String host,
    required int port,
    required String groupId,
    required String groupKey,
    required String deviceId,
    required List<MergeSpaceFile> files,
  }) async {
    final payload = await _crypto.encrypt(
      utf8.encode(
        jsonEncode({
          'groupId': groupId,
          'deviceId': deviceId,
          'files': files.map((file) => file.toJson()).toList(),
        }),
      ),
      groupKey: groupKey,
    );

    final response = await _dio.post(
      '${MergeProtocol.baseUrl(host, port)}${MergeProtocol.indexPath}',
      data: payload,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'content-type': 'application/octet-stream',
          MergeProtocol.groupHeader: groupId,
          MergeProtocol.deviceHeader: deviceId,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw MergeClientException(
        'Index exchange failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final encrypted = _asBytes(response.data);
    final clear = await _crypto.decrypt(encrypted, groupKey: groupKey);
    final data = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
    final rawFiles = data['files'] as List<dynamic>? ?? const [];
    return rawFiles
        .map((file) => MergeSpaceFile.fromJson(file as Map<String, dynamic>))
        .toList();
  }

  /// Encrypts and uploads one file. The peer verifies the hash after decrypting.
  Future<void> uploadFile({
    required String host,
    required int port,
    required String groupId,
    required String groupKey,
    required String deviceId,
    required MergeSpaceFile file,
    required List<int> bytes,
  }) async {
    final encrypted = await _crypto.encrypt(bytes, groupKey: groupKey);
    final response = await _dio.post(
      '${MergeProtocol.baseUrl(host, port)}${MergeProtocol.filesPath}',
      data: encrypted,
      queryParameters: {'path': file.relativePath},
      options: Options(
        headers: {
          'content-type': 'application/octet-stream',
          MergeProtocol.groupHeader: groupId,
          MergeProtocol.deviceHeader: deviceId,
          MergeProtocol.hashHeader: file.hash,
          MergeProtocol.originHeader: file.originDeviceId,
          MergeProtocol.modifiedHeader: file.modifiedAt.toIso8601String(),
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw MergeClientException(
        _errorMessage(response.data, 'Upload failed'),
        statusCode: response.statusCode,
      );
    }
  }

  /// Downloads and decrypts one file from a peer.
  Future<Uint8List> downloadFile({
    required String host,
    required int port,
    required String groupId,
    required String groupKey,
    required String deviceId,
    required String relativePath,
  }) async {
    final response = await _dio.get(
      '${MergeProtocol.baseUrl(host, port)}${MergeProtocol.filesPath}',
      queryParameters: {'path': relativePath},
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          MergeProtocol.groupHeader: groupId,
          MergeProtocol.deviceHeader: deviceId,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw MergeClientException(
        'Download failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return _crypto.decrypt(_asBytes(response.data), groupKey: groupKey);
  }

  /// Notifies a peer that a file was deleted locally.
  Future<void> deleteRemoteFile({
    required String host,
    required int port,
    required String groupId,
    required String deviceId,
    required String relativePath,
  }) async {
    final response = await _dio.delete(
      '${MergeProtocol.baseUrl(host, port)}${MergeProtocol.filesPath}',
      queryParameters: {'path': relativePath},
      options: Options(
        headers: {
          MergeProtocol.groupHeader: groupId,
          MergeProtocol.deviceHeader: deviceId,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    if (response.statusCode != 200) {
      throw MergeClientException(
        'Delete failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  Future<bool> isReachable({
    required String host,
    required int port,
    required String groupId,
  }) async {
    try {
      final response = await _dio.get(
        '${MergeProtocol.baseUrl(host, port)}${MergeProtocol.healthPath}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          headers: {MergeProtocol.groupHeader: groupId},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Uint8List _asBytes(dynamic data) {
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    if (data is List) return Uint8List.fromList(data.cast<int>());
    throw const MergeClientException('Peer returned a non-binary payload');
  }

  static String _errorMessage(dynamic data, String fallback) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }
}

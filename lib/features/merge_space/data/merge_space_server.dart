import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as sha;
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../../core/security/network_security.dart';
import '../domain/merge_space_file.dart';
import '../domain/paired_device.dart';
import 'merge_crypto.dart';
import 'merge_protocol.dart';
import 'merge_space_storage.dart';

typedef MergeGroupProvider = DeviceGroup? Function();
typedef MergePairHandler = Future<DeviceGroup> Function(PairedDevice device);
typedef MergeIndexProvider = Future<List<MergeSpaceFile>> Function();
typedef MergeFileHandler = Future<void> Function(MergeSpaceFile file);
typedef MergeDeleteHandler = Future<void> Function(
  String relativePath,
  String deviceId,
);

/// HTTP endpoint exposed by every member of a Merge Space group.
class MergeSpaceServer {
  final MergeGroupProvider _groupProvider;
  final MergePairHandler _onPair;
  final MergeIndexProvider _buildIndex;
  final MergeFileHandler _onFileReceived;
  final MergeDeleteHandler _onRemoteDelete;
  final MergeSpaceStorage _storage;
  final MergeCrypto _crypto;
  final String Function() _localDeviceId;
  final ServerSecurityConfig? _securityConfig;

  HttpServer? _server;
  int? _boundPort;

  MergeSpaceServer({
    required MergeGroupProvider groupProvider,
    required MergePairHandler onPair,
    required MergeIndexProvider buildIndex,
    required MergeFileHandler onFileReceived,
    required MergeDeleteHandler onRemoteDelete,
    required MergeSpaceStorage storage,
    required String Function() localDeviceId,
    MergeCrypto? crypto,
    ServerSecurityConfig? securityConfig,
  })  : _securityConfig = securityConfig,
        _groupProvider = groupProvider,
        _onPair = onPair,
        _buildIndex = buildIndex,
        _onFileReceived = onFileReceived,
        _onRemoteDelete = onRemoteDelete,
        _storage = storage,
        _localDeviceId = localDeviceId,
        _crypto = crypto ?? MergeCrypto();

  int? get boundPort => _boundPort;

  bool get isRunning => _server != null;

  Handler get handler => _buildRouter().call;

  Router _buildRouter() {
    final router = Router();
    router.get(MergeProtocol.healthPath, _handleHealth);
    router.get(MergeProtocol.statusPath, _handleStatus);
    router.post(MergeProtocol.pairPath, _handlePair);
    router.post(MergeProtocol.indexPath, _handleIndex);
    router.get(MergeProtocol.filesPath, _handleDownload);
    router.post(MergeProtocol.filesPath, _handleUpload);
    router.delete(MergeProtocol.filesPath, _handleDelete);
    return router;
  }

  Future<int> start({int? port}) async {
    if (kIsWeb) {
      debugPrint('[MergeSpaceServer] HTTP server skipped on Web');
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
    } catch (error) {
      debugPrint('[MergeSpaceServer] Port $port unavailable: $error');
      _server = await shelf_io.serve(pipeline, InternetAddress.anyIPv4, 0);
    }

    _boundPort = _server!.port;
    debugPrint('[MergeSpaceServer] Listening on port $_boundPort');
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

  Response _handleHealth(Request request) {
    final group = _groupProvider();
    if (group == null) {
      return _jsonError(503, 'Merge Space is not active');
    }
    final requested = request.headers[MergeProtocol.groupHeader];
    if (requested != null && requested != group.groupId) {
      return _jsonError(403, 'Unknown Merge Space group');
    }
    return _json(200, {
      'ok': true,
      'groupId': group.groupId,
      'deviceId': _localDeviceId(),
    });
  }

  Future<Response> _handleStatus(Request request) async {
    final group = await _authorized(request);
    if (group == null) return _jsonError(403, 'Not authorized');

    final files = await _buildIndex();
    return _json(200, {
      'groupId': group.groupId,
      'deviceId': _localDeviceId(),
      'fileCount': files.where((file) => !file.isDeleted).length,
      'tombstoneCount': files.where((file) => file.isDeleted).length,
    });
  }

  Future<Response> _handlePair(Request request) async {
    try {
      final group = _groupProvider();
      if (group == null) return _jsonError(503, 'Merge Space is not active');

      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final requestedGroupId = data['groupId'] as String? ?? '';
      final keyHash = data['keyHash'] as String? ?? '';
      final rawDevice = data['device'];

      if (requestedGroupId != group.groupId) {
        return _jsonError(403, 'Unknown Merge Space group');
      }
      if (keyHash != MergeCrypto.fingerprint(group.groupKey)) {
        return _jsonError(403, 'Pairing key does not match');
      }
      if (rawDevice is! Map<String, dynamic>) {
        return _jsonError(400, 'Missing device details');
      }

      final device =
          PairedDevice.fromJson(rawDevice).copyWith(groupId: group.groupId);
      if (device.deviceId.isEmpty) {
        return _jsonError(400, 'Missing device id');
      }

      final updated = await _onPair(device);
      return _json(
        200,
        {'ok': true, 'group': updated.copyWith(groupKey: '').toJson()},
      );
    } catch (error, stack) {
      debugPrint('[MergeSpaceServer] Pair error: $error\n$stack');
      return _jsonError(400, 'Invalid pairing request');
    }
  }

  Future<Response> _handleIndex(Request request) async {
    try {
      final group = await _authorized(request);
      if (group == null) return _jsonError(403, 'Not authorized');

      final encrypted = Uint8List.fromList(await _readBody(request));
      final clear = await _crypto.decrypt(
        encrypted,
        groupKey: group.groupKey,
      );
      final data = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      final requestedGroupId = data['groupId'] as String? ?? '';
      if (requestedGroupId != group.groupId) {
        return _jsonError(403, 'Unknown Merge Space group');
      }

      final files = await _buildIndex();
      final payload = await _crypto.encrypt(
        utf8.encode(
          jsonEncode({
            'groupId': group.groupId,
            'deviceId': _localDeviceId(),
            'files': files.map((file) => file.toJson()).toList(),
          }),
        ),
        groupKey: group.groupKey,
      );
      return Response.ok(
        payload,
        headers: const {'content-type': 'application/octet-stream'},
      );
    } catch (error, stack) {
      debugPrint('[MergeSpaceServer] Index error: $error\n$stack');
      return _jsonError(400, 'Invalid index request');
    }
  }

  Future<Response> _handleUpload(Request request) async {
    try {
      final group = await _authorized(request);
      if (group == null) return _jsonError(403, 'Not authorized');

      final relativePath = request.url.queryParameters['path'] ?? '';
      if (!MergeSpaceStorage.isSafeRelativePath(relativePath)) {
        return _jsonError(400, 'Unsafe file path');
      }

      final encrypted = Uint8List.fromList(await _readBody(request));
      if (encrypted.length > MergeProtocol.maxEncryptedFileBytes) {
        return _jsonError(413, 'File is too large');
      }
      final bytes = await _crypto.decrypt(encrypted, groupKey: group.groupKey);
      if (bytes.length > MergeProtocol.maxEncryptedFileBytes) {
        return _jsonError(413, 'File is too large');
      }

      final expectedHash = request.headers[MergeProtocol.hashHeader] ?? '';
      final actualHash = sha.sha256.convert(bytes).toString();
      if (expectedHash.isNotEmpty && expectedHash != actualHash) {
        return _jsonError(422, 'File hash mismatch');
      }

      final origin =
          request.headers[MergeProtocol.originHeader] ?? _localDeviceId();
      final modified = DateTime.tryParse(
            request.headers[MergeProtocol.modifiedHeader] ?? '',
          ) ??
          DateTime.now();
      final deviceId = request.headers[MergeProtocol.deviceHeader] ?? '';

      await _storage.writeBytes(relativePath, bytes);
      final file = MergeSpaceFile(
        relativePath: MergeSpaceStorage.normalizeRelative(relativePath),
        hash: actualHash,
        baseHash: actualHash,
        sizeBytes: bytes.length,
        modifiedAt: modified,
        originDeviceId: origin,
      );
      await _onFileReceived(file);

      return _json(200, {
        'ok': true,
        'path': file.relativePath,
        'hash': file.hash,
        'from': deviceId,
      });
    } catch (error, stack) {
      debugPrint('[MergeSpaceServer] Upload error: $error\n$stack');
      return _jsonError(400, 'Invalid upload request');
    }
  }

  Future<Response> _handleDownload(Request request) async {
    try {
      final group = await _authorized(request);
      if (group == null) return _jsonError(403, 'Not authorized');

      final relativePath = request.url.queryParameters['path'] ?? '';
      if (!MergeSpaceStorage.isSafeRelativePath(relativePath)) {
        return _jsonError(400, 'Unsafe file path');
      }
      if (!await _storage.exists(relativePath)) {
        return _jsonError(404, 'File not found');
      }

      final bytes = await _storage.readBytes(relativePath);
      final payload = await _crypto.encrypt(bytes, groupKey: group.groupKey);
      return Response.ok(
        payload,
        headers: const {'content-type': 'application/octet-stream'},
      );
    } catch (error, stack) {
      debugPrint('[MergeSpaceServer] Download error: $error\n$stack');
      return _jsonError(400, 'Invalid download request');
    }
  }

  Future<Response> _handleDelete(Request request) async {
    try {
      final group = await _authorized(request);
      if (group == null) return _jsonError(403, 'Not authorized');

      final relativePath = request.url.queryParameters['path'] ?? '';
      if (!MergeSpaceStorage.isSafeRelativePath(relativePath)) {
        return _jsonError(400, 'Unsafe file path');
      }
      final deviceId = request.headers[MergeProtocol.deviceHeader] ?? '';

      await _storage.delete(relativePath);
      await _onRemoteDelete(relativePath, deviceId);
      return _json(200, {'ok': true, 'path': relativePath});
    } catch (error, stack) {
      debugPrint('[MergeSpaceServer] Delete error: $error\n$stack');
      return _jsonError(400, 'Invalid delete request');
    }
  }

  Future<DeviceGroup?> _authorized(Request request) async {
    final group = _groupProvider();
    if (group == null) return null;
    final requested = request.headers[MergeProtocol.groupHeader];
    if (requested == null || requested != group.groupId) return null;

    final deviceId = request.headers[MergeProtocol.deviceHeader] ?? '';
    if (deviceId.isEmpty) return null;
    final isMember = group.devices.any(
      (device) => device.deviceId == deviceId,
    );
    return isMember ? group : null;
  }

  Future<List<int>> _readBody(Request request) {
    return request.read().fold<List<int>>(
      <int>[],
      (buffer, chunk) => buffer..addAll(chunk),
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

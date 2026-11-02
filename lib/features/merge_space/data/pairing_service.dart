import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../domain/paired_device.dart';
import 'merge_crypto.dart';

/// Decoded content of a Merge Space pairing QR code.
class MergePairingLink {
  final String groupId;
  final String groupKey;
  final String host;
  final int port;

  const MergePairingLink({
    required this.groupId,
    required this.groupKey,
    required this.host,
    required this.port,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MergePairingLink &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          groupKey == other.groupKey &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode =>
      groupId.hashCode ^ groupKey.hashCode ^ host.hashCode ^ port.hashCode;

  @override
  String toString() => 'MergePairingLink($groupId, $host:$port)';
}

/// Builds and parses `nearshare://merge/pair` links.
class PairingService {
  static const String scheme = 'nearshare';
  static const String host = 'merge';
  static const String path = '/pair';

  final Uuid _uuid;

  PairingService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  DeviceGroup createGroup({DateTime? now}) {
    return DeviceGroup(
      groupId: _uuid.v4(),
      groupKey: MergeCrypto.generateGroupKey(),
      devices: const [],
      createdAt: now ?? DateTime.now(),
    );
  }

  /// `nearshare://merge/pair?groupId=...&key=...&host=192.168.1.5&port=8080`
  String buildUri({
    required DeviceGroup group,
    required String hostAddress,
    required int port,
  }) {
    if (group.groupId.trim().isEmpty) {
      throw ArgumentError.value(group.groupId, 'groupId', 'Must not be empty');
    }
    if (group.groupKey.trim().isEmpty) {
      throw ArgumentError.value(group.groupKey, 'groupKey', 'Must not be empty');
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
        'groupId': group.groupId,
        'key': group.groupKey,
        'host': hostAddress.trim(),
        'port': '$port',
      },
    ).toString();
  }

  MergePairingLink? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.scheme != scheme) return null;
    if (uri.host != host) return null;
    if (uri.path != path) return null;

    final groupId = uri.queryParameters['groupId'];
    final groupKey = uri.queryParameters['key'];
    final hostAddress = uri.queryParameters['host'];
    final port = int.tryParse(uri.queryParameters['port'] ?? '');

    if (groupId == null || groupId.trim().isEmpty) return null;
    if (groupKey == null || groupKey.trim().isEmpty) return null;
    if (hostAddress == null || hostAddress.trim().isEmpty) return null;
    if (port == null || port <= 0 || port > 65535) return null;

    try {
      final bytes = base64Decode(groupKey.trim());
      if (bytes.length != MergeCrypto.keyLengthBytes) {
        return null;
      }
    } catch (_) {
      return null;
    }

    return MergePairingLink(
      groupId: groupId.trim(),
      groupKey: groupKey.trim(),
      host: hostAddress.trim(),
      port: port,
    );
  }
}

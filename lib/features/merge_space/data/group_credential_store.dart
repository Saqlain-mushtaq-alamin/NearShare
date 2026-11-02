import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/paired_device.dart';

/// Persists the group id and AES key on the device.
abstract class GroupCredentialStore {
  Future<MergedGroupCredentials?> load();

  Future<void> save(MergedGroupCredentials credentials);

  Future<void> clear();
}

/// Secure storage backed implementation used by the app.
class SecureGroupCredentialStore implements GroupCredentialStore {
  static const String storageKey = 'nearshare_merge_credentials';

  final FlutterSecureStorage _storage;

  SecureGroupCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<MergedGroupCredentials?> load() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final credentials = MergedGroupCredentials.fromJson(json);
      if (credentials.groupId.isEmpty || credentials.groupKey.isEmpty) {
        return null;
      }
      return credentials;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(MergedGroupCredentials credentials) {
    return _storage.write(
      key: storageKey,
      value: jsonEncode(credentials.toJson()),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: storageKey);
}

/// In-memory store for tests and headless hosts.
class InMemoryGroupCredentialStore implements GroupCredentialStore {
  MergedGroupCredentials? _credentials;

  MergedGroupCredentials? get credentials => _credentials;

  @override
  Future<MergedGroupCredentials?> load() async => _credentials;

  @override
  Future<void> save(MergedGroupCredentials credentials) async {
    _credentials = credentials;
  }

  @override
  Future<void> clear() async {
    _credentials = null;
  }
}

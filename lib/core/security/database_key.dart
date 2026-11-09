import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

/// Makes the sqlite3 package load SQLCipher's ABI-compatible library.
///
/// Android needs an explicit override; other platforms pick up the bundled
/// SQLCipher library automatically.
void configureSqlCipher() {
  if (kIsWeb) return;
  try {
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }
  } catch (e) {
    debugPrint('[DatabaseKeyService] SQLCipher setup failed: $e');
  }
}

/// Opens Drift databases through SQLCipher using a key from secure storage.
class DatabaseKeyService {
  DatabaseKeyService({
    required this.storageKey,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static final DatabaseKeyService history = DatabaseKeyService(
    storageKey: 'nearshare_database_key_v1',
  );
  static final DatabaseKeyService mergeSpace = DatabaseKeyService(
    storageKey: 'nearshare_merge_database_key_v1',
  );

  final String storageKey;
  final FlutterSecureStorage _storage;
  Future<String>? _cachedKey;

  Future<String> getOrCreateKey() {
    return _cachedKey ??= _readOrCreate();
  }

  Future<String> _readOrCreate() async {
    final existing = await _storage.read(key: storageKey);
    if (existing != null && existing.length >= 32) {
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final generated = base64UrlEncode(bytes);
    await _storage.write(key: storageKey, value: generated);
    return generated;
  }

  Future<NativeDatabase> openFile(File file) async {
    final key = await getOrCreateKey();
    return NativeDatabase(
      file,
      setup: (database) {
        database.execute("PRAGMA key = '$key';");
        database.execute('PRAGMA cipher_memory_security = ON;');
        if (database.select('PRAGMA cipher_version;').isEmpty) {
          throw StateError(
            'SQLCipher is not available; refusing to open unencrypted data',
          );
        }
      },
    );
  }

  @visibleForTesting
  Future<NativeDatabase> openInMemory() async {
    return NativeDatabase.memory();
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/transfer_session.dart';
import 'local/transfer_session_database.dart';

/// Persistence contract for resumable [TransferSession] state.
///
/// Implementations must survive process termination so interrupted transfers
/// can be listed and resumed after an app restart.
abstract class TransferSessionRepository {
  Future<void> saveSession(TransferSession session);

  Future<TransferSession?> getSession(String transferId);

  Future<List<TransferSession>> getAllSessions();

  /// Sessions that are not finished (pending, in progress or paused).
  Future<List<TransferSession>> getIncompleteSessions();

  Future<void> deleteSession(String transferId);

  /// Removes sessions whose last activity is older than [maxAge] and returns
  /// the removed rows so callers can clean up their temporary files.
  Future<List<TransferSession>> deleteStaleSessions({
    Duration maxAge = const Duration(hours: 24),
    DateTime? now,
  });

  Future<void> close();
}

/// Default location of the NearShare SQLite database.
Future<File> defaultDatabaseFile() async {
  final Directory baseDir = await _resolveBaseDirectory();
  final dir = Directory(p.join(baseDir.path, 'NearShare'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return File(p.join(dir.path, 'nearshare.db'));
}

Future<Directory> _resolveBaseDirectory() async {
  try {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  } catch (_) {
    return await getTemporaryDirectory();
  }
}

/// SQLite backed repository using `drift`.
class DriftTransferSessionRepository implements TransferSessionRepository {
  final TransferSessionDatabase _db;
  final bool _ownsDatabase;

  DriftTransferSessionRepository(this._db, {bool ownsDatabase = true})
      : _ownsDatabase = ownsDatabase;

  /// Opens (or creates) the database file at [path].
  factory DriftTransferSessionRepository.open(String path) {
    return DriftTransferSessionRepository(
      TransferSessionDatabase(NativeDatabase(File(path))),
    );
  }

  /// An isolated, throw-away database that lives only in memory.
  ///
  /// Used by unit tests.
  factory DriftTransferSessionRepository.inMemory() {
    return DriftTransferSessionRepository(
      TransferSessionDatabase(NativeDatabase.memory()),
    );
  }

  /// Lazily resolves the platform documents directory on first query.
  factory DriftTransferSessionRepository.openDefault() {
    final db = TransferSessionDatabase(
      LazyDatabase(
        () async {
          final file = await defaultDatabaseFile();
          return NativeDatabase(file);
        },
      ),
    );
    return DriftTransferSessionRepository(db);
  }

  @override
  Future<void> saveSession(TransferSession session) async {
    await _db.into(_db.sessionRecords).insertOnConflictUpdate(
          _toCompanion(session),
        );
  }

  @override
  Future<TransferSession?> getSession(String transferId) async {
    final query = _db.select(_db.sessionRecords)
      ..where((t) => t.transferId.equals(transferId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<TransferSession>> getAllSessions() async {
    final rows = await _db.select(_db.sessionRecords).get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<TransferSession>> getIncompleteSessions() async {
    final rows = await _db.select(_db.sessionRecords).get();
    return rows
        .map(_fromRow)
        .where((s) => s.status.isIncomplete)
        .toList()
      ..sort((a, b) => b.lastActivityAtOrStart.compareTo(a.lastActivityAtOrStart));
  }

  @override
  Future<void> deleteSession(String transferId) async {
    await (_db.delete(_db.sessionRecords)
          ..where((t) => t.transferId.equals(transferId)))
        .go();
  }

  @override
  Future<List<TransferSession>> deleteStaleSessions({
    Duration maxAge = const Duration(hours: 24),
    DateTime? now,
  }) async {
    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    final rows = await _db.select(_db.sessionRecords).get();
    final stale = rows
        .map(_fromRow)
        .where((s) => s.lastActivityAtOrStart.isBefore(cutoff))
        .toList();

    if (stale.isEmpty) return const [];

    for (final session in stale) {
      await deleteSession(session.transferId);
    }
    return stale;
  }

  @override
  Future<void> close() async {
    if (_ownsDatabase) {
      await _db.close();
    }
  }

  SessionRecordsCompanion _toCompanion(TransferSession session) {
    return SessionRecordsCompanion(
      transferId: Value(session.transferId),
      peerId: Value(session.peerId),
      peerName: Value(session.peerName),
      peerIp: Value(session.peerIp),
      peerPort: Value(session.peerPort),
      direction: Value(session.direction.name),
      status: Value(session.status.name),
      chunkSize: Value(session.chunkSize),
      localDeviceId: Value(session.localDeviceId),
      localDeviceName: Value(session.localDeviceName),
      filesJson: Value(jsonEncode(session.files.map((f) => f.toJson()).toList())),
      receivedChunksJson: Value(
        jsonEncode(
          session.receivedChunksPerFile.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        ),
      ),
      fileSavePathsJson: Value(
        jsonEncode(
          session.fileSavePaths.map((key, value) => MapEntry(key.toString(), value)),
        ),
      ),
      startedAt: Value(session.startedAt),
      lastActivityAt: Value(session.lastActivityAt),
      completedAt: Value(session.completedAt),
      errorMessage: Value(session.errorMessage),
    );
  }

  TransferSession _fromRow(SessionRecord row) {
    return TransferSession.fromJson({
      'transferId': row.transferId,
      'peerId': row.peerId,
      'peerName': row.peerName,
      'peerIp': row.peerIp,
      'peerPort': row.peerPort,
      'direction': row.direction,
      'status': row.status,
      'chunkSize': row.chunkSize,
      'localDeviceId': row.localDeviceId,
      'localDeviceName': row.localDeviceName,
      'files': jsonDecode(row.filesJson),
      'receivedChunksPerFile': jsonDecode(row.receivedChunksJson),
      'fileSavePaths': jsonDecode(row.fileSavePathsJson),
      'startedAt': row.startedAt.toIso8601String(),
      'lastActivityAt': row.lastActivityAt?.toIso8601String(),
      'completedAt': row.completedAt?.toIso8601String(),
      'errorMessage': row.errorMessage,
    });
  }
}

/// Repository backed by a plain in-memory map.
///
/// Useful for widget tests that only need session bookkeeping.
class InMemoryTransferSessionRepository implements TransferSessionRepository {
  final Map<String, TransferSession> _sessions = {};

  @override
  Future<void> saveSession(TransferSession session) async {
    _sessions[session.transferId] = session;
  }

  @override
  Future<TransferSession?> getSession(String transferId) async {
    return _sessions[transferId];
  }

  @override
  Future<List<TransferSession>> getAllSessions() async {
    return _sessions.values.toList()
      ..sort((a, b) => b.lastActivityAtOrStart.compareTo(a.lastActivityAtOrStart));
  }

  @override
  Future<List<TransferSession>> getIncompleteSessions() async {
    return _sessions.values.where((s) => s.status.isIncomplete).toList()
      ..sort((a, b) => b.lastActivityAtOrStart.compareTo(a.lastActivityAtOrStart));
  }

  @override
  Future<void> deleteSession(String transferId) async {
    _sessions.remove(transferId);
  }

  @override
  Future<List<TransferSession>> deleteStaleSessions({
    Duration maxAge = const Duration(hours: 24),
    DateTime? now,
  }) async {
    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    final stale = _sessions.values
        .where((s) => s.lastActivityAtOrStart.isBefore(cutoff))
        .toList();
    for (final session in stale) {
      _sessions.remove(session.transferId);
    }
    return stale;
  }

  @override
  Future<void> close() async {
    _sessions.clear();
  }
}

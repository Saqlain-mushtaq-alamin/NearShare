import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/security/database_key.dart';

part 'history_database.g.dart';

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
    // path_provider is unavailable (unit tests, bare shells). Fall back to an
    // isolated temp directory so the database still behaves like SQLite.
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      return Directory.systemTemp.createTempSync('nearshare_db_');
    }
  }
}

/// Opens (or creates) the app-wide database, resolving the platform documents
/// directory lazily on first query.
///
/// Widget tests build many short-lived [ProviderScope]s, each of which may
/// open this database, so drift's "database created twice" warning is not
/// meaningful here.
NearShareDatabase openDefaultNearShareDatabase() {
  driftRuntimeOptions = DriftRuntimeOptions()
    ..dontWarnAboutMultipleDatabases = true;
  return NearShareDatabase(
    LazyDatabase(
      () async {
        final file = await defaultDatabaseFile();
        return DatabaseKeyService.history.openFile(file);
      },
    ),
  );
}

/// Resumable transfer session state (Phase 3).
///
/// Complex structures (file list, received-chunk map, save paths) are stored
/// as JSON documents so the row stays flat and easy to migrate.
class SessionRecords extends Table {
  TextColumn get transferId => text()();
  TextColumn get peerId => text()();
  TextColumn get peerName => text()();
  TextColumn get peerIp => text().nullable()();
  IntColumn get peerPort => integer().nullable()();
  TextColumn get direction => text()();
  TextColumn get status => text()();
  IntColumn get chunkSize => integer()();
  TextColumn get localDeviceId => text().nullable()();
  TextColumn get localDeviceName => text().nullable()();
  TextColumn get filesJson => text()();
  TextColumn get receivedChunksJson => text()();
  TextColumn get fileSavePathsJson => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get lastActivityAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {transferId};
}

/// One row per finished transfer, shown on the history screen.
///
/// Drift derives the row class name from the table name, so the prefix keeps
/// [TransferHistoryRecord] distinct from the domain `TransferRecord`.
class TransferHistoryRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transferId => text().unique()();
  TextColumn get direction => text()();
  TextColumn get peerDeviceId => text()();
  TextColumn get peerDeviceName => text()();
  IntColumn get totalFiles => integer()();
  IntColumn get totalSizeBytes => integer()();
  TextColumn get status => text()();
  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// The individual files that made up a finished transfer.
class TransferHistoryFileRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transferId => text().references(
        TransferHistoryRecords,
        #transferId,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get fileName => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get mimeType => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get status => text()();
}

/// The single SQLite database used by NearShare.
///
/// Version 1 (Phases 2-3) only had [SessionRecords]. Phase 4 added the
/// transfer-history tables on top of it so resumable sessions and history
/// share one file and one connection.
@DriftDatabase(
  tables: [SessionRecords, TransferHistoryRecords, TransferHistoryFileRecords],
)
class NearShareDatabase extends _$NearShareDatabase {
  NearShareDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  TransferHistoryDao get historyDao => TransferHistoryDao(this);

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(transferHistoryRecords);
            await m.createTable(transferHistoryFileRecords);
          }
        },
      );
}

/// Queries for reading and writing the transfer history.
@DriftAccessor(
  tables: [TransferHistoryRecords, TransferHistoryFileRecords],
)
class TransferHistoryDao extends DatabaseAccessor<NearShareDatabase>
    with _$TransferHistoryDaoMixin {
  TransferHistoryDao(super.db);

  /// Replaces the record and its files atomically, keyed by [transferId].
  ///
  /// `insertOnConflictUpdate` would target the auto-increment primary key, so
  /// re-saving an existing transfer id would trip the unique constraint
  /// instead of updating. Deleting first keeps the behaviour explicit.
  Future<void> upsertRecord(
    TransferHistoryRecordsCompanion record,
    List<TransferHistoryFileRecordsCompanion> files,
  ) {
    return transaction(() async {
      await (delete(db.transferHistoryFileRecords)
            ..where(
              (t) => t.transferId.equals(record.transferId.value),
            ))
          .go();
      await (delete(db.transferHistoryRecords)
            ..where(
              (t) => t.transferId.equals(record.transferId.value),
            ))
          .go();
      await into(db.transferHistoryRecords).insert(record);
      for (final file in files) {
        await into(db.transferHistoryFileRecords).insert(file);
      }
    });
  }

  Stream<List<TransferHistoryRecord>> watchAll({
    String? direction,
    String? deviceId,
    int? limit,
  }) {
    final query = select(db.transferHistoryRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    if (direction != null) {
      query.where((t) => t.direction.equals(direction));
    }
    if (deviceId != null) {
      query.where((t) => t.peerDeviceId.equals(deviceId));
    }
    if (limit != null) query.limit(limit);
    return query.watch();
  }

  Future<TransferHistoryRecord?> findById(String transferId) {
    final query = select(db.transferHistoryRecords)
      ..where((t) => t.transferId.equals(transferId))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<List<TransferHistoryFileRecord>> findFiles(String transferId) {
    final query = select(db.transferHistoryFileRecords)
      ..where((t) => t.transferId.equals(transferId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }

  Future<void> deleteRecord(String transferId) {
    return transaction(() async {
      await (delete(db.transferHistoryFileRecords)
            ..where((t) => t.transferId.equals(transferId)))
          .go();
      await (delete(db.transferHistoryRecords)
            ..where((t) => t.transferId.equals(transferId)))
          .go();
    });
  }

  Future<void> clearAll() {
    return transaction(() async {
      await delete(db.transferHistoryFileRecords).go();
      await delete(db.transferHistoryRecords).go();
    });
  }
}

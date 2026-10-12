import 'package:drift/drift.dart';

part 'transfer_session_database.g.dart';

/// Raw storage for resumable transfer sessions.
///
/// Complex structures ([TransferFile] list, received-chunk map, save paths) are
/// stored as JSON documents so the row stays flat and easy to migrate.
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

@DriftDatabase(tables: [SessionRecords])
class TransferSessionDatabase extends _$TransferSessionDatabase {
  TransferSessionDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

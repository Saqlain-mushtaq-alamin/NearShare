import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

class MergeSpaceFiles extends Table {
  TextColumn get relativePath => text()();
  TextColumn get hash => text()();
  TextColumn get baseHash => text().nullable()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get modifiedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get originDeviceId => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {relativePath};
}

class PairedDevices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  TextColumn get platform => text()();
  TextColumn get groupId => text()();
  DateTimeColumn get pairedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pendingSync'))();

  @override
  Set<Column> get primaryKey => {deviceId};
}

class SyncConflicts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get relativePath => text()();
  TextColumn get localHash => text()();
  TextColumn get remoteHash => text()();
  TextColumn get localVersionJson => text()();
  TextColumn get remoteVersionJson => text()();
  TextColumn get remoteDeviceId => text()();
  DateTimeColumn get detectedAt => dateTime()();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();
}

Future<File> defaultMergeSpaceDatabaseFile() async {
  final Directory baseDir = await _resolveBaseDirectory();
  final dir = Directory(p.join(baseDir.path, 'NearShare'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return File(p.join(dir.path, 'nearshare_merge.db'));
}

Future<Directory> _resolveBaseDirectory() async {
  try {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  } catch (_) {
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      return Directory.systemTemp.createTempSync('nearshare_merge_db_');
    }
  }
}

MergeSpaceDatabase openDefaultMergeSpaceDatabase() {
  driftRuntimeOptions = DriftRuntimeOptions()
    ..dontWarnAboutMultipleDatabases = true;
  return MergeSpaceDatabase(
    LazyDatabase(() async {
      final file = await defaultMergeSpaceDatabaseFile();
      return NativeDatabase(file);
    }),
  );
}

MergeSpaceDatabase openInMemoryMergeSpaceDatabase() {
  driftRuntimeOptions = DriftRuntimeOptions()
    ..dontWarnAboutMultipleDatabases = true;
  return MergeSpaceDatabase(NativeDatabase.memory());
}

@DriftDatabase(tables: [MergeSpaceFiles, PairedDevices, SyncConflicts])
class MergeSpaceDatabase extends _$MergeSpaceDatabase {
  MergeSpaceDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

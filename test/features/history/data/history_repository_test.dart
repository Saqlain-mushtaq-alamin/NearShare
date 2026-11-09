import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/history/data/history_database.dart';
import 'package:nearshare/features/history/data/history_repository.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';

TransferRecord buildRecord({
  required String transferId,
  required DateTime timestamp,
  TransferDirection direction = TransferDirection.sending,
  String peerId = 'peer-1',
  String peerName = 'Laptop',
  int totalFiles = 1,
  int totalSizeBytes = 100,
  TransferRecordStatus status = TransferRecordStatus.completed,
  List<TransferFileRecord>? files,
}) {
  return TransferRecord(
    transferId: transferId,
    direction: direction,
    peerDeviceId: peerId,
    peerDeviceName: peerName,
    totalFiles: totalFiles,
    totalSizeBytes: totalSizeBytes,
    status: status,
    timestamp: timestamp,
    completedAt: timestamp.add(const Duration(minutes: 1)),
    files: files ??
        [
          TransferFileRecord(
            fileName: '$transferId.txt',
            fileSizeBytes: totalSizeBytes,
            mimeType: 'text/plain',
            localPath: '/tmp/$transferId.txt',
            status: TransferRecordStatus.completed,
          ),
        ],
  );
}

Future<List<TransferRecord>> drain(Stream<List<TransferRecord>> stream) {
  return stream.first;
}

void main() {
  group('HistoryRepository drift database', () {
    late NearShareDatabase db;
    late DriftHistoryRepository repository;

    setUp(() {
      db = NearShareDatabase(NativeDatabase.memory());
      repository = DriftHistoryRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('inserts and queries a single record', () async {
      await repository.saveTransferRecord(
        buildRecord(transferId: 'a', timestamp: DateTime(2026, 1, 1)),
      );

      final all = await drain(repository.getAllRecords());
      expect(all, hasLength(1));
      expect(all.first.transferId, 'a');
      expect(all.first.peerDeviceName, 'Laptop');
      expect(all.first.status, TransferRecordStatus.completed);
    });

    test('inserts a record together with its file rows', () async {
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 'files-1',
          timestamp: DateTime(2026, 1, 2),
          totalFiles: 2,
          totalSizeBytes: 300,
          files: const [
            TransferFileRecord(
              fileName: 'one.txt',
              fileSizeBytes: 100,
              mimeType: 'text/plain',
              localPath: '/tmp/one.txt',
              status: TransferRecordStatus.completed,
            ),
            TransferFileRecord(
              fileName: 'two.txt',
              fileSizeBytes: 200,
              mimeType: 'text/plain',
              localPath: '/tmp/two.txt',
              status: TransferRecordStatus.failed,
            ),
          ],
        ),
      );

      final loaded = await repository.getRecordById('files-1');
      expect(loaded, isNotNull);
      expect(loaded!.files, hasLength(2));
      expect(loaded.files[0].fileName, 'one.txt');
      expect(loaded.files[0].status, TransferRecordStatus.completed);
      expect(loaded.files[1].fileName, 'two.txt');
      expect(loaded.files[1].status, TransferRecordStatus.failed);
      expect(loaded.files[1].localPath, '/tmp/two.txt');
    });

    test('re-saving the same transferId replaces the record and its files',
        () async {
      await repository.saveTransferRecord(
        buildRecord(transferId: 'up', timestamp: DateTime(2026, 1, 1)),
      );
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 'up',
          timestamp: DateTime(2026, 1, 1),
          status: TransferRecordStatus.failed,
          files: const [
            TransferFileRecord(
              fileName: 'only.txt',
              fileSizeBytes: 10,
              mimeType: 'text/plain',
              status: TransferRecordStatus.failed,
            ),
          ],
        ),
      );

      final all = await drain(repository.getAllRecords());
      expect(all, hasLength(1));
      expect(all.first.status, TransferRecordStatus.failed);
      expect(all.first.files, hasLength(1));
      expect(all.first.files.single.fileName, 'only.txt');
    });

    test('getAllRecords returns records newest first', () async {
      await repository.saveTransferRecord(
        buildRecord(transferId: 'old', timestamp: DateTime(2026, 1, 1)),
      );
      await repository.saveTransferRecord(
        buildRecord(transferId: 'new', timestamp: DateTime(2026, 3, 1)),
      );
      await repository.saveTransferRecord(
        buildRecord(transferId: 'mid', timestamp: DateTime(2026, 2, 1)),
      );

      final all = await drain(repository.getAllRecords());
      expect(all.map((r) => r.transferId).toList(), ['new', 'mid', 'old']);
    });

    test('filters by direction', () async {
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 'sent',
          timestamp: DateTime(2026, 1, 2),
          direction: TransferDirection.sending,
        ),
      );
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 'recv',
          timestamp: DateTime(2026, 1, 1),
          direction: TransferDirection.receiving,
          peerId: 'peer-2',
          peerName: 'Tablet',
        ),
      );

      final sent =
          await drain(repository.getAllRecords(filter: TransferDirection.sending));
      expect(sent.map((r) => r.transferId), ['sent']);

      final received = await drain(
        repository.getAllRecords(filter: TransferDirection.receiving),
      );
      expect(received.map((r) => r.transferId), ['recv']);
    });

    test('filters by device id', () async {
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 'd1',
          timestamp: DateTime(2026, 1, 1),
          peerId: 'peer-1',
        ),
      );
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 'd2',
          timestamp: DateTime(2026, 1, 2),
          peerId: 'peer-2',
          peerName: 'Tablet',
        ),
      );

      final byDevice =
          await drain(repository.getRecordsByDevice('peer-2'));
      expect(byDevice.map((r) => r.transferId), ['d2']);

      final filtered = await drain(
        repository.getAllRecords(deviceFilter: 'peer-1'),
      );
      expect(filtered.map((r) => r.transferId), ['d1']);
    });

    test('search matches file names and peer names', () async {
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 's1',
          timestamp: DateTime(2026, 1, 1),
          peerName: 'Laptop',
          files: const [
            TransferFileRecord(
              fileName: 'holiday.jpg',
              fileSizeBytes: 5,
              mimeType: 'image/jpeg',
              status: TransferRecordStatus.completed,
            ),
          ],
        ),
      );
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 's2',
          timestamp: DateTime(2026, 1, 2),
          peerId: 'peer-9',
          peerName: 'Tablet',
          files: const [
            TransferFileRecord(
              fileName: 'notes.txt',
              fileSizeBytes: 5,
              mimeType: 'text/plain',
              status: TransferRecordStatus.completed,
            ),
          ],
        ),
      );

      final byFile =
          await drain(repository.getAllRecords(search: 'holiday'));
      expect(byFile.map((r) => r.transferId), ['s1']);

      final byPeer = await drain(repository.getAllRecords(search: 'tablet'));
      expect(byPeer.map((r) => r.transferId), ['s2']);

      final none = await drain(repository.getAllRecords(search: 'zzz'));
      expect(none, isEmpty);
    });

    test('deleteRecord removes the record and its file rows', () async {
      await repository.saveTransferRecord(
        buildRecord(transferId: 'gone', timestamp: DateTime(2026, 1, 1)),
      );
      await repository.saveTransferRecord(
        buildRecord(transferId: 'kept', timestamp: DateTime(2026, 1, 2)),
      );

      await repository.deleteRecord('gone');

      expect(await repository.getRecordById('gone'), isNull);
      final files = await db.historyDao.findFiles('gone');
      expect(files, isEmpty);

      final remaining = await drain(repository.getAllRecords());
      expect(remaining.map((r) => r.transferId), ['kept']);
    });

    test('clearAllHistory empties both tables', () async {
      await repository.saveTransferRecord(
        buildRecord(transferId: 'c1', timestamp: DateTime(2026, 1, 1)),
      );
      await repository.saveTransferRecord(
        buildRecord(transferId: 'c2', timestamp: DateTime(2026, 1, 2)),
      );

      await repository.clearAllHistory();

      expect(await drain(repository.getAllRecords()), isEmpty);
      expect(await repository.getRecordById('c1'), isNull);
      expect(await db.select(db.transferHistoryRecords).get(), isEmpty);
      expect(await db.select(db.transferHistoryFileRecords).get(), isEmpty);
    });

    test('getRecentRecords limits the result set', () async {
      for (var i = 0; i < 5; i++) {
        await repository.saveTransferRecord(
          buildRecord(transferId: 'r$i', timestamp: DateTime(2026, 1, i + 1)),
        );
      }

      final recent = await drain(repository.getRecentRecords(2));
      expect(recent.map((r) => r.transferId), ['r4', 'r3']);
    });

    test('watch stream emits again after a write', () async {
      final emissions = <List<TransferRecord>>[];
      final sub = repository.getAllRecords().listen(emissions.add);

      await repository.saveTransferRecord(
        buildRecord(transferId: 'live', timestamp: DateTime(2026, 1, 1)),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.map((r) => r.transferId), contains('live'));
      await sub.cancel();
    });

    test('creates both the session and history tables on a fresh database',
        () async {
      expect(db.schemaVersion, 2);
      final tables = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
      ).get();
      final names =
          tables.map((row) => row.data.values.first as String).toSet();
      expect(names, containsAll(<String>{'session_records'}));
      expect(names, containsAll(<String>{'transfer_history_records'}));
      expect(names, containsAll(<String>{'transfer_history_file_records'}));
    });

    test('upgrades a phase 3 database by creating only the history tables',
        () async {
      // Phase 3 shipped schemaVersion 1 with just the session table. Recreate
      // that shape, stamp user_version = 1, then open the current database so
      // drift runs the 1 -> 2 upgrade path.
      final executor = NativeDatabase.memory(
        setup: (db) {
          db.execute(
            'CREATE TABLE session_records ('
            'transfer_id TEXT NOT NULL PRIMARY KEY, '
            'peer_id TEXT NOT NULL, peer_name TEXT NOT NULL, '
            'peer_ip TEXT, peer_port INTEGER, direction TEXT NOT NULL, '
            'status TEXT NOT NULL, chunk_size INTEGER NOT NULL, '
            'local_device_id TEXT, local_device_name TEXT, '
            'files_json TEXT NOT NULL, received_chunks_json TEXT NOT NULL, '
            'file_save_paths_json TEXT NOT NULL, started_at INTEGER NOT NULL, '
            'last_activity_at INTEGER, completed_at INTEGER, '
            'error_message TEXT)',
          );
          db.execute(
            'INSERT INTO session_records (transfer_id, peer_id, peer_name, '
            'direction, status, chunk_size, files_json, '
            'received_chunks_json, file_save_paths_json, started_at) '
            "VALUES ('keep', 'p', 'P', 'sending', 'completed', 1024, "
            "'[]', '{}', '{}', 0)",
          );
          db.execute('PRAGMA user_version = 1');
        },
      );

      final upgraded = NearShareDatabase(executor);
      final tables = await upgraded.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
      ).get();
      final names =
          tables.map((row) => row.data.values.first as String).toSet();
      expect(names, contains('session_records'));
      expect(names, contains('transfer_history_records'));
      expect(names, contains('transfer_history_file_records'));

      // The pre-existing session row survives the upgrade.
      final kept = await upgraded
          .customSelect('SELECT transfer_id FROM session_records')
          .get();
      expect(kept.single.data.values.first, 'keep');
      expect(upgraded.schemaVersion, 2);

      await upgraded.close();
    });
  });

  group('InMemoryHistoryRepository', () {
    late InMemoryHistoryRepository repository;

    setUp(() {
      repository = InMemoryHistoryRepository();
    });

    test('saves, lists and deletes records', () async {
      await repository.saveTransferRecord(
        buildRecord(transferId: 'm1', timestamp: DateTime(2026, 1, 1)),
      );
      await repository.saveTransferRecord(
        buildRecord(transferId: 'm2', timestamp: DateTime(2026, 1, 2)),
      );

      final all = await drain(repository.getAllRecords());
      expect(all.map((r) => r.transferId), ['m2', 'm1']);

      await repository.deleteRecord('m2');
      final after = await drain(repository.getAllRecords());
      expect(after.map((r) => r.transferId), ['m1']);
    });

    test('filters by direction, device and search', () async {
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 'f1',
          timestamp: DateTime(2026, 1, 1),
          direction: TransferDirection.sending,
          peerName: 'Laptop',
        ),
      );
      await repository.saveTransferRecord(
        buildRecord(
          transferId: 'f2',
          timestamp: DateTime(2026, 1, 2),
          direction: TransferDirection.receiving,
          peerId: 'peer-2',
          peerName: 'Tablet',
        ),
      );

      final sent =
          await drain(repository.getAllRecords(filter: TransferDirection.sending));
      expect(sent.map((r) => r.transferId), ['f1']);

      final tablet =
          await drain(repository.getAllRecords(deviceFilter: 'peer-2'));
      expect(tablet.map((r) => r.transferId), ['f2']);

      final byName = await drain(repository.getAllRecords(search: 'laptop'));
      expect(byName.map((r) => r.transferId), ['f1']);
    });

    test('clearAllHistory empties the store', () async {
      await repository.saveTransferRecord(
        buildRecord(transferId: 'x', timestamp: DateTime(2026, 1, 1)),
      );
      await repository.clearAllHistory();
      expect(await drain(repository.getAllRecords()), isEmpty);
    });
  });
}

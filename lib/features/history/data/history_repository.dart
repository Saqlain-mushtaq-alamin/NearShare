import 'package:drift/drift.dart';
import 'package:drift/native.dart' show NativeDatabase;

import '../../transfer/domain/transfer_session.dart' show TransferDirection;
import '../domain/transfer_record.dart';
import 'history_database.dart';

export '../../transfer/domain/transfer_session.dart' show TransferDirection;

/// Persistence contract for the local transfer history.
///
/// History is written by `TransferManager` (sends) and `TransferServer`
/// (receives) the moment a transfer reaches a terminal state, and is read by
/// the history UI. Everything lives on-device and can be wiped by the user.
abstract class HistoryRepository {
  /// Stores (or replaces) [record] together with its file list.
  ///
  /// Keyed by [TransferRecord.transferId], so calling this twice for the same
  /// transfer keeps the latest outcome.
  Future<void> saveTransferRecord(TransferRecord record);

  /// Every record, newest first, optionally narrowed by direction, device or a
  /// free-text query over the peer and file names.
  Stream<List<TransferRecord>> getAllRecords({
    TransferDirection? filter,
    String? deviceFilter,
    String? search,
  });

  Stream<List<TransferRecord>> getRecordsByDevice(String deviceId);

  Future<TransferRecord?> getRecordById(String transferId);

  /// Removes the record and cascade-deletes its file rows.
  Future<void> deleteRecord(String transferId);

  /// Wipes every history table.
  Future<void> clearAllHistory();

  Stream<List<TransferRecord>> getRecentRecords(int limit);

  /// Releases any underlying resources.
  Future<void> close();
}

/// SQLite backed [HistoryRepository] sharing the app-wide drift database.
class DriftHistoryRepository implements HistoryRepository {
  final NearShareDatabase _db;
  final bool _ownsDatabase;

  DriftHistoryRepository(this._db, {bool ownsDatabase = false})
      : _ownsDatabase = ownsDatabase;

  /// An isolated, throw-away database that lives only in memory.
  ///
  /// Used by unit tests.
  factory DriftHistoryRepository.inMemory() {
    return DriftHistoryRepository(
      NearShareDatabase(NativeDatabase.memory()),
      ownsDatabase: true,
    );
  }

  @override
  Future<void> saveTransferRecord(TransferRecord record) {
    final companion = TransferHistoryRecordsCompanion(
      transferId: Value(record.transferId),
      direction: Value(record.direction.name),
      peerDeviceId: Value(record.peerDeviceId),
      peerDeviceName: Value(record.peerDeviceName),
      totalFiles: Value(record.totalFiles),
      totalSizeBytes: Value(record.totalSizeBytes),
      status: Value(record.status.name),
      timestamp: Value(record.timestamp),
      completedAt: Value(record.completedAt),
    );

    final files = [
      for (final file in record.files)
        TransferHistoryFileRecordsCompanion(
          transferId: Value(record.transferId),
          fileName: Value(file.fileName),
          fileSizeBytes: Value(file.fileSizeBytes),
          mimeType: Value(file.mimeType),
          localPath: Value(file.localPath),
          status: Value(file.status.name),
        ),
    ];

    return _db.historyDao.upsertRecord(companion, files);
  }

  @override
  Stream<List<TransferRecord>> getAllRecords({
    TransferDirection? filter,
    String? deviceFilter,
    String? search,
  }) {
    return _watch(
      direction: filter?.name,
      deviceId: deviceFilter,
      search: search,
    );
  }

  @override
  Stream<List<TransferRecord>> getRecordsByDevice(String deviceId) {
    return _watch(deviceId: deviceId);
  }

  @override
  Future<TransferRecord?> getRecordById(String transferId) async {
    final row = await _db.historyDao.findById(transferId);
    if (row == null) return null;
    final files = await _db.historyDao.findFiles(transferId);
    return _toDomain(row, files);
  }

  @override
  Future<void> deleteRecord(String transferId) {
    return _db.historyDao.deleteRecord(transferId);
  }

  @override
  Future<void> clearAllHistory() {
    return _db.historyDao.clearAll();
  }

  @override
  Stream<List<TransferRecord>> getRecentRecords(int limit) {
    return _watch(limit: limit);
  }

  @override
  Future<void> close() async {
    if (_ownsDatabase) {
      await _db.close();
    }
  }

  /// Re-runs the record query whenever the record table changes, attaching the
  /// file rows in the same batched read.
  Stream<List<TransferRecord>> _watch({
    String? direction,
    String? deviceId,
    String? search,
    int? limit,
  }) {
    final needle = search?.trim().toLowerCase();
    return _db.historyDao
        .watchAll(direction: direction, deviceId: deviceId, limit: limit)
        .asyncMap((rows) async {
      final records = <TransferRecord>[];
      for (final row in rows) {
        final files = await _db.historyDao.findFiles(row.transferId);
        records.add(_toDomain(row, files));
      }
      if (needle == null || needle.isEmpty) return records;
      return records.where((r) => r.matchesSearch(needle)).toList();
    });
  }

  TransferRecord _toDomain(
    TransferHistoryRecord row,
    List<TransferHistoryFileRecord> files,
  ) {
    return TransferRecord(
      transferId: row.transferId,
      direction: TransferDirection.fromName(row.direction),
      peerDeviceId: row.peerDeviceId,
      peerDeviceName: row.peerDeviceName,
      totalFiles: row.totalFiles,
      totalSizeBytes: row.totalSizeBytes,
      status: TransferRecordStatus.fromName(row.status),
      timestamp: row.timestamp,
      completedAt: row.completedAt,
      files: [
        for (final file in files)
          TransferFileRecord(
            fileName: file.fileName,
            fileSizeBytes: file.fileSizeBytes,
            mimeType: file.mimeType,
            localPath: file.localPath,
            status: TransferRecordStatus.fromName(file.status),
          ),
      ],
    );
  }
}

/// Repository backed by a plain in-memory map.
///
/// Useful for widget tests that only need history bookkeeping.
class InMemoryHistoryRepository implements HistoryRepository {
  final Map<String, TransferRecord> _records = {};

  @override
  Future<void> saveTransferRecord(TransferRecord record) async {
    _records[record.transferId] = record;
  }

  @override
  Stream<List<TransferRecord>> getAllRecords({
    TransferDirection? filter,
    String? deviceFilter,
    String? search,
  }) {
    return Stream.value(
      _sorted()
          .where(
            (r) =>
                (filter == null || r.direction == filter) &&
                (deviceFilter == null || r.peerDeviceId == deviceFilter) &&
                (search == null || r.matchesSearch(search)),
          )
          .toList(),
    );
  }

  @override
  Stream<List<TransferRecord>> getRecordsByDevice(String deviceId) {
    return Stream.value(
      _sorted().where((r) => r.peerDeviceId == deviceId).toList(),
    );
  }

  @override
  Future<TransferRecord?> getRecordById(String transferId) async {
    return _records[transferId];
  }

  @override
  Future<void> deleteRecord(String transferId) async {
    _records.remove(transferId);
  }

  @override
  Future<void> clearAllHistory() async {
    _records.clear();
  }

  @override
  Stream<List<TransferRecord>> getRecentRecords(int limit) {
    return Stream.value(_sorted().take(limit).toList());
  }

  @override
  Future<void> close() async {
    _records.clear();
  }

  List<TransferRecord> _sorted() {
    return _records.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

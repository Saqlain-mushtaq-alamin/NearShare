import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'history_database.dart';
import 'history_repository.dart';

/// The one SQLite database shared by resumable sessions and transfer history.
final nearShareDatabaseProvider = Provider<NearShareDatabase>((ref) {
  final db = openDefaultNearShareDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Reads and writes the local transfer history.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return DriftHistoryRepository(ref.watch(nearShareDatabaseProvider));
});

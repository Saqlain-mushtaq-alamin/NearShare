# NearShare Phase 4 Development Plan: Transfer History & Resend

## Context
- **Status:** Phases 1-3 are complete (device discovery, file transfer, and resumable transfers work).
- **Framework:** Flutter + Riverpod.
- **Local DB:** drift (formerly moor) ORM for SQLite.
- **Privacy:** No cloud storage — history is 100% local and clearable by the user at any time.
- **Current State:** Transfer sessions from Phase 3 already use SQLite; Phase 4 extends the DB to provide full transfer history.

---

## 4.1 Database Schema

Design the drift database tables to store both transfer records and their associated file details.

```dart
import 'package:drift/drift.dart';

// TransferRecords table
class TransferRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transferId => text().unique()();
  TextColumn get direction => text()();          // 'sent' or 'received'
  TextColumn get peerDeviceId => text()();
  TextColumn get peerDeviceName => text()();
  IntColumn get totalFiles => integer()();
  IntColumn get totalSizeBytes => integer()();
  TextColumn get status => text()();              // 'completed', 'failed', 'cancelled'
  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

// TransferFileRecords table
class TransferFileRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transferId => text().references(TransferRecords, #transferId)();
  TextColumn get fileName => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get mimeType => text()();
  TextColumn get localPath => text().nullable()();  // path where file is saved (received) or was sent from
  TextColumn get status => text()();                // 'completed', 'failed'
}
```

---

## 4.2 Domain Models

Under `lib/features/history/domain/`:

```dart
enum TransferDirection { sent, received }
enum TransferRecordStatus { completed, failed, cancelled }

class TransferRecord {
  final String transferId;
  final TransferDirection direction;
  final String peerDeviceId;
  final String peerDeviceName;
  final int totalFiles;
  final int totalSizeBytes;
  final TransferRecordStatus status;
  final DateTime timestamp;
  final DateTime? completedAt;
  final List<TransferFileRecord> files;

  TransferRecord({
    required this.transferId,
    required this.direction,
    required this.peerDeviceId,
    required this.peerDeviceName,
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.status,
    required this.timestamp,
    this.completedAt,
    required this.files,
  });
}

class TransferFileRecord {
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String? localPath;
  final TransferRecordStatus status;

  TransferFileRecord({
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    this.localPath,
    required this.status,
  });
}
```

---

## 4.3 Data Layer

Under `lib/features/history/data/`:

### `history_database.dart`
- Drift database definition compiling `TransferRecords` and `TransferFileRecords`.
- Define database migrations (from version 1 → future versions).
- Create a DAO (Data Access Object) to organize queries related to transfer history.

### `history_repository.dart`
Implement `HistoryRepository` to interface between the data layer and domain logic:
- `Future<void> saveTransferRecord(TransferRecord record)` — called by `TransferManager` when a transfer completes/fails/cancels.
- `Stream<List<TransferRecord>> getAllRecords({TransferDirection? filter, String? deviceFilter})` — yields records matching filters.
- `Stream<List<TransferRecord>> getRecordsByDevice(String deviceId)`
- `Future<TransferRecord?> getRecordById(String transferId)`
- `Future<void> deleteRecord(String transferId)` — deletes the transfer and cascade-deletes associated files.
- `Future<void> clearAllHistory()` — wipes all history tables.
- `Stream<List<TransferRecord>> getRecentRecords(int limit)`

---

## 4.4 Integration with Transfer Manager

Update `lib/features/transfer/application/transfer_manager.dart` (created in Phases 2/3):
- Listen to transfer completion events (success, fail, or cancel).
- Construct a `TransferRecord` summarizing the operation (including iterating over the transferred files to build `TransferFileRecord` list).
- Call `historyRepository.saveTransferRecord(record)`.
- Ensure this happens reliably even if the app process is terminated shortly after completion.

---

## 4.5 Presentation Layer

Under `lib/features/history/presentation/`:

### `history_provider.dart`
- Riverpod provider (`historyProvider` or a `Notifier`) that watches the `HistoryRepository` stream.
- Exposes `List<TransferRecord>` sorted by date (newest first).
- Provides methods for updating filters: by direction (sent/received), by device, or by file type.
- Exposes delete and clear methods to UI.

### `history_screen.dart`
- Main history view consisting of a chronological list of transfer records.
- Each item displays:
  - Direction icon (↑ sent / ↓ received).
  - Peer device name.
  - File count & total size.
  - Timestamp & status indicator (e.g., green check, red cross).
- Features filter chips: All | Sent | Received.
- Search bar for querying by device name or file name.
- Empty state UI: "No transfer history yet" with illustrative graphic.

### `history_detail_screen.dart`
- Detail view for a specific `TransferRecord`.
- Lists individual files with thumbnails (for images/video) or file type icons (for docs/archives).
- Displays individual file name, size, and type.
- **For sent items:** Includes a "Resend" button to trigger the resend flow.
- **For received items:** Includes "Open File" / "Open Folder" buttons launching native OS handlers.

### `history_item_widget.dart`
- Reusable list item widget for `history_screen.dart`.
- Includes swipe actions: resend (swipe right), delete (swipe left).
- Tap gesture navigates to `history_detail_screen.dart`.

---

## 4.6 Resend Feature

When the user triggers a "Resend" on a history item:
1. Verify File Integrity: Check if the original files still exist at their logged `localPath`.
2. Pre-fill Flow:
   - If files exist, initialize the send flow with these files pre-attached.
   - Look up the target device's ID in the currently discovered devices list; if present, pre-select it to save time.
3. Error Handling: If any files are missing or moved, show a snackbar or dialog stating: "Some files are no longer available at their original locations."

---

## 4.7 Navigation Updates

Add a persistent bottom navigation bar to the app:
- Tabs: Home | History | Rooms (placeholder) | Settings (placeholder).

Router paths (`go_router` or similar):
- `/history` → Renders `HistoryScreen`.
- `/history/:transferId` → Renders `HistoryDetailScreen`.

---

## Tests

### Unit Tests (minimum 10)
1. Drift database — insert and query a `TransferRecord`.
2. Drift database — insert a `TransferRecord` with associated `TransferFileRecords`.
3. `HistoryRepository` — `getAllRecords` returns records in correct chronological order.
4. `HistoryRepository` — filter by direction works correctly.
5. `HistoryRepository` — filter by device works correctly.
6. `HistoryRepository` — `deleteRecord` removes record and associated file records.
7. `HistoryRepository` — `clearAllHistory` empties both tables.
8. TransferManager integration — completed transfer is reliably saved to history.
9. TransferManager integration — failed/cancelled transfer is saved to history with correct status.
10. Resend logic — correctly identifies missing files vs existing files.

### Widget Tests (minimum 5)
1. `HistoryScreen` — shows empty state when no history exists.
2. `HistoryScreen` — renders list of records with correct information.
3. `HistoryScreen` — filter chips (All, Sent, Received) filter UI list correctly.
4. `HistoryDetailScreen` — shows file list and appropriate action buttons (Resend / Open).
5. `HistoryItemWidget` — displays direction, device name, and file count accurately.

### Integration Tests
1. Complete a successful transfer → verify it appears in the history database and UI.
2. Complete 5 varied transfers → verify all appear in correct chronological order.
3. Tap "Resend" → verify send flow is pre-filled with correct files and device targeting.
4. Delete a record from the UI → verify it's removed from the list and database.
5. Clear all history → verify the empty state appears immediately.

---

## Acceptance Criteria
- [ ] Drift database schema created with `TransferRecords`, `TransferFileRecords` tables, and DAOs.
- [ ] Completed/failed/cancelled transfers are automatically saved to local history.
- [ ] History screen shows all past transfers sorted by date.
- [ ] Filter by direction (sent/received) works.
- [ ] Individual transfer detail view correctly shows file list.
- [ ] Resend feature pre-fills send flow with original files and target device.
- [ ] Resend handles missing/moved files gracefully with appropriate user feedback.
- [ ] Delete individual record and clear all history work as intended.
- [ ] Bottom navigation added with dedicated History tab.
- [ ] All unit tests pass (minimum 10).
- [ ] All widget tests pass (minimum 5).
- [ ] `flutter analyze` passes with no issues.
- [ ] Code committed with tag `phase-4-complete`.

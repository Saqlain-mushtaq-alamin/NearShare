# Phase 7: Merge Space (Automatic Sync)

## Goals
- Implement a private, owner-only shared folder that auto-syncs across all paired devices.
- Establish a "sync-when-nearby" model (no cloud relay) leveraging mDNS for discovery.
- Create a robust sync engine that handles file diffing, change tracking, and conflict resolution.
- Ensure all synced data is encrypted using a symmetric group key.
- Provide a clear and intuitive UI for setting up Merge Space, viewing sync status, and resolving conflicts.
- Implement platform-specific background synchronization mechanisms.

## Prerequisites
- Phases 1-6 complete (fully functional P2P transfer app with room-based sharing).
- Existing underlying networking and transfer protocols from earlier phases to handle file payloads.
- Drift database setup for storing file indexes and device groups.
- `pointycastle` or `cryptography` package integrated for AES-256-GCM encryption.
- Platform-specific background task runner packages (e.g., `workmanager` for Android, native channels for Desktop).

## 7.1 Merge Space Concept
- **What it is:** A designated folder on each device that stays continuously in sync with paired devices.
- **How it works:** When two paired devices are on the same network, they automatically discover each other via mDNS and sync any new, modified, or deleted files.
- **Model:** Works similarly to Syncthing/Resilio. It is not a cloud sync; devices sync locally when nearby.
- **Local Availability:** Each device maintains a full local copy of the Merge Space, allowing offline access to all files.

## 7.2 Device Pairing Protocol
**Path:** `lib/features/merge_space/data/`

Pairing creates a "Device Group" — a trusted ring of devices sharing a Merge Space.
1. **Initiation:** The first device generates:
   - A Group ID (UUID v4).
   - A Group Key (256-bit symmetric key for encryption).
   - A pairing payload encoded as a QR code or fallback pairing string:
     `nearshare://merge/pair?groupId=<ID>&key=<KEY>&host=<IP>&port=<PORT>`
2. **Joining:** The second device scans the QR code or inputs the pairing string.
3. **Handshake:** The joining device connects to the host device, exchanges device info (name, platform, device ID), and both securely store the group credentials.
4. **Persistence:** Group credentials must be stored securely using `flutter_secure_storage` or an encrypted SharedPreferences layer.

## 7.3 Sync Engine & Protocol (Detailed)
**Path:** `lib/features/merge_space/data/`

The core of the sync operation relies on maintaining an accurate local file index and efficiently comparing it with peers.

### `file_index.dart`
- **Role:** Tracks all files within the local Merge Space folder.
- **Mechanism:** Computes a SHA-256 hash of the file content for change detection.
- **Metadata:** Tracks relative path, hash, size, modification timestamp, and a soft-delete flag (`isDeleted`).
- **Storage:** Persisted locally via Drift SQLite.

### `sync_engine.dart`
- **Role:** Orchestrates the synchronization logic between devices.
1. **Index Comparison:** When a paired device is discovered, exchange the full local file index.
2. **Diff Calculation:** Determine the delta state:
   - **New (Local/Remote):** File exists on one device but not the other.
   - **Modified:** File exists on both but hashes differ.
   - **Deleted:** Soft delete flag is active on one device.
   - **Conflicted:** The same file was modified on both devices independently since the last successful sync.
3. **Conflict Resolution Logic:**
   - If a conflict is detected, **do not silently overwrite**.
   - Preserve both versions by renaming them:
     - `filename (Device A).ext`
     - `filename (Device B).ext`
   - Mark the conflict in the local database for user review.
4. **Transfer Phase:** Reuse the Phase 2/3 binary transfer protocol to send/receive missing or modified files.
5. **Delta Sync (V2 concept, optional for MVP):** Instead of whole files, chunk files into blocks, hash blocks, and only send modified blocks (rsync style). MVP will default to whole-file replacement.

### `sync_protocol.dart`
- **Role:** Extends the existing HTTP server to handle sync-specific API routes.
- **Endpoints:**
  - `POST /api/v1/merge/sync/index` — Exchange complete or partial file indices.
  - `POST /api/v1/merge/sync/request` — Request specific files or file blocks.
  - `POST /api/v1/merge/sync/upload` — Upload files to the remote device (wrapper over standard transfer protocol).
  - `GET /api/v1/merge/sync/status` — Poll current sync status.

### `sync_scheduler.dart`
- **Role:** Determines *when* to execute sync operations.
- **Triggers:**
  - **Discovery:** Triggered immediately when mDNS discovers a paired device.
  - **File Changes:** Triggered when the local file watcher detects a change in the Merge Space folder.
  - **Periodic:** Every 5 minutes while connected to the same network.
- **Debouncing:** Ensure multiple rapid file changes don't spam sync operations (e.g., minimum 30-second interval between sync runs).

## 7.4 Domain Models
**Path:** `lib/features/merge_space/domain/`

```dart
class DeviceGroup {
  final String groupId;
  final String groupKey;          // 256-bit AES symmetric key
  final List<PairedDevice> devices;
  final DateTime createdAt;
}

class PairedDevice {
  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime pairedAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;
}

enum SyncStatus { synced, syncing, pendingSync, offline, error }

class MergeSpaceFile {
  final String relativePath;     // Relative to Merge Space root
  final String hash;             // SHA-256 of file contents
  final int sizeBytes;
  final DateTime modifiedAt;
  final bool isDeleted;
  final String? originDeviceId;  // Device that last modified this file
}

class SyncConflict {
  final String relativePath;
  final MergeSpaceFile localVersion;
  final MergeSpaceFile remoteVersion;
  final DateTime detectedAt;
}
```

## 7.5 Database Schema (Drift)
**Path:** `lib/features/merge_space/data/local_database.dart`

```dart
class MergeSpaceFiles extends Table {
  TextColumn get relativePath => text()();
  TextColumn get hash => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get modifiedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get originDeviceId => text()();
  @override Set<Column> get primaryKey => {relativePath};
}

class PairedDevices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  TextColumn get platform => text()();
  TextColumn get groupId => text()();
  DateTimeColumn get pairedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  @override Set<Column> get primaryKey => {deviceId};
}

class SyncConflicts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get relativePath => text()();
  TextColumn get localHash => text()();
  TextColumn get remoteHash => text()();
  TextColumn get remoteDeviceId => text()();
  DateTimeColumn get detectedAt => dateTime()();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();
}
```

## 7.6 Encryption
- All payloads (indices, metadata, files) transferred between paired devices in a Merge Space must be encrypted using the symmetric `groupKey`.
- **Algorithm:** AES-256-GCM.
- **Security:** The group key is completely localized to the paired devices and is never transmitted to an external server or cloud provider.

## 7.7 Presentation Layer
**Path:** `lib/features/merge_space/presentation/`

- **`merge_space_setup_screen.dart`** (First-time setup)
  - Heading: "Add Your Devices"
  - Card showing the current device (Host).
  - "Add Device" button displaying the pairing QR code and raw connection string.
  - Scanner view for joining devices to read the host's QR code.

- **`merge_space_screen.dart`** (Main View / Bottom Nav Tab)
  - File browser tailored to the Merge Space directory.
  - Global sync status header ("All synced ✅", "Syncing...", "1 device pending").
  - Per-file sync status indicators (✅ synced, 🔄 syncing, ⏳ waiting).
  - Floating Action Button to "Add Files" into the space.
  - Pull-to-refresh to manually force a sync cycle.

- **`paired_devices_screen.dart`** (Device Management)
  - List of all paired devices in the group.
  - Displays device name, platform, last synced timestamp, and storage used.
  - Option to "Remove Device" (requires user confirmation).
  - "Add Device" button.

- **`sync_conflict_screen.dart`** (Conflict Resolution)
  - Alerts the user when a conflict is detected.
  - Side-by-side comparison of conflicting files showing size, modified date, and origin device.
  - Action buttons: "Keep Both" (creates renamed copies), "Keep This Device's Version", "Keep Other Device's Version".

## 7.8 Background Sync (Platform-Specific)

### Android
- Utilize **WorkManager** to register a periodic background task.
- Schedule the task to run approximately every 15 minutes, constrained to when the device is on an unmetered Wi-Fi connection.
- Use a `BroadcastReceiver` to trigger a sync when the network state changes (e.g., joining Wi-Fi).

### iOS
- Use **BGAppRefreshTask** for background synchronization.
- **Limitation:** iOS strictly controls execution frequency. Provide clear UI context like "Last synced: X minutes ago".
- Always trigger an immediate sync pass when the app transitions to the foreground.

### Windows
- Implement a background system tray agent.
- Since Flutter desktop background support is limited, this may require spawning a separate hidden Dart executable or using platform channels to hook into native Windows APIs.
- Monitor the file system continuously via native watchers.
- Show a system tray icon with real-time sync status.

### macOS
- Implement a menu bar agent.
- Utilize **launchd** to ensure background persistence and restart capability.
- Similar continuous file watching and sync execution as Windows.

## 7.9 File Watching
**Path:** `lib/features/merge_space/data/file_watcher_service.dart`

- Continuously observe the local Merge Space directory.
- On standard file events (create, modify, delete), update the local SQLite index immediately and queue a sync request.
- Use `dart:io`'s `FileSystemEntity.watch()` for supported platforms, or native watchers via FFI/method channels where Dart's implementation falls short.
- **Debouncing:** Batch multiple rapid filesystem events (e.g., over a 2-second window) into a single index update operation.

## 7.10 Navigation Updates
- **Bottom Navigation:** Replace the "Rooms" placeholder with the "Merge Space" tab, or add it as a 5th tab.
- **Routes to implement:**
  - `/merge-space` → `MergeSpaceScreen` (Main file browser)
  - `/merge-space/setup` → `MergeSpaceSetupScreen` (Initial pairing flow)
  - `/merge-space/devices` → `PairedDevicesScreen` (Device management)
  - `/merge-space/conflicts` → `SyncConflictScreen` (Conflict resolution UI)

## Test Specifications

### Unit Tests (Minimum 15)
1. `DeviceGroup` model creation and JSON serialization/deserialization.
2. Pairing code generation — verify QR data string encoding and decoding.
3. `file_index.dart` — Verify correct SHA-256 hash calculation for a file.
4. `file_index.dart` — Detect file modifications correctly based on hash and timestamp.
5. `sync_engine.dart` — Diff calculation correctly identifies newly added files.
6. `sync_engine.dart` — Diff calculation correctly identifies deleted files (soft delete).
7. `sync_engine.dart` — Diff calculation correctly identifies modified files.
8. `sync_engine.dart` — Conflict detection triggers when identical files are modified on both sides.
9. `sync_engine.dart` — Conflict resolution: "Keep both" renames files correctly.
10. Encryption — AES-256-GCM successfully encrypts and decrypts a file block with the group key.
11. `sync_scheduler.dart` — Debounce logic correctly drops rapid sync triggers within a 30-second window.
12. `sync_scheduler.dart` — Verifies sync is queued when mDNS discovers a paired device.
13. Database — `MergeSpaceFiles` CRUD operations work correctly.
14. Database — `PairedDevices` CRUD operations work correctly.
15. Database — `SyncConflicts` CRUD operations and resolution flag updates work correctly.

### Widget Tests (Minimum 6)
1. `MergeSpaceSetupScreen` — Renders the QR code and raw pairing code strings correctly.
2. `MergeSpaceScreen` — Renders a list of files with correct sync status icons.
3. `MergeSpaceScreen` — Displays the global sync status indicator.
4. `PairedDevicesScreen` — Displays a list of devices with their last synced timestamps.
5. `SyncConflictScreen` — Renders the conflict resolution UI with side-by-side file details and option buttons.
6. `MergeSpaceScreen` — Renders the empty state correctly when no files exist in the space.

### Integration Tests (Manual — Requires 2+ devices)
1. Pair two physical devices using the QR code scanner → Verify both list each other as paired.
2. Copy a file into the Merge Space folder on Device A → Verify it appears on Device B within ~1 minute.
3. Delete a file on Device A → Verify it disappears from Device B after a sync cycle.
4. Concurrently edit the same text file on both devices while disconnected, then reconnect → Verify conflict is detected and both versions are kept via renaming.
5. Turn off Wi-Fi on Device B, add 5 files on Device A, then reconnect Device B to Wi-Fi → Verify files sync automatically.
6. Remove Device B from Device A's paired list → Verify Device B no longer receives sync updates from Device A.

## Acceptance Criteria
- [ ] Device pairing via QR code and manual pairing string works.
- [ ] A dedicated Merge Space folder is created on each paired device.
- [ ] Files added to the Merge Space sync seamlessly to all paired devices on the same network.
- [ ] File deletions sync properly (soft delete handling).
- [ ] File modifications sync properly.
- [ ] Conflicts are accurately detected and both versions are preserved (no data loss).
- [ ] All sync payloads and file transfers are encrypted using the AES-256 group key.
- [ ] Background sync operates correctly on Android via WorkManager.
- [ ] Background sync on iOS leverages app foregrounding and BGAppRefreshTask.
- [ ] Sync statuses (per-file and global) reflect accurately in the UI.
- [ ] Paired device management (viewing, adding, removing devices) is fully functional.
- [ ] Local file watcher reliably detects changes and triggers sync.
- [ ] All 15+ unit tests pass.
- [ ] All 6+ widget tests pass.
- [ ] All manual integration scenarios complete successfully.
- [ ] `flutter analyze` passes with no warnings.
- [ ] Code is committed with the tag `phase-7-complete`.

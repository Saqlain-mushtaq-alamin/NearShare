# NearShare Phase 3: Resumable File Transfers

## Goals
Implement a robust chunk-based transfer protocol that allows interrupted file transfers to resume from where they left off, rather than restarting from byte 0. This involves modifying both the sending and receiving mechanisms, persisting transfer session state, and gracefully handling network disconnections and app restarts.

## Prerequisites
- Phase 2 completion (basic 1:1 file transfer over local HTTP server using `shelf` and `dio`).
- Working device discovery mechanism.

## 3.1 Chunk-Based Transfer Protocol Design
To support resumability, files will no longer be sent as a single monolithic stream. Instead:
- Files are split into logical chunks (e.g., 1MB per chunk default).
- Each chunk is transmitted as a separate HTTP POST/PUT request.
- **Headers for Chunk Requests:**
  - `X-Transfer-Id: <uuid>` - Unique identifier for the transfer session.
  - `X-File-Index: <int>` - Index of the file within the transfer session.
  - `X-Chunk-Index: <int>` - The index of the current chunk being sent.
  - `X-Chunk-Size: <int>` - The size of the current chunk in bytes.
  - `X-Total-Chunks: <int>` - The total number of chunks for this file.
  - `Content-Range: bytes <start>-<end>/<total>` - Standard HTTP range header indicating the byte range of this chunk.
- **Receiver Behavior:**
  - The receiver accepts chunks and writes them directly to a temporary file (or discrete temporary chunk files).
  - The receiver tracks the receipt of each chunk in a database or persisted state.
  - Upon receiving the final missing chunk, the receiver assembles/verifies the file and renames it to the final destination file.

## 3.2 Resume Protocol
When a sender reconnects after a network drop or app restart, it needs to determine what the receiver already has.
- **New Endpoint:** `GET /api/v1/transfer/resume/:transferId/:fileIndex`
- **Response Format:**
  ```json
  {
    "receivedChunks": [0, 1, 2, 5, 6],
    "totalChunksExpected": 20
  }
  ```
- **Resume Flow:**
  1. Sender detects disconnection and pauses the transfer.
  2. Sender re-discovers the target device (IP might have changed).
  3. Sender queries the resume endpoint for the incomplete transfer session.
  4. Sender filters out already `receivedChunks` from its queue.
  5. Sender resumes sending only the missing chunks, starting with the lowest missing index.

## 3.3 Domain Models
New and updated models to support chunking and persistence:

```dart
// lib/domain/models/chunk_info.dart
class ChunkInfo {
  final int index;
  final int startByte;
  final int endByte;
  final int size;
  final bool received;

  ChunkInfo({
    required this.index,
    required this.startByte,
    required this.endByte,
    required this.size,
    this.received = false,
  });
}

// lib/domain/models/transfer_session.dart
enum TransferDirection { sending, receiving }
enum TransferStatus { pending, inProgress, paused, completed, failed, cancelled }

class TransferSession {
  final String transferId;
  final String peerId;
  final TransferDirection direction; 
  final List<TransferFile> files;
  
  // Map of fileIndex to a list of received chunk indices
  final Map<int, List<int>> receivedChunksPerFile; 
  
  final DateTime startedAt;
  final DateTime? lastActivityAt;
  final TransferStatus status;

  // Constructor, copyWith, fromJson, toJson...
}
```

## 3.4 Data Layer Changes

### Chunk Manager
Create `lib/data/transfer/chunk_manager.dart`:
- `List<ChunkInfo> splitFileIntoChunks(TransferFile file, int chunkSize)`: Calculates byte ranges.
- `void markChunkReceived(String transferId, int fileIndex, int chunkIndex)`: Updates the session state.
- `List<int> getMissingChunks(String transferId, int fileIndex)`: Returns indices of chunks not yet received.
- `bool isFileComplete(String transferId, int fileIndex)`: Checks if received chunks equal total expected chunks.
- `Future<File> assembleFile(String transferId, int fileIndex)`: Validates temp file, renames to final.

### Transfer Session Repository
Create `lib/data/repository/transfer_session_repository.dart`:
- Use `drift` (SQLite) to persist `TransferSession` data.
- Ensures state survives app termination.
- Methods: `saveSession`, `getSession`, `getIncompleteSessions`, `deleteSession`.

### Transfer Server (Receiver side)
Update `lib/data/network/transfer_server.dart`:
- Add route: `GET /api/v1/transfer/resume/:transferId/:fileIndex`.
- Update upload route (e.g., `POST /api/v1/transfer/chunk`) to parse chunk headers.
- Write incoming bytes to a temporary file using `RandomAccessFile` at the correct offset based on `Content-Range`.
- Call `ChunkManager.markChunkReceived` upon successful write.

### Transfer Client (Sender side)
Update `lib/data/network/transfer_client.dart`:
- Read files using `File.openRead(start, end)` to extract specific chunks.
- Before transmission (or on resume), query the resume endpoint.
- Iterate over chunks; skip those already present in `receivedChunks`.
- Implement exponential backoff for connection failures during chunk transmission.

### Transfer Manager
Update `lib/domain/managers/transfer_manager.dart`:
- Coordinate client, server, and repository.
- Save session state to the DB continuously (e.g., after every chunk or every N chunks).
- On app initialization, check the repository for incomplete sessions (`TransferStatus.paused` or `inProgress` but interrupted).
- Trigger automatic resume attempts when a known peer is discovered.

## 3.5 Presentation Layer Changes

### Transfer Progress Screen
Update `lib/presentation/screens/transfer_progress_screen.dart`:
- Add visual states for:
  - "Resuming transfer..."
  - "Connection lost — will resume when device is found"
- Update progress calculation to be based on chunks/bytes completed vs total.
- Show detailed progress: e.g., "Chunk 15/50".

### Incomplete Transfers Widget
Create `lib/presentation/widgets/incomplete_transfers_widget.dart`:
- Displayed on the home screen if there are paused/incomplete sessions.
- Lists sessions with target device name and progress percentage.
- Provides "Resume" and "Cancel" (discard) actions.

## 3.6 Connection Monitoring
Create `lib/data/network/connection_monitor.dart`:
- Actively monitors the connection state to the peer during an active transfer.
- Uses heartbeats or socket timeout detection to quickly identify drops.
- Upon drop: transitions session to `paused`, halts active Dio requests, saves state.
- Subscribes to device discovery stream to trigger auto-resume when the IP is available again.

## 3.7 Cleanup
- Implement logic in `TransferManager` to:
  - Delete temporary chunk files upon successful file assembly.
  - Run a periodic check to delete stale `TransferSession` entries older than 24 hours (and associated temp files).
  - Handle edge cases: if the receiver deleted a partial file manually from the file system, the resume endpoint should return an empty list or trigger a restart.

## Tests

### Unit Tests (minimum 12)
1. **ChunkInfo:** Verify correct byte range calculations for various indices and sizes.
2. **splitFileIntoChunks (Standard):** Verify correct chunk count and ranges for cleanly divisible file sizes.
3. **splitFileIntoChunks (Remainder):** Verify the last chunk handles remainder bytes correctly.
4. **markChunkReceived:** Verify it correctly updates the received chunks list/state.
5. **getMissingChunks:** Verify it correctly returns only the indices of chunks not yet marked received.
6. **isFileComplete (True):** Verify it returns true when all chunks are marked received.
7. **isFileComplete (False):** Verify it returns false when one or more chunks are missing.
8. **TransferSession Serialization:** Verify conversion to/from DB models (SQLite).
9. **Resume Endpoint:** Verify the handler returns the correct JSON list of received chunks based on state.
10. **Client Resume Logic:** Verify the client correctly skips sending chunks that are in the received list.
11. **Retry Logic:** Verify exponential backoff timing intervals on simulated network failures.
12. **Cleanup:** Verify stale session cleanup logic identifies and removes sessions older than 24h.

### Widget Tests (minimum 3)
1. **TransferProgressScreen (Resuming):** Verify UI correctly displays "Resuming..." state and UI elements.
2. **TransferProgressScreen (Disconnected):** Verify UI shows "Connection lost" state and instructions.
3. **IncompleteTransfersWidget:** Verify it renders a list of incomplete transfers with resume/cancel buttons.

### Integration Tests (Manual — 2 devices)
1. **Mid-transfer Disconnect:** Start sending a large file (100MB+). Turn off sender Wi-Fi mid-transfer. Turn Wi-Fi back on. Verify transfer resumes from the last successful chunk, NOT from 0.
2. **Sender App Kill:** Start transfer. Kill sender app. Reopen app. Verify incomplete transfer shows on home screen. Tap resume. Verify transfer completes successfully.
3. **Receiver App Kill:** Start transfer. Kill receiver app. Reopen app. Sender detects disconnection and then receiver restarts. Verify resume works successfully.
4. **Integrity Check:** Verify the completed file (after a resumed transfer) has the exact same checksum/hash as the original file.

## Acceptance Criteria
- [ ] Files are sent in chunks (configurable chunk size, default 1MB).
- [ ] Receiver tracks received chunks per file accurately.
- [ ] Resume endpoint returns correct chunk list.
- [ ] After disconnection, sender queries resume endpoint and skips already-sent chunks.
- [ ] Transfer sessions are persisted to SQLite (survive app restart).
- [ ] Incomplete transfers shown on home screen with resume/cancel options.
- [ ] Connection loss is detected and handled gracefully (no crash, no corruption).
- [ ] Completed resumed file is identical to original (integrity check).
- [ ] Stale sessions are cleaned up automatically.
- [ ] Handle edge case: receiver deleted partial file manually.
- [ ] All unit tests pass (minimum 12).
- [ ] All widget tests pass (minimum 3).
- [ ] Manual resume tests pass.
- [ ] `flutter analyze` passes.
- [ ] Code committed with tag `phase-3-complete`.

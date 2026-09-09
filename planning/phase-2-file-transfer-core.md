# Phase 2: Core 1:1 File Transfer (Local Network)

## Context
- Phase 1 (device discovery via mDNS) is complete — devices can find each other
- Framework: Flutter + Riverpod
- Transfer approach: Each device runs a lightweight embedded HTTP server using `shelf` + `shelf_io`. Sender picks files, picks target device, then POSTs files to the receiver's HTTP server.
- This is the same model used by LocalSend
- Platforms: Android, iOS, Windows, macOS

## 2.1 Architecture Overview
- **HTTP Server Model:** 
  - Every device runs a small HTTP server on a random port (broadcast port via mDNS).
  - Sender: picks files → picks target device → sends HTTP POST to receiver's IP:port.
  - Receiver: HTTP server receives the request → shows accept/reject prompt → if accepted, saves file.
- **Request/Response Protocol Design:**
  - `POST /api/v1/transfer/prepare` — sender announces intent (file list with names, sizes, types).
  - Receiver responds: accepted / rejected.
  - `POST /api/v1/transfer/upload/:transferId/:fileIndex` — sends actual file data (multipart).
  - `GET /api/v1/transfer/status/:transferId` — check transfer status.
  - `POST /api/v1/transfer/cancel/:transferId` — cancel transfer.

## 2.2 Domain Models
Under `lib/features/transfer/domain/`:

```dart
// transfer_file.dart
class TransferFile {
  final String name;
  final int sizeInBytes;
  final String mimeType;
  final String localPath;    // sender side
  final String? savePath;    // receiver side
}

// transfer_request.dart
class TransferRequest {
  final String transferId;   // UUID
  final String senderId;
  final String senderName;
  final List<TransferFile> files;
  final int totalSizeBytes;
  final DateTime timestamp;
}

// transfer_progress.dart
class TransferProgress {
  final String transferId;
  final int currentFileIndex;
  final int totalFiles;
  final int bytesTransferred;
  final int totalBytes;
  final double speedBps;     // bytes per second
  final TransferStatus status;
}

enum TransferStatus { pending, accepted, rejected, inProgress, completed, failed, cancelled }
```

## 2.3 Data Layer — HTTP Server (Receiver Side)
Under `lib/features/transfer/data/`:

- `transfer_server.dart` — Uses `shelf` + `shelf_io`:
  - `start(int port)` — starts HTTP server.
  - `stop()` — stops server.
  - Routes:
    - `POST /api/v1/transfer/prepare` → parse TransferRequest JSON → emit event for UI to show accept/reject dialog → wait for user decision → respond.
    - `POST /api/v1/transfer/upload/:transferId/:fileIndex` → stream file bytes to disk, emit progress events.
    - `POST /api/v1/transfer/cancel/:transferId` → cancel and cleanup.
  - Use `StreamController` to emit events to the presentation layer.
  - Handle multipart file uploads.
  - Save files to the configured download directory (`path_provider`).

## 2.4 Data Layer — HTTP Client (Sender Side)
Under `lib/features/transfer/data/`:

- `transfer_client.dart` — Uses `dio`:
  - `prepareTransfer(Device target, List<TransferFile> files)` → POST to target's `/prepare` endpoint.
  - `uploadFile(Device target, String transferId, int fileIndex, TransferFile file)` → POST multipart to `/upload`.
  - `cancelTransfer(Device target, String transferId)` → POST to `/cancel`.
  - Report upload progress via `dio`'s `onSendProgress` callback.
  - Handle connection errors gracefully.

## 2.5 Data Layer — Transfer Manager
Under `lib/features/transfer/data/`:

- `transfer_manager.dart` — Orchestrates the full transfer flow:
  - For sending: prepare → wait for accept → upload files sequentially → report completion.
  - For receiving: handle incoming prepare request → show to user → on accept, receive files → report completion.
  - Manages concurrent transfers (queue if needed).
  - Generates transfer IDs (UUID).

## 2.6 Presentation Layer
Under `lib/features/transfer/presentation/`:

- `transfer_provider.dart` — Riverpod provider:
  - Exposes current transfer progress.
  - Exposes incoming transfer requests (for accept/reject).
  - Methods: `sendFiles()`, `acceptTransfer()`, `rejectTransfer()`, `cancelTransfer()`.
- `file_picker_screen.dart` — File selection:
  - Uses `file_picker` package.
  - Tabs: All Files (simple for now, can add Photos/Videos/Docs tabs in Phase 5).
  - Multi-select.
  - Shows selected count and total size.
  - "Next" button → goes to device selection.
- `device_select_screen.dart` — Pick target device:
  - Shows discovered devices from Phase 1.
  - Tap to select → confirmation screen.
- `transfer_confirmation_screen.dart` — Confirm before sending:
  - File count, total size, target device name.
  - "Send" and "Cancel" buttons.
- `transfer_progress_screen.dart` — During transfer:
  - Overall progress bar.
  - Current file name.
  - Speed (MB/s).
  - ETA.
  - Cancel button.
- `transfer_complete_screen.dart` — After transfer:
  - Success checkmark or failure message.
  - "Send Again" and "Done" buttons.
- `incoming_transfer_dialog.dart` — Accept/reject prompt:
  - "[Sender Name] wants to send you [N] files ([size])".
  - File list.
  - Accept / Reject buttons.

## 2.7 File Storage
- Determine save directory per platform:
  - Android: `/storage/emulated/0/NearShare/Received/` or app-specific dir.
  - iOS: App documents directory.
  - Windows/macOS: `Documents/NearShare/Received/`.
- Use `path_provider` to get appropriate directory.

## 2.8 Navigation
- Add send flow routes to `GoRouter`:
  - `/send` → file picker
  - `/send/select-device` → device selection
  - `/send/confirm` → confirmation
  - `/send/progress/:transferId` → progress
  - `/send/complete/:transferId` → complete

## Tests

### Unit Tests (minimum 15)
1. TransferFile model — creation, serialization
2. TransferRequest model — creation, serialization, total size calculation
3. TransferProgress model — percentage calculation, speed formatting
4. TransferStatus enum — all states covered
5. TransferServer — handles prepare request correctly (mock shelf request)
6. TransferServer — handles upload request correctly
7. TransferServer — rejects transfer returns correct response
8. TransferClient — prepareTransfer sends correct JSON payload
9. TransferClient — uploadFile sends multipart correctly (mock dio)
10. TransferClient — handles server rejection gracefully
11. TransferClient — handles network error gracefully
12. TransferManager — full send flow (prepare → upload → complete)
13. TransferManager — full receive flow (receive → accept → save → complete)
14. TransferManager — cancel flow
15. File save path resolution per platform

### Widget Tests (minimum 6)
1. FilePickerScreen — shows file picker, multi-select works
2. DeviceSelectScreen — shows discovered devices
3. TransferConfirmationScreen — shows file count, size, device name
4. TransferProgressScreen — shows progress bar, speed, ETA
5. TransferCompleteScreen — shows success state with buttons
6. IncomingTransferDialog — shows sender info, accept/reject buttons

### Integration Tests (Manual — 2 devices)
1. Device A selects a file → picks Device B → sends → Device B receives prompt → accepts → file transfers → file saved on Device B
2. Device B rejects → no file saved, Device A sees rejection
3. Send multiple files (3+) → all transfer correctly
4. Send a large file (50MB+) → completes without crash
5. Cancel mid-transfer → both sides handle gracefully

## Acceptance Criteria
- [ ] HTTP server starts on app launch and registers port via mDNS
- [ ] Sender can pick files and select a target device
- [ ] Transfer request (prepare) is sent and receiver sees accept/reject prompt
- [ ] Accepted files transfer correctly and are saved to the correct directory
- [ ] Rejected transfers are handled gracefully on both sides
- [ ] Progress is shown during transfer (progress bar, speed, ETA)
- [ ] Transfer can be cancelled by either party
- [ ] Multiple files transfer sequentially without errors
- [ ] All unit tests pass (minimum 15)
- [ ] All widget tests pass (minimum 6)
- [ ] Manual 2-device tests pass
- [ ] `flutter analyze` passes
- [ ] Code committed with tag `phase-2-complete`

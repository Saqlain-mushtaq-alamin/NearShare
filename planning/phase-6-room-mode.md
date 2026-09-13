# Phase 6: Room Mode Development Plan

## Context
- **Phases 1-5 complete:** Full 1:1 transfer app with polished UI is completed.
- **Room Mode:** A group file transfer feature where one device creates a "room," multiple devices join via QR code or a 6-digit code, and the host sends files to ALL joined devices simultaneously.
- **Key Differentiator:** This feature sets NearShare apart from competitors.
- **Framework:** Flutter + Riverpod + GoRouter.
- **Discovery:** Extends existing mDNS system.
- **Transfer:** Extends existing HTTP server/client.

---

## 6.1 Room Mode Concept
- A **Room** is a temporary group session for file sharing.
- One device acts as the **HOST** (creates the room).
- Other devices act as **MEMBERS** (join the room).
- The host selects files and broadcasts them to ALL members simultaneously.
- Members can also share files with the room (optional, host can restrict).
- The room dissolves automatically when the host leaves.
- Each room is identified by a unique **6-digit code** AND a **QR code** for easy joining.

---

## 6.2 Room Protocol Design

### Room Discovery
The host broadcasts a room service via mDNS: `_nearshare-room._tcp`
- **TXT record:** `roomId`, `roomCode` (6-digit), `hostName`, `memberCount`

### API Endpoints (on host's HTTP server)
- `POST /api/v1/room/join`
  - Member sends join request with device info + room code.
  - Host responds: accepted/rejected + room info (member list).
- `GET /api/v1/room/info`
  - Get current room state (members, file queue).
- `POST /api/v1/room/leave`
  - Member leaves the room.
- `DELETE /api/v1/room`
  - Host closes the room.
- `POST /api/v1/room/transfer/prepare`
  - Host announces files to all members.
- `POST /api/v1/room/transfer/upload/:transferId/:fileIndex`
  - Host sends a file to each member (reuses Phase 2/3 transfer protocol).
- **WebSocket or SSE:** `GET /api/v1/room/events`
  - Real-time events (member joined, member left, transfer starting, etc.).

---

## 6.3 Domain Models

Under `lib/features/rooms/domain/`:

```dart
class Room {
  final String roomId;           // UUID
  final String roomCode;         // 6-digit numeric code
  final String hostDeviceId;
  final String hostDeviceName;
  final List<RoomMember> members;
  final RoomStatus status;
  final DateTime createdAt;
}

class RoomMember {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final int port;
  final DateTime joinedAt;
}

enum RoomStatus { waiting, transferring, completed, closed }
```

---

## 6.4 Data Layer

Under `lib/features/rooms/data/`:

### `room_manager.dart`
Manages room lifecycle:
- **For HOST:** `createRoom()` → generates `roomId` + `roomCode` → starts room mDNS broadcast → starts listening for join requests.
- **For MEMBER:** `joinRoom(code)` → find room service via mDNS OR manual IP entry → POST join request.
- **Member list management:** add/remove members.
- **Room teardown:** stop broadcast, notify all members, cleanup.

### `room_transfer_service.dart`
Handles group transfer:
- Host sends files to EACH member in parallel (concurrent HTTP uploads).
- Tracks per-member progress independently.
- Handles partial failures (some members fail, others succeed).
- Reuses chunk-based transfer from Phase 3 for each member.

### `room_event_service.dart`
Real-time events:
- Use SSE (Server-Sent Events) or polling for member state updates.
- Events: `memberJoined`, `memberLeft`, `transferStarted`, `transferProgress`, `transferCompleted`, `roomClosed`.

---

## 6.5 QR Code Integration

### `qr_code_service.dart`
- **QR Code Content:** Generate QR code containing: `nearshare://room/join?code=123456&host=192.168.1.5&port=8080`
- **Display:** Use `qr_flutter` package to display the QR code on the host's screen.
- **Scanning:** Use `mobile_scanner` package for members to scan the QR code.
- **Fallback:** Always support manual 6-digit code entry as a reliable fallback.

---

## 6.6 Presentation Layer

Under `lib/features/rooms/presentation/`:

### `rooms_screen.dart`
Rooms tab main view:
- "Create Room" button.
- "Join Room" button.
- Active room indicator if currently in one.
- Recent rooms history (optional).

### `create_room_screen.dart`
Host creates room:
- Shows QR code (large, scannable) + 6-digit code (large, copyable).
- "Waiting for devices to join..." with member count.
- Live list of joined members.
- "Send Files" button (enabled when ≥1 member).
- "Close Room" button.

### `join_room_screen.dart`
Member joins:
- QR scanner view (full-screen camera).
- OR text field for 6-digit code.
- "Join" button.
- Loading state: "Connecting to room..."
- Error state: "Room not found" / "Room is full".

### `room_active_screen.dart`
Active room view (both host and member):
- Member list with status indicators.
- Host view: file picker + "Send to All" button.
- Member view: waiting state or receiving progress.
- Per-member progress when transferring.
- Leave/Close button.

### `room_transfer_progress_screen.dart`
Group transfer progress:
- Overall progress (total files × total members).
- Per-member progress bars.
- Individual member status: sending, completed, failed.
- Cancel button.

---

## 6.7 Navigation Updates

Update GoRouter configurations for the Rooms tab:
- `/rooms` → Rooms home
- `/rooms/create` → Create room
- `/rooms/join` → Join room (QR + code entry)
- `/rooms/active/:roomId` → Active room
- `/rooms/active/:roomId/transfer` → Transfer progress

---

## 6.8 Edge Cases
- **Host leaves early:** If the host leaves while members are connected, all members must be notified and the room is closed.
- **Member loses connection:** The member is marked as disconnected, and transfer is skipped/failed for that member without breaking others.
- **Partial transfer failure:** If transfer to some members fails, a partial success state is reported to the host.
- **Room code collision:** Although unlikely with 6 digits (short lifespan), logic should handle regenerations if a collision is detected.
- **Maximum capacity:** Cap the room size at a suggested 10 members to avoid overloading the host's server/network.

---

## Tests

### Unit Tests (minimum 12)
1. **Room model** — verify creation, member management.
2. **Room code generation** — strictly 6 digits, numeric only.
3. **RoomManager** — `createRoom` generates a valid room object and starts services.
4. **RoomManager** — a join request with the correct code is accepted.
5. **RoomManager** — a join request with the wrong code is rejected.
6. **RoomManager** — member removal works correctly.
7. **RoomManager** — room closure triggers notifications to all members.
8. **RoomTransferService** — successfully sends to multiple members in parallel.
9. **RoomTransferService** — handles partial failure (some members succeed, some fail).
10. **QR code data** — encodes/decodes URI string correctly.
11. **Room event** — serialization/deserialization of event JSON payloads.
12. **Room max capacity** — rejects join requests when full (e.g., > 10 members).

### Widget Tests (minimum 6)
1. **RoomsScreen** — shows Create and Join buttons.
2. **CreateRoomScreen** — shows QR code and 6-digit code.
3. **CreateRoomScreen** — shows joined members list.
4. **JoinRoomScreen** — shows QR scanner and code input.
5. **RoomActiveScreen** — host view shows file picker and members.
6. **RoomTransferProgressScreen** — shows per-member progress bars.

### Integration Tests (Manual — 3+ devices)
1. Device A creates a room → Device B scans QR → joins → Device C enters code → joins → all visible in member list.
2. Host sends 3 files → both B and C receive all 3 files.
3. Device C disconnects mid-transfer → Device B still receives successfully.
4. Host closes room → both members are notified and directed to the home screen.
5. Wrong code entry → rejection is handled gracefully with appropriate UI feedback.

---

## Acceptance Criteria
- [ ] Room creation with QR code + 6-digit code works.
- [ ] Devices can join via QR scan or code entry.
- [ ] Host sees live member list.
- [ ] Host can send files to all members simultaneously.
- [ ] Per-member transfer progress is tracked and displayed.
- [ ] Partial failures are handled (some succeed, some fail).
- [ ] Room closure notifies all members.
- [ ] Member disconnect is handled gracefully.
- [ ] Rooms tab integrated into bottom navigation.
- [ ] All unit tests pass (minimum 12).
- [ ] All widget tests pass (minimum 6).
- [ ] Manual 3-device test pass.
- [ ] `flutter analyze` passes.
- [ ] Code committed with tag `phase-6-complete`.

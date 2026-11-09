# NearShare Architecture

## Overview

NearShare is a local-first Flutter application. Peers discover each other over
mDNS, then communicate directly over HTTP or HTTPS on the LAN. There is no
account system, central server, cloud relay, analytics, or telemetry.

```text
┌──────────────┐   mDNS discovery    ┌──────────────┐
│  Device A    │◄───────────────────►│  Device B    │
│              │                     │              │
│  UI / state  │   HTTP(S) + chunks  │  UI / state  │
│  Riverpod    │◄───────────────────►│  Riverpod    │
│  Storage     │                     │  Storage     │
└──────────────┘                     └──────────────┘
        │                                    │
        └──────── same local network ────────┘
```

## Application Layers

Each feature follows a lightweight layered structure:

- `domain/` — immutable models and pure rules, such as `Device`,
  `TransferFile`, `Room`, and `SyncEngine`.
- `data/` — discovery, HTTP clients/servers, databases, file storage, and
  cryptographic services.
- `presentation/` — Riverpod notifiers and Flutter screens/widgets.

`lib/core/` contains cross-cutting security, providers, error handling, and
utilities. `lib/shared/` contains theme, navigation, and reusable widgets.
Generated Drift, Freezed, JSON, and Riverpod code is produced with
`build_runner`.

## Device Discovery

`BonsoirMdnsDiscoveryService` advertises and browses:

- `_nearshare._tcp` — nearby device transfer endpoint, default port `53317`.
- `_nearshare-room._tcp` — room host discovery.
- `_nearshare-merge._tcp` — Merge Space peers.

TXT attributes include the stable device ID, display name, platform, and,
when TLS is configured, the SHA-256 TLS certificate fingerprint under `fp`.
Own broadcasts are filtered by device ID. Peers can also be reached through a
room QR code or entered manually when mDNS is blocked.

## Nearby Transfer Protocol

The receiver runs `TransferServer`; the sender drives `TransferClient`.

### Preparation

`POST /api/v1/transfer/prepare`

The sender announces a `TransferRequest` containing transfer ID, sender
identity, file metadata, total size, timestamp, and chunk size. The receiver:

1. Checks that the request came from the local network.
2. Applies rate, concurrency, timeout, and body-size limits.
3. Rejects self-sends.
4. Validates file count, sizes, names, and suspicious file types.
5. Checks available disk space when the platform API is available.
6. Prompts the user to accept or reject the transfer.

### Chunk Upload

`POST /api/v1/transfer/chunk/:transferId/:fileIndex`

Each chunk carries `x-chunk-index`, `x-chunk-size`, `x-total-chunks`, and
`content-range` headers. Chunks are streamed to temporary files and tracked in
a transfer session repository, so they can arrive out of order or be resumed
after a disconnect. `TransferManager` sends up to four chunks in parallel by
default, clamped to the file's chunk count and a safe upper bound.

### Resume and Finalize

- `GET /api/v1/transfer/resume/:transferId`
- `GET /api/v1/transfer/resume/:transferId/:fileIndex`
- `GET /api/v1/transfer/status/:transferId`
- `POST /api/v1/transfer/finalize/:transferId/:fileIndex`
- `POST /api/v1/transfer/cancel/:transferId`

Finalization concatenates verified chunks into a sanitized destination name.
When the sender supplied a SHA-256 digest, the receiver hashes the assembled
file and deletes it if the digest does not match. Zero-byte files complete
without any chunk upload. History records are written through the encrypted
Drift database.

## TLS and Trust

Each device generates an RSA 2048-bit self-signed certificate and stores the
certificate and private key in `flutter_secure_storage`. The certificate
fingerprint is the SHA-256 hash of its DER encoding.

Peers learn the expected fingerprint through mDNS. `TransferClient` pins that
fingerprint and accepts the TLS certificate only when the presented certificate
matches. If a peer has no advertised fingerprint, the client uses local HTTP
rather than silently trusting an unverified certificate. Servers bind to all
IPv4 interfaces but reject requests whose peer address is not loopback, RFC
1918, link-local, IPv6 unique-local, or link-local. This supports physical LAN
interfaces without exposing the service to public addresses.

TLS currently protects the nearby-transfer endpoint. Room and Merge Space
servers apply local-network middleware and rate/concurrency limits; their
application protocols carry their own room codes, pairing secrets, and
AES-256-GCM payload protection.

## Rooms

A host owns a `RoomManager` and exposes:

- `POST /api/v1/room/join`
- `GET /api/v1/room/info`
- `POST /api/v1/room/leave`
- `DELETE /api/v1/room`
- `GET /api/v1/room/events` — Server-Sent Events stream

Rooms use a six-digit code and capacity checks. The host broadcasts room state
over mDNS. File sharing inside a room uses the same resumable transfer engine
and room-scoped progress reporting.

## Merge Space

Merge Space is a paired-device shared-folder system.

- A group has a random 256-bit AES key. Pairing proves knowledge of the key
  without transmitting it.
- The protocol uses `x-merge-group-id`, `x-merge-device-id`, `x-merge-hash`,
  `x-merge-modified-at`, `x-merge-origin-device-id`, and `x-merge-deleted`
  headers.
- Endpoints live under `/api/v1/merge/`: health, status, pair, sync index, and
  files.
- File indexes are exchanged, diffs are computed by `SyncEngine`, and
  conflicts are resolved by keeping local, keeping remote, or keeping both.
- Payloads use AES-256-GCM with the wire format
  `nonce (12 bytes) || ciphertext || MAC (16 bytes)`. Encrypted payloads are
  capped at 64 MiB.
- Merge Space metadata and pairing state are stored in a SQLCipher database;
  the group key is kept in secure storage.

## Security Controls

`ServerSecurityConfig` and `securityMiddleware` provide:

- Local-network address validation.
- Per-peer sliding-window rate limiting.
- Bounded concurrent handlers.
- Request timeouts.
- Maximum body size checks.
- Hardening headers such as `X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy`, `Cache-Control`, and a restrictive
  `Content-Security-Policy`.

`FileStorageService` sanitizes path traversal and illegal characters, handles
Windows reserved device names, truncates long names while preserving the
extension, avoids splitting Unicode surrogate pairs, deduplicates names, and
supports free-space checks. Transfer content validation rejects malformed
metadata and warns about risky executable/script extensions.

## Data Protection

- Drift databases for transfer history and Merge Space are opened through
  `DatabaseKeyService` using SQLCipher and `PRAGMA key`.
- Database keys, TLS private keys, and Merge Space group keys are stored with
  `flutter_secure_storage`.
- Android backups are disabled to avoid copying secrets off-device.
- The optional app lock uses `local_auth` with biometrics or device
  PIN/password.
- iOS App Transport Security permits local networking but does not allow
  arbitrary internet loads.

## Failure and Recovery

- Chunk uploads, resume queries, and finalization use bounded exponential
  backoff for connection errors.
- Incomplete files are deleted after cancellation, rejection, checksum
  failure, or other terminal errors.
- Transfer sessions persist chunk state so a reconnect can resume.
- Discovery and server startup failures are surfaced to the UI rather than
  crashing the app.
- Listeners are cancelled and controllers closed during feature teardown.

## Testing Strategy

`test/` mirrors `lib/` and includes:

- Unit tests for models, state rules, sanitization, checksums, rate limiting,
  and crypto.
- In-process HTTP handler tests for transfer, room, and Merge Space protocols.
- TLS integration tests that start a real HTTPS server and verify pinning.
- Drift database tests with in-memory databases.
- Widget tests for key screens and app-lock gating.

Run all checks with:

```powershell
flutter analyze
flutter test
```

Manual two-device LAN testing is still required for platform permissions,
mDNS behavior on real routers, sleep/wake handling, and store readiness.

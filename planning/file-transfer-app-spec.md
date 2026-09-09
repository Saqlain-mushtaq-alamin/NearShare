# NearShare — Full Product & Development Spec
### Offline, No-Ads, Cross-Platform File Transfer App

---

## 1. Product Vision

A file-transfer app that moves files phone-to-phone (and phone-to-PC) with **no internet, no account, no ads, and no cloud servers**. It fixes the specific things people complain about in Xender, SHAREit, and Zapya: intrusive ads, bloated content portals, failed transfers with no resume, and weak group-sharing UX.

**One-line positioning:** *"Your files never leave your Wi-Fi. No account. No ads. No cloud."*

**Target users:** students, offices, families, event/campus environments, and privacy-conscious users leaving SHAREit/Xender.

---

## 2. Core Problem Being Solved

| Pain point in existing apps | What NearShare does instead |
|---|---|
| Ads, video portals, bloatware (SHAREit, Zapya) | Zero ads, zero unrelated features |
| Transfer fails on weak signal, restarts from 0 | Resumable transfers |
| Same-Wi-Fi only (LocalSend) | Local network mode + nearby offline mode (Wi-Fi Direct/Hotspot fallback) |
| No transfer history / repeat sending | One-tap "resend to last contact," local history |
| Clunky group transfer | Simple "Room" mode: one QR/code, many devices, one drag-and-drop |
| No visibility into what's being sent | Preview + accept/reject per file before it lands on device |
| Privacy concerns (data ownership, trackers) | Fully local, no telemetry, open about security model in-app |

---

## 3. Fundamental Requirements (MVP — Must Have)

These are non-negotiable for a usable v1. No backend needed for any of these.

1. **Device discovery** — find nearby devices on the same Wi-Fi/hotspot using mDNS/Bonjour or a lightweight UDP broadcast protocol (same approach LocalSend uses).
2. **Direct P2P transfer** — send files over local network sockets (HTTP server on each device or WebRTC data channel for NAT traversal on non-LAN cases).
3. **File picker** — select photos, videos, documents, any file type, multi-select.
4. **Send flow** — pick device → confirm → transfer with progress bar.
5. **Receive flow** — incoming request notification → accept/reject → save to local storage.
6. **Basic transfer history (local only)** — list of past sends/receives stored in local DB (SQLite/Room/CoreData), never uploaded anywhere.
7. **Resumable transfer** — if connection drops, resume from last received chunk instead of restarting.
8. **Cross-platform parity** — Android + iOS at minimum for MVP (Windows/macOS/web can follow).
9. **No account, no login** — app must be usable within seconds of install.
10. **Basic security** — transfers happen only after explicit accept; optionally encrypt the local network transfer channel (TLS self-signed cert between devices).
11. **Permissions handling** — proper local network / storage / Bluetooth permission prompts (especially important on iOS 18+ and Android 14+).

---

## 4. Non-Fundamental Requirements (v2 / Growth Features)

These aren't needed to ship, but are your differentiators once MVP is live and stable.

1. **Room mode (multi-device group transfer)** — one device creates a "room" via QR code or 6-digit code; multiple devices join; drag files once, all get it.
2. **One-tap resend** — repeat last transfer to the same recipient/group without re-picking files.
3. **Auto-organize received files** — sort into folders by file type/sender/date automatically.
4. **Offline "send later" queue** — queue a file for a specific contact; auto-sends the moment that device is detected nearby again.
5. **Desktop companion app (Windows/macOS)** — receive/send from PC via same local-network protocol, browser-based fallback (like LocalSend's web client) for zero-install use.
6. **Nearby Wi-Fi Direct fallback** — when not on the same router (e.g., outdoors), fall back to Wi-Fi Direct or Bluetooth for discovery + hotspot for transfer.
7. **File compression option** — optional zip/compress before sending large batches.
8. **Dark mode / theming** — cosmetic, but expected baseline in 2026.
9. **Transfer speed stats** — show real-time Mbps, ETA — a trust-building UI touch users from Xender specifically like.
10. **QR-code "instant pair"** — scan to pair instead of typing a code, useful in noisy rooms/classrooms.
11. **Localization** — multi-language support for global reach (huge factor in this category's user base).
12. **Optional PIN-lock on the app** — since it touches personal files, a local app-lock (Face ID/fingerprint) is a nice trust signal.

---

## 5. Explicitly Out of Scope (Do NOT Build These)

Avoid the exact bloat that makes people leave the competitors:
- No built-in video/music player or "content hub"
- No social media video downloader
- No ads or ad SDKs
- No account system / cloud sync
- No analytics/telemetry that leaves the device
- No "clone phone" / migration tool (different product, different complexity)

---

## 6. Screen-by-Screen Flow

### 6.1 Onboarding (first launch only, <10 seconds)
- **Screen 1:** App name + one-line pitch ("Send files. No internet. No account. No ads.")
- **Screen 2:** Permission requests (Local Network, Storage, Bluetooth) — each with a one-line "why we need this"
- **Screen 3:** Auto-generated device name (editable) — e.g., "Rafiul's Pixel" — no login required
- → Lands directly on Home screen

### 6.2 Home Screen
- Big "Send" button (top)
- Big "Receive" button (or auto-listening indicator "Ready to receive")
- List of nearby discovered devices (auto-refreshing)
- Bottom nav: **Home | History | Rooms | Settings**

### 6.3 Send Flow
1. Tap **Send** → file picker (Photos / Videos / Documents / Apps / All Files tabs)
2. Multi-select files → tap **Next**
3. Device list appears (nearby devices auto-discovered) → tap target device
4. Confirmation screen: file count, total size, target device name
5. Transfer screen: progress bar, speed (Mbps), ETA, cancel button
6. Success screen: checkmark, "Send again" and "Done" buttons

### 6.4 Receive Flow
1. Incoming request push/local notification: "Rafiul's Pixel wants to send you 3 files (24MB)"
2. Tap notification → preview screen: file names/thumbnails, sender name
3. **Accept** or **Reject**
4. If accepted: progress screen (same UI as send)
5. Success screen: "Files saved to NearShare/Received" with **Open Folder** shortcut

### 6.5 Room Mode (group transfer)
1. Tap **Rooms** tab → **Create Room**
2. QR code + 6-digit code displayed, "Waiting for devices to join…"
3. Other users tap **Join Room** → scan QR or enter code
4. Host sees list of joined devices → drag/select files → **Send to All**
5. All members get simultaneous accept prompts → progress screens

### 6.6 History Screen
- Chronological list: sent/received, file thumbnails, device name, date/size
- Swipe or tap → **Resend** shortcut
- Filter by device or file type
- Local-only, clearable at any time from Settings

### 6.7 Settings Screen
- Device name (editable)
- Storage location (default save folder)
- Security: toggle transfer encryption, app lock (Face ID/PIN)
- Clear history / clear cache
- About: privacy policy note ("We don't collect your data. Full stop.")
- Language selector

---

## 7. Technical Architecture (No Backend Needed)

| Layer | Approach |
|---|---|
| Discovery | mDNS/Bonjour (Android: NSD API, iOS: Bonjour/NetService) or UDP broadcast |
| Transfer protocol | Local HTTP server per device (each device runs a lightweight embedded server; peer sends multipart POST) — same model as LocalSend |
| Cross-network fallback | WebRTC data channel with a public STUN server (free, no custom backend) for cases without shared LAN |
| Local storage | SQLite (Android: Room, iOS: CoreData/SQLite) for transfer history |
| Security | TLS with self-signed cert per session, or simple pairing token exchanged via QR |
| Offline queue | Local job queue that retries discovery every N seconds until target device is found |

**Key point:** none of this needs a backend server you host. STUN servers are free/public and don't store data; everything else is device-to-device.

---

## 8. Tech Stack Recommendation

- **Cross-platform framework:** Flutter (fastest path to Android + iOS + Desktop from one codebase; LocalSend itself is built in Flutter, proving this works well for this exact use case)
- **Alternative:** React Native (if you're more comfortable there) — slightly weaker for low-level networking, so Flutter is the stronger pick here
- **Local DB:** SQLite via `sqflite` (Flutter) or Room/CoreData if going native
- **Networking:** `nsd`/`bonsoir` (mDNS) + `dio`/native HTTP server package for transfer

---

## 9. Growth & Launch Checklist (to get users fast)

1. Emphasize **"no login, no ads, no cloud"** in every store screenshot — this is your #1 differentiator against Xender/SHAREit/Zapya complaints.
2. Post launch demo (30–60 sec video) on **r/androidapps, r/SideProject, r/privacy**, and Product Hunt.
3. Since transfer apps are inherently viral (you need 2 people to use it), design your **share link / invite flow** to be frictionless — e.g., "Invite via any messaging app" button that sends an install link.
4. Open-source the core (like LocalSend did) if you want fast trust + GitHub stars + community contributions — GitHub visibility is a legitimate growth channel in this category.
5. Keep first-run experience under 10 seconds, zero permissions asked before they're needed.
6. Target campuses, offices, and events in your early outreach — these are naturally high-density, no-internet-needed environments where the app's value is obvious immediately.

---

## 10. Suggested Build Order

1. **Week 1–2:** Discovery + basic 1:1 send/receive over local Wi-Fi (MVP core)
2. **Week 3:** Local history + resumable transfer
3. **Week 4:** Polish send/receive UI, permissions, onboarding
4. **Week 5:** Room mode (group transfer)
5. **Week 6:** Desktop web-client fallback (optional but high-value, low-effort if using a local HTTP server approach)
6. **Week 7:** Beta test with 10–20 real users (friends/campus group), fix connection edge cases
7. **Week 8:** Store listing, launch content, submit to app stores

---

## 11. NEW FEATURE — "Merge Space" (Personal Multi-Device Sync)

### 11.1 The Problem (in your words)
You own a Windows PC, a Windows laptop, and an iPhone. A file on your PC isn't available on your laptop or phone unless you manually copy it — and cloud tools like Google Drive solve it but need internet and a download step every time.

### 11.2 What This Feature Actually Does
A **private, owner-only shared space** across all of your own paired devices. Drop a file/folder into "Merge Space" on any device, and it automatically replicates to every other trusted device you own — no manual transfer, no cloud storage, no third-party server.

### 11.3 The One Honest Limitation (read this before building)
True "access anywhere with zero internet, instantly" is not physically possible without a server holding a copy somewhere. What **is** achievable with no backend is a **sync-when-nearby model**:

- Every trusted device keeps its **own full local copy** of the Merge Space.
- Whenever two of your devices land on the same network (home Wi-Fi, work Wi-Fi, phone hotspot) or are in Bluetooth/Wi-Fi Direct range, they **auto-sync in the background** — no action needed from you.
- Result: by the time you leave home with your phone, it already has last night's PC file on it. You open it at university with **zero internet needed**, because it's not fetching anything — it's already local.
- The only case this doesn't cover: a file added to your PC *while* you're already away from home, that you need on your phone *before* you're ever near the PC again. For that one edge case, see the optional relay add-on below (11.7) — everything else works fully offline.

This is the same underlying model as Syncthing/Resilio, but with a far simpler, cleaner UI and tighter integration into the rest of your app.

### 11.4 Fundamental Requirements for Merge Space (MVP)
1. **Device pairing/ownership** — link PC, laptop, and iPhone under one private "device group," secured by a pairing code/QR generated on first device and scanned/entered on the others. No account or cloud login involved.
2. **Merge Space folder** — one designated local folder per device that acts as the sync root (e.g., `NearShare/MergeSpace/`).
3. **Drop-in = auto-sync** — anything placed in that folder is queued for sync to all other paired devices.
4. **Background sync-when-nearby** — app/agent on each device listens for other paired devices on the local network (same mDNS discovery used elsewhere in the app) and syncs automatically, silently, without opening the app.
5. **Conflict handling** — if the same file is edited on two devices before syncing, keep both versions (`file (PC edit).docx` / `file (laptop edit).docx`) rather than silently overwriting — this is a common failure point in sync tools.
6. **Delta/partial sync** — only transfer changed portions of large files, not the whole file again (block-level diff, same concept as rsync).
7. **End-to-end encryption** — files encrypted at rest and in transit between your devices; since it's your own private group, use a key derived from the pairing process, never sent anywhere external.
8. **Windows background agent** — since Windows PCs/laptops aren't always "in the app," you'll need a lightweight background service/tray app that keeps syncing even when the main UI isn't open. iOS is more restrictive here (see 11.6).

### 11.5 Non-Fundamental / v2 Features for Merge Space
1. **Selective sync** — choose which folders sync to which devices (e.g., don't sync huge video folder to phone, only to laptop).
2. **Version history** — keep last N versions of a changed file locally, so accidental overwrites are recoverable.
3. **Storage quota per device** — cap how much of Merge Space syncs to a storage-limited device like a phone.
4. **Manual "sync now" trigger** — force an immediate sync check instead of waiting for background detection.
5. **Sync status dashboard** — see which devices are up to date, which are pending, last-synced timestamps.
6. **Folder-level sharing rules** — e.g., "Work" folder syncs only to PC + laptop, "Photos" syncs to all three.

### 11.6 Platform-Specific Notes (important for planning)
- **Windows (PC + laptop):** straightforward — a background service/tray app can run continuously and sync freely on local network.
- **iPhone:** iOS restricts long-running background processes. Realistic approach: sync triggers when the app is opened, when on Wi-Fi with background app refresh enabled, or via a background task scheduled by iOS (limited frequency, Apple-controlled). This means iPhone sync may lag slightly behind PC/laptop sync — worth setting that expectation clearly in-app ("Last synced: 2 hours ago" indicator) rather than promising instant.

### 11.7 Optional Add-On: Remote Relay (only if you want true away-from-all-devices access)
If you later want the one edge case in 11.3 solved — accessing/adding files when *none* of your other devices are nearby — the only real solution is a lightweight relay server (yours or a cheap VPS) that temporarily holds encrypted blobs until the target device reconnects. This is optional, clearly separated from the core no-backend product, and shouldn't be built until the core Merge Space is stable and adopted. Flag it as a "Pro" feature for later, not part of MVP.

### 11.8 Screen Additions for Merge Space

**New bottom nav tab: "Merge Space"**

1. **Setup screen (first time):** "Add your devices" → generate pairing QR on first device → scan on second/third device → confirms device group created.
2. **Merge Space home:** shows the synced folder contents, each file tagged with sync status icon (✅ synced everywhere / 🔄 syncing / ⏳ waiting for device).
3. **Device list screen:** shows all paired devices, last-synced time, storage used per device, remove-device option.
4. **Conflict screen:** appears only when a conflict is detected — shows both versions, lets user pick or keep both.
5. **Settings additions:** encryption status indicator, re-pair/reset device group, selective sync toggles (v2).

### 11.9 Updated Positioning Line
*"Your files, on every device you own — synced automatically, no cloud, no internet required to access what's already there."*

---

## 12. Risks / Things to Watch

- **iOS local networking permission changes** — Apple has tightened Local Network API requirements; test early on real devices, not just simulator.
- **NAT/firewall edge cases** — some corporate/public Wi-Fi networks block device-to-device local discovery; your WebRTC fallback matters here.
- **App store review** — be totally transparent about permissions (local network, storage) in your listing to avoid rejection/delay.
- **Naming/trademark check** — confirm "NearShare" (or whatever name you pick) isn't already trademarked before you invest in branding.

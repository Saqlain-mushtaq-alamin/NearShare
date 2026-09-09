# NearShare — Development Roadmap (Master Index)

> **One-line positioning:** *"Your files never leave your Wi-Fi. No account. No ads. No cloud."*

---

## How to Use This Roadmap

This roadmap breaks the entire NearShare app into **8 phases**. Each phase is self-contained — it has its own goals, deliverables, and tests. When you finish a phase, you have a **working, testable app** at that level.

### Rules for Every Phase

1. **Complete the phase fully** before moving to the next one.
2. **Run ALL tests** listed at the end of each phase document — every test must pass.
3. **Commit your code** at the end of each phase with the tag `phase-X-complete`.
4. **Do NOT skip phases** — later phases depend on earlier ones.

---

## Phase Overview

| Phase | Document | What You Build | Result When Done |
|-------|----------|----------------|------------------|
| **0** | [phase-0-project-setup.md](./phase-0-project-setup.md) | Flutter project scaffold, CI, linting, folder structure | Empty app that builds on Android, iOS, Windows, macOS |
| **1** | [phase-1-device-discovery.md](./phase-1-device-discovery.md) | mDNS/NSD device discovery on local network | Devices find each other automatically |
| **2** | [phase-2-file-transfer-core.md](./phase-2-file-transfer-core.md) | 1:1 file send/receive over local HTTP server | Files transfer between two devices |
| **3** | [phase-3-resumable-transfers.md](./phase-3-resumable-transfers.md) | Chunk-based transfer with resume on disconnect | Interrupted transfers resume, not restart |
| **4** | [phase-4-transfer-history.md](./phase-4-transfer-history.md) | Local SQLite history + resend capability | Users see past transfers & can resend |
| **5** | [phase-5-ui-polish-onboarding.md](./phase-5-ui-polish-onboarding.md) | Full UI (onboarding, send/receive flows, settings, permissions) | Complete, polished user-facing app |
| **6** | [phase-6-room-mode.md](./phase-6-room-mode.md) | Group transfer rooms (QR/code, multi-device) | Group file sharing works |
| **7** | [phase-7-merge-space.md](./phase-7-merge-space.md) | Multi-device sync folder with background agent | Auto-sync across owned devices |
| **8** | [phase-8-hardening-launch.md](./phase-8-hardening-launch.md) | Security, performance, store listing, beta test | App ready for public release |

---

## Tech Stack (Decided)

| Component | Choice | Package / Tool |
|-----------|--------|----------------|
| Framework | Flutter | `flutter` SDK |
| Language | Dart | |
| Discovery | mDNS/Bonjour | `bonsoir` or `nsd_android` + Bonjour on iOS |
| HTTP Server | Embedded local server | `shelf` / `shelf_io` |
| HTTP Client | HTTP requests | `dio` |
| Local DB | SQLite | `sqflite` + `drift` (type-safe ORM) |
| State Management | Riverpod | `flutter_riverpod` |
| Routing | GoRouter | `go_router` |
| File Picker | System file picker | `file_picker` |
| QR Code | Generate + Scan | `qr_flutter` + `mobile_scanner` |
| Encryption | TLS / AES | `pointycastle` or `cryptography` |
| Testing | Unit + Widget + Integration | `flutter_test`, `integration_test`, `mockito` |
| CI | GitHub Actions | `.github/workflows/` |

---

## Folder Structure (Target)

```
nearshare/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/                    # Shared utilities, constants, errors
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── utils/
│   │   └── extensions/
│   ├── features/                # Feature-based modules
│   │   ├── discovery/           # Phase 1: Device discovery
│   │   │   ├── data/            # Repositories, data sources
│   │   │   ├── domain/          # Models, interfaces
│   │   │   └── presentation/   # UI widgets, screens, providers
│   │   ├── transfer/            # Phase 2-3: File transfer + resume
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── history/             # Phase 4: Transfer history
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── onboarding/          # Phase 5: Onboarding flow
│   │   │   └── presentation/
│   │   ├── settings/            # Phase 5: Settings
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── rooms/               # Phase 6: Room mode
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   └── merge_space/         # Phase 7: Merge Space sync
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   └── shared/                  # Shared widgets, theme, navigation
│       ├── widgets/
│       ├── theme/
│       └── navigation/
├── test/                        # Unit + widget tests (mirrors lib/)
├── integration_test/            # Integration / E2E tests
├── assets/                      # Icons, images, animations
├── planning/                    # This folder — specs and plans
└── .github/workflows/           # CI pipeline
```

---

## Dependency Graph

```
Phase 0 (Setup)
    │
    ▼
Phase 1 (Discovery)
    │
    ▼
Phase 2 (File Transfer) ──────► Phase 3 (Resumable)
                                    │
                                    ▼
                               Phase 4 (History)
                                    │
                                    ▼
                               Phase 5 (UI Polish)
                                    │
                          ┌─────────┴─────────┐
                          ▼                   ▼
                   Phase 6 (Rooms)    Phase 7 (Merge Space)
                          │                   │
                          └─────────┬─────────┘
                                    ▼
                            Phase 8 (Launch)
```

> **Note:** Phase 6 and Phase 7 are independent of each other and can be developed in parallel by different developers.

---

## Estimated Timeline

| Phase | Estimated Duration | Cumulative |
|-------|--------------------|------------|
| 0 — Project Setup | 1–2 days | Day 2 |
| 1 — Discovery | 3–4 days | Week 1 |
| 2 — File Transfer | 4–5 days | Week 2 |
| 3 — Resumable Transfer | 3–4 days | Week 2.5 |
| 4 — Transfer History | 2–3 days | Week 3 |
| 5 — UI Polish & Onboarding | 5–7 days | Week 4 |
| 6 — Room Mode | 5–7 days | Week 5 |
| 7 — Merge Space | 7–10 days | Week 6–7 |
| 8 — Hardening & Launch | 5–7 days | Week 8 |

---

## Getting Started

**Start here → [Phase 0: Project Setup](./phase-0-project-setup.md)**

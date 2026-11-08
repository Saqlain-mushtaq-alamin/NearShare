# NearShare Privacy Policy

**Effective date:** November 2, 2026

NearShare is designed as a local-first file transfer and synchronization tool.
This policy explains what the app does and does not do with your information.

## Summary

- NearShare does **not** collect, transmit, sell, or share personal data.
- There is no account, cloud service, advertising SDK, analytics SDK, or
  telemetry.
- Files are sent directly between devices on the same local network.
- Data created by the app stays on your device unless you choose to send a file
  to another device.

## Information NearShare Uses

NearShare may access or create the following information on your device:

- **Device identity** — a randomly generated device ID, a user-visible device
  name, and the platform name. These are advertised on the local network so
  nearby peers can identify the device.
- **Local network information** — local IP address, port, and mDNS service
  records needed to discover and connect to peers.
- **Files you select** — files and folders you explicitly choose to send or
  share in a room or Merge Space.
- **Transfer history** — records of sent and received files, including names,
  sizes, timestamps, status, and save locations.
- **Merge Space data** — paired-device records, shared-folder indexes, group
  metadata, and conflict records.
- **Security material** — a local TLS certificate and private key, Merge Space
  group keys, and the local database encryption key.
- **Settings** — preferences such as onboarding completion and app-lock
  enabled/disabled.

This information is used only to provide the app's features. It is not sent to
the developer or any third party.

## Local Network Activity

NearShare broadcasts a service record on the local network so other NearShare
devices can find it. The record contains the device ID, display name, platform,
port, and, when enabled, a TLS certificate fingerprint. Anyone capable of
monitoring your local network may be able to see this broadcast.

When you send a file or join a room or Merge Space, the app connects directly to
the selected device. The receiving device can see your device name and the file
metadata required to accept the transfer.

## Storage and Retention

Transfer history, Merge Space metadata, and app settings are stored locally.
Sensitive keys and certificates are stored in the platform secure storage, and
local databases are encrypted with SQLCipher where supported.

Received files are stored in the location shown by the app, typically the
NearShare folder in the device's documents or downloads area. Temporary chunk
files are removed when a transfer completes, fails, or is cancelled.

Data remains on your device until you delete it in the app, clear app data, or
uninstall the app. Uninstalling the app removes app-managed data, subject to
operating-system backup behavior. NearShare disables Android app backups so its
local secrets are not copied off-device.

## Permissions

NearShare may request:

- **Local network / Wi-Fi access** to discover peers and transfer files.
- **Biometric or device credential access** only if you enable App Lock.
- **File access** for files and folders you explicitly choose.

NearShare does not use these permissions for advertising or tracking.

## Sharing

NearShare does not share data with the developer or third parties. Data is
shared only with devices you select through the app's transfer, room, or Merge
Space features. You are responsible for choosing recipients and for the
security of your local network.

## Children's Privacy

NearShare does not collect personal information from anyone, including
children. The app does not require an account or provide social features beyond
local device-to-device sharing.

## Security

NearShare uses local-network request filtering, rate limits, TLS certificate
pinning for device transfers, SHA-256 checksum verification, encrypted local
databases, secure storage for secrets, and an optional app lock. No method of
transmission or storage is completely secure, so use NearShare only on networks
and with devices you trust.

## Changes

If this policy changes, the updated version will be published with the app or
in the project repository with a new effective date.

## Contact

For privacy questions, open an issue in the NearShare project repository. Do not
include personal data or security-sensitive details in a public issue.

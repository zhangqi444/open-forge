# Spacedrive

Cross-device data platform and virtual distributed file system (VDFS). Spacedrive indexes files, emails, notes, and cloud storage across all your devices into a unified, searchable library. It tracks content identity via BLAKE3 hashes, syncs metadata via P2P (Iroh/QUIC), and provides a unified view across local disks, NAS, and cloud volumes — without moving data.

**Official site:** https://v2.spacedrive.com  
**License:** FSL-1.1-ALv2 (Functional Source License — not OSI open source)

> ⚠️ **Note:** Spacedrive v2 is a major rewrite in active development. Self-hosted server mode is available but APIs and deployment patterns are evolving rapidly.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| macOS / Windows / Linux | Desktop app | Primary supported deployment; all features |
| Linux server | Headless daemon | Experimental; serves as a library node for desktop clients |
| Any | Docker | Community/experimental; no official image yet |

---

## Inputs to Collect

### Phase 1 — Planning
- Primary device (desktop app) for initial setup
- File paths to index (local disks, NAS mounts, external drives)
- Cloud volumes to connect: S3, Google Drive, Dropbox, OneDrive, Azure, GCS
- Whether to run a headless server node (for always-on indexing)

### Phase 2 — Deployment
- Node pairing: each device runs a Spacedrive instance and is added to a shared "library"
- P2P discovery via Iroh/QUIC — no port forwarding required for device-to-device sync

---

## Software-Layer Concerns

### Desktop App Install

Download the latest release from https://github.com/spacedriveapp/spacedrive/releases for macOS, Windows, or Linux.

### Headless Server (Linux)

```bash
# Build from source (Rust + Node.js required)
git clone --recurse-submodules https://github.com/spacedriveapp/spacedrive
cd spacedrive
./scripts/setup.sh
# Build headless daemon
cargo build --release -p sd-server
./target/release/sd-server
```

### Key Concepts
| Concept | Description |
|---------|-------------|
| **Library** | A shared namespace of indexed files across devices |
| **Volume** | A storage source: local disk, NAS, S3, cloud drive |
| **Location** | A folder within a volume that Spacedrive indexes |
| **BLAKE3 hash** | Content identity — same file on two devices = same hash |
| **Sidecar** | Metadata file stored alongside original (thumbnails, transcripts) |
| **Adapter** | Script-based connector for external data sources (Gmail, Obsidian, GitHub, etc.) |

### P2P Sync
- Devices connect via **Iroh/QUIC** — no central server needed
- Metadata (file index, hashes, tags) syncs between devices; **files stay where they are**
- Offline devices remain in the index and show as "offline"

### Data Archival Adapters
Shipped adapters index external sources as searchable repositories:
Gmail, Apple Notes, Chrome Bookmarks, Chrome History, Safari History, Obsidian, Slack, GitHub, macOS Contacts, macOS Calendar, OpenCode.

### Spacebot (AI Agent Integration)
Optional `spacebot` process pairs with a Spacedrive node as its home device. Routes AI agent operations (file reads, shell commands) through Spacedrive's permission system across the full device fleet — one security model for all devices.

---

## Upgrade Procedure

Desktop: auto-update or download new release from GitHub.

Server: `git pull`, rebuild binary, restart.

---

## Gotchas

- **FSL License**: Spacedrive v2 uses the Functional Source License (FSL-1.1-ALv2) — it converts to Apache-2.0 after 2 years, but is **not currently OSI open source**. Commercial use restrictions apply.
- **Active development**: v2 is a major rewrite; APIs, config, and deployment patterns change frequently. Not yet stable for production use.
- **No official Docker image**: Self-hosting via Docker requires building from source or using community images.
- **Metadata-only sync**: P2P sync moves index metadata, not file bytes — you keep files where they are; copies require manual transfer.
- **Desktop-first**: The server daemon is experimental; primary UX and setup flows are through the desktop app.

---

## References
- GitHub: https://github.com/spacedriveapp/spacedrive
- Website: https://v2.spacedrive.com
- Discord: https://discord.gg/gTaF2Z44f5

---
name: VersityGW (Versity S3 Gateway)
description: "Go S3-compatible gateway. Translates S3 API to local filesystem / other backends. Apache-2. Versity Software (commercial backing). Multi-arch (Linux/macOS/BSD amd64+arm64). Optional WebGUI. Enterprise support available."
---

# VersityGW (Versity S3 Gateway)

VersityGW is **"MinIO / Ceph RADOS Gateway / s3proxy — but Go + multi-backend + commercially-backed + Apache-2"** — a high-performance S3 translation service. Turn your local filesystem INTO an S3 server, OR proxy S3 requests to other S3 storage, OR bridge POSIX+S3 (files accessible both ways). Built by **Versity Software** with commercial enterprise support available.

Built + maintained by **Versity Software**. License: **Apache-2.0**. Active; multi-platform binaries (Linux/macOS/BSD × amd64/arm64 = 6 targets); optional WebGUI; mailing list + community discussions + commercial sales.

Use cases: (a) **expose local-filesystem as S3** — let apps talk S3 to disk (b) **S3-to-S3 proxy** — translate/filter requests (c) **POSIX+S3 unified access** — files accessible via both (d) **S3-compatible gateway in front of exotic storage** — tape, object-store, etc (e) **test harness for S3-code** — local dev (f) **legacy-data + cloud-native apps** integration (g) **compliance gateway** — filter/audit S3 requests (h) **multi-cloud S3 abstraction**.

Features (per README):

- **S3 protocol** translation
- **Multiple backends** (posix, s3 proxy, more)
- **WebGUI** (optional) — management + S3 explorer
- **Multi-platform binaries**: Linux/macOS/BSD × amd64/arm64
- **Enterprise support** (commercial, Versity Sales)
- **Apache-2 OSS core**
- **Go Report Card** passing
- **Simplified interface** to add new storage backends

- Upstream repo: <https://github.com/versity/versitygw>
- Website: <https://www.versity.com>
- WebGUI wiki: <https://github.com/versity/versitygw/wiki/WebGUI>
- Releases: <https://github.com/versity/versitygw/releases>

## Architecture in one minute

- **Go** single binary (~20MB)
- **Stateless-ish** (config + in-memory mapping)
- **Resource**: low-moderate — scales with traffic
- **Port**: default S3 (configurable)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Binary**         | **Multi-platform release**                                      | **Primary**                                                                        |
| **Docker**         | Unofficial (check)                                                                                                     | Community                                                                                   |
| **Systemd**        | Binary + service unit                                                                                                  | Common                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Backend              | posix (`/path/to/data`) OR S3 URL                            | Config       |                                                                                    |
| **Access keys**      | S3 access-key-ID + secret                                   | **CRITICAL** | **Generated + configured**                                                                                    |
| TLS cert             | For S3-over-HTTPS                                           | Security     | S3 clients expect HTTPS                                                                                    |
| Domain + bucket-DNS  | `s3.example.com` + `*.s3.example.com`                       | URL          | Virtual-host-style S3                                                                                    |
| WebGUI creds (opt)   | Admin                                                        | Config       |                                                                                    |

## Install

```sh
# Binary:
wget https://github.com/versity/versitygw/releases/download/vX.Y/versitygw-linux-amd64
chmod +x versitygw-linux-amd64
./versitygw-linux-amd64 posix /path/to/data
```

Or docker-compose (community):
```yaml
services:
  versitygw:
    image: versity/versitygw:v1.4.1        # **check for official image**
    environment:
      ROOT_ACCESS_KEY: ${ROOT_ACCESS_KEY}
      ROOT_SECRET_KEY: ${ROOT_SECRET_KEY}
    volumes:
      - ./data:/data
    command: posix /data
    ports: ["7070:7070"]
    restart: unless-stopped
```

## First boot

1. Install binary
2. Generate strong access-key + secret (random 32+ chars each)
3. Start gateway pointing to backend
4. Test with `aws s3` CLI: `aws --endpoint-url http://localhost:7070 s3 ls`
5. Enable WebGUI if desired
6. Put behind HTTPS reverse proxy (S3 clients expect HTTPS for most features)
7. Configure DNS for virtual-hosted-style buckets
8. Back up config + access keys

## Data & config layout

- **Backend**: the actual data (posix = filesystem, S3 = remote S3)
- Config file + access-key DB

## Backup

Back up the BACKEND (filesystem or remote S3). VersityGW itself is primarily stateless + config.

## Upgrade

1. Releases: <https://github.com/versity/versitygw/releases>. Active.
2. Replace binary
3. Test S3 API compatibility after major-version bumps

## Gotchas

- **123rd HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — S3-GATEWAY-AUTH**:
  - Holds S3 access keys + secrets
  - Compromise = access to ALL backend data
  - **123rd tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "S3-gateway + object-storage-credential-hub"** (1st — VersityGW; distinct from Parseable 113 which CONSUMES S3 — VersityGW PROVIDES S3)
  - **CROWN-JEWEL Tier 1: 35 tools / 32 sub-categories**
- **POSIX ↔ S3 DUAL-MODE DATA-CONSISTENCY**:
  - Same files accessible via filesystem AND S3 — race-conditions possible
  - **Recipe convention: "dual-mode-data-consistency-risk callout"** — important
  - **NEW recipe convention** (VersityGW 1st formally)
- **S3 VIRTUAL-HOST-STYLE REQUIRES WILDCARD DNS**:
  - `bucket.s3.example.com` vs `s3.example.com/bucket`
  - Virtual-host is more common now
  - **Recipe convention: "S3-virtual-host-style-DNS-requirement" callout**
  - **NEW recipe convention** (VersityGW 1st formally)
- **GO-REPORT-CARD**:
  - Code-quality signal
  - **Go-Report-Card: 4 tools** (Gokapi+Sablier+PBW+VersityGW) 🎯 **4-TOOL MILESTONE**
- **MULTI-PLATFORM BINARY BREADTH**:
  - Linux/macOS/BSD × amd64/arm64 = 6 targets
  - BSD-support is rare
  - **BSD-support: 2 tools** (Polaris+VersityGW) 🎯 **2-TOOL MILESTONE**
- **COMMERCIAL-PARALLEL**:
  - Versity Sales + enterprise-support
  - **Commercial-parallel-with-OSS-core: 9 tools** (+VersityGW) 🎯 **9-TOOL MILESTONE**
- **MAILING-LIST (pre-Discord-era infra)**:
  - Still used for enterprise announcements
  - **Recipe convention: "mailing-list-enterprise-communication" neutral-signal**
  - **NEW neutral-signal convention** (VersityGW 1st formally)
- **APACHE-2 PERMISSIVE**:
  - Not copyleft; enterprise-friendly
  - **Recipe convention: "Apache-2-permissive-license neutral-signal"** — standard
- **S3 API COMPATIBILITY GAPS**:
  - No S3 implementation is 100%
  - Check which features your client needs
  - **Recipe convention: "S3-API-compatibility-partial-always" callout**
  - **NEW recipe convention** (VersityGW 1st formally — applies to all S3 gateways)
- **INSTITUTIONAL-STEWARDSHIP**: Versity Software + commercial-backed + mailing-list + wiki + enterprise-sales + Apache-2. **109th tool — commercial-company-with-OSS-parallel sub-tier** (reinforces).
- **TRANSPARENT-MAINTENANCE**: active + Go-Report-Card + mailing-list + wiki + releases + community + enterprise-sales. **116th tool in transparent-maintenance family.**
- **S3-GATEWAY-CATEGORY:**
  - **VersityGW** — Go; commercial-backed; multi-platform
  - **MinIO** — Go; dominant OSS S3; AGPL v3 (stricter license)
  - **SeaweedFS** — Go; distributed
  - **Garage** — Rust; geo-distributed
  - **Ceph RADOS Gateway** — enterprise distributed
  - **s3proxy** — Java; multiple-backends
  - **rclone serve s3** — rclone-based
- **ALTERNATIVES WORTH KNOWING:**
  - **MinIO** — if you want dominant OSS-S3 + strong clients
  - **Garage** — if you want Rust + geo-distributed
  - **rclone serve s3** — if you want minimal + many-backends
  - **s3proxy** — if you want Java + many-backends
  - **Choose VersityGW if:** you want Apache-2 + BSD-support + commercial-option.
- **PROJECT HEALTH**: active + commercial-backed + Apache-2 + multi-platform + Go-quality. EXCELLENT.

## Links

- Repo: <https://github.com/versity/versitygw>
- Website: <https://www.versity.com>
- Wiki: <https://github.com/versity/versitygw/wiki>
- MinIO (alt): <https://github.com/minio/minio>
- Garage (alt): <https://garagehq.deuxfleurs.fr>
- rclone (alt): <https://rclone.org>

---
name: Diskover (Community Edition)
description: "Open-source file indexer + search engine + data-analytics + management platform. Elasticsearch-powered. Python + PHP web app. Commercial subscription tier available. diskoverdata/diskover-community."
---

# Diskover (Community Edition)

Diskover CE is **"Elasticsearch-powered file-system x-ray for storage admins"** — an open-source file-system indexer using Elasticsearch to index + manage data across heterogeneous storage. Identify old/unused/duplicate files, monitor usage, report, and make data-driven storage decisions. Crawls local FS, NFS, SMB, cloud. Plugin architecture for additional metadata.

Built + maintained by **diskoverdata** (commercial company). Python (indexer) + PHP web-app (diskover-web). Runs on Linux, macOS, Windows 10. Free CE for unlimited time — commercial annual-subscription for advanced features. Released Diskover v2.3.4 CE Jan 2026 (recent).

Use cases: (a) **petabyte-scale file-system observability** (b) **identify old/duplicate/wasted files** (c) **storage capacity planning** (d) **data-migration reporting** (e) **multi-filesystem unified search** (f) **cloud-storage audit** (g) **enterprise storage administration** (h) **home-lab duplicate-finder on steroids**.

Features (per README):

- **Elasticsearch-powered** indexing
- **Multi-source crawling** (local FS, NFS, SMB, cloud)
- **Plugin architecture** for metadata
- **Web app** (PHP/JS/HTML5/CSS)
- **Cross-platform** (Linux, macOS, Win10)
- **CE free** — unlimited time
- **Commercial-parallel** (enterprise tier)

- Upstream repo: <https://github.com/diskoverdata/diskover-community>
- Website: <https://diskoverdata.com>
- Docs: <https://github.com/diskoverdata/diskover-docs>
- Plans (commercial): <https://diskoverdata.com/platforms/diskover-plans/>

## Architecture in one minute

- **Python** indexer (crawler)
- **Elasticsearch** data store (required, substantial)
- **PHP** web app (diskover-web)
- **Resource**: moderate-to-heavy — Elasticsearch needs RAM (2GB+ min, more for large indexes)
- **Ports**: ES + web

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Native**         | Python + PHP + ES                                                                                                      | **Primary**                                                                                   |
| **Docker**         | Community images                                                                                                       | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Elasticsearch        | v7/v8                                                       | DB           | **Required — heavy**                                                                                    |
| PHP web server       | nginx/Apache                                                | Web          |                                                                                    |
| File systems         | Paths to crawl                                              | Data         | **Read permissions required**                                                                                    |
| Cloud creds          | S3/Azure/GCS (optional)                                     | Secret       |                                                                                    |

## Install

Follow install guides linked from README. Many steps — ES setup + Python crawler + PHP web. Docker-compose approach is common community path.

Not reproducing full steps — consult upstream docs.

## First boot

1. Stand up Elasticsearch
2. Install crawler + web app
3. Configure indexes
4. Kick off first crawl (can take hours/days for large storage)
5. Browse results in diskover-web
6. Configure scheduled re-index
7. Consider commercial upgrade if need advanced features
8. Back up ES + crawler config

## Data & config layout

- Elasticsearch indexes — crawled-file metadata (potentially petabytes of entries)
- crawler config
- web app config + user accounts

## Backup

```sh
# Snapshot Elasticsearch indexes
# Backup config files
# Contents: file-path + metadata listings (potentially sensitive-path-disclosure)
```

## Upgrade

1. Releases: <https://github.com/diskoverdata/diskover-community/releases>
2. v1.X EOL — plan migration to v2.x
3. ES-version compatibility matters

## Gotchas

- **184th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — FILE-SYSTEM-METADATA-INDEX + STORAGE-CREDS**:
  - Holds: **path-index of ALL files** on crawled storage, NFS/SMB credentials, cloud-storage creds, file-path + filename metadata
  - Knowing what paths + filenames exist on an org's storage = reconnaissance-treasure
  - **184th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "file-system-metadata-index + storage-recon"** (1st — Diskover; distinct from oCIS which is file-content, this is metadata-only at scale)
  - **CROWN-JEWEL Tier 1: 64 tools / 57 sub-categories**
- **ELASTICSEARCH-REQUIRED**:
  - ES is heavy + ops-overhead
  - **Elasticsearch-required-dependency: 4 tools** (+Diskover) 🎯 **4-TOOL MILESTONE** (extending media-stack ES users)
- **COMMUNITY-EDITION-VS-ENTERPRISE**:
  - CE is genuine unlimited-time OSS
  - Enterprise features behind subscription
  - **Commercial-parallel-with-OSS-core: 17 tools** 🎯 **17-TOOL MILESTONE** (+Diskover)
  - **Genuine-CE-unlimited-time: 1 tool** 🎯 **NEW FAMILY** (Diskover — distinct from trial/freemium; CE is forever-free)
- **PETABYTE-SCALE-PLANNING**:
  - Designed for enterprise storage at scale
  - **Recipe convention: "petabyte-scale-storage-architecture-planning"** reinforces Open Archiver (121)
- **CROSS-PLATFORM-SERVER-TOOL**:
  - Linux + macOS + Win10
  - Rare for server-tool
  - **Cross-platform-server-tool: 2 tools** (Cloud Commander+Diskover) 🎯 **2-TOOL MILESTONE**
- **PLUGIN-API-ARCHITECTURE**:
  - Metadata plugins
  - **Plugin-API-architecture: 6 tools** 🎯 **6-TOOL MILESTONE** (+Diskover)
- **EOL-V1-EXPLICIT-WARNING**:
  - README mentions v1.X EOL
  - Good maintenance discipline
  - **Recipe convention: "explicit-EOL-major-version-warning positive-signal"**
  - **NEW positive-signal convention** (Diskover 1st formally)
- **DECADE-PLUS-OSS**:
  - Diskover has long history
  - **Decade-plus-OSS: 14 tools** (+Diskover) 🎯 **14-TOOL MILESTONE**
- **JANUARY-2026-RECENT-RELEASE**:
  - v2.3.4 Jan 2026 = actively maintained
  - **Recipe convention: "recent-release-confirms-active-maintenance positive-signal"**
  - **NEW positive-signal convention** (Diskover 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: diskoverdata company + CE-unlimited + ES-ecosystem + cross-platform + docs-repo-separate + commercial-tier. **170th tool — commercial-company-OSS-CE-steward sub-tier** (NEW-soft) 🎯 **170-TOOL INSTITUTIONAL-STEWARDSHIP MILESTONE at Diskover**.
- **TRANSPARENT-MAINTENANCE**: active + releases + docs + commercial-parallel + recent-release + EOL-warning. **176th tool in transparent-maintenance family.**
- **STORAGE-ANALYTICS-CATEGORY:**
  - **Diskover CE** — Elasticsearch-powered; enterprise-grade; commercial-tier
  - **Czkawka** — local GUI dedup (b119)
  - **WizTree / WinDirStat** — desktop disk-usage
  - **Cloud vendor analytics** — AWS/GCP/Azure native
- **ALTERNATIVES WORTH KNOWING:**
  - **Czkawka** — if you want desktop-scale + no ES
  - **WizTree / ncdu** — if you just want disk usage
  - **Choose Diskover if:** you need enterprise-scale + search + plugins + cross-platform.
- **PROJECT HEALTH**: active (Jan-2026 release) + commercial-backed + CE-free + cross-platform. Strong.

## Links

- Repo: <https://github.com/diskoverdata/diskover-community>
- Website: <https://diskoverdata.com>
- Czkawka (alt): <https://github.com/qarmin/czkawka>

---
name: OpenCloud
description: "Modern, secure cloud-storage + collaboration platform — the successor to ownCloud Infinite Scale (OCIS). Forked + rebooted by former ownCloud team. EU-headquartered (Germany). Go backend, database-less (filesystem + OIDC). Apache-2.0."
---

# OpenCloud

OpenCloud is **a modern, secure cloud-storage + collaboration platform for private clouds** — positioned as the **successor to ownCloud Infinite Scale (OCIS)** in terms of both architecture (same foundational design: Go, microservices, Spaces, no central DB) and team. The project was started in 2024 by former ownCloud GmbH engineers after the ownCloud ecosystem fragmented; OpenCloud GmbH is based in Germany and operates the commercial side.

**Positioning vs Nextcloud + ownCloud Classic + ownCloud Infinite Scale:**
- **Nextcloud** — the largest self-hosted file-share/collaboration platform (forked from ownCloud 2016); PHP-based; huge features
- **ownCloud Classic** — PHP, predecessor of Nextcloud; mostly legacy
- **ownCloud Infinite Scale (OCIS)** — Go-based rewrite of ownCloud; modern architecture
- **OpenCloud** — **Go-based; continuation of OCIS philosophy + team**; Apache-2.0

> **📌 Why the fork/reboot?** ownCloud GmbH's 2023 acquisition by Kiteworks led to uncertainty about OCIS's future + license stability. The former team reconstituted under OpenCloud GmbH to continue the Go-based modern architecture under clearer governance + Apache-2.0 licensing. Pattern similar to **MariaDB ← MySQL (Oracle)**, **OpenTofu ← Terraform (HashiCorp)**, **OpenBao ← Vault (HashiCorp)** — community-driven response to upstream corporate moves.

Features:

- **Spaces** — flexible storage units (personal + project + shared); modern alternative to traditional folder-sharing
- **End-to-end design for OIDC** — no built-in user DB; delegates to Keycloak / external IdP
- **Database-less backend** — all state on filesystem (massively simpler ops, different tradeoffs vs DB-backed)
- **Fast + modern** — Go microservices, performant at scale
- **WebDAV + S3 interfaces**
- **Desktop + mobile clients** — compatible with ownCloud / ocis client protocols
- **Collabora Online / OnlyOffice** integration for document editing
- **Activity feed + notifications**
- **Sharing** — per-file / per-space / public links
- **Trash + versioning**
- **Full-text search** (via external component)
- **Audit log**
- **Anti-virus scanning** (via ClamAV — see batch 64)

- Upstream repo (server): <https://github.com/opencloud-eu/opencloud>
- Org: <https://github.com/opencloud-eu>
- Website: <https://opencloud.eu>
- Docs: <https://docs.opencloud.eu>
- Matrix: `#opencloud:matrix.org`
- CI: <https://ci.opencloud.rocks>
- Commercial: **OpenCloud GmbH** (Germany)

## Architecture in one minute

- **Go microservices** — dozens of small services (frontend, webdav, graph, storage, etc.)
- **Single `opencloud` binary** bundles all services (process-per-service internally)
- **Filesystem storage** — no database! State + metadata in filesystem (POSIX + xattrs)
- **LibreGraph Connect (lico)** — embedded IdP (minimal); Keycloak / Authentik / external OIDC preferred in production
- **Reva** under the hood — shared codebase with CS3 Mesh Operations (European science-cloud project)
- **Resource**: moderate — 1-2 GB RAM for small deployments; scales horizontally

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker Compose**                                                 | **Upstream-recommended**                                                           |
| Single VM          | Go binary + systemd                                                        | `make build` from source or grab release                                                                   |
| Kubernetes         | **Helm chart** (official)                                                                   | Production path                                                                                        |
| Managed            | **OpenCloud GmbH hosted** (commercial)                                                                      | Paid                                                                                                                |
| Raspberry Pi       | arm64 builds — possible                                                                                          | Fine for small deployments                                                                                                       |

## Inputs to collect

| Input                | Example                                         | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `cloud.example.com`                                 | URL          | TLS mandatory                                                                    |
| OIDC provider        | Keycloak / Authentik / Azure AD / Google                  | Auth         | **Required for production** — lico is dev-only for most scenarios                                |
| Storage path         | `$HOME/.opencloud/` (default) or configured                    | Storage      | Filesystem-based; plan capacity carefully                                                                 |
| Admin                | first user via OIDC or `ocis init` equivalent            | Bootstrap    | Bootstrap user                                                                                                       |
| ClamAV (opt)         | external service                                                         | Security     | For AV scan of uploads                                                                                                                        |
| Collabora / OnlyOffice | external service                                                                       | Integration  | For in-browser editing                                                                                                                                        |

## Install via binary (dev / simple)

Per upstream README:

```sh
# Clone + build
git clone https://github.com/opencloud-eu/opencloud.git
cd opencloud
make generate
make -C opencloud build

# Init + run
./opencloud/bin/opencloud init
./opencloud/bin/opencloud server
```

Creates `$HOME/.opencloud/` with config + storage. For production, use Docker Compose + external OIDC (see docs).

## Install via Docker Compose (production)

Use upstream's deployment examples — includes OpenCloud + Keycloak + TLS reverse proxy. See <https://docs.opencloud.eu/>.

## First boot

1. Browse OpenCloud URL → redirected to OIDC (Keycloak/Authentik)
2. Log in via IdP → OpenCloud creates your home Space
3. Upload a file via web UI → verify on filesystem (`ls $OPENCLOUD_BASE_DATA_PATH/spaces/<id>/`)
4. Create a Project Space for team collaboration
5. Invite users (creates OIDC users in Keycloak or your IdP)
6. Install desktop client (ownCloud/OCIS-compatible); log in + sync
7. (Optional) integrate Collabora / OnlyOffice for editing
8. Configure audit logs + retention per compliance

## Data & config layout

- `$OPENCLOUD_BASE_DATA_PATH/` (default `$HOME/.opencloud/`):
  - `storage/` — actual user files + metadata (xattrs)
  - `cert/` — TLS certs
  - `idm/` — lico identity data (if using embedded)
  - `proxy/`, `search/`, etc. — per-service state
- Config via env vars + optional YAML overrides

## Backup

```sh
# Whole data path — CRITICAL
sudo tar czf opencloud-$(date +%F).tgz $OPENCLOUD_BASE_DATA_PATH/
```

**Filesystem-based** backup is straightforward but **quiesce OpenCloud during snapshot** for consistency (LVM snapshot, ZFS snapshot, or stop service briefly). Also back up OIDC provider (Keycloak DB).

## Upgrade

1. Releases: <https://github.com/opencloud-eu/opencloud/releases>. Active.
2. **Back up data path + OIDC state.**
3. Docker: bump tag → restart → internal migrations.
4. Read release notes carefully — pre-1.0 APIs can change.
5. Desktop clients: generally forward-compatible.

## Gotchas

- **Pre-1.0 / early-stage**: OpenCloud is young (started 2024). Architecture is mature (inherited from OCIS), but branding + defaults + integrations still settling. Pin versions; monitor releases.
- **No database = different DR model.** Traditional ownCloud/Nextcloud backups = DB dump + files. OpenCloud = just files (with xattrs + metadata). Simpler in one dimension, requires POSIX-friendly storage (no S3-backed-POSIX without careful gateway).
- **OIDC is not optional in practice.** The embedded LibreGraph Connect is minimal. Real deployments use **Keycloak** / **Authentik** / **Azure AD** / **Google Workspace**. Plan IdP alongside OpenCloud — it's another service to run + back up.
- **Filesystem requirements**: xattrs, POSIX semantics, decent IOPS. ext4/XFS/ZFS on Linux. Not all NFS configs handle xattrs well; test before committing.
- **Scaling horizontally**: microservices architecture scales but requires shared storage (NFS/CephFS/similar) + load balancer. Non-trivial ops.
- **Comparison to Nextcloud**: Nextcloud is PHP-heavy, feature-rich (groupware, apps, talk, calendar, contacts, more). OpenCloud is Go-lean, storage-focused, modern. Different design targets.
- **Client compatibility**: OCIS-compatible clients. ownCloud official + iOS/Android apps. Some fragmentation in client ecosystem vs Nextcloud's dominance.
- **Migration from ownCloud / OCIS**: documented paths; test on copy. Nextcloud migration more complex (different architecture).
- **EU-headquartered (Germany)**: GDPR-native, data-sovereignty-friendly for EU orgs. (Similar jurisdiction framing to batch 68 Passbolt Luxembourg.)
- **Governance transparency**: OpenCloud GmbH is clear about being commercial (hosted + support). Code is Apache-2.0 in independent org. Less foundation-backed than Zammad (batch 71) but cleaner than single-company control.
- **CS3 Mesh / Reva heritage**: underlying Reva/CS3 code is shared with European academic cloud-federation projects (CERN, Science Mesh). Suggests strong interop roadmap.
- **Not a drop-in Nextcloud replacement**: if you want groupware + apps + Talk + calendars + 100+ plugins, Nextcloud is more feature-complete. OpenCloud is about files + spaces + collaboration on docs — a narrower but more focused scope.
- **Anti-virus**: ClamAV integration for upload scanning (pair with batch 64 ClamAV recipe).
- **Audit log**: available; configure retention per policy (SOC 2 / ISO 27001 / GDPR).
- **License**: **Apache-2.0** — straightforward permissive OSS.
- **Alternatives worth knowing:**
  - **Nextcloud** — dominant self-host cloud; PHP; groupware-rich (separate recipe likely)
  - **ownCloud Infinite Scale (OCIS)** — upstream lineage; governance uncertain post-acquisition
  - **Seafile** — Chinese-origin; C + Python; file-sync focus
  - **Pydio Cells** — Go; enterprise features; commercial lean
  - **NextcloudCasper / OnlyOffice Workspace** — Nextcloud + OnlyOffice integrated
  - **Mega / Sync.com / Tresorit** — commercial end-to-end cloud
  - **S3 + file browser (Cyberduck / Transmit)** — DIY
  - **Choose OpenCloud if:** modern Go stack, file-focused, EU jurisdiction, database-less simplicity + Apache-2.0 governance.
  - **Choose Nextcloud if:** you need the full groupware + 100s of apps + most mature ecosystem.
  - **Choose Seafile if:** Chinese/Asian userbase or file-sync performance priority.

## Links

- Repo: <https://github.com/opencloud-eu/opencloud>
- Org: <https://github.com/opencloud-eu>
- Website: <https://opencloud.eu>
- Docs: <https://docs.opencloud.eu>
- Releases: <https://github.com/opencloud-eu/opencloud/releases>
- Matrix: <https://app.element.io/#/room/#opencloud:matrix.org>
- LibreGraph Connect (embedded IdP): <https://github.com/libregraph/lico>
- Reva / CS3: <https://github.com/cs3org/reva>
- Keycloak (recommended IdP): <https://www.keycloak.org>
- Nextcloud (alt): <https://nextcloud.com>
- ownCloud Infinite Scale (lineage): <https://github.com/owncloud/ocis>
- Seafile (alt): <https://www.seafile.com>
- ClamAV (batch 64): <https://www.clamav.net>

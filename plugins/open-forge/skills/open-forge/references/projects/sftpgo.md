---
name: SFTPGo
description: Full-featured SFTP/SCP/FTPS/HTTP/WebDAV server in a single Go binary. Pluggable storage (local / S3 / GCS / Azure Blob / SFTP / HTTP / Crypt), PostgreSQL/MySQL/SQLite/BoltDB/in-memory user store, per-user quotas + bandwidth throttling + virtual folders, WebAdmin + WebClient UIs, 2FA, OIDC. AGPL-3.0 (community) + commercial Enterprise.
---

# SFTPGo

SFTPGo is a production-ready file-transfer server that speaks **SFTP, SCP, FTPS, HTTP(s), WebDAV** from a single Go binary. Modern alternative to `openssh-sftp`/`proftpd`/`vsftpd` with:

- **Protocols**: SFTP + SCP + FTPS + HTTP + WebDAV — all in one
- **Storage backends**: local FS, S3 (AWS/MinIO/R2/B2/Wasabi), GCS, Azure Blob, another SFTP server, HTTP, encrypted (Crypt)
- **User stores**: SQLite (default), BoltDB, PostgreSQL, MySQL, CockroachDB, in-memory
- **WebAdmin UI** (operator) + **WebClient UI** (end-user: browser file management)
- **Per-user/group**: quotas, bandwidth throttling, virtual folders (mix storage backends), home-dir templates, regex filters on filenames
- **2FA (TOTP)**, **OIDC SSO**, **public key auth**, **SSH cert**, **password + MFA combo**
- **Event hooks + actions** — webhook on login/upload/download/error
- **Recursive rate limits** + **defender** (auto-ban bad IPs)

- Upstream repo: <https://github.com/drakkan/sftpgo>
- Website: <https://sftpgo.com>
- Docs: <https://docs.sftpgo.com/latest/> (Community)
- Enterprise docs: <https://docs.sftpgo.com/enterprise/>
- Docker Hub: <https://hub.docker.com/r/drakkan/sftpgo>
- GHCR: <https://github.com/drakkan/sftpgo/pkgs/container/sftpgo>

## Open Source vs Enterprise

SFTPGo has a **sustainable dual-edition model**:

| Feature                     | Community (AGPLv3)                  | Enterprise (commercial)                                         |
| --------------------------- | ----------------------------------- | --------------------------------------------------------------- |
| Core protocols + storage    | ✅ Full                              | ✅ Full + performance optimizations                              |
| WebAdmin + WebClient        | ✅                                   | ✅ + in-browser document edit/co-author                          |
| Cloud storage performance   | Standard                            | In-memory streaming (no temp files); ~70% faster                 |
| High availability            | Shared DB + storage                 | Enhanced event handling + optimized instance coordination        |
| Automation                  | Simple placeholders                  | Dynamic logic, conditions, loops, multi-backend routing          |
| Data lifecycle              | Delete/retain                        | Smart archiving (move to cloud via virtual folders)              |
| Email ingestion             | —                                    | Native IMAP auto-extract attachments                              |
| Public sharing              | Standard links                       | Email auth + group delegation                                    |
| Data protection             | —                                    | Automated PGP + antivirus + DLP via ICAP                          |
| Advanced SSO                | Standard OIDC                        | Extended parameters                                              |
| Support                     | GitHub issues                        | Direct from authors, ISO 27001 vendor compliance                 |

Community edition is **fully production-ready** for standard file-transfer needs. Upgrade to Enterprise for compliance-heavy / mission-critical / high-performance cloud workflows.

## Architecture in one minute

- **Single Go binary** (`sftpgo`) — all protocols + web UIs in one process
- **User store DB**: SQLite default; Postgres/MySQL for HA or centralized auth
- **Home directories**: local filesystem OR cloud storage (S3/GCS/Azure) mounted per-user
- **Web admin** on `:8080` (configurable); **SFTP** on `:2022` (default in Docker; the real world usually runs on `:22`)

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                                     |
| ----------- | ------------------------------------------------ | ------------------------------------------------------------------------- |
| Single VM   | Docker (`drakkan/sftpgo:<VERSION>`)              | **Recommended**                                                            |
| Single VM   | Docker (`drakkan/sftpgo:<VERSION>-alpine`)       | Smaller image                                                              |
| Single VM   | Docker (`drakkan/sftpgo:<VERSION>-distroless`)   | Most minimal, security-hardened                                            |
| Single VM   | Native binary (systemd unit)                     | Official `.deb` / `.rpm` at <https://github.com/drakkan/sftpgo/releases>   |
| Kubernetes  | Official Helm chart                                | <https://github.com/sftpgo/helm-charts>                                    |
| Windows     | `.msi` installer                                   | Supported; same binary                                                     |

## Inputs to collect

| Input                         | Example                                | Phase     | Notes                                                                |
| ----------------------------- | -------------------------------------- | --------- | -------------------------------------------------------------------- |
| SFTP port                     | `2022:2022` or `22:2022`               | Network   | Container defaults to 2022; bind to 22 if it's the main SSH server     |
| WebAdmin/WebClient port       | `8080:8080`                            | Network   | HTTP; put behind TLS reverse proxy                                      |
| FTPS ports (optional)         | `2121:2121` + passive port range        | Network   | Only if you need FTPS                                                    |
| WebDAV port (optional)        | `10080:10080`                           | Network   | Only if you need WebDAV                                                   |
| Data dir                      | `./sftpgo-data:/srv/sftpgo`            | Storage   | User home dirs (local FS backend)                                          |
| Config dir                    | `./sftpgo-config:/var/lib/sftpgo`       | Storage   | DB (SQLite), logs, host keys                                              |
| Host keys                     | auto-generated on first run            | Security  | Persist with the config volume                                            |
| Admin creds                   | set via web wizard                     | Bootstrap | First-visit admin setup                                                   |
| OIDC (optional)               | client_id/secret/issuer                | Auth      | For SSO                                                                    |

## Install via Docker Compose

```yaml
services:
  sftpgo:
    image: drakkan/sftpgo:v2.6.6-alpine    # pin; check releases
    container_name: sftpgo
    restart: unless-stopped
    ports:
      - "2022:2022"      # SFTP
      - "8080:8080"      # Web admin + client
      # - "2121:2121"    # FTPS (optional)
      # - "10080:10080"  # WebDAV (optional)
    volumes:
      - ./sftpgo-data:/srv/sftpgo
      - ./sftpgo-config:/var/lib/sftpgo
    environment:
      SFTPGO_DEFAULT_ADMIN_USERNAME: admin
      SFTPGO_DEFAULT_ADMIN_PASSWORD: <strong>
      # Override via SFTPGO_* env var tree; config also supports TOML/YAML/JSON at /etc/sftpgo/sftpgo.json
```

Container runs as **UID 1000** (`USER 1000:1000` in Dockerfile). For bind mounts:

```sh
mkdir -p sftpgo-data sftpgo-config
sudo chown -R 1000:1000 sftpgo-data sftpgo-config
```

Image variants:

- `drakkan/sftpgo:latest` — full Debian base
- `drakkan/sftpgo:latest-alpine` — smaller
- `drakkan/sftpgo:latest-distroless` — minimal, security-hardened (no shell)

## First boot

1. Browse `http://<host>:8080/web/admin/setup` (or `/web/admin` if admin already bootstrapped)
2. Set the admin username + password (or use the env vars pre-seeded)
3. Log in at `/web/admin/login`
4. **Add user** → pick authentication (password / public key / both / TOTP / OIDC)
5. Configure home directory (local FS, S3, GCS, Azure, SFTP, HTTP, Crypt)
6. Test SFTP: `sftp -P 2022 user@<host>`

## Example: per-user S3 home

When adding a user via WebAdmin:

- **Home Dir**: `s3://my-bucket/users/alice/`
- **Storage filesystem**: S3
- **S3 credentials**: access key + secret + region
- **Path prefix**: `users/alice/`

SFTPGo mounts the S3 bucket as Alice's SFTP home. She uploads via SFTP → files land in S3.

Same pattern works with MinIO, Backblaze B2, Wasabi, Cloudflare R2, DigitalOcean Spaces (all S3-compatible).

## Data & config layout

Inside `/var/lib/sftpgo/`:

- `sftpgo.db` — SQLite user/group/share DB (default)
- `ssh_host_keys/` — **host keys** (`ssh_host_ed25519_key`, `ssh_host_rsa_key`, `ssh_host_ecdsa_key`) — preserving these across upgrades = no "host key changed" warnings
- `logs/` — access + audit logs
- `backups/` — scheduled backup dumps (configurable)

For local-filesystem backend, user home dirs live under `/srv/sftpgo/` by default.

## Backup

```sh
# Via SFTPGo's built-in backup API / command
docker compose exec sftpgo sftpgo dumpdata --output /var/lib/sftpgo/backups/sftpgo-$(date +%F).json

# Or filesystem-level
docker run --rm -v sftpgo-config:/src -v "$PWD":/backup alpine tar czf /backup/sftpgo-config-$(date +%F).tgz -C /src .
docker run --rm -v sftpgo-data:/src -v "$PWD":/backup alpine tar czf /backup/sftpgo-data-$(date +%F).tgz -C /src .

# Host keys especially critical — if lost, all SSH clients get "host key changed" warnings
```

Restore: `sftpgo loaddata --input <backup.json>` OR restore the config volume + restart.

## Upgrade

1. Releases: <https://github.com/drakkan/sftpgo/releases>. Active project, regular releases.
2. `docker compose pull && docker compose up -d`. DB migrations on startup.
3. **Preserve host keys** (`ssh_host_*_key` files in config volume) across upgrades.
4. Back up the user DB before every major bump.
5. Read release notes — occasional config key renames.

## Gotchas

- **Host keys must persist.** Without, every SFTP client sees "REMOTE HOST IDENTIFICATION HAS CHANGED" on reconnect (justifiably alarming). Mount the config volume; it stores the keys in `ssh_host_keys/`.
- **Port 2022 vs 22** — Docker container defaults to 2022 to coexist with the host's SSH. To run as the real SSH server port, bind `22:2022` in Docker (and move your host SSH to a different port first).
- **UID 1000** inside container — for bind mounts, `chown 1000:1000` on the host.
- **Default admin credentials** — `SFTPGO_DEFAULT_ADMIN_USERNAME` + `SFTPGO_DEFAULT_ADMIN_PASSWORD` pre-seed the admin. Change before exposing publicly, or let the setup wizard create it.
- **Web UI on port 8080 is HTTP by default.** Put behind TLS (Caddy / Traefik / nginx) before public exposure.
- **FTPS is OFF by default.** Enable only if a legacy client needs it; SFTP is preferred.
- **Passive FTP port range** must be predefined + opened in firewall + NAT-forwarded. For Docker, publish the range: `-p 50000-50100:50000-50100`.
- **S3 / GCS / Azure as home directory** — all API calls bill by request. High-frequency small ops (listing a big dir, many tiny uploads) can run up cloud bills.
- **Encrypted (Crypt) backend** encrypts files at rest with AES256 + per-user key. Use for cloud backends where you don't trust the provider.
- **Virtual folders** let you mount multiple storage backends under one user's directory tree — e.g., `/user/alice/local/` = local FS, `/user/alice/archive/` = S3 Glacier. Operator feature, powerful.
- **Rate limiting + defender** (auto-ban) — enabled by default; tune thresholds in config.
- **Two user stores = trouble**: SQLite is great for single-instance; for HA / multi-node, use Postgres + shared storage (or S3 backend).
- **AGPLv3 community** — public-facing SaaS requires source disclosure. Private / internal use = fine.
- **Enterprise license** is commercial; non-public pricing ("contact us"). Worth considering for regulated workloads (ISO 27001 vendor compliance).
- **OIDC** integrates with Keycloak, Zitadel, Authelia, Okta, Auth0 — configure via `SFTPGO_HTTPD__BINDINGS__0__OIDC__*` env vars.
- **Hooks** (pre-login, post-connect, pre-download, post-upload) — webhooks for audit / AV scanning / triggering pipelines.
- **WebClient** (end-user UI) lets users upload/download/share via browser — can enable/disable per-user.
- **Shares** — time-limited public links OR password-protected folder shares. Operator configurable.
- **Quotas** per user + per group (size + file count). Hard + soft thresholds.
- **No shell access** to SFTP users by design. Protocol-level file transfer only.
- **`sftpgo-plugin-*`** ecosystem: auth via LDAP/Keycloak plugin, kms via HashiCorp Vault, custom event handlers.
- **Alternatives worth knowing:**
  - **openssh-sftp-server** — built into OpenSSH; minimal features
  - **ProFTPd / vsftpd** — classic; FTP-focused
  - **MinIO** — S3-compatible object storage; can front with SFTPGo for SFTP access
  - **Syncthing** — peer-to-peer sync, not a server model
  - **Nextcloud** — webdav + browser UI, heavier, different focus
  - **Seafile** — block-level sync, different model
  - **FileRun** — commercial, polished UI
  - **rclone serve** — quick local-only SFTP/HTTP/WebDAV from rclone; no user mgmt

## Links

- Repo: <https://github.com/drakkan/sftpgo>
- Website: <https://sftpgo.com>
- Community docs: <https://docs.sftpgo.com/latest/>
- Enterprise docs: <https://docs.sftpgo.com/enterprise/>
- Getting started: <https://docs.sftpgo.com/latest/getting-started/>
- Configuration: <https://docs.sftpgo.com/latest/config-file/>
- Storage backends: <https://docs.sftpgo.com/latest/storages/>
- Helm chart: <https://github.com/sftpgo/helm-charts>
- Releases: <https://github.com/drakkan/sftpgo/releases>
- Docker Hub: <https://hub.docker.com/r/drakkan/sftpgo>
- GHCR: <https://github.com/drakkan/sftpgo/pkgs/container/sftpgo>
- Plugins: <https://github.com/sftpgo>
- Sponsors / commercial: <https://github.com/sponsors/drakkan>

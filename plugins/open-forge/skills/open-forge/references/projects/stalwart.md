---
name: Stalwart Mail Server
description: Modern all-in-one mail + collaboration server written in Rust. JMAP + IMAP4 + POP3 + SMTP + CalDAV + CardDAV + WebDAV in a single binary, with DMARC/DKIM/SPF/ARC, spam filter (Sieve + built-in rules), multi-tenancy, Let's Encrypt, web admin UI. Pluggable storage (RocksDB, Postgres, MySQL, SQLite, S3, FoundationDB, Redis). AGPL-3.0.
---

# Stalwart Mail Server

Stalwart is the "what if a mail server was designed in 2023 instead of 1993" answer. Single Rust binary that bundles everything mailcow/Mail-in-a-Box stitch together from separate daemons:

- **Protocols**: JMAP (RFC 8620), IMAP4, POP3, SMTP (submission + delivery), CalDAV, CardDAV, WebDAV
- **Authentication**: built-in, LDAP, OIDC, SQL
- **Storage backends (pluggable)**: RocksDB (default), **FoundationDB** (massive scale), PostgreSQL, MySQL, SQLite, S3-compatible, Azure Blob, Redis
- **Mail security**: DMARC + DKIM + SPF + ARC signing/verification, MTA-STS, DANE, SMTP TLS reporting
- **Spam filter**: Sieve scripting + integrated heuristics + Bayesian learning (no separate Rspamd)
- **Automatic TLS** via Let's Encrypt (ACME): DNS-01 (no public ports) or TLS-ALPN-01
- **Multi-tenancy** with domain + tenant isolation
- **Web admin UI** at `/admin` for config + mailbox management
- **Security-audited** (<https://stalw.art/blog/security-audit>)

Trade-offs vs **mailcow**:

- ✅ Single binary, much smaller footprint (~150 MB RAM vs 6 GB for mailcow)
- ✅ Modern: JMAP native, WebDAV/CalDAV/CardDAV included, proper multi-tenancy
- ✅ Pluggable SQL/S3 storage enables cluster deployments
- ✅ Automatic TLS — no separate acme container
- ❌ Younger project (v0.x still; API breakage between 0.10 → 0.12 → 0.15 → 0.16 has happened)
- ❌ Smaller ecosystem (no equivalent of mailcow's 15-container polished turnkey experience)
- ❌ Webmail NOT included — pair with Roundcube / SnappyMail / Cypht externally
- Written in **Rust** (vs mailcow's mix of PHP + shell + Go)

The same hard mail-hosting prerequisites apply: dedicated VPS with port 25 open, correct PTR, clean IP reputation, SPF/DKIM/DMARC DNS, etc.

- Upstream repo: <https://github.com/stalwartlabs/stalwart>
- Website: <https://stalw.art>
- Docs: <https://stalw.art/docs>
- Install (Docker): <https://stalw.art/docs/install/platform/docker>
- Requirements: <https://stalw.art/docs/install/requirements>
- DNS setup: <https://stalw.art/docs/install/dns>

## Architecture in one minute

- **Single binary** `stalwart` handles all protocols + admin UI
- **Config volume** (`/etc/stalwart`) — TOML configs, TLS certs (if ACME disabled), Sieve scripts
- **Data volume** (`/var/lib/stalwart`) — RocksDB data files (or empty if using external storage)
- **Optional external stores**: Postgres/MySQL/S3/Redis for HA or big deployments
- **Logs** → stdout in Docker (use Console logger, NOT File logger — container filesystem is ephemeral)

## Compatible install methods

| Infra         | Runtime                                       | Notes                                                                     |
| ------------- | --------------------------------------------- | ------------------------------------------------------------------------- |
| Single VM     | Docker (`stalwartlabs/stalwart:v0.16`)        | **Recommended** for most self-hosts                                        |
| Single VM     | Docker with FoundationDB image (`:v0.16-fdb`) | For FDB deployments                                                         |
| Single VM     | Debian package / macOS / Windows native       | Packages at <https://stalw.art/download>                                    |
| Kubernetes    | Community Helm                                  | Kubernetes + orchestration supported                                        |
| Docker Swarm  | Supported                                       | See <https://stalw.art/docs/cluster/orchestration/docker-swarm>             |

## Inputs to collect

| Input                       | Example                                | Phase     | Notes                                                                 |
| --------------------------- | -------------------------------------- | --------- | --------------------------------------------------------------------- |
| Mail hostname (FQDN)        | `mail.example.com`                     | DNS       | **PERMANENT-ish** — baked into TLS certs + SPF                          |
| Public IP + PTR             | IP + `mail.example.com`                | DNS       | **Critical** for deliverability                                        |
| DNS provider credentials    | Cloudflare/Route53/GCP/RFC2136 token   | ACME      | For DNS-01 challenge (no public ports needed)                           |
| `STALWART_RECOVERY_ADMIN`   | `admin:<strong-pw>`                    | Bootstrap | Skip log-extracted temp password; set before first start               |
| Storage backend             | RocksDB / Postgres / S3 / FoundationDB | Storage   | RocksDB fine for single-host; S3+Postgres for cluster                   |
| Spam filter config          | defaults are OK                        | Runtime   | Sieve scripts for custom rules                                         |
| Directory (auth backend)    | built-in / LDAP / OIDC / SQL           | Auth      | Built-in for small/simple; LDAP/SQL for integration                     |

## Install via Docker

Simplest path — uses built-in RocksDB:

```sh
docker volume create stalwart-etc
docker volume create stalwart-data

docker run -d --name stalwart --restart unless-stopped \
  -v stalwart-etc:/etc/stalwart \
  -v stalwart-data:/var/lib/stalwart \
  -p 25:25 -p 465:465 -p 587:587 \
  -p 143:143 -p 993:993 \
  -p 110:110 -p 995:995 \
  -p 443:443 -p 8080:8080 \
  -e STALWART_RECOVERY_ADMIN="admin:$(openssl rand -base64 24 | tr -d /=+)" \
  stalwartlabs/stalwart:v0.16    # pin; avoid :latest
```

Compose equivalent:

```yaml
services:
  stalwart:
    image: stalwartlabs/stalwart:v0.16
    container_name: stalwart
    restart: unless-stopped
    environment:
      STALWART_RECOVERY_ADMIN: "admin:${STALWART_ADMIN_PW:?}"
    volumes:
      - stalwart-etc:/etc/stalwart
      - stalwart-data:/var/lib/stalwart
    ports:
      - "25:25"
      - "465:465"
      - "587:587"
      - "143:143"
      - "993:993"
      - "110:110"
      - "995:995"
      - "443:443"     # HTTPS + ACME TLS-ALPN-01
      - "8080:8080"   # management HTTP (setup wizard)

volumes:
  stalwart-etc:
  stalwart-data:
```

## First-boot setup wizard

1. Start container → it runs in **bootstrap mode** with a transient admin
2. If you didn't set `STALWART_RECOVERY_ADMIN`:
   ```sh
   docker logs stalwart 2>&1 | grep -A8 'bootstrap mode'
   # Copy the 16-char password
   ```
3. Browse **`http://<host>:8080/admin`**
4. Log in with `admin` + temp/recovery password
5. Setup wizard asks:
   - **Server hostname** (e.g., `mail.example.com`)
   - **Admin email + password** (final, persistent)
   - **TLS certificate** (Let's Encrypt ACME recommended)
   - **DKIM keys** (auto-generate: yes)
   - **DNS management** (auto via Cloudflare/Route53/GCP/RFC2136, or manual with exported zone file)
   - **Directory backend** (built-in / LDAP / SQL / OIDC)
   - **Logging** → **Console** (NOT File — container ephemeral)
   - **Storage backend** (RocksDB default)
6. Save final admin password — **shown once only**, not recoverable from logs
7. **Restart** the container
8. Log in to the WebUI at `https://mail.example.com/admin` with the permanent admin

## DNS requirements

Generated by Stalwart after setup (exportable as zone file):

- **MX** → your host
- **A / AAAA** → hostname to IP
- **SPF** TXT (e.g., `v=spf1 mx -all`)
- **DKIM** TXT (keys generated by Stalwart)
- **DMARC** TXT (policy recommended: `p=quarantine` then `p=reject`)
- **MTA-STS** TXT + HTTPS policy file
- **TLSRPT** TXT
- **autoconfig** / **autodiscover** CNAME (client autoconfig)
- **PTR** (set via VPS provider, not DNS host)

## Data & config layout

Container-side:

- `/etc/stalwart/` — `config.toml`, domain configs, certs, Sieve scripts, admin web UI assets
- `/var/lib/stalwart/` — RocksDB data (mailboxes, JMAP state, Bayesian training data, queue)
- `/tmp/` — ephemeral

With external storage (S3 + Postgres):

- `/etc/stalwart/` stays local
- `/var/lib/stalwart/` nearly empty
- Mailboxes + metadata in Postgres, blobs in S3 → enables HA/cluster

## Backup

```sh
# Stop for consistent snapshot
docker stop stalwart
docker run --rm -v stalwart-etc:/src -v "$PWD":/backup alpine \
  tar czf /backup/stalwart-etc-$(date +%F).tgz -C /src .
docker run --rm -v stalwart-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/stalwart-data-$(date +%F).tgz -C /src .
docker start stalwart

# For PostgreSQL backend: pg_dump
# For S3 backend: bucket versioning + replication
```

DKIM private keys live in the config volume; losing them = signatures break + you must regenerate + republish DNS.

## Upgrade

1. Releases: <https://github.com/stalwartlabs/stalwart/releases>.
2. **Read release notes carefully** — 0.x means API/config may break.
3. `docker compose pull && docker compose up -d`. Migration runs on startup.
4. Backup both volumes before every minor version bump.
5. Upgrade guide per version: <https://stalw.art/docs/install/upgrade>.
6. Consider running a staging instance first for 0.x → 0.y jumps.

## Gotchas

- **Version is 0.x** — upstream is rapidly evolving; expect config/API breakage between minor versions. Pin image tags. Read upgrade notes.
- **Webmail NOT bundled.** Stalwart is protocol + server only. For webmail: Roundcube, SnappyMail, Cypht, or native IMAP/JMAP clients.
- **Console logger for Docker.** The install wizard offers File vs Console; **pick Console** — File logger inside a container writes to ephemeral storage lost on restart.
- **Default admin password shown ONCE** on the setup wizard's final screen. Write it down. Use `STALWART_RECOVERY_ADMIN` env var to pre-set it.
- **Mail hosting is hard.** Same prerequisites as mailcow: dedicated IP with clean reputation, port 25 open outbound (blocked on AWS/GCP/Azure), correct PTR, proper DNS.
- **DNS-01 ACME requires DNS provider API credentials.** When available, prefer DNS-01 — you can run Stalwart without opening port 443 publicly.
- **TLS-ALPN-01 ACME** fallback needs port 443 reachable at first boot. If using a reverse proxy, temporarily bypass during first cert issuance.
- **UID 2000** is the in-container user. For bind mounts: `chown 2000:2000 /srv/stalwart/config /srv/stalwart/data`. Named volumes handle this auto.
- **FoundationDB build is separate** (`:v0.16-fdb` tag) due to client version coupling. Don't use it unless you already run FDB.
- **Multi-tenant** support is first-class — one Stalwart instance serves many orgs with domain-scoped admins. Config via web UI.
- **Sieve scripting** is the filter language (per-user + system-wide). RFC-standard, widely supported.
- **Bayesian spam learning** is built-in; users can mark as spam/not-spam via IMAP flags, learnings stored in the DB.
- **JMAP is first-class** — use JMAP clients (FairEmail on Android, Thunderbird (partial), JMAP Proxy) for modern experience. IMAP works for everything else.
- **AGPL-3.0** — public SaaS = must offer source. Private/internal = no obligation.
- **Port 8080 management HTTP** should be **firewalled to admin IPs** post-setup OR proxied behind auth. Not meant to be publicly exposed.
- **Cluster mode** (HA + scale-out): requires external storage (Postgres + S3) and clustered directory. Documented but more complex than single-node.
- **DNSSEC-aware resolver** (Unbound equivalent) NOT bundled. Stalwart queries the system resolver.
- **No built-in anti-virus.** For ClamAV-style scanning, pipe through a separate daemon or use Sieve vnd.dovecot.execute hooks.
- **Security audit report** at <https://stalw.art/blog/security-audit> — important for compliance / risk review.
- **Alternatives worth knowing:**
  - **mailcow** — more mature, 15-container polished setup; heavier
  - **Mailu** — simpler Python UI, light setup; less featureful
  - **Mail-in-a-Box** — opinionated Ubuntu installer
  - **Postfix + Dovecot + Rspamd + Postfixadmin** (DIY) — maximum control, maximum work
  - **Docker-Mailserver** (DMS) — script-wrapped Postfix/Dovecot/Rspamd in one container

## Links

- Repo: <https://github.com/stalwartlabs/stalwart>
- Website: <https://stalw.art>
- Docs: <https://stalw.art/docs>
- Install (Docker): <https://stalw.art/docs/install/platform/docker>
- Install (Linux): <https://stalw.art/docs/install/platform/linux>
- System requirements: <https://stalw.art/docs/install/requirements>
- DNS setup: <https://stalw.art/docs/install/dns>
- Securing the server: <https://stalw.art/docs/install/security>
- Performance tuning: <https://stalw.art/docs/install/performance>
- Upgrade guide: <https://stalw.art/docs/install/upgrade>
- Docker Swarm orchestration: <https://stalw.art/docs/cluster/orchestration/docker-swarm>
- Releases: <https://github.com/stalwartlabs/stalwart/releases>
- Docker Hub: <https://hub.docker.com/r/stalwartlabs/stalwart>
- Security audit: <https://stalw.art/blog/security-audit>
- Reddit: <https://www.reddit.com/r/stalwartlabs/>
- Discord: <https://discord.gg/jtgtCNj66U>

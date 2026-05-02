# Mitra

**What it is:** A self-hosted federated micro-blogging platform built on ActivityPub. Part of the Fediverse — interoperable with Mastodon, Pleroma, and other federated services. Features quote posts, custom emojis, reactions, polls, Mastodon-compatible API, and an optional content subscription/monetization system with Monero payments.

**Official URL:** https://codeberg.org/silverpill/mitra
**Demo:** https://public.mitra.social/ (invite-only)
**Docs:** https://codeberg.org/silverpill/mitra/wiki
**License:** AGPL-3.0
**Stack:** Rust + PostgreSQL 15+

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Debian package (systemd) | Recommended; packages on releases page |
| Any Linux VPS / bare metal | Docker | Community images on Docker Hub |
| Alpine Linux | apk | Available in Alpine testing repo |
| YunoHost | YunoHost app | https://apps.yunohost.org/app/mitra |
| NixOS | nixpkgs | Available in nixpkgs unstable |

---

## Inputs to Collect

### Pre-deployment
- PostgreSQL 15+ database, user, and password
- `config.yaml` — instance config (hostname, database, storage path, limits)
- Domain with valid SSL certificate (required for ActivityPub federation)
- SMTP settings (optional, for email notifications)
- Monero wallet RPC URL (optional, for subscription payments)

### Runtime
- Admin account created via CLI after install
- Instance name, description, and registration policy (open/invite-only/closed)

---

## Software-Layer Concerns

**Debian package install:**
```bash
dpkg -i mitra_amd64.deb
```

PostgreSQL setup:
```sql
CREATE USER mitra WITH PASSWORD 'mitra';
CREATE DATABASE mitra OWNER mitra ENCODING 'UTF8';
```

Config file: `/etc/mitra/config.yaml`

Create admin:
```bash
su mitra -s $SHELL -c "mitra create-account <username> <password> admin"
```

Start service:
```bash
systemctl enable --now mitra
```

**Docker (community images):**
- `bleakfuture0/mitra` — https://hub.docker.com/r/bleakfuture0/mitra
- `fjox/mitra` — https://hub.docker.com/r/fjox/mitra

**System requirements:** Minimum 256 MB RAM (1 GB for building from source); 10 GB storage for single-user instance with defaults.

**Mastodon API:** Compatible with Mastodon clients (Phanpy, Husky, Fedilab, Tuba, toot CLI, etc.).

**Federation over Tor/I2P:** Optional; configure onion/I2P addresses in `config.yaml`.

**Upgrade procedure:** Follow semver — patch releases are bugfix-only; check release notes for minor/major migrations. For Debian: `dpkg -i mitra_<new-version>_amd64.deb`. For Docker: pull new image and restart.

---

## Gotchas

- **SSL required** — ActivityPub federation will not work without HTTPS; use Caddy or Nginx with Let's Encrypt
- **PostgreSQL 15+ only** — older versions not supported
- **Character limit is 5000** by default (configurable) — higher than Mastodon's 500
- **Content subscriptions require Monero** — the only supported payment method for the built-in monetization feature
- **Account migration** supported — identity is portable; users can move between instances
- **AGPL-3.0** — modifications must be open-sourced if deployed publicly
- No official Docker Compose provided — use community images or the Debian package

---

## Links
- Codeberg: https://codeberg.org/silverpill/mitra
- Releases: https://codeberg.org/silverpill/mitra/releases
- Instances list: https://fedidb.org/software/mitra
- Matrix chat: https://matrix.to/#/#mitra:unredacted.org

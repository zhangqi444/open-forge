---
name: WriteFreely
description: "Clean, minimalist, federated (ActivityPub) blogging platform for writers — start a blog, internal knowledge-sharing, or community. Distraction-free editor, multi-blog per account, 20+ languages + RTL. Go, SQLite or MySQL. AGPL-3.0."
---

# WriteFreely

WriteFreely is **a minimalist federated blogging platform** — built by **Musing Studio LLC** (the team behind hosted **Write.as**). Positioned as "Medium for writers who want privacy + ownership + federation." Clean auto-saving editor, minimal UI, ActivityPub-powered so your blog federates with Mastodon/Plume/other fediverse software out of the box.

Features:

- **Distraction-free editor** — auto-saving; plain Markdown
- **Multi-blog per account** — pen names, separate topics, drafts
- **ActivityPub federation** — followers on Mastodon/Plume/other AP software can follow your blog directly
- **OAuth 2.0** — for bringing users from existing platforms
- **Hashtags + static pages** (pin posts as static pages)
- **i18n**: 20+ languages, first-class **RTL** + non-Latin script support
- **Privacy-first**: minimal data collection, only publishes what writer consents to
- **Public or private** blogs; drafts; scheduled posts
- **Single binary** — Go, no runtime dependencies
- **SQLite OR MySQL**

- Upstream repo: <https://github.com/writefreely/writefreely>
- Homepage + docs: <https://writefreely.org>
- Install guide: <https://writefreely.org/start>
- Docker guide: <https://writefreely.org/docs/latest/admin/docker>
- Container: `ghcr.io/writefreely/writefreely`
- Managed: <https://write.as/writefreely>
- Documentation repo: <https://github.com/writefreely/documentation>
- Instance directory: <https://writefreely.org/instances>

## Architecture in one minute

- **Go binary** — single static binary; runs anywhere Go supports
- **SQLite** (default) or **MySQL** for multi-writer/instance
- **ActivityPub** for federation
- **Resource**: small — 50-150 MB RAM; static binary starts fast
- **No background workers needed** for base functionality

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Binary + systemd**                                               | **Upstream's flagship path** — single binary + config.ini                          |
| Docker             | `ghcr.io/writefreely/writefreely`                                         | Official image                                                                             |
| Managed hosting    | **Write.as** (paid; directly funds upstream)                                               | Simplest; supports project financially                                                                      |
| Raspberry Pi       | arm64/arm32 binaries                                                                          | Works well                                                                                                  |
| Kubernetes         | Community manifests                                                                                            | Works                                                                                                                        |
| AUR / Nanos        | Community packages                                                                                                            | Per README                                                                                                                                     |

## Inputs to collect

| Input                | Example                                           | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `blog.example.com`                                     | URL          | TLS required for federation — ActivityPub needs HTTPS                             |
| DB                   | SQLite (single-user) / MySQL (multi-user + scale)              | Storage      | SQLite fine for personal/small                                                            |
| Admin                | first-run wizard                                               | Bootstrap    | Strong password; creates first user                                                                      |
| Mode                 | `single-user` OR `multi-user`                                              | Config       | Decide up front; changing later possible but painful                                                                      |
| OAuth (opt)          | GitHub / Gitea / generic OAuth 2.0                                         | Auth         | For letting users sign in via existing platform                                                                                           |
| Federation (opt)     | Enabled                                                                   | Fediverse    | Enables followers on Mastodon/Plume                                                                                                      |

## Install via binary + config wizard

```sh
# Download binary (check releases for current version)
wget https://github.com/writefreely/writefreely/releases/download/vX.Y.Z/writefreely_vX.Y.Z_linux_amd64.tar.gz
tar xzf writefreely_*.tar.gz
cd writefreely

# Interactive config wizard
./writefreely --config

# Initialize DB + create admin
./writefreely --init-db
./writefreely --gen-keys
./writefreely --create-admin admin:CHANGE_ME

# Run
./writefreely
```

Wrap with systemd unit + reverse proxy for TLS.

## Install via Docker

```yaml
services:
  writefreely:
    image: ghcr.io/writefreely/writefreely:latest          # pin in prod
    container_name: writefreely
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
      - ./config.ini:/go/keys/config.ini
```

Follow upstream Docker guide for DB + keys + admin bootstrap.

## First boot

1. Finish config wizard (federation on/off, single vs multi-user, DB type, domain)
2. Create admin via `--create-admin`
3. Front with reverse proxy + TLS (required for federation)
4. Browse → log in as admin → create first blog
5. Customize: theme colors, logo, site title, description
6. (Optional) configure OAuth 2.0 for user signups
7. Publish a test post → verify via public URL + ActivityPub (`curl -H "Accept: application/activity+json" https://yourblog.example.com/post-url`)
8. Follow your blog from a Mastodon account → verify federation works
9. Configure email (SMTP) for password reset + account notifications

## Data & config layout

- `config.ini` — all settings
- `writefreely.db` (SQLite) OR external MySQL
- `keys/` — cryptographic keys (DO NOT lose — federation breaks without them)
- `static/` + `templates/` (if customizing)

## Backup

```sh
# SQLite deploy
sudo tar czf writefreely-$(date +%F).tgz data/ config.ini keys/
# MySQL deploy
mysqldump -u writefreely writefreely > writefreely-$(date +%F).sql
tar czf wf-config-$(date +%F).tgz config.ini keys/
```

**Don't lose `keys/`** — ActivityPub signing keys live there; losing them breaks federation with every peer server that has cached your identity.

## Upgrade

1. Releases: <https://github.com/writefreely/writefreely/releases>. Active.
2. **Back up `keys/` + DB first.**
3. Binary: download new, swap, restart.
4. Docker: bump tag → restart → migrations auto.
5. Major version bumps: read release notes for config changes.

## Gotchas

- **Federation (ActivityPub) requires HTTPS + a real public domain.** Self-signed / IP-only = federation broken. Use real TLS cert + proper DNS. Reverse proxy terminating TLS is standard.
- **Single-user vs multi-user**: decide before first deploy. Single-user = simpler config, everything under one namespace. Multi-user = Write.as-like platform where people sign up + get their own blogs. Changing later is painful.
- **Losing `keys/` = federation identity lost.** Backup them alongside DB. Without them, restoring from backup creates a new federated identity — existing followers on other servers will need to re-follow.
- **Managed vs self-hosted**: Write.as directly funds upstream development — if you don't want to run infra, hosting there supports the project. Same ethical principle as Proton/Bitwarden paid tiers.
- **Privacy defaults**: WriteFreely philosophy is "publish only what you consent to." Default modes are conservative. Review federation toggle + public-listing toggle per blog.
- **ActivityPub surface area**: federation means your posts + follower list interact with OTHER servers. Know the fediverse social model — it's not just RSS. Blocking + defederating from bad actors is your job.
- **Spam + abuse**: multi-user instances face sign-up spam. Use OAuth-gated signups or closed registration unless you want to moderate.
- **SMTP for password reset**: configure or users have no recovery path. Use SendGrid/Postmark/your own for transactional.
- **Pin static pages via post-pinning**: simple + elegant. No separate "pages" entity — just posts marked as pinned.
- **No rich media editor**: Markdown only. No WYSIWYG. That's the point; not everyone wants this.
- **No comments** (by design): focus is writing, not discussion. Fediverse replies act as comments in federation. For in-blog comments use external (Commento / Isso / Giscus).
- **Not a CMS**: for "blog + pages + complex layouts + multiple content types," use Ghost (batch 66) / WordPress / Publii.
- **Performance at scale**: single SQLite instance = small. For many-writer instance, MySQL + separate reverse proxy. WriteFreely is not Medium-scale; it's mid-scale blogging.
- **License**: **AGPL-3.0** — strong copyleft. If you modify the source + host a public instance, you must publish modifications. Fine for most deployments; incompatible with closing up the source for commercial SaaS.
- **Copyright**: "© 2018-2026 Musing Studio LLC and contributing authors" — active commercial entity + community-backed project.
- **Alternatives worth knowing:**
  - **Ghost** (batch 66) — more feature-rich; membership/newsletter focus
  - **WordPress** — feature-giant; federation via ActivityPub plugin
  - **Plume** — similar federated blogging (Rust; less active)
  - **Mastodon** — federation yes, but for microblogs
  - **Hugo/Jekyll + Git** — static sites; no federation
  - **Bear Blog / HTMLy** — minimal blogging; no fediverse
  - **Medium / Substack** — commercial, closed
  - **Choose WriteFreely if:** you want minimalist federated blogging + Go binary simplicity + privacy-first + AGPL.
  - **Choose Ghost if:** you need newsletters/membership/rich editor + SEO focus.
  - **Choose WordPress if:** you need the plugin ecosystem.

## Links

- Repo: <https://github.com/writefreely/writefreely>
- Docs: <https://writefreely.org>
- Install guide: <https://writefreely.org/start>
- Docker guide: <https://writefreely.org/docs/latest/admin/docker>
- Instance directory: <https://writefreely.org/instances>
- Write.as (managed): <https://write.as/writefreely>
- Releases: <https://github.com/writefreely/writefreely/releases>
- Container: <https://ghcr.io/writefreely/writefreely>
- Musing Studio: <https://musing.studio>
- Documentation repo: <https://github.com/writefreely/documentation>
- Plume (alt): <https://joinplu.me>
- Ghost (batch 66, alt): <https://ghost.org>

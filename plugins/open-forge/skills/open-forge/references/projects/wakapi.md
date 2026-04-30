---
name: Wakapi
description: "Self-hosted WakaTime-compatible backend for coding-time statistics. Captures heartbeats from WakaTime plugins in your IDE/editor, stores locally, serves stats + badges. Go + SQLite/MySQL/Postgres. GPL-3.0."
---

# Wakapi

Wakapi is **"self-hosted WakaTime"** — a drop-in replacement for the commercial WakaTime coding-stats service. The same WakaTime plugins you install in VS Code / JetBrains / Vim / Emacs / Sublime / Atom / Xcode / 80+ editors are configured to point at YOUR Wakapi instance instead of wakatime.com. Your typing heartbeats (project + language + editor + OS + file) are sent to Wakapi, stored in your choice of DB, and displayed as **rich coding statistics: hours-per-project, top languages, editor/OS distribution, per-day/week/month totals, embeddable badges, weekly email reports, Prometheus metrics**.

Why self-host coding stats: (a) privacy — WakaTime's commercial tier requires sending every file you type to their servers (b) cost — free WakaTime is limited; self-host = unlimited (c) data-ownership — your coding history belongs to you.

Built + maintained by **muety (Ferdinand Mütsch)**, Germany-based. Lightning-fast Go implementation. **Currently NOT accepting PRs** due to maintainer time constraints — per upstream banner. Code-maintenance mode; still active releases + bug fixes.

Features:

- **WakaTime plugin compatibility** — all official WakaTime IDE plugins work
- **Stats**: projects, languages, editors, hosts, operating systems
- **Badges** — embeddable SVG badges for READMEs
- **Weekly email reports**
- **REST API**
- **WakaTime integration** — mirror your data to+from wakatime.com
- **Prometheus metrics** export
- **Lightning fast** — Go + efficient DB queries

- Upstream repo: <https://github.com/muety/wakapi>
- Homepage + hosted cloud: <https://wakapi.dev>
- Docker image: <https://ghcr.io/muety/wakapi>
- Helm chart: <https://github.com/ricristian/wakapi-helm-chart>
- Contact: <https://github.com/muety>
- Donate: <https://liberapay.com/muety/>
- Default config: <https://github.com/muety/wakapi/blob/master/config.default.yml>

## Architecture in one minute

- **Go** single binary
- **DB**: SQLite (default), MySQL, or PostgreSQL
- **Resource**: tiny — 30-100MB RAM; sub-100MB disk for years of heartbeats
- **Config**: YAML (`config.yml`) + env var overrides (`WAKAPI_*`)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | `ghcr.io/muety/wakapi` + volume                            | **Upstream-primary**                                                               |
| Docker Compose     | `compose.yml` included in repo                                            | Bundled examples                                                                           |
| Cloud (hosted)     | <https://wakapi.dev> — free hosted instance                                         | If you don't want to self-host                                                                        |
| Bare-metal         | `go install` + systemd                                                                            | Go-native                                                                                              |
| Helm               | wakapi-helm-chart community                                                                                     | K8s deploy                                                                                                           |

## Inputs to collect

| Input                        | Example                                                   | Phase        | Notes                                                                    |
| ---------------------------- | --------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                       | `wakapi.example.com`                                            | URL          | TLS required for WakaTime plugin (most plugins reject HTTP)                                                                  |
| `WAKAPI_PASSWORD_SALT`       | random 32+ chars                                                     | Secret       | **Immutable — rotating invalidates all password hashes**                                                                                 |
| DB backend                   | SQLite (default) / MySQL / Postgres                                        | DB           | SQLite fine for solo; Postgres for multi-user teams                                                                              |
| SMTP (opt)                   | for weekly email reports                                                         | Email        | Optional                                                                                                                  |
| `WAKAPI_MAIL_SMTP_PASS`      | SMTP password                                                                            | Secret       | Docker Secrets supported                                                                                                                  |
| `WAKAPI_DB_PASSWORD`         | DB password if MySQL/Postgres                                                                          | Secret       | Docker Secrets supported                                                                                                                  |
| IDE configuration            | `~/.wakatime.cfg` points at Wakapi                                                                                    | Client       | Per editor, install WakaTime plugin, then override `api_url`                                                                                                              |

## Install via Docker

```yaml
services:
  wakapi:
    image: ghcr.io/muety/wakapi:2                    # pin major version
    restart: unless-stopped
    ports: ["3000:3000"]
    volumes:
      - ./wakapi-data:/data
    environment:
      WAKAPI_PASSWORD_SALT: ${SALT}
      WAKAPI_PUBLIC_URL: https://wakapi.example.com
      WAKAPI_DB_TYPE: sqlite3
      WAKAPI_DB_NAME: /data/wakapi.db
      # For weekly reports:
      # WAKAPI_MAIL_ENABLED: "true"
      # WAKAPI_MAIL_SMTP_HOST: smtp.example.com
      # ...
```

Client config (`~/.wakatime.cfg`):
```
[settings]
api_url = https://wakapi.example.com/api/heartbeat
api_key = <your-wakapi-api-key>
```

## First boot

1. Deploy with strong `WAKAPI_PASSWORD_SALT`
2. Create admin account via web UI
3. Copy API key from profile page
4. Configure IDE: install **official WakaTime plugin** → set `api_url` + `api_key` in `~/.wakatime.cfg`
5. Start coding → verify heartbeats appear in Wakapi dashboard (~30s delay)
6. Put behind TLS
7. (opt) Enable WakaTime relay to mirror data to cloud wakatime.com
8. (opt) Enable email reports
9. Add badges to your READMEs
10. Back up `/data` (especially the DB)

## Data & config layout

- `/data/wakapi.db` — SQLite DB with heartbeats
- `/data/` — may contain avatar/images
- Config via YAML file or env vars

## Backup

```sh
# Online backup of SQLite:
sqlite3 /data/wakapi.db ".backup /backup/wakapi-$(date +%F).db"

# Or MySQL/Postgres:
mysqldump -u user -p wakapi > wakapi-$(date +%F).sql
pg_dump -Fc -U user wakapi > wakapi-$(date +%F).dump
```

## Upgrade

1. Releases: <https://github.com/muety/wakapi/releases>. Active.
2. Docker: bump tag; migrations run automatically.
3. Config format has been stable; read changelog for env var additions.
4. **Back up DB before major version upgrades.**

## Gotchas

- **PR submissions currently closed.** Upstream banner: "we temporarily do not accept pull requests". The project is in **code-maintenance mode** — still receives releases, bug fixes, dependency updates, but feature development is slower. Bus-factor concern mitigated by (a) stable feature set (b) clear upstream communication (c) permissive GPL license = forkable if needed. Reasonable to rely on for personal use; plan fallback if you need rapid feature velocity.
- **WakaTime plugin is the data source** — Wakapi doesn't replace it. You still install the **official WakaTime extension** in every editor; you just point its API URL at your Wakapi. Plugins: VS Code, JetBrains IDEs, Vim/Neovim, Emacs, Sublime, Atom, Xcode, Android Studio, Visual Studio, 80+ total.
- **API key is per-user** — each developer using your Wakapi instance generates their own key. For team deployments, each dev registers a user + gets a key.
- **Heartbeat data is typing-level privacy.** Every file you edit is sent to Wakapi — filename, language, project, timestamp. That's a record of what you worked on and when. Self-hosting = you keep that record. Still: back up ENCRYPTED + consider who else has DB access.
- **WakaTime Cloud relay** — Wakapi can forward heartbeats to wakatime.com so you keep using their leaderboards + public profiles while also storing locally. Optional.
- **Salt immutability**: `WAKAPI_PASSWORD_SALT` participates in password hashing. Rotating it = all existing user passwords become invalid. Set ONCE + never rotate (same pattern as session secrets across many tools: Immich, Homepage, Kanidm, etc. → immutability-of-secrets family from batches 77-79).
- **Docker Secrets** supported for `WAKAPI_PASSWORD_SALT`, `WAKAPI_DB_PASSWORD`, `WAKAPI_MAIL_SMTP_PASS` — use for production.
- **Local volume + user permissions**: if you persist data in a local directory (not a named volume), set the correct `user:` in compose to avoid permission issues. Upstream calls this out.
- **SQLite for solo; Postgres/MySQL for teams**: SQLite is production-grade for a single developer's data volume. For team installations with many concurrent writers, use Postgres.
- **Heartbeat-history grows indefinitely.** A decade of daily coding = millions of heartbeats. SQLite handles this fine but DB files grow to 100+ MB over years. Budget for it.
- **Badges + embedding**: `https://wakapi.example.com/api/badge/<user>/<interval>/<label>` produces an SVG badge — great for open-source READMEs to show time invested. Caveat: embedding your badge in a public README exposes the badge URL → anyone can see your stats (not heartbeat data, just aggregate). Don't embed badges for work-confidential projects.
- **Prometheus metrics** exposed on `/api/metrics`; basic-auth-optional; feed into Grafana for long-term visualization beyond Wakapi's built-in UI.
- **"Quick-run release" one-liner** downloads binary + runs — useful for "try it locally on my laptop" but skip for production (always Docker + pinned version).
- **GPL-3.0 license** — standard copyleft. Self-host + modify is fine; redistributing modified Wakapi requires source disclosure.
- **Alternatives worth knowing:**
  - **WakaTime** (cloud, commercial) — the incumbent
  - **Code::Stats** — similar stats-collection; open source + hosted
  - **ActivityWatch** — broader "where did my time go" tool (not just coding)
  - **RescueTime** — commercial productivity tracker
  - **Hakatime** — similar WakaTime-compatible backend; Haskell; less active
  - **Choose Wakapi if:** want WakaTime-compat + Go stack + great hosted option too.
  - **Choose ActivityWatch if:** want beyond-just-coding time tracking.
  - **Choose Code::Stats if:** prefer simpler / more social aspect.

## Links

- Repo: <https://github.com/muety/wakapi>
- Releases: <https://github.com/muety/wakapi/releases>
- Docker image: <https://ghcr.io/muety/wakapi>
- Hosted cloud: <https://wakapi.dev>
- Default config: <https://github.com/muety/wakapi/blob/master/config.default.yml>
- Dockerfile: <https://github.com/muety/wakapi/blob/master/Dockerfile>
- Helm chart: <https://github.com/ricristian/wakapi-helm-chart>
- Donate (Liberapay): <https://liberapay.com/muety/>
- WakaTime: <https://wakatime.com>
- ActivityWatch (alt): <https://activitywatch.net>
- Code::Stats (alt): <https://codestats.net>
- Hakatime (alt): <https://github.com/mujx/hakatime>

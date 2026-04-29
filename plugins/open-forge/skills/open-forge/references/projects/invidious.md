---
name: Invidious
description: Alternative, privacy-respecting front-end for YouTube. No JS required, no ads, no tracking. Crystal + PostgreSQL. Pairs with invidious-companion for video retrieval.
---

# Invidious

Invidious is a self-hostable YouTube front-end. It proxies requests to YouTube, extracts video metadata + streams, and serves them through a privacy-friendly UI with no ads, no cookies, no JS requirement, RSS feeds, and a full JSON API. Modern deployments pair Invidious with **invidious-companion** — a separate service that handles the heavy lifting of extracting video URLs from YouTube (which changes adversarially), reducing the churn rate on the main Invidious image.

- Upstream repo: <https://github.com/iv-org/invidious>
- Companion: <https://github.com/iv-org/invidious-companion>
- Documentation repo: <https://github.com/iv-org/documentation>
- Installation guide: <https://docs.invidious.io/installation/>
- **Image is on Quay (not Docker Hub)**, per upstream stance: `quay.io/invidious/invidious` + `quay.io/invidious/invidious-companion`

## Compatible install methods

| Infra              | Runtime                                    | Notes                                                                   |
| ------------------ | ------------------------------------------ | ----------------------------------------------------------------------- |
| Single VM          | Docker + Compose (pre-built Quay image)    | **Recommended** — production install path per upstream docs             |
| Single VM          | Docker + Compose (build from source)       | Dev only; the in-repo `docker-compose.yml` has a `# Warning` banner      |
| Bare metal         | Crystal build + systemd                    | Fully supported; see installation docs                                  |
| Kubernetes         | Community Helm charts                      | No official chart                                                        |

## Inputs to collect

| Input                          | Example                                 | Phase     | Notes                                                                    |
| ------------------------------ | --------------------------------------- | --------- | ------------------------------------------------------------------------ |
| `hmac_key`                     | 16+ random chars (`pwgen 16 1`)         | Runtime   | **Required**; used to sign URLs and tokens                               |
| `invidious_companion_key`      | 16+ random chars (different from HMAC)  | Runtime   | **Required** if using companion; shared between invidious + companion    |
| `domain`                       | `invidious.example.com`                 | Runtime   | Public hostname; used in canonical URLs                                  |
| `https_only`                   | `true` (behind reverse proxy) / `false` | Runtime   | Controls cookie secure flag                                              |
| DB credentials                 | `kemal` / `kemal` (upstream default)    | Runtime   | **Change in any real deploy**                                            |
| Public port                    | 3000                                    | Network   | Upstream compose binds to `127.0.0.1:3000`; put behind reverse proxy     |
| Registration toggle            | `registration_enabled`                  | Runtime   | Turn off unless you want open sign-ups                                   |
| Captcha                        | `captcha_enabled`                       | Runtime   | Reduces bot accounts                                                     |

## Install via Docker Compose (production)

Per <https://docs.invidious.io/installation/> section "Docker-compose method (production)". The install still requires cloning the repo because the Postgres init scripts live in it:

```sh
git clone https://github.com/iv-org/invidious.git
cd invidious

# Generate two unrelated secrets:
HMAC_KEY=$(pwgen 16 1)
COMPANION_KEY=$(pwgen 16 1)

cat > docker-compose.yml <<EOF
services:
  invidious:
    image: quay.io/invidious/invidious:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      INVIDIOUS_CONFIG: |
        db:
          dbname: invidious
          user: kemal
          password: STRONG_CHANGE_ME
          host: invidious-db
          port: 5432
        check_tables: true
        invidious_companion:
          - private_url: "http://companion:8282/companion"
        invidious_companion_key: "${COMPANION_KEY}"
        hmac_key: "${HMAC_KEY}"
        domain: "invidious.example.com"
        https_only: true
    healthcheck:
      test: wget -nv --tries=1 --spider http://127.0.0.1:3000/api/v1/stats || exit 1
      interval: 30s
      timeout: 5s
      retries: 2
    depends_on:
      - invidious-db

  companion:
    image: quay.io/invidious/invidious-companion:latest
    restart: unless-stopped
    environment:
      - SERVER_SECRET_KEY=${COMPANION_KEY}
    cap_drop: [ALL]
    read_only: true
    volumes:
      - companioncache:/var/tmp/youtubei.js:rw
    security_opt:
      - no-new-privileges:true

  invidious-db:
    image: docker.io/library/postgres:14
    restart: unless-stopped
    volumes:
      - postgresdata:/var/lib/postgresql/data
      - ./config/sql:/config/sql
      - ./docker/init-invidious-db.sh:/docker-entrypoint-initdb.d/init-invidious-db.sh
    environment:
      POSTGRES_DB: invidious
      POSTGRES_USER: kemal
      POSTGRES_PASSWORD: STRONG_CHANGE_ME
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U kemal -d invidious"]
EOF

docker compose up -d
```

Then put a reverse proxy (Caddy / Traefik / nginx) in front terminating TLS and proxying to `127.0.0.1:3000`.

**For ARM64 hosts** (Raspberry Pi 4+, AWS Graviton): use `quay.io/invidious/invidious:latest-arm64`.

## Configuration reference

The `INVIDIOUS_CONFIG` env var is a YAML document injected into `/etc/invidious/config.yml` at startup. Full option reference (hundreds of keys — channel crawl, logging, popular feeds, captcha keys, etc.): <https://github.com/iv-org/invidious/blob/master/config/config.example.yml>.

Key options worth setting:

- `registration_enabled: false` — prevent public signup on a private instance
- `login_enabled: true` — allow subscription/history features for existing accounts
- `captcha_enabled: true` — block bot signups (ImageMagick captcha)
- `popular_enabled: true` — populate Home page
- `statistics_enabled: false` — hide the public `/api/v1/stats` endpoint
- `channel_threads` / `feed_threads` — concurrency of background refreshers
- `external_port: 443` — if reverse proxy terminates TLS on 443
- `use_innertube_for_captions` / `use_pubsub_feeds` — workarounds for YouTube changes

## Data & config layout

- Volume `postgresdata` → `/var/lib/postgresql/data` — user accounts, subscriptions, playlists, watch history
- Volume `companioncache` → `/var/tmp/youtubei.js` — companion's YouTube-internal API cache
- `./config/sql` + `./docker/init-invidious-db.sh` (bind-mounted into Postgres) — DB init; needed on first boot

No other persistent state. Video data is not cached server-side — every play proxies through YouTube.

## Backup

```sh
docker compose exec -T invidious-db pg_dump -U kemal invidious | gzip > invidious-$(date +%F).sql.gz
```

The companion cache is disposable; Postgres holds everything user-visible.

## Upgrade

1. Read release notes: <https://github.com/iv-org/invidious/releases>. Because YouTube changes adversarially, Invidious + companion release cadence is **fast** — expect weekly-to-monthly breakage/fix cycles.
2. `cd invidious && git pull` to refresh the SQL init scripts (rarely changes, but required for fresh DBs).
3. `docker compose pull && docker compose up -d`.
4. The schema migrates automatically with `check_tables: true`.
5. Keep invidious + invidious-companion image versions in lockstep — mismatched pairs fail to extract video URLs.

## Gotchas

- **Hosted by YouTube's tolerance.** YouTube actively breaks third-party extractors. Expect outages; plan for frequent updates. Without recent updates, video playback silently fails on most videos.
- **Pin with caution.** `:latest` keeps you patched against YouTube changes — the usual "pin a specific version" advice is weaker here. Upstream explicitly ships a rolling tag for this reason. If you pin, monitor releases and bump weekly.
- **IP bans from YouTube.** Popular instances are rate-limited / IP-banned by Google; running on residential or small-VPS IP ranges is fine; large commercial VPS ranges get flagged faster. There's no universal workaround — see companion's proxy-chain options.
- **Default DB password is `kemal`.** Upstream compose ships it; change before first boot. Postgres locks the password in at volume-init time.
- **Registration is on by default.** A public instance will accrue spam accounts fast. Disable unless you want open sign-ups.
- **`https_only` must match reality.** If you set it `true` but the proxy strips HTTPS, cookies break. If you set it `false` while serving over HTTPS, session cookies leak to HTTP contexts.
- **Image is on Quay, not Docker Hub.** Upstream does this deliberately (Quay is fully FOSS; Docker Hub is not). Mirrors on Docker Hub are community-maintained and may lag.
- **Clone the repo even for Docker installs.** The Postgres `init-invidious-db.sh` + `config/sql` directory must be bind-mounted; there's currently no self-contained image that includes them.
- **Companion is not optional** in modern deployments (2024+). Older tutorials that run just `invidious` + `postgres` are outdated; without companion, video extraction fails on most content.
- **Legal posture varies by jurisdiction.** Self-hosting for personal use is generally fine; running a public instance may attract DMCA notices. Upstream disclaims responsibility; iv-org's official hosted instances were taken down in 2024 after a Google cease-and-desist.
- **AGPL v3.** Public-facing modified deployments must offer source.
- **SponsorBlock integration** is off by default — enable with `enable_user_notifications` + related keys, see config reference.
- **Don't forget a reverse proxy.** Binding `127.0.0.1:3000` is deliberate; exposing port 3000 publicly bypasses the intended TLS-terminating layer.

## Links

- Installation (authoritative): <https://docs.invidious.io/installation/>
- Configuration reference: <https://github.com/iv-org/invidious/blob/master/config/config.example.yml>
- Companion: <https://github.com/iv-org/invidious-companion>
- API docs: <https://docs.invidious.io/api/>
- Releases: <https://github.com/iv-org/invidious/releases>
- Quay images: <https://quay.io/repository/invidious/invidious>
- Status of public instances: <https://instances.invidious.io/>

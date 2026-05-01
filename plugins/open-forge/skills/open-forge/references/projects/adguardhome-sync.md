---
name: AdGuardHome Sync
description: "Sync AdGuardHome config from an origin instance to one or more replicas. Go binary + Docker. bakito/adguardhome-sync. Cron-based. Syncs filters, rewrites, clients, DNS/DHCP config."
---

# AdGuardHome Sync

**Synchronize AdGuardHome config from an origin instance to one or more replicas.** Keeps multiple AdGuardHome nodes in sync — filters, DNS rewrites, client lists, services, DNS config, DHCP config, theme. Runs on a cron schedule or on-demand. Written in Go; distributed as a single binary or Docker image.

Built + maintained by **bakito**. Go binary, GHCR Docker image, Brew cask.

- Upstream repo: <https://github.com/bakito/adguardhome-sync>
- Releases: <https://github.com/bakito/adguardhome-sync/releases>
- Docker image: `ghcr.io/bakito/adguardhome-sync`
- FAQ + deprecations: <https://github.com/bakito/adguardhome-sync/wiki>

## Architecture in one minute

- **Go binary** (`adguardhome-sync`) — single process, no DB
- Config via **YAML file** or **environment variables**
- Communicates with AdGuardHome instances via their **HTTP API**
- Optional **web dashboard / API** on port `8080` (can be disabled by setting `API_PORT=0`)
- Sync triggered by **cron** (`CRON=`) and/or `RUN_ON_START=true`
- Resource: **tiny** (Go binary, minimal RAM)

## Compatible install methods

| Infra              | Runtime                                         | Notes                                   |
| ------------------ | ----------------------------------------------- | --------------------------------------- |
| **Docker**         | `ghcr.io/bakito/adguardhome-sync`               | **Primary**                             |
| **Go binary**      | `go install github.com/bakito/adguardhome-sync` | Any Linux/macOS/Windows host with Go    |
| **Brew**           | `brew install --cask adguardhome-sync`          | macOS                                   |
| **systemd service**| Binary + `.service` unit                        | Bare-metal Linux                        |

## Inputs to collect

| Input               | Example                               | Phase   | Notes                                                                         |
| ------------------- | ------------------------------------- | ------- | ----------------------------------------------------------------------------- |
| Origin URL          | `http://192.168.1.1:3000`             | Config  | AdGuardHome admin interface URL                                                |
| Origin username/pw  | `admin` / `password`                  | Config  | AdGuardHome login credentials                                                 |
| Replica URL(s)      | `http://192.168.1.2:3000`             | Config  | One or more; numbered `REPLICA1_`, `REPLICA2_`, etc.                          |
| Replica credentials | per-replica user/pw                   | Config  | Each replica can have different credentials                                   |
| Cron expression     | `*/30 * * * *` (every 30 min)         | Config  | Standard cron; sync frequency                                                 |
| Run on start        | `true` / `false`                      | Config  | Do a sync immediately on startup                                              |
| Features to sync    | all enabled by default                | Config  | Each sync category can be individually disabled                               |

## Install via Docker CLI

```sh
docker run -d \
  --name=adguardhome-sync \
  -p 8080:8080 \
  -v /opt/adguardhome-sync/adguardhome-sync.yaml:/config/adguardhome-sync.yaml \
  --restart unless-stopped \
  ghcr.io/bakito/adguardhome-sync:latest
```

## Install via Docker Compose (config file)

```yaml
services:
  adguardhome-sync:
    image: ghcr.io/bakito/adguardhome-sync
    container_name: adguardhome-sync
    command: run --config /config/adguardhome-sync.yaml
    volumes:
      - /opt/adguardhome-sync/adguardhome-sync.yaml:/config/adguardhome-sync.yaml
    ports:
      - 8080:8080
    restart: unless-stopped
```

## Install via Docker Compose (environment variables)

No config file needed — use env vars directly:

```yaml
services:
  adguardhome-sync:
    image: ghcr.io/bakito/adguardhome-sync
    container_name: adguardhome-sync
    environment:
      - ORIGIN_URL=http://192.168.1.1:3000
      - ORIGIN_USERNAME=admin
      - ORIGIN_PASSWORD=secret
      - REPLICA1_URL=http://192.168.1.2:3000
      - REPLICA1_USERNAME=admin
      - REPLICA1_PASSWORD=secret
      - CRON=*/30 * * * *
      - RUN_ON_START=true
    ports:
      - 8080:8080
    restart: unless-stopped
```

For multiple replicas: add `REPLICA2_URL`, `REPLICA2_USERNAME`, `REPLICA2_PASSWORD`, etc.

## Config file format (YAML)

```yaml
cron: "*/30 * * * *"
runOnStart: true

origin:
  url: http://192.168.1.1:3000
  username: admin
  password: secret

replica1:
  url: http://192.168.1.2:3000
  username: admin
  password: secret

# Optional: per-feature enable/disable
# features:
#   generalSettings: true
#   queryLogConfig: true
#   statsConfig: true
#   filters: true
#   dhcp: false
```

## Install via systemd (bare-metal)

```sh
# Download from releases
wget https://github.com/bakito/adguardhome-sync/releases/latest/download/adguardhome-sync_linux_amd64.tar.gz
tar -xzf adguardhome-sync_linux_amd64.tar.gz -C /usr/local/bin/ adguardhome-sync

# Create config dir
mkdir -p /opt/adguardhome-sync
# Write config file: /opt/adguardhome-sync/adguardhome-sync.yaml

# Install + enable service (upstream provides adguardhome-sync.service)
cp adguardhome-sync.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now adguardhome-sync
```

## First boot

1. Deploy (Docker or binary).
2. Both **origin** and all **replicas** must already be set up via AdGuardHome's own installation wizard before running sync.
3. Set `autoSetup: true` on replicas only if you want adguardhome-sync to run AdGuardHome's wizard automatically (new blank instance).
4. Start sync → check logs for success: `docker compose logs adguardhome-sync`.
5. Verify replica matches origin in AdGuardHome web UI.
6. Optionally visit `http://<host>:8080` for the sync dashboard / API (disable with `API_PORT=0` if not needed).

## Backup

No persistent data beyond the config file — back up `adguardhome-sync.yaml`.
AdGuardHome itself is the data store; back up each AdGuardHome instance's data independently.

## Upgrade

1. Releases: <https://github.com/bakito/adguardhome-sync/releases>
2. Docker: `docker pull ghcr.io/bakito/adguardhome-sync:latest && docker compose up -d`
3. Check deprecations wiki before upgrading major versions.

## Gotchas

- **Both instances must be fully initialized first.** adguardhome-sync expects an already-configured AdGuardHome (with admin username + password). A fresh AdGuardHome that hasn't been through its setup wizard will fail — or use `autoSetup: true` to let adguardhome-sync run the wizard for you.
- **Replica credentials are independent from origin's.** Each replica can have a different admin password; configure them separately.
- **`REPLICA#_` numbering starts at 1**, no zero. `REPLICA1_URL`, `REPLICA2_URL`, etc. An `REPLICA0_URL` or `REPLICA_URL` (no number) will be ignored.
- **Unused replica env vars cause sync errors on Unraid.** The upstream README specifically notes: if you have `REPLICA2_` vars defined but no second replica, remove them to avoid spurious errors.
- **Home Assistant AdGuard Home add-on users** need to manually enable the disabled ports in the add-on's Network section before adguardhome-sync can connect.
- **API port 8080 is shared with AdGuardHome's default port.** If running on the same host as AdGuardHome, remap one of them: `-p 8888:8080` for the sync dashboard, and run AdGuardHome on its own port.
- **DHCP sync disabled by default in some versions** — check `features.dhcp` in your config. DHCP sync requires both instances to have DHCP on the same subnet, which isn't common in multi-site setups.
- **TLS:** if your AdGuardHome instances use self-signed certs, set `ORIGIN_INSECURE_SKIP_VERIFY=true` / `REPLICA1_INSECURE_SKIP_VERIFY=true`. Not recommended for public networks.
- **One-way sync only.** Origin → replicas. Changes on a replica are overwritten on next sync. Don't manage replicas directly.

## Project health

Active development, Go CI, e2e tests, Brew cask, GHCR image, wiki with FAQ + deprecation docs. Solo-maintained by bakito.

## AdGuardHome-sync alternatives

- **AdGuardHome built-in sync** — as of AdGuardHome v0.107+ there's a basic sync feature built in; may reduce the need for a separate tool for simple cases
- **adguardhome-sync** — this tool; handles multi-replica, cron, full config categories
- **Manual** — export/import via AdGuardHome API; one-time, not automated

**Choose adguardhome-sync if:** you run multiple AdGuardHome nodes (home + VPS, Pi-hole-replacement HA pair, site-to-site) and want automated config propagation.

## Links

- Repo: <https://github.com/bakito/adguardhome-sync>
- GHCR image: <https://github.com/bakito/adguardhome-sync/pkgs/container/adguardhome-sync>
- FAQ: <https://github.com/bakito/adguardhome-sync/wiki/FAQ>
- AdGuardHome: <https://github.com/AdguardTeam/AdGuardHome>

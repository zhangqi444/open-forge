---
name: SafeLine (雷池 WAF)
description: Self-hosted Web Application Firewall by Chaitin. Reverse-proxy WAF with semantic-analysis detection engine, rate limiting, anti-bot challenges, HTML/JS dynamic protection.
---

# SafeLine (雷池)

SafeLine is a self-hosted, open-source Web Application Firewall that sits as a reverse proxy in front of your apps. Its distinctive feature is a **semantic-analysis detection engine** (Tengine-based nginx + a C++ detector service) rather than traditional regex-based rule matching. Six+ services work together: Postgres, management API, detector, Tengine (data plane), Luigi (reporting), FVM (feed/version manager), and Chaos (plugin runner).

- Upstream repo: <https://github.com/chaitin/SafeLine>
- Docs (EN): <https://docs.waf.chaitin.com/en>
- Docs (中文): <https://docs.waf-ce.chaitin.cn>
- Install guide: <https://docs.waf.chaitin.com/en/GetStarted/Deploy>
- Live demo: <https://demo.waf.chaitin.com:9443/>

## Architecture in one minute

- **tengine** (data plane, Tengine-based nginx) — `network_mode: host`, takes 80/443 inbound traffic; proxies to your backends
- **detect** — C++ detector; Tengine calls it over a unix socket to decide pass/block
- **mgt** — Go management API + web dashboard (default port 9443/tcp, HTTPS only)
- **postgres** — config + audit store
- **luigi** — report/statistics aggregator
- **fvm** — fetches detection-rule feed updates from Chaitin cloud
- **chaos** — plugin/extension sandbox
- **Custom bridge network** with pinned IPv4 addresses (subnet controlled by `SUBNET_PREFIX` env)

## Compatible install methods

| Infra             | Runtime                                      | Notes                                                                     |
| ----------------- | -------------------------------------------- | ------------------------------------------------------------------------- |
| Single host       | Official `setup.sh` (Docker + Compose)       | Recommended — installer lays out dirs + `compose.yaml` + `.env`           |
| Single host       | Manual Docker Compose                        | Supported; use upstream `compose.yaml` directly                            |
| Kubernetes        | Not upstream-supported                       | Tengine needs `network_mode: host`; porting is non-trivial                 |
| Debian/Ubuntu pkg | Not supported                                | Docker is the only blessed path                                            |

## Inputs to collect

| Input              | Example                                    | Phase        | Notes                                                                      |
| ------------------ | ------------------------------------------ | ------------ | -------------------------------------------------------------------------- |
| `SAFELINE_DIR`     | `/data/safeline`                           | Host         | Root for bind-mounted data; installer defaults to `/data/safeline`          |
| `POSTGRES_PASSWORD`| strong random                              | Data         | Required; used by mgt, luigi, chaos to reach Postgres                       |
| `SUBNET_PREFIX`    | `169.254.0`                                | Network      | Private /24 for the `safeline-ce` bridge; must not clash with host routes   |
| `IMAGE_TAG`        | e.g. `7.1.0`                               | Runtime      | Pin; the installer picks latest from `version.json` unless overridden       |
| `IMAGE_PREFIX`     | `chaitin/safeline` or `swr.cn-east-3.myhuaweicloud.com/chaitin-safeline` | Runtime | Choose registry — latter is used by the China edition           |
| `MGT_PORT`         | `9443`                                     | Runtime      | Dashboard HTTPS port; mgt binds 1443 inside, remaps to `MGT_PORT` on host  |
| Open ports 80, 443 | host firewall                              | Network      | Tengine runs on host network; must be free                                 |

## Install via upstream one-liner (recommended)

Upstream publishes a single-command installer (docs at <https://docs.waf.chaitin.com/en/GetStarted/Deploy>):

```sh
bash -c "$(curl -fsSLk https://waf.chaitin.com/release/latest/manager.sh)" -- --en
```

This interactively:

1. Picks install dir (default `/data/safeline`) and subnet prefix.
2. Writes `.env` (generates `POSTGRES_PASSWORD`, `IMAGE_TAG`, `IMAGE_PREFIX`).
3. `docker compose up -d` with the upstream `compose.yaml`.
4. Prints the admin login URL, username (`admin`), and a one-time password that you read from the `mgt` container logs (or via the printed `docker exec safeline-mgt resetadmin` invocation).

Post-install, first login → set admin password → add upstream applications (reverse-proxy targets) in the dashboard.

## Install via manual Docker Compose

Only if you want to build your own install orchestration:

```sh
mkdir -p /data/safeline && cd /data/safeline
curl -fsSL https://raw.githubusercontent.com/chaitin/SafeLine/main/compose.yaml -o compose.yaml

cat > .env <<'EOF'
SAFELINE_DIR=/data/safeline
POSTGRES_PASSWORD=<strong random>
SUBNET_PREFIX=169.254.0
IMAGE_PREFIX=chaitin/safeline
# omit REGION / ARCH_SUFFIX / RELEASE unless you need non-default builds
IMAGE_TAG=7.1.0      # pick from https://github.com/chaitin/SafeLine/blob/main/version.json
MGT_PORT=9443
EOF

docker compose up -d

# Reset admin password to a known value
docker exec safeline-mgt resetadmin
```

## Protecting your first site

1. Browse `https://<host>:9443` → log in as `admin`.
2. Add an **Application**: upstream IP/port (your real backend), listen ports (80/443), TLS cert (or let SafeLine manage ACME).
3. Tengine reloads automatically; point your DNS at the SafeLine host.
4. Tune detection rules and rate limits per app.

## Data & config layout

Directories under `$SAFELINE_DIR` (bind-mounted into containers):

- `resources/postgres/data` — Postgres data dir
- `resources/mgt` — management state (certs, app configs, audit DB)
- `resources/nginx` — rendered Tengine configs (auto-generated from mgt; don't hand-edit)
- `resources/detector` — detector state
- `resources/sock` — unix sockets between containers
- `resources/cache` — Tengine cache
- `resources/luigi`, `resources/chaos` — service state
- `logs/nginx`, `logs/detector` — access + detection logs

All sensitive config lives in Postgres + mgt state; Postgres password is the primary secret.

## Upgrade

1. Check <https://github.com/chaitin/SafeLine/releases> or the installer's prompt for the new `IMAGE_TAG`.
2. `cd $SAFELINE_DIR`; edit `.env` → bump `IMAGE_TAG`.
3. `docker compose pull && docker compose up -d`.
4. mgt runs migrations on boot. **Back up `resources/postgres/data` before major-version upgrades** — major jumps occasionally require manual migrations documented in release notes.
5. The installer's `manager.sh upgrade` automates the same steps and is the blessed path.

## Gotchas

- **`tengine` runs with `network_mode: host`.** SafeLine expects exclusive ownership of host ports 80/443 — you cannot run another nginx/Caddy/Traefik on the same host without port remapping on the other side.
- **`SUBNET_PREFIX` default `169.254.0` is a link-local range.** It rarely clashes but can conflict with some cloud-provider metadata routes — change to `172.22.222` or similar if things behave strangely.
- **Admin password reset path:** `docker exec safeline-mgt resetadmin` — print this in your runbook because it's the only reliable recovery if you lose credentials.
- **Detection rule feeds are cloud-fetched** by the `fvm` service. Air-gapped installations need offline feed bundles from Chaitin; without internet egress, detection rules go stale.
- **The EE "Pro" edition has feature gates.** The `compose.yaml` is CE; some commercial features (distributed clustering, advanced bot detection tiers) are not included.
- **Logs under `resources/nginx`/`logs/nginx` grow fast.** Tengine writes access logs per app; set logrotate or rely on the built-in `json-file` driver's `max-size: 100m, max-file: 5` (already set in compose).
- **Tengine is nginx-derived but not 100% identical.** Third-party nginx modules may not work; use SafeLine's plugin framework (Chaos) instead.
- **China-region installs** need `IMAGE_PREFIX=swr.cn-east-3.myhuaweicloud.com/chaitin-safeline` and `REGION=-g` to pull from the Huawei mirror, per the README's warning about ghcr.io unreachability.
- **Do not edit `resources/nginx/*` by hand** — it's regenerated from mgt's Postgres on every app change.

## Links

- Repo: <https://github.com/chaitin/SafeLine>
- Compose: <https://github.com/chaitin/SafeLine/blob/main/compose.yaml>
- Version manifest: <https://github.com/chaitin/SafeLine/blob/main/version.json>
- Install docs (EN): <https://docs.waf.chaitin.com/en/GetStarted/Deploy>
- Config + app docs (EN): <https://docs.waf.chaitin.com/en/GetStarted/AddApplication>
- Releases: <https://github.com/chaitin/SafeLine/releases>

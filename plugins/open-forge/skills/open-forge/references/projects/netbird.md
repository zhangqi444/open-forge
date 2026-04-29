---
name: NetBird
description: WireGuard-based peer-to-peer overlay network with a centralized management plane, SSO/IdP integration, and granular access policies.
---

# NetBird

NetBird builds a WireGuard-based mesh between your devices. Peers exchange keys and NAT-traversal hints via a central **Signal** service, optionally fall back to a **TURN/Relay** server for restrictive NATs, and are enrolled & access-controlled by a **Management** API that delegates authentication to an external OIDC identity provider (NetBird Cloud uses Auth0; self-hosters typically bundle **Zitadel** via the official installer).

- Upstream repo: <https://github.com/netbirdio/netbird>
- Self-hosting guide (authoritative): <https://docs.netbird.io/selfhosted/selfhosted-guide>
- Quickstart with Zitadel: <https://docs.netbird.io/selfhosted/selfhosted-quickstart>
- Images: `netbirdio/dashboard`, `netbirdio/signal`, `netbirdio/management`, `netbirdio/relay` (Docker Hub)

## Architecture in one minute

You will run **at least 5–6 containers** on one VM:

1. `dashboard` (React UI, 80/443)
2. `signal` (peer coordination, gRPC)
3. `management` (API, ACLs, peer registry; gRPC + REST)
4. `relay` (NetBird's own relay, replaces much of coturn usage)
5. `coturn` (STUN/TURN fallback, UDP)
6. `zitadel` + `zdb` (CockroachDB or Postgres) — only if you let the installer set up its own IdP

All peers connect **outbound** to Signal + Management via gRPC/HTTPS; the data plane is direct peer-to-peer WireGuard UDP, with coturn/relay only for symmetric-NAT fallback.

## Compatible install methods

| Infra                | Runtime                 | Notes                                                                   |
| -------------------- | ----------------------- | ----------------------------------------------------------------------- |
| Single VM (1 vCPU+)  | Docker + Compose        | Recommended — use upstream `getting-started-with-zitadel.sh` installer  |
| Managed K8s          | Helm                    | Community chart (`netbirdio/helm-charts`); advanced                     |
| Bare metal           | Systemd units           | Possible but unsupported; compose is the blessed path                   |

## Inputs to collect (self-hosted with Zitadel)

| Input                         | Example                                        | Phase     | Notes                                                                                  |
| ----------------------------- | ---------------------------------------------- | --------- | -------------------------------------------------------------------------------------- |
| Public FQDN                   | `netbird.example.com`                          | DNS       | Single hostname for dashboard, management, signal, zitadel                              |
| Let's Encrypt email           | `admin@example.com`                            | TLS       | Installer provisions certs automatically                                                |
| TURN domain (optional)        | same as FQDN                                   | Coturn    | Upstream defaults coturn to same host                                                   |
| TURN secret                   | random 32+ bytes                               | Coturn    | Shared-secret TURN auth; installer generates                                            |
| Zitadel admin email / pass    | set via installer prompts                      | IdP       | First login to Zitadel UI                                                               |
| Open TCP 80, 443; UDP 3478, 49152-65535 | firewall                             | Network   | HTTP/S for UI + API; STUN/TURN UDP; WireGuard peer UDP (varies)                         |
| Docker & Docker Compose v2    | `docker --version`                             | Host      | Compose v2 required                                                                     |
| `jq` + `curl`                 | `apt install jq curl`                          | Host      | Installer script depends on them                                                        |

## Install via the official installer (recommended)

Upstream strongly prefers their installer over manual compose — it generates `docker-compose.yml` from `docker-compose.yml.tmpl`, a `.env`, and Zitadel client registrations in one shot.

```sh
mkdir -p netbird && cd netbird
curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started-with-zitadel.sh -o setup.sh
chmod +x setup.sh
export NETBIRD_DOMAIN=netbird.example.com
./setup.sh
```

The script will:

1. Check for Docker Compose + jq.
2. Ask for `NETBIRD_DOMAIN`, admin email, TURN secret, and DB engine (CockroachDB vs. Postgres for Zitadel).
3. Boot Zitadel, wait for it to be healthy, create the admin account, create OIDC clients for the dashboard + management, and write them back into NetBird's `.env`.
4. `docker compose up -d` the full stack.

First login lands in Zitadel, where you create users / org; they then sign in to the NetBird dashboard with SSO.

## Install via manual compose

Only do this if you already have an OIDC IdP (Keycloak, Authentik, Okta, Auth0). Template: <https://github.com/netbirdio/netbird/blob/main/infrastructure_files/docker-compose.yml.tmpl>. Key env vars are documented at <https://docs.netbird.io/selfhosted/identity-providers> — you must fill in `NETBIRD_MGMT_IDP`, `NETBIRD_AUTH_*`, OIDC issuer URL, client ID/secret for both device-auth and management API.

Image refs appear as `$NETBIRD_DASHBOARD_TAG`, `$NETBIRD_MANAGEMENT_TAG`, etc. in the template — pin them (e.g. `0.57.1`) rather than leaving unset. Releases: <https://github.com/netbirdio/netbird/releases>.

## Data & config layout

- `./management.json` — management's ACL, IdP, and peer settings (mounted into `/etc/netbird`)
- `./signal.json` — signal service config
- `./turnserver.conf` — coturn config
- `./zitadel.env` + Zitadel DB volume (`zdbdata`, or `zdbpg` for Postgres)
- Docker volumes: `netbird_management`, `netbird_signal`, `netbird_letsencrypt` (cert cache)

## Upgrade

1. `cd netbird && git pull` (or re-download installer) to refresh the template.
2. Edit `.env` to bump `NETBIRD_*_TAG` per <https://docs.netbird.io/selfhosted/selfhosted-guide#upgrade>.
3. `docker compose pull && docker compose up -d`.
4. Management applies DB migrations automatically; read release notes for breaking changes at <https://github.com/netbirdio/netbird/releases>.

## Gotchas

- **The installer overwrites `docker-compose.yml`**. Hand-edits get lost; customize via `.env` or a compose override file (`docker-compose.override.yml`).
- **TLS ports 80 + 443 must be free** — the bundled Caddy/nginx inside `dashboard` terminates TLS and fetches Let's Encrypt certs. If you already run a reverse proxy on the host, either disable HTTPS in NetBird and proxy to it, or pick a different host.
- **UDP peer connectivity is the hard part.** WireGuard peers want direct UDP; symmetric NATs force relay traffic through coturn or the netbird `relay` service, which eats bandwidth. Don't under-provision the TURN server.
- **Bundled Zitadel is heavy.** CockroachDB is the installer default and runs as a single-node cluster; for low-RAM hosts pick Postgres (`ZITADEL_DATABASE=postgres`) during the install prompts.
- **Clock skew breaks JWT auth.** Keep the host NTP-synced or Management will reject perfectly valid tokens.
- **Default Signal/Management listen on 80/443 without mTLS** — treat those endpoints as public; auth is at the OIDC layer.
- **Don't expose coturn's admin port.** Only 3478/udp and the TURN relay UDP range should be reachable from clients; nothing else.
- **Peer OS clients** come from <https://github.com/netbirdio/netbird/releases> — not your server install. Version skew between client and management is tolerated for a few minor versions.

## Links

- Self-hosting guide: <https://docs.netbird.io/selfhosted/selfhosted-guide>
- Zitadel quickstart: <https://docs.netbird.io/selfhosted/selfhosted-quickstart>
- Identity provider config matrix: <https://docs.netbird.io/selfhosted/identity-providers>
- Template compose: <https://github.com/netbirdio/netbird/blob/main/infrastructure_files/docker-compose.yml.tmpl>
- Releases: <https://github.com/netbirdio/netbird/releases>
- Client downloads: <https://app.netbird.io/install> (same binaries work against self-hosted)

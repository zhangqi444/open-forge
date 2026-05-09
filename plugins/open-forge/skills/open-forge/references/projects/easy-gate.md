---
name: Easy Gate
description: Lightweight self-hosted homepage/dashboard for your infrastructure. Config-as-code (JSON or YAML), real-time file reloading, per-group visibility based on IP subnets, service categories, and notes. Single Go binary or Docker container. MIT-licensed.
---

# Easy Gate

Easy Gate is a minimal, opinionated homepage for your self-hosted stack. Define your services and notes in a single JSON or YAML file — changes take effect immediately without restarting the container. Groups let you show different items to different users based on their IP or subnet (handy for LAN vs. VPN).

What makes Easy Gate distinctive:

- **Zero-restart live reload** — config file is watched; changes appear in the browser instantly
- **IP-based group filtering** — assign services to groups by CIDR subnet; perfect for "homelab vs. VPN" visibility
- **Service categories** — organize bookmarks into labeled sections
- **Notes** — freeform text snippets alongside your service links
- **Auto favicon fetch** — if no icon is provided, Easy Gate fetches the service's favicon
- **Single binary** — also distributable as a prebuilt executable with no runtime dependencies

- Upstream repo: <https://github.com/wiredlush/easy-gate>
- Docker Hub: <https://hub.docker.com/r/wiredlush/easy-gate>
- Latest release: 2.0.3

## Architecture in one minute

- **Single Go container** — serves the dashboard on **`:8080`** by default
- Reads a JSON or YAML config file (default: `/etc/easy-gate/easy-gate.json`)
- Config path override via `EASY_GATE_CONFIG_PATH` env var
- Entire config can also be passed as a JSON/YAML string in `EASY_GATE_CONFIG`

## Compatible install methods

| Infra     | Runtime           | Notes                                      |
| --------- | ----------------- | ------------------------------------------ |
| Single VM | Docker / Compose  | **Most common**                             |
| Any Linux | Native binary     | No external dependencies, from GitHub Releases |
| Behind proxy | Compose + nginx | Example in repo `examples/` directory      |

## Inputs to collect

| Input         | Example                     | Phase  | Notes                                           |
| ------------- | --------------------------- | ------ | ----------------------------------------------- |
| Config file   | `./easy-gate.yml`           | Config | Mounted into container; hot-reloaded on change  |
| Port          | `8080`                      | Network | Default dashboard port                          |
| Groups        | subnet CIDRs per group      | Optional | Enables IP-based visibility filtering          |

## Install via Docker Compose

```yaml
# docker-compose.yml
services:
  easy-gate:
    image: wiredlush/easy-gate:latest
    container_name: easy-gate
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./easy-gate.yml:/etc/easy-gate/easy-gate.json
```

```bash
docker compose up -d
# Open http://localhost:8080
```

## Example config (YAML)

```yaml
# easy-gate.yml
title: "My Homelab"

theme:
  background: "#1d1d1d"
  foreground: "#ffffff"

groups:
  - name: internal
    subnet: 192.168.1.0/24
  - name: vpn
    subnet: 10.8.0.0/24

services:
  - name: Gitea
    url: https://git.home.example.com
    category: Dev
    groups:
      - internal
      - vpn

  - name: Grafana
    url: http://192.168.1.10:3000
    category: Monitoring
    groups:
      - internal

  - name: Public Site
    url: https://example.com
    category: Web
    groups: []   # visible to everyone

notes:
  - name: Maintenance window
    text: "Fridays 22:00-00:00 UTC — updates may cause downtime"
    groups:
      - internal
```

## Environment variables

| Variable               | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `EASY_GATE_CONFIG_PATH` | Override config file path inside the container              |
| `EASY_GATE_CONFIG`     | Pass entire config as a JSON/YAML string (takes precedence) |
| `EASY_GATE_ROOT_PATH`  | Set a custom root directory for the app                     |

## Notes

- Services with an empty `groups` list are visible to all visitors regardless of IP
- `behind_proxy: true` in the config makes Easy Gate trust the `X-Forwarded-For` header for IP detection — required when running behind nginx or Traefik
- TLS can be enabled directly in the app by setting `use_tls: true` with `cert_file` and `key_file` paths
- Full example for reverse-proxy deployment is in the [`examples/`](https://github.com/wiredlush/easy-gate/tree/master/examples) directory of the repo

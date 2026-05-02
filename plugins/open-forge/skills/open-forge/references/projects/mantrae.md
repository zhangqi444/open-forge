---
name: mantrae-project
description: Mantrae recipe for open-forge. Web-based Traefik dynamic configuration manager. Provides a clean UI to manage routers, middlewares, services, DNS, and optionally sync from labelled containers via a companion agent. Upstream: https://github.com/MizuchiLabs/mantrae
---

# Mantræ

A web-based configuration manager for Traefik's dynamic configuration. Instead of editing YAML/TOML files directly, Mantræ gives you a clean UI to manage routers, middlewares, services, and DNS — and then exposes the resulting config as an HTTP endpoint that Traefik polls.

> **Not a Traefik dashboard.** Mantræ does not monitor Traefik status. Traefik connects to Mantræ to *fetch* its dynamic config.

Upstream: <https://github.com/MizuchiLabs/mantrae> | Docs: <https://mantrae.pages.dev>

> ⚠️ **Active development / pre-stable.** Breaking changes are expected before the first stable release. Pin to a specific release tag in production.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host with Traefik | Traefik uses Mantræ as its HTTP dynamic config provider |
| Multi-node with `mantraed` agent | Agent runs on each Docker node, syncs container labels to Mantræ |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which host port should Mantræ bind to?" | Default: `3000` |
| preflight | "Traefik entrypoints for the Mantræ-served config?" | e.g. `websecure`, `web` — configured in Traefik static config |
| config | "Deploy the `mantraed` agent for auto-sync from container labels?" | Optional; agent is a separate container/service |
| config (agent) | "Mantræ server URL for the agent?" | Agent connects to Mantræ to push discovered routes |

## Software-layer concerns

### Image

```
ghcr.io/mizuchilabs/mantrae:latest
```

Pin to a release tag for production: <https://github.com/MizuchiLabs/mantrae/releases>

### Compose

```yaml
services:
  mantrae:
    image: ghcr.io/mizuchilabs/mantrae:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - mantrae-data:/data

volumes:
  mantrae-data:
```

> Source: upstream docs — <https://mantrae.pages.dev>

### Connect Traefik to Mantræ

In your `traefik.yml` static config, add Mantræ as an HTTP provider:

```yaml
providers:
  http:
    endpoint: "http://mantrae:3000/api/traefik/<provider-name>"
    pollInterval: "5s"
```

Traefik polls this endpoint every 5 s (adjustable) to fetch the dynamic config that Mantræ manages.

### Password management

```bash
# Reset admin password
mantrae reset --password newpassword

# Reset password for a specific user
mantrae reset --user username --password newpassword
```

Or exec into the container:

```bash
docker exec -it mantrae mantrae reset --password newpassword
```

### `mantraed` agent (optional — multi-node label sync)

The agent was split into a separate repository: <https://github.com/MizuchiLabs/mantraed>.
Image: `ghcr.io/mizuchilabs/mantraed`

The old `mantrae-agent` image remains available for compatibility but is deprecated. Use `mantraed` for new deployments.

```yaml
services:
  mantraed:
    image: ghcr.io/mizuchilabs/mantraed:latest
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - MANTRAE_URL=http://mantrae:3000
      - MANTRAE_TOKEN=<api-token-from-mantrae-ui>
```

The agent reads standard `traefik.*` labels from containers on its Docker host and pushes the discovered routing config to Mantræ.

### DNS integration

Mantræ supports automatic DNS record management for:
- Cloudflare
- PowerDNS
- Technitium
- PiHole

Configure DNS providers through the Mantræ web UI under Settings.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data is stored in the named volume. Back up the volume before major upgrades (pre-stable project — breaking changes may occur).

## Gotchas

- **Pre-stable software** — breaking changes are expected. Pin to a specific release tag and read changelogs before upgrading.
- **Mantræ is the source of truth** — once you use Mantræ as Traefik's HTTP provider, do not also manage the same routes via static YAML files. Conflicts will cause unpredictable behavior.
- **Mantræ does not restart Traefik** — Traefik polls the config endpoint automatically. No manual reload required for dynamic config changes.
- **`mantrae-agent` is deprecated** — use the new `mantraed` image from the separate repo.
- **Docker socket access on agent nodes** — `mantraed` needs the Docker socket to read container labels. Treat this as full Docker access.
- **API token required for agent** — generate the token in the Mantræ UI before deploying the agent.

## Links

- Upstream README: <https://github.com/MizuchiLabs/mantrae>
- Documentation: <https://mantrae.pages.dev>
- `mantraed` agent: <https://github.com/MizuchiLabs/mantraed>
- Releases: <https://github.com/MizuchiLabs/mantrae/releases>

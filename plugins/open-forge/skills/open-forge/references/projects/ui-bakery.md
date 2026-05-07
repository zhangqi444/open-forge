---
name: ui-bakery
description: UI Bakery recipe for open-forge. Low-code platform for building internal tools, customer portals, CRUD apps, and automations. Self-hosted on-premise via Docker. Proprietary license with free self-hosted tier. Source: https://github.com/uibakery/self-hosted
---

# UI Bakery

Low-code platform for building internal tools, customer portals, CRUD apps, and workflow automations. Drag-and-drop UI builder with data source connectors (databases, REST APIs, etc.), scheduled jobs, and webhooks. Self-hosted (on-premise) via Docker. Proprietary license. Free self-hosted tier available with a license key.

Upstream: <https://github.com/uibakery/self-hosted> | Cloud: <https://cloud.uibakery.io> | Docs: <https://docs.uibakery.io>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux | Docker (install.sh) | Recommended |
| Any | Docker Compose (manual) | For custom setups |
| AWS / Azure / GCP | Cloud-specific guides | See docs |
| Kubernetes | Helm chart | See docs |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | License key | Obtain free at https://uibakery.io/on-premise-ui-bakery |
| config | Hosting URL | Public URL, e.g. http://yourserver:3030 |
| config | Port | Default: 3030 |
| infra | 2 vCPUs, 4 GiB RAM, 20 GiB storage | Minimum requirements |
| infra | Outbound access to Azure Container Registry | cruibakeryonprem.westeurope.data.azurecr.io (for image pulls) |

## Software-layer concerns

- Proprietary license — source code is not open. The self-hosted repo contains deployment scripts only.
- License key required even for the free self-hosted tier.
- Docker images are pulled from Azure Container Registry (ACR) — the install machine needs internet access to Azure.

## Install — Linux (install.sh)

```bash
# Run from /home or a dedicated directory
curl -k -L -o install.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/install.sh
bash ./install.sh

# During install:
# 1. Enter your license key
# 2. Enter hosting URL (e.g. http://yourserver:3030)
# 3. Enter port (default: 3030)

# Access at http://yourserver:3030 after completion
```

> If Docker < 20.10.11 or Docker Compose < 1.29.2 is already installed, the script will stop. Update them manually first.

## Upgrade

```bash
# Follow: https://docs.uibakery.io/on-premise/updating-on-premise-version
curl -k -L -o update.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/update.sh
bash ./update.sh
```

## Gotchas

- **License key required** — get a free key at https://uibakery.io/on-premise-ui-bakery before running install.sh. The install prompts for it.
- **Internet access to Azure Container Registry is required** — the installer pulls Docker images from `cruibakeryonprem.westeurope.data.azurecr.io`. Air-gapped installs are not supported without enterprise arrangements.
- **Proprietary software** — this is not open source; the GitHub repo only contains deployment tooling, not application source code.
- The install script may upgrade Docker and Docker Compose on the host — if the server runs other apps, test in a dedicated environment first.
- Docker minimum version: 20.10.11 / Docker Compose minimum: 1.29.2.

## Links

- Self-hosted repo: https://github.com/uibakery/self-hosted
- License key: https://uibakery.io/on-premise-ui-bakery
- Documentation: https://docs.uibakery.io/on-premise/ui-bakery-on-premise
- Update guide: https://docs.uibakery.io/on-premise/updating-on-premise-version
- Cloud (SaaS) version: https://cloud.uibakery.io

---
name: illa-builder-project
description: ILLA Builder recipe for open-forge. Open-source low-code internal tool builder. Self-hosting via ILLA CLI or Docker. Apache 2.0.
---

# ILLA Builder

Open-source low-code platform for building internal tools — drag-and-drop UI builder with 40+ data source connectors (MySQL, PostgreSQL, REST APIs, GraphQL, MongoDB, Redis, Elasticsearch, S3, and more) and real-time collaboration. Self-hosting is via the ILLA CLI (which manages Docker containers internally) or direct Docker. Upstream: <https://github.com/illacloud/illa-builder>. Site: <https://illacloud.com>.

> ⚠️ **Check upstream maintenance status.** GitHub activity slowed in 2024. Verify the repo is actively maintained before adopting for production use.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| ILLA CLI | <https://docs.illacloud.com/self-hosted-deployment> | ✅ | Primary self-hosting path. CLI wraps Docker — Docker must be installed on the host. |
| Docker (manual) | <https://docs.illacloud.com/self-hosted-deployment> | ✅ | When you need more control over the container configuration. |
| Kubernetes | <https://docs.illacloud.com/self-hosted-deployment> | ⚠️ Community | No official Helm chart; Kubernetes support is community-maintained. |
| ILLA Cloud (managed) | <https://illacloud.com> | ✅ | Out of scope for open-forge — hosted service. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Is Docker installed and running on this host?" | Confirm | ILLA CLI requires Docker |
| preflight | "Linux or macOS?" | `linux` / `macos` | Determines CLI download URL |
| preflight | "Architecture (amd64 or arm64)?" | `amd64` / `arm64` | Determines CLI download URL |
| post-deploy | "Change the default root password immediately after first login." | Reminder | Default credentials are well-known — must change |

## Software-layer concerns

### ILLA CLI install and deploy

```bash
# Linux / amd64
curl -L https://github.com/illacloud/illa/releases/latest/download/illa-linux-amd64.tar.gz | tar xz
./illa deploy --self
```

For other architectures, replace `linux-amd64` with the appropriate suffix (e.g. `linux-arm64`, `darwin-amd64`). Check the [releases page](https://github.com/illacloud/illa/releases) for the current available assets.

The CLI pulls and starts the required Docker containers. It does not ship an `docker-compose.yml` in the main repository branch — container lifecycle is managed entirely through the CLI tool.

### Default credentials

| Field | Value |
|---|---|
| Email | `root@illacloud.com` |
| Password | `password` |

**Change the password immediately after first login.** These credentials are public knowledge.

### Container management

The ILLA CLI manages containers internally. Use CLI commands rather than direct `docker` commands for lifecycle operations:

```bash
./illa deploy --self    # initial deploy
./illa update --self    # update to latest
./illa stop --self      # stop all ILLA containers
./illa start --self     # start stopped containers
./illa remove --self    # remove all ILLA containers
```

### Ports

Default web UI port: **2022** (may vary by CLI version — check CLI output after deploy).

### Data directories

ILLA CLI creates Docker volumes for persistent data (database, uploads). Volume names are prefixed with `illa_`. Back up these volumes before running `./illa update`.

### No official docker-compose.yml

The main branch of `illacloud/illa-builder` does not ship a `docker-compose.yml`. Do not attempt to synthesize one from the source — use the CLI or consult the self-hosted deployment docs for any manually managed Docker approach.

## Upgrade procedure

```bash
# Using ILLA CLI
./illa update --self
```

The CLI pulls new images and recreates containers. Back up database volumes before upgrading.

If the CLI itself needs updating, re-download it from the releases page and replace the binary.

## Gotchas

- **Change the default root password immediately.** The default email/password (`root@illacloud.com` / `password`) is public. Anyone who finds your ILLA instance can log in as root until you change it.
- **ILLA CLI wraps Docker.** Docker must be installed and running before `./illa deploy --self`. The CLI is not a standalone installer — it orchestrates Docker containers.
- **No official Helm chart.** Kubernetes support is community-contributed. If you need Kubernetes, verify the community chart's maintenance status independently.
- **No official docker-compose.yml in the main branch.** If you find one on the internet, verify its source and date carefully — unofficial compose files may be outdated or insecure.
- **GitHub activity slowed in 2024.** Evaluate whether the project is actively maintained before adopting it for a production internal tooling platform. Check the Issues and Pull Requests tabs for recent activity.
- **CLI architecture.** The ILLA CLI binary is platform-specific. Download the correct variant for your OS and CPU architecture from the releases page.

## Links

- GitHub (builder): <https://github.com/illacloud/illa-builder>
- GitHub (CLI): <https://github.com/illacloud/illa>
- Self-hosted deployment docs: <https://docs.illacloud.com/self-hosted-deployment>
- Site: <https://illacloud.com>
- License: Apache 2.0
- Stars: ~11K

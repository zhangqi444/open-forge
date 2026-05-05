---
name: grist-project
description: Grist recipe for open-forge. Modern relational spreadsheet combining spreadsheet flexibility with database robustness. Covers Docker single-container deploy, grist-omnibus (with auth), environment variables, and persistence. Derived from https://github.com/gristlabs/grist-core.
---

# Grist

Modern relational spreadsheet that combines spreadsheet flexibility with database robustness. Upstream: <https://github.com/gristlabs/grist-core>. License: Apache 2.0.

Grist supports Python formulas, cross-table references, access rules, OIDC/SAML SSO, and collaborative editing. It stores documents as SQLite files. Two variants: grist-core (Community, this recipe) and full Grist (additional features, free for individuals/small orgs).

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker (grist-core) | <https://github.com/gristlabs/grist-core#using-grist> | yes | Simplest deploy. No auth by default — use behind a reverse proxy with auth or grist-omnibus. |
| grist-omnibus | <https://github.com/gristlabs/grist-omnibus> | yes | Bundles Grist + Traefik + Dex (OIDC). Recommended for internet-facing installs needing auth. |
| Desktop app | <https://github.com/gristlabs/grist-desktop> | yes | Single-user local app. No server needed. |
| getgrist.com hosted | <https://getgrist.com> | yes | Managed cloud. Out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What port should Grist run on?" | Integer default 8484 | Set via PORT env var. |
| preflight | "Where should Grist documents be stored on the host?" | Path default ./persist | Mounted to /persist inside container. |
| config | "App name to show in the UI?" | String default Grist | GRIST_APP_ROOT_URL displays this. |
| config | "Enable gVisor sandboxing?" | Yes / No default No | GRIST_SANDBOX_FLAVOR=gvisor. Requires Linux + Docker. |
| config | "AI Formula Assistant? (OpenAI or compatible)" | Yes / No | Set ASSISTANT_CHAT_COMPLETION_ENDPOINT and ASSISTANT_API_KEY. |
| auth | "Authentication method?" | options: None (LAN-only) / grist-omnibus / External OIDC / External SAML | Drives auth config. |

## Docker install (no auth, LAN/intranet use)

Upstream: <https://github.com/gristlabs/grist-core#using-grist>

```bash
docker run -p 8484:8484 -v $PWD/persist:/persist -it gristlabs/grist
```

Access at http://localhost:8484. All documents are saved to ./persist on the host.

To run on a different port:

```bash
docker run --env PORT=9999 -p 9999:9999 -v $PWD/persist:/persist -it gristlabs/grist
```

### docker-compose.yml (single-node, no auth)

```yaml
services:
  grist:
    image: gristlabs/grist:latest
    ports:
      - "8484:8484"
    environment:
      - PORT=8484
      # - GRIST_SANDBOX_FLAVOR=gvisor
    volumes:
      - ./persist:/persist
    restart: unless-stopped
```

## grist-omnibus (auth + TLS)

For internet-facing deployments with authentication, use grist-omnibus which bundles Grist + Traefik + Dex (OIDC provider):

```bash
git clone https://github.com/gristlabs/grist-omnibus
cd grist-omnibus
# Edit settings.env with your domain, admin email, etc.
docker compose up -d
```

See <https://github.com/gristlabs/grist-omnibus> for full setup.

## Software-layer concerns

### Key environment variables

| Variable | Default | Description |
|---|---|---|
| PORT | 8484 | Port Grist listens on inside container |
| GRIST_APP_ROOT_URL | (auto) | Public URL of the instance |
| GRIST_SANDBOX_FLAVOR | unsandboxed | gvisor for gVisor sandboxing (Linux + Docker only) |
| GRIST_SESSION_SECRET | (random) | Secret for session cookies — set explicitly for stable sessions |
| GRIST_SINGLE_ORG | (none) | Lock Grist to a single org (team site) slug |
| GRIST_DEFAULT_EMAIL | (none) | Email of the default owner/admin |
| ASSISTANT_CHAT_COMPLETION_ENDPOINT | (none) | OpenAI-compatible endpoint for AI formula assistant |
| ASSISTANT_API_KEY | (none) | API key for AI formula assistant |

### Ports

| Port | Use |
|---|---|
| 8484 | Web UI and API (HTTP) |

### Data directories (inside container)

| Path | Contents |
|---|---|
| /persist | Grist documents (.grist SQLite files), plugins, and config |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Grist documents are self-contained SQLite files in /persist. They are forward-compatible across versions.

## Gotchas

- **No auth by default**: Without auth configured, anyone who can reach port 8484 can access all documents. Use grist-omnibus, a reverse proxy with auth (Authelia, Authentik), or firewall to LAN only.
- **Persist volume**: Without mounting /persist, all documents are lost when the container stops.
- **gVisor sandboxing**: Requires Linux with Docker and kernel support. Set GRIST_SANDBOX_FLAVOR=gvisor only if confirmed supported by your kernel.
- **GRIST_SESSION_SECRET**: Set this explicitly to a stable random string; otherwise sessions break on container restart.
- **AI assistant**: Compatible with OpenAI, Claude (via OpenRouter), and any OpenAI-compatible endpoint. Set both ASSISTANT_CHAT_COMPLETION_ENDPOINT and ASSISTANT_API_KEY.
- **Documents are SQLite**: Any SQLite-compatible tool can read numeric/text data from .grist files directly — excellent for backups and migrations.

## Links

- GitHub: <https://github.com/gristlabs/grist-core>
- grist-omnibus (auth): <https://github.com/gristlabs/grist-omnibus>
- Docker Hub: <https://hub.docker.com/r/gristlabs/grist>
- Documentation: <https://support.getgrist.com/>
- Templates: <https://templates.getgrist.com/>

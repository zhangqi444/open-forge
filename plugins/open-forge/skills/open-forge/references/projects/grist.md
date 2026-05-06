---
name: grist
description: Grist recipe for open-forge. Modern relational spreadsheet combining spreadsheet flexibility with database robustness. Self-hosted via Docker. Upstream https://support.getgrist.com/self-managed/.
---

# Grist

Modern relational spreadsheet — a hybrid database/spreadsheet with named typed columns, Python formulas, drag-and-drop dashboards, OIDC/SAML SSO, REST API, and Zapier integrations. Built on SQLite. Upstream: <https://github.com/gristlabs/grist-core>. Docs: <https://support.getgrist.com/self-managed/>. License: Apache-2.0 (Community Edition `grist-core`).

Grist listens on port `8484` by default. The upstream-documented self-host path is Docker. There is no docker-compose file in the repo root; upstream documents a `docker run` command and the self-managed guide covers all configuration.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | <https://support.getgrist.com/self-managed/> | ✅ | Recommended. Single `gristlabs/grist` container. |
| Build from source | <https://github.com/gristlabs/grist-core#building-from-source> | ✅ | Development / contribution. |
| grist-desktop (native app) | <https://github.com/gristlabs/grist-desktop> | ✅ | Local desktop app — not a server deployment. |
| grist-omnibus | <https://github.com/gristlabs/grist-omnibus> | ✅ | Pre-packaged solution with bundled SSO (Dex) for easier auth setup. |
| getgrist.com managed | <https://getgrist.com> | ✅ | Hosted SaaS — out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | Options from table above | Drives method section |
| auth | "Default user email (GRIST_DEFAULT_EMAIL)?" | Email address | Required for initial access without SSO |
| domain | "Public URL Grist will be served at (APP_HOME_URL)?" | Full URL | All public installs |
| auth | "Admin panel boot key (GRIST_BOOT_KEY)?" | Random string | Optional but recommended for `/admin` page |
| auth | "Configure OIDC or SAML SSO?" | Yes/No | Optional — see docs |
| storage | "Host path for Grist data persistence?" | Free-text (default `./persist`) | All Docker installs |

## Docker — quick start

> **Source:** <https://github.com/gristlabs/grist-core#using-grist>

```bash
# Minimal — data lost on container removal
docker pull gristlabs/grist
docker run -p 8484:8484 -it gristlabs/grist

# With persistent data
docker run -p 8484:8484 \
  -v $PWD/persist:/persist \
  -it gristlabs/grist

# Visit http://localhost:8484
```

## Docker Compose

> No docker-compose is shipped in the upstream repo. The following is a representative pattern based on the upstream `docker run` documentation at <https://support.getgrist.com/self-managed/>.

```yaml
# docker-compose.yml — based on upstream docker run docs
services:
  grist:
    image: gristlabs/grist
    restart: unless-stopped
    ports:
      - "8484:8484"
    environment:
      - GRIST_DEFAULT_EMAIL=${GRIST_DEFAULT_EMAIL}
      - APP_HOME_URL=${APP_HOME_URL}
      - GRIST_BOOT_KEY=${GRIST_BOOT_KEY}
      # Optional: custom port
      # - PORT=8484
      # Optional: enable gVisor sandboxing
      # - GRIST_SANDBOX_FLAVOR=gvisor
    volumes:
      - ./persist:/persist
```

```bash
docker compose up -d
# Visit http://localhost:8484
# Admin panel at http://localhost:8484/admin?boot-key=<GRIST_BOOT_KEY>
```

## Software-layer concerns

### Key env vars

| Variable | Default | Purpose |
|---|---|---|
| `GRIST_DEFAULT_EMAIL` | _(unset)_ | Email attributed to unauthenticated work in the default Docker config. Change to your email. |
| `APP_HOME_URL` | auto-detected | Canonical public URL. Set when behind a reverse proxy. |
| `PORT` | `8484` | Listening port inside container. Change port mapping too if changing this. |
| `GRIST_BOOT_KEY` | _(unset)_ | Secret to access `/admin?boot-key=<key>`. Recommended. |
| `GRIST_SANDBOX_FLAVOR` | _(unset)_ | Sandboxing: `gvisor` (Linux), `macSandboxExec` (macOS), `pyodide` (any OS/Windows) |
| `GRIST_SESSION_SECRET` | _(unset)_ | Secret for session cookies. Set a random string in production. |
| `GRIST_SINGLE_ORG` | _(unset)_ | Set to an org slug to restrict to a single organization. |
| `GRIST_DOMAIN` | _(unset)_ | Domain for cookies. Required if using subdomains. |
| `ASSISTANT_API_KEY` | _(unset)_ | OpenAI / OpenRouter API key for AI Formula Assistant. |
| `ASSISTANT_CHAT_COMPLETION_ENDPOINT` | OpenAI default | Override to use OpenRouter or other OpenAI-compatible endpoint. |
| `GRIST_ALLOWED_HOSTS` | _(unset)_ | Comma-separated allowed hostnames (for multi-tenant or proxy setups). |

### Data directory

| Path (container) | Host mount | Contents |
|---|---|---|
| `/persist` | `./persist` | SQLite documents, attachments, user data |

### Docker images

| Image | Description |
|---|---|
| `gristlabs/grist` | Default. Contains Community + extra source-available full-edition code (inactive unless enabled via Admin Panel). |
| `gristlabs/grist-oss` | Exclusively FOSS code. Functionally equivalent to `gristlabs/grist` in default config. |

## Upgrade procedure

```bash
cd ~/grist

# Pull new image
docker compose pull

# Recreate container
docker compose up -d

# Migrations are handled automatically
```

Or with docker run:
```bash
docker pull gristlabs/grist
docker stop grist && docker rm grist
# Re-run docker run command with same -v mount
```

## Gotchas

- **Authentication requires SSO or a custom auth solution for multi-user.** Out of the box, the Docker container operates in limited anonymous mode attributing work to `GRIST_DEFAULT_EMAIL`. For real multi-user auth, configure OIDC/SAML or use `grist-omnibus` which bundles Dex.
- **`PORT` env var must match container port, not just the host-side mapping.** If you change `PORT=9999`, also change the container-side port: `-p 9999:9999`. Don't only change the host mapping.
- **`gristlabs/grist` vs `gristlabs/grist-oss`.** Both are functionally equivalent by default. The full-edition features in `gristlabs/grist` only activate when enabled from the Admin Panel (requires a Grist activation key).
- **Python formulas run in a sandbox.** On Linux with Docker, `GRIST_SANDBOX_FLAVOR=gvisor` enables gVisor isolation. On any OS, `pyodide` works via WebAssembly. No sandbox = Python runs directly on the host — don't use with untrusted documents.
- **`/persist` must be writable by the container user.** On Linux hosts, ensure permissions allow the container to write (`chmod -R 777 ./persist` or match the container UID).
- **Admin Panel available at `/admin`.** Requires `GRIST_BOOT_KEY` to be set; visit `/admin?boot-key=<key>`. Useful for diagnosing config problems.

## Upstream docs

- Self-Managed Grist: <https://support.getgrist.com/self-managed/>
- OIDC setup: <https://support.getgrist.com/install/oidc/>
- SAML setup: <https://support.getgrist.com/install/saml/>
- Admin Panel: <https://support.getgrist.com/admin-panel/>
- Configuration reference: <https://support.getgrist.com/self-managed/#environment-variables>
- grist-omnibus (bundled auth): <https://github.com/gristlabs/grist-omnibus>
- GitHub repo: <https://github.com/gristlabs/grist-core>

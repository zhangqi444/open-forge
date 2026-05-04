# Grist

Modern relational spreadsheet that combines spreadsheet flexibility with database robustness. Grist documents are SQLite files, formulas are Python, and the UI is a drag-and-drop dashboard builder. Open-source Community Edition (`grist-core`) is Apache 2.0. Contributions from Grist Labs and the French government (ANCT/DINUM). Upstream: <https://github.com/gristlabs/grist-core>. Docs: <https://support.getgrist.com/self-managed/>.

Grist listens on port `8484` by default. Single-container. Data persists to a `/persist` volume.

## Compatible install methods

Verified against upstream README at <https://github.com/gristlabs/grist-core#using-grist>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | `docker run -p 8484:8484 -v $PWD/persist:/persist gristlabs/grist` | ✅ | Simplest self-hosted deploy. All-in-one. |
| Docker Compose | See below | ✅ | Production with reverse proxy and auth. |
| `grist-omnibus` | <https://github.com/gristlabs/grist-omnibus> | ✅ | Preconfigured bundle with Traefik + Dex (OIDC) for quick HTTPS production setup. |
| Cloudron | <https://www.cloudron.io/store/io.grist.cloudronapp.html> | Community | Cloudron app store. |
| Yunohost | <https://github.com/YunoHost-Apps/grist_ynh> | Community | Yunohost app store. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| port | "Port for Grist?" | Number (default 8484) | All |
| auth | "Authentication type?" | `AskUserQuestion`: `No auth (single user)` / `OIDC` / `SAML` / `Forward auth (Authelia/Traefik)` | All |
| domain | "External URL for Grist (e.g. `https://grist.example.com`)?" | Free-text | Production |
| sandbox | "Enable gVisor formula sandboxing?" | `AskUserQuestion`: `Yes (recommended)` / `No` | Optional |

## Software-layer concerns

### Quick single-user start

```bash
docker run -p 8484:8484 \
  -v $PWD/persist:/persist \
  -e GRIST_DEFAULT_EMAIL=admin@example.com \
  --name grist \
  gristlabs/grist
```

Visit `http://localhost:8484`. No login required in single-user mode.

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `GRIST_DEFAULT_EMAIL` | Admin email address | Used for single-user mode; sets document owner |
| `APP_HOME_URL` | External URL | Required for production. e.g. `https://grist.example.com` |
| `GRIST_SANDBOX_FLAVOR` | Formula sandbox | `gvisor` (recommended) or `pyodide` |
| `PORT` | Port to listen on | Default: `8484` |
| `GRIST_SESSION_SECRET` | Session encryption key | Set for production. Generate: `openssl rand -hex 32` |
| `GRIST_OIDC_IDP_ISSUER` | OIDC provider URL | For SSO authentication |
| `GRIST_OIDC_IDP_CLIENT_ID` | OIDC client ID | For SSO authentication |
| `GRIST_OIDC_IDP_CLIENT_SECRET` | OIDC client secret | For SSO authentication (sensitive) |
| `GRIST_SINGLE_ORG` | Lock to one team/org | Set to team name for single-tenant deploy |
| `GRIST_HIDE_UI_ELEMENTS` | Disable UI elements | e.g. `helpCenter,billing,templates` |

### Docker Compose (with nginx reverse proxy)

```yaml
services:
  grist:
    image: gristlabs/grist:latest
    environment:
      APP_HOME_URL: "https://grist.example.com"
      GRIST_SESSION_SECRET: "${GRIST_SESSION_SECRET}"
      GRIST_DEFAULT_EMAIL: "admin@example.com"
      GRIST_SANDBOX_FLAVOR: "gvisor"
    volumes:
      - grist_data:/persist
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/grist.conf:ro
      - ./certs:/etc/ssl/certs:ro
    depends_on:
      - grist
    restart: unless-stopped

volumes:
  grist_data:
```

### grist-omnibus (easiest production setup)

For a production-ready setup with HTTPS and OIDC included:

```bash
git clone https://github.com/gristlabs/grist-omnibus
cd grist-omnibus
# Edit settings.env — set GRIST_EXTERNAL_URL, admin email, etc.
docker compose up -d
```

`grist-omnibus` bundles Traefik (reverse proxy + auto-TLS) and Dex (OIDC provider) alongside Grist.

### Python formula sandboxing

Grist formulas run in Python. For untrusted users (multi-tenant), enable gVisor sandboxing:

```bash
docker run ... -e GRIST_SANDBOX_FLAVOR=gvisor gristlabs/grist
```

Check if gVisor works on your system:
```bash
docker run --rm gristlabs/grist python3 -c "print('ok')"
```

### Data directories

| Path | Contents |
|---|---|
| `/persist/` | SQLite `.grist` document files, home database, log files |
| `/persist/grist.sqlite3` | Home/team database (users, workspaces, document index) |
| `/persist/docs/` | Individual Grist document files (each is a `.grist` SQLite file) |

Backup: copy the entire `/persist/` directory. Individual documents can be exported as `.grist`, `.xlsx`, or `.csv`.

## Upgrade procedure

1. `docker compose pull`
2. `docker compose up -d`

Grist applies schema migrations automatically. Always back up `/persist/` before upgrading major versions.

## Gotchas

- **`PORT` env var, not just port mapping.** If you want to change the port Grist listens on, set `--env PORT=9999` *and* change the port mapping. Port mapping alone won't work.
- **gVisor requires compatible kernel.** gVisor sandboxing requires Linux 4.14+ and a compatible Docker setup. Not available in all cloud environments. Falls back to no sandboxing if not available.
- **Multi-user needs SSO.** The open-source Community Edition requires an external OIDC or SAML provider for multi-user authentication. grist-omnibus includes Dex as a built-in OIDC provider.
- **Documents are SQLite files.** Every Grist document is a self-contained `.grist` SQLite file. You can open them with SQLite tools directly to inspect or export data.
- **grist-core vs. paid edition.** Grist Labs sells an enterprise edition with additional features (audit logs, advanced RBAC, usage analytics). grist-core/Community is fully functional for most self-hosting scenarios.

## Links

- Upstream: <https://github.com/gristlabs/grist-core>
- Docs: <https://support.getgrist.com/self-managed/>
- grist-omnibus: <https://github.com/gristlabs/grist-omnibus>
- Docker Hub: <https://hub.docker.com/r/gristlabs/grist>
- Templates: <https://templates.getgrist.com>
- OIDC setup: <https://support.getgrist.com/install/oidc/>

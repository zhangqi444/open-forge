---
name: Nginx UI
description: Web admin panel for Nginx. Visual server/location/SSL config editor, Let's Encrypt automation, multi-node cluster mirroring, live log tailing, built-in terminal, AI code completion for nginx configs. Go + Vue. GPL-3.0.
---

# Nginx UI

Nginx UI is a web dashboard for managing an existing Nginx installation. Unlike Nginx Proxy Manager (which wraps Nginx and hides the config), Nginx UI exposes **the actual `nginx.conf` files** and lets you edit them — with syntax highlighting, a visual block editor, AI-assisted completion, Let's Encrypt automation, and multi-node cluster config mirroring.

- **Visual config editor** — custom "NgxConfigEditor" block editor for nginx syntax
- **Ace code editor** — raw syntax editor with highlighting + LLM code completion
- **Let's Encrypt** — automatic cert issuance + renewal for your sites
- **Cluster management** — mirror config changes to multiple nginx nodes
- **Live config validation** — `nginx -t` before reload
- **Reload / restart** from UI
- **Live log tailing** — access + error logs
- **Site templates** — new site from template (reverse proxy, static, HTTPS, etc.)
- **Built-in terminal** (web shell) — if enabled
- **ChatGPT / Deepseek assistant** — ask questions about your config
- **i18n** — EN, ES, ZH, JP, VI, plus more

- Upstream repo: <https://github.com/0xJacky/nginx-ui>
- Docs: <https://nginxui.com>
- Docker Hub: <https://hub.docker.com/r/uozi/nginx-ui>

## Architecture in one minute

Two deployment modes:

### Mode A: Same container as nginx (Docker image)

The `uozi/nginx-ui` image is **based on the official nginx image** — it contains nginx itself + the UI. You replace your nginx deployment with this combined container.

### Mode B: Installed alongside existing nginx (native binary)

Binary runs on the same host as your nginx, reads/writes `/etc/nginx/`, talks to nginx via `nginx -s reload`. Works on Linux, macOS, Windows, FreeBSD/OpenBSD/Dragonfly BSD, OpenWrt.

Ports:

- **`:80` / `:443`** — nginx itself (if in-container mode)
- **`:9000`** (default binary) OR **mapped port** (in-container: exposes UI on a separate port) — the UI

## Compatible install methods

| Infra       | Runtime                                           | Notes                                                              |
| ----------- | ------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM   | Docker (`uozi/nginx-ui:latest` — bundles nginx)    | **Most common**                                                     |
| Single VM   | Native binary via install script                    | Installs as `nginx-ui` systemd service                                |
| Single VM   | Native binary (manual)                              | Download + run; works on Linux/macOS/Windows/BSD                      |
| Kubernetes  | Community Helm charts                                | Several community options                                              |
| OpenWrt     | ipk package or binary                                | For home routers                                                       |

## Inputs to collect

| Input                  | Example                                | Phase     | Notes                                                            |
| ---------------------- | -------------------------------------- | --------- | ---------------------------------------------------------------- |
| Nginx config dir       | `/etc/nginx` (volume or host path)      | Filesystem | Nginx UI manages everything here                                 |
| Nginx UI data dir      | `/etc/nginx-ui`                         | Filesystem | Config DB, cluster keys, AI chat history                            |
| Web UI port            | e.g. `8080` → `80` (container mode)     | Network   | Port 80 in container is both nginx and UI (separate routes)         |
| TZ                     | `Asia/Shanghai`, `UTC`, etc.            | Config    | For Let's Encrypt + logs                                            |
| First admin            | set via `/install` wizard on first visit | Bootstrap | First-user-is-admin                                                 |
| AI API key (optional)  | OpenAI / Deepseek / Azure OpenAI         | AI        | For LLM completion + chat assistant                                  |

## Install via Docker (bundled nginx, typical)

```sh
docker run -dit --name nginx-ui \
  --restart unless-stopped \
  -e TZ=UTC \
  -v /opt/nginx:/etc/nginx \
  -v /opt/nginx-ui:/etc/nginx-ui \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 8080:80 -p 8443:443 \
  uozi/nginx-ui:2.3.10    # pin; check Docker Hub
```

**First run**: ensure `/opt/nginx` (the `/etc/nginx` target) is **empty** — the container populates it. If it's non-empty with your existing config, the install wizard can import it.

Open <http://host:8080/install>. Complete wizard:

1. Set admin username + password
2. Database location (defaults to `/etc/nginx-ui/database.db`)
3. HTTPS certificate (leave empty to configure later via UI)

## Install via Docker Compose

```yaml
services:
  nginx-ui:
    image: uozi/nginx-ui:2.3.10
    container_name: nginx-ui
    restart: unless-stopped
    stdin_open: true
    tty: true
    environment:
      TZ: UTC
    volumes:
      - nginx:/etc/nginx
      - nginx-ui:/etc/nginx-ui
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"      # UI on a separate port

volumes:
  nginx:
  nginx-ui:
```

## Install via Linux script (native, alongside existing nginx)

```sh
bash <(curl -L -s https://raw.githubusercontent.com/0xJacky/nginx-ui/main/install.sh) install
```

Installs as `nginx-ui` systemd service; default port `9000`. Config at `/usr/local/etc/nginx-ui/app.ini`. Admin wizard at `http://<host>:9000/install`.

Service control:

```sh
systemctl status nginx-ui
systemctl restart nginx-ui
```

## First boot

1. Browse `/install` → create admin account
2. **Nginx config** — if importing existing: point at your config path + validate
3. **Let's Encrypt account** — configure email + ACME server
4. **Sites** → pick a template (reverse proxy, static HTTPS, etc.) → fill in upstream + domain → issue cert → deploy
5. **Cluster** (optional) — add peer nodes by public key; changes mirror to peers

## Data & config layout

Inside `/etc/nginx-ui/`:

- `database.db` — SQLite: users, sessions, cluster peers, site metadata
- `app.ini` OR `app.conf` — Nginx UI's own config
- `ssl/` — issued ACME certs (if not using host nginx's cert dir)
- `chat_history/` — AI assistant conversation history

Inside `/etc/nginx/` (managed by Nginx UI):

- `nginx.conf` — main
- `sites-available/` + `sites-enabled/` — vhosts
- `conf.d/` — snippets
- `stream-available/` + `stream-enabled/` — TCP/UDP streams
- Everything else nginx-standard

## Backup

```sh
# Nginx UI state
docker run --rm -v nginx-ui:/src -v "$PWD":/backup alpine \
  tar czf /backup/nginx-ui-$(date +%F).tgz -C /src .

# Nginx config + certs
docker run --rm -v nginx:/src -v "$PWD":/backup alpine \
  tar czf /backup/nginx-conf-$(date +%F).tgz -C /src .
```

## Upgrade

1. Releases: <https://github.com/0xJacky/nginx-ui/releases>. Active.
2. Docker: `docker compose pull && docker compose up -d`.
3. Native: re-run install script.
4. DB migrations are automatic; back up `database.db` before major jumps.
5. **Read release notes** — 2.x → 3.x (when it happens) will have breaking changes.

## Gotchas

- **Docker-socket mount** (`/var/run/docker.sock`) gives the container **root on the host**. Only mount it if you trust the image + need Docker stats features. Can be omitted to reduce attack surface.
- **First-run must be empty `/etc/nginx`** in container mode — Nginx UI populates it. If not empty, wizard prompts to import.
- **UI serves on the same container as nginx** — port 80/443 are nginx's web traffic; UI is either on a separate port (Docker mapping) or on a special nginx location.
- **Auth protects the UI only** — nginx itself serves whatever sites you configure. Don't expose the UI publicly without TLS + strong password.
- **Cluster mirroring** mirrors config changes across multiple Nginx UI nodes — deltas go via gRPC with public-key auth. Useful for multi-host nginx deployments.
- **ChatGPT/AI features send config snippets to a third-party LLM** — turn off or route to your own LLM (Ollama/vLLM) if confidential configs are a concern. Supports OpenAI-compatible endpoints.
- **Let's Encrypt** — uses the HTTP-01 challenge by default; needs port 80 reachable. DNS-01 supported for wildcards (via supported DNS providers).
- **Edit-the-raw-config** works — the UI saves config back to `/etc/nginx` and reloads. Mistakes that fail `nginx -t` are caught before reload (won't break live traffic), but only the very latest edit — the UI doesn't maintain a per-save rollback (it's not git-backed).
- **Version-control your `/etc/nginx`** — Nginx UI doesn't maintain rollback. Simple `git init /etc/nginx && git commit` after every UI save gives you version history.
- **Built-in terminal / web shell** is extremely powerful — if enabled + reachable, it's **root-equivalent access**. Disable unless you're the only admin.
- **GPL-3.0** — strong copyleft; derivative works must be GPL too. Internal use = no obligations.
- **Multi-language support**: 15+ languages. i18n via Weblate.
- **Nginx UI vs Nginx Proxy Manager** trade-off:
  - **Nginx Proxy Manager** — simpler UX, hides nginx.conf from you; good for non-power-users
  - **Nginx UI** — exposes raw nginx syntax + more advanced features (streams, cluster, AI); better for people who know nginx
- **Alternatives worth knowing:**
  - **Nginx Proxy Manager (NPM)** — simpler; wraps nginx in SQLite-backed abstractions (separate recipe)
  - **Zoraxy** — Go-based reverse proxy manager, similar target audience
  - **Caddy** — auto-TLS first-class, simpler conf; not GUI-driven by default
  - **Traefik** — docker-label-driven; service discovery; no editor UI
  - **HAProxy** — different engine (not nginx); no first-party UI
  - **Caddy with community UIs** (caddy-manager, caddy-gui)

## Links

- Repo: <https://github.com/0xJacky/nginx-ui>
- Docs: <https://nginxui.com>
- Docker Hub: <https://hub.docker.com/r/uozi/nginx-ui>
- Releases: <https://github.com/0xJacky/nginx-ui/releases>
- Installation docs: <https://nginxui.com/guide/getting-started.html>
- Config reference: <https://nginxui.com/guide/config-nginx.html>
- Weblate (i18n): <https://weblate.nginxui.com/engage/nginx-ui/>
- Demo: <https://demo.nginxui.com>

# An Otter Wiki

Minimalistic Python-based wiki with collaborative content management. Content is stored in a Git repository (full change history). Uses Markdown as markup language. Built with Flask, halfmoon CSS, and CodeMirror editor. Includes user authentication, page attachments, extended Markdown (tables, footnotes, mermaid diagrams), and an experimental Git HTTP server.

**Official site:** https://otterwiki.com  
**Source:** https://github.com/redimp/otterwiki  
**Upstream docs:** https://otterwiki.com/Installation  
**Docker image:** `redimp/otterwiki:2`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended — single container, app-data volume |
| Any Linux host | Docker (single container) | Same image, no compose needed |
| Python host | pip + gunicorn | Direct install; see upstream docs |

---

## Inputs to Collect

### All phases
| Variable | Description | Example |
|----------|-------------|---------|
| `HOST_PORT` | Host port to expose the wiki on | `8080` |
| `DATA_DIR` | Host path for wiki data (git repo + attachments) | `./app-data` |

### Reverse proxy (if applicable)
| Field | Description |
|-------|-------------|
| Domain / virtual host | The public hostname for the wiki |
| SSL termination | nginx / caddy / apache; upstream has example configs at https://otterwiki.com/Installation#reverse-proxy |

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  otterwiki:
    image: redimp/otterwiki:2
    restart: unless-stopped
    ports:
      - 8080:80
    volumes:
      - ./app-data:/app-data
```

Start with:

```bash
docker compose up -d
```

Then open http://127.0.0.1:8080. The first registered account is automatically an admin.

### Data directory

- All wiki content and attachments stored under `/app-data` in the container
- The directory is a Git repository — `git log` works inside it
- Back up `app-data/` (includes the Git history of all pages)

### Reverse proxy

For production deployments, put a web server in front. Upstream provides example configs for nginx, Apache, and Caddy at https://otterwiki.com/Installation#reverse-proxy

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

The wiki data in `app-data/` is preserved across upgrades.

---

## Gotchas

- The first user to register becomes the admin — register immediately after first start.
- The Git HTTP server (clone/pull/push wiki content) is marked experimental in upstream docs.
- Image tag `:2` tracks the latest v2.x release; use a pinned digest for reproducible deployments.
- If you use a reverse proxy, ensure it does not buffer large uploads (attachments).

---

**Upstream README:** https://github.com/redimp/otterwiki#readme  
**Installation guide:** https://otterwiki.com/Installation  
**Configuration guide:** https://otterwiki.com/Configuration

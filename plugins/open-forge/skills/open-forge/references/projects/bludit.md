---
name: bludit-project
description: Bludit recipe for open-forge. Covers Docker and traditional PHP/webserver install as documented at https://github.com/bludit/bludit.
---

# Bludit

Simple, fast, and flexible flat-file CMS. Stores all content as JSON files — no database required. Built on PHP, supports Markdown and HTML. Upstream: <https://github.com/bludit/bludit>. Official site: <https://www.bludit.com/>. Docs: <https://docs.bludit.com/>.

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker | <https://github.com/bludit/bludit#quick-installation-for-testing> | Fastest start; no PHP env needed |
| PHP + webserver (Apache/Nginx) | <https://docs.bludit.com/en/getting-started/installation> | Traditional shared hosting or VPS with existing PHP stack |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which port should Bludit be accessible on?" | Number (default `8000`) | Maps to container port `80` |
| data | "Where should Bludit's content/data be persisted?" | Host directory path | Bind-mount at `/var/www/html/bl-content` inside container |
| domain | "What domain/subdomain will Bludit run on?" | Hostname | Used for reverse proxy config |

## Docker quick-start (from upstream README)

```bash
docker pull bludit/docker:latest
docker run -d --name bludit \
  -p 8000:80 \
  -v $(pwd)/bl-content:/var/www/html/bl-content \
  bludit/docker:latest
```

Visit `http://localhost:8000` → follow the web installer.

> Note: The upstream README does not include a volume mount in its example, but persisting `/var/www/html/bl-content` is essential — this is where all posts, pages, uploads, and settings are stored.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Data directory | `/var/www/html/bl-content` — all JSON data, uploads, plugins, and themes. **Must be persisted via bind-mount or named volume.** |
| No database | Bludit uses flat JSON files. No database service needed. |
| PHP requirements | PHP ≥ 8.0 with extensions: `mbstring`, `gd`, `dom`, `json`. All included in the official Docker image. |
| Admin panel | Accessible at `/admin` after install wizard. |
| Plugins & themes | Stored in `bl-content/plugins/` and `bl-content/themes/` — persist with the data volume. |
| Reverse proxy (critical) | Bludit reads client IP from `REMOTE_ADDR` only. Behind Nginx/Caddy/Cloudflare, configure `real_ip` rewriting at the webserver layer or the brute-force blocklist will lock out the proxy IP, blocking all visitors. See upstream README for `mod_remoteip` (Apache) and `ngx_http_realip_module` (Nginx) instructions. |

## Upgrade procedure

Per <https://github.com/bludit/bludit#upgrading-bludit>:

1. **Back up** the entire `bl-content` directory.
2. Pull the new Docker image: `docker pull bludit/docker:latest`
3. Stop and remove the old container: `docker stop bludit && docker rm bludit`
4. Start a new container with the same volume mount (data is preserved).
5. Log into the admin area and verify settings.
6. Clear browser cache (some JS components like TinyMCE may cache stale files).

For cross-major-version upgrades (e.g. v3.x → v4.x), consult the upstream migration guide first.

## Gotchas

- **Forget to mount data volume**: without `-v bl-content:/var/www/html/bl-content`, all posts and settings are lost when the container restarts.
- **Reverse proxy brute-force lockout**: the most common production issue. If all visitors suddenly can't log in, the proxy IP has been blocklisted. Fix: configure `REMOTE_ADDR` rewriting at the webserver, then clear the blocklist from `bl-content/tmp/`.
- **Cloudflare cache**: after upgrades, purge Cloudflare cache — JavaScript editor (TinyMCE) and theme assets may not reload otherwise.
- **Cross-major upgrades**: the standard "replace files" upgrade path only applies within the same major version (e.g. 3.x → 3.y). Cross-major upgrades need the migration guide.

## Links

- Upstream README: <https://github.com/bludit/bludit>
- Documentation: <https://docs.bludit.com/>
- Docker Hub: <https://hub.docker.com/r/bludit/docker>
- Plugins: <https://plugins.bludit.com/>
- Themes: <https://themes.bludit.com/>

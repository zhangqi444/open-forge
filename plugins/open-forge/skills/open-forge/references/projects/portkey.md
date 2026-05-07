# portkey

**Lightweight web portal and startup page** — single-binary Go app configured via one `config.yml` file. Displays a collection of links organized into groups, includes a fuzzy-search box with keyword shortcuts, supports custom pages, dark/light mode, and optional Prometheus metrics.

**Official site:** https://portkey.page
**Source:** https://github.com/kodehat/portkey
**License:** AGPL-3.0
**Demo:** https://demo.portkey.page

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker | Single container; mount config file |
| Any VPS / bare metal | Binary | Download pre-built binary; no dependencies |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Whether to run behind a reverse proxy (required if hosting under a subdirectory)
- Whether to enable Prometheus metrics endpoint

### Phase 2 — Deploy
- `config.yml` — define title, links, groups, search engines, custom pages
- `contextPath` — set if hosting under a subdirectory (e.g. `/portkey`)

---

## Software-Layer Concerns

- **Config file:** Single `config.yml`; all links, groups, and pages defined here
- **Env var overrides:** All config keys can be set via env vars prefixed `PORTKEY_` in uppercase (e.g. `PORTKEY_HOST`, `PORTKEY_PORT`)
- **Default port:** 3000
- **Metrics:** Optional HTTP metrics server on port 3030 (Prometheus-compatible); enable with `enableMetrics: true`
- **No database** — fully stateless; config file is the only persistent state
- **Reverse proxy subdirectory:** Set `contextPath: /portkey` (must start with `/`) when hosting under a path prefix

---

## Deployment

```bash
# Docker (config.yml in current directory)
docker run --rm -it \
  -v $(PWD)/config.yml:/opt/config.yml \
  -p 3000:3000 \
  codehat/portkey:latest
```

```yaml
# docker-compose.yml
version: '3'
services:
  portkey:
    image: codehat/portkey:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./config.yml:/opt/config.yml:ro
```

Minimal `config.yml`:
```yaml
title: "My Portal"
subtitle: "Where do you want to go?"
host: 0.0.0.0
port: 3000
portals:
  - label: "GitHub"
    url: "https://github.com"
    icon: "github"
```

Full config reference: https://github.com/kodehat/portkey/blob/main/config.yml

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

For binary installs, download the latest release from GitHub and replace the binary.

---

## Gotchas

- **`host` must be `0.0.0.0`** in Docker (not `localhost`) or the container won't be reachable from outside
- **Use a pinned tag** in production rather than `latest` — changelog at GitHub releases
- **`contextPath` requires leading slash** — `/portkey` is correct; `portkey` will cause routing issues
- **Config changes require restart** — no hot-reload; restart the container after editing `config.yml`
- **Fuzzy search** works on link labels and configured keywords; configure keywords in config for best results

---

## Links

- Upstream README: https://github.com/kodehat/portkey#readme
- Example config: https://github.com/kodehat/portkey/blob/main/config.yml
- Demo: https://demo.portkey.page

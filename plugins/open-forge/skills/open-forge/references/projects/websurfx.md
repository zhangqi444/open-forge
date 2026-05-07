---
name: Websurfx
description: Lightning-fast, privacy-respecting metasearch engine written in Rust. Aggregates results from multiple search engines without ads or tracking. Alternative to SearXNG. AGPL-3.0.
website: https://github.com/neon-mmd/websurfx
source: https://github.com/neon-mmd/websurfx
license: AGPL-3.0
stars: 1092
tags:
  - search
  - metasearch
  - privacy
  - searx
platforms:
  - Rust
  - Docker
depends_3rdparty: true
---

# Websurfx

Websurfx is a modern metasearch engine written in Rust that aggregates results from Google, Bing, DuckDuckGo, and other engines without ads or tracking. It emphasizes speed, security, and privacy. It's an alternative to SearXNG with a focus on performance (Rust vs Python) and a cleaner UI.

Source: https://github.com/neon-mmd/websurfx  
Latest release: v1.29.0 (April 2026)  
Discord: https://discord.gg/SWnda7Mw5u

> **Note**: Requires third-party search engines to function — upstream engines may rate-limit or block automated queries. Use with caution in high-traffic environments.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker | Recommended; official docker-compose provided |
| Any Linux VM / VPS | Docker + Redis | For `hybrid` or `redis` caching modes |
| Any Linux VM / VPS | Native Rust binary | Build from source |

## Inputs to Collect

**Phase: Planning**
- Port to expose (default: `8080`)
- Caching strategy: `none`, `memory`, `hybrid` (memory+Redis), or `redis`
- Redis connection URL (if using Redis caching)
- Search engines to enable (configured in `config.lua`)
- Safe search level (0–4)
- Rate limiting preferences

**Phase: First Boot**
- Review and customize `config.lua` — engines, UI theme, safe search, etc.

## Software-Layer Concerns

**Docker Compose (no caching):**
```yaml
version: "3.9"
services:
  app:
    image: neonmmd/websurfx:latest
    ports:
      - 8080:8080
    volumes:
      - ./websurfx/:/etc/xdg/websurfx/
    restart: unless-stopped
```

**Docker Compose (with Redis caching):**
```yaml
version: "3.9"
services:
  app:
    image: neonmmd/websurfx:latest
    ports:
      - 8080:8080
    volumes:
      - ./websurfx/:/etc/xdg/websurfx/
    depends_on:
      - redis
    links:
      - redis
    restart: unless-stopped

  redis:
    image: redis:latest
    restart: unless-stopped
```

**Config directory:** `./websurfx/` mounted to `/etc/xdg/websurfx/` inside container

**Create config on first run:**
```bash
mkdir -p ./websurfx
# Copy example config from source or releases
wget -O ./websurfx/config.lua \
  https://raw.githubusercontent.com/neon-mmd/websurfx/rolling/websurfx/config.lua
# Edit to taste
```

**Key `config.lua` settings:**
```lua
-- Binding
binding_ip_addr = "0.0.0.0"
port = 8080

-- Caching: "none" | "memory" | "redis" | "hybrid"
caching = "memory"
redis_url = "redis://redis:6379"

-- Safe search: 0 (off) to 4 (strict)
safe_search = 2

-- Upstream engines
upstream_search_engines = {
  DuckDuckGo = true,
  Bing = false,
  Google = false,
}
```

**Ports:**
- `8080` → Web UI

## Upgrade Procedure

1. `docker pull neonmmd/websurfx:latest`
2. `docker-compose down && docker-compose up -d`
3. Review config changelog: https://github.com/neon-mmd/websurfx/releases

## Gotchas

- **Third-party dependency**: Results depend on upstream search engines (Google, Bing, DDG, etc.) — these may block/rate-limit scraping; some engines require API keys
- **rolling branch**: The active development branch is `rolling`; `main` may lag behind. Docker image tags: `latest` tracks rolling
- **Rate limiting by upstreams**: High query volumes will trigger CAPTCHAs or IP bans from upstream engines; consider using a VPN/proxy or limiting to engines that are more tolerant
- **No JavaScript required**: The default UI works without JS, but some themes require it
- **Config format is Lua**: Not YAML/TOML — syntax errors in `config.lua` crash the app on startup
- **Build from source**: Requires Rust toolchain; Docker is strongly recommended for most users

## Links

- Upstream README: https://github.com/neon-mmd/websurfx/blob/rolling/README.md
- Documentation: https://github.com/neon-mmd/websurfx/tree/rolling/docs
- Configuration reference: https://github.com/neon-mmd/websurfx/blob/rolling/websurfx/config.lua
- Releases: https://github.com/neon-mmd/websurfx/releases
- Discord: https://discord.gg/SWnda7Mw5u

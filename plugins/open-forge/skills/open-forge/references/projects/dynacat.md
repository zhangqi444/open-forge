# Dynacat

**What it is:** Self-hosted dashboard focused on dynamic real-time updates and easy integration with external apps. A fork of Glance, extended with more widget types, external app integrations without custom code, theming, and a small single-binary footprint. Configured via YAML.

**Official site:** https://dynacat.artur.zone  
**Docs:** https://dynacat.artur.zone/configuration  
**GitHub:** https://github.com/Panonim/dynacat  
**Companion repo (widgets):** https://github.com/Panonim/dynawidgets

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Official Docker image available |
| Any Linux | Binary | Single static binary <20 MB, multi-arch |
| Raspberry Pi / ARM | Binary or Docker | Multi-arch builds available |
| Windows / macOS | Binary | Pre-built binaries for multiple OSes |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| Config YAML file | Main configuration — pages, columns, widgets |
| Host port | Port to expose the dashboard (e.g. `8080`) |

---

## Software-Layer Concerns

- **Single binary** — no external dependencies, <20 MB
- **Configuration is entirely YAML-based** — edit the config file and restart to apply changes
- **Pages, columns, and widgets** are defined in the YAML config; multiple pages supported
- **No database** — stateless; all data comes from live API/RSS fetches
- **Uncached pages load in ~1s** (depending on widget count and internet speed)
- **Low memory usage** — suitable for low-power devices (Raspberry Pi, NAS)

### Widget types

| Category | Examples |
|----------|---------|
| News/feeds | RSS feeds, Hacker News posts, Subreddit posts |
| Media | YouTube channel uploads, Twitch channels |
| Finance | Market prices |
| Infrastructure | Docker container status, Server stats |
| Utilities | Calendar, Weather forecasts |
| Custom | Custom widgets via Dynawidgets |

---

## Example Docker Compose

```yaml
services:
  dynacat:
    image: panonim/dynacat:latest
    container_name: dynacat
    ports:
      - "8080:8080"
    volumes:
      - ./config.yml:/app/config.yml:ro
    restart: unless-stopped
```

---

## Example Config Snippet

```yaml
pages:
  - name: Home
    columns:
      - size: small
        widgets:
          - type: calendar
            first-day-of-week: monday
          - type: rss
            limit: 10
            feeds:
              - url: https://selfh.st/rss/
                title: selfh.st
      - size: full
        widgets:
          - type: docker-containers
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. For binary: download new release from GitHub, replace binary, restart

---

## Gotchas

- **Config changes require a restart** — no hot-reload
- **No authentication built in** — add a reverse proxy with auth (Caddy, Authelia) if exposing publicly
- **External API rate limits** apply for widgets like GitHub, Reddit, YouTube — some widgets require API keys
- Dynacat is a Glance fork — check [Glance docs](https://github.com/nicholaswilde/glance) for base widget reference; Dynacat extends these
- **Preconfigured pages** available at https://dynacat.artur.zone/preconfigured-pages — drop-in YAML configs

---

## Links

- Docs: https://dynacat.artur.zone/configuration
- Themes: https://dynacat.artur.zone/themes
- Preconfigured pages: https://dynacat.artur.zone/preconfigured-pages
- GitHub: https://github.com/Panonim/dynacat
- Dynawidgets: https://github.com/Panonim/dynawidgets

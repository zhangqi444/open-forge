# Comic Library Utilities (CLU)

**What it is:** A web-based toolset for managing large comic book libraries (CBZ/CBR files). Bulk convert, rename, move, enhance, and rebuild comic archives — all via a browser UI without needing direct server access. Integrates with Komga, GetComics.org, Metron, and ComicVine for metadata and downloads. Includes folder monitoring with auto-rename/convert, a pull list for weekly new releases, reading insights/stats, and optional local GCD database support.

**Official URL:** https://clucomics.org
**Container:** `allaboutduncan/comic-utils-web:latest`
**License:** See repo
**Stack:** Python/Docker; single container

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / homelab | Docker Compose | Single container; maps to comic library on host |
| Windows / macOS | Docker Desktop | Same compose file |

---

## Inputs to Collect

### Pre-deployment (volumes)
- `/path/to/local/config` → `/config` — persistent config/settings directory
- `/path/to/local/cache` → `/cache` — DB and thumbnail cache
- `/path/to/your/library` → `/data` — your main comic library (first/primary library)
- Additional libraries → `/data2`, `/data3`, etc. (add more volume mounts as needed)

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  comic-utils:
    image: allaboutduncan/comic-utils-web:latest
    container_name: clu
    restart: always
    ports:
      - "5577:5577"
    volumes:
      - /path/to/local/config:/config
      - /path/to/local/cache:/cache
      - /path/to/your/comics:/data      # main library
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-file: "3"
```

**Default port:** `5577`

**Multiple libraries:** Add additional volume mounts (`/data2`, `/data3`, etc.) for multiple comic directories.

**Full documentation:** https://clucomics.org — install steps and all feature docs have moved to the official site.

**Upgrade procedure:**
```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **Designed for large libraries** — originally built while migrating a 70,000+ comic collection; performs well at scale but bulk operations take time
- **Komga integration** — works great alongside Komga (the comic server); CLU handles management while Komga handles reading
- **GetComics.org downloads** — the download feature depends on the availability of GetComics.org; verify the site is accessible in your region
- **Metron/ComicVine API keys** — metadata update features require API keys from Metron and/or ComicVine; obtain before use

---

## Links
- GitHub: https://github.com/allaboutduncan/clu-comics
- Documentation: https://clucomics.org
- Docker Hub: https://hub.docker.com/r/allaboutduncan/comic-utils-web

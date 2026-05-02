# Yacht

**What it is:** A web UI for managing Docker containers with a focus on app templates and 1-click deployments. Supports Portainer-compatible template URLs, Docker Compose stacks, container editing, and centralized volume/path settings. Originally written in Vue.js/Python; a TypeScript rewrite is in progress.

> ⚠️ **Maintenance status:** The current repository (`SelfhostedPro/Yacht`) has not been actively updated and the main branch is in alpha. The author is working on a new version at https://github.com/Yacht-Docker-Container. Check there for the latest development status before deploying.

**Official URL:** https://github.com/SelfhostedPro/Yacht
**Docker Hub:** `selfhostedpro/yacht`
**Docs:** https://dev.yacht.sh
**License:** MIT
**Stack:** Vue.js (frontend) + Python/FastAPI (backend); Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| DigitalOcean | Marketplace 1-click | Available on DO Marketplace |
| Linode | Marketplace | Available on Linode Marketplace |

---

## Inputs to Collect

### Pre-deployment
- `PUID` / `PGID` — optional user/group for file permissions
- Port — default `8000`
- Config volume path — persists Yacht settings and database

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  yacht:
    image: selfhostedpro/yacht
    container_name: yacht
    restart: unless-stopped
    ports:
      - 8000:8000
    volumes:
      - yacht:/config
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  yacht:
```

**Default port:** `8000`

**Default credentials:** `admin@yacht.local` / `pass` — **change immediately after first login**

**Templates:** Add a Portainer-compatible template URL in Settings → Templates. Recommended starter template:
```
https://raw.githubusercontent.com/SelfhostedPro/selfhosted_templates/yacht/Template/template.json
```
Templates define apps with variables (e.g. `!config` → `/yacht/AppData/Config`) that auto-fill from server settings.

**ARM devices:** If graphs aren't showing, add `cgroup_memory=1 cgroup_enable=memory` to `/boot/cmdline.txt` and reboot.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **Alpha software** — risk of data loss; not suitable for production-critical environments
- **Docker socket mount** — required for container management; grants significant host access
- **Change default password immediately** — `admin@yacht.local` / `pass` is publicly known
- **New version in progress** — active development has moved to https://github.com/Yacht-Docker-Container; the current repo is in maintenance mode
- **Docs at dev.yacht.sh** — the main yacht.sh website is outdated; use `dev.yacht.sh` for current installation instructions

---

## Links
- GitHub: https://github.com/SelfhostedPro/Yacht
- New version (in progress): https://github.com/Yacht-Docker-Container
- Docs: https://dev.yacht.sh
- Docker Hub: https://hub.docker.com/r/selfhostedpro/yacht

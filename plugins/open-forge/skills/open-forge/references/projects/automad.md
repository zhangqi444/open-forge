# Automad

**Flat-file CMS and template engine — no database required.**
Official site: https://automad.org
GitHub: https://github.com/marcantondahmen/automad

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker (single container) | Nginx + PHP 8.3 bundled in image |
| Any Linux | Bare metal (Composer) | PHP 8+ required |
| Any Linux | Bare metal (manual) | Download dist bundle, extract to web root |

---

## Inputs to Collect

### All phases
- `DOMAIN` — public hostname (e.g. `automad.example.com`)
- `DATA_DIR` — host path for site data (e.g. `/opt/automad/app`)
- `PORT` — host port to expose (default `80`)

---

## Software-Layer Concerns

### Config
- All site data stored under `/app` inside container (flat files, no database)
- First admin account is auto-created on first run; credentials logged by the container

### Data
- No database — content stored as flat files
- Mount host directory to `/app` in container for persistence

### Ports
- Default: `80` (HTTP)

### Docker run
```bash
docker run -dp 80:80 -v ./app:/app --name mysite automad/automad:v2
```
View initial credentials:
```bash
docker logs mysite
```

---

## Upgrade Procedure

1. `docker pull automad/automad:v2`
2. `docker stop mysite && docker rm mysite`
3. Re-run with same `-v ./app:/app` mount
4. Check logs for any migration notices: `docker logs mysite`

---

## Gotchas

- This repo contains source code only; Docker image is the distribution build
- PHP process must have write access to the document root and all subdirectories
- Pull requests to the main repo are not accepted upstream; contributions go via language packs or discussions

---

## References
- [Documentation](https://automad.org)
- [Docker Hub](https://hub.docker.com/r/automad/automad)
- [GitHub README](https://github.com/marcantondahmen/automad#readme)

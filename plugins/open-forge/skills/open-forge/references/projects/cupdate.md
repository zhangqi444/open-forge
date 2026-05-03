# Cupdate

**What it is:** Zero-config container image update tracker for Docker, Podman, and Kubernetes. Automatically discovers all container images in use, identifies the latest available versions, and presents results via a web UI, REST API, and RSS feed. Also performs vulnerability scanning via Docker Scout, Quay/Clair, GitHub Advisories, and osv.dev. Does **not** apply updates — it only reports them.

**Official URL:** https://github.com/AlexGustafsson/cupdate  
**Live demo:** https://alexgustafsson.github.io/cupdate

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux Docker host | Docker Compose | Recommended for Docker setups |
| Kubernetes | Kubectl / Helm | See `docs/kubernetes/README.md` |
| Podman host | Docker Compose (socket compat) | Podman support is beta |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | Docker socket path | Usually `/var/run/docker.sock` |
| Deploy | Cache/DB directory | Mounted at `./data`; stores BoltDB cache and SQLite DB |
| Deploy | Host port | Default `8080` |
| Optional | `CUPDATE_DOCKER_HOST` | Docker socket path (default `unix:///var/run/docker.sock`) |
| Optional | `CUPDATE_DOCKER_INCLUDE_ALL_CONTAINERS` | Set `true` to process stopped containers too |
| Optional | `CUPDATE_CACHE_PATH` | BoltDB cache file path (default `/var/run/data/cachev1.boltdb`) |
| Optional | `CUPDATE_DB_PATH` | SQLite database path (default `/var/run/data/dbv1.sqlite`) |
| Optional | `CUPDATE_LOGOS_PATH` | Directory for cached image logos |

---

## Software-Layer Concerns

### Docker image
Use a pinned released version — **`latest` tracks `main` and may be unstable**:
```
ghcr.io/alexgustafsson/cupdate:0.24.5
```
Check [releases](https://github.com/AlexGustafsson/cupdate/releases) for the current stable tag.

### docker-compose.yml
```yaml
services:
  cupdate:
    image: ghcr.io/alexgustafsson/cupdate:0.24.5
    ports:
      - 8080:8080
    environment:
      CUPDATE_DOCKER_HOST: unix:///var/run/docker.sock
      CUPDATE_CACHE_PATH: /var/run/data/cachev1.boltdb
      CUPDATE_DB_PATH: /var/run/data/dbv1.sqlite
      CUPDATE_LOGOS_PATH: /var/run/data/logos
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./data:/var/run/data
      - target: /tmp
        type: tmpfs
```

### TLS / remote Docker hosts
If pointing at a remote Docker daemon over TLS, set `CUPDATE_DOCKER_TLS_PATH` to a directory containing `ca.pem`, `cert.pem`, and `key.pem`. For single-host setups the socket mount is sufficient.

### Kubernetes
See [docs/kubernetes/README.md](https://github.com/AlexGustafsson/cupdate/blob/main/docs/kubernetes/README.md) for RBAC, ServiceAccount, and Deployment manifests.

---

## Upgrade Procedure

```bash
# Update the image tag in docker-compose.yml to the new version
docker compose pull
docker compose up -d
```

Data persists in `./data`. Check release notes — cache/DB schema versions are embedded in filenames (`cachev1`, `dbv1`); a schema bump requires a new filename path.

---

## Gotchas

- **Do not use `latest` tag** — it tracks the `main` branch which may be unstable; always pin to a release tag
- **Read-only socket** — mount Docker socket as `:ro`; Cupdate only reads container/image metadata, it never modifies containers
- **Does not apply updates** — Cupdate is intentionally discovery-only; use Watchtower, Diun, or your CI pipeline to apply updates
- **tmpfs required** — the compose file mounts `/tmp` as tmpfs; this is needed for temporary image processing; include it
- **Podman beta** — Podman support requires Docker socket compatibility mode (`podman system service`); Podman-native socket is not yet supported

---

## Links

- GitHub: https://github.com/AlexGustafsson/cupdate
- Docker setup guide: https://github.com/AlexGustafsson/cupdate/blob/main/docs/docker/README.md
- Config reference: https://github.com/AlexGustafsson/cupdate/blob/main/docs/config.md
- Kubernetes setup: https://github.com/AlexGustafsson/cupdate/blob/main/docs/kubernetes/README.md
- Live demo: https://alexgustafsson.github.io/cupdate

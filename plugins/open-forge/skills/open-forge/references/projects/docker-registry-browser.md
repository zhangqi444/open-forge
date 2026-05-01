# Docker Registry Browser

**Web UI for Docker Registry HTTP API V2 — browse repositories and tags, view image details, and delete tags through a clean Rails interface.**
GitHub: https://github.com/klausmeyer/docker-registry-browser
Docs: https://github.com/klausmeyer/docker-registry-browser/blob/master/docs/README.md

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Kubernetes | Helm | Chart at klausmeyer/helm-charts |

---

## Inputs to Collect

### Required
- `SECRET_KEY_BASE` — generate with `openssl rand -hex 64`
- Docker registry URL to connect to

---

## Software-Layer Concerns

### Docker run
```bash
docker run --name registry-browser \
  -e SECRET_KEY_BASE="$(openssl rand -hex 64)" \
  -e DOCKER_REGISTRY_URL="http://your-registry:5000" \
  -p 8080:8080 \
  klausmeyer/docker-registry-browser
```

### Docker Compose
```yaml
services:
  registry-browser:
    image: klausmeyer/docker-registry-browser
    container_name: registry-browser
    environment:
      - SECRET_KEY_BASE=your-secret-key-base
      - DOCKER_REGISTRY_URL=http://your-registry:5000
    ports:
      - "8080:8080"
    restart: unless-stopped
```

### Ports
- `8080` — web UI

### Full configuration options
See docs: https://github.com/klausmeyer/docker-registry-browser/blob/master/docs/README.md

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- `SECRET_KEY_BASE` is required — app will not start without it
- Registry must have the HTTP API V2 enabled and be reachable from the container
- Tag deletion requires the registry to have `REGISTRY_STORAGE_DELETE_ENABLED=true`

---

## References
- Documentation: https://github.com/klausmeyer/docker-registry-browser/blob/master/docs/README.md
- Helm chart: https://github.com/klausmeyer/helm-charts/tree/master/charts/docker-registry-browser
- GitHub: https://github.com/klausmeyer/docker-registry-browser#readme

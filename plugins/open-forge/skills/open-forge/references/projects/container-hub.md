# Container Hub (Docker Registry UI)

> Simple, lightweight browser UI for exploring and managing Docker/OCI container registries — browse repositories, view tags, inspect manifests, delete images, and manage multiple registries from one interface.

**URL:** https://github.com/eznix86/docker-registry-ui
**Source:** https://github.com/eznix86/docker-registry-ui
**License:** Not specified in README (check repository root)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any   | Docker Compose | Official image: `ghcr.io/eznix86/docker-registry-ui:latest` |
| Kubernetes | Helm chart | `helm repo add docker-registry-ui https://eznix86.github.io/docker-registry-ui` |

## Inputs to Collect

### Provision phase
- URL(s) of your existing Docker/OCI registry (e.g. `http://registry:5000` or `https://registry.example.com`)
- Registry credentials (if the registry requires authentication)

### Deploy phase
- `REGISTRY_URL` — primary registry URL
- `REGISTRY_AUTH` — base64-encoded `username:password` for the primary registry (optional for unauthenticated registries since v0.3.2)
- Additional registries: `REGISTRY_URL_<SUFFIX>` / `REGISTRY_AUTH_<SUFFIX>` for each additional registry

## Software-layer Concerns

### Docker Compose
```yaml
services:
  registry-ui:
    image: ghcr.io/eznix86/docker-registry-ui:latest
    restart: unless-stopped
    ports:
      - "8011:80"
    environment:
      - REGISTRY_URL=http://your-registry.com:5000
      - REGISTRY_AUTH=base64basicauthhere
      # Multiple registries (optional):
      # - REGISTRY_URL_PERSONAL=https://registry2.example.com
      # - REGISTRY_AUTH_PERSONAL=base64creds2
```

### Kubernetes (Helm)
```sh
helm repo add docker-registry-ui https://eznix86.github.io/docker-registry-ui
helm repo update
helm install docker-registry-ui docker-registry-ui/docker-registry-ui \
  -n docker-registry-ui \
  --create-namespace

# Pass credentials via secret:
kubectl create secret generic registry-ui-secret \
  -n docker-registry-ui \
  --from-literal=url="http://your-registry.com:5000" \
  --from-literal=auth="$(echo -n 'username:password' | base64)"
```

### Config / env vars
- `REGISTRY_URL`: primary registry URL (required)
- `REGISTRY_AUTH`: base64(`username:password`) for primary registry; omit for unauthenticated registries (v0.3.2+)
- `REGISTRY_URL_<SUFFIX>` / `REGISTRY_AUTH_<SUFFIX>`: additional registries — any unique suffix (e.g. `_PERSONAL`, `_GHCR`)
- GitHub Container Registry (v0.5.0+): set `REGISTRY_URL_GHCR=https://ghcr.io` and `REGISTRY_AUTH_GHCR=base64(github-username:PAT)` — PAT needs `delete:packages, repo, write:packages`

### Generating base64 auth
```bash
echo -n "username:password" | base64
# result: dXNlcm5hbWU6cGFzc3dvcmQ=
```

### Data dirs
- No persistent data; stateless — no volumes required

## Upgrade Procedure
```bash
docker compose pull
docker compose up -d
```

## Gotchas
- **Requires an existing registry** — Container Hub is a UI only; you must have a Docker Registry v2 (or OCI-compatible) registry running separately.
- **Storage reclamation is manual** — deleting images via the UI only marks them deleted; run registry garbage collection to actually free disk space:
  ```bash
  bin/registry garbage-collect --delete-untagged /etc/docker/registry/config.yml
  ```
- **Pre-v1.0.0 scalability** — the current release does not scale well for registries with 100+ tags per repository; a v1.0.0 rewrite is in progress (see [issue #28](https://github.com/eznix86/docker-registry-ui/issues/28)).
- `REGISTRY_AUTH` is optional (omittable) for unauthenticated registries from v0.3.2 onward.
- The UI is served on port `80` inside the container; map to any host port.

## Links
- [README](https://github.com/eznix86/docker-registry-ui/blob/main/README.md)
- [GitHub Container Registry image](https://github.com/eznix86/docker-registry-ui/pkgs/container/docker-registry-ui)
- [Helm chart repo](https://eznix86.github.io/docker-registry-ui)
- [Docker Registry garbage collection docs](https://distribution.github.io/distribution/about/garbage-collection/)

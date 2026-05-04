---
name: gitness
description: Recipe for Gitness (Harness Open Source) — open-source DevOps platform with code hosting, CI/CD pipelines, Gitspaces, and artifact registry. Successor to Drone CI.
---

# Gitness (Harness Open Source)

Open-source developer platform combining source code hosting, automated CI/CD pipelines, cloud development environments (Gitspaces), and artifact registries. Evolved from Drone CI — Harness Open Source is the next generation of Drone, with broader scope. Drone CI itself is maintained on a feature branch while the main platform evolves. Upstream: <https://github.com/harness/gitness>. Docs: <https://developer.harness.io/docs/open-source>. Docker Hub: <https://hub.docker.com/r/harness/harness>. License: Apache-2.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | <https://github.com/harness/gitness#running-harness-locally> | Yes | Recommended for evaluation and small teams |
| Docker with bind mount | <https://developer.harness.io/docs/open-source> | Yes | Production; persists data outside the container |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Host data directory for Harness data? | Absolute path (e.g. /data/harness) | Recommended for persistence; default /tmp/harness is ephemeral |
| infra | Port for Harness Web UI? | Port number (default 3000) | All |
| infra | Port for Harness SSH (Git over SSH)? | Port number (default 3022) | Optional; needed for git+ssh clone support |
| software | Public URL/hostname? | HTTPS URL | Production; needed for OAuth callbacks, clone URLs |

## Software-layer concerns

### Docker (quickstart)

```bash
docker run -d \
  -p 3000:3000 \
  -p 3022:3022 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/harness:/data \
  --name harness \
  --restart always \
  harness/harness
```

Then visit http://localhost:3000 and complete setup.

Key mounts:
- `/var/run/docker.sock`: Required for CI pipeline execution (pipelines run containers via Docker)
- `/data`: All persistent data (database, repositories, artifacts)

> Using a bind mount for /data is strongly recommended. The default /tmp/harness is ephemeral and will be lost when the container is removed.

### Docker Compose

```yaml
services:
  harness:
    image: harness/harness
    container_name: harness
    restart: always
    ports:
      - "3000:3000"   # Web UI + API
      - "3022:3022"   # Git over SSH
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - harness-data:/data
    environment:
      - GITNESS_URL_BASE=https://harness.example.com   # set your public URL

volumes:
  harness-data:
```

### Key environment variables

| Variable | Description |
|---|---|
| GITNESS_URL_BASE | Public base URL — used for clone URLs, webhooks, OAuth callbacks |
| GITNESS_DATABASE_DRIVER | Database driver: sqlite3 (default) or postgres |
| GITNESS_DATABASE_DATASOURCE | DSN for non-SQLite databases |
| GITNESS_PRINCIPAL_ADMIN_EMAIL | Admin account email (first-run) |
| GITNESS_PRINCIPAL_ADMIN_PASSWORD | Admin account password (first-run) |

### Pipeline syntax

Harness Open Source uses a YAML pipeline format (`.harness/pipeline.yaml`):

```yaml
pipeline:
  stages:
    - stage:
        type: CI
        spec:
          cloneCodebase: true
          platform:
            os: Linux
            arch: Amd64
          runtime:
            type: Docker
            spec: {}
          execution:
            steps:
              - step:
                  type: Run
                  name: test
                  spec:
                    connectorRef: account.harnessImage
                    image: golang:1.21
                    command: go test ./...
```

## Upgrade procedure

```bash
docker pull harness/harness
docker compose up -d   # or docker stop/rm/run with same flags
```

Review the GitHub releases page at <https://github.com/harness/gitness/releases> before upgrading.

## Gotchas

- Docker socket mount required: CI pipelines need access to `/var/run/docker.sock` to run build containers. This is a security trade-off — the container effectively has root on the host via Docker.
- SQLite by default: fine for small teams; switch to PostgreSQL for larger deployments or high concurrency.
- Drone CI users: Drone pipeline YAML is not directly compatible with Harness Open Source pipelines. Migration work is required. Drone itself lives on the `drone` branch of this repo.
- Active development: Harness Open Source is evolving rapidly. Pipeline feature parity with Drone is a work-in-progress — check the roadmap before committing for production CI use.
- Gitspaces: the cloud development environment feature may require additional infrastructure (Kubernetes).

## Drone CI note

Drone CI is maintained as a feature branch (`drone`) of this repo: <https://github.com/harness/gitness/tree/drone>. It continues to receive updates. If you specifically need Drone's pipeline compatibility, the Drone branch is still available, but new self-hosters are encouraged to start with Harness Open Source.

## Links

- GitHub: <https://github.com/harness/gitness>
- Docs (Open Source): <https://developer.harness.io/docs/open-source>
- Docker Hub: <https://hub.docker.com/r/harness/harness>
- Releases: <https://github.com/harness/gitness/releases>
- Drone CI docs: <https://docs.drone.io/>

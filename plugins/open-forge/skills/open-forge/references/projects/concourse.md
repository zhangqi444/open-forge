---
name: concourse
description: Concourse recipe for open-forge. Open-source CI/CD automation system. Pipeline-as-code with strong opinions on idempotency, immutability, and reproducibility. Stateless workers.
---

# Concourse

Open-source CI/CD automation system written in Go. Built around strong opinions: idempotency, immutability, declarative YAML pipelines, stateless workers, and reproducible builds. Scales from simple to complex multi-pipeline setups. Upstream: <https://github.com/concourse/concourse>. Docs: <https://concourse-ci.org/docs.html>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (quickstart) | Local dev / small teams |
| Helm (Kubernetes) | Production; scalable workers |
| Binary (`concourse web` + `concourse worker`) | Bare-metal / custom orchestration |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "External URL for Concourse?" | `CONCOURSE_EXTERNAL_URL`; needed for GitHub OAuth redirects and fly login |
| preflight | "Admin username and password?" | `CONCOURSE_ADD_LOCAL_USER` |
| preflight | "Session signing key / worker key?" | Auto-generated in Docker Compose quickstart |

## Docker Compose quickstart

```bash
# Download the official quickstart compose file
wget https://concourse-ci.org/docker-compose.yml

# Generate keys
docker run --rm -v "$PWD/keys:/keys" \
  concourse/concourse generate-key -t rsa -f /keys/session_signing_key
docker run --rm -v "$PWD/keys:/keys" \
  concourse/concourse generate-key -t ssh -f /keys/tsa_host_key
docker run --rm -v "$PWD/keys:/keys" \
  concourse/concourse generate-key -t ssh -f /keys/worker_key
cp keys/worker_key.pub keys/authorized_worker_keys

docker compose up -d
```

Or use the single-file compose from upstream: <https://concourse-ci.org/quick-start.html>

Key environment variables in compose:
```yaml
CONCOURSE_EXTERNAL_URL: http://localhost:8080
CONCOURSE_ADD_LOCAL_USER: admin:changeme
CONCOURSE_MAIN_TEAM_LOCAL_USER: admin
CONCOURSE_WORKER_BAGGAGECLAIM_DRIVER: overlay
```

- UI: http://localhost:8080
- Default credentials: `admin` / `changeme`

## fly CLI

```bash
# Install fly (must match server version)
fly -t local login -c http://localhost:8080 -u admin -p changeme

# Set a pipeline
fly -t local set-pipeline -p my-pipeline -c pipeline.yml

# Unpause and trigger
fly -t local unpause-pipeline -p my-pipeline
fly -t local trigger-job -j my-pipeline/my-job
```

## Pipeline example (pipeline.yml)

```yaml
jobs:
  - name: hello
    plan:
      - task: say-hello
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: { repository: alpine }
          run:
            path: echo
            args: ["Hello, world!"]
```

## Software-layer concerns

- Port: `8080` (web UI + API)
- Worker runs builds in containers (Linux/Windows); requires Docker or containerd
- Resources: Concourse's first-class abstraction for inputs/outputs (git repos, S3 buckets, Docker images, etc.)
- Credential management: integrates with Vault, Credhub, AWS SSM, Kubernetes secrets
- Stateless workers: workers can be replaced, scaled, or paused without losing pipeline state

## Upgrade procedure

1. Pull new images: `docker compose pull`
2. Restart: `docker compose up -d`
3. Fly CLI must match server version — download matching `fly` after upgrade

## Gotchas

- `fly` CLI must be the same version as the Concourse server — always re-download after upgrading
- `CONCOURSE_EXTERNAL_URL` must be reachable by workers and OAuth callbacks — use actual hostname in production
- Worker requires `privileged` containers or specific kernel capabilities for some build operations
- Keys (TSA, session, worker) must be stable — regenerating them invalidates all active sessions and worker registrations

## Links

- GitHub: <https://github.com/concourse/concourse>
- Docs: <https://concourse-ci.org/docs.html>
- Quick start: <https://concourse-ci.org/quick-start.html>
- Docker Hub: <https://hub.docker.com/r/concourse/concourse>

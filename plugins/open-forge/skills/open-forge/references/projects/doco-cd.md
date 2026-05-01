---
name: Doco CD
description: "Lightweight GitOps CD tool for Docker Compose and Swarm. Go. Docker. kimdre/doco-cd. Webhook + polling, external secrets (SOPS/Vault/AWS), Prometheus metrics, notifications, distroless image."
---

# Doco CD

**Lightweight GitOps continuous delivery for Docker Compose and Swarm.** Think "simple Portainer or ArgoCD for Docker Compose." Watch a git repository; when the compose file changes, Doco CD pulls and redeploys automatically — via webhooks (instant) or polling (periodic). External secret management (SOPS, Vault, AWS SM, GCP SM, Azure KV), Prometheus metrics, notifications (Apprise-compatible), Swarm mode, minimal RAM/CPU usage, distroless image.

Built + maintained by **kimdre**. Apache 2.0 license.

- Upstream repo: <https://github.com/kimdre/doco-cd>
- Docs: <https://doco.cd/latest/>
- Docker Hub: `ghcr.io/kimdre/doco-cd`

## Architecture in one minute

- **Go** binary — single container, minimal footprint
- Reads a git repository containing `docker-compose.yml` files
- Connects to **Docker socket** to deploy/update stacks
- Webhooks receiver: GitHub, GitLab, Gitea, Bitbucket → instant deploy on push
- Polling: periodic git pull fallback for repos without webhooks
- External secrets: SOPS, HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, Azure Key Vault
- Distroless base image — minimal attack surface
- Resource: **tiny** — Go binary, event-driven polling

## Compatible install methods

| Infra        | Runtime                         | Notes                                                     |
| ------------ | ------------------------------- | --------------------------------------------------------- |
| **Docker**   | `ghcr.io/kimdre/doco-cd`        | **Primary** — GHCR; distroless image                      |

## Inputs to collect

| Input                           | Example                               | Phase    | Notes                                                                                        |
| ------------------------------- | ------------------------------------- | -------- | -------------------------------------------------------------------------------------------- |
| Docker socket                   | `/var/run/docker.sock`                | Docker   | Mount into container; Doco CD needs it to deploy stacks                                     |
| Git repo URL(s)                 | `https://github.com/you/infra.git`    | Config   | Repo(s) containing docker-compose files; configured in Doco CD config                       |
| Git credentials (if private)    | personal access token / SSH key       | Auth     | For private repos                                                                            |
| Webhook secret                  | random string                         | Auth     | Shared secret between git provider and Doco CD for webhook validation                       |
| External secret provider (opt.) | SOPS key / Vault address              | Secrets  | For secrets not committed to git                                                             |
| Notification URL (opt.)         | Apprise URL                           | Notify   | For deploy success/failure notifications                                                     |

## Install via Docker Compose

```yaml
services:
  doco-cd:
    image: ghcr.io/kimdre/doco-cd:latest
    container_name: doco-cd
    restart: unless-stopped
    ports:
      - "3000:3000"    # webhook receiver port
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./doco-cd-config:/config
    environment:
      - LOG_LEVEL=info
```

Then configure repos and auth in the Doco CD config file (YAML). Full config reference: <https://doco.cd/latest/>

## How it works

1. **Configure** which git repos to watch (containing docker-compose files) and where to deploy them.
2. **Push** a change to your compose file in git.
3. **Webhook fires** (or polling detects the change).
4. **Doco CD** clones/pulls the repo → `docker compose up -d` on the target host.
5. **Notification** sent (if configured).

## Supported git providers

GitHub, GitLab, Gitea, Bitbucket (and any provider with standard webhook formats).

## Supported external secret providers

| Provider | Notes |
|----------|-------|
| SOPS | File-level encryption; supports age, PGP, AWS KMS, GCP KMS, Azure Key Vault |
| HashiCorp Vault | Dynamic secrets |
| AWS Secrets Manager | Cloud secrets |
| GCP Secret Manager | Cloud secrets |
| Azure Key Vault | Cloud secrets |

## Gotchas

- **Docker socket access = full Docker control.** Doco CD needs the Docker socket to deploy stacks. Like any tool with socket access, it can create/destroy containers. Mount `:ro` for check-only or use a socket proxy with appropriate permissions.
- **Declarative only — what's in git is what's deployed.** Doco CD is GitOps: the git repo is the source of truth. Manual `docker compose` changes on the host will be overwritten on next deploy. Commit everything to git.
- **Swarm mode.** For Docker Swarm stacks, enable Swarm mode in Doco CD config. Deploys become `docker stack deploy` instead of `docker compose up`.
- **Distroless image.** The base image has no shell — you can't `docker exec -it doco-cd sh`. Use `docker logs doco-cd` for debugging or switch to a debug-tagged image temporarily.
- **Polling vs webhooks.** Webhooks are instant; polling is the fallback (and useful for repos that don't support webhooks, e.g. internal git servers). Configure both for reliability.
- **SOPS + age is the simplest secret approach.** Age is a modern encryption tool — generate a key pair, encrypt secrets with `sops`, commit encrypted files to git, give Doco CD the private key. The encrypted file is safe to commit.
- **Multiple repos.** Doco CD can watch multiple repositories simultaneously — useful for monorepo-style infra repos or separate service repos.
- **Prometheus metrics.** Exposed for deploy counts, durations, failure rates. Scrape with Prometheus + Grafana for GitOps observability.
- **Documentation moved.** The GitHub wiki is deprecated — all docs are at <https://doco.cd/latest/>. Old wiki links don't work.

## Project health

Active Go development, GHCR CI (distroless image), CodeQL, vulnerability scanning, Prometheus metrics, SOPS + multi-cloud secrets support. Solo-maintained by kimdre. Apache 2.0.

## GitOps-for-Compose-family comparison

- **Doco CD** — Go, Docker Compose + Swarm, webhooks + polling, external secrets, distroless, Prometheus
- **Watchtower** — Go, image auto-update daemon; no git integration; simpler
- **Portainer** — full management UI; GitOps via Stacks + git integration; heavier
- **ArgoCD** — Kubernetes-native; not for Compose
- **Flux CD** — Kubernetes-native; not for Compose

**Choose Doco CD if:** you want lightweight GitOps CD for Docker Compose or Swarm — push to git, auto-deploy — without the weight of Portainer or the K8s requirement of ArgoCD/Flux.

## Links

- Repo: <https://github.com/kimdre/doco-cd>
- Docs: <https://doco.cd/latest/>
- External secrets: <https://doco.cd/latest/External-Secrets/>
- Notifications: <https://doco.cd/latest/Advanced/Notifications/>
- Portainer (heavier alt): <https://portainer.io>

---
name: stackstorm
description: StackStorm recipe for open-forge. Event-driven automation platform (IFTTT for ops). Self-hosted via Docker Compose or Linux packages. Source: https://github.com/StackStorm/st2. Docs: https://docs.stackstorm.com.
---

# StackStorm

Event-driven automation platform — "IFTTT for Ops". Connects sensors (event sources) to triggers, rules, workflows, and actions across your infrastructure. Think: Slack message triggers a workflow that provisions a server, runs tests, and posts results. Upstream: <https://github.com/StackStorm/st2>. Docs: <https://docs.stackstorm.com>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal (Ubuntu) | Docker Compose | Recommended quick-start; all services containerised |
| VPS / bare metal (Ubuntu 20.04/22.04) | Native packages (deb) | Production path per upstream; installer script available |
| Local dev | Docker Compose | docker-compose.yml in st2-docker repo |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Docker Compose or native packages?" | Drives install path |
| credentials | "ST2 admin username?" | Default: st2admin |
| credentials | "ST2 admin password?" | Set strong password; cannot be empty |
| smtp | "SMTP config for notifications?" | Optional; used by st2-notify action |
| domain | "Public domain or IP?" | For HTTPS setup if exposing ST2 Web UI externally |

## Software-layer concerns

- Components: st2 (core), st2web (UI), MongoDB (metadata), RabbitMQ (message bus), PostgreSQL (history), Redis (coordination)
- Default ports: 443 (NGINX + HTTPS), 80 (redirect), API at /api, auth at /auth
- Config path (native): /etc/st2/st2.conf
- Packs: the unit of automation — install with st2 pack install <pack-name> from StackStorm Exchange
- st2 CLI: primary management tool; also available as REST API and Web UI
- Logs: /var/log/st2/ (native), docker compose logs (Docker)

### Docker Compose quick-start (from st2-docker)

```bash
git clone https://github.com/StackStorm/st2-docker.git
cd st2-docker
cp conf/stackstorm.env.example conf/stackstorm.env
# Edit conf/stackstorm.env — set ST2_USER, ST2_PASSWORD
docker compose up -d
```

Upstream Docker Compose repo: https://github.com/StackStorm/st2-docker

### Native install (Ubuntu 22.04)

```bash
curl -sSL https://stackstorm.com/packages/install.sh | bash -s -- --user=st2admin --password=<password>
```

Upstream install docs: https://docs.stackstorm.com/install/index.html

## Upgrade procedure

1. Review changelog: https://github.com/StackStorm/st2/blob/master/CHANGELOG.md
2. Docker: update image tags in docker-compose.yml, docker compose pull, docker compose up -d
3. Native: sudo apt-get update && sudo apt-get install --only-upgrade st2 st2web st2chatops
4. After upgrade: st2ctl restart && st2 --version

## Gotchas

- Resource hungry: full stack (MongoDB + RabbitMQ + PostgreSQL + Redis + multiple st2 services) needs 4 GB RAM minimum; 8 GB recommended for production.
- Pack dependencies: packs are Python virtualenvs; system Python must not conflict. Use the pack virtualenv isolation (on by default).
- RabbitMQ memory: set vm_memory_high_watermark in RabbitMQ config to avoid OOM disconnects under heavy load.
- API tokens: generate per-service tokens (st2 apikey create) rather than using admin creds in automation.
- RBAC: Role-based access control is available but must be explicitly configured; not enabled by default.
- ChatOps: st2chatops is a separate service bridging Slack/HipChat/etc.; optional but popular.
- st2 pack install: requires outbound internet access from the st2 container/host to StackStorm Exchange (https://exchange.stackstorm.org).

## Links

- Upstream repo: https://github.com/StackStorm/st2
- Docker Compose repo: https://github.com/StackStorm/st2-docker
- Docs: https://docs.stackstorm.com
- Pack Exchange: https://exchange.stackstorm.org
- Install guide: https://docs.stackstorm.com/install/index.html
- Release notes: https://github.com/StackStorm/st2/releases

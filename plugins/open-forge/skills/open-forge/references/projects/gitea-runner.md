---
name: gitea-runner
description: Recipe for Gitea Runner (act_runner) — self-hosted CI runner for Gitea Actions, compatible with GitHub Actions workflow syntax.
---

# Gitea Runner (act_runner)

The official CI runner for Gitea Actions. Executes GitHub Actions-compatible workflows (`.gitea/workflows/*.yaml`) on your self-hosted Gitea instance. Runs jobs in Docker containers (default), on the host directly, or in other environments. Based on `nektos/act`. Source: <https://gitea.com/gitea/runner>. Docs: <https://docs.gitea.com/usage/actions/act-runner>. License: MIT.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.gitea.com/usage/actions/act-runner> | Yes | Recommended; runner + Docker-in-Docker |
| Binary | <https://dl.gitea.com/gitea-runner/> | Yes | Bare-metal; runs as a systemd service |
| Docker image | <https://hub.docker.com/r/gitea/act_runner> | Yes | Containerized runner |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| software | Gitea instance URL? | HTTP(S) URL (e.g. https://gitea.example.com) | Required — runner registers against this URL |
| software | Runner registration token? | String from Gitea admin panel | Required; get from Site Admin > Actions > Runners |
| software | Runner name? | String (default: hostname) | Optional |
| software | Runner labels? | Comma-separated (default: ubuntu-latest:docker://...) | Optional; controls which jobs this runner accepts |

## Prerequisites — enable Actions in Gitea

Actions are disabled by default. Add to `app.ini`:

```ini
[actions]
ENABLED = true
```

Then restart Gitea. Get the runner token from: `https://your-gitea.example.com/-/admin/actions/runners`

## Software-layer concerns

### Docker Compose (runner + DinD)

```yaml
services:
  runner:
    image: gitea/act_runner:nightly
    environment:
      CONFIG_FILE: /config.yaml
      GITEA_INSTANCE_URL: https://gitea.example.com
      GITEA_RUNNER_REGISTRATION_TOKEN: <your_token>
      GITEA_RUNNER_NAME: my-runner
      GITEA_RUNNER_LABELS: ""
    volumes:
      - ./runner-config.yaml:/config.yaml
      - runner-data:/data
      - /var/run/docker.sock:/var/run/docker.sock   # for Docker executor
    restart: unless-stopped

volumes:
  runner-data:
```

> Mounting `/var/run/docker.sock` allows the runner to spin up Docker containers for each job. This gives the runner root-equivalent access to the host via Docker — see security gotchas.

### runner-config.yaml (optional overrides)

```yaml
# Generate default config: docker run --rm gitea/act_runner:nightly generate-config > runner-config.yaml
log:
  level: info

runner:
  capacity: 5              # max parallel jobs
  timeout: 3h
  insecure: false          # set true only for self-signed Gitea TLS
  fetch_timeout: 5s
  fetch_interval: 2s

cache:
  enabled: true
  dir: ""
  host: ""
  port: 0

container:
  network: "bridge"
  privileged: false
  options:                 # extra docker run args
  valid_volumes: []        # restrict volume mounts in workflows
```

### Registration (one-time, CLI)

```bash
# Interactive
./gitea-runner register

# Non-interactive
./gitea-runner register \
  --instance https://gitea.example.com \
  --token <registration_token> \
  --name my-runner \
  --no-interactive
```

After registration, a `.runner` file is created in the working directory — keep it; it contains the runner's credentials.

### Run as systemd service (binary install)

```ini
[Unit]
Description=Gitea Runner
After=network.target

[Service]
ExecStart=/usr/local/bin/gitea-runner daemon --config /etc/gitea-runner/config.yaml
WorkingDirectory=/var/lib/gitea-runner
Restart=always
User=gitea-runner

[Install]
WantedBy=multi-user.target
```

## Upgrade procedure

```bash
# Docker
docker compose pull && docker compose up -d

# Binary: download new version from https://dl.gitea.com/gitea-runner/
# and replace the binary; restart the service
```

## Gotchas

- Docker socket security: mounting `/var/run/docker.sock` gives the runner root-equivalent access on the host. Use with caution on shared hosts; consider using dedicated VMs or Kubernetes for untrusted workflows.
- Registration token vs runner token: the registration token is one-time and used to register. After registration, the runner uses a separate token stored in `.runner`.
- Labels control job assignment: labels like `ubuntu-latest:docker://...` tell Gitea which `runs-on:` values this runner accepts. Leave blank to use defaults.
- `capacity`: limits parallel jobs per runner instance. Default is conservative — increase if your host has resources.
- Actions syntax: Gitea Actions is largely GitHub Actions-compatible but not 100%. Some marketplace actions may not work. See <https://docs.gitea.com/usage/actions/comparison> for differences.
- Nightly vs latest tag: use `nightly` for latest features; use a pinned version tag for stability.

## Links

- Source (Gitea): <https://gitea.com/gitea/runner>
- Docs: <https://docs.gitea.com/usage/actions/act-runner>
- Docker Hub: <https://hub.docker.com/r/gitea/act_runner>
- Binary downloads: <https://dl.gitea.com/gitea-runner/>
- GitHub Actions compatibility: <https://docs.gitea.com/usage/actions/comparison>
- nektos/act (underlying engine): <https://github.com/nektos/act>

---
name: gitlab-ce
description: Recipe for GitLab Community Edition — open-source DevOps platform with Git hosting, CI/CD, issue tracking, wikis, and container registry.
---

# GitLab Community Edition (CE)

Comprehensive open-source DevOps platform: Git repository hosting, merge requests, CI/CD pipelines, container registry, issue tracking, wikis, and more. Used by 100,000+ organizations. Open-core: CE is MIT-licensed; Enterprise Edition (EE) adds paid features. Upstream: <https://gitlab.com/gitlab-org/gitlab>. GitHub mirror: <https://github.com/gitlabhq/gitlabhq>. Docs: <https://docs.gitlab.com>. License: MIT (CE). ~24K stars on GitHub mirror.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (official image) | <https://docs.gitlab.com/install/docker/installation/> | Yes | Recommended containerized install |
| Linux package (Omnibus) | <https://docs.gitlab.com/install/package/> | Yes | Recommended bare-metal/VM install; batteries included |
| Helm chart | <https://docs.gitlab.com/charts/> | Yes | Kubernetes (cloud-native GitLab) |
| GitLab Operator | <https://docs.gitlab.com/operator/> | Yes | Kubernetes via Operator pattern |
| Community Docker Compose | <https://github.com/sameersbn/docker-gitlab> | Community | Alternative Compose stack (sameersbn/gitlab) |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | External URL for GitLab? | HTTPS URL (e.g. https://gitlab.example.com) | Required — used for clone URLs, OAuth, email links |
| infra | SMTP server for email notifications? | host:port | Optional but recommended |
| infra | SMTP credentials? | username + password | Optional |
| software | Initial root password? | Sensitive string | First-run; min 8 chars |
| software | Time zone? | TZ string | Optional |
| software | Host data directory? | Absolute path | Docker; for config, logs, data |

## Software-layer concerns

### Docker (official, recommended)

```bash
# Create directories
sudo mkdir -p /srv/gitlab/{config,logs,data}
sudo chmod -R 755 /srv/gitlab

docker run -d \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume /srv/gitlab/config:/etc/gitlab \
  --volume /srv/gitlab/logs:/var/log/gitlab \
  --volume /srv/gitlab/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ce:latest
```

Set `external_url` in `/srv/gitlab/config/gitlab.rb` after first start, then `docker exec gitlab gitlab-ctl reconfigure`.

### Docker Compose (official)

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    hostname: gitlab.example.com
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.example.com'
        gitlab_rails['smtp_enable'] = false
        # Add more config here; see https://docs.gitlab.com/install/docker/configuration/
    ports:
      - '80:80'
      - '443:443'
      - '22:22'
    volumes:
      - gitlab-config:/etc/gitlab
      - gitlab-logs:/var/log/gitlab
      - gitlab-data:/var/opt/gitlab
    shm_size: '256m'

volumes:
  gitlab-config:
  gitlab-logs:
  gitlab-data:
```

### Linux package (Omnibus) — Debian/Ubuntu

```bash
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-ce
```

Root password is auto-generated on first install; find it at `/etc/gitlab/initial_root_password` (valid for 24h).

### Key configuration (gitlab.rb / GITLAB_OMNIBUS_CONFIG)

```ruby
# External URL (required)
external_url 'https://gitlab.example.com'

# SMTP (optional)
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.example.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "user@example.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'

# Registry (optional)
registry_external_url 'https://registry.example.com'

# Time zone
gitlab_rails['time_zone'] = 'UTC'
```

Apply changes: `gitlab-ctl reconfigure` (package) or restart container.

### Resource requirements

| Deployment | RAM | CPU | Notes |
|---|---|---|---|
| Minimum (evaluation) | 4 GB | 2 cores | Single user, small repos |
| Small team (up to 20 users) | 8 GB | 4 cores | CI runners on separate hosts recommended |
| Medium team (up to 100 users) | 16 GB | 8 cores | Dedicated PostgreSQL recommended |

## Upgrade procedure

```bash
# Docker
docker pull gitlab/gitlab-ce:latest
docker compose up -d   # or stop/rm/run

# Linux package
sudo apt update && sudo apt install gitlab-ce
```

Always upgrade to the next major version only — do not skip major versions. Check the upgrade path tool: <https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/>

## Gotchas

- Startup time: GitLab takes 3-5 minutes to start all services on first run. Watch `docker logs -f gitlab` or `gitlab-ctl status`.
- Upgrade path: never skip major versions. Use the upgrade path tool to plan multi-step upgrades.
- Memory: GitLab is memory-intensive. 4 GB minimum; 8 GB recommended for any real use.
- SSH port conflict: if port 22 is in use by the host SSH daemon, either change the host SSH port or change GitLab's SSH port to e.g. 2222.
- `shm_size`: the `--shm-size 256m` flag is required to prevent Gitaly from crashing.
- Container registry: requires a separate subdomain and its own TLS cert if used.
- CI runners: GitLab runners are separate containers/processes. Install them separately; see <https://docs.gitlab.com/runner/>.
- License: only CE is MIT. EE features are source-available but require a paid license for production use.

## Links

- GitLab.com source: <https://gitlab.com/gitlab-org/gitlab>
- Docker install docs: <https://docs.gitlab.com/install/docker/installation/>
- Omnibus package docs: <https://docs.gitlab.com/install/package/>
- Upgrade path tool: <https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/>
- Docker Hub: <https://hub.docker.com/r/gitlab/gitlab-ce>
- Community Compose (sameersbn): <https://github.com/sameersbn/docker-gitlab>
- GitLab Runner: <https://docs.gitlab.com/runner/>

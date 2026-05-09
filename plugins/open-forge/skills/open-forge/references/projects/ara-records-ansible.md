---
name: ara-records-ansible
description: ARA Records Ansible recipe for open-forge. Covers standalone local recording (no server), Docker/Podman container install, and the ara_api Ansible role (ara-collection) install methods, based on https://github.com/ansible-community/ara/blob/master/README.md and https://ara.readthedocs.io.
---

# ARA Records Ansible

Ansible run recording, reporting, and visualization tool. Records ansible and ansible-playbook runs to SQLite, MySQL, or PostgreSQL, and provides a REST API and self-hosted web UI for browsing results. Works wherever Ansible runs — laptop, CI/CD, AWX, Semaphore. Upstream: <https://github.com/ansible-community/ara>. Homepage: <https://ara.recordsansible.org>. License: GPL-3.0.

ARA's two-component design: an **Ansible callback plugin** that records playbook runs, and an **API server** that stores and serves data. The callback can write to a local SQLite file without any server; for multi-machine aggregation you run a persistent API server and point the callback at it.

## Compatible install methods

Verified against the upstream README.md and ara.readthedocs.io.

| Method | Upstream | When to use |
|---|---|---|
| Local recording (no server) | README.md §Recording playbooks without an API server | Single machine; SQLite; dev/personal use |
| Docker / Podman API server | README.md §Recording playbooks with an API server | Multi-machine; production; shared dashboard |
| ara_api Ansible role | <https://codeberg.org/ansible-community/ara-collection> | Production; Ansible-managed deployments |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Do you need a persistent API server (for multi-machine recording or a shared dashboard), or just local SQLite recording?" | server / local | Drives method section |
| server only: db | "Which database backend?" | sqlite / mysql / postgresql | SQLite is fine for small teams; use MySQL/PostgreSQL for high-volume recording |
| server only: port | "Which host port should the ARA API server listen on?" | Number | Default 8000 |
| server only: volume | "Path on the host to persist ARA server settings and database?" | Host path | E.g. ~/.ara/server |
| server only: auth | "Enable API authentication? (recommended for public-facing installs)" | Yes / No | See ara.readthedocs.io/en/latest/api-security.html |
| both | "Version of ARA to install/run?" | latest / pin e.g. 1.7.x | Use latest unless you need a specific version |

## Software-layer concerns

### Environment variables (callback side)

Set these before running `ansible-playbook`:

| Var | Description | Default |
|---|---|---|
| `ANSIBLE_CALLBACK_PLUGINS` | Path to ARA's callback plugins dir | Set via `python3 -m ara.setup.callback_plugins` |
| `ARA_API_CLIENT` | `offline` (local SQLite) or `http` (remote server) | `offline` |
| `ARA_API_SERVER` | URL of the API server when `ARA_API_CLIENT=http` | `http://127.0.0.1:8000` |
| `ARA_DEFAULT_DB_PATH` | Path to local SQLite file (offline mode) | `~/.ara/server/ansible.sqlite` |

For permanent config, write to `~/.ara/ara.env` or `/etc/ara/ara.env`.

### Data directory (server)

| Content | Container path |
|---|---|
| Settings / config | `/opt/ara` |
| SQLite database (default) | `/opt/ara/server.sqlite` |

Mount `/opt/ara` as a persistent volume.

### Server config keys (env vars or settings.yaml)

| Key | Default | Notes |
|---|---|---|
| `ARA_ALLOWED_HOSTS` | `["*"]` | Restrict to your domain in production |
| `ARA_CORS_ORIGIN_WHITELIST` | `["http://127.0.0.1:8000"]` | Add your frontend origin when needed |
| `ARA_DEBUG` | `false` | Never enable in production |
| `ARA_DATABASE_ENGINE` | `django.db.backends.sqlite3` | Use `mysql` or `postgresql_psycopg2` for production |
| `ARA_DATABASE_NAME` | `server.sqlite` | Full path for SQLite; DB name for MySQL/PostgreSQL |
| `ARA_LOG_LEVEL` | `INFO` | |

Full settings reference: <https://ara.readthedocs.io/en/latest/api-configuration.html>

## Method — Local recording (no server)

> **Source:** README.md §Recording playbooks without an API server

```bash
# Install ansible with ARA including API server deps (needed for ara-manage runserver)
python3 -m pip install --user ansible "ara[server]"

# Point Ansible at ARA's callback plugin
export ANSIBLE_CALLBACK_PLUGINS="$(python3 -m ara.setup.callback_plugins)"

# Run a playbook as usual
ansible-playbook playbook.yml

# Browse results via CLI
ara playbook list
ara host list

# Or start the built-in dev server at http://127.0.0.1:8000
ara-manage runserver
```

Data is stored in `~/.ara/server/ansible.sqlite` by default.

## Method — Docker / Podman API server

> **Source:** README.md §Recording playbooks with an API server

### Start the server

```bash
# Create a persistent volume directory
mkdir -p ~/.ara/server

# Docker Hub image
docker run --name ara-api --detach --tty \
  --volume ~/.ara/server:/opt/ara \
  -p 8000:8000 \
  docker.io/recordsansible/ara-api:latest

# quay.io image (equivalent)
podman run --name ara-api --detach --tty \
  --volume ~/.ara/server:/opt/ara \
  -p 8000:8000 \
  quay.io/recordsansible/ara-api:latest
```

### Docker Compose

```yaml
services:
  ara-api:
    image: docker.io/recordsansible/ara-api:latest
    restart: unless-stopped
    ports:
      - "${ARA_PORT:-8000}:8000"
    volumes:
      - "${ARA_DATA_PATH:-$HOME/.ara/server}:/opt/ara"
    environment:
      ARA_ALLOWED_HOSTS: '["*"]'
      ARA_CORS_ORIGIN_WHITELIST: '["http://127.0.0.1:8000"]'
```

### Configure Ansible clients to send data to the server

On each machine that runs Ansible playbooks:

```bash
# Install ara without server deps (callback only)
python3 -m pip install --user ansible ara

# Enable the callback plugin
export ANSIBLE_CALLBACK_PLUGINS="$(python3 -m ara.setup.callback_plugins)"

# Point to the API server
export ARA_API_CLIENT="http"
export ARA_API_SERVER="http://<server-host>:8000"

# Run a playbook — results are sent to the server
ansible-playbook playbook.yml
```

Add these exports to `~/.bashrc`, `/etc/environment`, or your CI pipeline config for persistence.

### Verify

```bash
# Check server health
curl http://<server-host>:8000/api/v1/playbooks/

# Browse the web UI
open http://<server-host>:8000
```

## Method — ara_api Ansible role

> **Source:** <https://codeberg.org/ansible-community/ara-collection>

The `ara_api` role installs and configures the ARA server on any Ansible-managed Linux host. The `ara_plugins` role sets up the callback on client hosts.

```bash
# Install the collection from Ansible Galaxy
ansible-galaxy collection install recordsansible.ara

# Example playbook
cat > site.yml <<'EOF'
- name: Install ARA server
  hosts: ara_servers
  roles:
    - role: recordsansible.ara.ara_api
      vars:
        ara_api_fqdn: "ara.example.com"
        ara_api_allowed_hosts:
          - ara.example.com
EOF

ansible-playbook site.yml
```

Role variables are documented in the collection README on Codeberg: <https://codeberg.org/ansible-community/ara-collection/blob/master/roles/ara_api/README.md>

## Upgrade procedure

### Docker / Podman

```bash
docker pull recordsansible/ara-api:latest
docker stop ara-api && docker rm ara-api
# Re-run the same docker run command with the new image
# Or with Compose:
docker compose pull && docker compose up -d
```

ARA handles database migrations automatically on startup via Django's migration framework.

### pip (local or client)

```bash
pip install --upgrade "ara[server]"
# or
pip install --upgrade ara
```

### Ansible role

Re-run the playbook with the updated collection version:
```bash
ansible-galaxy collection install recordsansible.ara --upgrade
ansible-playbook site.yml
```

## Gotchas

- **`ANSIBLE_CALLBACK_PLUGINS` must be set.** ARA's plugin will not record unless this env var points to the correct path. Run `python3 -m ara.setup.callback_plugins` to get the right path for your Python environment.
- **The `ara` pip package and the API server package are separate.** Client hosts that only run playbooks only need `pip install ara`. The server host needs `pip install "ara[server]"` (includes Django etc.).
- **SQLite is fine for personal use; use MySQL/PostgreSQL for team deployments.** SQLite has no concurrent-write support — simultaneous playbook runs from multiple hosts will serialize or fail.
- **ARA is not a CI/CD system.** It records and displays results; it does not trigger or schedule playbooks. Use AWX, Semaphore, Rundeck, or your existing CI for scheduling.
- **API authentication is off by default.** Enable it via `ARA_AUTHENTICATION_BACKEND` for any public-facing deployment. See <https://ara.readthedocs.io/en/latest/api-security.html>.
- **The live demo at demo.recordsansible.org** provides a preview of the web UI without self-hosting.
- **Version pinning:** the `latest` tag tracks the stable release; use a versioned tag (e.g. `ara-api:1.7`) for reproducible deployments.

## Links

- GitHub: <https://github.com/ansible-community/ara>
- Documentation: <https://ara.readthedocs.io>
- Docker Hub: <https://hub.docker.com/r/recordsansible/ara-api>
- quay.io: <https://quay.io/repository/recordsansible/ara-api>
- ara-collection (Ansible roles): <https://codeberg.org/ansible-community/ara-collection>
- Ansible Galaxy: <https://galaxy.ansible.com/recordsansible/ara>
- Live demo: <https://demo.recordsansible.org>

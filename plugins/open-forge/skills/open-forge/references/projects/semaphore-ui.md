---
name: Semaphore UI
description: Modern Web UI for Ansible, Terraform/OpenTofu, Bash, and PowerShell. Schedule playbooks, wire up CI-style pipelines, run tasks with per-job output, manage secrets + inventory. Not to be confused with Travis-era "semaphoreci.com" (unrelated). MIT.
---

# Semaphore UI

Semaphore UI is a web-based DevOps task runner. You define **projects** containing:

- **Inventory** (Ansible hosts, Terraform workspaces)
- **Environment** (env vars, sensitive via Vault or Semaphore's own encryption)
- **Key Store** (SSH keys, passwords, login credentials)
- **Tasks / Templates** — Ansible playbooks, Terraform plans, bash scripts, PowerShell scripts
- **Schedules** (cron-triggered runs)

Then click "Run" (or let a cron schedule do it) and Semaphore executes in the background, streaming output to the web UI. Team-friendly with roles + audit log. Lighter than Rundeck / AWX; heavier than a plain crontab.

Good fit for:

- Home-lab Ansible runners who've outgrown a cron + `ansible-playbook`
- Small teams needing a shared IaC runner without the bulk of AWX/Tower
- OpenTofu / Terraform without needing Terraform Cloud

- Upstream repo: <https://github.com/semaphoreui/semaphore>
- Website: <https://semaphoreui.com>
- Docs: <https://docs.semaphoreui.com>
- Install docs: <https://docs.semaphoreui.com/administration-guide/installation>
- Docker compose ref: <https://github.com/semaphoreui/semaphore/tree/develop/deployment/compose>

## Not to be confused

**`semaphoreci.com`** is a commercial SaaS CI/CD product (same founders as this project, years ago; now diverged). This project = self-hosted task runner; the SaaS = hosted CI. Different code, different repo, no shared infrastructure. Upstream renamed to "Semaphore UI" in 2024 to reduce the confusion.

## Architecture in one minute

Two pieces, both optional to deploy separately:

1. **Server** (`semaphoreui/semaphore`) — web UI + API + task executor
2. **Runner** (`semaphoreui/runner`) — optional remote runner; lets tasks execute on different machines than the server (useful for air-gapped clusters, OS-specific targets, etc.)

Storage options: SQLite (default, for small installs), MySQL/MariaDB, Postgres, BoltDB. The default Docker image uses SQLite on a volume.

## Compatible install methods

| Infra       | Runtime                                                | Notes                                                                     |
| ----------- | ------------------------------------------------------ | ------------------------------------------------------------------------- |
| Single VM   | Docker (`semaphoreui/semaphore:<VERSION>`)             | **Recommended**                                                            |
| Single VM   | Docker Compose with MySQL / Postgres                    | For multi-user + heavier concurrency                                       |
| Single VM   | Binary + systemd                                        | Upstream .deb/.rpm/.exe artifacts                                          |
| Kubernetes  | Plain Deployment or community Helm chart                 | Stateless; PVC for SQLite or external DB                                   |
| Multi-host  | Server + Runner split (`semaphoreui/runner`)             | For executing on different networks                                        |

## Inputs to collect

| Input                                 | Example                              | Phase     | Notes                                                            |
| ------------------------------------- | ------------------------------------ | --------- | ---------------------------------------------------------------- |
| `SEMAPHORE_ADMIN_*`                   | username/password/email              | Bootstrap | Creates first admin on startup                                    |
| `SEMAPHORE_WEB_ROOT`                  | `https://semaphore.example.com`      | Runtime   | Public URL; used in email links + OAuth callbacks                 |
| `SEMAPHORE_ACCESS_KEY_ENCRYPTION`     | `openssl rand -base64 32`            | Security  | **Critical** — encrypts stored SSH keys + passwords in Key Store  |
| DB choice                             | SQLite / MySQL / Postgres / BoltDB   | DB        | SQLite fine <5 users; Postgres/MySQL for real teams                |
| Data volume                           | `/var/lib/semaphore`                 | Data      | SQLite DB, playbooks, temp files                                  |
| SSH keys for managed hosts            | imported via Key Store               | Config    | Semaphore encrypts with ACCESS_KEY_ENCRYPTION                     |
| Git repositories                      | Ansible playbook repos                | Config    | Auto-synced; deploy keys typical                                  |

## Install via Docker Compose (server-only)

Combining upstream `deployment/compose/server/base.yml` + `config.yml`:

```yaml
volumes:
  server:

services:
  server:
    image: docker.io/semaphoreui/semaphore:v2.18.2    # pin; ${SEMAPHORE_VERSION:-latest} default is risky
    restart: always
    environment:
      SEMAPHORE_ADMIN_NAME: Admin
      SEMAPHORE_ADMIN: admin
      SEMAPHORE_ADMIN_PASSWORD: <strong>            # CHANGE FROM DEFAULT p455w0rd
      SEMAPHORE_ADMIN_EMAIL: admin@example.com
      SEMAPHORE_WEB_ROOT: https://semaphore.example.com
      SEMAPHORE_ACCESS_KEY_ENCRYPTION: <openssl rand -base64 32>
    volumes:
      - server:/var/lib/semaphore
    ports:
      - "3000:3000"
```

Browse `http://<host>:3000`, log in as `admin` / your password.

### With Postgres

```yaml
services:
  server:
    image: docker.io/semaphoreui/semaphore:v2.18.2
    restart: always
    environment:
      SEMAPHORE_DB_DIALECT: postgres
      SEMAPHORE_DB_HOST: postgres
      SEMAPHORE_DB_USER: semaphore
      SEMAPHORE_DB_PASS: <strong>
      SEMAPHORE_DB: semaphore
      SEMAPHORE_ADMIN: admin
      SEMAPHORE_ADMIN_PASSWORD: <strong>
      SEMAPHORE_ADMIN_EMAIL: admin@example.com
      SEMAPHORE_WEB_ROOT: https://semaphore.example.com
      SEMAPHORE_ACCESS_KEY_ENCRYPTION: <openssl rand -base64 32>
    depends_on: [postgres]
    ports: ["3000:3000"]
  postgres:
    image: postgres:17-alpine
    restart: always
    environment:
      POSTGRES_DB: semaphore
      POSTGRES_USER: semaphore
      POSTGRES_PASSWORD: <strong>
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### Running with a separate Runner

When you want tasks to execute on a different machine (firewalled / different OS):

```yaml
services:
  runner:
    image: docker.io/semaphoreui/runner:v2.16.15    # match server version
    restart: always
    environment:
      SEMAPHORE_RUNNER_API_URL: https://semaphore.example.com/api
      SEMAPHORE_RUNNER_REGISTRATION_TOKEN: <obtained from server UI>
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # if using docker in tasks
      - runner-data:/tmp
```

Register the runner's token via server UI → Runners → Add runner.

## Data & config layout

Inside `/var/lib/semaphore`:

- `database.boltdb` (if BoltDB mode) or `semaphore.db` (SQLite)
- `project_*/` — per-project git checkouts
- `tmp/` — task scratch

Configuration via:

- **Env vars** (default in Docker)
- **config.json** (mounted at `/etc/semaphore/config.json`; takes precedence over env)

Encrypted secrets in Key Store (SSH keys, login credentials) use `SEMAPHORE_ACCESS_KEY_ENCRYPTION`.

## Backup

```sh
# Full data volume
docker run --rm -v server:/src -v "$PWD":/backup alpine \
  tar czf /backup/semaphore-$(date +%F).tgz -C /src .

# SEPARATE: the encryption key
echo "SEMAPHORE_ACCESS_KEY_ENCRYPTION=..." > semaphore-key-$(date +%F).txt
```

**Backup is useless without the encryption key.** SSH keys + stored passwords in the Key Store become ciphertext garbage on restore if the key is lost.

Postgres installs: add a `pg_dump` step.

## Upgrade

1. Releases: <https://github.com/semaphoreui/semaphore/releases>.
2. Docker: `docker compose pull && docker compose up -d`. Migrations run on startup.
3. **Runner version must match server version.** Upgrade server first, then runners.
4. Breaking changes between minor versions are rare but happen; read release notes.
5. Pre-v2 (Semaphore 1.x) data migration path documented at <https://docs.semaphoreui.com/administration-guide/upgrading/upgrade-to-v2>.

## Gotchas

- **Default admin password `p455w0rd`** in upstream compose. CHANGE BEFORE FIRST BOOT or bot-scan will find it in minutes.
- **Default `SEMAPHORE_ACCESS_KEY_ENCRYPTION`** in upstream compose is `IlRqgrrO5Gp27MlWakDX1xVrPv4jhoUx+ARY+qGyDxQ=` — **well-known, NOT secret**. Replace with your own before storing any real keys.
- **Losing `SEMAPHORE_ACCESS_KEY_ENCRYPTION` = losing all stored SSH keys + credentials.** They're encrypted; no key = no decrypt.
- **Name confusion with SemaphoreCI**. Totally different product.
- **SQLite fine until concurrency bites.** Above ~5 concurrent task runs, switch to Postgres/MySQL or you'll see SQLite "database is locked" errors.
- **Ansible runs use the server's filesystem for playbook checkouts.** Disk fills with orphaned `project_*/` directories if projects churn. Periodic prune needed.
- **`SEMAPHORE_WEB_ROOT`** must match the public URL. Wrong = broken email links + OAuth callbacks.
- **Runner separation is optional.** Small installs keep everything in one server container. Only split when you need geographic distribution or OS separation.
- **No built-in log retention.** Task output grows; set retention via API or clear old runs periodically.
- **Secrets in task output.** Ansible playbooks that `echo` secrets land them in the task log. Use `no_log: true` + Ansible Vault.
- **OIDC / LDAP** supported; config via env vars (<https://docs.semaphoreui.com/administration-guide/configuration/authentication>).
- **Per-project RBAC** roles: Owner, Manager, Task runner, Guest. Fine-grained enough for small teams.
- **Schedules use cron syntax** (5-field); validate with a cron-parser before saving.
- **Terraform / OpenTofu support** requires picking the right template type; state stored as artifact unless you configure remote backend.
- **Bash / PowerShell script templates** run in the task runner's shell — remember everything runs as the server user (or runner's user).
- **Inventory file-type integrations** supported: static file, dynamic (command), cloud (AWS/GCP/Azure via Ansible dynamic inventories).
- **Volumes:** if you store secrets in config.json (mounted), they're in the host filesystem — secure accordingly.
- **Frequent dependency updates** — upstream ships often. Pin + test in staging before rolling to prod.
- **Alternatives worth knowing:**
  - **AWX / Ansible Automation Platform** — Red Hat's upstream + commercial; much heavier
  - **Rundeck** — more generic job scheduler; older UI
  - **Ansible Semaphore** (historical name) = this project
  - **StackStorm** — event-driven automation platform
  - **n8n** / **Automatisch** — if you want generic workflow over Ansible-specific
  - **Just a cron job** — for truly small setups

## Links

- Repo: <https://github.com/semaphoreui/semaphore>
- Website: <https://semaphoreui.com>
- Docs: <https://docs.semaphoreui.com>
- Installation: <https://docs.semaphoreui.com/administration-guide/installation>
- Docker install: <https://docs.semaphoreui.com/administration-guide/installation/docker>
- Compose reference: <https://github.com/semaphoreui/semaphore/tree/develop/deployment/compose>
- Config env reference: <https://docs.semaphoreui.com/administration-guide/configuration/environment-variables>
- Authentication: <https://docs.semaphoreui.com/administration-guide/configuration/authentication>
- Releases: <https://github.com/semaphoreui/semaphore/releases>
- Docker Hub: <https://hub.docker.com/r/semaphoreui/semaphore>
- Runner image: <https://hub.docker.com/r/semaphoreui/runner>
- Upgrade to v2: <https://docs.semaphoreui.com/administration-guide/upgrading/upgrade-to-v2>

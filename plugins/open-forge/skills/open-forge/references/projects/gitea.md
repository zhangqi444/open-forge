---
name: gitea-project
description: Gitea recipe for open-forge. MIT-licensed lightweight self-hosted Git service — Go binary with built-in SSH server, web UI, CI/CD (Gitea Actions), package registry, issue tracker, wiki. Runs from SQLite + single binary for hobby use, or Postgres/MySQL + Docker for production. Covers binary + systemd, Docker Compose (official `gitea/gitea` image), and from-source builds. Flags the runner architecture (Gitea Actions needs a separate `act_runner` process to execute workflows).
---

# Gitea

MIT-licensed, community-managed fork of Gogs. Full-featured Git forge: web UI, SSH+HTTPS Git, issues, PRs, wiki, packages (OCI/npm/Maven/PyPI/etc.), Gitea Actions CI, org management. Upstream: <https://github.com/go-gitea/gitea>. Docs: <https://docs.gitea.com/>.

Single static Go binary; SQLite by default (fine for personal/small-team), Postgres or MySQL for real deploys. Default HTTP port `:3000`, SSH port `:22` (usually remapped to avoid clashing with host SSH).

## Compatible install methods

Every method below is documented under <https://docs.gitea.com/installation/>:

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Prebuilt binary + systemd | <https://docs.gitea.com/installation/install-from-binary> | ✅ Recommended for bare metal | Production on a dedicated VM — minimal footprint. |
| Docker (`gitea/gitea`) + Compose | <https://docs.gitea.com/installation/install-with-docker> | ✅ Recommended for container hosts | The most common self-host shape. |
| Docker Rootless | <https://docs.gitea.com/installation/install-with-docker-rootless> | ✅ | Security-hardened container variant. |
| Kubernetes (Helm) | <https://gitea.com/gitea/helm-gitea> | ✅ | K8s deployments. |
| Package managers (apt/dnf/brew/scoop) | <https://docs.gitea.com/installation/install-from-package> | ⚠️ Community-maintained per-distro | Fast but versions lag upstream. |
| From source | <https://docs.gitea.com/installation/install-from-source> | ✅ | Custom builds, contributors. Needs Go 1.23+ + Node LTS + pnpm. |
| Unattended (`gitea install` CLI) | Any of the above | ✅ | Scripted setup skipping the web-install wizard. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| db | "Database? (SQLite / Postgres / MySQL)" | `AskUserQuestion` | SQLite is fine up to ~few users; Postgres for anything real. |
| db | "Postgres host/port/user/pass/db?" | Free-text (sensitive) | Only if not SQLite. |
| dns | "Public domain?" | Free-text | E.g. `git.example.com`. |
| tls | "Reverse proxy for HTTPS? (Caddy / nginx / Traefik / built-in ACME)" | `AskUserQuestion` | Gitea can do its own ACME but reverse proxy is more common. |
| ssh | "Expose Gitea SSH on port 22 (shared with host) or a different port (e.g. 2222)?" | `AskUserQuestion`: `22-built-in` / `22-via-shim` / `2222` | See §SSH patterns below. |
| admin | "Initial admin user + email + password?" | Free-text (sensitive) | First user via web install is auto-promoted to admin. `gitea admin user create` for CLI path. |
| actions | "Enable Gitea Actions (CI)?" | Boolean | Requires deploying at least one `act_runner` separately. |

## Install — Docker Compose

From upstream's `docs.gitea.com/installation/install-with-docker`:

```yaml
# compose.yaml
networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:1.26   # pin minor — don't use :latest
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=postgres
      - GITEA__database__HOST=db:5432
      - GITEA__database__NAME=gitea
      - GITEA__database__USER=gitea
      - GITEA__database__PASSWD=${DB_PW}
      - GITEA__server__DOMAIN=git.example.com
      - GITEA__server__ROOT_URL=https://git.example.com/
      - GITEA__server__SSH_DOMAIN=git.example.com
      - GITEA__server__SSH_PORT=2222
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "2222:22"
    depends_on:
      - db

  db:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_USER: gitea
      POSTGRES_PASSWORD: ${DB_PW}
      POSTGRES_DB: gitea
    networks:
      - gitea
    volumes:
      - ./postgres:/var/lib/postgresql/data
```

Bring up:

```bash
echo "DB_PW=$(openssl rand -hex 24)" > .env
docker compose up -d
docker compose logs -f server
# Visit http://<host>:3000 — web installer confirms the env-provided settings,
# first user created becomes admin.
```

### Env-var naming convention

Gitea's INI config (`/data/gitea/conf/app.ini`) has `[section]` + `KEY = value` structure. The env-var equivalent is `GITEA__<section>__<KEY>` (double underscores, UPPERCASE or mixed). Anything in the INI can be overridden via env.

## Install — Binary + systemd

```bash
# 1. Download binary (check https://dl.gitea.com/gitea/ for latest)
GITEA_VERSION=1.22.4
ARCH=linux-amd64
curl -L -o /tmp/gitea \
  "https://dl.gitea.com/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-${ARCH}"
sudo install -m 0755 -o root -g root /tmp/gitea /usr/local/bin/gitea

# 2. Verify GPG sig (optional but upstream-recommended)
# See https://docs.gitea.com/installation/install-from-binary#verifying-gpg-signature

# 3. System user + directories
sudo adduser --system --shell /bin/bash --gecos 'Git Version Control' \
  --group --disabled-password --home /home/git git

sudo mkdir -p /var/lib/gitea/{custom,data,log}
sudo chown -R git:git /var/lib/gitea
sudo chmod -R 750 /var/lib/gitea
sudo mkdir /etc/gitea
sudo chown root:git /etc/gitea
sudo chmod 770 /etc/gitea   # tighten to 750 after web install finishes

# 4. systemd unit (upstream ships one at contrib/systemd/gitea.service)
curl -sL https://raw.githubusercontent.com/go-gitea/gitea/main/contrib/systemd/gitea.service \
  | sudo tee /etc/systemd/system/gitea.service > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable --now gitea
sudo systemctl status gitea
```

Then visit `http://<host>:3000` to complete the web install wizard.

## SSH patterns

Gitea needs an SSH server for `git@host:user/repo.git` URLs. Two options:

### Built-in SSH server (Gitea 1.6+)

Gitea starts its own SSH daemon on `SSH_PORT`. Set `START_SSH_SERVER=true` (or `GITEA__server__START_SSH_SERVER=true`) and pick a port that doesn't clash with host OpenSSH. Simple, self-contained.

### Host OpenSSH + shim (port 22 UX)

If you want `git clone git@git.example.com:user/repo.git` to just work (no `-p 2222`), keep host OpenSSH on `:22` and configure Gitea to use the `git` OS user with an `authorized_keys` shim. Gitea writes keys into `~git/.ssh/authorized_keys` in a format that invokes `gitea serv` on each connection. Setup:

- Host `git` user owns `~/.ssh/authorized_keys` with mode `0600`.
- Gitea runs as the same `git` user (or can write into its `.ssh/` dir).
- `BUILTIN_SSH_SERVER_USER = git` in `app.ini`.

See <https://docs.gitea.com/administration/command-line#admin> for SSH config details. The Docker image ships a variant that handles both patterns.

## Reverse proxy (Caddy example)

```caddy
git.example.com {
    reverse_proxy 127.0.0.1:3000
    # Large file uploads for git push — raise limits
    request_body {
        max_size 500MB
    }
}
```

For nginx, the canonical recipe is at <https://docs.gitea.com/administration/reverse-proxies>.

## Gitea Actions (CI/CD)

Gitea Actions is GitHub-Actions-compatible at the workflow-YAML level. To run workflows you need a separate `act_runner` process (the Gitea fork of nektos/act):

```yaml
# compose.yaml — add to the same stack, or on a separate host
  runner:
    image: gitea/act_runner:latest
    container_name: gitea_runner
    restart: unless-stopped
    environment:
      GITEA_INSTANCE_URL: "http://server:3000"
      GITEA_RUNNER_REGISTRATION_TOKEN: "${RUNNER_TOKEN}"   # from Gitea admin UI
    volumes:
      - ./runner_data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - gitea
    depends_on:
      - server
```

Get the registration token from Gitea admin UI → Site Administration → Actions → Runners → Create new runner. Each runner can be scoped to a repo / org / instance-wide.

## Data layout

| Path (Docker) | Path (binary) | Content |
|---|---|---|
| `/data/` | `/var/lib/gitea/` | Everything persistent — repos, LFS, config, attachments, sessions. |
| `/data/gitea/conf/app.ini` | `/etc/gitea/app.ini` | Config file. Env vars override this. |
| `/data/git/repositories/` | `/var/lib/gitea/data/repositories/` | Bare git repos. |
| `/data/gitea/lfs/` | `/var/lib/gitea/data/lfs/` | Git-LFS storage (if enabled). |

Back up = stop Gitea + `tar` the data dir + dump the DB. Or use `gitea dump`:

```bash
docker compose exec server su git -c 'gitea dump -c /data/gitea/conf/app.ini'
# → creates gitea-dump-<timestamp>.zip in /tmp inside the container
```

## Upgrade procedure

### Docker

```bash
# Read release notes FIRST — https://github.com/go-gitea/gitea/releases
cd /path/to/gitea
# Bump image tag in compose.yaml (minor-version bumps OK, major = read notes carefully)
docker compose pull server
docker compose up -d
docker compose logs -f server   # watch DB migrations run
```

### Binary

```bash
sudo systemctl stop gitea
sudo cp /usr/local/bin/gitea /usr/local/bin/gitea.bak
curl -L -o /tmp/gitea-new "https://dl.gitea.com/gitea/${NEW_VERSION}/gitea-${NEW_VERSION}-linux-amd64"
sudo install -m 0755 /tmp/gitea-new /usr/local/bin/gitea
sudo systemctl start gitea
sudo journalctl -u gitea -n 100
```

**Major-version bumps (1.x → 1.y where y jumps) can run destructive migrations on first boot.** `gitea dump` first.

## Gotchas

- **SSH port conflict.** Host SSH and Gitea's built-in SSH can't both bind `:22`. Pick a pattern (§SSH patterns) and commit to it.
- **`app.ini` vs env vars.** Env vars override `app.ini` at startup but are NOT written back into the file. After a Docker install, inspecting `app.ini` shows old values — don't be surprised.
- **SQLite for multi-user breaks down at scale.** It works for a handful of users; past that, migrate to Postgres via `gitea migrate` + config change.
- **Actions runner needs Docker-in-Docker or host docker.sock.** The compose example mounts `/var/run/docker.sock` — this grants the runner container root on the host. For untrusted workflows, use DinD or isolated runner VMs.
- **Default admin is the first user.** Until the first user registers, anyone hitting `/user/sign_up` can claim admin. Either register immediately after `docker compose up -d`, OR disable public registration pre-first-user via `DISABLE_REGISTRATION=true` + use `gitea admin user create` CLI to bootstrap.
- **`gitea dump` doesn't include the DB for MySQL/Postgres by default** — it exports data as SQL. For external Postgres you still need `pg_dump` separately.
- **LFS storage grows fast.** Large files live under `/data/gitea/lfs/`. Plan for disk growth or move LFS to S3 via `[lfs] STORAGE_TYPE=minio`.
- **Webhook egress.** By default Gitea will POST to any URL — internal network targets can be used for SSRF. For multi-tenant deploys, set `[webhook] ALLOWED_HOST_LIST` to restrict targets.
- **CSP / iframe embedding.** Upstream ships sane defaults; custom themes can accidentally break Actions' log viewer if they relax CSP weirdly.
- **`latest` image tag drifts across major versions.** Always pin a specific minor (e.g. `1.22`), not `latest`. A surprise `1.x → 2.0` is the biggest upgrade risk.

## Links

- Upstream repo: <https://github.com/go-gitea/gitea>
- Docs: <https://docs.gitea.com/>
- Installation index: <https://docs.gitea.com/installation/>
- Docker image: <https://hub.docker.com/r/gitea/gitea>
- Releases: <https://github.com/go-gitea/gitea/releases>
- Helm chart: <https://gitea.com/gitea/helm-gitea>
- Actions: <https://docs.gitea.com/usage/actions/overview>
- act_runner: <https://gitea.com/gitea/act_runner>
- Binaries: <https://dl.gitea.com/gitea/>

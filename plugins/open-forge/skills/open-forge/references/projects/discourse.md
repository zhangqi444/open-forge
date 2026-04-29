---
name: discourse-project
description: Discourse recipe for open-forge. GPL-2.0 Rails-based discussion forum — the de-facto modern open-source forum software. Self-host is strictly opinionated — upstream only supports a single install path, the `discourse_docker` launcher-managed container via `install-discourse` bootstrap script on Ubuntu/Debian. This recipe covers that canonical path, the `containers/app.yml` configuration model, the rebuild semantics, optional multi-container (web + data) split, email setup (mandatory), and common operational gotchas.
---

# Discourse

GPL-2.0 Ruby on Rails + Ember.js discussion forum. Upstream: <https://github.com/discourse/discourse>. Install guide: <https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md>. Docker tooling: <https://github.com/discourse/discourse_docker>.

**Only one officially supported install method.** Discourse upstream is emphatic: the ONLY supported self-host path is `discourse_docker` (their launcher-managed Docker container). Bare-metal installs, Kubernetes, "just use the Rails app," Docker Hub community images — none are supported. Asking for help on any non-standard install in the official forum gets a polite "use the standard installer" in return.

## What you're deploying

`discourse_docker` bootstraps a single Docker container (or optionally multiple: separate `web` + `data` containers) that runs:

- Rails app (Puma)
- Sidekiq (background jobs)
- Postgres
- Redis
- Nginx

Default ports: `:80` + `:443` on the host (Nginx inside container binds those and handles TLS via Let's Encrypt).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `install-discourse` bootstrap script (recommended) | <https://raw.githubusercontent.com/discourse/discourse_docker/main/install-discourse> | ✅ **Only supported path** | The upstream-blessed install. |
| Manual `discourse_docker` setup | <https://github.com/discourse/discourse_docker> | ✅ | Same end state; lets you customize `containers/app.yml` before bootstrap. |
| Multi-container split (web + data) | <https://github.com/discourse/discourse_docker/blob/main/samples/data.yml> · <https://github.com/discourse/discourse_docker/blob/main/samples/web_only.yml> | ✅ | Large installs; run Postgres in a dedicated `data` container, app in `web_only`. |
| Discourse hosting (official managed) | <https://discourse.org/pricing> | ✅ Paid | Not self-host; mentioned for completeness. |
| Bitnami / other blueprints | — | ⚠️ Community | **NOT supported.** Upstream won't help. |
| Kubernetes | — | ❌ | **NOT supported.** The `discourse_docker` model is incompatible with typical K8s patterns. |

## Hardware requirements (per INSTALL-cloud.md)

| Requirement | Minimum | Recommended |
|---|---|---|
| RAM | 1 GB (with swap) | 2 GB+ |
| CPU | 1 core | 2+ cores |
| Disk | 10 GB | 20 GB+ |
| OS | 64-bit Linux | Ubuntu LTS (22.04 / 24.04) |

The installer auto-tunes `UNICORN_WORKERS` and `db_shared_buffers` based on host specs.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Fresh Ubuntu/Debian root SSH?" | Boolean | Installer expects root. |
| preflight | "Split web + data into two containers?" | `AskUserQuestion` | Only for larger installs (> a few thousand active users). Single-container is fine for most. |
| dns | "Domain?" | Free-text (e.g. `forum.example.com`) | Must already resolve to the host BEFORE install. Installer offers free `*.discourse.diy` subdomain as fallback. |
| smtp | "SMTP provider?" | `AskUserQuestion`: `Mailgun` / `SendGrid` / `Amazon SES` / `Postmark` / `Mailjet` / `Other` | **Discourse requires SMTP even to create the first admin** — the confirmation email is mandatory. No skipping. |
| smtp | "SMTP host / port / user / pass?" | Free-text (sensitive) | Written into `containers/app.yml`. |
| smtp | "From/notification email addresses?" | Free-text | `DISCOURSE_DEVELOPER_EMAILS` (promotes these emails to admin on signup) + `DISCOURSE_SMTP_USER_NAME` + `DISCOURSE_NOTIFICATION_EMAIL`. |
| admin | "Initial admin email(s)?" | Free-text, comma-separated | Becomes `DISCOURSE_DEVELOPER_EMAILS` in `app.yml`. |

## Install — Quick Start (INSTALL-cloud.md §Quick Start)

```bash
# On a fresh Ubuntu/Debian server, as root
wget -qO- https://raw.githubusercontent.com/discourse/discourse_docker/main/install-discourse | sudo bash
```

The script:

1. Installs Docker + git if missing.
2. Clones `discourse_docker` to `/var/discourse`.
3. Runs `./discourse-setup` which asks interactive prompts (domain, admin emails, SMTP).
4. Writes `containers/app.yml` with your answers.
5. Bootstraps the container (`./launcher bootstrap app`) — this takes 10-20 minutes; downloads base image, builds app image with your config baked in.
6. Starts the container (`./launcher start app`).

After install, visit `https://${DOMAIN}/` — first-run wizard prompts to create the admin account (must be on of the emails you listed in `DISCOURSE_DEVELOPER_EMAILS`).

## The `launcher` tool

From `/var/discourse`:

```bash
./launcher start app          # Start
./launcher stop app           # Stop
./launcher restart app        # Restart
./launcher rebuild app        # Rebuild (after editing app.yml or upgrading)
./launcher logs app           # View logs
./launcher enter app          # Shell inside container
./launcher destroy app        # Destroy the container (data in /shared persists)
./launcher ssh app            # SSH (same as enter)
./launcher cleanup            # Remove containers stopped > 24h
```

`rebuild` is the single most important command. It:

1. Stops the container.
2. Builds a new image from your current `containers/app.yml`.
3. Runs DB migrations.
4. Starts the new container.

**Any time you edit `app.yml`, run `./launcher rebuild app`** — restart alone won't pick up changes to env vars / plugins / hooks.

## `containers/app.yml` structure

This is the one config file. Key sections:

```yaml
templates:
  - "templates/postgres.template.yml"
  - "templates/redis.template.yml"
  - "templates/web.template.yml"
  - "templates/web.ratelimited.template.yml"
  - "templates/web.ssl.template.yml"         # auto-uncommented by setup if using SSL
  - "templates/web.letsencrypt.ssl.template.yml"   # Let's Encrypt via templated ACME

expose:
  - "80:80"
  - "443:443"

params:
  db_default_text_search_config: "pg_catalog.english"
  db_shared_buffers: "1024MB"       # auto-tuned on install

env:
  LANG: en_US.UTF-8
  UNICORN_WORKERS: 3                # auto-tuned
  DISCOURSE_HOSTNAME: 'forum.example.com'
  DISCOURSE_DEVELOPER_EMAILS: 'you@example.com'
  DISCOURSE_SMTP_ADDRESS: smtp.mailgun.org
  DISCOURSE_SMTP_PORT: 587
  DISCOURSE_SMTP_USER_NAME: postmaster@mg.example.com
  DISCOURSE_SMTP_PASSWORD: "your-password"
  DISCOURSE_SMTP_DOMAIN: example.com
  # DISCOURSE_CDN_URL: https://discourse-cdn.example.com

volumes:
  - volume:
      host: /var/discourse/shared/standalone
      guest: /shared
  - volume:
      host: /var/discourse/shared/standalone/log/var-log
      guest: /var/log

hooks:
  # Install plugins here
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/docker_manager.git
          - git clone https://github.com/discourse/discourse-solved.git
```

## Plugins

Plugins go in the `hooks.after_code` block of `app.yml`. After adding, `./launcher rebuild app`. The admin UI at `/admin/plugins` lists installed plugins; most need a rebuild, not just a restart.

Popular first-party plugins:
- `docker_manager` (shipped by default — auto-updates Discourse from the UI)
- `discourse-solved` (mark answers as solved)
- `discourse-calendar` (events)
- `discourse-assign` (assign topics)
- `discourse-chat-integration` (Slack/Matrix/etc notifications)
- `discourse-oauth2-basic` (generic OAuth)
- `discourse-saml` (SAML SSO)

## Upgrade procedure

**Preferred path: admin UI.** Go to `/admin/upgrade` (requires the `docker_manager` plugin which ships by default). It shows available versions for Discourse core + each plugin, with a one-click upgrade button. Performs `git pull` + migrations; runs without downtime for code-only upgrades.

**Major-version upgrades OR Postgres/Ruby bumps** require a rebuild:

```bash
cd /var/discourse
git pull
./launcher rebuild app
# 15-20 min; forum is DOWN during rebuild
```

Upstream announces Postgres/Ruby bumps in the official dev blog; the admin UI also shows a banner saying "upgrade requires rebuild from CLI."

## Backup

```bash
# Automatic: admin UI → Settings → Backups. Runs nightly, keeps N days.
# Manual via launcher:
cd /var/discourse
./launcher enter app
discourse backup
exit

# Backups land in /var/discourse/shared/standalone/backups/default/
```

Offsite: set `s3_backup_bucket` + `s3_access_key_id` + `s3_secret_access_key` in admin UI → Settings → Backups → store on S3.

## Multi-container (large installs)

For > 5k DAU or heavy plugin load, split the monolith:

```bash
cd /var/discourse/containers
cp ../samples/data.yml data.yml         # Postgres + Redis
cp ../samples/web_only.yml web_only.yml # Rails app
# Edit both — the web_only one points DB_HOST / REDIS_HOST at the data container.
./launcher bootstrap data
./launcher start data
./launcher bootstrap web_only
./launcher start web_only
```

Upgrades happen per-container (`./launcher rebuild web_only` without rebuilding `data`). This is the shape official Discourse hosting uses.

## Gotchas

- **SMTP is mandatory, even for the first admin.** You cannot complete signup without the activation email. Every dev on every "why is setup broken" forum thread learned this the hard way.
- **Only `discourse_docker` is supported.** Don't waste time on Kubernetes / Bitnami / community compose files — if you deviate, you own it forever.
- **Rebuild vs restart distinction.** `restart` just restarts the running container with existing image. `rebuild` re-runs bootstrap (slow; builds a fresh image with current `app.yml`). After ANY `app.yml` edit, `rebuild`.
- **Let's Encrypt inside the container.** The `web.letsencrypt.ssl.template.yml` template runs `certbot` inside the container. Needs ports 80 + 443 reachable from the internet DURING rebuild. Behind a CDN or another reverse proxy, this breaks — use DNS-01 or terminate TLS upstream and add `templates/web.ratelimited.template.yml` + drop the LE template.
- **DNS must resolve BEFORE install.** `install-discourse` tries to obtain a Let's Encrypt cert during setup. If the A-record isn't up, the cert obtain fails, you get a partial install, and recovery is manual.
- **1GB RAM requires swap.** Upstream explicitly says 1GB works only "with swap." Add a 2GB swap file before running install-discourse on a 1GB VPS, or the bootstrap OOMs on asset precompile.
- **S3 for attachments on large installs.** Local attachments fill disk fast on active forums. Configure S3 in admin → Settings → Files → `enable_s3_uploads = true`.
- **CDN is near-mandatory for public forums.** `DISCOURSE_CDN_URL` offloads static assets. Upstream's own forum (meta.discourse.org) uses Fastly.
- **Admin can access the DB shell.** `./launcher enter app` + `su postgres -c psql discourse` — inside-the-container DB access. Useful for emergency, risky in normal operation.
- **PG version bumps need a dump+restore.** When upstream moves to a newer Postgres, the rebuild does the pg_upgrade for you automatically — but this is the one "please do a backup first" moment where the automation can fail. Check release notes for Postgres bumps and run a manual `discourse backup` before rebuild.
- **`app.yml` contains secrets in plaintext.** `/var/discourse/containers/app.yml` has SMTP password, maybe S3 keys. Chmod 600 + back it up separately from data (e.g. into your password manager).
- **Plugins can break upgrades.** A plugin that's incompatible with the new Discourse will fail the rebuild. The admin UI's "Available Upgrades" page flags this; heed the warning. Worst case: comment out the plugin in `app.yml`, rebuild, file a plugin issue.
- **Emoji and avatars rely on `image_magick`-era tooling.** Some base-image bumps (Bullseye → Bookworm) have broken image processing. Upstream patches these fast but expect occasional transient breakage immediately post-rebuild.

## Links

- Upstream repo: <https://github.com/discourse/discourse>
- Docker repo: <https://github.com/discourse/discourse_docker>
- Install guide: <https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md>
- `launcher` usage: <https://github.com/discourse/discourse_docker#launcher>
- `samples/` directory (standalone / data / web_only / mail-receiver templates): <https://github.com/discourse/discourse_docker/tree/main/samples>
- Meta (the community forum for Discourse): <https://meta.discourse.org/>
- Howtos on Meta: <https://meta.discourse.org/c/howto/10>
- Releases: <https://github.com/discourse/discourse/releases>
- Official hosting: <https://discourse.org/pricing>

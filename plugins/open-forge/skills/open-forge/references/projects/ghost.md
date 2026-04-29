---
name: ghost-project
description: Ghost recipe for open-forge. Covers every upstream-blessed install method documented under https://ghost.org/docs/install/ — Ghost-CLI on Ubuntu (recommended production), Docker Compose preview (with self-hosted ActivityPub + Tinybird Analytics), Local install (dev), Install from source (Ghost core dev), DigitalOcean 1-Click marketplace, Linode VPS — plus community-maintained options (Bitnami blueprint, Docker Hub `ghost` image). Each section cites the upstream URL it derives from per CLAUDE.md § Strict doc-verification policy.
---

# Ghost

Open-source publishing platform built on Node.js + MySQL/SQLite. Upstream: <https://github.com/TryGhost/Ghost>. Install methods index: <https://ghost.org/docs/install/>.

Ghost itself is a Node app listening on port `2368`. What varies across install methods is which webserver fronts it (NGINX vs Caddy vs Apache), which database it uses (MySQL vs SQLite), how TLS is provisioned (Ghost-CLI runs Let's Encrypt + NGINX automatically; Docker preview uses Caddy on-demand; Bitnami uses `bncert-tool` + Apache), and which optional services are bundled (the new Docker preview ships self-hosted ActivityPub + Tinybird Analytics out of the box; Ghost-CLI does not).

## Compatible install methods

Verified against the upstream `TryGhost/Docs` repo's `install/` tree per CLAUDE.md § *Strict doc-verification policy*. Each method below has its own section with the upstream URL cited at the section head.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Ghost-CLI on Ubuntu | <https://ghost.org/docs/install/ubuntu/> | ✅ | Recommended production. Ubuntu 22.04/24.04 + NGINX + Node + MySQL 8 + systemd. |
| Docker Compose (preview) | <https://ghost.org/docs/install/docker/> | ✅ | New Ghost 6.0+ tooling. Optional self-hosted ActivityPub + Tinybird Analytics. Caddy webserver. |
| Local install (dev) | <https://ghost.org/docs/install/local/> | ✅ | Development on Mac/Win/Linux with SQLite. Not for production. |
| Install from source | <https://ghost.org/docs/install/source/> | ✅ | Working on Ghost core itself (fork → `pnpm dev`). Not for production. |
| DigitalOcean 1-Click | <https://ghost.org/docs/install/digitalocean/> | ✅ (DO is upstream's "official hosting partner") | Marketplace droplet — runs Ghost-CLI under the hood. |
| Linode VPS | <https://ghost.org/docs/install/linode/> | ✅ | Thin wrapper: provision a Linode Ubuntu VPS, then follow the Ubuntu guide. |
| Ghost(Pro) managed hosting | <https://ghost.org/pricing/> | ✅ | Out of scope for open-forge — paid managed service, no install. |
| Bitnami blueprint | <https://bitnami.com/stack/ghost> | ⚠️ Community-maintained | Pre-baked single-node Apache + Node + MySQL. AWS Lightsail / others. **Not in upstream's install index.** |
| Docker Hub `ghost` image | <https://ghost.org/docs/install/docker-community/> · <https://hub.docker.com/_/ghost> | ⚠️ Community-maintained | Older image at `docker-library/ghost`. Upstream recommends the new ghost-docker preview instead. |

## Inputs to collect

Phase-keyed prompts. Ask each at the phase where it's needed — not all upfront.

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | `AskUserQuestion`, options from the table above | Drives which method section the recipe loads. |
| dns | "What's the domain you want to host Ghost on?" | Free-text | All methods that expose Ghost publicly. |
| dns | "Use `www.<domain>` or apex (`<domain>`) as canonical?" | `AskUserQuestion`: `www` / `apex` | All public-facing methods. Some (Docker preview's Caddy redirect blocks, Bitnami's `bncert-tool`) have method-specific gotchas — see those sections. |
| tls | "Email for Let's Encrypt expiration notices?" | Free-text | All public-facing methods (Ghost-CLI, Docker preview, DO, Linode, Bitnami). Cert auto-renews; this is the warning channel if it ever breaks. |
| smtp | "Which outbound email provider?" | `AskUserQuestion`: `Resend` / `SendGrid` / `Mailgun` / `Other (specify)` / `Skip outbound` | All methods (Ghost requires SMTP for membership / newsletter / password-reset). Loads the matching `references/modules/smtp-*.md`. |
| smtp | "API key for `<provider>`?" | Free-text (sensitive — rotate after) | Resend keys start `re_`; SendGrid `SG.`; Mailgun varies. |
| smtp | "From address?" | Free-text | Must be on a verified domain at the provider. |
| smtp | "From display name?" | Free-text | E.g. `Aria Zhang`. Plain string — Claude wraps it correctly in JSON / env config. |
| inbound (optional) | "Set up inbound forwarding (e.g. `hello@<domain>` → your Gmail)?" | `AskUserQuestion`: `Yes — ImprovMX` / `Skip` | Loads `references/modules/inbound-improvmx.md`. |
| inbound | "Where should `<alias>@<domain>` forward to?" | Free-text | Existing inbox the user reads. |

Method-specific extras (e.g. Bitnami's `blueprint_id` / `bundle_id`, DigitalOcean's droplet size) are listed in the relevant method section.

After each prompt, write the value into the state file under `inputs.*` so a resume can skip re-asking.

## Mail configuration (cross-cutting JSON shape)

Ghost-CLI installs (Ubuntu, Local, DigitalOcean, Linode) and the Bitnami blueprint configure mail in `config.production.json`. The Docker preview maps the same fields onto `MAIL_*` env vars in `.env`. Canonical JSON shape:

```json
"mail": {
  "transport": "SMTP",
  "from": "'<Display Name>' <<from-address>>",
  "options": {
    "host": "<smtp-host>",
    "port": 465,
    "secure": true,
    "auth": {
      "user": "<smtp-user>",
      "pass": "<smtp-pass>"
    }
  }
}
```

Per-provider specifics: see `references/modules/smtp-*.md` (Resend, SendGrid, Mailgun) and upstream's <https://ghost.org/docs/config/#mail>.

### Verifying SMTP

Once configured, in Ghost admin: **Settings → Email newsletter → Send test email**, or add a member and publish a test post. Confirm arrival in the inbox AND the provider's dashboard / log.

Common failures:

- Wrong `user` — many providers use a literal string like `"resend"` or `"apikey"`, not the account email.
- Wrong port — `465` = implicit TLS `secure:true`; `587` = STARTTLS `secure:false`.
- Unverified sending domain at the provider.

If it fails, check Ghost's log:

- Ghost-CLI / Bitnami: `tail -n 200 <ghost-content-dir>/logs/*.log`
- Docker preview: `docker compose logs ghost`

---

## Method — Ghost-CLI on Ubuntu

> **Source:** <https://ghost.org/docs/install/ubuntu/> (TryGhost/Docs `install/ubuntu.mdx`).

The upstream-recommended production path. Ghost-CLI handles NGINX vhost, Let's Encrypt SSL, MySQL DB+user creation, systemd unit, and Ghost itself in a single interactive flow.

### Method-specific inputs

| Field | Value |
|---|---|
| Ubuntu version | `22.04` or `24.04` LTS — upstream-supported only |
| Sudo username | **NOT** `ghost` — upstream warns it conflicts with Ghost-CLI |
| Node major | Latest LTS supported by Ghost (currently `22`; check <https://ghost.org/docs/faq/node-versions/>) |
| Site dir name | Ghost-CLI requires its own dir under `/var/www/<sitename>/` |
| MySQL root password | Generated; needed during `ghost install` for DB creation |

DNS A-record must already point to the server's IP **before** running `ghost install` — Ghost-CLI runs Let's Encrypt during the flow, which fails without resolvable DNS.

### Server prep (Claude runs via SSH as root)

```bash
# 1. Create a non-root sudoer (must NOT be named 'ghost')
adduser "${SUDO_USER}"
usermod -aG sudo "${SUDO_USER}"

# 2. Update packages
apt-get update && apt-get upgrade -y

# 3. NGINX
apt-get install -y nginx
# Open firewall if ufw is active
ufw status | grep -q active && ufw allow 'Nginx Full'

# 4. MySQL 8 + switch root to password auth (Ghost does NOT support socket auth)
apt-get install -y mysql-server
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '${MYSQL_ROOT_PW}'; FLUSH PRIVILEGES;"

# 5. Node.js from Nodesource
apt-get install -y ca-certificates curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=22
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
  | tee /etc/apt/sources.list.d/nodesource.list
apt-get update && apt-get install -y nodejs
```

### Install Ghost-CLI + Ghost

```bash
# Ghost-CLI globally (run as root or with sudo)
sudo npm install -g ghost-cli@latest

# Switch to the non-root user before installing Ghost itself
su - "${SUDO_USER}"

# Create site dir
sudo mkdir -p "/var/www/${SITENAME}"
sudo chown "${SUDO_USER}:${SUDO_USER}" "/var/www/${SITENAME}"
sudo chmod 775 "/var/www/${SITENAME}"
cd "/var/www/${SITENAME}"

# Interactive install
ghost install
```

Upstream's `ghost install` prompts (answer using collected inputs):

| Prompt | Answer |
|---|---|
| Blog URL | `https://${CANONICAL_HOST}` (must include protocol; IP addresses cause errors) |
| MySQL hostname | `localhost` |
| MySQL username / password | `root` / `${MYSQL_ROOT_PW}` |
| Ghost database name | Generated (e.g. `ghost_prod`) |
| Set up a ghost MySQL user? | **Yes** (least-privilege; only the Ghost DB) |
| Set up NGINX? | **Yes** (upstream-recommended) |
| Set up SSL? | **Yes** — provide `${LETSENCRYPT_EMAIL}` |
| Set up systemd? | **Yes** |
| Start Ghost? | **Yes** |

### Verify

```bash
curl -sI "https://${CANONICAL_HOST}/"            # → 200 with valid cert
curl -sI "https://${CANONICAL_HOST}/ghost/"      # → 200 admin bootstrap
ghost ls                                          # → running, 'online'
ghost log                                         # → no startup errors
```

Then have the user open `https://${CANONICAL_HOST}/ghost` to claim the owner account (first user wins — guard this URL during the bootstrap window).

### Lifecycle

```bash
ghost stop             # stop
ghost start            # start
ghost restart          # restart
ghost log              # tail logs
ghost update           # in-place upgrade to latest Ghost
ghost help             # full command list
```

Recovery:

- `ghost uninstall` — clean removal (preferred over `rm -rf` to avoid orphan systemd units / NGINX vhosts).
- `ghost setup` — resume an interrupted install without rerunning everything.

### Ghost-CLI Ubuntu gotchas

- **Sudo username can't be `ghost`** — Ghost-CLI uses a `ghost` system user under the hood; collision causes the install to fail mid-flow.
- **MySQL root must be password-auth, not socket** — Ubuntu 22.04+ defaults to `auth_socket`; the `ALTER USER ... mysql_native_password` step above is mandatory.
- **DNS must propagate first** — Ghost-CLI runs Let's Encrypt inline. If the A-record isn't resolvable when `ghost install` reaches the SSL step, it errors. `dig +short ${CANONICAL_HOST}` should return the server IP before starting.
- **Web Analytics / self-hosted ActivityPub are NOT supported on Ghost-CLI** — upstream's `ubuntu.mdx` explicitly says these features need the Docker preview install. Ghost-CLI installs use Ghost(Pro)'s hosted ActivityPub service (free with usage caps).
- **Don't install in `/root`, `/home`, or anywhere outside `/var/www/<sitename>/`** — upstream is opinionated about the site dir layout; deviations break `ghost update` later.

---

## Method — Docker Compose (preview)

> **Source:** <https://ghost.org/docs/install/docker/> (TryGhost/Docs `install/docker.mdx`). Tooling repo: <https://github.com/TryGhost/ghost-docker>.

New batteries-included tooling shipped with Ghost 6.0. Caddy as webserver (handles TLS), MySQL, Ghost — plus opt-in profiles for self-hosted ActivityPub (`activitypub`) and Tinybird-backed Web Analytics (`analytics`). The only upstream path that supports self-hosting these two features.

### Method-specific inputs

| Field | Value |
|---|---|
| Linux distro | Any (DigitalOcean's 2GB/1CPU droplet is upstream's reference). Docker 20.10.13+ required. |
| Install dir | `/opt/ghost` (upstream convention; clone target) |
| `DOMAIN` | The canonical host (e.g. `${CANONICAL_HOST}`). |
| `ADMIN_DOMAIN` | Optional separate admin host (e.g. `admin.${APEX}`). |
| `DATABASE_ROOT_PASSWORD` / `DATABASE_PASSWORD` | Generated via `openssl rand -hex 32`. **Do not change once initialised** — it changes config but not the actual DB password, breaking connections. |
| ActivityPub | Off by default (uses Ghost(Pro) hosted ActivityPub, free up to 2000 followers / 2000 following / 100 interactions/day). Self-host by adding `activitypub` to `COMPOSE_PROFILES`. |
| Web Analytics | Requires a Tinybird account (free tier exists). Self-host by adding `analytics` to `COMPOSE_PROFILES`. |

DNS A-record (and optionally `ADMIN_DOMAIN`'s A-record) must already point at the server before `docker compose up` — Caddy obtains Let's Encrypt certs on first request.

### Install (Claude runs via SSH)

```bash
# 1. Install Docker per upstream's guide (https://docs.docker.com/engine/install/)
#    — handled by runtimes/docker.md preflight.

# 2. Clone the upstream tooling
sudo git clone https://github.com/TryGhost/ghost-docker.git /opt/ghost
cd /opt/ghost

# 3. Copy example config
sudo cp .env.example .env
sudo cp caddy/Caddyfile.example caddy/Caddyfile

# 4. Generate DB passwords
DB_ROOT_PW=$(openssl rand -hex 32)
DB_PW=$(openssl rand -hex 32)

# 5. Patch .env (Claude does this with sed/jq, NOT hand-editing)
sudo sed -i \
  -e "s|^DOMAIN=.*|DOMAIN=${CANONICAL_HOST}|" \
  -e "s|^DATABASE_ROOT_PASSWORD=.*|DATABASE_ROOT_PASSWORD=${DB_ROOT_PW}|" \
  -e "s|^DATABASE_PASSWORD=.*|DATABASE_PASSWORD=${DB_PW}|" \
  /opt/ghost/.env
# Plus the SMTP block per the cross-cutting Mail config above.

# 6. Edit Caddyfile blocks for the chosen DNS shape — see Caddy domain setup below.

# 7. Pull + start
sudo docker compose pull
sudo docker compose up -d
```

Visit `https://${CANONICAL_HOST}/` — Caddy provisions TLS on first request. Then `https://${CANONICAL_HOST}/ghost` to claim the owner account.

### Caddy domain setup (one of three shapes — pick one)

The `caddy/Caddyfile.example` ships with three commented-out blocks. Uncomment exactly one:

| Shape | What to uncomment | Required if |
|---|---|---|
| Separate admin domain | "Separate admin domains" block | `ADMIN_DOMAIN` is set |
| Apex (`mysite.com`) canonical, redirect `www` | "Redirect www → root domain" block + DNS for both | `DOMAIN=apex` and you want `www` → apex |
| `www.mysite.com` canonical, redirect apex | "Redirect root → www domain" block + DNS for both + replace `CHANGE_ME` with the apex | `DOMAIN=www.*` (**required for ActivityPub to work** when using a `www` canonical) |

Other variables come from `.env` and should not be edited in the Caddyfile.

### Optional — Web Analytics (Tinybird)

```bash
cd /opt/ghost

# 1. Login to Tinybird (interactive — opens browser)
sudo docker compose run --rm tinybird-login

# 2. Sync schema files into the shared volume
sudo docker compose run --rm tinybird-sync

# 3. Deploy datasources / pipes / endpoints
sudo docker compose run --rm tinybird-deploy

# 4. Get tokens to paste into .env
sudo docker compose run --rm tinybird-login get-tokens
```

Paste the four `TINYBIRD_*` values from step 4 into the Tinybird block of `.env`, then add `analytics` to `COMPOSE_PROFILES`:

```bash
sudo sed -i 's|^COMPOSE_PROFILES=.*|COMPOSE_PROFILES=analytics|' /opt/ghost/.env
sudo docker compose pull
sudo docker compose up -d
```

Verify by visiting the site homepage and checking that the visit appears under Ghost admin → **Analytics**.

### Optional — Self-hosted ActivityPub

```bash
# Add 'activitypub' to COMPOSE_PROFILES (combine with 'analytics' if both wanted)
sudo sed -i 's|^COMPOSE_PROFILES=.*|COMPOSE_PROFILES=analytics,activitypub|' /opt/ghost/.env

# Uncomment ACTIVITYPUB_TARGET so Ghost talks to the local ActivityPub container
sudo sed -i 's|^# *ACTIVITYPUB_TARGET=.*|ACTIVITYPUB_TARGET=activitypub:8080|' /opt/ghost/.env

# Restart ghost + caddy
sudo docker compose pull
sudo docker compose up -d --force-recreate ghost caddy
```

Verify under Ghost admin → **Network**.

### Migrating an existing Ghost-CLI install

Upstream ships a migration assistant that copies content + dumps DB + stops the existing NGINX-fronted Ghost-CLI install + brings up the Caddy-fronted Docker stack on the same host.

```bash
cd /opt/ghost
# (After cloning + setting up .env + Caddyfile, but BEFORE 'docker compose up -d')
sudo bash scripts/migrate.sh
```

The script offers a rollback (`bash recovery_instructions.sh`) if anything fails. Don't delete the old install until the new one is verified.

### Verify

```bash
curl -sI "https://${CANONICAL_HOST}/"
sudo docker compose ps           # all services 'running'
sudo docker compose logs ghost    # no startup errors
sudo docker compose logs caddy    # cert provisioning OK
```

### Lifecycle

```bash
cd /opt/ghost

# Update Ghost (pulls new tooling AND new images)
sudo git pull && sudo docker compose pull && sudo docker compose up -d

# Recreate ghost after editing .env
sudo docker compose up -d --force-recreate ghost

# Recreate ghost + caddy after editing DOMAIN / ADMIN_DOMAIN / ACTIVITYPUB_TARGET
sudo docker compose up -d --force-recreate ghost caddy

# Logs / state
sudo docker compose ps
sudo docker compose logs -f <service>

# Image cleanup
sudo docker image prune
```

### Docker preview gotchas

- **`DATABASE_*` passwords are write-once.** Changing them after first init breaks DB connectivity (the config changes but the actual stored password doesn't). Treat them as immutable; rotate by full DB recreate + restore from backup.
- **`www` canonical requires the "Redirect root → www" block uncommented and `CHANGE_ME` replaced with the apex** — required for ActivityPub to work correctly with `www` domains.
- **First-request TLS cert delay.** Caddy obtains certs on first hit, so the very first browser request can take a few seconds and may show a brief 502 if DNS hasn't fully propagated. Verify with `dig +short ${CANONICAL_HOST}` before declaring failure.
- **Tinybird deploy can fail mid-update.** When updating Ghost, the `tinybird-deploy` service runs new schema migrations against your workspace — if it fails, the previous deployment stays live, but new Ghost may expect the new schema. `docker compose logs tinybird-deploy` shows what went wrong.
- **Profiles are case-sensitive in `COMPOSE_PROFILES`.** Use `analytics`, `activitypub` (lowercase), comma-separated, no spaces.
- **Don't run alongside Ghost-CLI on the same host without using `scripts/migrate.sh`** — port 80/443 collisions between NGINX and Caddy will keep one of them down.

---

## Method — Local install (dev)

> **Source:** <https://ghost.org/docs/install/local/> (TryGhost/Docs `install/local.mdx`).

Fast-track local install for theme development or kicking the tyres. Runs Ghost in `development` mode against SQLite3 — explicitly **not** for production (no auth hardening, no TLS, no proper process supervision).

### Method-specific inputs

| Field | Value |
|---|---|
| Platform | Mac / Windows / Linux (any) |
| Node major | Latest LTS supported by Ghost (<https://ghost.org/docs/faq/node-versions/>) |
| Package manager | `npm` or `yarn` |
| Python 3 + setuptools | Required for native SQLite3 build (<https://ghost.org/docs/faq/python-setuptools-required-sqlite3>) |
| Install dir | A clean, empty directory the user picks |

### Install

```bash
# 1. Ghost-CLI globally (no sudo on Windows; sudo on Linux/macOS as needed)
npm install -g ghost-cli@latest

# 2. cd into an empty directory
mkdir -p ~/ghost-local && cd ~/ghost-local

# 3. Local install
ghost install local
```

When `ghost install local` finishes:

- Site UI: `http://localhost:2368`
- Admin UI: `http://localhost:2368/ghost`
- Mode: `development` (less caching than production)
- DB: SQLite3 auto-created at `<install-dir>/content/data/`
- Logs: `stdout` only (no log files)

### Lifecycle

```bash
ghost stop      # stop
ghost start     # start
ghost log       # tail logs
ghost ls        # list every Ghost instance on this machine
```

### Theme development (the main use case)

Custom themes go under `<install-dir>/content/themes/<theme-name>/`. Edits to existing files hot-reload; **adding new files** requires `ghost restart` to pick up.

Validate themes against the latest Ghost API with `gscan`:

```bash
npm install -g gscan

gscan /path/to/ghost/content/themes/<theme-name>     # validate a theme dir
gscan -z /path/to/theme.zip                           # validate a zip
```

The hosted version at <https://gscan.ghost.org/> is the same tool.

### Local install gotchas

- **Not production.** `ghost install local` runs in development mode with relaxed defaults — never expose this to the internet. For production, use Ghost-CLI on Ubuntu, the Docker preview, or DigitalOcean 1-Click.
- **Python 3 + setuptools.** Without these, the SQLite3 native build during `ghost install local` fails with cryptic gyp errors. Install via `brew install python@3.12` (macOS), apt's default (Linux), or python.org installer (Windows).
- **Multiple instances on one machine** — `ghost ls` shows them all. Each has its own port (2368, 2369, ...); `ghost install local --port 2369` for a second instance.
- **Background process survives shell exits.** `ghost stop` is the only clean shutdown — closing the terminal doesn't kill it.

---

## Method — Install from source (Ghost core dev)

> **Source:** <https://ghost.org/docs/install/source/> (TryGhost/Docs `install/source.mdx`).

For contributors modifying Ghost itself (server, admin client, default theme, helpers). Runs the monorepo with hot-reload; **not** an install method for users who just want to host a Ghost site — use Ghost-CLI Ubuntu or the Docker preview for that.

### Method-specific inputs

| Field | Value |
|---|---|
| Platform | Mac / Linux (Windows works but unofficial). |
| Node major | Latest LTS supported by Ghost — install via [nvm](https://github.com/creationix/nvm#install-script). |
| Docker | Required for the dev MySQL container + other services. |
| GitHub fork | Required unless on the Ghost core team (push access to `TryGhost/Ghost`). |

### Install

```bash
# 1. Fork TryGhost/Ghost on GitHub via the web UI.

# 2. Clone WITH submodules (admin client + default theme are submodules)
git clone --recurse-submodules git@github.com:TryGhost/Ghost && cd Ghost

# 3. (Non-core-team only) point origin at your fork
git remote rename origin upstream
git remote add origin git@github.com:<YourUsername>/Ghost.git

# 4. Enable pnpm + run upstream's setup
corepack enable pnpm
pnpm run setup        # installs deps, initialises the DB, sets up git hooks + submodules

# 5. Start in dev mode
pnpm dev
```

Once running:

- Site: <http://localhost:2368/>
- Admin: <http://localhost:2368/ghost/>

### Stay up to date

```bash
pnpm main             # update everything to latest main
```

### Dev commands

```bash
# Run variants
pnpm dev              # default — admin builds + watches for changes
pnpm dev:ghost        # ignore admin changes
pnpm dev:admin        # ignore server changes
pnpm dev --portal     # also run the Portal dev server

# DB migrations (Ghost uses its own knex-migrator)
pnpm knex-migrator reset       # wipe
pnpm knex-migrator init        # populate fresh

# Build a production tarball (for installing into a Ghost-CLI site via 'ghost install --archive')
pnpm archive

# Tests
pnpm test:unit
pnpm test:acceptance
pnpm test:regression
pnpm test:single path/to/test.js
pnpm test:all
pnpm lint
```

Client (admin) tests live under `ghost/admin/` and use ember-cli; run `ember test` there while `pnpm dev` is up.

### Source-install gotchas

- **Submodules must be initialised** — clone with `--recurse-submodules`, or `git submodule update --init --recursive` after the fact. Skipping this leaves the admin client + default theme empty.
- **Don't run `ember test` and `pnpm dev` simultaneously** — they fight over the admin build directory; wait for tests to finish.
- **`pnpm fix` resolves most "Cannot find module" errors** — happens after switching Node versions or interrupting an install.
- **`pnpm-lock.yaml` rebase conflicts** — don't hand-merge. `git reset HEAD package.json pnpm-lock.yaml` + `git checkout -- package.json pnpm-lock.yaml`, then re-run the dependency add/remove that caused the conflict, then `git add` + `git rebase --continue`.
- **Source install is dev-only.** Don't deploy `pnpm dev` output to a public URL. Production deploys go through Ghost-CLI's `--archive` flag against a tarball built with `pnpm archive`.

---

## Method — DigitalOcean 1-Click marketplace

> **Source:** <https://ghost.org/docs/install/digitalocean/> (TryGhost/Docs `install/digitalocean.mdx`). Marketplace listing: <https://marketplace.digitalocean.com/apps/ghost>.

DigitalOcean is upstream's "official hosting partner" — the marketplace droplet is the only third-party platform Ghost officially endorses. Mechanically it provisions a DO Droplet pre-loaded with Ghost-CLI, then drops you into the same `ghost install` flow as the Ubuntu method.

### Method-specific inputs

| Field | Value |
|---|---|
| DO account | Required. Account-level SSH key must be uploaded **before** droplet creation. |
| Droplet size | Smallest current shared-CPU plan is sufficient for a personal blog; size up for high traffic / many members. |
| Single droplet only | Ghost is single-process and **cannot** be sharded across droplets. |
| Domain | Mandatory (for SSL provisioning during the Ghost-CLI flow). |

### Provision (browser-driven, Claude can't fully automate)

This step is a click-flow in the DO UI; Claude reads it aloud and verifies the result:

1. Open <https://marketplace.digitalocean.com/apps/ghost> and click **Create Ghost Droplet**.
2. Pick a plan (default is fine for a blog), region, and SSH key. Create exactly **one** droplet.
3. Once the droplet has a public IP, set the DNS A-record for `${CANONICAL_HOST}` → that IP. Wait for propagation (`dig +short ${CANONICAL_HOST}`).

### First SSH = Ghost-CLI auto-flow

```bash
ssh root@${PUBLIC_IP}
```

On first login, the droplet auto-runs an update check and prepares the Ghost-CLI environment, then prompts:

```
Ghost will prompt you for two details:

1. Your domain
2. Your email address (only used for SSL)

Press enter when you're ready to get started!
```

Press Enter, then answer the prompts:

| Prompt | Answer |
|---|---|
| Blog URL | `https://${CANONICAL_HOST}` (must include `https://`; IPs cause errors) |
| Email | `${LETSENCRYPT_EMAIL}` |

Ghost-CLI then installs + configures Ghost + obtains the SSL cert. The remaining install questions (NGINX setup / SSL setup / systemd / start Ghost) accept the same answers as the Ubuntu method — see that section's prompt-to-answer table.

### Verify

Same as Ghost-CLI Ubuntu: `curl -sI`, `ghost ls`, `ghost log`. Then claim the owner account at `https://${CANONICAL_HOST}/ghost`.

### Lifecycle

Identical to Ghost-CLI Ubuntu — `ghost help`, `ghost update`, `ghost stop / start / restart`, `ghost log`. The only difference is the underlying VM is a DO Droplet (vs a manually-provisioned Ubuntu host).

### DigitalOcean 1-Click gotchas

- **DNS propagation before first SSH.** Ghost-CLI's auto-flow runs Let's Encrypt as part of the prompt sequence — the A-record must be resolvable before you press Enter, or the SSL step fails. If it fails, run `ghost setup ssl` later.
- **Single droplet, no sharding.** Ghost has no horizontal-scale story; if the user expects load-balanced multi-droplet, they're on the wrong path.
- **Failed install recovery.** Same commands as Ghost-CLI Ubuntu: `ghost uninstall` for a clean wipe, `ghost setup` to resume.

---

## Method — Linode VPS

> **Source:** <https://ghost.org/docs/install/linode/> (TryGhost/Docs `install/linode.mdx`).

A thin wrapper around the Ghost-CLI Ubuntu method on Linode infrastructure. Upstream's `linode.mdx` is essentially three lines of guidance: provision a secured Ubuntu Linode, then follow the Ubuntu method.

### Method-specific inputs

| Field | Value |
|---|---|
| Linode image | **Ubuntu** — 22.04 LTS or 24.04 LTS only |
| RAM | ≥ 1 GiB |
| Sudo username | **NOT** `ghost` (same constraint as Ghost-CLI Ubuntu) |

### Provision

Follow Linode's own guides (Claude links them; user clicks through their account):

1. **Provision the Linode.** Pick the Ubuntu image. <https://www.linode.com/docs/guides/getting-started/>.
2. **Secure the Linode.** Standard hardening: non-root user, SSH key auth only, firewall, package updates. <https://www.linode.com/docs/guides/securing-your-server/>.
3. Once the Linode is configured + secured, switch to **Method — Ghost-CLI on Ubuntu** above and run that flow on the Linode VM.

There are no Linode-specific install commands — the entire Ghost install is the Ubuntu method.

### Linode-specific gotchas

- **Image must be Ubuntu.** Other Linode images (Debian, AlmaLinux, etc.) are not upstream-supported for Ghost-CLI. Pick Ubuntu LTS at create time.
- **Username constraint applies here too** — even if Linode's own guides default to `linode` or another name, ensure the Ghost-install user is **not** named `ghost`.
- **Linode firewalls are off by default on basic plans.** Either enable Linode Cloud Firewall (UI) or use `ufw` on the Linode itself; either way, allow ports 22, 80, 443.

---

## Method — Bitnami blueprint (community-maintained)

> ⚠️ **Community-maintained.** Bitnami is not affiliated with TryGhost, and this method is **not** listed in upstream's install index at <https://ghost.org/docs/install/>. The Bitnami Ghost stack ships as an AWS Lightsail blueprint (and other marketplace channels). Verify Bitnami's own docs (<https://docs.bitnami.com/>) for current versions, paths, and gotchas at deploy time — they may have changed since this section was written.

The Bitnami Ghost blueprint bundles Ghost, Node, MySQL, and Apache as a reverse proxy. Ghost itself listens on `127.0.0.1:2368`; Apache terminates TLS and proxies to it.

### Bitnami-specific inputs

After preflight (which gathers AWS profile/region/deployment name), the cross-cutting prompts above cover domain / TLS / SMTP. Bitnami additionally needs:

| Field | Value |
|---|---|
| `blueprint_id` | `ghost_5` (latest Ghost major the blueprint ships with — version may be `6.x` in practice) |
| `bundle_id` | `nano_3_0` works for a personal blog; upgrade to `micro_3_0`+ for real traffic |

### Initial admin credentials

Right after provision, the initial admin email + password live in a file on the instance:

```bash
ssh -i "$KEY_PATH" "bitnami@$PUBLIC_IP" 'sudo cat /home/bitnami/bitnami_credentials'
```

Save the admin URL for the state file:

```
outputs.admin_url: https://<canonical-host>/ghost
```

Remind the user to change the password during the **hardening** phase.

### Paths

| Thing | Path |
|---|---|
| App root | `/opt/bitnami/ghost/` |
| Config | `/opt/bitnami/ghost/config.production.json` |
| Apache HTTPS vhost | `/opt/bitnami/apache/conf/vhosts/ghost-https-vhost.conf` |
| Apache HTTP vhost | `/opt/bitnami/apache/conf/vhosts/ghost-vhost.conf` |
| ctlscript | `/opt/bitnami/ctlscript.sh` |

### Restart command

After any config change:

```bash
sudo /opt/bitnami/ctlscript.sh restart
```

Takes 10–20s. Ghost logs to `/opt/bitnami/ghost/logs/` (check if it fails to start).

### TLS via bncert-tool

Bitnami ships a Let's Encrypt helper called `bncert-tool`. It does **not** support `--mode unattended` — attempting that prints "Unattended mode is not supported yet" and exits.

**Use `--mode text` with an option file.** Piping `yes` does not work — the flags get ignored and the tool re-prompts.

Write the option file:

```bash
cat > /tmp/bncert.opts <<EOF
domains=${APEX} ${CANONICAL_HOST}
email=${LETSENCRYPT_EMAIL}
accept_tos=1
enable_https_redirection=1
enable_www_to_nonwww_redirection=0
enable_nonwww_to_www_redirection=1
EOF
```

Note: redirect direction flags in the option file are finicky and sometimes do not override the tool's interactive default. Verify after the fact with `curl -sI`. If the canonical ended up reversed from what was asked, either re-run the tool or accept it and document.

Run:

```bash
sudo /opt/bitnami/bncert-tool --mode text --optionfile /tmp/bncert.opts
```

The tool rewrites the Apache vhosts and obtains + installs the cert. Ports 80/443 must be reachable from the internet first — DNS must already resolve to the instance.

Verify:

```bash
curl -sI "https://${CANONICAL_HOST}/"
```

Expect `HTTP/1.1 200` or `301/302` with a valid certificate.

### Switch Ghost's URL to https

Ghost stores its canonical URL in `config.production.json`. After TLS is working, update it:

```bash
ssh … 'sudo jq ".url = \"https://'"${CANONICAL_HOST}"'\"" /opt/bitnami/ghost/config.production.json > /tmp/ghost-config.json \
       && sudo mv /tmp/ghost-config.json /opt/bitnami/ghost/config.production.json \
       && sudo chown bitnami:daemon /opt/bitnami/ghost/config.production.json'
sudo /opt/bitnami/ctlscript.sh restart
```

#### ⚠️ Apache reverse-proxy fix (critical — do this at the same time)

If Apache proxies requests to Ghost without forwarding the original scheme/host, Ghost sees the request as HTTP and redirects back to `https://127.0.0.1:2368/` — the site dies with a redirect loop or dropped connections.

Edit `/opt/bitnami/apache/conf/vhosts/ghost-https-vhost.conf`. Directly before the `ProxyPass / http://127.0.0.1:2368/` line, add:

```apache
ProxyPreserveHost On
RequestHeader set X-Forwarded-Proto "https"
```

Restart Apache:

```bash
sudo /opt/bitnami/ctlscript.sh restart apache
```

Verify the site loads in a browser and the admin UI at `/ghost` does not bounce. Stale 301s from the broken state can stick around in the browser — suggest a hard reload or incognito window.

### Bitnami mail configuration

The cross-cutting JSON shape above goes into `/opt/bitnami/ghost/config.production.json`. Apply with `jq`, not hand-editing — `config.production.json` is JSON and a stray comma breaks Ghost on startup:

```bash
# Build new mail block in a temp file, then splice it in
sudo jq --slurpfile m /tmp/mail.json '.mail = $m[0]' \
  /opt/bitnami/ghost/config.production.json > /tmp/ghost-config.json \
  && sudo mv /tmp/ghost-config.json /opt/bitnami/ghost/config.production.json \
  && sudo chown bitnami:daemon /opt/bitnami/ghost/config.production.json
sudo /opt/bitnami/ctlscript.sh restart
```

### Bitnami database

Bitnami provisions MySQL on localhost with a generated password. Ghost is already wired up; normally no action is needed. If you need direct DB access, the creds are in `config.production.json` under `database.connection`.

### Bitnami gotchas summary

- **bncert-tool**: text mode + option file, no `--unattended`, don't pipe `yes`.
- **Redirect direction**: option-file `enable_*_redirection` flags sometimes ignored — verify with `curl -sI`.
- **Apache proxy after https URL**: must add `ProxyPreserveHost On` + `X-Forwarded-Proto "https"` or Ghost dies with loops.
- **JSON config**: always edit with `jq`, restore ownership to `bitnami:daemon`.
- **Restart timing**: `ctlscript.sh restart` takes 10–20s; site 502s briefly during restart.
- **Stale 301s in browser**: after any redirect change, hard reload or incognito.

---

## Method — Docker Hub community image

> **Source:** <https://ghost.org/docs/install/docker-community/> (TryGhost/Docs `install/docker-community.mdx`). Image: <https://hub.docker.com/_/ghost>. Maintained by the docker-library community at <https://github.com/docker-library/ghost>.

_Section content added in a subsequent commit (Task H of the granular fix plan)._

---

## TODO — verify on subsequent deployments

- **Tasks B–H of the granular fix plan**: fill in the placeholder method sections in subsequent commits (Ghost-CLI Ubuntu, Docker Compose preview, Local, Source, DigitalOcean 1-Click, Linode, Docker Hub community).
- **First Ghost-CLI Ubuntu deploy**: verify the install-question list, NGINX vhost paths, and systemd unit name match what's on real Ubuntu 22.04 / 24.04 in 2026.
- **First Docker Compose preview deploy**: verify the `ghost-docker` repo structure + `.env.example` fields haven't drifted; verify Tinybird workspace creation flow end-to-end.
- **First DigitalOcean 1-Click deploy**: confirm a base droplet still spins the Ghost-CLI flow on first SSH (per upstream `digitalocean.mdx`).
- **First Linode deploy**: confirm "follow Ubuntu guide" minimal-wrapper still applies; record any Linode-specific firewall / image gotchas.
- **Bitnami Apache reverse-proxy fix**: verify it's still required on the latest Bitnami `ghost_5` blueprint (may be fixed upstream by Bitnami).
- **Docker Hub community image**: confirm the latest tag layout (`5-alpine` vs `6-alpine` etc.) and document migration semantics if a user starts here then later moves to the ghost-docker preview.

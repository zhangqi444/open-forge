---
name: Pterodactyl
description: "Open-source game server management panel. Web UI for creating/controlling dozens of game servers (Minecraft, Valheim, Rust, ARK, CS:GO, source engine, etc.) each in isolated Docker containers. Panel (PHP/Laravel/React) + Wings daemon (Go). MIT."
---

# Pterodactyl

Pterodactyl is the canonical **open-source game server hosting panel** — what your local Minecraft host or indie game-server company most likely uses under the hood. A slick web UI where admins provision game servers, players control their own servers (start/stop/console/files/backups/scheduling), and every server runs inside an **isolated Docker container** with CPU/memory/disk limits.

Two components:

- **Panel** (PHP/Laravel/React) — the web UI + API
- **Wings** (Go daemon) — runs on each game-server host; talks to Docker locally + reports to the Panel

Supported games (via "Eggs" — YAML install + run recipes):

- **Minecraft** (Java + Bedrock, Paper, Spigot, Forge, Fabric, ...)
- **Valheim, Rust, ARK, CS:2, CS:GO, Source engine games, TF2, Garry's Mod**
- **Factorio, Terraria, 7 Days to Die, Unturned**
- **Satisfactory, Palworld, V Rising, Enshrouded, Ark SE**
- **Generic voice (Mumble, TeamSpeak, self-hosted Discord alternatives)**
- Hundreds more via community Eggs

Core features:

- **Per-server Docker containers** with resource limits
- **Web console** (xterm.js) — type commands, watch output
- **File manager** — browse/edit server files via web
- **Scheduled tasks** — cron-like (restart, backup, broadcast)
- **Backups** — local or S3-compatible (R2, Wasabi, B2, ...)
- **Sub-users + permissions** — give moderators specific access
- **OAuth / 2FA**
- **API** for automation
- **Multi-node** — one Panel + many Wings hosts; pin servers per node
- **Resource monitoring** dashboard (CPU/RAM/disk/network per server)
- **Two-factor auth** on users + sudo-style on critical actions

- Upstream Panel repo: <https://github.com/pterodactyl/panel>
- Wings daemon repo: <https://github.com/pterodactyl/wings>
- Docs: <https://pterodactyl.io>
- Community Eggs: <https://github.com/pelican-eggs/eggs> (and many forks)
- Discord: <https://discord.gg/pterodactyl>

## Architecture in one minute

- **Panel (PHP/Laravel 10+ + React)** — the web app; needs MySQL/MariaDB + Redis + PHP 8.1+
- **Wings (Go)** — node daemon; talks Docker; streams console via SFTP/WebSocket
- **Database**: MySQL/MariaDB required for Panel
- **Redis**: required for sessions + queue
- **SFTP server (Wings-embedded)** — players connect via SFTP for file access
- **TLS**: Wings ↔ Panel requires TLS; use Let's Encrypt on both
- **Docker on each game node** — Wings manages containers

Small deployment: Panel + Wings on same host. Bigger: dedicated Panel server + multiple Wings nodes.

## Compatible install methods

| Infra       | Runtime                                                  | Notes                                                           |
| ----------- | -------------------------------------------------------- | --------------------------------------------------------------- |
| Single VM   | Panel + Wings on one host                                   | **Beginner path** — smallish home use                               |
| Multi-node  | 1 Panel VM + N Wings VMs                                       | **Production path** — real hosting                                        |
| Installer   | Community installer script (untrusted; read first!)              | `pterodactyl-installer` on GitHub                                               |
| Native      | Per docs (Panel: PHP-FPM + nginx + MySQL; Wings: systemd Go binary) | The canonical supported path                                                     |
| Docker Panel | Community Docker images                                              | Panel in Docker works; Wings should NOT be dockerized (needs host Docker access)       |

## Inputs to collect

| Input               | Example                         | Phase     | Notes                                                           |
| ------------------- | ------------------------------- | --------- | --------------------------------------------------------------- |
| Panel FQDN          | `panel.example.com`               | DNS + TLS | Used in email + API URLs                                              |
| Wings FQDN per node | `node1.example.com`                 | DNS + TLS | TLS required for Panel↔Wings                                                  |
| DB creds            | MySQL/MariaDB user+db               | DB        | Panel uses MySQL/MariaDB                                                              |
| Redis               | localhost / shared                    | Queue     | Sessions + queue                                                                               |
| SMTP                | host + port + creds                     | Email     | Password resets, invites, notifications                                                                      |
| TLS certs           | Let's Encrypt                             | Security  | Both Panel + every Wings node                                                                                        |
| Docker on Wings     | Docker Engine 20+ on each node               | Runtime   | Pterodactyl strictly requires Docker on game nodes                                                                              |
| Ports               | 80/443 panel; 8080/2022 wings                  | Network   | 2022 = SFTP on Wings                                                                                                 |

## Install — Panel (summary; see docs for full)

```sh
# On panel server (Ubuntu 22.04):
# Install PHP 8.1, MariaDB, Redis, nginx
apt install -y nginx mariadb-server php8.1-{cli,fpm,mysql,gd,mbstring,bcmath,xml,curl,zip} redis-server tar unzip git composer

mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache
cp .env.example .env
composer install --no-dev --optimize-autoloader

php artisan key:generate --force
php artisan p:environment:setup    # wizard: URL, cache, queue, session
php artisan p:environment:database # DB connection
php artisan p:environment:mail     # SMTP

php artisan migrate --seed --force
php artisan p:user:make   # create admin

chown -R www-data:www-data /var/www/pterodactyl/*
# nginx config: see docs. PHP-FPM proxy pass, TLS via Certbot.
```

## Install — Wings (summary)

```sh
# On each game-server node:
curl -Lo /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
chmod u+x /usr/local/bin/wings

# Install Docker Engine
# In Panel UI: Admin → Nodes → Create → fill FQDN, memory, disk
# Panel generates auto-deploy command; copy-paste on node:
cd /etc/pterodactyl && wings configure --token <token> --url https://panel.example.com

# systemd unit:
cat > /etc/systemd/system/wings.service << 'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now wings
```

## Use

1. Log in to Panel
2. Admin → Nodes → create node(s); deploy Wings
3. Admin → Nests → Eggs → import Eggs for games you want (e.g., `paper.json` for Paper Minecraft)
4. Admin → Servers → Create Server → pick node + Egg + memory/disk limits + owner user
5. Wings pulls the Docker image + runs the Egg's install script + starts the server
6. Hand off the server URL to the owner user — they manage via their own Panel login

## Data & config layout

**Panel** (`/var/www/pterodactyl`):

- `.env` — app config
- `database/database.sqlite` (dev) or MySQL
- `storage/app/` — uploads
- `storage/logs/` — logs

**Wings** (`/etc/pterodactyl`):

- `config.yml` — node config
- Wings creates `/var/lib/pterodactyl/volumes/<server-uuid>/` for each server's files
- Docker manages container state

## Backup

```sh
# Panel DB
mysqldump -upanel -p panel | gzip > pterodactyl-panel-$(date +%F).sql.gz

# Panel .env + storage
tar czf pterodactyl-panel-files-$(date +%F).tgz /var/www/pterodactyl/.env /var/www/pterodactyl/storage

# Wings: back up server volumes
tar czf wings-volumes-$(date +%F).tgz /var/lib/pterodactyl/volumes

# OR: use Pterodactyl's built-in backup feature (per-server) — stores to S3 or local
```

## Upgrade

1. Releases: <https://github.com/pterodactyl/panel/releases> (Panel) + <https://github.com/pterodactyl/wings/releases> (Wings)
2. **Back up first** — DB + `.env` + Wings volumes
3. Panel: `php artisan down` → download new release → extract over → `composer install --no-dev` → `php artisan migrate --force` → `php artisan up`
4. Wings: download new `wings` binary → `systemctl restart wings`
5. Keep Panel and Wings **in sync** (close major versions). Major mismatches break node API.
6. 1.11.x is the current stable line (check releases).

## Gotchas

- **Wings must run as root on the node** — it manages Docker + host files + network. Don't run on a host with other sensitive services unless you trust the isolation.
- **Pterodactyl is EOL-threatened by the community "Pelican Panel" fork** — as of 2024, key Pterodactyl contributors launched [Pelican Panel](https://pelican.dev) as an opinionated rewrite. Pterodactyl continues but development cadence has slowed. Consider **Pelican Panel** for new deployments. (Both are open source and similar in spirit.)
- **Games with anti-cheat that check "is this a server under my control"** — Battleye and similar sometimes dislike containerized servers. Research before choosing.
- **Resource over-commit** — Pterodactyl lets you over-allocate memory per node; combined with spiky games (Minecraft chunks loading), this causes OOM kills. Leave headroom.
- **Disk space monitoring** — each server has a disk quota; if quota is full, players can't save new chunks/data/uploads. Monitor.
- **SFTP port 2022** — on Wings, by default; players connect via SFTP client with their Panel credentials to upload/download files.
- **Docker on Wings**: Docker daemon must be running + user creating containers is root-equivalent. Security: if a player escapes their container, they have host-root. This is a known limitation; use kernel hardening (seccomp, AppArmor) + dedicated Wings host per customer for multi-tenant use.
- **Backups to S3-compatible** — configure in Panel admin → backup driver. Local backups eat Wings disk fast; S3 (R2/B2/Wasabi) is cheaper.
- **Eggs are YAML recipes** — upstream maintains many; community forks fill gaps. Read Egg source before importing (it's shell + env vars).
- **Minecraft-specific**: Pterodactyl's Eggs support Paper, Spigot, Forge, Fabric, Bedrock, proxies (BungeeCord, Velocity). Very mature.
- **Voice servers** (Mumble, TeamSpeak) supported; Discord-like platforms aren't games so not typical targets.
- **Two-factor auth** — enable on admin accounts. High-value target for griefers/hackers.
- **Player subuser permissions** — granular. Give your mods "can restart" but not "can delete files."
- **Panel email** — SMTP must work; otherwise password resets + invites fail. Test with `php artisan p:environment:mail` wizard.
- **Firewall on Wings** — open only 8080 (Wings API), 2022 (SFTP), and your game ports. Panel does NOT need to reach Docker directly — it talks to Wings on 8080.
- **Public IP on Wings** — each Wings node needs a public IP so players can connect to game servers. NAT + port-forwarding works for homelabs.
- **License**: MIT (permissive).
- **Commercial hosts** using Pterodactyl is a large industry — BisectHosting, Nitrado, Shockbyte, Pebblehost, ApexHosting many run it.
- **Alternatives worth knowing:**
  - **Pelican Panel** — Pterodactyl fork/rewrite; more active; backwards-compatible Egg-ish design <https://pelican.dev>
  - **AMP (Application Management Panel)** — commercial; popular with one-shot home users
  - **LinuxGSM** — shell-script based; no web UI; great for one server
  - **Crafty Controller** — Minecraft-focused web UI
  - **WISP** — commercial game hosting panel (fork of Pterodactyl with BSL-ish license; now abandoned?)
  - **Choose Pterodactyl if:** you want mature production game hosting + large Egg ecosystem.
  - **Choose Pelican if:** you're starting fresh in 2025+.
  - **Choose Crafty if:** Minecraft only.
  - **Choose LinuxGSM if:** you're running one server and don't need a web panel.

## Links

- Panel repo: <https://github.com/pterodactyl/panel>
- Wings repo: <https://github.com/pterodactyl/wings>
- Docs: <https://pterodactyl.io>
- Panel docs: <https://pterodactyl.io/panel/1.0/getting_started.html>
- Wings docs: <https://pterodactyl.io/wings/1.0/installing.html>
- Community Eggs: <https://github.com/pelican-eggs/eggs>
- Pelican Panel (successor fork): <https://pelican.dev>
- Discord: <https://discord.gg/pterodactyl>
- Releases (Panel): <https://github.com/pterodactyl/panel/releases>
- Releases (Wings): <https://github.com/pterodactyl/wings/releases>
- Sponsors: <https://github.com/sponsors/pterodactyl>

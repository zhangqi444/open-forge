---
name: sourcebans-pp
description: SourceBans++ recipe for open-forge. Admin, ban, and communication management system for Source engine game servers (CS:GO, TF2, etc.). Web panel + SourceMod plugin. PHP 8.2+ + MySQL. Source: https://github.com/sbpp/sourcebans-pp
---

# SourceBans++

Global admin, ban, and communication management web panel for game servers running on Valve's Source engine (CS:GO, CS2, TF2, L4D2, etc.). Provides a web UI for managing bans, mutes, gags, and admins across multiple Source game servers, plus a SourceMod plugin that enforces bans server-side. PHP 8.2+ + MySQL/MariaDB. CC-BY-SA-4.0 licensed.

Upstream: <https://github.com/sbpp/sourcebans-pp> | Docs: <https://sbpp.github.io/docs/>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose (dev stack) | PHP 8.2 + Apache + MariaDB + Adminer |
| Linux | LAMP/LEMP (manual) | PHP 8.2+, MySQL 5.6+/MariaDB 10+, Apache/Nginx |
| Source game server | SourceMod 1.11+ + MetaMod:Source | Required on game server for ban enforcement |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Source game server(s) with MetaMod:Source + SourceMod installed | Required for server-side ban enforcement |
| config | MySQL/MariaDB host, DB name, user, password | |
| config | Web panel domain/URL | Used in admin links and email notifications |
| config | Admin email | For web panel admin account |
| config | PHP memory_limit ≥ 64M | Required |
| config | PHP GMP extension enabled | Required |

## Software-layer concerns

### Architecture

- **Web panel** — PHP 8.2+ app served by Apache or Nginx; connects to MySQL for ban data
- **SourceMod plugin** — compiled `.smx` plugin installed on each game server; connects to MySQL to enforce bans in-game
- **Shared MySQL database** — both the web panel and game server plugins read/write the same DB

### PHP requirements

- PHP 8.2+
- Extensions: GMP (required), standard web extensions (curl, pdo_mysql, mbstring, etc.)
- `memory_limit` ≥ 64M in php.ini

### Key files (web panel)

| File/Dir | Description |
|---|---|
| `includes/config.php` | DB credentials and site config |
| `install/` | Web installer (delete after install) |
| `addons/sourcemod/plugins/` | Compiled `.smx` SourceMod plugin files |
| `addons/sourcemod/configs/` | SourceMod plugin config files |

## Install — Release (recommended)

```bash
# 1. Download latest release (includes compiled plugins + dependencies)
# https://github.com/sbpp/sourcebans-pp/releases/latest
wget https://github.com/sbpp/sourcebans-pp/releases/latest/download/sbpp-web-panel.zip
unzip sbpp-web-panel.zip -d /var/www/sbpp

# 2. Create MySQL database
mysql -u root -p <<SQL
CREATE DATABASE sourcebans;
CREATE USER 'sbpp'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON sourcebans.* TO 'sbpp'@'localhost';
SQL

# 3. Configure web server to serve /var/www/sbpp
#    (Apache virtual host or Nginx server block)

# 4. Run the web installer: http://yourserver/install/
#    Follow the quickstart guide at https://sbpp.github.io/docs/quickstart/

# 5. Delete install/ directory after setup completes
rm -rf /var/www/sbpp/install/
```

See the quickstart guide at https://sbpp.github.io/docs/quickstart/ for the complete walkthrough.

## Install — Docker (local dev)

```bash
git clone https://github.com/sbpp/sourcebans-pp.git
cd sourcebans-pp

./sbpp.sh up        # build + start; panel at http://localhost:8080 (admin/admin)
./sbpp.sh logs web  # tail logs
./sbpp.sh down      # stop
# ./sbpp.sh reset   # stop + drop volumes (fresh start)
```

The dev Docker stack includes PHP 8.2 + Apache, MariaDB, Adminer, and Mailpit. DB schema and default admin are seeded automatically on first boot.

## SourceMod plugin setup (game server)

```
# Copy from the release zip to your game server:
addons/sourcemod/plugins/sbpp_main.smx         -> gameserver/addons/sourcemod/plugins/
addons/sourcemod/configs/sourcebans.cfg.txt     -> gameserver/addons/sourcemod/configs/

# Edit sourcebans.cfg on the game server:
# Set DB host, database, user, password to match the web panel DB
# Set website URL

# Restart the game server / reload SourceMod
sm plugins reload sbpp_main
```

## Upgrade procedure

```bash
# Web panel: download new release zip, overwrite files (preserve config.php)
# Run DB migrations via /install/ if prompted (check release notes)
# Delete install/ after upgrading

# SourceMod plugin: replace .smx file, reload plugin on game server
```

## Gotchas

- Game servers require MetaMod:Source AND SourceMod 1.11+ — SourceMod alone is not enough. Install MetaMod first, then SourceMod on top.
- Use release packages, not the master branch — master doesn't include compiled `.smx` plugins or PHP Composer dependencies. The release zip bundles everything needed.
- Delete the `install/` directory after completing setup — leaving it accessible is a security risk.
- PHP GMP extension is required — without it the web panel will throw errors. Enable it in php.ini: `extension=gmp`.
- Shared MySQL database: the game server plugin and web panel must connect to the same MySQL host/database. Configure `sourcebans.cfg` on each game server with the same credentials.
- Multiple game servers can all connect to the same SourceBans++ instance — each server registers separately in the web panel.

## Links

- Source: https://github.com/sbpp/sourcebans-pp
- Documentation: https://sbpp.github.io/docs/
- Quickstart guide: https://sbpp.github.io/docs/quickstart/
- FAQ: https://sbpp.github.io/faq/
- Discord: https://discord.gg/4Bhj6NU

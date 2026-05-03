# Calorific

> Dead-simple self-hosted calorie tracker — log meals, save reusable meals and ingredients, track daily calorie goals, and generate log entries from saved items. No macro management, no complexity. PHP + MySQL/MariaDB; runs on a standard AMP stack or Docker.

**Official URL:** https://github.com/xdpirate/calorific

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Easiest; MySQL included |
| Existing LAMP stack | PHP + MySQL/Apache | Drop-in; no build step |
| Existing LEMP stack | PHP + MySQL/Nginx | Should work; less tested |

---

## Inputs to Collect

### Phase: Pre-Deploy (Docker)
Edit `docker-compose.yml` — change MySQL credentials before first run:
| Input | Description | Example |
|-------|-------------|---------|
| MySQL user | DB username in compose | change from default `calorific` |
| MySQL password | DB password in compose **and** `index.php` | use strong unique value |
| MySQL root password | MariaDB root password | strong password |

### Phase: Pre-Deploy (AMP Stack)
Create `credentials.php` in the Calorific directory:
```php
<?php
$mysqlHost = "localhost";
$mysqlUser = "calorific_user";
$mysqlPassword = "yourpassword";
$mysqlDB = "calorific";  // optional; defaults to 'calorific'
// Uncomment for MySQL < 8 or MariaDB < 11.4.5:
// $mysqlCollation = "utf8mb4_general_ci";
```

---

## Software-Layer Concerns

### Docker Compose (Quick Start)
```bash
git clone https://github.com/xdpirate/calorific
cd calorific

# IMPORTANT: edit docker-compose.yml and change MySQL credentials first!
# Also update credentials in index.php to match

docker compose up -d
```
Wait 10–20 seconds after first run for the database to initialize, then visit http://localhost:1338

### AMP Stack Install
```bash
# Clone into web root
sudo git clone https://github.com/xdpirate/calorific /var/www/html/calorific

# Create credentials file
cat > /var/www/html/calorific/credentials.php << 'PHP'
<?php
$mysqlHost = "localhost";
$mysqlUser = "calorific_user";
$mysqlPassword = "yourpassword";
PHP

# Calorific creates the database schema automatically on first load
```

### Data Directories
| Path | Purpose |
|------|---------|
| MySQL/MariaDB volume | All meal logs, saved meals, ingredients |

### Ports
- Docker default: `1338`
- AMP stack: whatever port your web server runs on

### Built-in Updater
The UI has an Update button (bottom right) for `git pull` updates. **Only enable on trusted networks:**
- Requires `git` installed on the server
- Requires the app to run outside Docker
- Enable in `credentials.php`: `$updaterEnabled = true;`
- Disable after updating

---

## Upgrade Procedure

**Docker:**
1. `git pull` in the repository directory
2. `docker compose down && docker compose up -d`

**AMP stack:**
1. `git pull` in the Calorific directory (or use the built-in updater)
2. Calorific handles any schema changes automatically on next load

---

## Gotchas

- **Change Docker credentials before first run** — the default MySQL username/password are in the repository in plain text; change them in `docker-compose.yml` AND `index.php` before deploying externally
- **No authentication** — Calorific has zero login/auth; designed for local network use; protect with a reverse proxy + auth layer (htpasswd, Authelia, VPN) if accessible externally
- **Built-in updater security** — the updater passes credentials to the OS; only enable in trusted environments; keep it disabled in production
- **Hour offsets** — if the server timezone differs from yours, use the hour offset setting to align log timestamps with local time
- **Medical disclaimer** — Calorific is a personal convenience tool, not medical/nutritional advice

---

## Links
- GitHub: https://github.com/xdpirate/calorific
- Releases: https://github.com/xdpirate/calorific/releases/latest

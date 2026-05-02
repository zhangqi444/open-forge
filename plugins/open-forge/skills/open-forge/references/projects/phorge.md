# Phorge

**What it is:** A community-driven fork of Phabricator — a suite of open-source web development tools including code review (Differential), repository browser (Diffusion), task/bug tracking (Maniphest), wiki (Phriction), project boards (Workboards), CI (Harbormaster), and more. A full software development platform for teams.

**Official URL:** https://phorge.it
**Repo:** https://we.phorge.it/source/phorge
**Docs:** https://we.phorge.it/book/phorge/
**License:** Apache-2.0
**Stack:** PHP 7.2+ + MySQL/MariaDB 8.0+/10.5.1+ + Apache/nginx; no official Docker image

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Apache + mod_php + MySQL | Classic LAMP stack |
| Any Linux VPS | nginx + php-fpm + MySQL | Common production setup |
| Any Linux VPS | lighttpd + PHP + MySQL | Supported but less documented |

---

## Inputs to Collect

### Pre-deployment
- MySQL/MariaDB credentials and host — Phorge needs multiple databases (it creates them automatically)
- `phorge.base-uri` — public URL (set via `./bin/config set phorge.base-uri 'https://phorge.example.com'`)
- Email settings — SMTP or local MTA for notifications
- Storage config — local filesystem path or S3-compatible bucket for file attachments

---

## Software-Layer Concerns

**Installation overview:**
```bash
# Clone the repo
git clone https://we.phorge.it/source/phorge.git

# Install dependencies via your OS package manager:
# PHP 7.2+, php-mysql, php-gd, php-curl, php-json, etc.
# MySQL 8.0+ or MariaDB 10.5.1+

# Configure database connection
./bin/config set mysql.host localhost
./bin/config set mysql.user phorge
./bin/config set mysql.pass yourpassword

# Run storage upgrade (creates/migrates databases)
./bin/storage upgrade

# Set base URI
./bin/config set phorge.base-uri 'https://phorge.example.com'
```

**Web server:** Point document root to `webroot/` inside the Phorge checkout. Apache with mod_rewrite or nginx with try_files.

**Daemons** — Phorge requires background daemons for notifications, repository mirroring, and task processing:
```bash
./bin/phd start
```

**Full installation guide:** https://we.phorge.it/book/phorge/article/installation_guide/

**Upgrade procedure:**
```bash
git pull
./bin/storage upgrade
./bin/phd restart
```

---

## Gotchas

- **Multiple databases** — Phorge creates ~30 databases automatically; give the MySQL user `CREATE DATABASE` privileges
- **Daemons required** — `./bin/phd start` must be running for notifications, repo sync, and background jobs; add to system startup
- **No official Docker image** — community Docker images exist but are unofficial; manual LAMP deployment is the supported path
- **Phabricator fork** — Phorge is a maintained community fork of the abandoned Phabricator; Phabricator-compatible data can be migrated
- **Heavy install** — requires PHP, MySQL, a web server, and daemon processes; not a lightweight tool; designed for teams

---

## Links
- Website: https://phorge.it
- Repo: https://we.phorge.it/source/phorge
- Installation guide: https://we.phorge.it/book/phorge/article/installation_guide/
- Docs: https://we.phorge.it/book/phorge/

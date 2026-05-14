# DomainMOD

**What it is:** Open-source domain and internet asset manager written in PHP/MySQL. Centralizes domain registration, registrar accounts, SSL certificates, DNS, and web server data (WHM/cPanel import). Includes a Data Warehouse for live server reporting.

**Official site:** https://domainmod.org  
**Demo:** https://demo.domainmod.org  
**Docs:** https://domainmod.org/docs/  
**GitHub:** https://github.com/domainmod/domainmod  
**Docker Hub:** https://hub.docker.com/r/domainmod/domainmod

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Official image on Docker Hub |
| LAMP stack | Bare metal | PHP + MariaDB/MySQL on any Linux |

---

## Requirements

| Component | Version |
|-----------|---------|
| PHP | 8.1–8.2.9 |
| MariaDB | 10.4–11.1.2 |
| MySQL | 5.7–8.1.0 |
| PHP extensions | PDO (MySQL), cURL, OpenSSL, gettext |
| PHP settings | `allow_url_fopen = On` |

---

## Inputs to Collect

### Phase: Deploy (Docker)

| Variable | Description |
|----------|-------------|
| DB host | Hostname/IP of MySQL/MariaDB server |
| DB name | Database to create for DomainMOD |
| DB user | Database username |
| DB password | Database password |
| App URL | Public URL where DomainMOD will be served |

### Phase: Deploy (Bare Metal)

- Install PHP 8.1/8.2 with required extensions
- Create MySQL/MariaDB database and user
- Clone repo or download zip to web root
- Configure `_includes/config.inc.php` with DB credentials
- Point web server document root to the DomainMOD directory

---

## Software-Layer Concerns

- **Config file:** `_includes/config.inc.php` — DB credentials, app URL, timezone
- **Data directory:** Contains uploaded assets and cached data; back up alongside the database
- **Data Warehouse:** WHM/cPanel server import requires cPanel API access credentials — optional feature
- **Cron jobs:** Recommended for auto-refresh of domain expiry data; see docs for cron setup
- **No built-in authentication beyond a login form** — put behind a VPN or reverse proxy with additional auth if sensitive

---

## Upgrade Procedure

### Docker
1. Pull new image: `docker pull domainmod/domainmod`
2. Stop and recreate the container
3. DomainMOD runs DB migrations on startup

### Bare Metal
1. Back up database and config
2. `git pull` or download new zip
3. Replace files, keeping your `config.inc.php`
4. Navigate to the app — migrations run automatically

---

## Gotchas

- The Docker Hub image handles the web server and PHP; you still need a separate MariaDB/MySQL container or service
- `allow_url_fopen` **must** be enabled in `php.ini` — DomainMOD fetches remote domain data
- Data Warehouse currently only supports WHM/cPanel servers; other control panels are not supported
- Demo credentials are publicly listed — change all default passwords immediately after setup

---

## Links

- Website: https://domainmod.org
- Docs: https://domainmod.org/docs/
- Docker Hub: https://hub.docker.com/r/domainmod/domainmod
- GitHub: https://github.com/domainmod/domainmod

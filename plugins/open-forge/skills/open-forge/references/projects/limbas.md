# Limbas

**Low-code database framework for business applications** — graphical PHP-based database frontend that lets you build database-driven business apps with minimal programming. Supports PostgreSQL, MySQL, MSSQL, SAP MaxDB, and Oracle. Includes a web installer for easy setup.

**Official site:** https://www.limbas.com/en/
**Source:** https://github.com/limbas/limbas
**License:** GPL-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Apache + PHP 8 + PostgreSQL | Primary supported stack |
| Any VPS / bare metal | Apache + PHP 8 + MySQL | Also supported |
| Any VPS / bare metal | Docker | Official Docker Hub image: `limbas/limbas` |

---

## Inputs to Collect

### Phase 1 — Planning
- Database type: PostgreSQL, MySQL, MSSQL, SAP MaxDB, or Oracle
- Whether using Docker or native install

### Phase 2 — Deploy
- Database credentials (host, name, user, password)
- Apache web server with PHP 8+ and PDO/unixODBC
- Admin account credentials

---

## Software-Layer Concerns

- **Stack:** PHP 8+, Apache, PDO/unixODBC; runs on Linux servers
- **Supported databases:** PostgreSQL, MySQL, MSSQL, SAP MaxDB, Oracle
- **Document root:** Must point to the `public/` subdirectory after installation
- **Web installer:** Easiest install path via the separate [web-installer](https://github.com/limbas/web-installer) tool; downloads latest package and sets correct permissions
- **Docker image:** `limbas/limbas` on Docker Hub

---

## Deployment

**Web installer (recommended for non-developers):**
1. Download the web installer from https://github.com/limbas/web-installer/releases
2. Upload to your web server
3. Run the installer — it downloads Limbas, unpacks with correct permissions, and redirects to the Limbas installer
4. Set document root to the `public/` directory after installation

**Docker:**
```bash
docker run -d --restart unless-stopped \
  -p 80:80 \
  -e DB_HOST=your-db-host \
  -e DB_NAME=limbas \
  -e DB_USER=limbas \
  -e DB_PASS=yourpassword \
  limbas/limbas:latest
```

Full documentation: https://limbas.org/en/documentation/get-started-en/

---

## Upgrade Procedure

Download the latest release from GitHub and follow the upgrade guide at https://limbas.org/en/documentation/

---

## Gotchas

- **Document root must be `public/`** — pointing to the repo root exposes config files
- **Web installer requires internet access** on the server to download the Limbas package
- **Low commit activity** — stable/mature project; infrequent commits are expected; use release archives
- **PDO/unixODBC required** — ensure these PHP extensions are installed; without them, database connections fail

---

## Links

- Upstream README: https://github.com/limbas/limbas#readme
- Documentation: https://limbas.org/en/documentation/get-started-en/
- Web installer: https://github.com/limbas/web-installer
- Docker Hub: https://hub.docker.com/r/limbas/limbas
- Demo server: https://www.limbas.com/en/Service___Support/Demoserver/

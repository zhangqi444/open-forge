# FileRun

**What it is:** A self-hosted file management and sharing solution with a polished web interface. Think Google Drive/Dropbox for your own server — browse, upload, preview, share, and collaborate on files. Supports Nextcloud/WebDAV clients, office document preview (via OnlyOffice/Collabora), photo gallery, metadata search, and user management.

> ⚠️ **Closed source / freemium.** FileRun is proprietary. Free for personal use (limited users); paid plans for teams.

**Official URL:** https://filerun.com
**License:** Proprietary; free personal tier + paid plans
**Stack:** PHP + MySQL/MariaDB + Apache/nginx; Docker image available

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Docker Compose | Official Docker image; recommended |
| Any Linux VPS | PHP + MySQL + Apache/nginx | Manual LAMP/LEMP install |

---

## Inputs to Collect

### Pre-deployment
- MySQL/MariaDB credentials — host, database, user, password
- File storage path — host directory where user files will be stored
- `FR_DB_HOST`, `FR_DB_NAME`, `FR_DB_USER`, `FR_DB_PASS` — database connection env vars

---

## Software-Layer Concerns

**Docker Compose (refer to https://filerun.com/docker for current official compose):**
```yaml
services:
  db:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: yourpassword
      MYSQL_DATABASE: filerun
      MYSQL_USER: filerun
      MYSQL_PASSWORD: yourpassword
    volumes:
      - db_data:/var/lib/mysql

  filerun:
    image: afian/filerun:latest
    environment:
      FR_DB_HOST: db
      FR_DB_NAME: filerun
      FR_DB_USER: filerun
      FR_DB_PASS: yourpassword
    ports:
      - "8082:80"
    volumes:
      - /path/to/userfiles:/user-files
      - /path/to/config:/var/www/html/customizables
    depends_on:
      - db
```

**Default port:** `8082` (in example above; adjust as needed)

**First run:** Visit the web UI and log in with the default admin credentials (set during setup or documented in the FileRun docs at https://filerun.com/quick-start).

**Elasticsearch integration (optional):** FileRun supports full-text search via Elasticsearch for content indexing.

**Office document editing:** Integrate with OnlyOffice or Collabora Online for in-browser document editing.

**Upgrade procedure:** See https://filerun.com/update — generally pull new Docker image and run the update script.

---

## Gotchas

- **Closed source** — proprietary; free tier limited to 3 users; paid plans for more
- **MariaDB/MySQL required** — no SQLite option
- **License activation** — the free personal license may require activation on the FileRun website
- **Open alternatives:** [Nextcloud](https://github.com/nextcloud/server) and [Seafile](https://github.com/haiwen/seafile) are popular open-source alternatives with similar functionality

---

## Links
- Website: https://filerun.com
- Docker setup: https://filerun.com/docker
- Quick start: https://filerun.com/quick-start

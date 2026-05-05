# phpIPAM

Open-source web-based IP Address Management (IPAM). phpIPAM tracks IPv4/IPv6 subnets, addresses, VLANs, VRFs, and devices. It provides a REST API, LDAP/AD integration, and supports scanning to auto-discover live hosts.

**Official site:** https://phpipam.net

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Official image `phpipam/phpipam-www` + MariaDB |
| Any Linux host | LAMP stack | PHP 8+, MySQL/MariaDB 10.2+, Apache/Nginx |
| Kubernetes | Helm (community) | Community charts available |

---

## Inputs to Collect

### Phase 1 — Planning
- Database credentials (`MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`, `MYSQL_USER`, `MYSQL_DB`)
- Admin password for initial setup
- External hostname / base URL

### Phase 2 — Deployment
- `IPAM_DATABASE_HOST`, `IPAM_DATABASE_USER`, `IPAM_DATABASE_PASS`, `IPAM_DATABASE_WEBHOST`
- Timezone (`TZ`)
- Whether to enable host scanning (requires `NET_ADMIN` capability)

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  phpipam-db:
    image: mariadb:latest
    environment:
      MYSQL_ROOT_PASSWORD: secret_root
      MYSQL_DATABASE: phpipam
      MYSQL_USER: phpipam
      MYSQL_PASSWORD: secret_phpipam
    volumes:
      - phpipam-db:/var/lib/mysql
    restart: unless-stopped

  phpipam-www:
    image: phpipam/phpipam-www:latest
    ports:
      - "8080:80"
    environment:
      TZ: UTC
      IPAM_DATABASE_HOST: phpipam-db
      IPAM_DATABASE_USER: phpipam
      IPAM_DATABASE_PASS: secret_phpipam
      IPAM_DATABASE_WEBHOST: "%"
    depends_on:
      - phpipam-db
    restart: unless-stopped

  phpipam-cron:
    image: phpipam/phpipam-cron:latest
    environment:
      TZ: UTC
      IPAM_DATABASE_HOST: phpipam-db
      IPAM_DATABASE_USER: phpipam
      IPAM_DATABASE_PASS: secret_phpipam
      SCAN_INTERVAL: "15m"
    depends_on:
      - phpipam-db
    restart: unless-stopped

volumes:
  phpipam-db:
```

### Service Roles
| Service | Purpose |
|---------|---------|
| `phpipam-www` | Web UI and API |
| `phpipam-cron` | Scheduled subnet scans and pings |
| `phpipam-db` | MariaDB backend |

### Environment Variables (www)
| Variable | Description |
|----------|-------------|
| `IPAM_DATABASE_HOST` | MariaDB hostname |
| `IPAM_DATABASE_USER` | DB username |
| `IPAM_DATABASE_PASS` | DB password |
| `IPAM_DATABASE_WEBHOST` | Allowed DB connect host (use `%` for Docker) |
| `TZ` | Timezone |
| `IPAM_TRUST_X_FORWARDED` | Set `true` when behind reverse proxy |

### Config Paths (non-Docker)
- `config.php` — main config file (database, features, authentication)
- `config/config.dist.php` — template; copy to `config/config.php`

### Reverse Proxy
Set `$trust_x_forwarded_headers = true;` in `config.php` **or** `IPAM_TRUST_X_FORWARDED=true` in Docker env. Filter `X-Forwarded-*` headers at the proxy.

### Host Scanning
The `phpipam-cron` container pings subnet hosts. Add `cap_add: [NET_ADMIN, NET_RAW]` if ICMP scanning is needed.

---

## Upgrade Procedure

1. Back up MariaDB: `docker exec phpipam-db mysqldump -u root -p phpipam > backup.sql`
2. Pull new images and restart.
3. phpIPAM auto-applies DB schema upgrades on first load.
4. Verify at **Administration → phpIPAM settings → DB version**.

---

## Gotchas

- **`IPAM_DATABASE_WEBHOST: "%"`** is required in Docker deployments so the web container can reach MariaDB from any container IP.
- **Behind a reverse proxy?** Always set `IPAM_TRUST_X_FORWARDED=true`; otherwise login loops occur.
- **MySQL 8.0+** requires `default-authentication-plugin=mysql_native_password` for older phpIPAM versions.
- **Admin password reset**: `php functions/scripts/reset-admin-password.php` in the CLI.
- **CTE queries** (Common Table Expressions) require MySQL 8.0+ or MariaDB 10.2.1+ for full functionality.
- phpIPAM is PHP-based — keep PHP version within the supported range (7.2–8.5 for current releases).

---

## References
- GitHub: https://github.com/phpipam/phpipam
- Docs: https://phpipam.net/documents/
- Docker Hub: https://hub.docker.com/r/phpipam/phpipam-www
- API docs: https://phpipam.net/api-documentation/

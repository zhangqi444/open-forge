---
name: librenms
description: LibreNMS recipe for open-forge. Auto-discovering PHP/MySQL/SNMP network monitoring system with broad device support (Cisco, Linux, Juniper, HP, and many more).
---

# LibreNMS

Auto-discovering network monitoring system based on PHP, MySQL, and SNMP. Supports a wide range of hardware and operating systems including Cisco, Linux, FreeBSD, Juniper, Brocade, Foundry, HP, and many more. GPL-licensed fork of Observium. Upstream: <https://github.com/librenms/librenms>. Docs: <https://docs.librenms.org/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Containerized deployment; simplest setup |
| Ubuntu/Debian bare-metal | Official docs primary path; full control |
| VM image (VirtualBox) | Quick evaluation |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Database password for LibreNMS?" | MySQL/MariaDB root + librenms user |
| preflight | "Admin username and password?" | LibreNMS web UI admin account |
| preflight | "SNMP community string?" | Default `public`; change for security |
| preflight | "Base URL / domain?" | Set in `APP_URL` |

## Docker Compose example

Based on upstream Docker guide: <https://docs.librenms.org/Installation/Docker/>

```yaml
version: "3.9"
services:
  db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: changeme
      MYSQL_DATABASE: librenms
      MYSQL_USER: librenms
      MYSQL_PASSWORD: changeme
    volumes:
      - librenms-db:/var/lib/mysql

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  librenms:
    image: librenms/librenms:latest
    restart: unless-stopped
    depends_on:
      - db
      - redis
    ports:
      - "8000:8000"
    environment:
      APP_URL: http://localhost:8000
      DB_HOST: db
      DB_NAME: librenms
      DB_USER: librenms
      DB_PASSWORD: changeme
      REDIS_HOST: redis
      TZ: UTC
    volumes:
      - librenms-data:/data
      - librenms-logs:/opt/librenms/logs
      - librenms-rrd:/opt/librenms/rrd

  dispatcher:
    image: librenms/librenms:latest
    restart: unless-stopped
    depends_on:
      - librenms
    environment:
      DISPATCHER_NODE_ID: dispatcher1
      REDIS_HOST: redis
      DB_HOST: db
      DB_NAME: librenms
      DB_USER: librenms
      DB_PASSWORD: changeme
      SIDECAR_DISPATCHER: 1
      TZ: UTC
    volumes:
      - librenms-data:/data
      - librenms-rrd:/opt/librenms/rrd

volumes:
  librenms-db:
  librenms-data:
  librenms-logs:
  librenms-rrd:
```

## Software-layer concerns

- Default port: `8000`
- RRD data in `/opt/librenms/rrd` — persist this volume; it holds all historical graphs
- Dispatcher sidecar runs pollers/cron tasks; required for discovery and polling to work
- SNMP: devices must be reachable from the LibreNMS container on UDP/161
- Alerting: supports email, Slack, PagerDuty, Telegram, and many more via transports
- Oxidized integration: network config backups; configure via `Settings → Oxidized`

## Adding devices

Once running, add devices via UI: **Devices → Add Device** (or CLI: `./addhost.php <hostname> <community> v2c`)

## Upgrade procedure

1. Pull new image: `docker compose pull librenms dispatcher`
2. Restart: `docker compose up -d`
3. DB migrations run automatically on startup

## Gotchas

- Dispatcher container is required — without it, no polling or discovery happens
- SNMP community string must match what's configured on each device
- RRD volume can grow large over time — monitor disk usage; consider RRDtool tuning or Graphite/InfluxDB backends
- Put behind a reverse proxy with TLS (Caddy / NGINX) for production; LibreNMS serves plain HTTP by default
- Timezone (`TZ`) should be consistent across all containers and match your Prometheus/Grafana setup

## Links

- GitHub: <https://github.com/librenms/librenms>
- Docker install docs: <https://docs.librenms.org/Installation/Docker/>
- Full docs: <https://docs.librenms.org/>

---
name: openfire
description: Openfire recipe for open-forge. Open-source XMPP (Jabber) real-time collaboration server. Source: https://github.com/igniterealtime/Openfire. Website: https://igniterealtime.org/projects/openfire/.
---

# Openfire

Open-source XMPP (Jabber) real-time collaboration server licensed under the Apache License 2.0. Written in Java, it's one of the most widely deployed XMPP servers. Features an embedded web admin console, plugin system, LDAP/AD integration, and support for federation, MUC (multi-user chat), file transfer, and TLS. Upstream: <https://github.com/igniterealtime/Openfire>. Website: <https://www.igniterealtime.org/projects/openfire/>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose | Docker image from igniterealtime |
| VPS / bare metal | Java installer (deb/rpm/tar.gz) | Official installer packages available |
| Home server / NAS | Docker | ARM64 supported |
| Kubernetes | Helm | Community chart available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| xmpp_domain | "XMPP domain (e.g. chat.example.com)?" | Must match your DNS and TLS cert |
| admin_port | "Admin console port?" | Default: 9090 (HTTP), 9091 (HTTPS) |
| client_port | "XMPP client port?" | Default: 5222 (STARTTLS), 5223 (Direct TLS) |
| db_type | "Database type? (embedded / mysql / postgresql)" | Embedded (HSQLDB) OK for small installs |
| db_host | "Database host (if not embedded)?" | |
| db_name | "Database name?" | e.g. openfire |
| db_user | "Database user?" | |
| db_pass | "Database password?" | |
| tls_cert | "TLS certificate source? (self-signed / ACME / upload)" | |

## Software-layer concerns

- **Java 11+** required (bundled in official installer packages)
- **Ports**: 5222 (XMPP client STARTTLS), 5223 (XMPP client Direct TLS), 7777 (file transfer proxy), 7070/7443 (HTTP binding / BOSH), 9090 (admin HTTP), 9091 (admin HTTPS), 5269 (server federation)
- Config stored in `/var/lib/openfire/` (Docker) or `/opt/openfire/` (bare metal)
- Embedded HSQLDB database works out-of-the-box; switch to MySQL/PostgreSQL for production
- LDAP/AD integration available via admin console → Users → LDAP
- Plugin management via web admin console or by dropping JARs into `plugins/` directory
- TLS setup: Admin console → Server → TLS/SSL Certificates; supports Let's Encrypt via ACME plugin

### Docker Compose (with MySQL)

```yaml
services:
  openfire:
    image: exadel/openfire:latest
    container_name: openfire
    restart: unless-stopped
    ports:
      - "9090:9090"   # Admin HTTP
      - "9091:9091"   # Admin HTTPS
      - "5222:5222"   # XMPP client STARTTLS
      - "5223:5223"   # XMPP client Direct TLS
      - "7777:7777"   # File transfer proxy
      - "7070:7070"   # BOSH HTTP
      - "7443:7443"   # BOSH HTTPS
      - "5269:5269"   # Server federation
    environment:
      - OPENFIRE_USER=admin
    volumes:
      - openfire-data:/var/lib/openfire
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: openfire-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: openfire
      MYSQL_USER: openfire
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    volumes:
      - openfire-db:/var/lib/mysql

volumes:
  openfire-data:
  openfire-db:
```

### Docker Compose (embedded database — minimal)

```yaml
services:
  openfire:
    image: exadel/openfire:latest
    container_name: openfire
    restart: unless-stopped
    ports:
      - "9090:9090"
      - "9091:9091"
      - "5222:5222"
      - "5223:5223"
    volumes:
      - openfire-data:/var/lib/openfire

volumes:
  openfire-data:
```

### Bare-metal install (Debian/Ubuntu)

```bash
# Download the .deb from https://www.igniterealtime.org/downloads/
wget https://www.igniterealtime.org/downloadServlet?filename=openfire/openfire_4.X.X_all.deb -O openfire.deb
sudo dpkg -i openfire.deb
sudo systemctl enable --now openfire
# Then visit http://your-host:9090 for the setup wizard
```

## Upgrade procedure

1. **Docker**: update image tag, then `docker compose pull && docker compose up -d`
2. **Bare metal**:
   ```bash
   sudo systemctl stop openfire
   # Install new .deb package (preserves config in /var/lib/openfire)
   sudo dpkg -i openfire-new.deb
   sudo systemctl start openfire
   ```
3. Plugin updates: Admin console → Plugins → update individual plugins
4. Backup `/var/lib/openfire/` (or `/opt/openfire/`) before major version upgrades

## Gotchas

- **XMPP domain is permanent**: The XMPP domain set during the setup wizard is stored in the database and is very difficult to change later. Choose carefully (e.g. `chat.example.com`).
- **Embedded HSQLDB for production**: The embedded database is suitable only for testing or very small deployments (<50 users). Use MySQL/PostgreSQL for anything production-grade.
- **Java requirement**: Openfire requires Java 11+ at runtime. Official installer packages bundle a JRE; Docker images include it. On bare metal, ensure Java is installed before running.
- **Firewall ports**: XMPP federation (port 5269) must be open if you want to communicate with users on other XMPP servers. For a private deployment, you can block 5269.
- **Let's Encrypt plugin**: The admin-console-based ACME plugin is the easiest TLS path. Alternatively, place Openfire behind an NGINX reverse proxy for TLS termination; configure `xmpp.proxy.externalIP` in Openfire settings.
- **Resource usage**: Openfire is Java-based. Allocate at least 512 MB heap (set via `JAVA_OPTS=-Xmx512m`); 1 GB+ recommended for active deployments.

## Links

- Upstream repo: https://github.com/igniterealtime/Openfire
- Website: https://www.igniterealtime.org/projects/openfire/
- Documentation: https://www.igniterealtime.org/projects/openfire/documentation.jsp
- Community forums: https://discourse.igniterealtime.org/c/openfire
- Download page: https://www.igniterealtime.org/downloads/
- Plugin library: https://www.igniterealtime.org/projects/openfire/plugins.jsp

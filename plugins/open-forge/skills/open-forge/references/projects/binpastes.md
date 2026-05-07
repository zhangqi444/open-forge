---
name: binpastes
description: BinPastes recipe for open-forge. Minimal pastebin with client-side encryption, full-text search, one-time messages, and expiry. Single Java JAR + MySQL. Source: https://github.com/querwurzel/BinPastes
---

# BinPastes

A minimal self-hosted pastebin designed for one to a few users. Features client-side encryption of note content, full-text search across notes, configurable expiry, one-time messages (self-destruct on read), and dark mode. Single deployable JAR file backed by MySQL. Apache-2.0 licensed, built with Java/Spring Boot. Upstream: <https://github.com/querwurzel/BinPastes>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux VPS | Java 21 JAR (native) | MySQL 8+ | Upstream-recommended; single binary |
| Any Linux VPS | Docker Compose | MySQL 8+ | Wrap JAR in a container |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for BinPastes?" | FQDN | e.g. paste.example.com |
| "MySQL host, database, username, password?" | connection details | For the binpastes database |
| "JDK 21 available on server?" | Yes / needs install | Required; download from Adoptium if not installed |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Port to run on?" | Number | Default Spring Boot port (8080) |
| "Reverse proxy?" | NGINX / Caddy / none | Recommended for HTTPS termination |

## Software-Layer Concerns

- **Single JAR**: BinPastes builds to a single `binpastes.jar` — no separate frontend server needed.
- **JDK 21 required**: Download from https://adoptium.net/temurin/releases/ — the `bin/java` binary in the JDK is all that's needed.
- **MySQL only**: No SQLite or PostgreSQL. MySQL 8+ required.
- **Client-side encryption**: Note content is encrypted in the browser before being sent to the server — the server never sees plaintext for encrypted notes.
- **Config file**: `application-mysql.properties` placed next to the JAR overrides defaults. Set mysql.host, mysql.database, mysql.username, mysql.password.
- **Build**: Requires Maven (`./mvnw clean package -Denv=mysql`) to produce the JAR. Or download a pre-built JAR from the releases page.
- **Intended scale**: "One to few users" per upstream README — not designed for high-traffic public instances.

## Deployment

### Native JAR (recommended)

```bash
# Install JDK 21 (if not present)
# Download from https://adoptium.net/temurin/releases/?version=21

# Get the JAR (build from source or download from releases)
git clone https://github.com/querwurzel/BinPastes.git
cd BinPastes
./mvnw clean package -Denv=mysql
# JAR is at backend/build/binpastes.jar (or backend/target/ depending on build config)

# Create MySQL database
mysql -u root -p -e "CREATE DATABASE binpastes;"

# Create config file next to the JAR
cat > application-mysql.properties << EOF
mysql.host=localhost
mysql.database=binpastes
mysql.username=binpastes_user
mysql.password=changeme
EOF

# Run
java -Dspring.profiles.active=mysql -jar binpastes.jar
```

### systemd service

```ini
[Unit]
Description=BinPastes pastebin
After=network.target mysql.service

[Service]
User=binpastes
WorkingDirectory=/opt/binpastes
ExecStart=/usr/lib/jvm/temurin-21/bin/java -Dspring.profiles.active=mysql -jar binpastes.jar
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name paste.example.com;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Upgrade Procedure

1. Download new JAR from https://github.com/querwurzel/BinPastes/releases or rebuild from source.
2. Stop the service, replace `binpastes.jar`, restart.
3. Database schema migrations handled automatically by Spring Boot on startup.
4. Backup MySQL database before upgrading.

## Gotchas

- **JDK 21 required**: Not JRE — the full JDK. JRE alone may be sufficient to run the JAR; JDK needed to build.
- **MySQL only**: No PostgreSQL or SQLite. Plan for a MySQL/MariaDB instance alongside.
- **Config file placement**: `application-mysql.properties` must be in the same directory as `binpastes.jar` when it runs.
- **Small-scale only**: Not designed for public instances with many users — search indexes and single-instance assumptions apply.
- **Client-side encryption UX**: Users must remember their encryption key/passphrase; there is no server-side recovery for encrypted notes.

## Links

- Source: https://github.com/querwurzel/BinPastes
- Releases: https://github.com/querwurzel/BinPastes/releases
- MySQL config example: https://github.com/querwurzel/BinPastes/blob/main/backend/src/main/resources/application-mysql.properties
- JDK 21: https://adoptium.net/temurin/releases/?version=21

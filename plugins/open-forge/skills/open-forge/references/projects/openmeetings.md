---
name: openmeetings
description: Recipe for Apache OpenMeetings — web-based video conferencing, instant messaging, whiteboard, and collaborative document editing. Java + MariaDB/PostgreSQL + Docker.
---

# Apache OpenMeetings

Web-based video conferencing and groupware platform. Features multi-user video/audio conferencing, instant messaging, collaborative whiteboard, document editing, meeting recording, and calendar integration. Uses Kurento as WebRTC media server. Upstream: <https://github.com/apache/openmeetings>. Website: <https://openmeetings.apache.org/>.

License: Apache-2.0. Platform: Java 21, MariaDB/PostgreSQL, Docker. Latest stable: 9.0.0 (April 2026). Actively maintained under the Apache Foundation.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (apache/openmeetings) | Recommended — official Docker image |
| Tarball (native) | Java server on existing infrastructure |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| db | "Database: Derby (embedded), MariaDB, or PostgreSQL?" | Derby built-in for testing; MariaDB/PostgreSQL for production |
| db | "Database host, name, user, password?" | If using MariaDB/PostgreSQL |
| network | "Public hostname for OpenMeetings?" | Used for WebRTC/TURN config |
| mail | "SMTP host, port, user, password, from address?" | Required for email invitations |
| admin | "Initial admin username and password?" | Set during first-run wizard |

## Docker (recommended)

Two variants: `apache/openmeetings:9.0.0` (full, ~1.1 GB) and `apache/openmeetings:min-9.0.0` (~750 MB).

`docker-compose.yml`:
```yaml
services:
  db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: openmeetings
      MYSQL_USER: openmeetings
      MYSQL_PASSWORD: strongpassword
    volumes:
      - om_db:/var/lib/mysql

  openmeetings:
    image: apache/openmeetings:9.0.0
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "5080:5080"
      - "5443:5443"
    environment:
      OM_DB_TYPE: MYSQL
      OM_DB_HOST: db
      OM_DB_PORT: 3306
      OM_DB_NAME: openmeetings
      OM_DB_USER: openmeetings
      OM_DB_PASS: strongpassword
    volumes:
      - om_data:/opt/openmeetings/webapps/openmeetings/data
      - om_logs:/opt/openmeetings/logs

volumes:
  om_db:
  om_data:
  om_logs:
```

```bash
docker compose up -d
```

Wait ~2 minutes for first-start init, then visit `http://your-host:5080/openmeetings/install` to run the setup wizard.

## First-run wizard steps

1. Choose database type, enter credentials
2. Configure SMTP settings
3. Create admin user and set timezone
4. Click "Install" — creates DB schema
5. Click "Start Application" when done

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config | `webapps/openmeetings/WEB-INF/classes/openmeetings.properties` |
| Data dir | `webapps/openmeetings/data/` — uploaded files and recordings |
| Logs | `logs/` |
| HTTP port | `5080` (context path: `/openmeetings/`) |
| HTTPS port | `5443` |
| WebRTC | Kurento media server is embedded |
| Recordings | Stored in `data/streams/` — can grow large |
| TURN | Configure Coturn in `openmeetings.properties` for NAT traversal |

## Upgrade procedure

```bash
# Change image tag to new version in docker-compose.yml, then:
docker compose pull
docker compose up -d
# DB migrations run automatically on startup
```

## Gotchas

- **Large image**: The full Docker image is ~1.1 GB (includes Kurento). Use `min-*` variant to save ~350 MB.
- **First-start delay**: 1–3 minutes for DB schema init. Do not kill the container during this.
- **HTTPS required for WebRTC**: Browsers block camera/mic access on plain HTTP. Use port 5443 with a TLS cert or place OpenMeetings behind a TLS-terminating reverse proxy.
- **TURN server needed for NAT**: Without a TURN server, users behind corporate firewalls or strict NAT will fail to connect audio/video. Configure Coturn and add its address to `openmeetings.properties`.
- **Java 21 required** for native installs. Docker handles this automatically.
- **Context path**: The app is at `/openmeetings/`, not the root `/`. Proxy accordingly: `proxy_pass http://openmeetings:5080/openmeetings/`.

## Upstream links

- Source: <https://github.com/apache/openmeetings>
- Website: <https://openmeetings.apache.org/>
- Docker Hub: <https://hub.docker.com/r/apache/openmeetings>
- Installation guide: <https://openmeetings.apache.org/installation.html>
- Upgrade guide: <https://openmeetings.apache.org/Upgrade.html>

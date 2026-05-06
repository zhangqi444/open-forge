---
name: ofbiz
description: Recipe for Apache OFBiz — an open-source Enterprise Resource Planning (ERP) system with a suite of business applications. Covers Docker, Gradle/Java, and manual install methods.
---

# Apache OFBiz

Open-source ERP system with a suite of business applications (inventory, orders, accounting, CRM, manufacturing). Built on Java. Upstream: <https://github.com/apache/ofbiz-framework>. Docs: <https://ofbiz.apache.org/>.

OFBiz is a full Java web application running on an embedded Apache Tomcat/Geronimo container. Default web port is `8443` (HTTPS) or `8080` (HTTP). It is heavyweight — production deployments typically need 2–4 GB RAM minimum.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (Gradle image) | Quickest way to evaluate; not official production image |
| Gradle build + run | Recommended for production on any Linux/macOS server |
| Manual WAR deploy | For existing application server infrastructure |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Install method: Docker / Gradle / Manual WAR?" | Drives which section to follow |
| preflight | "Java version?" | OFBiz 18.12+ requires Java 17; trunk requires Java 21 |
| runtime | "Admin password for the OFBiz admin account?" | Set during seed/demo-data load |
| db | "Database: embedded Derby (dev) or PostgreSQL/MySQL (prod)?" | Derby is the default; for production use an external DB |
| db | "Database host, port, name, user, password?" | Only if using external database |
| network | "Public hostname or IP?" | For configuring allowed hosts and TLS |

## Docker (Gradle image)

OFBiz does not have an official Docker Hub image. The recommended approach is to use the Gradle wrapper included in the source.

```bash
git clone https://github.com/apache/ofbiz-framework.git
cd ofbiz-framework

# Build and load demo data (first run only)
./gradlew cleanAll loadAll

# Start OFBiz
./gradlew ofbiz
```

Web UI is available at: `https://localhost:8443/accounting` (self-signed cert by default).
Default admin credentials: `admin` / `ofbiz`

### Docker Compose wrapper

For containerised use, create a `Dockerfile` and `docker-compose.yml`:

```dockerfile
FROM eclipse-temurin:21-jdk
WORKDIR /ofbiz
COPY . .
RUN ./gradlew cleanAll loadAll
EXPOSE 8443 8080
CMD ["./gradlew", "ofbiz"]
```

```yaml
services:
  ofbiz:
    build: .
    ports:
      - "8443:8443"
      - "8080:8080"
    volumes:
      - ofbiz_data:/ofbiz/runtime/data
volumes:
  ofbiz_data:
```

## Gradle build + run (recommended production)

```bash
# Prerequisites: Java 17+ (Java 21 for trunk), Git
git clone https://github.com/apache/ofbiz-framework.git
cd ofbiz-framework

# First-time setup: load demo or seed data
./gradlew cleanAll loadAll     # demo data (for evaluation)
# OR
./gradlew cleanAll loadSeed    # minimal seed data (for production)

# Start
./gradlew ofbiz

# Run as a service — create a systemd unit:
sudo nano /etc/systemd/system/ofbiz.service
```

Systemd unit:
```ini
[Unit]
Description=Apache OFBiz ERP
After=network.target

[Service]
User=ofbiz
WorkingDirectory=/opt/ofbiz-framework
ExecStart=/opt/ofbiz-framework/gradlew ofbiz
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## External database (PostgreSQL)

Edit `framework/entity/config/entityengine.xml`:

```xml
<datasource name="localpostgres"
    helper-class="org.apache.ofbiz.entity.datasource.GenericHelperDAO"
    field-type-name="postgres"
    check-on-start="true"
    add-missing-on-start="true"
    use-foreign-keys="true">
  <inline-jdbc
      jdbc-driver="org.postgresql.Driver"
      jdbc-uri="jdbc:postgresql://localhost:5432/ofbiz"
      jdbc-username="ofbiz"
      jdbc-password="changeme"
      pool-minsize="2"
      pool-maxsize="250"/>
</datasource>
```

Also add the PostgreSQL JDBC driver JAR to `framework/entity/lib/`.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config dir | `framework/*/config/` — XML-based configuration |
| Data dir | `runtime/` (embedded Derby data, logs, uploads) |
| Logs | `runtime/logs/ofbiz.log` |
| Default HTTPS port | `8443` (self-signed cert bundled) |
| Default HTTP port | `8080` |
| Admin URL | `https://localhost:8443/accounting` or `/webtools/control/main` |
| Java requirement | Java 17 (OFBiz 18.12.x), Java 21 (trunk) |
| Memory | Minimum 2 GB heap; set via `JAVA_OPTS=-Xmx2g` |

## Upgrade procedure

OFBiz does not have a built-in upgrade tool. Upgrades require:

1. Backup database and `runtime/` directory.
2. Checkout new version: `git checkout release22.01` (or appropriate tag).
3. Re-run `./gradlew cleanAll` to rebuild.
4. Apply any migration scripts from `applications/*/data/` directories.
5. Restart with `./gradlew ofbiz`.

Review the migration guide for each release: <https://cwiki.apache.org/confluence/display/OFBIZ/OFBiz+Documentation+Index>

## Gotchas

- **Self-signed TLS by default**: OFBiz ships with a self-signed certificate. For production, replace with a real cert in `framework/catalina/ofbiz-containers.xml`.
- **Demo data is not for production**: `loadAll` loads demo data including test users. Use `loadSeed` for production.
- **No official Docker image**: Community images exist but are unofficial. The Gradle wrapper approach is upstream-recommended.
- **Heavy Java app**: First startup can take 2–5 minutes. Heap must be tuned for production (≥2 GB).
- **Default admin password**: Change the default `admin/ofbiz` credentials immediately after first login.
- **Derby for dev only**: The embedded Derby database is not suitable for concurrent production use; switch to PostgreSQL or MySQL.

## Upstream links

- Source: <https://github.com/apache/ofbiz-framework>
- Docs: <https://ofbiz.apache.org/developers.html>
- Wiki: <https://cwiki.apache.org/confluence/display/OFBIZ/OFBiz+Documentation+Index>
- Docker guide: <https://cwiki.apache.org/confluence/display/OFBIZ/Building+and+running+OFBiz+using+Docker>

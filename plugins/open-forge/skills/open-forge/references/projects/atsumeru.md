# Atsumeru

**Self-hosted manga, comics, and light novel media server** — organizes and serves your digital library to native clients on Windows, Linux, macOS, and Android. Supports ComicInfo.xml metadata, multi-user access controls, and a REST API.

**Official site / docs:** https://atsumeru.xyz  
**Source:** https://github.com/Atsumeru-xyz/Atsumeru  
**Docker Hub:** https://hub.docker.com/r/atsumerudev/atsumeru  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker | Primary recommended method |
| Linux/macOS/Windows | Java JAR | Run directly with JRE |
| ARM (Raspberry Pi) | Docker (linux/arm/v7, arm64) | Supported; ZIP-only reading in ARM mode |

---

## Inputs to Collect

| Input | Description | Default |
|-------|-------------|---------|
| `HTTP_PORT` | External API/web port | `31337` |
| Library path | Host path to manga/comics/novels | — |
| Config path | Persistent config directory | — |
| DB path | Persistent database directory | — |

---

## Software-layer Concerns

### Docker CLI
```bash
docker run -d \
  --name=atsumeru \
  -p 31337:31337 \
  -v /path/to/library:/library \
  -v /path/to/config:/app/config \
  -v /path/to/db:/app/database \
  -v /path/to/cache:/app/cache \
  -v /path/to/logs:/app/logs \
  --restart unless-stopped \
  atsumerudev/atsumeru:latest
```

### Docker Compose
```yaml
version: '3.3'
services:
  atsumeru:
    image: atsumerudev/atsumeru:latest
    ports:
      - '31337:31337'
    volumes:
      - /path/to/library:/library
      - /path/to/config:/app/config
      - /path/to/db:/app/database
      - /path/to/cache:/app/cache
      - /path/to/logs:/app/logs
    restart: unless-stopped
```

### Docker image tags
| Tag | Description |
|-----|-------------|
| `latest` | Most recent release |
| `x.y.z` | Specific version (e.g. `2.0`) |

### Persistent volumes
| Container path | Purpose |
|----------------|---------|
| `/library` | Your manga/comics/novels library |
| `/app/config` | Application configuration |
| `/app/database` | Database files |
| `/app/cache` | Thumbnail and metadata cache |
| `/app/logs` | Application logs |

### Web UI / API
- **Swagger UI:** `http://localhost:31337/swagger-ui/index.html`
- **Default port:** `31337`
- Configure clients (Windows/Linux/macOS/Android) to connect to `http://your-server:31337`

### Metadata support
- Auto-imports `ComicInfo.xml` (embedded or alongside archive)
- Supports `book_info.json`
- Manual metadata editing with catalog parsing

### Features
- Multi-user with separate reading history and access controls
- Autocategories, custom categories, Metacategories
- Series download in supported client apps
- REST API for integrations
- ARM support (Raspberry Pi) — ZIP archives only in ARM mode

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```
Config, database, and library volumes are preserved across updates.

---

## Gotchas

- **ARM limitation.** On ARM (Raspberry Pi, etc.), only ZIP archive reading is supported. CBZ, CBR (RAR), and 7z may not work.
- **Default port is 31337.** Unusual port — make sure firewall rules allow it if accessing remotely.
- **Library must be mounted read-write** if Atsumeru writes metadata back to archives; read-only if you prefer no modifications.
- **Java-based.** The JAR version requires a JRE. The Docker image bundles it.
- **Latest release is 2.0** (April 2026) — a major version bump; check the changelog for breaking changes if upgrading from 1.x.

---

## References

- Docker install guide: https://atsumeru.xyz/installation/docker.html
- JAR install guide: https://atsumeru.xyz/installation/jar.html
- Upstream README: https://github.com/Atsumeru-xyz/Atsumeru#readme
- Full documentation: https://atsumeru.xyz

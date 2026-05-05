---
name: gitea-project
description: Gitea recipe for open-forge. Lightweight self-hosted Git service written in Go. Covers Docker Compose with SQLite (simple) and PostgreSQL (production), SSH configuration, environment variables, and upgrade procedure. Derived from https://docs.gitea.com/installation/install-with-docker.
---

# Gitea

Lightweight self-hosted Git service. Upstream: <https://github.com/go-gitea/gitea>. Documentation: <https://docs.gitea.com/>. Docker install guide: <https://docs.gitea.com/installation/install-with-docker>. License: MIT.

Gitea provides repository hosting, issue tracking, pull requests, CI/CD (Gitea Actions, compatible with GitHub Actions), package registry, and team management. Written in Go — runs as a single binary on all platforms.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker Compose (rootful) | <https://docs.gitea.com/installation/install-with-docker> | yes | Recommended. Rootful image; simpler port binding. |
| Docker Compose (rootless) | <https://docs.gitea.com/installation/install-with-docker-rootless> | yes | More secure; runs as non-root. Different port defaults. |
| Binary | <https://docs.gitea.com/installation/install-from-binary> | yes | Bare-metal install. Download prebuilt binary. |
| Package managers | <https://docs.gitea.com/installation/install-from-package> | yes | Homebrew, Scoop, Docker Hub, APT. |
| Kubernetes | <https://docs.gitea.com/installation/install-on-kubernetes> | yes | Helm chart for cluster deployments. |
| Gitea Cloud | <https://cloud.gitea.com> | yes (managed) | Hosted service. Out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Database backend?" | options: SQLite3 (simple) / PostgreSQL (production) / MySQL | SQLite3 requires no extra container. |
| preflight | "What HTTP port should Gitea run on?" | Integer default 3000 | |
| preflight | "What SSH port should Gitea expose?" | Integer default 222 | Maps to container port 22. |
| preflight | "HOST_UID and HOST_GID for volume ownership?" | Integers default 1000 | USER_UID / USER_GID env vars. Match to host /data volume owner. |
| config | "Gitea domain?" | FQDN e.g. gitea.example.com | Used for clone URLs and web links. |
| db | "PostgreSQL password?" | String sensitive | Only if PostgreSQL selected. |

## Docker Compose install — SQLite3 (simplest)

Upstream: <https://docs.gitea.com/installation/install-with-docker>

```yaml
networks:
  gitea:
    external: false

services:
  server:
    image: docker.gitea.com/gitea:1.26.1
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "222:22"
```

```bash
docker compose up -d
```

Access at http://localhost:3000. Follow the installation wizard on first visit.

## Docker Compose install — PostgreSQL (production)

```yaml
networks:
  gitea:
    external: false

services:
  server:
    image: docker.gitea.com/gitea:1.26.1
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=postgres
      - GITEA__database__HOST=db:5432
      - GITEA__database__NAME=gitea
      - GITEA__database__USER=gitea
      - GITEA__database__PASSWD=gitea_password
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "222:22"
    depends_on:
      - db

  db:
    image: docker.io/library/postgres:14
    restart: always
    environment:
      - POSTGRES_USER=gitea
      - POSTGRES_PASSWORD=gitea_password
      - POSTGRES_DB=gitea
    networks:
      - gitea
    volumes:
      - ./postgres:/var/lib/postgresql/data
```

## Software-layer concerns

### Environment variables

| Variable | Description |
|---|---|
| USER_UID | UID of the gitea user inside container. Match to host volume owner (not needed for named volumes). |
| USER_GID | GID of the gitea user inside container. |
| GITEA__database__DB_TYPE | sqlite3, postgres, or mysql |
| GITEA__database__HOST | Database host:port |
| GITEA__database__NAME | Database name |
| GITEA__database__USER | Database user |
| GITEA__database__PASSWD | Database password |
| GITEA__server__DOMAIN | Public domain for clone URLs |
| GITEA__server__ROOT_URL | Full public URL e.g. https://gitea.example.com/ |
| GITEA__server__SSH_DOMAIN | Domain for SSH clone URLs |

The GITEA__ prefix pattern maps directly to app.ini sections: GITEA__<SECTION>__<KEY>=value.

### Ports

| Port | Use |
|---|---|
| 3000 | Web UI and HTTP API |
| 22 (container) / 222 (host default) | SSH for git push/pull |

### Data directory (inside container)

| Path | Contents |
|---|---|
| /data | Git repositories, app.ini config, attachments, avatars, LFS data |
| /data/gitea | Gitea application data |
| /data/git | Git repositories |

### Rootful vs rootless

- **Rootful** (default): Runs as root inside container. Simpler port binding. Image: docker.gitea.com/gitea:1.26.1
- **Rootless**: Runs as non-root. More secure. Different default ports (3000 HTTP, 2222 SSH). See: <https://docs.gitea.com/installation/install-with-docker-rootless>
- **Important**: Do not switch between rootful and rootless on an existing install — images are not compatible with each other.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Gitea performs database migrations automatically on startup. Check release notes before upgrading across major versions at <https://github.com/go-gitea/gitea/releases>.

## Gotchas

- **Installation wizard**: On first access, visit http://server-ip:3000 to complete the installation wizard. Set the admin account before exposing to the internet.
- **Database hostname in wizard**: If using docker-compose with a db service, enter `db` as the database hostname in the wizard (not localhost).
- **Non-3000 HTTP port**: If using a non-3000 port, also update LOCAL_ROOT_URL in app.ini (or via env: GITEA__server__LOCAL_ROOT_URL).
- **SSH port mismatch**: Gitea generates SSH clone URLs using the SSH_DOMAIN and SSH_PORT. Set GITEA__server__SSH_PORT to match the host-mapped port (e.g. 222) so clone URLs are correct.
- **Volume permissions**: For host volumes, the /data directory must be owned by USER_UID:USER_GID. Named volumes let Docker handle this automatically.
- **Gitea Actions**: Built-in CI/CD (GitHub Actions-compatible). Requires a separate act_runner binary/container. See <https://docs.gitea.com/usage/actions/>.

## Links

- GitHub: <https://github.com/go-gitea/gitea>
- Documentation: <https://docs.gitea.com/>
- Docker install guide: <https://docs.gitea.com/installation/install-with-docker>
- Docker Hub: <https://hub.docker.com/r/gitea/gitea>
- Docker image (canonical): <https://docker.gitea.com/gitea>
- Releases: <https://github.com/go-gitea/gitea/releases>

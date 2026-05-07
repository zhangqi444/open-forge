# SCM Manager

**Unified Git, Mercurial, and Subversion repository manager** — share and manage repositories over HTTP with no database required. Full web UI, central user/group/permission management, plugin system, and REST API.

**Official site:** https://www.scm-manager.org  
**Source:** https://github.com/scm-manager/scm-manager  
**Docs:** https://www.scm-manager.org/docs/  
**License:** BSD-3-Clause (listed as AGPL-3.0-only in README)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker | Primary recommended path |
| Debian/Ubuntu | .deb package | Native install |
| Kubernetes | Helm chart (K8s) | Official support |
| Linux | JAR / native | JDK 11+ required |

---

## System Requirements

- Docker, or JDK 11+ for native install
- No database required (embedded storage)

---

## Inputs to Collect

| Input | Description | Default |
|-------|-------------|---------|
| `SCM_VERSION` | SCM-Manager version tag | See [download page](https://www.scm-manager.org/download) |
| `HTTP_PORT` | External port | `8080` |
| `SCM_CONTEXT_PATH` | URL context path (if not serving from `/`) | `/` |
| Data volume | Persistent home directory | `scm-home:/var/lib/scm` |

---

## Software-layer Concerns

### Docker (quickstart)
```bash
docker run --name scm \
  -p 8080:8080 \
  -v scm-home:/var/lib/scm \
  scmmanager/scm-manager:<version>
```
Access at `http://localhost:8080`. Default admin credentials are set on first run via the web UI.

### Docker Compose
```yaml
services:
  scm:
    image: scmmanager/scm-manager:latest
    container_name: scm
    ports:
      - '8080:8080'
    volumes:
      - scm-home:/var/lib/scm
    restart: unless-stopped

volumes:
  scm-home:
```

### Configuration
**Via environment variables:**
```bash
docker run -e "SCM_CONTEXT_PATH=/scm" scmmanager/scm-manager:<version>
```

**Via `config.yml`:**
```bash
# Copy default config out of running container
docker cp scm:/etc/scm/config.yml ./config.yml
# Edit, then mount back:
docker run -v ${PWD}/config.yml:/etc/scm/config.yml scmmanager/scm-manager:<version>
```

### Persistent data
All data lives in `/var/lib/scm` (repositories, users, plugins, config). Use a named Docker volume or bind mount. If using a bind mount, the container runs as UID 1000 — ensure the host directory is writable by that user.

### Features
- Git, Mercurial (Hg), and Subversion (SVN) repositories
- Central user, group, and permission management
- Web UI — no config file hacking required
- Plugin system (code review, CI integration, LDAP auth, etc.)
- Full RESTful API (JSON and XML)
- Branch and tag browsing, diffs, commit history
- Webhook support

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```
The home directory volume preserves all data across upgrades. Check the [changelog](https://scm-manager.org/blog/) for breaking changes.

---

## Gotchas

- **No database required.** SCM-Manager uses its own embedded storage in the home directory (`/var/lib/scm`). Back up this directory.
- **Mercurial support** requires Mercurial installed on the host (or in the Docker image). The official Docker image may or may not include it — check the release notes.
- **Plugin updates** are managed via the web UI under Admin → Plugin Center. Some plugins require a restart.
- **UID 1000** is used inside the container. Bind mounts must be owned/writable by UID 1000 on the host.
- **Kubernetes deployment** via Helm is first-class supported — see https://www.scm-manager.org/docs/.

---

## References

- Docker install docs: https://www.scm-manager.org/docs/latest/en/installation/docker/
- Upstream README: https://github.com/scm-manager/scm-manager#readme
- Full docs: https://www.scm-manager.org/docs/

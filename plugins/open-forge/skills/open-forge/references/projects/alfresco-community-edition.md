# Alfresco Community Edition

**Enterprise Content Management (ECM) platform** — document management, collaboration, records management, and workflow in a single platform. Open source community release of Alfresco Content Services.

**Official site:** https://www.alfresco.com/products/community/download  
**Source:** https://github.com/Alfresco/alfresco-community-repo  
**Docker installer:** https://github.com/Alfresco/alfresco-docker-installer  
**License:** LGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker Compose (generated) | Primary install method via Yeoman generator |
| Linux (Ubuntu/CentOS/RHEL/Debian) | Docker Compose | Full support; bind-mount permissions may need tuning |
| macOS | Docker Compose | Works as-is with Docker Desktop |
| Windows 10/11 | Docker Compose | WSL2 or Hyper-V recommended; use Docker volumes not bind mounts |

---

## System Requirements

- **RAM:** 16 GB minimum available to Docker (12 GB absolute floor)
- **Disk:** 50 GB+ for images and data
- **CPU:** 4+ cores recommended
- **Node.js:** 18+ (for generator only)
- **Docker:** Engine 20.10+ or Docker Desktop
- **Docker Compose:** V2 (or V1 with `docker-compose` syntax)

---

## Inputs to Collect

### Provision phase
| Input | Description | Default |
|-------|-------------|---------|
| `ACS_VERSION` | Alfresco Content Services version | `26.1` |
| `RAM_GB` | GB of RAM to allocate | `16` |
| `HTTPS` | Enable HTTPS termination | `false` |
| `PROXY_TYPE` | `nginx` or `traefik` (ACS 26.1 only) | `nginx` |
| `SERVER_NAME` | Hostname for the deployment | `localhost` |
| `ADMIN_PASSWORD` | Admin user password | `admin` |
| `HTTP_PORT` | External HTTP port | `80` |
| `DATABASE` | `postgresql` or `mariadb` | `postgresql` |

### Deploy phase
| Input | Description | Default |
|-------|-------------|---------|
| `CROSS_LOCALE` | Multi-language content support | `true` |
| `CONTENT_INDEXING` | Index document content for full-text search | `true` |
| `SOLR_HTTP_MODE` | `http` / `https` / `secret` | `http` |
| `ACTIVEMQ` | Enable Events service (required for Out-of-Process SDK) | `false` |
| `SMTP` | Create internal Postfix relay | `false` |
| `LDAP` | Create internal OpenLDAP server | `false` |

---

## Software-layer Concerns

### Install (Yeoman generator)
```bash
npm install -g yo generator-alfresco-docker-installer
mkdir alfresco-deploy && cd alfresco-deploy
yo alfresco-docker-installer
# Accept prompts or pass flags:
# yo alfresco-docker-installer --acsVersion=26.1 --password=MyPass --port=8080
docker compose up -d
```

### Service URLs (default port 80)
| Service | URL |
|---------|-----|
| Content App | `http://localhost/` |
| Share UI | `http://localhost/share` |
| Repository API | `http://localhost/alfresco` |
| SOLR Console | `http://localhost/solr` |
| Default credentials | `admin` / `admin` (or chosen password) |

### Config paths
| Path | Purpose |
|------|---------|
| `config/nginx.conf` | NGINX proxy config |
| `config/cert/` | SSL certificate placeholders |
| `data/alf-repo-data/` | Alfresco content store (bind mount) |
| `data/postgres-data/` | PostgreSQL data |
| `data/solr-data/` | Search Services index |
| `logs/alfresco/` | Alfresco repository logs |

### Linux bind-mount permissions
Alfresco's internal user has UID `33000`. After first run (or before, using generated `create_volumes.sh`):
```bash
sudo chown -R 33000 data/alf-repo-data logs/alfresco
sudo chown -R 33031 data/activemq-data  # if ActiveMQ enabled
```
Or regenerate with `--windows=true` to use named Docker volumes instead.

### Environment / config keys
Alfresco configuration lives in `alfresco-global.properties` (baked into generated images). Key properties:
- `db.url`, `db.username`, `db.password` — database connection
- `solr.host`, `solr.port`, `solr.secureComms` — SOLR link
- `mail.host`, `mail.port` — outbound email (if SMTP addon enabled)

---

## Upgrade Procedure

1. Review [Alfresco upgrade notes](https://docs.alfresco.com/content-services/community/upgrade/) for schema changes
2. Back up content store and database:
   ```bash
   docker compose stop alfresco
   tar czf backup-alf-data-$(date +%F).tar.gz data/alf-repo-data
   docker compose exec postgres pg_dump -U alfresco alfresco > backup-$(date +%F).sql
   ```
3. Regenerate Docker Compose with new ACS version:
   ```bash
   yo alfresco-docker-installer --acsVersion=<new-version>
   ```
4. Pull new images and restart:
   ```bash
   docker compose pull
   docker compose up -d
   ```
5. Monitor logs for schema upgrade completion:
   ```bash
   docker compose logs -f alfresco | grep "Server startup"
   ```

---

## Gotchas

- **Not for production out-of-the-box.** The generator is explicitly a dev/testing/POC tool. Review and harden all credentials, certificates, and volume permissions before production use.
- **Long startup times.** First boot takes 3–10 minutes. Use `docker compose logs -f alfresco` and wait for "Server startup in [XXXX] milliseconds".
- **Traefik (ACS 26.1 only) requires Docker socket mount.** Must mount `/var/run/docker.sock`; regenerating with the current generator handles this automatically.
- **SOLR HTTP mode locked for ACS 7.2+.** Plain HTTP option is removed; use `secret` or `https`.
- **`make test` destroys data.** Never run the test suite in a production checkout.
- **Addons go in `alfresco/modules/amps/` or `alfresco/modules/jars/`.** Drop AMP/JAR files there before `docker compose up --build`.

---

## References

- Upstream README: https://github.com/Alfresco/alfresco-docker-installer#readme
- Alfresco Community docs: https://docs.alfresco.com/content-services/community/
- ACS deployment reference: https://github.com/Alfresco/acs-deployment

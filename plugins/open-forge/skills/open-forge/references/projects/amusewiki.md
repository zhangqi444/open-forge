# AmuseWiki

**Multi-site wiki engine** built on the Emacs Muse markup (Text::Amuse). Supports read-only sites, moderated wikis, fully open wikis, and private sites. Multiple independent sites can run on a single instance. Git-backed content storage.

**Official site:** https://amusewiki.org  
**Source:** https://github.com/melmothx/amusewiki  
**Docker image (community):** https://github.com/rojenzaman/amusewiki-docker  
**Demo:** https://sandbox.amusewiki.org  
**License:** GPL-1.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker (community image `rojen/amusewiki`) | Easiest path; SQLite by default |
| Debian/Ubuntu | Native Perl + nginx | Official install path documented at amusewiki.org |
| Any | Docker Compose | Compose file available in the docker repo |

---

## Inputs to Collect

### Provision phase
| Input | Description | Default |
|-------|-------------|---------|
| `POST_DOMAIN` | Initial site domain | `localhost` |
| `AMW_USERNAME` | Admin username | `amusewiki` |
| `AMW_PASSWORD` | Admin password | `changeme` |
| `AMW_WORKERS` | Number of fcgi process sets | auto |
| `AMW_NPROC` | Number of perl-fcgi processes | auto |
| `HTTP_PORT` | External port for HTTP | `80` |
| `HTTPS_PORT` | External port for HTTPS | `443` |

### Deploy phase
| Input | Description | Default |
|-------|-------------|---------|
| `CONTAINER_IS_BEHIND_HTTPS_TRAEFIK` | Set `true` for Traefik HTTPS reverse proxy | `false` |
| `AMW_SQLITE_PATH` | SQLite database path inside container | `/var/lib/dbconfig-common/sqlite3/amusewiki/amusewiki` |
| `HOST_SSH_PUBLIC_KEY` | Authorize host SSH key for git operations | — |
| `EMAIL_SENDER_TRANSPORT` | Set `SMTP` to enable outbound email | — |
| `EMAIL_SENDER_TRANSPORT_host` | SMTP server hostname | — |
| `EMAIL_SENDER_TRANSPORT_port` | SMTP port | — |

---

## Software-layer Concerns

### Quick Start (Docker Compose)
```yaml
services:
  app:
    image: rojen/amusewiki:package
    ports:
      - '80:80'
      - '443:443'
    environment:
      - POST_DOMAIN=localhost
      - CHANGE_PASSWORD_BEFORE_RUN=true
      - AMW_USERNAME=myadmin
      - AMW_PASSWORD=MySecurePass
    volumes:
      - amw_repo:/var/lib/amusewiki/repo
      - amw_thumbnails:/var/lib/amusewiki/thumbnails
      - amw_staging:/var/lib/amusewiki/staging
      - amw_db:/var/lib/dbconfig-common/sqlite3/amusewiki
      - amw_web:/etc/nginx/sites-enabled

volumes:
  amw_repo:
  amw_thumbnails:
  amw_staging:
  amw_db:
  amw_web:
```

Default credentials after first run: `amusewiki` / `changeme` (change via `CHANGE_PASSWORD_BEFORE_RUN=true` + `AMW_USERNAME`/`AMW_PASSWORD`).

### Docker image tags
| Tag | Description |
|-----|-------------|
| `rojen/amusewiki:package` (= `latest`) | Debian package install, no TeX |
| `rojen/amusewiki:texlive-minimal` | Adds minimal TeX for PDF export |
| `rojen/amusewiki:texlive-base` | Base TeX environment |
| `rojen/amusewiki:texlive-full` | Full TeX (large image, best PDF support) |

Use `texlive-minimal` or higher if you need PDF/EPUB export.

### Persistent volumes (required)
| Volume path | Purpose |
|-------------|---------|
| `/var/lib/amusewiki/repo` | Git repository of wiki content |
| `/var/lib/amusewiki/thumbnails` | Generated image thumbnails |
| `/var/lib/amusewiki/staging` | Upload staging area |
| `/var/lib/dbconfig-common/sqlite3/amusewiki` | SQLite database |
| `/etc/nginx/sites-enabled` | nginx site configuration |

Optional (set `OTHER_VOLUMES_USED_IN_CONTAINER` env if using):
- `/var/lib/amusewiki/log` — application logs
- `/var/lib/amusewiki/ssl` — SSL certificates
- `/var/lib/amusewiki/.ssh` — SSH keys for git operations

### Config paths (native Perl install)
| Path | Purpose |
|------|---------|
| `amusewikifarm.conf` | Main application config |
| `dbic.yaml.pg.example` / `dbic.yaml.sqlite.example` | Database DSN templates |

For native install on Debian/Ubuntu, follow the official guide:  
https://amusewiki.org/library/install

---

## Upgrade Procedure

**Docker:**
```bash
docker compose pull
docker compose up -d
```
The `UPDATE_AMUSEWIKI=true` environment variable can force a git pull inside the container before startup.

**Native Perl install:** Follow https://amusewiki.org/library/upgrade-amusewiki

---

## Gotchas

- **Do not run `make test` in production.** The test suite leaves files behind and will corrupt a live install.
- **`CHANGE_PASSWORD_BEFORE_RUN=true` required on first deploy** — the default password is public.
- **Multiple sites per instance.** AmuseWiki is designed as a farm; you can host many independent wikis. Manage via the admin panel.
- **PDF/EPUB export requires TeX.** Use a `texlive-*` image tag; the base `package` tag has no TeX.
- **`POST_DOMAIN` sets the initial site's canonical domain.** Change it later with `CHANGE_DOMAIN_BY_ID` env var.
- **SSH key for git push.** To allow editing via git push, mount your host's SSH public key via `HOST_SSH_PUBLIC_KEY`.
- **Markup is Text::Amuse** (Emacs Muse variant), not Markdown or MediaWiki syntax. See https://amusewiki.org/library/manual.

---

## References

- Official install docs: https://amusewiki.org/library/install
- Upgrade guide: https://amusewiki.org/library/upgrade-amusewiki
- Docker image README: https://github.com/rojenzaman/amusewiki-docker#readme
- Upstream README: https://github.com/melmothx/amusewiki/blob/master/README.mdwn

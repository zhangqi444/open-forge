# Liveblog

> Self-hosted live blogging platform for journalists and publishers — create real-time event coverage with a multi-author editorial workflow, embeddable live blog widgets, and syndication. Built on Superdesk (Python/Flask backend, Angular client). Requires Elasticsearch, MongoDB, and Redis.

**Official URL:** https://github.com/liveblog/liveblog  
**Docs:** http://sourcefabric.booktype.pro/live-blog-30-for-journalists/what-is-live-blog/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VPS/VM (Ubuntu 20.04 LTS) | Docker Compose | Recommended; spins up all dependencies |
| Linux VPS/VM | Manual (Python + Node.js) | Full dev/prod setup; complex |

**Requires:** Elasticsearch, MongoDB, Redis (all provided via Docker Compose)

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `ADMIN_EMAIL` | Admin account email | `admin@example.com` |
| `ADMIN_PASSWORD` | Admin account password (default: `admin`) | change immediately |
| `DOMAIN` | Public domain for embedding and webhooks | `liveblog.example.com` |

### Phase: Optional
| Input | Description | Example |
|-------|-------------|---------|
| S3 credentials | Store uploaded assets in Amazon S3 (optional) | see `AMAZON-S3-PUBLISHED-URL.MD` in repo |

---

## Software-Layer Concerns

### Docker Compose Setup
```bash
git clone https://github.com/liveblog/liveblog
cd liveblog/docker

# Start infrastructure (Elasticsearch, Redis, MongoDB)
docker-compose -f docker-compose-dev.yml -p lbdemo up -d

# Initialize data (run once after containers are healthy)
docker-compose -p lbdemo -f ./docker-compose-dev.yml run superdesk \
  ./scripts/fig_wrapper.sh bash -c "
    python3 manage.py app:initialize_data ;
    python3 manage.py users:create -u admin -p admin -e 'admin@example.com' --admin ;
    python3 manage.py register_local_themes ;"
```

Access at http://localhost:9000 (user: `admin`, password: `admin`)

### Elasticsearch Index Issue
If you see `IndexMissingException[[liveblog] missing]` after login:
```bash
docker-compose -p lbdemo -f ./docker-compose-dev.yml run superdesk \
  ./scripts/fig_wrapper.sh bash -c "
    curl -X POST elastic:9200/liveblog
    python3 manage.py app:rebuild_elastic_index --index=liveblog"
```

### Stack Components
| Service | Purpose |
|---------|---------|
| Superdesk (Python/Flask) | Backend API — port `5000` |
| Angular client | Frontend — port `9000` |
| Elasticsearch | Full-text search and content index |
| MongoDB | Primary data store |
| Redis | Job queue and caching |

### Ports
- Web UI: `9000`
- API: `5000`
- WebSocket: `5100`

---

## Upgrade Procedure

1. Pull updated images: `docker-compose pull`
2. Stop: `docker-compose down`
3. Start: `docker-compose up -d`
4. Run any new migrations: `python3 manage.py app:initialize_data` (safe to re-run)
5. Check logs for Elasticsearch index issues and rebuild if needed

---

## Gotchas

- **Heavyweight stack** — requires Elasticsearch, MongoDB, and Redis; minimum 2–4 GB RAM; not suitable for small VPS
- **Python 3.6.15 specific** — the manual install path requires exactly Python 3.6.15 via pyenv; newer Python versions may break dependencies
- **Docker setup is marked "outdated"** — the README notes the Docker setup is outdated; the recommended path is the local dev setup which still uses Docker for services but runs the app manually
- **Default credentials** — change the default `admin`/`admin` credentials immediately after setup
- **Elasticsearch index** — may need manual rebuild on first run or after upgrade; use `app:rebuild_elastic_index`
- **S3 asset storage** — if using Amazon S3, check `AMAZON-S3-PUBLISHED-URL.MD` in the repo for the correct published URL configuration since v3.4

---

## Links
- GitHub: https://github.com/liveblog/liveblog
- Docs: http://sourcefabric.booktype.pro/live-blog-30-for-journalists/what-is-live-blog/
- S3 config: https://github.com/liveblog/liveblog/blob/master/AMAZON-S3-PUBLISHED-URL.MD

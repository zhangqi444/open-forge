# Priviblur

> Privacy-respecting alternative frontend for Tumblr — browse blogs, posts, and tags without being tracked, no account required. Proxies all requests to Tumblr on your behalf. Works without JavaScript.

**Official URL:** https://github.com/syeopite/priviblur  
**Docker Images:** https://quay.io/repository/syeopite/priviblur

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Official images on Quay.io |
| Any Linux VPS/VM | Docker Compose | Compose file provided in repo |
| Any Linux VPS/VM | Python (manual) | Sanic web framework; Python 3.x |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `DOMAIN` | Public domain for your instance | `tumblr.example.com` |
| `config.toml` | App config file (copy from `config.example.toml`) | see repo |

### Phase: config.toml
| Setting | Description | Example |
|---------|-------------|---------|
| `host` | Bind address | `0.0.0.0` |
| `port` | Listening port | `8080` |
| `workers` | Number of async workers | `2` |

---

## Software-Layer Concerns

### Config File
- Copy `config.example.toml` to `config.toml` and edit before deploying
- Mount `config.toml` into the container at the expected path (check the repo's compose file for the exact mount point)
- Full example config: https://github.com/syeopite/priviblur/blob/master/config.example.toml

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/app/config.toml` | Main config — bind-mount from host |

### Ports
- Default: `8080` — proxy with Nginx/Caddy and terminate TLS

### Manual Install (Python)
```bash
git clone https://github.com/syeopite/priviblur
cd priviblur
git checkout v0.3.0   # pin to a stable release
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pybabel compile -d locales -D priviblur
python -m src.server
# Or via Sanic CLI:
sanic src.server.app --host 0.0.0.0 --workers 2
```

### Docker (via Quay.io)
```bash
docker run -d \
  -p 8080:8080 \
  -v /path/to/config.toml:/app/config.toml:ro \
  quay.io/syeopite/priviblur:latest
```

> For master/bleeding-edge builds use the PussTheCat.org mirror image (see README).

---

## Upgrade Procedure

1. Pull the latest stable image: `docker pull quay.io/syeopite/priviblur:latest`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`
4. No database to migrate — stateless proxy

---

## Gotchas

- **Tumblr API dependency** — Priviblur proxies Tumblr's internal API; if Tumblr changes their API, some features may break until Priviblur is updated
- **No account features** — read-only browsing only; no login, reblog, or like functionality (by design — privacy proxy)
- **Official images are stable-release only** — Quay.io only publishes tagged releases; use the PussTheCat.org community image for master builds
- **Sanic environment variables** — when using Sanic CLI, prefix env vars with `PRIVIBLUR_` instead of standard env names; see Sanic docs for details
- **AGPL license** — if you modify and deploy Priviblur, you must publish your changes under the same license

---

## Links
- GitHub: https://github.com/syeopite/priviblur
- Docker images (Quay.io): https://quay.io/repository/syeopite/priviblur
- Public instances list: https://github.com/syeopite/priviblur/blob/master/instances.md
- Config example: https://github.com/syeopite/priviblur/blob/master/config.example.toml

# MintHCM

An open-source, AI-native Human Capital Management (HCM) platform built for agentic engineering. Covers the full HR lifecycle: recruitment, employee management, time and attendance, performance, organisational structure, and reporting. Designed around MCP/WebMCP, agent-to-agent (A2A) communication, and built-in AI agents. Built on PHP (SuiteCRM foundation) + MySQL (Percona) + Elasticsearch. Mobile apps for iOS and Android available.

- **Official site:** https://minthcm.org
- **GitHub:** https://github.com/minthcm/minthcm
- **Docker image:** `minthcm/minthcm`
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Web + MySQL (Percona) + Elasticsearch stack |
| On-premise / cloud | Bare metal | See official install guide |

---

## Inputs to Collect

### Deploy Phase (.env in docker/ directory)
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| WEB_PORT | No | 80 | Host port to expose the web UI |
| MYSQL_PASSWORD | Yes | minthcm | MySQL root password — change for production |
| DB_HOST | No | minthcm-db | MySQL container hostname |
| DB_PORT | No | 3306 | MySQL port |
| DB_NAME | No | minthcm | Database name |
| DB_USER | No | root | Database user |
| DB_PASS | Yes | minthcm | Database password — change for production |
| MINT_URL | Yes | http://localhost | Public URL of MintHCM (used in emails, links) |
| MINT_USER | No | admin | Initial admin username |
| MINT_PASS | Yes | minthcm | Initial admin password — change for production |
| ELASTICSEARCH_HOST | No | minthcm-es | Elasticsearch container hostname |

---

## Software-Layer Concerns

### Architecture (Docker Compose stack)
- **minthcm-web** — PHP application (Apache/nginx inside container), port 80
- **minthcm-db** — Percona Server 8.0 (MySQL-compatible)
- **minthcm-es** — Elasticsearch 7.16.3 (4 GB memory limit; 512 MB Java heap)

### Config
- .env file in docker/ directory (copy default .env provided)
- MINT_URL must match your actual public URL for links and emails to work

### Data Directories
| Volume | Contents |
|--------|----------|
| minthcm_www | Web application files |
| minthcm_cron | Cron jobs |
| minthcm_db | MySQL data |
| minthcm_es | Elasticsearch indices |

### Ports
- WEB_PORT (default 80) — Web UI

### Resource Requirements
- Elasticsearch requires at least 4 GB RAM on the host (mem_limit: 4g in compose); production systems should plan accordingly

---

## Setup Steps

```bash
git clone https://github.com/minthcm/minthcm.git && cd minthcm/docker
cp .env .env.local
# Edit .env.local: set strong passwords, correct MINT_URL
cp .env.local .env
docker compose up -d
# Access at http://localhost (or your configured WEB_PORT)
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

Check the GitHub releases for any migration notes before upgrading major versions.

---

## Gotchas

- **Elasticsearch memory:** The compose file sets mem_limit: 4g for Elasticsearch; ensure your host has sufficient RAM or lower ES_JAVA_OPTS (at cost of performance)
- **Change default credentials:** Default .env has MYSQL_PASSWORD=minthcm and MINT_PASS=minthcm — always change before exposing to a network
- **MINT_URL must be correct:** Used internally for generating links in emails, calendar invites, etc.; set to your actual public hostname/IP
- **First-run initialisation is slow:** The PHP app initialises the database on first start, which may take several minutes; wait for minthcm-db healthcheck to pass before the web container starts
- **Percona Server 8.0:** Uses caching_sha2_password authentication by default; older MySQL clients may need explicit auth plugin override
- **Mobile apps available:** iOS and Android apps connect to your self-hosted MintHCM instance via the configured MINT_URL

---

## References
- Installation guide: https://minthcm.org/support/minthcm-installation-guide/
- GitHub: https://github.com/minthcm/minthcm
- docker-compose.yml: https://raw.githubusercontent.com/minthcm/minthcm/master/docker/docker-compose.yml

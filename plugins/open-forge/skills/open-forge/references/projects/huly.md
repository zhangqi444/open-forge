# Huly

All-in-one project management platform. Huly is a self-hosted alternative to Linear, Jira, Slack, Notion, and Motion. Combines project tracking, team chat, docs, HR, and planning in a single platform. Built on a collaborative real-time engine (Hocuspocus).

**Official site:** https://huly.io  
**Source:** https://github.com/hcengineering/platform  
**Self-host repo:** https://github.com/hcengineering/huly-selfhost  
**Upstream docs:** https://github.com/hcengineering/huly-selfhost/blob/main/README.md  
**License:** EPL-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary self-hosted method |
| Kubernetes | Helm / kube manifests | Sample configs in selfhost repo |

---

## Inputs to Collect

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `HULY_VERSION` | Platform release version tag | `v0.7.413` |
| `SECRET` | Server secret for JWT/signing | random string |
| `HTTP_BIND` | Host IP to bind nginx | `0.0.0.0` |
| `HTTP_PORT` | Host port for web access | `80` |

### Database
| Variable | Description | Default |
|----------|-------------|---------|
| `CR_DATABASE` | CockroachDB database name | set in `.env` |
| `CR_USERNAME` | CockroachDB user | set in `.env` |
| `CR_USER_PASSWORD` | CockroachDB password | set in `.env` |

---

## Software-Layer Concerns

### System requirements
Huly is resource-intensive:
- **Minimum:** 2 vCPUs, 8 GB RAM
- **Recommended:** 4 vCPUs, 16 GB RAM or more

### Quick start
```sh
git clone https://github.com/hcengineering/huly-selfhost.git
cd huly-selfhost
cp .env .env.local  # edit .env to set HULY_VERSION, SECRET, HTTP_PORT etc.
docker compose up -d
```

### Services
| Service | Image | Role |
|---------|-------|------|
| `nginx` | `nginx:1.21.3` | Reverse proxy / web entrypoint |
| `cockroach` | `cockroachdb/cockroach:latest-v24.2` | Primary relational DB (CockroachDB) |
| `redpanda` | `redpandadata/redpanda:v24.3.6` | Kafka-compatible event streaming |
| `minio` | `minio/minio` | S3-compatible file storage |
| `elastic` | `elasticsearch:7.14.2` | Full-text search (with ingest-attachment plugin) |
| `account` | `hardcoreeng/account:${HULY_VERSION}` | User accounts service |
| `front` | `hardcoreeng/front:${HULY_VERSION}` | Web frontend |
| `collaborator` | `hardcoreeng/collaborator:${HULY_VERSION}` | Real-time collaboration |
| `fulltext` | `hardcoreeng/fulltext:${HULY_VERSION}` | Full-text indexing service |
| `rekoni` | `hardcoreeng/rekoni:${HULY_VERSION}` | Document parsing service |
| `stats` | `hardcoreeng/stats:${HULY_VERSION}` | Analytics/stats service |
| `kvs` | `hardcoreeng/hulykvs:${HULY_VERSION}` | Key-value store service |

### Volumes
| Volume | Contents |
|--------|----------|
| `cr_data` / `cr_certs` | CockroachDB data and TLS certs |
| `redpanda` | Event stream data |
| `files` | MinIO file storage |
| `elastic` | Elasticsearch indices |

### Version pinning
Always set `HULY_VERSION` to a specific `v*` tag (e.g., `v0.7.413`). All `hardcoreeng/*` images are versioned together.

---

## Upgrade Procedure

1. **Read `MIGRATION.md` first** — each release may have required migration steps
2. Stop stack (recommended for major upgrades): `docker compose down`
3. Pull selfhost repo: `git pull`
4. Update `HULY_VERSION` in `.env`
5. Pull images: `docker compose pull`
6. Start: `docker compose up -d`
7. **0.6.x → 0.7.x requires special migration steps** — follow the `v0.7` section in `MIGRATION.md`

---

## Gotchas

- **Resource-heavy** — Huly runs ~10+ containers including Elasticsearch, CockroachDB, and Redpanda; do not deploy on servers with less than 8 GB RAM
- **Always read MIGRATION.md before upgrading** — some versions require manual DB migration steps, config changes, or service additions
- **0.6.x → 0.7.x is a breaking migration** — direct in-place upgrade is not supported; follow dedicated migration steps
- **CockroachDB, not PostgreSQL** — Huly uses CockroachDB (Postgres-compatible) as its primary DB, not vanilla Postgres
- **Elasticsearch 7.14.2 with ingest-attachment** — the `elastic` container installs the plugin at startup; first start may be slow
- **EPL-2.0 license** — Eclipse Public License; compatible with MIT/Apache for commercial self-hosting use, but review copyleft implications if distributing modifications

---

## Links
- Platform source: https://github.com/hcengineering/platform
- Self-host repo: https://github.com/hcengineering/huly-selfhost
- Migration guide: https://github.com/hcengineering/huly-selfhost/blob/main/MIGRATION.md
- Releases: https://github.com/hcengineering/platform/releases

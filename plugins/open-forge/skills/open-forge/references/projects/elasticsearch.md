# Elasticsearch

Elasticsearch is a distributed, RESTful search and analytics engine built on Apache Lucene. It serves as the heart of the Elastic Stack for full-text search, log analytics, vector search, and observability use cases at any scale.

**Official site:** https://www.elastic.co/elasticsearch  
**GitHub:** https://github.com/elastic/elasticsearch  
**Upstream README:** https://github.com/elastic/elasticsearch/blob/main/README.asciidoc  
**Docker Hub:** https://hub.docker.com/_/elasticsearch  
**License:** SSPL / Elastic License 2.0 (source-available; BSL from v5.9 of EMQX — but Elasticsearch itself uses ELv2)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker Compose | Standard single-node or multi-node cluster |
| Kubernetes | Helm / ECK operator | Official Elastic Cloud on Kubernetes operator |
| Bare metal | Package / tarball | `.deb`, `.rpm`, or `.tar.gz` |

---

## Inputs to Collect

### Before deployment
- `ELASTIC_PASSWORD` — password for built-in `elastic` superuser
- `ES_JAVA_OPTS` — JVM heap settings (e.g. `-Xms2g -Xmx2g`); set to ~50% of RAM, max 32 GB
- `cluster.name` — logical cluster name
- Data directory path on host (for volume mount)
- Number of nodes (single-node dev vs. multi-node production)
- TLS: use self-signed (default) or bring your own certificates

### Optional
- `KIBANA_PASSWORD` — if deploying Kibana alongside
- `discovery.seed_hosts` / `cluster.initial_master_nodes` — for multi-node
- Snapshot repository path (S3 / GCS / NFS) for backups

---

## Software-Layer Concerns

### Data directories
- Container: `/usr/share/elasticsearch/data`
- Host mount: map a named volume or host path; do **not** use an NFS-backed mount without tuning

### Key env vars (single-node)
```
discovery.type=single-node
ELASTIC_PASSWORD=changeme
ES_JAVA_OPTS=-Xms1g -Xmx1g
xpack.security.enabled=true
```

### Config files
- `elasticsearch.yml` — main config; mount at `/usr/share/elasticsearch/config/elasticsearch.yml`
- `jvm.options.d/` — JVM tuning overrides

### Ports
| Port | Purpose |
|------|---------|
| 9200 | HTTP REST API (clients, Kibana) |
| 9300 | Transport (inter-node cluster) |

### OS tuning required
```bash
# On the Docker host — Elasticsearch needs higher vm.max_map_count
sysctl -w vm.max_map_count=262144
# Persist: echo "vm.max_map_count=262144" >> /etc/sysctl.conf
```

---

## Minimal Docker Compose (single-node, security enabled)

```yaml
version: "3.8"
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.17.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-changeme}
      - ES_JAVA_OPTS=-Xms1g -Xmx1g
      - xpack.security.enabled=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    restart: unless-stopped

volumes:
  esdata:
    driver: local
```

---

## Upgrade Procedure

1. **Snapshot** all indices before upgrading
2. Check the [upgrade guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-upgrade.html) — major-version upgrades must go through each major version sequentially (e.g. 7 → 8 → 9)
3. Pull new image tag
4. For rolling upgrades (multi-node): disable shard allocation, stop one node, upgrade, re-enable — repeat per node
5. For single-node: `docker compose pull && docker compose up -d`
6. Run `GET /_cluster/health` to confirm `green` or `yellow` status

---

## Gotchas

- **vm.max_map_count** — Elasticsearch refuses to start if this is too low; set it on the **Docker host**, not inside the container
- **Heap sizing** — never set `-Xmx` above 32 GB (compressed OOP threshold); ~50% of system RAM is the sweet spot
- **Security by default** (v8+) — TLS and authentication are enabled out of the box; older v7 images had security off by default
- **License tiers** — Basic (free), Gold, Platinum, Enterprise; most self-hosted features are in Basic; X-Pack features (ML, SIEM) need a paid license or trial
- **Kibana pairing** — Kibana must match the exact Elasticsearch version; use the same image tag for both
- **Snapshots for backups** — there is no simple `mysqldump` equivalent; use the Snapshot API to back up indices
- **Single-node yellow** — a single-node cluster reports `yellow` health because replica shards cannot be assigned; this is normal; set `number_of_replicas: 0` for single-node

---

## Links

- Docs: https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html
- Docker: https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html
- Upgrade guide: https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-upgrade.html
- ECK (Kubernetes): https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html

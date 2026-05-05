# Apache Solr

Blazing-fast, open-source search platform built on Apache Lucene. Solr powers full-text, vector, and geospatial search at enterprise scale — with faceting, highlighting, spell-check, rich document handling (PDF, Word, HTML), and SolrCloud for distributed deployments.

**Official site:** https://solr.apache.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Official image on Docker Hub |
| Any Linux host | Standalone binary (Java) | Unzip and run `bin/solr start` |
| Kubernetes | Solr Operator (Helm) | Official Kubernetes operator available |
| Cloud (AWS/GCP/Azure) | Docker or Solr Operator | Managed Solr not available; self-host on VM or K8s |

---

## Inputs to Collect

### Phase 1 — Planning
- Deployment mode: standalone (single node) or SolrCloud (distributed with ZooKeeper)
- Expected index size and query volume
- Authentication requirements (BasicAuth plugin or Kerberos)

### Phase 2 — Deployment
- Solr heap size (`SOLR_HEAP`, default `512m`)
- Data directory / volume path
- Collection/core names
- Port (default `8983`)

---

## Software-Layer Concerns

### Docker Compose (Standalone)

```yaml
services:
  solr:
    image: solr:latest
    container_name: solr
    ports:
      - "8983:8983"
    volumes:
      - solr-data:/var/solr
    environment:
      - SOLR_HEAP=1g
    command:
      - solr-precreate
      - mycore

volumes:
  solr-data:
```

### Docker Compose (SolrCloud with ZooKeeper)

```yaml
services:
  zookeeper:
    image: zookeeper:3.9
    container_name: zookeeper
    environment:
      ZOO_MY_ID: 1

  solr1:
    image: solr:latest
    container_name: solr1
    ports:
      - "8983:8983"
    environment:
      - ZK_HOST=zookeeper:2181
    depends_on:
      - zookeeper
    volumes:
      - solr1-data:/var/solr

volumes:
  solr1-data:
```

### Standalone Binary Install

```bash
# Download from https://solr.apache.org/downloads.html
wget https://dlcdn.apache.org/solr/solr/<version>/solr-<version>.tgz
tar xzf solr-<version>.tgz
cd solr-<version>

# Start Solr
bin/solr start

# Create a core
bin/solr create -c mycore

# Start with example data
bin/solr start -e techproducts
```

### Environment Variables (Docker)
| Variable | Default | Purpose |
|----------|---------|---------|
| `SOLR_HEAP` | `512m` | JVM heap size for Solr |
| `ZK_HOST` | — | ZooKeeper connection string (SolrCloud only) |
| `SOLR_OPTS` | — | Additional JVM options |

### Data Paths
- `/var/solr/data/` — cores/collections data (Docker)
- `server/solr/` — cores data (binary install)

### Admin UI
Available at `http://localhost:8983/solr/` — provides core management, query interface, and schema browser.

---

## Upgrade Procedure

**Docker:** Update image tag in compose file, `docker compose pull && docker compose up -d`. Run `bin/solr zk upconfig` if schema changes are needed in SolrCloud.

**Binary:** Download new release, stop old Solr (`bin/solr stop`), extract new release, copy `server/solr/` data directory, start new Solr.

Always check the [Upgrade Notes](https://solr.apache.org/guide/solr/latest/upgrade-notes/solr-upgrade-notes.html) before major version upgrades.

---

## Gotchas

- **Java required:** Solr 9.x requires Java 11+; Solr 10.x requires Java 21+. The Docker image bundles Java.
- **`solr-precreate` vs `solr-demo`:** Use `solr-precreate <corename>` in Docker CMD to auto-create a core on first start.
- **SolrCloud requires ZooKeeper** — do not run SolrCloud without a ZK ensemble (minimum 3 nodes for production).
- **Security disabled by default** — enable the BasicAuth security plugin for any internet-exposed instance: `bin/solr auth enable`.
- **Heap sizing:** Allocate no more than 50% of available RAM to Solr heap; leave the rest for the OS file cache.
- **Port 8983 should not be publicly exposed** — put Nginx/Caddy in front with auth.
- **Schema changes** in SolrCloud require uploading new configs to ZooKeeper, then reloading the collection.

---

## References
- GitHub: https://github.com/apache/solr
- Official docs: https://solr.apache.org/guide/solr/latest/
- Docker Hub: https://hub.docker.com/_/solr
- Solr Operator (K8s): https://solr.apache.org/operator
- Upgrade notes: https://solr.apache.org/guide/solr/latest/upgrade-notes/solr-upgrade-notes.html

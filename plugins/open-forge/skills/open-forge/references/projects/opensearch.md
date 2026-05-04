# OpenSearch

Open-source, enterprise-grade search and observability suite. A community-driven, Apache 2.0-licensed fork of Elasticsearch 7.10 (and Kibana → OpenSearch Dashboards). Suitable for full-text search, log analytics (ELK-equivalent stack), security analytics, and vector/semantic search. Upstream: <https://github.com/opensearch-project/OpenSearch>. Docs: <https://docs.opensearch.org>.

OpenSearch nodes listen on port `9200` (REST API / search) and `9300` (cluster communication). OpenSearch Dashboards (the Kibana equivalent) listens on port `5601`.

## Compatible install methods

Verified against upstream docs at <https://docs.opensearch.org/docs/latest/install-and-configure/install-opensearch/>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.opensearch.org/docs/latest/install-and-configure/install-opensearch/docker/> | ✅ | Development and single-host deploys. Includes OpenSearch Dashboards. |
| Docker (standalone) | <https://hub.docker.com/r/opensearchproject/opensearch> | ✅ | Production with external orchestration. |
| Helm chart (Kubernetes) | <https://github.com/opensearch-project/helm-charts> | ✅ | Production Kubernetes. |
| Linux packages (deb/rpm/tar) | <https://docs.opensearch.org/docs/latest/install-and-configure/install-opensearch/rpm/> | ✅ | Bare-metal production installs. |
| Windows | <https://docs.opensearch.org/docs/latest/install-and-configure/install-opensearch/windows/> | ✅ | Windows host installs. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| cluster | "Cluster name?" | Free-text (e.g. `my-cluster`) | All |
| nodes | "Single node or multi-node cluster?" | `AskUserQuestion`: `Single node (dev)` / `Multi-node` | All |
| auth | "Admin password for OpenSearch?" | Free-text (sensitive) — min 8 chars, upper+lower+number+special | Docker |
| memory | "JVM heap size (default: 512m dev / 4g+ prod)?" | Free-text (e.g. `1g`) | All |
| tls | "TLS: use auto-generated self-signed certs or provide your own?" | `AskUserQuestion`: `Auto (self-signed)` / `Custom certs` | All |

## Software-layer concerns

### Key environment variables (Docker)

| Variable | Purpose | Notes |
|---|---|---|
| `discovery.type` | Cluster discovery mode | `single-node` for dev/single-node |
| `OPENSEARCH_INITIAL_ADMIN_PASSWORD` | Initial admin password | Required for v2.12+. Must be complex. |
| `DISABLE_SECURITY_PLUGIN` | Disable TLS + auth | Only for dev/testing. Never in production. |
| `DISABLE_INSTALL_DEMO_CONFIG` | Skip demo TLS config | Set to `true` when providing custom certs |
| `OPENSEARCH_JAVA_OPTS` | JVM options | e.g. `-Xms512m -Xmx512m` |
| `cluster.name` | Cluster name | Identifies the cluster |
| `node.name` | Node name | Unique per node |

### Docker Compose (single-node, development)

```yaml
services:
  opensearch:
    image: opensearchproject/opensearch:latest
    container_name: opensearch
    environment:
      cluster.name: opensearch-cluster
      node.name: opensearch-node1
      discovery.type: single-node
      OPENSEARCH_INITIAL_ADMIN_PASSWORD: "${OPENSEARCH_INITIAL_ADMIN_PASSWORD}"
      OPENSEARCH_JAVA_OPTS: "-Xms512m -Xmx512m"
    volumes:
      - opensearch_data:/usr/share/opensearch/data
    ports:
      - "9200:9200"
      - "9600:9600"   # Performance Analyzer
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    restart: unless-stopped

  opensearch-dashboards:
    image: opensearchproject/opensearch-dashboards:latest
    container_name: opensearch-dashboards
    ports:
      - "5601:5601"
    environment:
      OPENSEARCH_HOSTS: '["https://opensearch:9200"]'
    depends_on:
      - opensearch
    restart: unless-stopped

volumes:
  opensearch_data:
```

Set `OPENSEARCH_INITIAL_ADMIN_PASSWORD` in `.env` — must include uppercase, lowercase, digit, and special character.

Access: OpenSearch API at `https://localhost:9200`, Dashboards at `http://localhost:5601`.

### Multi-node cluster (production excerpt)

```yaml
# Repeat for node2, node3 with different node.name and seed_hosts
environment:
  cluster.name: opensearch-cluster
  node.name: opensearch-node1
  discovery.seed_hosts: opensearch-node1,opensearch-node2,opensearch-node3
  cluster.initial_cluster_manager_nodes: opensearch-node1,opensearch-node2,opensearch-node3
  OPENSEARCH_JAVA_OPTS: "-Xms4g -Xmx4g"
```

### Security plugin

OpenSearch ships with a security plugin enabled by default. It provides:
- TLS encryption (REST and transport layer)
- Basic auth, OIDC, SAML, Kerberos
- Role-based access control (RBAC)
- Audit logging

For development, TLS can be disabled:
```yaml
environment:
  DISABLE_SECURITY_PLUGIN: "true"   # Dev only — never in production
```

### Data directories

| Path | Contents |
|---|---|
| `/usr/share/opensearch/data` | Index data, transaction logs |
| `/usr/share/opensearch/config` | opensearch.yml, security config, TLS certs |
| `/usr/share/opensearch/logs` | Node logs |

## Upgrade procedure

Based on <https://docs.opensearch.org/docs/latest/upgrade-opensearch/>:

1. **Back up your indices** (snapshot to S3, filesystem, etc.).
2. For Docker: update image tag in compose file. For packages: upgrade OS packages.
3. Upgrade one node at a time (rolling upgrade for clusters ≥ 3 nodes).
4. OpenSearch supports rolling upgrades within the same major version.
5. Major version upgrades (e.g. 1.x → 2.x) require all nodes to be upgraded together.
6. Verify cluster health: `GET /_cluster/health` should return `green`.

## Gotchas

- **`OPENSEARCH_INITIAL_ADMIN_PASSWORD` is required in v2.12+.** Weak passwords are rejected at startup. Include uppercase, lowercase, digit, and special character.
- **Set `ulimits: memlock: -1`.** OpenSearch uses memory-mapping for performance. Without `memlock` unlimited, it will fail with warnings and degrade performance.
- **JVM heap = 50% of RAM, max 32GB.** `-Xms` and `-Xmx` should be equal and capped at ~32g (compressed OOPs limit).
- **Elasticsearch plugins do not work.** OpenSearch has its own plugin ecosystem. Some Elasticsearch plugins are compatible after recompilation; others are not.
- **Self-signed certs require client configuration.** If using the default auto-generated TLS certs, API clients must either trust the CA or disable cert verification.
- **Dashboards is a separate container.** OpenSearch Dashboards (the Kibana fork) is a separate image — `opensearchproject/opensearch-dashboards`.

## Links

- Upstream: <https://github.com/opensearch-project/OpenSearch>
- Docs: <https://docs.opensearch.org>
- Docker install: <https://docs.opensearch.org/docs/latest/install-and-configure/install-opensearch/docker/>
- Docker Hub: <https://hub.docker.com/r/opensearchproject/opensearch>
- Helm charts: <https://github.com/opensearch-project/helm-charts>
- Dashboards: <https://github.com/opensearch-project/OpenSearch-Dashboards>
- Upgrade guide: <https://docs.opensearch.org/docs/latest/upgrade-opensearch/>

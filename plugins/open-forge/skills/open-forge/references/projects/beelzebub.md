# Beelzebub

LLM-powered deception runtime and honeypot framework. Beelzebub deploys adaptive decoy services across SSH, HTTP, TCP, Telnet, and MCP protocols — using OpenAI or Ollama to generate realistic attacker interactions and collect threat intelligence.

**Official site:** https://github.com/beelzebub-labs/beelzebub

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary deployment method |
| Any Linux host | Go binary | Build from source; requires Go 1.21+ |
| Kubernetes | Helm | Official Helm chart in repo (`beelzebub-chart/`) |
| Cloud VPS | Docker Compose | Ideal for internet-exposed honeypot deployments |

---

## Inputs to Collect

### Phase 1 — Planning
- LLM backend: OpenAI API key or local Ollama endpoint
- Which protocols to expose: SSH, HTTP, TCP, Telnet, MCP
- Whether to enable Prometheus metrics and/or RabbitMQ event streaming
- Memory limit per service (default 100 MiB)

### Phase 2 — Deployment
- `OPEN_AI_SECRET_KEY` — OpenAI API key (or configure Ollama URL in service YAML)
- `RABBITMQ_URI` — optional, for event streaming to SIEM
- Port assignments for each decoy service

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  beelzebub:
    build: .
    container_name: beelzebub
    restart: always
    ports:
      - "22:22"       # SSH decoy
      - "23:23"       # Telnet decoy
      - "2222:2222"   # Alt SSH decoy
      - "8080:8080"   # HTTP decoy
      - "8081:8081"   # MCP decoy (AI agent deception)
      - "3306:3306"   # MySQL/MariaDB decoy
      - "80:80"       # HTTP decoy (standard)
      - "2112:2112"   # Prometheus metrics
    environment:
      RABBITMQ_URI: ${RABBITMQ_URI}
      OPEN_AI_SECRET_KEY: ${OPEN_AI_SECRET_KEY}
    volumes:
      - "./configurations:/configurations"
```

> **Note:** The official image is built from source — clone the repo and run `docker compose build` then `docker compose up -d`.

### Service Configuration (YAML)

Services are defined in `configurations/services/*.yaml`:

```yaml
# configurations/services/ssh.yaml
apiVersion: "v1"
protocol: "ssh"
address: ":22"
commands:
  - regex: "^ls"
    handler: "plugin"
    plugin: "OpenAIGPTLinuxTerminal"
  - regex: ".*"
    handler: "plugin"
    plugin: "OpenAIGPTLinuxTerminal"
```

### Core Configuration

```yaml
# configurations/beelzebub.yaml
core:
  logging:
    debug: false
  tracings:
    rabbit-mq:
      enabled: false
      uri: ${RABBITMQ_URI}
```

### Environment Variables
| Variable | Purpose |
|----------|---------|
| `OPEN_AI_SECRET_KEY` | OpenAI API key for LLM responses |
| `RABBITMQ_URI` | AMQP URI for event streaming (optional) |

### Prometheus Metrics (`:2112/metrics`)
| Metric | Description |
|--------|-------------|
| `beelzebub_events_total` | Total deception events |
| `beelzebub_events_ssh_total` | SSH interactions |
| `beelzebub_events_http_total` | HTTP interactions |
| `beelzebub_events_tcp_total` | TCP interactions |

---

## Upgrade Procedure

**Docker:** `git pull && docker compose build && docker compose up -d`

**Helm:** `helm upgrade beelzebub ./beelzebub-chart`

**Binary:** `git pull && go build -o beelzebub . && ./beelzebub run`

---

## Gotchas

- **Build-from-source only for Docker** — there is no pre-built image on Docker Hub; you must `docker compose build` from the cloned repo.
- **Expose decoy ports with care** — binding port 22 means your real SSH must move to a different port first.
- **LLM costs:** OpenAI usage adds up quickly under heavy attacker interaction; set `mem-limit-mib` and consider using local Ollama.
- **Port conflicts:** The default compose exposes ports 22, 23, 80 — ensure these are not in use by other services.
- **Validate config before restart:** `beelzebub validate` parses all YAML without starting services, useful in CI.
- **MCP deception service** (`:8081` by default) targets AI agents — useful for detecting prompt injection attacks.

---

## References
- GitHub: https://github.com/beelzebub-labs/beelzebub
- Plugin SDK: https://pkg.go.dev/github.com/beelzebub-labs/beelzebub/v3/pkg/plugin

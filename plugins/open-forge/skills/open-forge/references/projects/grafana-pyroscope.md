---
name: grafana-pyroscope
description: Grafana Pyroscope recipe for open-forge. Open-source continuous profiling platform for CPU, memory, and I/O performance insights. Integrates with Grafana's Explore Profiles UI.
---

# Grafana Pyroscope

Open-source continuous profiling platform. Collects CPU, memory, goroutine, and I/O profiles from applications (via push SDKs or pull via Grafana Alloy) and stores them for analysis. Visualize with Grafana's Explore Profiles UI. Upstream: <https://github.com/grafana/pyroscope>. Docs: <https://grafana.com/docs/pyroscope/latest/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single container) | Dev / quickstart |
| Docker Compose | Dev + app containers |
| Helm (Kubernetes) | Production K8s |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which languages/runtimes to profile?" | Go, Python, Java, Node.js, Ruby, .NET, eBPF (Alloy) |
| preflight | "Push SDK or pull via Grafana Alloy?" | Push = instrument app; Pull = agent-based, no code changes |

## Docker quickstart

```bash
docker run -it -p 4040:4040 grafana/pyroscope
```

- UI (via Grafana): query at http://localhost:4040
- Pyroscope API: http://localhost:4040/pyroscope/

## Docker Compose example

```yaml
version: "3.9"
services:
  pyroscope:
    image: grafana/pyroscope:latest
    ports:
      - "4040:4040"
    volumes:
      - pyroscope-data:/data

volumes:
  pyroscope-data:
```

## Sending profiles

### Option A: Push SDK (Go example)

```go
import "github.com/grafana/pyroscope-go"

pyroscope.Start(pyroscope.Config{
  ApplicationName: "my-app",
  ServerAddress:   "http://pyroscope:4040",
  Logger:          pyroscope.StandardLogger,
  ProfileTypes: []pyroscope.ProfileType{
    pyroscope.ProfileCPU,
    pyroscope.ProfileAllocObjects,
    pyroscope.ProfileAllocSpace,
  },
})
```

SDKs available for: Go, Python, Java/JVM, Node.js, Ruby, .NET, Rust — see <https://grafana.com/docs/pyroscope/latest/configure-client/>

### Option B: Grafana Alloy (pull, no code changes)

Use `pyroscope.scrape` component in Alloy config to pull profiles via `/debug/pprof/` endpoints (Go, Java) or eBPF for any process.

## Grafana datasource

Add a Pyroscope datasource: **Type: Grafana Pyroscope**, **URL: http://pyroscope:4040**

Explore via: **Grafana → Explore → Profiles** (requires `grafana-pyroscope-app` plugin)

## Software-layer concerns

- Port: `4040` (HTTP API + profiling ingest)
- Data stored at `/data` — persist this volume
- Supports multi-tenancy via `X-Scope-OrgID` header (same pattern as Mimir/Loki)
- License: AGPL-3.0

## Upgrade procedure

1. Pull new image: `docker compose pull pyroscope`
2. Restart: `docker compose up -d pyroscope`
3. Data volume persists; migrations run automatically

## Gotchas

- No built-in standalone query UI — requires Grafana + pyroscope-app plugin for visualization
- eBPF profiling (pull mode) requires privileged container or Linux capabilities (`SYS_ADMIN`, `BPF`)
- Go pprof endpoint must be exposed (`import _ "net/http/pprof"`) for pull-mode scraping
- AGPL-3.0 license — same considerations as Grafana Mimir/Loki

## Links

- GitHub: <https://github.com/grafana/pyroscope>
- Docs: <https://grafana.com/docs/pyroscope/latest/>
- Client SDKs: <https://grafana.com/docs/pyroscope/latest/configure-client/>
- Docker Hub: <https://hub.docker.com/r/grafana/pyroscope>

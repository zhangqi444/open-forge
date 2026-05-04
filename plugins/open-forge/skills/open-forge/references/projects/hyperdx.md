---
name: hyperdx
description: HyperDX recipe for open-forge. Open-source observability platform (logs, traces, metrics, session replays) built on ClickHouse — part of the ClickStack suite.
---

# HyperDX

Open-source observability platform that correlates logs, traces, metrics, and session replays in one place. Built on ClickHouse; part of the [ClickStack](https://clickhouse.com/use-cases/observability/clickstack/overview) observability suite. Upstream: <https://github.com/hyperdxio/hyperdx>. Docs: <https://clickhouse.com/docs/use-cases/observability/clickstack/deployment>.

## Compatible install methods

| Method | When to use |
|---|---|
| All-in-one Docker (quickstart) | Local dev / small teams; single container |
| Docker Compose (ClickStack) | Production; separates ClickHouse, HyperDX, OTel Collector, MongoDB |
| Helm (Kubernetes) | K8s production deployments |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "All-in-one or full ClickStack compose?" | Drives which deployment path |
| preflight | "Domain / public URL for HyperDX?" | Needed for reverse-proxy and OTel SDK config |
| preflight | "ClickHouse password?" | Used by HyperDX to connect |

## All-in-one quickstart

```bash
docker run -p 8080:8080 -p 4317:4317 -p 4318:4318 \
  docker.hyperdx.io/hyperdx/hyperdx-all-in-one
```

- UI: http://localhost:8080
- OTel gRPC: 4317, HTTP: 4318
- Requires ≥ 4 GB RAM and 2 CPU cores

## Docker Compose (ClickStack)

See upstream deployment docs: <https://clickhouse.com/docs/use-cases/observability/clickstack/deployment>

Key services: `clickhouse`, `hyperdx`, `otel-collector`, `mongodb`

## Software-layer concerns

- Ports: `8080` (UI/API), `8000` (internal API), `4317` (OTel gRPC), `4318` (OTel HTTP)
- Firewall: open 8080, 8000, 4318 if behind a firewall (upstream note)
- Data is stored in ClickHouse — persist ClickHouse volumes
- OTel SDKs: Browser, Node.js, Python available; see <https://clickhouse.com/docs/use-cases/observability/clickstack/sdks/>
- HyperDX is schema-agnostic — works on top of existing ClickHouse schemas

## Upgrade procedure

1. Pull updated images: `docker compose pull`
2. Restart: `docker compose up -d`
3. Check ClickHouse migration logs on first start after version bump

## Gotchas

- All-in-one image is `docker.hyperdx.io/hyperdx/hyperdx-all-in-one` — **not Docker Hub**
- Minimum 4 GB RAM; ClickHouse is memory-hungry
- HyperDX was acquired by ClickHouse; codebase now part of ClickStack ecosystem — branding/docs may shift
- Put UI behind a reverse proxy with TLS for production

## Links

- GitHub: <https://github.com/hyperdxio/hyperdx>
- ClickStack docs: <https://clickhouse.com/docs/use-cases/observability/clickstack/overview>
- Deployment guide: <https://clickhouse.com/docs/use-cases/observability/clickstack/deployment>

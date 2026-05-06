---
name: lura
description: Lura recipe for open-forge. High-performance API gateway framework (Go). The open-source framework powering KrakenD CE. Self-host via KrakenD CE binary or Docker. Source: https://github.com/luraproject/lura. KrakenD CE (full gateway binary): https://github.com/krakend/krakend-ce.
---

# Lura / KrakenD CE

Lura is the open-source Go framework underlying the KrakenD API Gateway. It sits between clients and backend microservices: aggregates multiple upstream calls into a single endpoint, fans out requests, filters/transforms responses, and applies auth/rate-limit middleware. Upstream framework: <https://github.com/luraproject/lura>. The ready-to-run binary (KrakenD CE) is at <https://github.com/krakend/krakend-ce> and <https://www.krakend.io>.

> **Note on naming:** "Lura" is the framework (library). "KrakenD CE" is the full, deployable gateway binary built on Lura. In most self-hosting scenarios you deploy KrakenD CE, not Lura directly. This recipe covers KrakenD CE deployment.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker (single container) | Recommended; stateless, no external DB needed |
| VPS / bare metal | Native binary | Download from krakend.io/download; Linux/macOS/Windows |
| Kubernetes | Helm chart | Official chart at https://github.com/krakend/helm-charts |
| Local dev | Docker | docker run + config file mount |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Will you deploy via Docker or native binary?" | Drives install steps |
| config | "Port for the gateway to listen on?" | Default: 8080 |
| backends | "List the upstream service URLs to proxy/aggregate?" | Each becomes an endpoint backend in krakend.json |
| auth | "JWT validation needed? If so, what JWKS URL?" | Optional; configured per-endpoint |
| tls | "TLS termination at gateway, reverse proxy, or none?" | KrakenD can do TLS directly or sit behind NGINX/Caddy |

## Software-layer concerns

- Config: single JSON file (krakend.json); no database, no persistent state
- Default port: 8080 (configurable via $KRAKEND_PORT or config)
- Zero external dependencies: KrakenD CE is a single stateless binary
- Hot-reload: not supported natively; restart container to apply config changes
- Logging: stdout JSON by default; pipe to log aggregator of choice
- Metrics: built-in Prometheus metrics endpoint at /__stats (enable in config)
- Flexible Configuration: supports env var substitution inside krakend.json using ${{ env "VAR" }} syntax

### Minimal Docker run

```bash
docker run -p 8080:8080 \
  -v $(pwd)/krakend.json:/etc/krakend/krakend.json \
  devopsfaith/krakend run -c /etc/krakend/krakend.json
```

### Minimal Docker Compose

```yaml
services:
  krakend:
    image: devopsfaith/krakend:latest
    container_name: krakend
    ports:
      - "8080:8080"
    volumes:
      - ./krakend.json:/etc/krakend/krakend.json:ro
    command: run -c /etc/krakend/krakend.json
    restart: unless-stopped
```

### Minimal krakend.json

```json
{
  "$schema": "https://www.krakend.io/schema/v3.json",
  "version": 3,
  "port": 8080,
  "endpoints": [
    {
      "endpoint": "/api/users",
      "method": "GET",
      "backend": [
        {
          "url_pattern": "/users",
          "host": ["http://users-service:8000"]
        }
      ]
    }
  ]
}
```

Validate config before deploying: `docker run --rm -v $(pwd)/krakend.json:/etc/krakend/krakend.json devopsfaith/krakend check -c /etc/krakend/krakend.json`

## Upgrade procedure

1. Review release notes: https://github.com/krakend/krakend-ce/releases
2. Test new version against config with krakend check (non-breaking usually; major versions may have config schema changes)
3. Pull new image: docker compose pull
4. docker compose up -d
5. Verify endpoints respond: curl http://localhost:8080/__health

## Gotchas

- No persistent state: KrakenD is entirely config-driven. Restart = reload. No online config editing.
- Config validation: Always run krakend check before deploying a new config; malformed JSON silently fails to start.
- Lura vs KrakenD CE: Lura is a Go library for building gateways; KrakenD CE is the ready-to-run binary. Deploy KrakenD CE unless you're writing your own gateway binary.
- Endpoint aggregation: Each endpoint can call multiple backends and merge responses; order of backend responses is not guaranteed unless you use sequential proxy mode.
- Rate limiting: Requires explicit configuration per endpoint; no global rate limit by default.
- HTTPS termination: KrakenD supports TLS directly but is commonly placed behind a reverse proxy (NGINX, Caddy, Traefik) for cert management.
- Enterprise vs CE: Some features (OAuth2 full support, OpenAPI import, advanced transformations) are Enterprise-only. Check https://www.krakend.io/features/ for the feature matrix.

## Links

- Lura framework: https://github.com/luraproject/lura
- KrakenD CE (deployable binary): https://github.com/krakend/krakend-ce
- KrakenD docs: https://www.krakend.io/docs/
- Docker Hub: https://hub.docker.com/r/devopsfaith/krakend
- KrakenD Designer (visual config editor): https://designer.krakend.io/
- Helm chart: https://github.com/krakend/helm-charts

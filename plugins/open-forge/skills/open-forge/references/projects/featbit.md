---
name: featbit
description: Featbit recipe for open-forge. Enterprise-grade self-hosted feature flag platform with SDK support for many languages, A/B testing, experimentation, audit logs, and team management. Source: https://github.com/featbit/featbit
---

# Featbit

Enterprise-grade self-hosted feature flag platform. Enables controlled rollouts, A/B testing, experimentation, and targeting rules across multiple environments. Provides SDKs for .NET, Java, Python, JavaScript, Go, and more. Built on .NET 8 + Angular with PostgreSQL storage. Upstream: https://github.com/featbit/featbit. Docs: https://docs.featbit.co.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose | Docker | Recommended. Official images. Single-command startup. |
| Kubernetes | K8s | Helm charts available in docs. |
| Source build | .NET 8 + Node.js | For development or customization. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Public URL for the Featbit UI?" | e.g. http://featbit.example.com:8081 — set as API_URL and EVALUATION_URL env vars |
| setup | "PostgreSQL password?" | Replace the default please_change_me in docker-compose.yml |
| setup | "Admin email and password?" | Created on first login through the web UI |

## Software-layer concerns

### Docker Compose (recommended)

  git clone https://github.com/featbit/featbit.git
  cd featbit

  # Edit docker-compose.yml:
  # - Replace all occurrences of please_change_me with a strong password
  # - Set API_URL to your server's address (e.g. http://your-server-ip:5000)
  # - Set EVALUATION_URL to http://your-server-ip:5100

  docker compose up -d

Services started:
  - ui              — Angular web console (port 8081)
  - api-server      — .NET REST API (port 5000)
  - evaluation-server — SDK evaluation endpoint (port 5100)
  - da-server       — Data analytics service (port 8200)
  - postgresql      — PostgreSQL 15 database (port 5432)

### Key environment variables

  # In docker-compose.yml — api-server and evaluation-server:
  DbProvider=Postgres
  MqProvider=Postgres
  CacheProvider=None
  Postgres__ConnectionString=Host=postgresql;Port=5432;Username=postgres;Password=<pw>;Database=featbit

  # In ui service:
  API_URL=http://<host>:5000         # REST API address
  EVALUATION_URL=http://<host>:5100  # SDK streaming endpoint

### Post-setup

1. Open http://<host>:8081 in browser
2. Create the initial admin account
3. Create an Organization and Project
4. Create feature flags and copy the SDK key from Settings > Environments
5. Integrate with your app using an SDK: https://docs.featbit.co/sdk/overview

### SDK connection

SDKs connect to the evaluation-server endpoint (port 5100 by default).
The SDK key (not the API token) is used for SDK authentication.

Example (Node.js):

  import { init } from '@featbit/node-server-sdk';
  const client = init({
    sdkKey: '<env-sdk-key>',
    streamingUri: 'http://<host>:5100',
    eventsUri: 'http://<host>:5100',
  });

## Upgrade procedure

  cd featbit
  git pull
  docker compose pull
  docker compose up -d

## Gotchas

- **please_change_me default password**: must be changed before any production use — it appears in multiple places in docker-compose.yml.
- **API_URL vs EVALUATION_URL**: these are consumed by the browser (UI) and by SDKs respectively. If behind a reverse proxy, both must be publicly reachable.
- **Port 5100 for SDKs**: this port must be accessible from application servers / client environments using the SDK, not just from browsers.
- **PostgreSQL init scripts**: the infra/postgresql/docker-entrypoint-initdb.d/ directory contains DB init SQL. Don't delete it before first boot.
- **No built-in TLS**: run behind nginx/Caddy for HTTPS. Update API_URL and EVALUATION_URL to https:// accordingly.
- **Redis option**: an optional Redis-backed variant exists for higher scale; the default Postgres-backed setup suits most self-hosters.

## References

- Upstream GitHub: https://github.com/featbit/featbit
- Documentation: https://docs.featbit.co
- SDK overview: https://docs.featbit.co/sdk/overview
- Docker Hub: https://hub.docker.com/u/featbit

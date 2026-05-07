---
name: openolitor
description: OpenOlitor recipe for open-forge. Administration platform for Community Supported Agriculture (CSA) groups — member management, orders, deliveries, and accounting. Scala + MariaDB + S3. Source: https://github.com/OpenOlitor/openolitor-server
---

# OpenOlitor

An administration platform for Community Supported Agriculture (CSA) groups. Manages members, subscriptions, depot assignments, deliveries, orders, and basic accounting for CSA/subscription farm operations. AGPL-3.0 licensed, Scala backend with an AngularJS frontend. Upstream (server): <https://github.com/OpenOlitor/openolitor-server>. Main project: <https://github.com/OpenOlitor/OpenOlitor>. Website: <https://openolitor.org/>

> ℹ️ **Note**: OpenOlitor is a multi-repo project with German/French documentation. The README and wiki are primarily in German/French.

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Docker Compose | Recommended; uses MariaDB + S3-compatible storage |
| Any Linux VPS | SBT build (native Scala) | For development; requires SBT + JDK |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for OpenOlitor?" | FQDN | e.g. csa.example.org |
| "MariaDB root password?" | String (sensitive) | For database initialisation |
| "OpenOlitor DB user password?" | String (sensitive) | App database user |
| "S3-compatible storage endpoint and credentials?" | endpoint + key + secret | For file/document storage; can use local MinIO |
| "SMTP config for member emails?" | host:port + credentials | Required for member notifications, invoices |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "CSA group name?" | String | Shown throughout the admin UI |
| "Primary language?" | de / fr / en | German and French are best-supported |

## Software-Layer Concerns

- **Multi-repo**: Server backend at openolitor-server; client (AngularJS) is a separate repo. Docker Compose bundles both.
- **MariaDB**: Preferred database; schema managed by the server on first run.
- **S3 storage**: Required for document uploads (invoices, delivery notes). Use MinIO for fully self-hosted deployment.
- **SMTP**: Required for member communications — invoices, delivery schedules, registration confirmations.
- **German/French primary**: UI and documentation are primarily in German and French. English support is partial.
- **CSA-specific domain model**: Designed around CSA concepts (depots, subscriptions, abos, Lieferpositionen). Not a general farm management tool.
- **Development activity**: Maintained by a Swiss/German cooperative — commit activity is episodic.

## Deployment

### Docker Compose

The `docker` directory in the server repo contains example configurations. Refer to the wiki for the current compose setup:

```bash
git clone https://github.com/OpenOlitor/openolitor-server.git
cd openolitor-server/docker
# Review and edit docker-compose configuration for your environment
# Set DB credentials, S3/storage config, SMTP, domain
docker compose up -d
```

See the technical setup wiki page: <https://github.com/OpenOlitor/OpenOlitor/wiki/Doku-Technisch_Server_Ent-Setup>

## Upgrade Procedure

1. Pull latest server image and client: `docker compose pull && docker compose up -d`
2. Database migrations run automatically on startup.
3. Check release notes: https://github.com/OpenOlitor/OpenOlitor/wiki/Release-Notes

## Gotchas

- **German-first**: Primary documentation is in German. Use a browser translator for wiki pages if needed.
- **CSA domain knowledge required**: Configuration assumes familiarity with CSA operations (depots, abos, lieferpositionen).
- **S3 required**: Local file storage is not supported without an S3-compatible endpoint — set up MinIO alongside if not using cloud S3.
- **Multi-repo complexity**: Server, client, and Docker configs are in separate repos; keep versions aligned.
- **Not a general farm/ERP tool**: Purpose-built for CSA subscription boxes — not suitable as general farm management or e-commerce.

## Links

- Server source: https://github.com/OpenOlitor/openolitor-server
- Main project / issues: https://github.com/OpenOlitor/OpenOlitor
- Wiki (German/French): https://github.com/OpenOlitor/OpenOlitor/wiki
- Website: https://openolitor.org/
- Release notes: https://github.com/OpenOlitor/OpenOlitor/wiki/Release-Notes

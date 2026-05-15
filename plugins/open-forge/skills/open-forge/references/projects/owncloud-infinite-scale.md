---
name: ownCloud Infinite Scale (oCIS)
description: "File sync and share platform — complete rewrite of ownCloud in Go. Microservices. High scalability. EULA for production use. owncloud org. Matrix. SonarCloud + Drone CI. Apache-2.0 code; separate EULA may apply."
---

# ownCloud Infinite Scale (oCIS)

oCIS is **"ownCloud 10 rewritten from scratch in Go as microservices"** — a complete file sync + share platform rewrite. Replaces ownCloud 10 (PHP) with a Go microservices architecture designed for cloud-native, high-scalability deployments. Supports Web Office integrations, clients on all major platforms.

Built + maintained by **ownCloud** (the company; now under **Kiteworks** ownership). Apache-2.0 code license; **End User License Agreement** applies for certain production uses — read before deploying. SonarCloud quality tracking. Matrix chat.

Use cases: (a) **enterprise file-sync-and-share** (b) **ownCloud 10 migration destination** (c) **high-scale team file-collab** (d) **cloud-native storage platform** (e) **Collabora/OnlyOffice integration** for Web Office (f) **GDPR-compliant sovereign file platform** (g) **S3-backed storage at scale** (h) **multi-tenant SaaS-like deployment**.

Features (per README + docs):

- **Go microservices** rewrite
- **High scalability** — infinite-scale design
- **Web Office apps** (Collabora/OnlyOffice)
- **Clients** on desktop + mobile
- **OpenID Connect** auth (IdP required)
- **Drone CI** pipeline
- **Security-focus** (SonarCloud)

- Upstream repo: <https://github.com/owncloud/ocis>
- Docs: <https://doc.owncloud.com/ocis_release/>
- Matrix: `#ocis:matrix.org`
- Docker Hub: <https://hub.docker.com/r/owncloud/ocis>

## Architecture in one minute

- **Go microservices** — many binaries in one `ocis` binary
- **OpenID Connect** external IdP (Keycloak/Zitadel/etc.)
- **S3 or local FS** for blobs
- **ClamAV** optional antivirus
- **Resource**: moderate-to-heavy at scale

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | Reference                                                                                                              | Primary                                                                                    |
| **Binary**         | Single binary                                                                                                          | Alt                                                                                   |
| **K8s Helm**       | For scale                                                                                                              | Recommended for production                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `files.example.com`                                         | URL          | **TLS MANDATORY**                                                                                    |
| OIDC IdP             | Keycloak/Zitadel/Okta URL                                   | Auth         | **Required**                                                                                    |
| OIDC client          | ID/secret                                                   | Secret       |                                                                                    |
| Storage backend      | Local/S3                                                    | Storage      | S3 for scale                                                                                    |
| Admin user           | Via IdP                                                     | Bootstrap    |                                                                                    |
| ClamAV (opt)         | Antivirus                                                   | Integration  |                                                                                    |
| Collabora/OnlyOffice | Web Office                                                  | Integration  | Optional                                                                                    |
| EULA review          | **Commercial use**                                          | Legal        | Read before production                                                                                    |

## Install via Docker Compose

See official docs: <https://doc.owncloud.com/ocis_release/deployment/>. Reference compose in the repo `deployments/examples/` — **review carefully**.

```yaml
services:
  ocis:
    image: owncloud/ocis:8.0.3        # **pin — track EULA for your tag**
    environment:
      OCIS_URL: https://files.example.com
      OCIS_INSECURE: "false"
      IDP_ISSUER: https://keycloak.example.com/realms/main
      # ... many envs
    volumes:
      - ./ocis-data:/var/lib/ocis
      - ./ocis-config:/etc/ocis
    ports: ["9200:9200"]
```

## First boot

1. Provision OIDC IdP separately (Keycloak/Zitadel)
2. Create OIDC client in IdP
3. Configure OCIS envs pointing at IdP
4. `ocis init` to generate initial configs
5. `ocis server` to start
6. First IdP-authenticated user becomes admin (check docs)
7. Put behind TLS via reverse proxy (nginx/Traefik)
8. Back up data + configs
9. **READ EULA** for your deployment context

## Data & config layout

- `/var/lib/ocis/` — user data blobs
- `/etc/ocis/` — configs + secrets

## Backup

```sh
sudo tar czf ocis-$(date +%F).tgz ocis-data/ ocis-config/
# Contains user files + secrets — **ENCRYPT**
# Consider S3-versioning for blobs
```

## Upgrade

1. Releases: <https://github.com/owncloud/ocis/releases>
2. Read release notes + migration guide
3. Docker pull + restart
4. Major versions may need migration

## Gotchas

- **164th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — FILE-SYNC-AND-SHARE-PLATFORM**:
  - Holds: **all user files** — documents, photos, sensitive data, shared links
  - Auth via external IdP (less creds in oCIS itself; but file-content sensitivity is maximum)
  - OIDC session-tokens
  - Shared-link secrets
  - **164th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "file-sync-share + team-collab-files"** (1st — oCIS)
  - **CROWN-JEWEL Tier 1: 56 tools / 51 sub-categories**
- **EULA-FOR-PRODUCTION-USE**:
  - Apache-2.0 code + End User License Agreement
  - Commercial use may require acceptance
  - **Recipe convention: "Apache-2-with-separate-EULA-awareness callout"**
  - **NEW recipe convention** (oCIS 1st formally; HIGH-severity for commercial deployments)
- **RECENT-OWNERSHIP-CHANGE (Kiteworks)**:
  - ownCloud acquired by Kiteworks
  - Stewardship shift worth monitoring
  - **Recipe convention: "recent-corporate-acquisition-stewardship-watch neutral-signal"**
  - **NEW neutral-signal convention** (oCIS 1st formally)
- **MICROSERVICE-COMPLEXITY-TAX**:
  - Many services bundled in single binary
  - Operational complexity at scale
  - **Microservice-complexity-tax: 8 tools** (+oCIS) 🎯 **8-TOOL MILESTONE**
- **COMPLETE-REWRITE-FROM-SCRATCH**:
  - oCIS is NOT ownCloud 10; it's a rewrite
  - Migration path exists but non-trivial
  - **Recipe convention: "complete-rewrite-migration-path-required callout"**
  - **NEW recipe convention** (oCIS 1st formally)
- **EXTERNAL-IDP-REQUIREMENT**:
  - No built-in user mgmt; requires external OIDC
  - **Recipe convention: "external-IdP-required-not-built-in neutral-signal"**
  - **NEW neutral-signal convention** (oCIS 1st formally)
- **SONARCLOUD-QUALITY-TRACKING**:
  - Security + coverage public
  - **Recipe convention: "SonarCloud-quality-transparency positive-signal"**
  - **NEW positive-signal convention** (oCIS 1st formally)
  - (Distinct from Codacy — 1st at Cloud Commander; similar spirit)
- **DRONE-CI**:
  - Self-hosted Drone CI
  - **Recipe convention: "self-hosted-CI-pipeline neutral-signal"**
  - **NEW neutral-signal convention** (oCIS 1st formally)
- **ACCEPTANCE-TEST-COVERAGE-BADGE**:
  - Separate acceptance-test coverage
  - Enterprise-grade quality discipline
  - **Recipe convention: "separate-acceptance-test-coverage-tracking positive-signal"**
  - **NEW positive-signal convention** (oCIS 1st formally)
- **SERVICE-CROSS-WITH-KITEWORKS-ECOSYSTEM**:
  - Cross-product integration potential
  - **Recipe convention: "corporate-ecosystem-cross-product-integration neutral-signal"**
  - **NEW neutral-signal convention** (oCIS 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: ownCloud-now-Kiteworks + Matrix + SonarCloud + Drone CI + docs-site + acceptance-tests + decade-plus. **150th tool 🎯 150-TOOL MILESTONE in institutional-stewardship family — major-commercial-corporate-OSS sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + SonarCloud + docs + Matrix + Apache-2-code. **156th tool in transparent-maintenance family.**
- **FILE-SYNC-SHARE-CATEGORY:**
  - **oCIS** — ownCloud rewrite in Go
  - **Nextcloud** — ownCloud fork; PHP; dominant OSS option
  - **Seafile** — C; enterprise-mature
  - **Syncthing** — P2P; no server
  - **ownCloud 10** — legacy PHP; being sunset
- **ALTERNATIVES WORTH KNOWING:**
  - **Nextcloud** — if you want PHP + dominant OSS + richer app ecosystem
  - **Seafile** — if you want C-based + enterprise-grade
  - **Syncthing** — if you want P2P-no-server
  - **Choose oCIS if:** you want ownCloud-future + Go-microservices + cloud-native scale.
- **PROJECT HEALTH**: active + Kiteworks-backed + CI + quality-gates + Matrix. Strong, but EULA + acquisition = monitor.

## Links

- Repo: <https://github.com/owncloud/ocis>
- Docs: <https://doc.owncloud.com/ocis_release/>
- Nextcloud (alt): <https://github.com/nextcloud/server>
- Seafile (alt): <https://github.com/haiwen/seafile>

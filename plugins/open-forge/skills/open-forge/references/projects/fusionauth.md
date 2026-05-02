# FusionAuth

**What it is:** A full-featured authentication and user management platform. Provides login, registration, MFA, SSO, OAuth2/OIDC, SAML, passwordless, social login, user search, audit logs, and more. Drop-in replacement for Auth0/Okta/Cognito with a self-hosted option. Free Community edition; paid plans for advanced features.

> **Closed source.** The core FusionAuth engine is proprietary. Self-hosted Community edition is free but not open source.

**Official URL:** https://fusionauth.io/download
**License:** Proprietary (Community edition free; paid tiers for advanced features)
**Stack:** Java; Docker; available as `.deb`/`.rpm` packages

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Docker Compose | Recommended for self-hosted; official compose files provided |
| Any Linux | `.deb` / `.rpm` package | Native install with system service |
| Kubernetes | Helm chart | Official chart available |

---

## Inputs to Collect

### Pre-deployment
- Database — PostgreSQL or MySQL (required for production; FusionAuth manages its own schema)
- `FUSIONAUTH_APP_MEMORY` — JVM heap size (e.g. `512M`)
- Port — default `9011`
- License key — required for paid plan features; Community edition works without one

---

## Software-Layer Concerns

**Quick Docker Compose (with bundled database — dev/test only):**
```bash
curl -o docker-compose.yml \
  https://raw.githubusercontent.com/FusionAuth/fusionauth-containers/main/docker/fusionauth/docker-compose.yml
curl -o .env \
  https://raw.githubusercontent.com/FusionAuth/fusionauth-containers/main/docker/fusionauth/.env
docker compose up -d
```
Visit `http://localhost:9011` to complete setup.

**Production:** Use an external PostgreSQL or MySQL instance instead of the bundled database. See https://fusionauth.io/docs/get-started/download-and-install/docker for the production compose example.

**Default port:** `9011`

**Initial setup:** After first launch, a setup wizard guides you through creating the admin account and configuring your first application/tenant.

**Upgrade procedure:**
1. Update the image tag in `docker-compose.yml`
2. `docker compose pull && docker compose up -d`
3. FusionAuth runs database migrations automatically on startup

---

## Gotchas

- **Closed source** — Community edition is free but proprietary; advanced features (advanced MFA, SAML IdP, webhooks, etc.) require a paid license
- **Java app** — memory usage is higher than Go/Rust equivalents; allocate at least 512MB RAM
- **PostgreSQL recommended for production** — the bundled database in the quick-start compose is for dev/testing only
- **License key for paid features** — enter in the admin UI under Reactor; Community edition works without one but has feature limits
- **Open alternatives:** [Keycloak](https://github.com/keycloak/keycloak) and [Authentik](https://github.com/goauthentik/authentik) are popular open-source alternatives

---

## Links
- Download/install: https://fusionauth.io/download
- Docker install docs: https://fusionauth.io/docs/get-started/download-and-install/docker
- Docker containers repo: https://github.com/FusionAuth/fusionauth-containers

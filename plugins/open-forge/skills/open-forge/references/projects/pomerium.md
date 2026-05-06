---
name: pomerium
description: Pomerium recipe for open-forge. Identity-aware reverse proxy and zero-trust access gateway — protect internal apps with OAuth/OIDC without a VPN. Docker install. Upstream: https://github.com/pomerium/pomerium
---

# Pomerium

Identity and context-aware reverse proxy. Secure access to internal web apps without a VPN — every request is authenticated via your identity provider (Google, Okta, Azure AD, GitHub, etc.) before reaching the backend. Successor to oauth_proxy.

4,770 stars · Apache-2.0

Upstream: https://github.com/pomerium/pomerium
Website: https://www.pomerium.com
Docs: https://www.pomerium.com/docs/
Docker Hub: https://hub.docker.com/r/pomerium/pomerium

## What it is

Pomerium provides zero-trust access to internal services:

- **Identity-aware proxy** — Every request verified against your IdP before forwarding
- **No VPN needed** — Users authenticate in browser; no client software required
- **Policy engine** — Allow/deny by email, domain, group, or custom claims
- **OIDC/OAuth2** — Supports Google Workspace, Okta, Azure AD, GitHub, GitLab, OneLogin, Auth0, and any OIDC provider
- **Context-aware** — Policies can check device posture, time of day, IP range
- **Signed headers** — Optionally append signed JWT assertion headers to upstream requests
- **Session management** — Cookie-based sessions with configurable TTL
- **All-in-one mode** — Single binary/container for small deployments
- **Split service mode** — Separate authenticate, authorize, databroker, proxy services for scale
- **Kubernetes ingress** — Optional Kubernetes ingress controller mode
- **Pomerium Zero** — Optional hosted control plane with management GUI

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Single container (all-in-one) | Simplest for small deployments |
| Docker Compose | pomerium + backends | Standard self-hosted setup |
| Kubernetes | Helm + ingress controller | Recommended for K8s |
| Bare metal | Go binary | Single binary, all-in-one mode |

## Inputs to collect

### Phase 1 — Pre-install
- Identity provider choice and credentials (client ID + secret)
- authenticate_service_url — public URL for authentication (e.g. https://auth.example.com)
- Domain for each service to be proxied
- TLS certificates or Let's Encrypt setup

### Phase 2 — Config file (config.yaml)
- shared_secret — 256-bit random key (head -c32 /dev/urandom | base64)
- cookie_secret — 256-bit random key
- idp_provider — google, okta, azure, github, gitlab, oidc, etc.
- idp_client_id / idp_client_secret
- Routes: from (public URL) → to (internal backend URL) + policy

## Software-layer concerns

### Config file (config.yaml)
Pomerium is configured via a single YAML file. Key structure:

  authenticate_service_url: https://auth.example.com

  shared_secret: <base64-random-32-bytes>
  cookie_secret: <base64-random-32-bytes>

  idp_provider: google
  idp_client_id: REPLACE_ME
  idp_client_secret: REPLACE_ME

  routes:
    - from: https://app.example.com
      to: http://internal-app:8080
      policy:
        - allow:
            or:
              - domain:
                  is: example.com
    - from: https://grafana.example.com
      to: http://grafana:3000
      policy:
        - allow:
            or:
              - email:
                  is: admin@example.com

### TLS
Pomerium can:
1. Terminate TLS itself (provide certificate_file / certificate_key_file)
2. Operate in insecure mode behind a TLS-terminating reverse proxy (insecure_server: true)

### Ports
- 443 (default HTTPS) or 8443
- 80 (HTTP redirect, optional)
- Can be changed via address config

## Docker Compose install

  version: '3'
  services:
    pomerium:
      image: pomerium/pomerium:latest
      container_name: pomerium
      restart: unless-stopped
      ports:
        - "443:443"
        - "80:80"
      volumes:
        - ./config.yaml:/pomerium/config.yaml:ro
        - ./cert.pem:/pomerium/cert.pem:ro
        - ./privkey.pem:/pomerium/privkey.pem:ro

    # Example protected backend
    myapp:
      image: nginx:alpine
      expose:
        - "80"

Mount your config.yaml and TLS cert/key into the container.

For insecure mode (behind Nginx/Traefik with TLS):
  Add insecure_server: true to config.yaml
  Remove cert volume mounts
  Let the upstream proxy handle TLS

## Upgrade procedure

1. Pull latest: docker pull pomerium/pomerium:latest
2. Review changelog at https://github.com/pomerium/pomerium/releases for config changes
3. Stop: docker compose stop pomerium
4. Start: docker compose up -d pomerium
5. Verify authentication flow works end-to-end

## Gotchas

- DNS wildcard — you need DNS entries (or wildcard *.example.com) for each proxied service pointing to Pomerium
- OAuth redirect URI — register your authenticate_service_url/oauth2/callback in your IdP
- shared_secret and cookie_secret — must be the same across all Pomerium services in split mode; store securely
- Cookie domain — by default sessions are scoped to the authenticate domain; ensure users can reach it
- HTTPS required — IdP OAuth callbacks require HTTPS; cannot use plain HTTP in production
- Route order — routes are matched in order; put more specific routes before wildcards
- JWT assertion headers — useful for upstream apps that want to trust identity without their own auth
- All-in-one limitations — for high availability, use split service mode with separate containers per service type
- Pomerium Zero — the hosted control plane is optional; full self-hosting is supported without it

## Links

- Upstream README: https://github.com/pomerium/pomerium/blob/main/README.md
- Documentation: https://www.pomerium.com/docs/
- Quickstart guide: https://www.pomerium.com/docs/get-started/quickstart
- Configuration reference: https://www.pomerium.com/docs/reference/
- IdP guides: https://www.pomerium.com/docs/identity-providers/

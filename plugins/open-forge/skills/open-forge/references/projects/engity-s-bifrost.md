# Engity's Bifröst

**Highly customizable advanced SSH server** — Go-based SSH server that extends OpenSSH with OpenID Connect / OAuth2 authentication, Docker container environments, Kubernetes pod environments, automatic user provisioning/cleanup, and a "remember me" feature for faster reconnects.

**Official site:** https://bifroest.engity.org
**Source:** https://github.com/engity-com/bifroest
**License:** Apache-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker | Recommended deployment path |
| Any Linux VPS / bare metal | Go binary | Build or download release binary |
| Kubernetes cluster | K8s manifest | Direct pod environment integration |

---

## Inputs to Collect

### Phase 1 — Planning
- Authentication method(s): SSH public key, OpenID Connect / OAuth2, or both
- Session environment: local shell, Docker container, or Kubernetes pod
- Whether to enable automatic user provisioning and cleanup

### Phase 2 — Deploy
- OIDC/OAuth2 provider credentials (client ID, secret, issuer URL) if using OIDC auth
- Docker socket access (if using Docker environments)
- Kubernetes kubeconfig (if using K8s environments)
- Bifröst YAML configuration file

---

## Software-Layer Concerns

- **Stack:** Go binary; minimal dependencies
- **Configuration:** Single YAML config file; see reference at https://bifroest.engity.org/reference/configuration/
- **Auth methods:**
  - Standard SSH public key (drop-in OpenSSH replacement)
  - OpenID Connect / OAuth2 — no special client needed beyond a standard SSH client
- **Session environments:**
  - Local: traditional shell session
  - Docker: each user gets an isolated container with custom image/network settings
  - Kubernetes: users land directly inside a dedicated Pod
- **Auto-provisioning:** Creates local users on demand based on OIDC claims; cleans up on session timeout (user, home dir, processes)
- **Remember me:** Temporarily stores public key from OIDC sessions for faster reconnect

---

## Deployment

Follow the getting started guide:
https://bifroest.engity.org/setup/

```bash
# Docker example
docker run -d \
  --name bifroest \
  -p 22:22 \
  -v ./bifroest.yaml:/etc/bifroest/bifroest.yaml:ro \
  ghcr.io/engity-com/bifroest:latest
```

Full configuration reference: https://bifroest.engity.org/reference/configuration/

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

For binary installs, download the latest release from GitHub releases.

---

## Gotchas

- **Not a drop-in for all OpenSSH use cases** — basic SSH key auth works as a drop-in, but advanced features require config changes
- **Docker socket required for Docker environments** — mount the Docker socket into the Bifröst container; understand the security implications
- **OIDC flow requires browser** — the initial OIDC auth opens a browser URL; subsequent reconnects use the cached public key ("remember me")
- **User cleanup on timeout** — auto-provisioned users and their home directories are deleted when sessions time out; ensure no persistent data is stored in auto-provisioned home dirs

---

## Links

- Upstream README: https://github.com/engity-com/bifroest#readme
- Getting started: https://bifroest.engity.org/setup/
- Configuration reference: https://bifroest.engity.org/reference/configuration/
- Use cases: https://bifroest.engity.org/usecases/

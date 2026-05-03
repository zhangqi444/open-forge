# Stackspin

**What it is:** Self-hosted suite of open-source apps (Nextcloud, Gitea, Wekan, etc.) deployed on Kubernetes with a single management interface.
**Official URL:** https://stackspin.net
**GitHub:** N/A (Greenhost: https://open.greenhost.net/stackspin/stackspin)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux server | Kubernetes (k3s) | Required — not Docker Compose |

## Inputs to Collect

### Deploy phase
- Domain/hostname
- Kubernetes cluster (k3s recommended for single-node)
- SMTP settings for notifications
- Admin email

## Software-Layer Concerns

- **Config:** Helm values files + single-app-dashboard configuration
- **Data dir:** Persistent volumes per app (Nextcloud, Gitea, etc.)
- **Key env vars:** Defined in Helm values

## Upgrade Procedure

Use the Stackspin dashboard or Helm upgrade commands. Back up persistent volumes before upgrading.

## Gotchas

- Requires Kubernetes — not suitable for simple Docker setups
- Multiple apps means more memory/CPU requirements
- Single sign-on (SSO) shared across all bundled apps

## References

- [Repo](https://open.greenhost.net/stackspin/stackspin)
- [Docs](https://stackspin.net/docs)

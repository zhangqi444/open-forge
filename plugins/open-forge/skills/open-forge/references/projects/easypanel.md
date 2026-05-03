# Easypanel

**What it is:** Modern server management panel for deploying apps, databases, and services using Docker — a simpler alternative to Coolify/Caprover.
**Official URL:** https://easypanel.io
**GitHub:** N/A (closed source)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VPS/server | Docker (auto-installed) | Easypanel installs Docker itself |

## Inputs to Collect

### Deploy phase
- Fresh Linux server (Ubuntu 20.04+ recommended)
- Root/sudo access

## Software-Layer Concerns

- **Config:** Managed via web UI
- **Data dir:** /etc/easypanel (managed internally)
- **Key env vars:** N/A — UI-driven configuration
- Installs and manages Docker automatically

## Upgrade Procedure

Use the built-in updater in the Easypanel web UI, or run the install script again.

## Gotchas

- Closed-source SaaS + self-hosted hybrid; some features require subscription
- Easypanel manages its own Docker; avoid manual Docker changes
- Best for single-server deployments

## References

- [Official Site](https://easypanel.io)
- [Docs](https://easypanel.io/docs)

# OpenTalk

**What it is:** Open-source video conferencing platform focused on privacy and GDPR compliance, designed for organizations.
**Official URL:** https://opentalk.eu
**GitHub:** https://gitlab.opencode.de/opentalk/ot-setup

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (server) | Docker Compose / Kubernetes | Multi-component stack |

## Inputs to Collect

### Deploy phase
- Domain/hostname
- OIDC/Keycloak configuration for authentication
- PostgreSQL credentials
- SMTP settings
- TURN/STUN server settings

## Software-Layer Concerns

- **Config:** Environment variables and YAML config files
- **Data dir:** PostgreSQL for metadata; object storage for recordings
- **Key env vars:** DATABASE_URL, KEYCLOAK_*, SMTP_*, TURN_*
- Requires Keycloak (or compatible OIDC) for authentication

## Upgrade Procedure

Follow upstream release notes. Back up database before upgrading.
See: https://gitlab.opencode.de/opentalk/ot-setup

## Gotchas

- Complex multi-service setup (controller, frontend, janus media server, keycloak)
- Designed for enterprise/organizational use
- Requires a TURN server for WebRTC NAT traversal

## References

- [Setup Repo](https://gitlab.opencode.de/opentalk/ot-setup)
- [Docs](https://opentalk.eu/en/docs)

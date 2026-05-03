# Installatron

**What it is:** Commercial web application auto-installer plugin for hosting control panels (cPanel, Plesk, DirectAdmin, etc.) — one-click install/update for 100s of web apps.
**Official URL:** https://installatron.com
**GitHub:** N/A (commercial/proprietary)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux hosting server | cPanel / Plesk / DirectAdmin | Runs as a plugin |

## Inputs to Collect

### Deploy phase
- Hosting control panel (cPanel, Plesk, etc.)
- License key
- Target domain/subdomain for each app install

## Software-Layer Concerns

- **Config:** Managed via hosting panel UI
- **Data dir:** Per-app; managed by the panel
- **Key env vars:** N/A

## Upgrade Procedure

Installatron auto-updates itself and can auto-update installed applications.

## Gotchas

- Commercial product — requires paid license
- Designed for shared/reseller hosting environments, not standalone Docker
- Not open source

## References

- [Official Site](https://installatron.com)
- [Docs](https://installatron.com/docs)

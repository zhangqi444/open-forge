# Virola

**What it is:** Self-hosted team messaging and video conferencing platform with channels, file sharing, and screen sharing.
**Official URL:** https://virola.io
**GitHub:** N/A (commercial/proprietary)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Windows Server | Native installer | Primary supported platform |
| Linux | Docker (unofficial) | Check virola.io for status |

## Inputs to Collect

### Deploy phase
- License key (free: up to 10 users)
- Domain/hostname
- Port (default: 7778)
- Admin credentials

## Software-Layer Concerns

- **Config:** Server admin console / web UI
- **Data dir:** Managed by server; see Virola docs
- **Key env vars:** N/A

## Upgrade Procedure

Download new installer from virola.io and run over existing install.

## Gotchas

- Primarily designed for Windows Server; Linux support may be limited
- Free tier limited to 10 users
- Proprietary protocol; requires Virola client apps

## References

- [Official Site](https://virola.io)
- [Docs](https://virola.io/documentation)

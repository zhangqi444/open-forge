# Open QuarterMaster

**Modular open-source inventory management system** — flexible, scalable inventory platform built around a Core API and Base Station frontend, extensible via plugins for specific use cases (POS, smart refrigerator integrations, workflow management, etc.). Runs on anything from Raspberry Pi to cloud VMs.

**Official site:** https://openquartermaster.com
**Source:** https://github.com/Epic-Breakfast-Productions/OpenQuarterMaster
**License:** GPL-3.0
**Demo:** https://openquartermaster.com/public/demo

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux (x86_64/ARM) | .deb packages (Station Captain) | Recommended single-host path |
| Any VPS / bare metal | Docker Compose | Container-based deployment |
| Raspberry Pi | .deb packages | Supported; runs on low-power hardware |

---

## Inputs to Collect

### Phase 1 — Planning
- Deployment target: single host (home/office) or multi-node
- Whether plugins are needed beyond core inventory
- Linux distribution (Debian/Ubuntu recommended for .deb path)

### Phase 2 — Deploy
- Admin account credentials
- Storage configuration for inventory data
- Plugin selection (optional, install via web UI after setup)

---

## Software-Layer Concerns

- **Core API:** Central hub for inventory management logic — what is stored where, item metadata
- **Base Station:** Web frontend for the Core API; primary user interface
- **Station Captain:** The installer/manager utility that handles component installation and updates; checks GitHub releases for updates
- **Plugin architecture:** Additional components extend the core; install/manage via the admin interface
- **Privacy:** No phone-home except Station Captain checking GitHub for updates; all inventory data stays local
- **Modular design:** Each component runs in its own container for isolation and flexibility

---

## Deployment

```bash
# Single-host deployment (recommended)
# See: https://github.com/Epic-Breakfast-Productions/OpenQuarterMaster/tree/main/deployment/Single%20Host
```

Follow the Single Host Deployment guide:
https://github.com/Epic-Breakfast-Productions/OpenQuarterMaster/tree/main/deployment/Single%20Host

For all deployment options:
https://github.com/Epic-Breakfast-Productions/OpenQuarterMaster/tree/main/deployment

---

## Upgrade Procedure

Station Captain handles updates automatically by checking GitHub releases. Trigger via the admin web UI or re-run the Station Captain installer.

---

## Gotchas

- **Station Captain phones home to GitHub** — only to check for updates to OQM components; no inventory data is transmitted
- **Active development** — 100+ commits per month; API and plugin interfaces may change between releases; pin versions in production
- **Plugin dependencies** — some plugins require additional infrastructure (e.g., barcode scanners, external integrations); review plugin docs before enabling
- **Raspberry Pi** — fully supported but heavier plugins may be slow on Pi 3/Zero; Pi 4/5 recommended for multi-plugin setups

---

## Links

- Upstream README: https://github.com/Epic-Breakfast-Productions/OpenQuarterMaster#readme
- Single host deployment: https://github.com/Epic-Breakfast-Productions/OpenQuarterMaster/tree/main/deployment/Single%20Host
- All deployment options: https://github.com/Epic-Breakfast-Productions/OpenQuarterMaster/tree/main/deployment
- Discord: https://discord.gg/cpcVh6SyNn
- Demo: https://openquartermaster.com/public/demo

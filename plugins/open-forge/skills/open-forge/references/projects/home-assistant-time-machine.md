# Home Assistant Time Machine

**Web-based backup and restore tool for Home Assistant — browse YAML snapshots of automations, scripts, Lovelace dashboards, ESPHome, and packages; restore individual items without a full backup restore.**
GitHub: https://github.com/saihgupr/HomeAssistantTimeMachine
Add-on repo: https://github.com/saihgupr/ha-addons

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Home Assistant OS / Supervised | HA Add-on | Recommended — native Ingress support, no port forwarding needed |
| Any Linux | Docker Compose | For non-HA-OS setups |
| Home Assistant | HACS Integration | Optional sensor + `time_machine.backup_now` service |

---

## Inputs to Collect

### Required (Docker only)
- Path to Home Assistant config directory
- Admin credentials

### Optional
- `ESPHOME_CONFIG_PATH` — custom location for ESPHome config files (Docker installs)

---

## Software-Layer Concerns

### Home Assistant Add-on (recommended)
1. Add the repository in HA: **Settings → Add-ons → Add-on Store → Repositories**
   ```
   https://github.com/saihgupr/ha-addons
   ```
2. Install **Home Assistant Time Machine** from the store
3. Start the add-on — accessible via HA Ingress (no port forwarding needed)

### Docker Compose
```bash
curl -o compose.yaml https://github.com/saihgupr/HomeAssistantTimeMachine/raw/branch/main/compose.yaml
# Edit compose.yaml — set HA config path and credentials
docker compose up -d
```

### Key features
- Browse YAML backups across automations, scripts, Lovelace, ESPHome, packages
- Side-by-side diff view with 8 color palettes
- Restore individual items (auto-creates safety backup before restoring)
- Reload automations/scripts directly from UI after restore
- Smart incremental backups (only changed files)
- Scheduled automatic backups
- Backup lock (prevent accidental deletion)
- Right-click context menu: lock, unlock, export (.tar.gz), delete
- Keyboard navigation (arrow keys + Enter)
- REST API for programmatic backup management
- Multi-language: English, Spanish, German, French, Dutch, Italian

### HACS integration (optional)
Adds a HA sensor for backup status and the `time_machine.backup_now` service call.

### Backup storage locations
`/share`, `/backup`, `/media`, or remote shares (configurable)

---

## Upgrade Procedure

- **Add-on**: update via HA Add-on Store
- **Docker**: docker compose pull && docker compose up -d

---

## Gotchas

- Split config setups (`!include`, `!include_dir_list`) are fully supported
- Always test a restore on a non-critical item first — a safety backup is auto-created before any restore
- Ingress is only available via the HA Add-on install; Docker installs require a port

---

## References
- GitHub: https://github.com/saihgupr/HomeAssistantTimeMachine#readme
- Add-on repository: https://github.com/saihgupr/ha-addons

# Unraid Config Guardian

**What it is:** A disaster recovery tool for Unraid servers. Automatically documents your entire Unraid configuration — Docker container templates, compose files, system settings, user shares, and plugins — so you can fully rebuild your server if the flash drive dies. Includes change tracking between backups.

**Official URL:** https://github.com/stephondoestech/unraid-config-guardian
**Docker Hub:** `stephondoestech/unraid-config-guardian`
**License:** MIT
**Stack:** Docker; runs as a sidecar on Unraid

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Unraid | Docker (Community Apps) | Primary deployment target |
| Unraid | Docker run / docker compose | Manual install via SSH |

> **Note:** This tool is purpose-built for Unraid. It reads Unraid-specific paths (`/mnt/user/appdata`, `/boot/config`, etc.) and will not provide meaningful output on non-Unraid hosts.

---

## Inputs to Collect

### Pre-deployment
- Backup output path — where generated docs/templates will be written (e.g. `/mnt/user/backups/unraid-docs`)
- `appdata` path — typically `/mnt/user/appdata`
- Schedule/trigger preference — run manually, on schedule, or watch for changes

### Runtime
- Review generated rebuild guide and container templates after first run
- Store backup output on a separate share from your appdata (different drive/parity)

---

## Software-Layer Concerns

**Emergency quick install (fresh Unraid after flash drive failure):**
```bash
mkdir -p /mnt/user/appdata/unraid-config-guardian
mkdir -p /mnt/user/backups/unraid-docs

docker run -d \
  --name unraid-config-guardian \
  -v /mnt/user/appdata/unraid-config-guardian:/config \
  -v /mnt/user/backups/unraid-docs:/output \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /boot/config:/unraid/config:ro \
  -v /mnt/user/appdata:/unraid/appdata:ro \
  stephondoestech/unraid-config-guardian:latest
```

**What gets backed up:**
- All running Docker containers → Docker templates + compose files
- System configuration → settings, shares, plugins
- Complete rebuild guide with step-by-step restoration instructions
- Change diff between backups (see what changed)

**Output:** Human-readable Markdown documentation + machine-readable templates in the output directory.

**Upgrade procedure:**
1. `docker pull stephondoestech/unraid-config-guardian:latest`
2. Restart container

---

## Gotchas

- **Unraid-only** — reads from `/boot/config` and Unraid-specific paths; not useful on non-Unraid hosts
- **Read-only mounts** — the container only reads your config; it does not modify any Unraid settings
- **Store backups off the primary array** — if your flash drive dies, your array may also be degraded; write output to a USB backup or off-site location
- **Docker socket access** — requires `/var/run/docker.sock` to enumerate running containers; treat this as a trusted container
- **Not a live backup tool** — documents configuration, not container data; your actual app data (databases, files) still needs separate backup via Unraid's built-in backup or another tool

---

## Links
- GitHub: https://github.com/stephondoestech/unraid-config-guardian
- Docker Hub: https://hub.docker.com/r/stephondoestech/unraid-config-guardian

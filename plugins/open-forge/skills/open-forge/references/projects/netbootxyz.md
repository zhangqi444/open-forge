# netboot.xyz

Network boot server that lets you PXE/iPXE boot various OS installers and utilities from a single place without needing physical media. Serves bootloaders over TFTP and hosts a web configuration interface for managing menus and mirroring assets locally.

**Official site:** https://netboot.xyz

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Home lab / LAN | Docker Compose | Recommended; requires existing DHCP server |
| Bare metal | Binary (standalone) | Run tftp-hpa + nginx manually |
| Raspberry Pi / ARM | Docker | ARM64 image available |
| Kubernetes | Not typical | TFTP/UDP via hostNetwork possible but non-standard |

---

## Inputs to Collect

### Phase 1 — Planning
- Existing DHCP server type (pfSense, OPNsense, dnsmasq, ISC DHCP, etc.)
- Network boot mode needed: Legacy BIOS, UEFI, or both
- Host static IP (required — DHCP "next-server" must be a static address)

### Phase 2 — Deployment
- Config directory path (bind-mount to `/config`)
- Optional local assets directory (`/assets` — for mirroring ISO/OS files locally)
- Web UI port (default `3000`), TFTP port (`69/udp`), asset server port (`8080`)

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  netbootxyz:
    image: ghcr.io/netbootxyz/netbootxyz
    container_name: netbootxyz
    environment:
      - MENU_VERSION=2.0.84  # optional; pin to specific menu version
      - NGINX_PORT=80         # optional; internal asset server port
      - WEB_APP_PORT=3000     # optional; internal web UI port
    volumes:
      - /path/to/config:/config    # optional; persist custom menus
      - /path/to/assets:/assets    # optional; mirror OS assets locally
    ports:
      - 3000:3000    # web configuration UI
      - 69:69/udp    # TFTP
      - 8080:80      # asset server (optional)
    restart: unless-stopped
```

### DHCP Server Configuration

Point your DHCP server at the netboot.xyz container for PXE booting:

**pfSense** — Services > DHCP Server > Network Booting:
- Next server: `<container-host-IP>`
- Default BIOS file: `netboot.xyz.kpxe`
- UEFI 32-bit file: `netboot.xyz.efi`

**dnsmasq** (`/etc/dnsmasq.conf`):
```
dhcp-boot=netboot.xyz.kpxe,,<container-host-IP>
# For UEFI:
# dhcp-boot=netboot.xyz.efi,,<container-host-IP>
```

**ISC DHCP** (`/etc/dhcp/dhcpd.conf`):
```
next-server <container-host-IP>;
filename "netboot.xyz.kpxe";
```

### Volumes
| Container path | Purpose |
|---------------|---------|
| `/config` | Custom boot menu files, web app config |
| `/assets` | Locally mirrored OS images/ISOs (served via nginx on port 8080) |

### Ports
| Port | Protocol | Purpose |
|------|----------|---------|
| `3000` | TCP | Web configuration UI |
| `69` | UDP | TFTP (bootloader delivery) |
| `8080` | TCP | Asset server (nginx for local ISO/file hosting) |

---

## Upgrade Procedure

```bash
docker compose pull netbootxyz
docker compose up -d netbootxyz
```

Configuration in `/config` and assets in `/assets` persist across upgrades. Menu version can be pinned via `MENU_VERSION` or left unset to pull latest.

---

## Gotchas

- **Requires an existing DHCP server** — netboot.xyz does not run one. You configure your router/DHCP to point PXE clients at the container's TFTP service.
- **Port 69/UDP must be accessible** — ensure no firewall blocks UDP 69 between DHCP clients and the container host.
- **Static host IP required** — DHCP `next-server` must resolve to a fixed address.
- **Legacy vs UEFI bootloaders** — use `netboot.xyz.kpxe` for BIOS clients, `netboot.xyz.efi` for UEFI. Some DHCP servers support conditional boot filename by client type.
- **Local asset mirroring** — without `/assets`, the container serves menus but OS downloads come from upstream CDNs (slower). Mirror ISOs locally for faster installs.
- **Port 69 conflict** — if another TFTP server (e.g., a NAS) is already on port 69, remap: `- 6969:69/udp` and update DHCP accordingly.
- LSIO's `linuxserver/docker-netbootxyz` image is deprecated; use the official `ghcr.io/netbootxyz/netbootxyz` image.

---

## References
- GitHub (Docker): https://github.com/netbootxyz/docker-netbootxyz
- GitHub (menus/source): https://github.com/netbootxyz/netboot.xyz
- Official docs: https://netboot.xyz/docs/
- docker-compose.yml.example: https://github.com/netbootxyz/docker-netbootxyz/blob/master/docker-compose.yml.example

# Roon

**What it is:** A premium music listening and library management platform. Connects to local music files, streaming services (Tidal, Qobuz), and network audio devices (Roon Ready devices, AirPlay, Chromecast). Features rich metadata, artist biographies, concert photos, DSP/EQ, multi-room audio, and a polished tablet/desktop interface. Roon Core runs as a server on your hardware.

> ⚠️ **Closed source / subscription required.** Roon Core is proprietary software and requires an active subscription to function.

**Official URL:** https://roon.app/en/core
**License:** Proprietary; subscription-based ($9.99/month or $699 lifetime at time of writing)
**Stack:** Proprietary; Linux/Windows/macOS; Docker available via community images

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VPS / NAS / bare metal | Native install | Official `.sh` installer; systemd service |
| NAS (Synology, QNAP, etc.) | Roon Ready app / native package | Vendor-specific packages available |
| Linux VPS | Docker (community) | No official Docker image; community images exist |

---

## Inputs to Collect

### Pre-deployment
- Roon account and active subscription — required; Core won't function without it
- Music library path — local directory or NAS share to scan
- Sufficient hardware — Roon recommends Intel NUC or equivalent; DSP features are CPU-intensive

---

## Software-Layer Concerns

**Native Linux install:**
```bash
curl -O https://download.roon.app/build/installers/RoonServer_installer_linuxx64.sh
chmod +x RoonServer_installer_linuxx64.sh
./RoonServer_installer_linuxx64.sh
```
Roon Server installs as a systemd service. The Roon Remote app (iOS, Android, macOS, Windows) connects to it for control.

**Web UI:** Roon does not have a traditional web interface — use the Roon Remote app on a phone, tablet, or desktop to control the Core.

**Docker (community):** Official Docker images are not provided. Community images exist but are unsupported. Check https://hub.docker.com for current options.

**Upgrade procedure:** Roon Core auto-updates itself when a new version is available (if auto-update is enabled in settings).

---

## Gotchas

- **Subscription required** — Roon Core checks license validity online; no offline operation without an active subscription
- **No official Docker image** — use the native installer; community Docker images are unsupported and may lag behind versions
- **High hardware requirements for DSP** — basic playback is lightweight; heavy DSP/upsampling needs a fast CPU (Intel NUC 8th gen+ recommended)
- **No web browser control** — requires Roon Remote app (iOS/Android/macOS/Windows); no web UI
- **Closed ecosystem** — "Roon Ready" certification is required for best integration with DACs/endpoints

---

## Links
- Roon Core: https://roon.app/en/core
- Downloads: https://download.roon.app

# FMD Server

**Find My Device server** — self-hosted backend for the FMD (Find My Device) Android app. Allows the app to upload its GPS location at regular intervals, and lets you push remote commands (ring, locate, wipe, etc.) to your Android device from a web UI.

**Official site / docs:** https://fmd-foss.org  
**Source:** https://gitlab.com/fmd-foss/fmd-server  
**Android app:** https://gitlab.com/fmd-foss/fmd-android  
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker | Primary recommended path |
| Linux | Go binary | Build from source |

---

## Inputs to Collect

| Input | Description | Default |
|-------|-------------|---------|
| `HTTP_PORT` | External port | `8080` |
| Public URL | Used to configure the FMD Android app | — |

---

## Software-layer Concerns

### Docker (quick test)
```bash
docker run --rm -p 8080:8080 registry.gitlab.com/fmd-foss/fmd-server:0.14.2
```
Visit `http://localhost:8080` — then register your FMD app using `http://<your-ip>:8080`.

> ⚠️ The above is for local testing only. For production, see the install guide.

### Docker Compose (production)
```yaml
services:
  fmd:
    image: registry.gitlab.com/fmd-foss/fmd-server:v0.14.2
    ports:
      - '8080:8080'
    volumes:
      - fmd_data:/data
    restart: unless-stopped

volumes:
  fmd_data:
```

See the [official installation guide](https://fmd-foss.org/docs/fmd-server/installation/overview) for full production config including TLS, persistent storage, and reverse proxy setup.

### Build from source (Docker Compose)
```yaml
services:
  fmd:
    build: https://gitlab.com/fmd-foss/fmd-server.git#master
    ports:
      - '8080:8080'
```
```bash
docker compose build && docker compose up
```

### Android app setup
1. Install FMD from [F-Droid](https://f-droid.org) or the GitLab releases
2. In the app, set server URL to `https://your-domain.com` (or `http://<ip>:8080` for LAN)
3. Register an account on the server
4. The app will begin uploading location data on the configured interval

### Remote commands available
- Locate (request GPS location)
- Ring (make device sound alarm)
- Lock screen
- Wipe device (remote factory reset)
- See full list at https://fmd-foss.org/docs

---

## Upgrade Procedure

```bash
# Update image tag in docker-compose.yml to new version, then:
docker compose pull
docker compose up -d
```
Check the [changelog](https://gitlab.com/fmd-foss/fmd-server/-/releases) for migration notes.

---

## Gotchas

- **Requires HTTPS for production.** The Android app requires a valid TLS certificate when connecting over the internet. Use a reverse proxy (nginx + Let's Encrypt / Caddy).
- **The Docker run example is for testing only** — it uses `--rm` (no persistence) and HTTP.
- **Android battery optimization.** For reliable location updates, exempt the FMD app from battery optimization on your device.
- **Location accuracy depends on device settings.** GPS accuracy varies; FMD uses whatever the Android location API provides.
- **Community projects** (clients, integrations) listed at https://fmd-foss.org/docs/fmd-server/community.
- **Funded by NLnet / NGI Mobifree.**

---

## References

- Installation guide: https://fmd-foss.org/docs/fmd-server/installation/overview
- Upstream README: https://gitlab.com/fmd-foss/fmd-server/-/blob/master/README.md
- FMD Android: https://gitlab.com/fmd-foss/fmd-android

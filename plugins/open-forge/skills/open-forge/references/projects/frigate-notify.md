# Frigate-Notify

Frigate-Notify is a notification bridge for Frigate NVR that sends event alerts to your preferred platforms — no Home Assistant required. Connects to Frigate via MQTT (recommended) or direct API polling, and supports a wide range of notification targets: Discord, Telegram, Ntfy, Gotify, Pushover, Signal, Matrix, Mattermost, SMTP, Webhook, and more via Apprise API.

- **Official site / docs:** https://frigate-notify.0x2142.com
- **GitHub:** https://github.com/0x2142/frigate-notify
- **Docker image:** `ghcr.io/0x2142/frigate-notify:latest`
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Single container; config file mounted |
| Any Docker host | docker run | Same; config file bind-mounted |

---

## Inputs to Collect

### Deploy Phase
| Setting | Required | Description |
|---------|----------|-------------|
| Frigate server URL | **Yes** | Base URL of your Frigate instance (e.g. `http://frigate:5000`) |
| MQTT or Web API | **Yes** | Choose one event collection method |
| MQTT host/port/credentials | If MQTT | MQTT broker details |
| Notification target config | **Yes** | At least one notification destination |
| `TZ` env var | Recommended | Timezone for timestamp display |

All configuration is done in `config.yml` (not environment variables).

---

## Software-Layer Concerns

### Config
- Single YAML config file: `config.yml` (copy from `example-config.yml`)
- Mounted into container at `/app/config.yml`
- Covers: Frigate connection, event collection method (MQTT vs Web API), notification targets, filters, quiet hours, etc.

### Data Directories
- No persistent data volume required — stateless notification bridge
- Config file must be persisted on host and mounted

### Ports
- No ports required by default
- Optional REST API on port `8000` (enable in config under `app.api.enabled`)

### Key Config Sections
```yaml
app:
  mode: events        # or "reviews"
  
frigate:
  server: http://frigate:5000
  webapi:             # OR use mqtt below
    enabled: true
    interval: 30
  mqtt:
    enabled: true
    server: mqtt-broker
    port: 1883
    username: user
    password: pass

# Add one or more notification targets:
alerts:
  discord:
    webhook: https://discord.com/api/webhooks/...
  telegram:
    token: your_bot_token
    chatid: "123456789"
  ntfy:
    server: https://ntfy.sh
    topic: frigate-events
  gotify:
    server: http://gotify:80
    token: your_token
```

---

## Minimal docker-compose.yml

```yaml
services:
  frigate-notify:
    image: ghcr.io/0x2142/frigate-notify:latest
    container_name: frigate-notify
    environment:
      - TZ=America/New_York
    volumes:
      - ./config.yml:/app/config.yml
    restart: unless-stopped
    # Uncomment if REST API is enabled in config:
    # ports:
    #   - "8000:8000"
```

Setup:
```bash
curl -O https://raw.githubusercontent.com/0x2142/frigate-notify/main/example-config.yml
mv example-config.yml config.yml
# Edit config.yml with your Frigate URL and notification targets
docker compose up -d
```

---

## Upgrade Procedure

```bash
docker compose pull frigate-notify
docker compose up -d frigate-notify
```

Config persists on the host; no data migration needed.

---

## Gotchas

- **MQTT vs Web API:** MQTT is the recommended and more reliable collection method; Web API polling introduces a delay equal to the interval setting
- **Only one collection method at a time:** Enable either `mqtt` or `webapi` — not both
- **Frigate authentication:** If Frigate has auth enabled, set `username` and `password` in the `frigate` config block, or use `headers` for custom auth headers
- **Event vs Reviews mode:** `mode: events` delivers per-object detections; `mode: reviews` groups events into Frigate's review summaries — check your Frigate version for review support
- **Quiet hours:** Config supports quiet hour windows per notification target to suppress overnight alerts
- **Aliveness monitoring:** Frigate-Notify exposes an HTTP endpoint for uptime checkers (Healthchecks.io, Uptime Kuma) — enable in config under `app.alertmanager`
- **Config changes:** Restart the container after any config file changes — changes are not hot-reloaded

---

## References
- Documentation: https://frigate-notify.0x2142.com/latest/
- Install guide: https://frigate-notify.0x2142.com/latest/install/
- Config reference: https://frigate-notify.0x2142.com/latest/config/
- GitHub: https://github.com/0x2142/frigate-notify
- example-config.yml: https://raw.githubusercontent.com/0x2142/frigate-notify/main/example-config.yml

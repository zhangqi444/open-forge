# MQTTUI

**What it is:** A self-hosted web interface for MQTT infrastructure. Monitor real-time message streams, visualize topic hierarchies, create automation rules (IF/THEN engine), send Telegram/Slack/webhook alerts, track per-topic analytics, and extend with plugins — all from a browser UI.

**Official URL:** https://github.com/terdia/mqttui
**Docker Hub:** `terdia07/mqttui`
**License:** MIT
**Stack:** Python (Flask + Socket.IO) + SQLite; multi-arch (amd64/arm64/armv7)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; includes Mosquitto broker |
| Any Linux VPS / bare metal | Docker run | Connect to existing broker |
| Homelab (Pi) | Docker Compose | armv7/arm64 supported |
| Any Linux | Manual (pip) | Python virtualenv install |

---

## Inputs to Collect

### Pre-deployment
- `MQTTUI_ADMIN_USER` / `MQTTUI_ADMIN_PASSWORD` — admin login credentials
- `SECRET_KEY` — random string for session signing (`openssl rand -hex 32`)
- `MQTT_BROKER` — hostname/IP of your MQTT broker (default: `localhost`; use `mosquitto` in Docker Compose)
- `MQTT_PORT` — default `1883`
- `MQTT_USERNAME` / `MQTT_PASSWORD` — broker credentials if auth is enabled
- Telegram bot token + chat ID (optional, for alert notifications)
- Slack webhook URL (optional)

### Runtime
- Automation rules configured in the web UI (no restart needed; hot-reload)
- API tokens generated per-user for programmatic access

---

## Software-Layer Concerns

**Docker Compose (includes Mosquitto broker):**
```bash
git clone https://github.com/terdia/mqttui.git
cd mqttui
docker compose up -d
```
Opens `http://localhost:8088`. Log in with configured admin credentials.

**Docker run (connect to existing broker):**
```bash
docker run -p 8088:5000 \
  -e MQTT_BROKER=your_broker \
  -e MQTTUI_ADMIN_USER=admin \
  -e MQTTUI_ADMIN_PASSWORD=changeme \
  -e SECRET_KEY=your-secret-key \
  terdia07/mqttui:v2.0
```

**Default port:** `8088` (maps to internal `5000`)

**Data persistence:** SQLite database for message history, rules, alerts. Mount a volume if you need persistence across container restarts.

**REST API:** Available at `/api/v1/` with OpenAPI docs at `/api/v1/docs`.

**Prometheus metrics:** `/metrics` endpoint for Grafana/Prometheus integration.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **Multi-broker support added in v2.1** — if running older version, only one broker per instance
- **Loop detection built-in:** Automation rules that publish back to trigger topics are guarded by `__source` marker + rate limiting + circuit breaker — but test rules with dry-run first
- **SSRF protection** in webhook alerts — private/reserved IP addresses are blocked from outbound webhook calls
- **Alert deduplication** has a 5-minute cooldown by default — adjust if you need more frequent alerting
- **Plugin subprocess isolation** — plugins can't access app internals, but they run as child processes; review plugin code before installing
- High-throughput deployments (1000+ msg/sec) use server-side batching via Socket.IO — may introduce slight display lag

---

## Links
- GitHub: https://github.com/terdia/mqttui
- Docker Hub: https://hub.docker.com/r/terdia07/mqttui
- OpenAPI docs: `http://localhost:8088/api/v1/docs` (when running)

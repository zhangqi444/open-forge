# WhoRang

**What it is:** A Home Assistant add-on that captures doorbell ring events — storing the image, timestamp, weather snapshot, and an optional AI description — and displays everything in a clean local web UI. All processing is local, no cloud required.

**Official URL:** https://github.com/Beast12/whorang
**License:** MIT
**Stack:** Python + SQLite; Home Assistant add-on (amd64/aarch64)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Home Assistant (Supervised/OS) | HA Add-on | Recommended; installs via HA add-on store |
| Any Docker host | Docker standalone | `docker build` from source (see TESTING.md) |

---

## Inputs to Collect

### Pre-deployment
- Camera source: either a **Home Assistant camera entity ID** (e.g. `camera.front_door`) or a direct **RTSP/HTTP URL**
- HA long-lived access token — only needed if running outside HA Supervisor
- Notification webhook URL (optional) — Gotify or generic webhook

### Runtime
- `storage_path` — where images and SQLite DB are stored (default: `/share/doorbell`)
- `retention_days` — auto-delete events older than N days (1–365, default: 30)
- Face recognition model — `buffalo_sc` (fast), `buffalo_s`, or `buffalo_l` (accurate)

---

## Software-Layer Concerns

**Installation via HA:**
1. Settings → Add-ons → Add-on Store → ⋮ → Repositories → add `https://github.com/Beast12/whorang`
2. Install **WhoRang Doorbell**, configure, start

**Config:** Set in the add-on Configuration tab or via the in-app Settings page (no restart needed for settings changes).

**Ring trigger endpoint:**
```
POST http://<addon-hostname>:8099/api/doorbell/ring
```
Call this from HA automations when your doorbell triggers.

**HA sensors exposed:** 3 sensors updated on each ring — usable in automations/dashboards.

**Face recognition:** Disabled by default; enabling it downloads ~InsightFace model at startup.

**Data path:** `/share/doorbell` (HA shared storage) — survives add-on updates.

**Upgrade procedure:** Update via HA Add-on Store → check for updates → Update button.

---

## Gotchas

- **HA add-on only** for normal usage — standalone Docker requires building from source
- **Camera required** — either HA entity or direct URL; without one, only timestamps are stored
- **Face recognition is resource-intensive** — avoid on low-powered devices like Pi 3
- **AI descriptions** are populated externally (e.g. via [LLM Vision](https://github.com/valentinfrlch/ha-llmvision)) — WhoRang stores the text but doesn't call AI itself
- `buffalo_l` model is most accurate but slowest; `buffalo_sc` recommended for RPi/NUC

---

## Links
- GitHub: https://github.com/Beast12/whorang
- Full config reference: https://github.com/Beast12/whorang/blob/main/doorbell-addon/DOCS.md
- Automation examples: https://github.com/Beast12/whorang/blob/main/doorbell-addon/AUTOMATION.md

# MedAssist

**What it is:** A self-hosted medication management and reminder app. Track medication inventory, receive email reminders when supplies run low, generate travel packing lists for medications, and monitor daily dosing schedules from a simple web dashboard. Built as a personal project by a hobbyist developer.

**Official URL:** https://github.com/njic/medassist
**Container:** `ghcr.io/njic/medassist:latest`
**Demo:** https://volimandr.eu
**License:** MIT
**Stack:** Node.js + SQLite

> ⚠️ **Disclaimer:** This is a hobby project, not medical software. Do not rely on it for critical medication management. Always follow your doctor's instructions independently of any app.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Any Linux VPS / bare metal | Docker run | Single container |
| Any Linux | Node.js (manual) | Download source, run `node app.js` |

---

## Inputs to Collect

### Pre-deployment
- `TZ` — timezone (e.g. `Europe/London`) for correct reminder scheduling
- Database directory — host path to persist SQLite database (e.g. `/path/to/database`)
- SMTP credentials — configured in the web UI after first launch for email reminders

### Runtime
- Medication names, dosage schedules, and current inventory counts — entered via web UI
- Email address for low-stock reminders
- Travel dates for packing list generation

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  medassist:
    container_name: medassist
    image: ghcr.io/njic/medassist:latest
    restart: always
    environment:
      - TZ=Etc/UTC
    ports:
      - 3111:3111
    volumes:
      - /path/to/database/directory:/app/database
```

**Docker run:**
```bash
docker run -p 3111:3111 \
  -v /path/to/database:/app/database \
  --restart always \
  -e TZ=Etc/UTC \
  ghcr.io/njic/medassist:latest
```

**Default port:** `3111`

**Data persistence:** SQLite database stored in `/app/database` inside the container. Mount a host directory to persist data across container restarts.

**Email reminders:** SMTP configuration is set through the web UI settings panel after first launch — no environment variables needed for SMTP.

**Travel list:** Generate a medication list for any date range from the web UI; optionally send directly to email.

**Node.js manual install:**
1. Download and extract source
2. Ensure `public/` folder and `app.js` are present
3. `node app.js`

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **Hobby project** — no guaranteed uptime, security audits, or professional support; review the code if deploying on a shared server
- **No built-in authentication** — the web UI has no login; deploy behind a reverse proxy with authentication (Basic Auth, Authelia, etc.) if not on a private network
- **Timezone critical** — set `TZ` correctly or reminders will fire at the wrong local time
- **SQLite only** — no support for external databases; fine for personal/family use, not for multi-user deployments
- **Email is optional** — the app works without SMTP; reminders just won't be sent

---

## Links
- GitHub: https://github.com/njic/medassist
- Demo: https://volimandr.eu
- Container: ghcr.io/njic/medassist:latest

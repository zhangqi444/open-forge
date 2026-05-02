# SharedMoments

**What it is:** A private self-hosted web app for couples, families, or friend groups to capture and relive their special moments together. Upload photos and videos, track milestones, set countdowns, display relationship/group duration, create custom lists (bucket list, movie list), and get reminders for anniversaries and special dates. Supports push, email, and Telegram notifications and an optional AI writing assistant.

**Official URL:** https://github.com/tech-kev/SharedMoments
**Docker Hub:** `techkev/sharedmoments`
**Demo:** https://sharedmoments.onrender.com/
**License:** AGPL-3.0
**Stack:** Python (Django) + SQLite

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Homelab / Raspberry Pi | Docker | Lightweight; SQLite, single container |

---

## Inputs to Collect

### Pre-deployment (required)
- `SECRET_KEY` — Django crypto secret; generate with: `python -c "import secrets; print(secrets.token_hex(32))"`

### Optional integrations
- **AI writing assistant** (pick one):
  - OpenAI: `OPENAI_API_KEY` + `OPENAI_MODEL` (e.g. `gpt-4o-mini`)
  - Anthropic: `ANTHROPIC_API_KEY` + `ANTHROPIC_MODEL` (e.g. `claude-haiku-4-5`)
  - Ollama (local): `OLLAMA_BASE_URL` (e.g. `http://host.docker.internal:11434`) + `OLLAMA_MODEL`
  - Custom prompt: `AI_SYSTEM_PROMPT`
- **Email notifications (SMTP):** `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`
- **Telegram notifications:** `TELEGRAM_BOT_TOKEN`

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  sharedmoments:
    image: techkev/sharedmoments
    container_name: sharedmoments
    restart: unless-stopped
    ports:
      - "5001:5001"
    volumes:
      - sm-database:/app/app/database
      - sm-uploads:/app/app/uploads
      - /etc/localtime:/etc/localtime:ro
    environment:
      - SECRET_KEY=CHANGE-ME-generate-with-python-secrets-token_hex-32
      # Optional AI (choose one):
      # - OPENAI_API_KEY=
      # - OPENAI_MODEL=gpt-4o-mini
      # - ANTHROPIC_API_KEY=
      # - ANTHROPIC_MODEL=claude-haiku-4-5
      # - OLLAMA_BASE_URL=http://host.docker.internal:11434
      # - OLLAMA_MODEL=llama3.2
      # Optional SMTP:
      # - SMTP_HOST=
      # - SMTP_PORT=587
      # - SMTP_USER=
      # - SMTP_PASS=
      # - SMTP_FROM=
      # Optional Telegram:
      # - TELEGRAM_BOT_TOKEN=

volumes:
  sm-database:
  sm-uploads:
```

**Default port:** `5001`

**Editions (selectable on setup, switchable anytime):**
- **Couples** — relationship status, anniversary, engagement & wedding dates
- **Family** — family name, founding date
- **Friends** — group name, founding date

**Reminder system:**
- Annual: birthdays, anniversaries (auto-synced from your data)
- One-time: custom reminders for specific dates
- Milestones: automatic at 100, 365, 1000 days, up to 30 years
- Countdowns: notified when a countdown reaches zero
- Per-user: mute individual reminders; set advance notice days

**Push notifications:** Work automatically in-browser and on mobile — no extra configuration needed.

**Password reset:** Via email link on the login page (requires SMTP), or via CLI: `python manage.py set-password <email>`

**v1 → v2 migration:** See the wiki for details. Uses temporary extra volumes and env vars; remove them after migration completes.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **AGPL-3.0** — modifications must be open-sourced if deployed publicly
- **`SECRET_KEY` is required** — app will not start without it; changing it invalidates all existing sessions
- **`/etc/localtime` mount** — recommended for correct reminder timing; without it, reminders may fire at wrong local times
- **AI is optional** — app works fully without any AI provider; AI features only appear if a provider is configured
- **Passkey support** — users can log in with a hardware security key or biometrics; works alongside email/password

---

## Links
- GitHub: https://github.com/tech-kev/SharedMoments
- Demo: https://sharedmoments.onrender.com/
- Wiki (migration guide): https://github.com/tech-kev/SharedMoments/wiki

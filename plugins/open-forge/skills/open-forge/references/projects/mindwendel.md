# Mindwendel

**Team brainstorming and idea voting tool** — create a challenge, invite people anonymously (no registration needed), brainstorm ideas collaboratively with live updates, and upvote the best ones. Built with Elixir/Phoenix LiveView.

**Official site / demo:** https://www.mindwendel.com  
**Source:** https://github.com/b310-digital/mindwendel  
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker Compose | Primary recommended path |
| Any | Elixir/Phoenix (native) | For development or custom builds |

---

## System Requirements

- Docker + Docker Compose
- PostgreSQL
- S3-compatible storage (for file attachments; optional)

---

## Inputs to Collect

### Required
| Variable | Description |
|----------|-------------|
| `DATABASE_HOST` | PostgreSQL hostname |
| `DATABASE_NAME` | Database name |
| `DATABASE_USER` | DB username |
| `DATABASE_USER_PASSWORD` | DB password |
| `SECRET_KEY_BASE` | Phoenix secret key (generate with `date +%s \| sha256sum \| base64 \| head -c 64`) |
| `URL_HOST` | Public hostname |

### Optional
| Variable | Description | Default |
|----------|-------------|---------|
| `URL_PORT` | External HTTPS port | `443` |
| `URL_SCHEME` | `https` or `http` | `https` |
| `MW_DEFAULT_LOCALE` | Interface language (`en` or `de`) | `en` |
| `MW_FEATURE_BRAINSTORMING_REMOVAL_AFTER_DAYS` | Auto-delete brainstormings after N days | `30` |
| `MW_FEATURE_IDEA_FILE_UPLOAD` | Enable file attachments | `true` |
| `OBJECT_STORAGE_*` | S3/MinIO config for file uploads | — |
| `VAULT_ENCRYPTION_KEY_BASE64` | Encryption key for stored files | — |

---

## Software-layer Concerns

### Docker Compose (production)
```bash
git clone https://github.com/b310-digital/mindwendel
cd mindwendel
cp .env.prod.example .env.prod
# Edit .env.prod with your database and secret key settings
docker compose -f docker-compose-prod.yml --env-file .env.prod up -d --build
```

### Minimal `.env.prod`
```env
DOCKER_COMPOSE_APP_PROD_DATABASE_HOST=postgres_prod
DOCKER_COMPOSE_APP_PROD_DATABASE_NAME=mindwendel_prod
DOCKER_COMPOSE_APP_PROD_DATABASE_USER=mindwendel
DOCKER_COMPOSE_APP_PROD_DATABASE_USER_PASSWORD=strong-password
DOCKER_COMPOSE_APP_PROD_SECRET_KEY_BASE=<64-char-random-string>
DOCKER_COMPOSE_APP_PROD_URL_HOST=your-domain.com
DOCKER_COMPOSE_APP_PROD_DATABASE_SSL=true
```

### Features
- 5-minute setup
- Anonymous participation — no registration required; usernames optional
- Real-time idea updates via Phoenix LiveView (WebSockets)
- Upvoting ideas
- Custom labels for clustering and filtering ideas
- Link previews
- Encrypted file attachments (S3/MinIO)
- Drag-and-drop lanes and idea ordering
- Comments on ideas
- AI-powered idea generation (OpenAI-compatible LLM)
- Export to HTML or CSV
- German and English interface
- Auto-delete brainstormings after 30 days (GDPR-compliant default)

---

## Upgrade Procedure

```bash
docker compose -f docker-compose-prod.yml --env-file .env.prod pull
docker compose -f docker-compose-prod.yml --env-file .env.prod up -d --build --force-recreate
```

---

## Gotchas

- **`SECRET_KEY_BASE` must be set** — Phoenix will refuse to start without it. Generate with: `date +%s | sha256sum | base64 | head -c 64`
- **`DATABASE_SSL=true` for non-local setups** — enforced by default in the prod compose file.
- **File attachments require S3/MinIO config** — if `MW_FEATURE_IDEA_FILE_UPLOAD=true` (the default), you must configure `OBJECT_STORAGE_*` variables and `VAULT_ENCRYPTION_KEY_BASE64`.
- **Auto-delete default is 30 days.** Change `MW_FEATURE_BRAINSTORMING_REMOVAL_AFTER_DAYS` or set to `0` to disable.
- **AI features** require an OpenAI-compatible API key configured separately.

---

## References

- Install guide: https://github.com/b310-digital/mindwendel/blob/main/docs/installing_mindwendel.md
- Upstream README: https://github.com/b310-digital/mindwendel#readme
- Demo: https://www.mindwendel.com

# Maybe Finance

Personal finance and wealth management app. Track net worth, investments, budgets, transactions, and financial goals in one self-hosted dashboard. Upstream: <https://github.com/maybe-finance/maybe>. Docs: <https://github.com/maybe-finance/maybe/tree/main/docs>.

> ⚠️ **Maintenance status:** The `maybe-finance/maybe` repository is **no longer actively maintained** as of the v0.6.0 final release. Docker images at `ghcr.io/maybe-finance/maybe` still exist and the app works, but no further upstream development is planned. Consider this when evaluating for production use.

Maybe is a Ruby on Rails app listening on port `3000`. It requires PostgreSQL and Redis. The official self-hosting method is Docker Compose with the provided `compose.example.yml`.

## Compatible install methods

Verified against upstream docs at <https://github.com/maybe-finance/maybe/blob/main/docs/hosting/docker.md>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (official) | <https://github.com/maybe-finance/maybe/blob/main/docs/hosting/docker.md> | ✅ | Recommended method. Uses `ghcr.io/maybe-finance/maybe:latest`. |
| Local dev (bare metal) | <https://github.com/maybe-finance/maybe#local-development-setup> | ✅ | Development only. Requires Ruby (see `.ruby-version`) + PostgreSQL. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| secrets | "SECRET_KEY_BASE?" | Free-text (generate with `openssl rand -hex 64`) | All |
| db | "PostgreSQL password?" | Free-text (sensitive) | Docker Compose |
| domain | "Domain or IP to access Maybe?" | Free-text | Production/reverse-proxy |
| optional | "OpenAI API key (for AI features)?" | Free-text (sensitive) — leave blank to disable | Optional |

## Software-layer concerns

### Environment variables (`.env` file)

| Variable | Purpose | Notes |
|---|---|---|
| `SECRET_KEY_BASE` | Rails session encryption key | **Required.** Generate with `openssl rand -hex 64`. |
| `POSTGRES_PASSWORD` | PostgreSQL password | Defaults to `maybe_password` — change in production. |
| `POSTGRES_USER` | PostgreSQL username | Defaults to `maybe_user`. |
| `POSTGRES_DB` | Database name | Defaults to `maybe_production`. |
| `OPENAI_ACCESS_TOKEN` | OpenAI API key | Optional. Enables AI chat/rules features. Will incur costs. |
| `SELF_HOSTED` | Marks as self-hosted instance | Set to `"true"` (included in compose file). |
| `RAILS_FORCE_SSL` | Force HTTPS | Set to `"true"` if terminating TLS at the app level. |

Generate SECRET_KEY_BASE:
```bash
openssl rand -hex 64
```

### Docker Compose setup

```bash
mkdir -p ~/maybe && cd ~/maybe

# Download the official compose file
curl -o compose.yml https://raw.githubusercontent.com/maybe-finance/maybe/main/compose.example.yml

# Create .env file
cat > .env << EOF
SECRET_KEY_BASE=$(openssl rand -hex 64)
POSTGRES_PASSWORD=changemestrong
EOF

# Start
docker compose up -d
```

Access at `http://localhost:3000`. Create your account on first login — there is no default admin.

### Services in docker-compose

| Service | Image | Port | Role |
|---|---|---|---|
| `web` | `ghcr.io/maybe-finance/maybe:latest` | 3000 | Main Rails app |
| `db` | `postgres:16` | 5432 | Metadata database |
| `redis` | `redis:latest` | 6379 | Cache + Action Cable |

### Data directories (Docker volumes)

| Volume | Contents |
|---|---|
| `app-storage` | ActiveStorage uploads (attachments, imports) |
| `postgres-data` | PostgreSQL database data |
| `redis-data` | Redis persistence |

## Upgrade procedure

1. Pull the latest image: `docker compose pull`
2. Restart the stack: `docker compose up -d`
3. Rails DB migrations run automatically on container start via `db:migrate`.
4. Verify the app loads and data is intact.

Note: Since the project is no longer maintained, there will be no new upstream releases after v0.6.0.

## Gotchas

- **No longer maintained.** v0.6.0 is the final release. The Docker image still works but won't receive security fixes or new features.
- **SECRET_KEY_BASE must be set.** The default in `compose.example.yml` is a placeholder — it works but everyone running the default has the same key. Generate your own.
- **First-run account creation.** There is no pre-seeded admin. Navigate to the app and create your account through the registration flow.
- **OpenAI features cost money.** If you set `OPENAI_ACCESS_TOKEN`, AI chat and rules features will call the OpenAI API and incur charges. Set spend limits on your OpenAI account before enabling.
- **"Maybe" is a trademark.** If you fork and redistribute, you cannot use the "Maybe" name or logo per the upstream license notes.
- **Redis is required.** Action Cable (real-time features) requires Redis. Do not remove it from the compose file.

## Links

- Upstream: <https://github.com/maybe-finance/maybe>
- Self-hosting guide: <https://github.com/maybe-finance/maybe/blob/main/docs/hosting/docker.md>
- Compose example: <https://raw.githubusercontent.com/maybe-finance/maybe/main/compose.example.yml>
- Final release notes: <https://github.com/maybe-finance/maybe/releases/tag/v0.6.0>

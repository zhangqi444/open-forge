---
name: claper-project
description: Claper recipe for open-forge. Open-source interactive presentation platform built on Phoenix/Elixir. Covers Docker Compose deployment with PostgreSQL, environment configuration, and upgrade procedure. Derived from https://github.com/ClaperCo/Claper and https://docs.claper.co.
---

# Claper

Open-source interactive presentation tool built on Phoenix and Elixir. Upstream: <https://github.com/ClaperCo/Claper>. Documentation: <https://docs.claper.co/>. License: GPLv3.

Claper turns presentations into interactive experiences — audiences can submit questions, vote in polls, interact with embeds, and give real-time feedback during a presentation. The presenter sees live audience engagement in a separate presenter view.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/ClaperCo/Claper> | yes | Recommended self-hosted method. Runs app + PostgreSQL together. |
| Build from source | <https://github.com/ClaperCo/Claper> | yes | Development. Requires Elixir, Node.js, and PostgreSQL. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What domain or IP will Claper be accessible at?" | FQDN or IP | Used for PHX_HOST and URL configuration. |
| preflight | "What port should Claper listen on?" | Integer default 4000 | Maps to 4000:4000 in docker-compose. |
| config | "PostgreSQL password?" | String sensitive | Used for POSTGRES_PASSWORD and DATABASE_URL. |
| config | "Secret key base?" | 64-char hex string | Generate with: openssl rand -hex 64 |
| smtp | "SMTP host for email?" | hostname | Required for account invitations and notifications. |
| smtp | "SMTP port?" | Integer e.g. 587 | |
| smtp | "SMTP username?" | String | |
| smtp | "SMTP password?" | String sensitive | |
| smtp | "Mail from address?" | email address | |

## Docker Compose install

Upstream: <https://github.com/ClaperCo/Claper>

### docker-compose.yml

```yaml
services:
  db:
    image: postgres:15
    volumes:
      - "claper-db:/var/lib/postgresql/data"
    healthcheck:
      test: ["CMD", "pg_isready", "-q", "-d", "claper", "-U", "claper"]
      retries: 3
      timeout: 5s
    environment:
      POSTGRES_PASSWORD: claper
      POSTGRES_USER: claper
      POSTGRES_DB: claper
    networks:
      - claper-net
  app:
    image: ghcr.io/claperco/claper:latest
    ports:
      - 4000:4000
    volumes:
      - "claper-uploads:/app/uploads"
    healthcheck:
      test: curl --fail http://localhost:4000 || exit 1
      retries: 3
      start_period: 20s
      timeout: 5s
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
    networks:
      - claper-net

volumes:
  claper-db:
    driver: local
  claper-uploads:
    driver: local

networks:
  claper-net:
    driver: bridge
```

### .env file

Create a .env file in the same directory as docker-compose.yml:

```
PHX_HOST=claper.example.com
PORT=4000
DATABASE_URL=ecto://claper:claper@db/claper
SECRET_KEY_BASE=<64-char hex, generate with: openssl rand -hex 64>
MIX_ENV=prod

# SMTP (required for invitations)
MAIL_SERVER=smtp.example.com
MAIL_PORT=587
MAIL_USERNAME=user@example.com
MAIL_PASSWORD=yourpassword
MAIL_FROM=noreply@example.com
MAIL_FROM_NAME=Claper
```

### Deploy steps

```bash
# Create .env with your values
docker compose up -d
```

Access at http://your-host:4000. Register the first user account.

## Software-layer concerns

### Ports

| Port | Use |
|---|---|
| 4000 | Web UI (HTTP) |

### Data directories (inside container)

| Path | Contents |
|---|---|
| /app/uploads | Uploaded presentation files (PDF, images) |
| /var/lib/postgresql/data | PostgreSQL database (in db container) |

### Environment variables (key ones)

| Variable | Description |
|---|---|
| PHX_HOST | Public hostname for the instance |
| PORT | Port Phoenix listens on (default 4000) |
| DATABASE_URL | PostgreSQL connection string |
| SECRET_KEY_BASE | Phoenix secret key — must be 64+ chars, keep secret |
| MIX_ENV | Set to prod |
| MAIL_SERVER | SMTP hostname |
| MAIL_PORT | SMTP port |
| MAIL_USERNAME | SMTP auth user |
| MAIL_PASSWORD | SMTP auth password |
| MAIL_FROM | Sender address |
| MAIL_FROM_NAME | Sender display name |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Migrations run automatically on container startup.

## Gotchas

- **SECRET_KEY_BASE must be set**: Phoenix refuses to start without it. Generate with `openssl rand -hex 64`.
- **Database waits for healthcheck**: The app container depends on the db healthcheck passing. If the db is slow to start, the app will retry automatically.
- **Uploads volume**: Presentation files (uploaded PDFs/images) are stored in the uploads volume. Back it up before upgrades.
- **Reverse proxy recommended**: For production, place Claper behind NGINX or Caddy for TLS termination. Pass `X-Forwarded-For` and `X-Forwarded-Proto` headers.
- **Built with Phoenix/Elixir**: Not a Node.js or Python app. Startup logs look different — successful start shows `Listening on http://0.0.0.0:4000`.

## Links

- GitHub: <https://github.com/ClaperCo/Claper>
- Documentation: <https://docs.claper.co/>
- Docker image: <https://ghcr.io/claperco/claper>

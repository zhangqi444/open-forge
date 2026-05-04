# Apache Answer

Open-source Q&A platform for teams and communities. Build a knowledge base, internal help center, or community forum where users ask questions, provide answers, vote, and comment. Developed by AnswerDev, donated to the Apache Software Foundation. Built with Go (backend) + React (frontend). 15K+ GitHub stars. Upstream: <https://github.com/apache/answer>. Docs: <https://answer.apache.org/docs>.

Answer runs as a single container on port `80` by default. Data persists to a `/data` volume (SQLite or MySQL/PostgreSQL).

## Compatible install methods

Verified against upstream README at <https://github.com/apache/answer#quick-start>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | `docker run -d -p 9080:80 -v answer-data:/data apache/answer:latest` | ✅ | Simplest. All-in-one, SQLite included. |
| Docker Compose | See below | Community | When using external MySQL/PostgreSQL |
| Binary | <https://answer.apache.org/docs/installation> | ✅ | Bare metal / no Docker |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| port | "Port to expose Answer on?" | Number (default `9080`) | All |
| db | "Database type?" | `AskUserQuestion`: `SQLite (built-in)` / `MySQL` / `PostgreSQL` | All |
| db_url | "Database connection URL?" | Free-text (sensitive) | MySQL / PostgreSQL only |
| email | "SMTP host for email notifications?" | Free-text | Optional, for user registration emails |

## Software-layer concerns

### Docker quickstart (SQLite, zero config)

```bash
docker run -d \
  -p 9080:80 \
  -v answer-data:/data \
  --name answer \
  apache/answer:latest
```

Visit `http://localhost:9080`. The first visit triggers a setup wizard.

### Setup wizard

On first run, Answer presents a web-based installation wizard:

1. Select database type (SQLite is pre-selected and requires no config)
2. Set site name, admin email, admin password
3. Configure SMTP (optional — for registration/notification emails)

For MySQL/PostgreSQL, enter the connection details in the wizard.

### Docker Compose (with MySQL)

```yaml
services:
  answer:
    image: apache/answer:latest
    restart: unless-stopped
    ports:
      - "9080:80"
    volumes:
      - answer_data:/data
    environment:
      - DB_TYPE=mysql
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_NAME=answer
      - DB_USER=answer
      - DB_PASSWORD=${DB_PASSWORD}
    depends_on:
      mysql:
        condition: service_healthy

  mysql:
    image: mysql:8
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: answer
      MYSQL_USER: answer
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]

volumes:
  answer_data:
  mysql_data:
```

### Plugin system

Answer supports plugins for extended functionality:

```bash
# Install a plugin (in the container)
docker exec -it answer /bin/sh
answer plugin install <plugin-name>
```

Browse available plugins: <https://answer.apache.org/plugins>

Common plugins:
- **Search** — Algolia, Elasticsearch integration
- **Storage** — S3, Tencent COS for file uploads
- **Notification** — Slack, Lark webhooks
- **Auth** — GitHub, Google OAuth

### Key configuration

Most configuration is done through the admin UI (Settings) after install:

- **Branding:** Site name, logo, description, custom CSS
- **User management:** Registration mode (open, invitation, closed), email verification
- **Permissions:** Reputation thresholds for voting, commenting, editing
- **Tags:** Manage tags/categories for Q&A organization
- **Email:** SMTP settings for notification emails

Environment variables (advanced):

| Variable | Purpose |
|---|---|
| `DB_TYPE` | `sqlite3` (default), `mysql`, `postgres` |
| `DB_HOST` | Database host |
| `DB_PORT` | Database port |
| `DB_NAME` | Database name |
| `DB_USER` | Database user |
| `DB_PASSWORD` | Database password (sensitive) |

### Data directories

| Path | Contents |
|---|---|
| `/data/` | SQLite DB (`answer.db`), uploaded files, config, logs |
| `/data/answer.db` | SQLite database (when using SQLite) |
| `/data/uploads/` | User-uploaded images and files |

## Upgrade procedure

1. `docker pull apache/answer:latest`
2. `docker stop answer && docker rm answer`
3. `docker run -d -p 9080:80 -v answer-data:/data --name answer apache/answer:latest`

Answer runs database migrations automatically on startup.

## Gotchas

- **Version tag recommended over `latest`.** Pin to a specific version (e.g. `apache/answer:2.0.0`) for reproducible deployments.
- **SQLite is fine for small communities.** SQLite works well for < ~10K users; switch to MySQL/PostgreSQL for larger communities or if you need concurrent write performance.
- **Port 80 inside container.** The container listens on port `80` internally. Map it to whatever external port you want (e.g. `-p 9080:80`).
- **Email is optional but strongly recommended.** Without SMTP, new user registration requires manual approval, and users can't receive password reset emails.
- **Plugins require container restart.** After installing a plugin, the Answer process inside the container needs a restart.
- **Apache License 2.0.** Fully open-source, Apache Software Foundation project.

## Links

- Upstream: <https://github.com/apache/answer>
- Website: <https://answer.apache.org>
- Docs: <https://answer.apache.org/docs/installation>
- Plugins: <https://answer.apache.org/plugins>
- Docker Hub: <https://hub.docker.com/r/apache/answer>

---
name: snippets-library-project
description: Full-stack code snippet manager with authentication, syntax highlighting, public sharing, bookmarks, and likes. Upstream: https://github.com/cojocaru-david/snippetslibrary.com
---

# Snippets Library

Full-stack code snippet manager built with Next.js 15, TypeScript, and Drizzle ORM (Postgres). Features authenticated snippet storage, syntax highlighting via Shiki, instant search, public share links, bookmarks, likes, and view tracking. Uses GitHub OAuth for sign-in. Upstream: <https://github.com/cojocaru-david/snippetslibrary.com>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | [GitHub docker-compose.yml](https://github.com/cojocaru-david/snippetslibrary.com/blob/main/docker-compose.yml) | ✅ | Recommended self-hosted install |
| Manual / source | [GitHub README](https://github.com/cojocaru-david/snippetslibrary.com#repository-scripts) | ✅ | Development |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | options | All |
| config | GitHub OAuth Client ID | string | All |
| config | GitHub OAuth Client Secret | string | All |
| config | NextAuth secret (`AUTH_SECRET`) | string | All |
| config | Public app URL (`NEXT_PUBLIC_APP_URL`) | URL | All |
| config | Postgres password | string | Docker Compose |
| config | Port to expose app on (default 3000) | number | Docker Compose |

## Docker Compose install

Source: <https://github.com/cojocaru-david/snippetslibrary.com>

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: snippets-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-snippets_library}
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - snippets-network

  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: snippets-library:latest
    container_name: snippets-app
    restart: unless-stopped
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD:-postgres}@postgres:5432/${POSTGRES_DB:-snippets_library}
      - AUTH_SECRET=${AUTH_SECRET}
      - GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
      - GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
      - NEXT_PUBLIC_APP_URL=${NEXT_PUBLIC_APP_URL}
    depends_on:
      - postgres
    networks:
      - snippets-network

networks:
  snippets-network:

volumes:
  postgres_data:
```

## Configuration

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | Postgres connection string |
| `GITHUB_CLIENT_ID` | ✅ | GitHub OAuth app client ID |
| `GITHUB_CLIENT_SECRET` | ✅ | GitHub OAuth app client secret |
| `AUTH_SECRET` | ✅ | NextAuth secret (random string) |
| `NEXT_PUBLIC_APP_URL` | ✅ | Public URL of the app |
| `IP_HASH_SALT` | optional | Salt for hashing visitor IPs |

Create a GitHub OAuth app at <https://github.com/settings/developers> with the callback URL set to `${NEXT_PUBLIC_APP_URL}/api/auth/callback/github`.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Run database migrations after upgrades:

```bash
docker compose exec app npm run db:migrate
```

## Gotchas

- Requires a GitHub OAuth app — sign-in is GitHub-only.
- `AUTH_SECRET` must be set or NextAuth will refuse to start.
- Database migrations are managed with drizzle-kit; run `npm run db:migrate` after schema changes.

## References

- GitHub: <https://github.com/cojocaru-david/snippetslibrary.com>

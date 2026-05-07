---
name: RSS Monster
description: Intelligent web-based RSS aggregator and reader. Fever API and Google Reader API compatible. Smart folders, semantic clustering, quality scoring, and multi-user support. MIT licensed.
website: https://github.com/pietheinstrengholt/rssmonster
source: https://github.com/pietheinstrengholt/rssmonster
license: MIT
stars: 466
tags:
  - rss
  - news-reader
  - aggregator
  - feed-reader
platforms:
  - JavaScript
  - Docker
---

# RSS Monster

RSS Monster is an intelligent web-based RSS aggregator and reader. Beyond simple chronological feed lists, it evaluates and prioritizes content using semantic clustering, quality scoring, importance ranking, and feed trust scores. Supports Fever API and Google Reader API for compatibility with RSS client apps (Reeder, FeedMe, News+, Vienna RSS). Multi-user, dark mode, OPML import/export, and an AI-powered assistant via MCP.

Source: https://github.com/pietheinstrengholt/rssmonster
Docker Hub (client): https://hub.docker.com/r/rssmonster/client
Docker Hub (server): https://hub.docker.com/r/rssmonster/server

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker Compose (client + server + MySQL) | Recommended |
| Any Linux VM / VPS | Node.js 20+ + MySQL | Native install |

## Inputs to Collect

**Phase: Planning**
- MySQL credentials (host, database, user, password)
- Public URL for the client (`VITE_VUE_APP_HOSTNAME`)
- Port to expose (client default: 8080, server default: 3000)
- Whether to expose Fever/Google Reader API (for external RSS clients)

## Software-Layer Concerns

**Docker Compose:**

```yaml
services:
  client:
    image: rssmonster/client
    depends_on:
      - server
    ports:
      - "8080:8080"
    environment:
      VITE_VUE_APP_HOSTNAME: http://localhost:3000
      VITE_NODE_ENV: production
      VITE_BASE_URL: /
      PORT: 8080

  server:
    image: rssmonster/server
    depends_on:
      - mysql
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      PORT: 3000
      DB_USERNAME: rssmonster
      DB_PASSWORD: CHANGE_ME
      DB_DATABASE: rssmonster
      DB_HOST: mysql
      DB_DIALECT: mysql

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: rssmonster
      MYSQL_USER: rssmonster
      MYSQL_PASSWORD: CHANGE_ME
      MYSQL_ROOT_PASSWORD: CHANGE_ME_ROOT
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

**Or build from source (development):**

```bash
git clone https://github.com/pietheinstrengholt/rssmonster
cd rssmonster
# Edit client/.env and server/.env with your config
docker compose up   # uses build context with dockerfiles
```

**Server environment variables:**

| Variable | Description |
|----------|-------------|
| DB_USERNAME | MySQL username |
| DB_PASSWORD | MySQL password |
| DB_DATABASE | MySQL database name |
| DB_HOST | MySQL host |
| DB_DIALECT | Database dialect (mysql) |
| PORT | Server port (default: 3000) |

**Client environment variables:**

| Variable | Description |
|----------|-------------|
| VITE_VUE_APP_HOSTNAME | URL of the backend server |
| VITE_BASE_URL | Base URL path for the client |
| PORT | Client port (default: 8080) |

**Fever API endpoint:** `http://yoursite.com:3000/fever/` — compatible with Reeder (iOS), FeedMe (Android).

**Google Reader API endpoint:** `http://yoursite.com:3000/reader/api/` — compatible with News+, FeedMe, Vienna RSS.

**Feed trust scores (run periodically):**

```bash
docker compose exec server npm run feedtrust
```

## Upgrade Procedure

1. `docker pull rssmonster/client && docker pull rssmonster/server`
2. `docker compose down && docker compose up -d`
3. Check releases: https://github.com/pietheinstrengholt/rssmonster/releases

## Gotchas

- **Two services**: Client (Vue.js frontend) and server (Node/Express backend) are separate containers — both must be running and the client's `VITE_VUE_APP_HOSTNAME` must point to the server URL
- **Development compose vs production**: The default `docker-compose.yml` in the repo uses build context (for development); for production, use pre-built images from Docker Hub
- **Fever API auth**: Fever API uses MD5 hash of `username:password` — set credentials in the RSSMonster user settings
- **Smart folders**: Smart folders use composable search expressions rather than fixed categories — read the README for the query syntax
- **Feed trust scores**: Run `npm run feedtrust` periodically to recalculate per-feed trust scores; this improves ranking quality over time
- **Node.js 20+**: Requires Node.js 20 or higher for the server

## Links

- Upstream README: https://github.com/pietheinstrengholt/rssmonster/blob/master/README.md
- Docker Hub: https://hub.docker.com/r/rssmonster/rssmonster
- Releases: https://github.com/pietheinstrengholt/rssmonster/releases

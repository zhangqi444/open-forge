# Lingarr

**Automatic subtitle translation for your media library — integrates with Sonarr/Radarr and supports 11 translation providers including DeepL, OpenAI, LibreTranslate, and local Ollama.**
GitHub: https://github.com/lingarr-translate/lingarr
Discord: https://discord.gg/HkubmH2rcR

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose + MariaDB | Default/recommended |
| Any Linux | Docker Compose + PostgreSQL | Supported |
| Any Linux | Docker Compose + SQLite | Supported (lightweight) |

---

## Inputs to Collect

### Required
- `DB_PASSWORD` — database password
- Media paths — host paths to movies and TV directories
- Translation service — choice of provider + API key (if not using local/free)

### Translation providers (pick one)
- LibreTranslate (free, self-hostable)
- Local AI via Ollama or any OpenAI-compatible endpoint
- DeepL (API key required)
- Anthropic, OpenAI, DeepSeek, Gemini (API keys required)
- Google, Bing, Yandex, Azure (API keys required)

---

## Software-Layer Concerns

### Docker Compose (with MariaDB)
```yaml
services:
  lingarr:
    image: ghcr.io/lingarr-translate/lingarr:latest
    container_name: lingarr
    restart: unless-stopped
    environment:
      - ASPNETCORE_URLS=http://+:9876
      - DB_CONNECTION=mysql
      - DB_HOST=lingarr-db
      - DB_PORT=3306
      - DB_DATABASE=lingarr
      - DB_USERNAME=lingarr
      - DB_PASSWORD=your-password
    ports:
      - "9876:9876"
    volumes:
      - /path/to/media/movies:/movies
      - /path/to/media/tv:/tv
      - /path/to/config:/app/config
    networks:
      - lingarr
    depends_on:
      lingarr-db:
        condition: service_healthy

  lingarr-db:
    image: mariadb:latest
    container_name: lingarr-db
    restart: unless-stopped
    environment:
      - MYSQL_DATABASE=lingarr
      - MYSQL_USER=lingarr
      - MYSQL_PASSWORD=your-password
      - MYSQL_ROOT_PASSWORD=your-root-password
    volumes:
      - /path/to/db:/var/lib/mysql
    networks:
      - lingarr
    healthcheck:
      test: "mariadb $$MYSQL_DATABASE -u$$MYSQL_USER -p$$MYSQL_PASSWORD -e 'SELECT 1;'"
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  lingarr:
    external: true
```

### Network setup (required)
```bash
docker network create lingarr
```

### Image tags
| Tag | Notes |
|-----|-------|
| `latest` | Stable, amd64 + arm64 |
| `1.x.x` | Pinned version |
| `main` | ⚠️ Dev build |

### Ports
- `9876` — web UI

### Key features
- Integrates with Sonarr and Radarr for automated subtitle translation
- Supports .srt and other subtitle formats
- Translates to your target language on schedule or on-demand
- Config stored at `/app/config`

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Lingarr starts quickly but DB migrations may not be ready — use `depends_on` with `condition: service_healthy`
- Must create the `lingarr` Docker network before first start: `docker network create lingarr`
- Media paths must match your Sonarr/Radarr volume mappings
- SQLite option available if you want to skip the DB container

---

## References
- GitHub: https://github.com/lingarr-translate/lingarr#readme
- Discord: https://discord.gg/HkubmH2rcR

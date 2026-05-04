---
name: tolgee
description: Tolgee recipe for open-forge. Open-source localization platform with in-context translation, machine translation (DeepL/Google/AWS), and SDKs for React, Angular, Vue, and more. Alternative to Crowdin/Phrase.
---

# Tolgee

Open-source localization platform that lets developers and translators collaborate on app translations. Features in-context translation (edit strings directly in the running app), machine translation (DeepL, Google Translate, AWS), translation memory, and SDK integrations. Apache 2.0 / Tolgee Enterprise License. Upstream: <https://github.com/tolgee/tolgee-platform>. Docs: <https://docs.tolgee.io/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Standard self-hosted deployment |
| Standalone Docker | Quick eval |
| Kubernetes / Helm | Production K8s |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Domain for Tolgee?" | For reverse-proxy TLS setup |
| preflight | "Admin email and password?" | `TOLGEE_AUTHENTICATION_INITIAL_USERNAME` / `TOLGEE_AUTHENTICATION_INITIAL_PASSWORD` |
| preflight | "Enable machine translation?" | Optional; needs API keys for DeepL/Google/AWS |

## Docker Compose example

```yaml
version: "3.9"
services:
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: tolgee
      POSTGRES_USER: tolgee
      POSTGRES_PASSWORD: changeme
    volumes:
      - tolgee-db:/var/lib/postgresql/data

  tolgee:
    image: tolgee/tolgee:latest
    restart: unless-stopped
    depends_on:
      - postgres
    ports:
      - "8080:8080"
    volumes:
      - tolgee-data:/data
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/tolgee
      SPRING_DATASOURCE_USERNAME: tolgee
      SPRING_DATASOURCE_PASSWORD: changeme
      TOLGEE_AUTHENTICATION_INITIAL_USERNAME: admin@example.com
      TOLGEE_AUTHENTICATION_INITIAL_PASSWORD: changeme
      TOLGEE_FILE_STORAGE_FS_DATA_PATH: /data

volumes:
  tolgee-db:
  tolgee-data:
```

## Software-layer concerns

- Port: `8080`
- Data dir `/data` — persist this volume; contains uploaded files and exports
- Machine translation: configure per-project in UI (Settings → Machine Translation); requires API keys for DeepL/Google/AWS
- In-context translation: embed Tolgee SDK in your app; hold Alt/Option + click any string to translate live
- SDK support: React, Angular, Vue, Svelte, Next.js, Nuxt, plain JS, iOS, Android, Flutter, i18next, PHP, Ruby
- `TOLGEE_AUTHENTICATION_INITIAL_*` only creates the admin on first run

## Upgrade procedure

1. Pull new image: `docker compose pull tolgee`
2. Restart: `docker compose up -d tolgee`
3. DB migrations run automatically via Liquibase on startup

## Gotchas

- Free Community Edition covers most features; [Tolgee Enterprise License](https://tolgee.io/pricing) adds advanced permissions, SSO, priority support
- `INITIAL_USERNAME` / `INITIAL_PASSWORD` only take effect on the first startup — changing them later has no effect
- Put behind a reverse proxy with TLS; plain HTTP is fine for localhost dev
- Translation export formats: JSON, PO, XLIFF, CSV, Apple Strings, Android XML, Flutter ARB

## Links

- GitHub: <https://github.com/tolgee/tolgee-platform>
- Docs: <https://docs.tolgee.io/>
- Docker Hub: <https://hub.docker.com/r/tolgee/tolgee>

---
name: LinguaCafe
description: "Self-hosted e-reader and vocabulary tracker for language learners. Docker. PHP/Laravel + MySQL. simjanos-dev/LinguaCafe. 18 languages, Anki export, DeepL/LibreTranslate, epub/text import, Jellyfin/Kodi integration."
---

# LinguaCafe

**Self-hosted e-reader and vocabulary tracker for language learners.** Import texts and e-books; read in the browser with hover-to-translate; look up words in built-in dictionaries; track vocabulary status; export to Anki flashcards. Integrates with DeepL and LibreTranslate for machine translation, and Jellyfin/Kodi for subtitle-based reading. 18 supported languages.

Built + maintained by **simjanos-dev (János Simó)** and contributors.

- Upstream repo: <https://github.com/simjanos-dev/LinguaCafe>
- Docs: <https://simjanos-dev.github.io/LinguaCafeDocs/>
- GHCR: `ghcr.io/simjanos-dev/linguacafe-webserver`

## Architecture in one minute

- **PHP / Laravel** backend + frontend
- **MySQL 8** database
- **Python** service for NLP tokenization (separate container for some languages)
- Docker Compose stack: `webserver` + `database` (+optional Python NLP service)
- Port **9191** (web UI); WebSocket port **6001** (Reverb/Pusher)
- Data in `./storage` bind mount + MySQL volume
- Resource: **medium** — PHP-FPM + MySQL + optional Python NLP

## Compatible install methods

| Infra             | Runtime                                           | Notes                                              |
| ----------------- | ------------------------------------------------- | -------------------------------------------------- |
| **Docker Compose**| `ghcr.io/simjanos-dev/linguacafe-webserver`       | **Primary** — clone repo + `docker compose up -d`  |

## Inputs to collect

| Input                        | Example                            | Phase    | Notes                                                                                         |
| ---------------------------- | ---------------------------------- | -------- | --------------------------------------------------------------------------------------------- |
| `DB_PASSWORD`                | strong random                      | Storage  | MySQL password; set in `.env` or compose env                                                  |
| Target language(s)           | Japanese, German, Spanish…         | Config   | Set in Settings → Languages after first boot                                                  |
| DeepL API key (optional)     | free or pro tier                   | Translate| For machine translation on hover; free tier = 500k chars/month                               |
| LibreTranslate (optional)    | self-hosted URL                    | Translate| Alternative to DeepL; self-hosted translation server                                          |
| Jellyfin/Kodi URL (optional) | `http://jellyfin:8096`             | Integrate| For importing subtitles from media server                                                     |

## Install

```bash
git clone https://github.com/simjanos-dev/LinguaCafe.git
cd LinguaCafe

# Copy and edit .env if customizing DB creds / port
cp .env.example .env   # if provided; or edit env vars in docker-compose.yml directly

# Set VERSION (optional; defaults to latest) and PORT (defaults to 9191)
# DB_PASSWORD should match across webserver + database services
docker compose up -d
```

Visit `http://localhost:9191`.

## First boot

1. Deploy containers (wait for MySQL health check — up to 60s).
2. Visit `http://localhost:9191` → register admin account.
3. Settings → Languages → add your target language(s).
4. Import a text: Text import → paste or upload a `.txt`/`.epub`.
5. Read: hover over words → dictionary popup → set word status (Unknown/Learning/Known).
6. Review vocabulary: Anki export or the built-in review screen.
7. (Optional) Configure DeepL API key in Settings → Integrations for auto-translation.
8. (Optional) Connect Jellyfin/Kodi for subtitle import.
9. Put behind TLS if exposing beyond localhost.

## Supported languages (18)

Arabic, Chinese (Simplified), Croatian, Czech, Dutch, Finnish, French, German, Greek, Italian, Japanese, Korean, Norwegian, Polish, Portuguese, Russian, Spanish, Swedish, Ukrainian.

NLP tokenization is language-specific — some languages need the Python NLP container. Check the docs for your target language's requirements.

## Vocabulary status levels

| Status | Color | Meaning |
|--------|-------|---------|
| Unknown | blue | First encounter |
| Learning (1–5) | yellow | In active learning |
| Known | green | Fully acquired |
| Ignored | gray | Proper nouns, skip |

## Features overview

| Feature | Details |
|---------|---------|
| E-reader | Read imported texts with click-to-lookup |
| Hover translate | Translate sentences via DeepL/LibreTranslate |
| Dictionaries | Built-in dictionaries per language; frequency lists |
| Vocabulary tracking | Per-word status across all imported texts |
| Statistics | Words learned per day, reading time, vocabulary growth |
| Anki export | Export vocabulary to Anki flashcard deck |
| epub import | Import e-books in epub format |
| Subtitle import | Jellyfin/Kodi integration for TV/movie subtitle reading |
| Backup | Scheduled automated backups; configurable interval |

## Data & config layout

- `./storage/` — uploaded texts, e-books, media, generated files
- MySQL volume — vocabulary DB, user data, word statuses, statistics

## Backup

Built-in scheduled backup: `BACKUP_INTERVAL: "59 23 * * *"` (cron) + `MAX_SAVED_BACKUPS: 14` — configure in compose env. Backups saved to `./storage/backups/`.

Manual backup:
```sh
docker compose exec database mysqldump -u linguacafe -p$DB_PASSWORD linguacafe > linguacafe-$(date +%F).sql
sudo tar czf linguacafe-storage-$(date +%F).tgz storage/
```

## Upgrade

1. `git pull && docker compose pull && docker compose up -d`
2. Check [changelog](https://github.com/simjanos-dev/LinguaCafe/releases) — some upgrades have migration steps.

## Gotchas

- **MySQL health check takes up to 60s on first run.** The webserver has a `depends_on` condition on MySQL health. Don't panic if the web container starts slowly — it's waiting for the DB. Check `docker compose logs database`.
- **Language-specific NLP containers.** Some languages (Japanese, Chinese, Korean) require a Python NLP service for tokenization (word segmentation). Check the install docs for your language — you may need to add a service to your compose.
- **DeepL free tier = 500k characters/month.** More than enough for personal language study. Pro tier for heavier use. LibreTranslate is a fully self-hosted alternative with no API key restrictions.
- **Port 6001 is the WebSocket port.** Used for real-time UI updates (Reverb/Pusher). If you proxy through nginx/Caddy, you need to also proxy WebSocket connections to `:6001`. Missing this causes the UI to fall back to polling or lose real-time features.
- **epub import.** LinguaCafe parses epub files; complex layouts (heavy image/table formatting) may not parse cleanly. Plain fiction e-books work best.
- **Anki export.** Exports vocabulary with example sentences from the text. Import the `.apkg` file into Anki desktop; standard note type.
- **Backup folder size.** With `MAX_SAVED_BACKUPS: 14`, daily backups accumulate. Monitor `./storage/backups/` size for large vocabulary databases.

## Project health

Active PHP/Laravel development, Docker CI (GHCR), 18 languages, Anki export, DeepL + LibreTranslate, Jellyfin/Kodi integration, built-in scheduler. Solo-maintained by János Simó. MIT license.

## Language-learning-reader-family comparison

- **LinguaCafe** — PHP+MySQL, Docker, 18 languages, Anki export, Jellyfin/Kodi, hover translate
- **Lute v3** — Python+Flask, SQLite, pip/Docker, similar concept but no Jellyfin/no epub
- **LingQ** — SaaS, subscription, polished; the main commercial alternative
- **Readlang** — SaaS, browser extension, simpler
- **Clozemaster** — SaaS, cloze-deletion focus; different learning style

**Choose LinguaCafe if:** you want a full-featured self-hosted reading environment with vocabulary tracking, Anki export, DeepL integration, and Jellyfin/Kodi subtitle import for 18 languages.

## Links

- Repo: <https://github.com/simjanos-dev/LinguaCafe>
- Docs: <https://simjanos-dev.github.io/LinguaCafeDocs/>
- GHCR: `ghcr.io/simjanos-dev/linguacafe-webserver`
- Lute v3 (simpler alt): <https://github.com/LuteOrg/lute-v3>

---
name: Lute v3
description: "Language learning through reading app. Python/Flask + SQLite. pip install / Docker. LuteOrg/lute-v3. Track vocabulary, interactive reading, text import, spaced-repetition-style review."
---

# Lute v3 (Learning Using Texts)

**Language learning through reading.** Import texts in a foreign language; click words to look them up, add translations, and track them through reading stages. Built-in spaced-repetition-style vocabulary review, statistics, and multi-language support. Python/Flask web app with SQLite. Desktop-friendly (launch locally, use in browser).

Built + maintained by **Jeff Zohrab (jzohrab)** and contributors.

- Upstream repo: <https://github.com/LuteOrg/lute-v3>
- Manual + docs: <https://luteorg.github.io/lute-manual/>
- Discord: <https://discord.gg/CzFUQP5m8u>
- PyPI: `lute3`
- Docker Hub: `jzohrab/lute3`

## Architecture in one minute

- **Python 3.8+ / Flask** web app
- **SQLite** database
- Serves on **http://localhost:5000** by default (configurable)
- Single user — designed for personal vocabulary tracking
- Resource: **tiny** — Python + SQLite; runs fine on any laptop or Pi

## Compatible install methods

| Infra          | Runtime             | Notes                                                                       |
| -------------- | ------------------- | --------------------------------------------------------------------------- |
| **pip**        | `pip install lute3` | **Simplest** — local install; `python -m lute.main` to start                |
| **Docker**     | `jzohrab/lute3`     | Containerized; good for NAS or always-on home server                        |
| **From source**| git + pip install   | Development; see manual                                                     |

## Install via pip

```bash
# Python 3.8+ required
pip install lute3

# Start Lute
python -m lute.main

# Visit http://localhost:5000
```

## Install via Docker

```bash
docker run -d \
  --name lute3 \
  -p 5000:5000 \
  -v lute_data:/lute_data \
  jzohrab/lute3
```

Visit `http://localhost:5000`.

## First use

1. Start Lute (pip or Docker).
2. Visit the web UI → **Load a demo** to see how it works (recommended first step).
3. Add a **language** (Settings → Languages) — configure parser, dictionary URL, sentence-lookup.
4. Import a **text** (Texts → New) — paste or upload; Lute tokenizes and displays it.
5. Click on unknown words (shown highlighted) → add a translation + pronunciation.
6. Words move through statuses: Unknown → 1 → 2 → 3 → 4 → 5 → Learned.
7. Read texts; click to look up; words gradually become familiar.
8. Use **Review** (flashcard-style) to drill vocabulary.
9. Import more texts as you progress.

## How word tracking works

Words go through numbered statuses representing familiarity:

| Status | Meaning |
|--------|---------|
| 0 | Unknown (unseen) — highlighted blue |
| 1–4 | Learning — highlighted yellow shades |
| 5 | Learned — no highlight |
| W | Well-known — explicitly marked, no highlight |
| I | Ignored — always ignored (names, proper nouns) |

Click a word → enter translation + status → save. Lute tracks across all texts in the language.

## Supported languages (built-in parsers)

Arabic, Classical Chinese, Czech, English, Finnish, French, German, Greek (Ancient + Modern), Hindi, Icelandic, Italian, Japanese, Korean, Latin, Norwegian, Polish, Portuguese (Brazil + European), Russian, Slovak, Slovenian, Spanish, Swedish, Turkish, Ukrainian, and more. Any language with a sentence-per-line structure can be used with the generic parser.

## Data & config layout

- Docker: `lute_data:/lute_data` — SQLite DB + uploaded audio files
- pip: `~/.lute3/` or the configured data directory
- No server-side user accounts — single-user by design

## Backup

```sh
# Docker
docker stop lute3
sudo tar czf lute3-$(date +%F).tgz <lute_data_volume>/
docker start lute3

# pip install
cp -r ~/.lute3/ ~/lute3-backup-$(date +%F)/
```

Contents: your entire vocabulary database across all languages. Back up before upgrading.

## Upgrade

- pip: `pip install --upgrade lute3`
- Docker: `docker pull jzohrab/lute3 && docker compose up -d`
- Check the [migration notes](https://luteorg.github.io/lute-manual/install/upgrading.html) for breaking changes between major versions.

## Gotchas

- **Single-user by design.** Lute is not a multi-user app. Don't try to host it for multiple people — vocabulary tracking is per-instance and there are no user accounts.
- **SQLite = single-file backup.** Simple and reliable for personal use. Backup before upgrades.
- **Demo mode is the best onboarding.** The manual strongly recommends loading the demo texts before importing your own. It shows how the UI works and demonstrates word-status flow.
- **Dictionary integration is external.** Lute opens dictionary links in a split pane or new tab when you click a word. Configure your preferred dictionary URL (e.g. Linguee, WordReference, DeepL, custom) per language in Settings.
- **Japanese/Korean/Chinese require special parsers.** These languages don't use spaces to separate words — Lute uses language-specific tokenizers (MeCab for Japanese, jieba for Chinese). The Docker image bundles required deps; pip install may need extras (`pip install lute3[mecab]` etc.) — check the manual.
- **Audio import.** Lute supports audio files alongside texts (for listening practice + sentence audio). Mount an `audio/` directory into the container.
- **v3 is a full rewrite.** Lute v1/v2 data is not directly compatible — use the migration tool if upgrading from an earlier version.

## Project health

Active Python development, CI, PyPI, Docker Hub, Discord, comprehensive manual. Maintained by Jeff Zohrab + community contributors. MIT license.

## Language-learning-through-reading-family comparison

- **Lute v3** — Python/Flask, SQLite, pip/Docker, multi-language parsers, open source
- **LingQ** — SaaS, polished, subscription; the main commercial equivalent
- **Readlang** — SaaS; browser extension + web; subscription
- **Language Reactor** — Netflix + YouTube subtitle reader; browser extension; not a text importer
- **Anki** — flashcard SRS; can complement Lute but not reading-focused

**Choose Lute v3 if:** you want a self-hosted language learning through reading app with vocabulary tracking, multi-language support, and spaced-repetition review — for free.

## Links

- Repo: <https://github.com/LuteOrg/lute-v3>
- Manual: <https://luteorg.github.io/lute-manual/>
- Discord: <https://discord.gg/CzFUQP5m8u>
- PyPI: `pip install lute3`

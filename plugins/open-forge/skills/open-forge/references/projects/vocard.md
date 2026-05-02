# Vocard

**What it is:** Highly customizable self-hosted Discord music bot. Supports YouTube, SoundCloud, Spotify, Twitch, and more. Uses Lavalink for audio playback. Features slash and message commands, built-in playlists, lyrics, sound effects, multiple languages, and an optional premium dashboard.

**Official site:** https://vocard.xyz  
**Docs:** https://docs.vocard.xyz  
**GitHub:** https://github.com/ChocoMeow/Vocard  
**Dashboard (premium):** https://github.com/ChocoMeow/Vocard-Dashboard

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; Lavalink + Vocard bot |
| Any Linux | Python 3.11+ | Run directly with Python |

---

## Prerequisites

- A **Discord bot application** with token (create at https://discord.com/developers/applications)
- A **Lavalink server** (v4.0.0+) — bundled in the Docker Compose setup

---

## Stack Components

| Container | Role |
|-----------|------|
| `lavalink` | Audio server (Java-based); handles audio streaming from platforms |
| `spotify-tokener` | Provides Spotify tokens to Lavalink for Spotify support |
| `vocard` | The Discord bot itself |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| Discord bot token | From Discord Developer Portal |
| `settings.json` | Vocard config — bot token, Lavalink connection, prefixes |
| `application.yml` | Lavalink config — server settings, source plugins |
| Lavalink password | Set in `application.yml` and matched in `settings.json` (default `youshallnotpass`) |

---

## Software-Layer Concerns

- **Lavalink v4.0.0+ required** — older versions are not compatible
- **Lavalink password** is set in `application.yml`; must match what Vocard uses to connect — change from default `youshallnotpass` if exposing Lavalink
- **Spotify support** requires the `spotify-tokener` sidecar (or a Spotify application token)
- **Docker networking** — Lavalink is on an internal Docker network (`vocard`); only the Discord bot container needs internet access
- **`settings.json`** — main Vocard configuration; see docs for full reference
- All slash commands and message commands are supported simultaneously

---

## Upgrade Procedure

1. Pull new images: `docker compose pull`
2. Restart: `docker compose up -d`
3. Check docs for any `settings.json` changes between versions

---

## Gotchas

- **Lavalink must be healthy before Vocard starts** — Docker Compose healthcheck handles this; don't skip it
- **Java memory (`-Xmx1G`)** — default is 1 GB for Lavalink; increase for large servers or high concurrency
- Lavalink password `youshallnotpass` is the well-known default — change it in `application.yml` (and update `settings.json` to match) before any internet-facing deployment
- **Platform availability** — YouTube access from Lavalink may require a workaround plugin depending on Google's API restrictions; check Lavalink plugin ecosystem for current solutions
- Vocard requires Python 3.11+ for non-Docker installs

---

## Links

- Website: https://vocard.xyz
- Docs: https://docs.vocard.xyz/latest/bot/setup
- GitHub: https://github.com/ChocoMeow/Vocard
- Docker setup: https://docs.vocard.xyz/latest/bot/setup/docker-linux/
- Support Discord: https://discord.gg/wRCgB7vBQv

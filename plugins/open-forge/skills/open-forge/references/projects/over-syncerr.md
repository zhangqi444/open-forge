# Overr-Syncerr

> Automation bridge for Overseerr/Jellyseerr that handles subtitle synchronisation, subtitle/audio preference management, and media labelling — triggered by webhooks from your request platform, no manual intervention required.

**Official URL:** https://github.com/gssariev/overr-syncerr  
**Docs:** https://wiki.overrsyncerr.info

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Primary deployment method |
| Any Linux VPS/VM | Docker Compose | Recommended |
| Bare metal | Python (direct) | Build from source; not documented upstream |

**Requires:** Overseerr or Jellyseerr (for webhook triggers), Sonarr/Radarr (media management), Bazarr (subtitle sync)

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `OVERSEERR_URL` | Base URL of your Overseerr/Jellyseerr instance | `http://overseerr:5055` |
| `OVERSEERR_API_KEY` | API key from Overseerr/Jellyseerr settings | `abc123...` |
| `SONARR_URL` | Sonarr base URL | `http://sonarr:8989` |
| `SONARR_API_KEY` | Sonarr API key | `abc123...` |
| `RADARR_URL` | Radarr base URL | `http://radarr:7878` |
| `RADARR_API_KEY` | Radarr API key | `abc123...` |
| `BAZARR_URL` | Bazarr base URL | `http://bazarr:6767` |
| `BAZARR_API_KEY` | Bazarr API key | `abc123...` |

### Phase: Optional Features
| Input | Description | Example |
|-------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI key for GPT-based subtitle translation (optional) | `sk-...` |
| `PLEX_URL` | Plex URL for auto-labelling feature (optional) | `http://plex:32400` |
| `PLEX_TOKEN` | Plex auth token for auto-labelling (optional) | `abc123...` |

---

## Software-Layer Concerns

### How It Works
1. Overseerr/Jellyseerr sends a webhook to Overr-Syncerr when a user reports a subtitle issue or when media becomes available
2. Overr-Syncerr looks up the media in Sonarr/Radarr, identifies the file, and calls Bazarr to sync/translate subtitles
3. Optionally applies per-user audio/subtitle track preferences and labels media in Plex with the requester's name
4. Posts a reply and resolves the issue in Overseerr/Jellyseerr automatically

### Config Files
- On first run, the container generates `subtitle_preferences.json` and `audio_preferences.json` in the data volume
- **IMPORTANT:** Run the script once to generate these files *before* enabling the Overseerr Request Monitor webhook, or preferences may not apply correctly

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/app/data` | Generated preference JSON files; bind-mount to persist |

### Ports
- Default webhook listener: `8282` (verify in your config; proxy with Nginx/Caddy if exposing externally)

### Webhook Configuration
In Overseerr/Jellyseerr → Settings → Notifications → Webhook:
- URL: `http://overr-syncerr:8282/webhook` (or your public URL)
- Enable: Issue Created, Issue Resolved, Media Available

---

## Upgrade Procedure

1. Pull the latest image: `docker pull gsariev/overr-syncerr:latest`
2. Stop the container: `docker compose down`
3. Start with new image: `docker compose up -d`
4. Check logs: `docker compose logs -f`

---

## Gotchas

- **Generate preference files first** — Start the container, let it create `subtitle_preferences.json` and `audio_preferences.json`, *then* enable the Overseerr Request Monitor webhook. Enabling it too early may cause preferences not to apply
- **4K instance support** — Bazarr supports separate 4K instances; configure both `BAZARR_URL` and `BAZARR_4K_URL` if you run a separate 4K Radarr/Bazarr stack
- **OpenAI translation** — GPT-based subtitle translation requires a paid OpenAI API key; Google Translate is the default free fallback
- **Plex labelling** — The auto-labelling feature requires a Plex token and marks media with the Overseerr requester's username for easy collection management
- **Personal project** — Built around one person's setup; may require adaptation for different naming conventions or unusual arr configurations

---

## Links
- GitHub: https://github.com/gssariev/overr-syncerr
- Docs/Wiki: https://wiki.overrsyncerr.info
- Docker Hub: https://hub.docker.com/r/gsariev/overr-syncerr

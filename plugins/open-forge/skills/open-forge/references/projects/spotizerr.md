# Spotizerr

**What it is:** Self-hosted Spotify music downloader — download tracks, albums, and playlists from Spotify via yt-dlp and spotDL.
**Official URL:** https://lavaforge.org/spotizerr/spotizerr
**Repo:** https://lavaforge.org/spotizerr/spotizerr

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

## Inputs to Collect

### Deploy phase
- Port to expose
- Spotify credentials or cookie (see upstream docs)
- Download output path (mount as volume)

## Software-Layer Concerns

- **Config:** Environment variables / config file
- **Data dir:** Persistent volume for downloads
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image and restart.

## Gotchas

- Downloading copyrighted music may violate Spotify ToS and local laws — personal use only
- Requires Spotify account credentials or session cookie
- Download quality depends on source availability

## References

- [Repo](https://lavaforge.org/spotizerr/spotizerr)

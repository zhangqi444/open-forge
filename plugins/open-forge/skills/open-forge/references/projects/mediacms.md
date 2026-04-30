---
name: MediaCMS
description: "Self-hosted video + media CMS — modern full-featured portal for building a YouTube-like site. Django + React + Celery. Chunked uploads, multi-resolution transcoding, HLS streaming, Whisper auto-transcription, SAML, RBAC. AGPL-3.0."
---

# MediaCMS

MediaCMS is **"build your own YouTube"** — a fully-featured video + media content-management system. Upload, transcode, play, comment, organize with categories/tags/playlists, share with public/private/unlisted/custom visibility, multi-user + RBAC, SAML SSO, auto-transcription via local Whisper, chunked uploads, playlists. Built on **Django + React + Celery**. Suitable for universities, schools, internal/sensitive-content portals, community video sites, or personal archives.

Developed by **Markos Gogoulos**. Active project; commercial services (custom installations, extensions, support, migrations) on <https://mediacms.io>.

Features (per upstream):

- **Host your own** — complete data sovereignty
- **Publishing workflows**: public / private / unlisted / custom
- **RBAC categories** with group-based view/edit
- **Automatic transcription** — local Whisper (no cloud)
- **Multi-media types**: video, audio, image, PDF
- **Classification**: categories, tags, custom
- **Sharing**: social share + embed codes
- **Video Trimmer** — trim, replace, save-as-new, segments
- **SAML SSO** with role/group mapping
- **Live search**
- **Playlists** (audio + video)
- **Responsive + light/dark themes**
- **Customizable branding**: logos, fonts, styling, pages
- **Enhanced VideoJS player** — multiple resolutions + playback speeds
- **Multi-resolution transcoding**: 144p/240p/360p/480p/720p/1080p × h264/h265/vp9
- **Adaptive streaming via HLS**
- **Subtitles/CC** (multilingual)
- **Scalable transcoding** with priority queues; experimental remote workers
- **Chunked uploads** — pausable/resumable
- **REST API** (Swagger-documented)
- **Localized** — many languages

- Upstream repo: <https://github.com/mediacms-io/mediacms>
- Homepage + services: <https://mediacms.io>
- Demo: <https://demo.mediacms.io>
- Docker Hub: <https://hub.docker.com/r/mediacms/mediacms>
- Commercial hosting (Elestio): <https://elest.io/open-source/mediacms>

## Architecture in one minute

- **Django / Python** web app + **Celery** workers for transcoding
- **PostgreSQL** (preferred) or MariaDB
- **Redis** for Celery broker + cache
- **FFmpeg** for transcoding + HLS segmenting
- **Whisper** (optional, for auto-transcription) — local
- **Nginx** in front for static + video delivery
- **Resource**: transcoding CPU-dominated; plan cores + disk. Idle: 1-2 GB RAM. Under transcode load: one core per concurrent job + disk IO.

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker Compose (official bundle)**                               | **Upstream-recommended**                                                           |
| Kubernetes         | Community manifests                                                        | Works; scale transcoders separately                                                                      |
| Bare-metal / VM    | Python + PostgreSQL + Redis + Nginx + FFmpeg                                          | For operators wanting full control                                                                           |
| Managed            | **Elestio one-click** — revenue share with upstream                                                    | Ethical-purchase option                                                                                               |
| GPU transcoding    | Custom FFmpeg builds (CUDA/NVENC)                                                                              | Not first-party-templated; DIY                                                                                                                   |

## Inputs to collect

| Input                | Example                                                 | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `videos.example.com`                                         | URL          | TLS via reverse proxy                                                            |
| DB                   | PostgreSQL (preferred)                                                | DB           | External or bundled                                                                         |
| Redis                | bundled or external                                                   | Cache        | For Celery broker                                                                                           |
| Storage              | Large — plan 10×-50× of original upload size for transcodes                                | Storage      | HLS segments + multiple resolutions                                                                         |
| Admin user           | set via env or `createsuperuser`                                                            | Bootstrap    | Strong password + MFA                                                                                             |
| SAML IdP (opt)       | Keycloak / Authentik / Okta / ADFS                                                          | Auth         | For org deployments                                                                                                                 |
| SMTP                 | for signup confirmations / notifications                                                                      | Email        | Deliverable transactional                                                                                                                                |
| Whisper (opt)        | local model — chooses model size                                                                       | AI           | CPU-heavy or GPU-accelerated                                                                                                                                  |

## Install via Docker Compose

Upstream provides the compose bundle — follow it. High-level services:

- `mediacms` — Django web
- `celery_worker` — transcode worker(s)
- `celery_beat` — scheduler
- `db` — PostgreSQL
- `redis` — cache + broker
- `nginx` — static + video front

Browse → admin → start uploading.

## First boot

1. Log in as superuser → change password
2. Configure basic branding: logo, name, about page
3. Set privacy defaults (public vs private default)
4. Create categories + RBAC groups
5. Enable transcoding profiles appropriate for your audience (disable 1080p if audience is low-bandwidth, enable 4K if you have the hardware)
6. Upload test video → verify all transcodes complete → play back at each resolution
7. Enable Whisper auto-transcription if using
8. Configure SAML SSO for org deploys
9. Put behind TLS reverse proxy
10. **Plan storage growth + retention.** Back up DB + media volumes.

## Data & config layout

- `media_files/` — original + transcoded videos + HLS segments + thumbnails + captions
- PostgreSQL DB — all metadata, users, permissions
- `logo/`, `static/`, custom CSS
- Celery task queue state in Redis (ephemeral)

## Backup

```sh
pg_dump -U mediacms mediacms > mediacms-$(date +%F).sql
sudo tar czf mediacms-media-$(date +%F).tgz media_files/
```

Media volume can be HUGE. Consider:
- Back up originals; re-transcode on restore (saves bulk)
- Or back up originals + compiled-HLS separately; HLS re-buildable from originals

## Upgrade

1. Releases: <https://github.com/mediacms-io/mediacms/releases>. Active.
2. Follow upstream upgrade guide — Django schema migrations.
3. **Back up DB before every upgrade.**
4. Docker: bump tag → `docker compose up` → migrations run.

## Gotchas

- **Transcoding = CPU/disk time sink.** Transcoding a 1080p 10-minute video to all profiles (144-1080p × multiple codecs) = minutes of CPU × storage. Plan:
  - Pin transcode worker to dedicated core(s)
  - Disable profiles you don't need (e.g., 144p on a corporate training portal)
  - Consider GPU (NVENC/QSV) for scale — requires custom FFmpeg in image
- **Storage blowup**: one 4K video = multiple transcodes + HLS segments per resolution = 3-5× original size in media volume. Calculate before promising user quotas.
- **Chunked uploads + nginx timeouts**: large uploads fail on default nginx `client_max_body_size` + timeouts. Tune reverse-proxy + Django settings. Documented by upstream.
- **Default admin password / URL**: change on day zero. Standard batch-68+ reflex.
- **Celery broker = Redis (or RabbitMQ)**: both support; Redis simpler. If Redis goes down mid-transcode, jobs can fail ungracefully. Redis persistence recommended.
- **Whisper auto-transcription**: local model = privacy + cost-free but CPU/GPU-heavy. Pick model size matching your workload. Accuracy varies by language + speaker.
- **SAML integration**: documented but each IdP (Keycloak/Authentik/Okta) has its own quirks. Test with dev IdP first.
- **Public portal = abuse surface**: open registration + public uploads = spam/abuse risk. Enable moderation queue, invite-only, or SSO-only for org deployments.
- **Copyright exposure**: if users can publicly upload to your MediaCMS, DMCA takedown process + abuse policy are YOUR responsibility. Publish terms; offer abuse@ email.
- **Commercial hosting**: Elestio option directly funds MediaCMS via revenue share. Good ethical-purchase path (pattern: WriteFreely→Write.as, Rallly→rallly.co).
- **Scaling**: single-node fine to 100s of videos, 10s of concurrent viewers. Beyond, separate transcode workers + CDN in front of HLS segments.
- **CDN for HLS**: putting Cloudflare / BunnyCDN in front of HLS segments massively reduces bandwidth cost at scale.
- **License**: **AGPL-3.0**. Public-hosted modifications = publish source.
- **Project health**: Markos Gogoulos-led; active releases; commercial services support sustainability.
- **Alternatives worth knowing:**
  - **PeerTube** — federated video platform; ActivityPub; decentralized
  - **Jellyfin** (batch earlier) — media server; personal-library focus; not a CMS
  - **Owncast** — live streaming focused
  - **Plex** — media server; commercial
  - **Kaltura** — enterprise video platform (commercial)
  - **Choose MediaCMS if:** you want a full video CMS + public portal + transcoding + modern UI + non-federated.
  - **Choose PeerTube if:** you want federation (fediverse video).
  - **Choose Jellyfin if:** personal media library, not public portal.

## Links

- Repo: <https://github.com/mediacms-io/mediacms>
- Homepage: <https://mediacms.io>
- Demo: <https://demo.mediacms.io>
- Services: <https://mediacms.io/#services/>
- Docker Hub: <https://hub.docker.com/r/mediacms/mediacms>
- Releases: <https://github.com/mediacms-io/mediacms/releases>
- Elestio managed: <https://elest.io/open-source/mediacms>
- PeerTube (federated alt): <https://joinpeertube.org>
- Jellyfin (media-server alt): <https://jellyfin.org>
- Owncast (live-stream alt): <https://owncast.online>

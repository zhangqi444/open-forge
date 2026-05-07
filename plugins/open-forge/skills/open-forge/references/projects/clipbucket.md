# ClipBucket

**Self-hosted video sharing platform** — YouTube/Netflix clone in PHP. Users can upload, share, and stream videos; create playlists and collections; send friend requests; exchange private messages. Supports photo sharing alongside video. Actively maintained fork of the original ClipBucket project.

**Official site:** https://clipbucket.fr  
**Source:** https://github.com/MacWarrior/clipbucket-v5  
**Docker Hub:** https://hub.docker.com/r/oxygenz/clipbucket-v5  
**Demo:** https://demo.clipbucket.oxygenz.fr/  
**License:** AAL

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker | All-in-one container (PHP + MySQL bundled) |
| Linux | PHP + MySQL/MariaDB + web server | Native install |

---

## System Requirements

- PHP 8.1–8.5+
- MySQL 9+ or MariaDB (strict mode compatible)
- Web server (Apache/nginx)
- ffmpeg (for video processing/transcoding)

---

## Inputs to Collect

| Input | Description | Default |
|-------|-------------|---------|
| `DOMAIN_NAME` | Domain name for the instance | `clipbucket.local` |
| `MYSQL_PASSWORD` | Root MySQL password | — (required) |
| `UID` / `GID` | Host user/group IDs (for bind mounts) | `1000` / `1000` |
| `HTTP_PORT` | External port | `80` |

---

## Software-layer Concerns

### Docker (recommended)
```bash
docker run \
  --restart unless-stopped \
  --pull=always \
  -e DOMAIN_NAME=your-domain.com \
  -e MYSQL_PASSWORD=strong_password \
  -e UID=1000 \
  -e GID=1000 \
  -v clipbucket_db:/var/lib/mysql \
  -v clipbucket_files:/srv/http/clipbucket \
  -p 80:80 \
  --name clipbucket \
  -d oxygenz/clipbucket-v5:latest
```

Access at `http://localhost` then follow the web installer.

### Docker Compose
```yaml
services:
  clipbucket:
    image: oxygenz/clipbucket-v5:latest
    ports:
      - '80:80'
    environment:
      - DOMAIN_NAME=your-domain.com
      - MYSQL_PASSWORD=strong_password
      - UID=1000
      - GID=1000
    volumes:
      - clipbucket_db:/var/lib/mysql
      - clipbucket_files:/srv/http/clipbucket
    restart: unless-stopped

volumes:
  clipbucket_db:
  clipbucket_files:
```

### Persistent volumes
| Volume | Purpose |
|--------|---------|
| `/var/lib/mysql` | MySQL database |
| `/srv/http/clipbucket` | Application files, uploads, videos |

### Note on UID/GID
- **Named Docker volumes:** UID/GID not needed — Docker manages permissions.
- **Bind mounts:** Set UID/GID to match the host user to avoid permission issues.

### Features
- Video upload, streaming, and transcoding
- Photo gallery sharing
- User accounts, friend requests, private messages
- Playlists and collections
- TMDB integration for metadata
- AI NSFW content detection
- Dark/light theme
- Multilingual (EN, FR, DE, PT, ES)
- Integrated DB update system

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```
Database migrations run automatically. Check the [changelog](https://github.com/MacWarrior/clipbucket-v5/releases) for manual steps.

---

## Gotchas

- **`DOMAIN_NAME` must match your actual domain.** It's used for video URLs, embeds, and the web installer. Set it correctly before first run.
- **ffmpeg is bundled in the Docker image.** Native installs require ffmpeg on the host for video processing.
- **AAL license** (Attribution Assurance License) requires attribution in the UI. Review license terms before white-labeling.
- **MySQL strict mode** is supported from v5.5.0+.
- **ClipBucket original** (arslancb/clipbucket) is archived. This is the maintained V5 fork by MacWarrior/Oxygenz.

---

## References

- Upstream README: https://github.com/MacWarrior/clipbucket-v5#readme
- Demo: https://demo.clipbucket.oxygenz.fr/
- Official site: https://clipbucket.fr

# GoMFT

**Self-hosted web-based managed file transfer application — schedule and monitor file transfers across cloud storage, SFTP, FTP, SMB, S3, WebDAV, and more, powered by rclone.**
Docs: https://starfleetcptn.github.io/GoMFT/
GitHub: https://github.com/StarFleetCPTN/GoMFT
Discord: https://discord.gg/f9dwtM3j

> ⚠️ Actively under development — configurations and database fields may change between releases. Review release notes before upgrading.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any | Go binary | Requires Go 1.21+, rclone, SQLite |

---

## Inputs to Collect

### Required
- `TZ` — timezone (e.g. `America/New_York`)
- `UID` / `GID` — host user IDs for volume permissions (default: 1000)

### Optional
- Notification credentials (SMTP, ntfy, Gotify, Pushbullet, Pushover, webhook) — configured in UI

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  gomft:
    image: starfleetcptn/gomft:latest
    container_name: gomft
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - gomft-data:/app/data
      - gomft-backups:/app/backups
    environment:
      - TZ=UTC
      - DATA_DIR=/app/data
      - BACKUP_DIR=/app/backups
      - LOGS_DIR=/app/data/logs
    user: "1000:1000"   # match your host UID:GID

volumes:
  gomft-data:
  gomft-backups:
```

> The repo's `docker-compose.yaml` builds from source. Use `image: starfleetcptn/gomft:latest` for the pre-built image.

### Ports
- `8080` — web UI

### Supported storage providers (via rclone)
Google Drive, Google Photos, Amazon S3, MinIO, Nextcloud, WebDAV, SFTP, FTP, SMB/CIFS, Hetzner Storage Box, Backblaze B2, Wasabi, local filesystem, and all other rclone backends.

### Key features
- Schedule transfers with cron expressions
- Real-time transfer monitoring and detailed logs
- File metadata tracking (hash, size, status, history)
- Webhook notifications (HMAC-SHA256, custom headers)
- Email, Pushbullet, ntfy, Gotify, Pushover notifications
- Configurable message templates for all notification types
- Event-based triggers (start, completion, errors)

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d
3. Review release notes for schema changes before upgrading

---

## Gotchas

- Rapid development — database/config structures may change between releases; always read release notes
- `user:` in compose must match UID:GID that owns the mounted volumes
- rclone is bundled in the Docker image — no separate rclone install needed

---

## References
- Documentation: https://starfleetcptn.github.io/GoMFT/
- GitHub: https://github.com/StarFleetCPTN/GoMFT#readme

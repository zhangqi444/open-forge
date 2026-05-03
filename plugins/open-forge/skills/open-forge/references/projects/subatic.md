# Subatic

> Simple, straightforward self-hosted video sharing platform. Upload videos, transcode them via a separate transcoder service, store originals and processed output in S3-compatible buckets, and serve at near-zero streaming cost. Architecture cuts streaming costs 99%+ vs traditional CDN by leveraging S3 public access + optional Cloudflare R2 caching.

**Official URL:** https://github.com/orthdron/subatic

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Primary method; includes Subatic + Transcoder + MinIO + PostgreSQL |
| Any Linux VPS/VM | Docker Compose + external S3 | Replace MinIO with AWS S3 / Cloudflare R2 / Backblaze B2 |

---

## Inputs to Collect

### Phase: Pre-Deploy (Subatic app)
| Input | Description | Example |
|-------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres://user:pass@db:5432/subatic` |
| `RAWFILES_S3_ACCESS_KEY_ID` | S3 key for raw (upload) bucket | `AKIAIOSFODNN7EXAMPLE` |
| `RAWFILES_S3_SECRET_ACCESS_KEY` | S3 secret for raw bucket | secret |
| `RAWFILES_S3_REGION` | Raw bucket region | `us-east-1` |
| `RAWFILES_S3_BUCKET` | Raw bucket name | `subatic-raw` |
| `RAWFILES_S3_ENDPOINT` | S3-compatible endpoint | `http://minio:9000` or `https://s3.amazonaws.com` |
| `MAX_FILE_SIZE` | Max upload size in MB | `500` |
| `PROCESSED_VIDEO_URL` | Public URL of the processed/output bucket | `https://your-public-bucket.r2.dev` |
| `WEBHOOK_TOKEN` | Shared secret between app and transcoder | random string |

### Phase: Pre-Deploy (Transcoder)
| Input | Description | Example |
|-------|-------------|---------|
| `RAWFILES_S3_*` | Same raw bucket credentials as above | (same) |
| `PROCESSED_S3_ACCESS_KEY_ID` | S3 key for processed (output) bucket | `AKIAIOSFODNN7EXAMPLE` |
| `PROCESSED_S3_SECRET_ACCESS_KEY` | S3 secret for processed bucket | secret |
| `PROCESSED_S3_REGION` | Processed bucket region | `us-east-1` |
| `PROCESSED_S3_BUCKET` | Processed bucket name | `subatic-processed` |
| `PROCESSED_S3_ENDPOINT` | Processed bucket endpoint | `https://your-r2-endpoint` |
| `WEBHOOK_URL` | URL of Subatic app webhook | `http://subatic:3000/` |
| `WEBHOOK_TOKEN` | Same shared secret as above | (same) |
| `SQS_ENABLED` | Enable AWS SQS for job queue | `false` (or `true` + `SQS_URL`) |
| `MARK_FAILED_AFTER` | Seconds before marking stuck jobs failed | `600` |

### Phase: MinIO (if not using external S3)
| Input | Description |
|-------|-------------|
| `MINIO_ACCESS_KEY` | MinIO access key |
| `MINIO_SECRET_KEY` | MinIO secret key |

### Phase: PostgreSQL
| Input | Description |
|-------|-------------|
| `POSTGRES_USER` | DB username |
| `POSTGRES_PASSWORD` | DB password |

---

## Software-Layer Concerns

### Architecture
Two services must run together:
1. **Subatic** — the web app (upload UI, video listing, webhook receiver)
2. **Subatic Transcoder** — separate service that transcodes uploaded videos and pushes to processed S3 bucket

Videos flow: user uploads → raw S3 bucket → transcoder pulls → transcodes → pushes to processed S3 bucket → Subatic webhook notified → video goes live.

### Data Directories
All state in PostgreSQL + S3 buckets. No local bind mounts needed beyond `.env`.

### Buckets
- **Raw bucket** — private; used for upload staging; accessed only by app + transcoder
- **Processed bucket** — **public**; connected to a domain/CDN for video delivery; CORS required for R2

### Cloudflare R2 CORS (if used)
```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["range"],
    "ExposeHeaders": ["Content-Type", "Access-Control-Allow-Origin", "ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

### Ports
| Service | Port |
|---------|------|
| Subatic web app | `3000` |
| MinIO console | `9001` |
| MinIO API | `9000` |

---

## Upgrade Procedure

1. Pull latest images: `docker compose pull`
2. `docker compose down`
3. `docker compose up -d`
4. Check both Subatic and Transcoder logs: `docker compose logs -f`

---

## Gotchas

- **Two S3 buckets** — raw (private, for uploads) and processed (public, for delivery) may be the same bucket if public, but separating them is cleaner for permissions
- **Processed bucket must be public** — videos are served directly from S3/R2; Subatic just stores the URL, not the bytes
- **`WEBHOOK_TOKEN` must match** — if app and transcoder have different tokens, transcoding notifications silently fail and videos never go live
- **SQS optional** — without SQS, the transcoder polls for new jobs; enabling SQS (`SQS_ENABLED=true`) adds push-based job delivery but requires an AWS SQS queue
- **Analytics optional** — Umami, Plausible, and Google Analytics integrations are all opt-in via env vars; leave them unset to disable
- **Transcoder repo is separate** — see https://github.com/orthdron/subatic-transcoding for the transcoder image and config

---

## Links
- GitHub (app): https://github.com/orthdron/subatic
- GitHub (transcoder): https://github.com/orthdron/subatic-transcoding
- README: https://github.com/orthdron/subatic#readme

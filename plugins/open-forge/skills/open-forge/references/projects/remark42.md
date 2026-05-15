---
name: remark42
description: remark42 recipe for open-forge. Lightweight, privacy-respecting comment engine — embed in any website, no user tracking. Docker install. Upstream: https://github.com/umputun/remark42
---

# remark42

Lightweight, self-hosted comment engine that doesn't spy on users. Embed in blogs, articles, or any static site. Supports social login, anonymous comments, email notifications, moderation, and import from Disqus.

5,484 stars · MIT

Upstream: https://github.com/umputun/remark42
Website: https://remark42.com/
Docs: https://remark42.com/docs/
Demo: https://remark42.com/demo/
Docker Hub: https://hub.docker.com/r/umputun/remark42

## What it is

remark42 provides a full comment system for static and dynamic websites:

- **No tracking** — No ads, no analytics, no user profiling
- **Social login** — Google, GitHub, Facebook, Twitter/X, Microsoft, Yandex, Apple, Patreon, Telegram, email
- **Anonymous comments** — Optional guest commenting without login
- **Moderation** — Admin approval queue, ban users, pin/unpin comments, restrict comment period
- **Notifications** — Email notifications for comment replies (SMTP required)
- **Telegram notifications** — Push admin alerts to a Telegram bot
- **Voting** — Up/down vote comments (configurable)
- **Markdown support** — Full Markdown in comment text
- **Import** — Import existing comments from Disqus, WordPress, Commento
- **Multi-site** — Single remark42 instance can serve multiple sites (different SITE IDs)
- **Read-only mode** — Lock old posts for commenting
- **Image proxy** — Optionally proxy user avatars through your server
- **Lightweight** — Single Go binary, SQLite storage, minimal resources

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Single container | Recommended; official image |
| Docker Compose | With reverse proxy | Add Nginx/Traefik in front |
| Bare metal | Go binary | Single binary, no external DB needed |

## Inputs to collect

### Phase 1 — Pre-install
- Public URL where remark42 will be served (REMARK_URL)
- Site ID(s) — arbitrary string matching what you embed in your site HTML
- Secret key — random string for JWT signing
- Admin user IDs — comma-separated list of user IDs to grant admin access

### Phase 2 — Authentication (at least one required)
- Google OAuth: client ID + secret
- GitHub OAuth: client ID + secret
- Facebook OAuth: client ID + secret
- Email auth: SMTP credentials (host, port, user, password, from address)
- Telegram auth: bot token

### Phase 3 — Optional
- SMTP for email notifications
- Telegram bot token for admin notifications
- Admin password (for basic admin access without OAuth)

## Software-layer concerns

### Config paths
- /srv/var/ — data directory (BoltDB/SQLite storage, backups, images); mount as volume

### Key environment variables
  REMARK_URL=https://comments.example.com
  SECRET=<random-64-char-string>
  SITE=my-blog                          # matches site_id in embed JS
  AUTH_GOOGLE_CID=<google-client-id>
  AUTH_GOOGLE_CSEC=<google-client-secret>
  AUTH_GITHUB_CID=<github-client-id>
  AUTH_GITHUB_CSEC=<github-client-secret>
  AUTH_EMAIL_ENABLE=true
  SMTP_HOST=smtp.example.com
  SMTP_PORT=465
  SMTP_USERNAME=user@example.com
  SMTP_PASSWORD=<password>
  SMTP_TLS=true
  NOTIFY_EMAIL_FROM=noreply@example.com
  ADMIN_SHARED_ID=<your-user-id>       # get from /auth/<provider>/callback
  DEBUG=false

### Embedding in your site
After deploy, add to each page:
  <script>
    var remark_config = {
      host: 'https://comments.example.com',
      site_id: 'my-blog',
    };
  </script>
  <script defer src="https://comments.example.com/web/embed.js"></script>
  <div id="remark42"></div>

### Port
Container exposes 8080 internally. Use reverse proxy for HTTPS.

## Docker Compose install

  version: "2"
  services:
    remark42:
      image: ghcr.io/umputun/remark42:v1.15.0
      container_name: remark42
      restart: always
      environment:
        - REMARK_URL=https://comments.example.com
        - SECRET=<your-secret>
        - SITE=my-site
        - AUTH_GITHUB_CID=<github-client-id>
        - AUTH_GITHUB_CSEC=<github-client-secret>
        - ADMIN_SHARED_ID=<admin-user-id>
      volumes:
        - ./var:/srv/var
      # Expose via reverse proxy:
      # ports:
      #   - "8080:8080"

Add Nginx/Traefik in front for HTTPS (required for OAuth callbacks).

## Upgrade procedure

1. Pull new image: docker pull ghcr.io/umputun/remark42:v1.15.0
2. Stop: docker compose stop remark42
3. Start: docker compose up -d remark42
4. Verify backup in ./var/backup/ was created on startup (auto-backup on version change)
5. Check logs: docker compose logs remark42

## Gotchas

- REMARK_URL must be exact — OAuth redirect URIs must match; include trailing slash or not consistently
- OAuth redirect URLs — register <REMARK_URL>/auth/<provider>/callback in each OAuth app
- Admin user ID discovery — start without ADMIN_SHARED_ID, log in once, check logs for "user id" to get your ID
- HTTPS required for OAuth — Google/GitHub/Facebook require HTTPS callback URLs; must use reverse proxy with SSL
- Multi-site — use comma-separated SITE values; embed JS uses matching site_id
- Email notifications vs auth — AUTH_EMAIL_ENABLE and SMTP are separate; email auth allows login-by-email; SMTP also needed for reply notifications
- BoltDB storage — single file per site in /srv/var/; back up this directory regularly
- Comment import — use /api/v1/admin/import endpoint or admin UI to import from Disqus JSON export
- Rate limiting — built-in rate limiting on comment submission; configurable

## Links

- Upstream README: https://github.com/umputun/remark42/blob/master/README.md
- Self-hosting docs: https://remark42.com/docs/getting-started/installation/
- Configuration reference: https://remark42.com/docs/configuration/parameters/
- Demo: https://remark42.com/demo/

---
name: Papermark
description: "Open-source DocSend alternative — secure document sharing with built-in analytics (views, time-per-page, geo) and custom branding/domains. PDFs, decks, videos. Next.js + Postgres + Prisma + Tinybird analytics + Resend email + Stripe. AGPL-3.0."
---

# Papermark

Papermark is the OSS alternative to DocSend — **secure document sharing with analytics**. Upload a PDF (or pitch deck, or video), get a shareable link with optional password / email gate, and see who viewed it, which pages, how long they stayed. Built for fundraising decks, sales collateral, investor reports, legal docs, NDAs-before-the-send, — any doc where "who looked at what, for how long?" matters.

Features:

- **Shareable links** — unique URLs per recipient; revoke/expire anytime
- **Custom branding** — logo, colors, custom domain per workspace
- **Analytics** — views, time per page, geo (IP-based), completion rate
- **Access gates**: email capture, passphrase, verified email, NDA acceptance, allowlist by domain
- **Multi-version** — upload new versions; previous links update automatically
- **Preview modes**: PDFs, images, videos, slide decks, spreadsheets, Notion-style docs
- **Downloads** — enable/disable per link
- **Watermarking** (planned / paid tier)
- **Team collaboration** — workspaces, multi-user
- **API** for automation
- **Papermark Free/Pro/Business/Enterprise** — hosted tiers; self-host is full-featured

- Upstream repo: <https://github.com/papermark/papermark>
- Website: <https://www.papermark.com>
- Docs: <https://www.papermark.com/docs> (if available; minimal at time of writing)
- Docker / install guides at upstream
- Discord: link in README

## Architecture in one minute

- **Next.js 14+** (full-stack)
- **TypeScript** + Tailwind + shadcn/ui
- **Prisma ORM** + **Postgres**
- **NextAuth.js** — authentication (email magic links, Google OAuth, etc.)
- **Tinybird** — analytics events pipeline (serverless ClickHouse; cloud service)
- **Resend** — transactional email (cloud service)
- **Stripe** — payments/subscriptions for the hosted tier
- **Mux** / **Cloudflare Stream** (optional) — video hosting
- **AWS S3 / R2 / Supabase Storage** — PDF + file storage

**Heavy on cloud dependencies** — Tinybird + Resend + Stripe are all external SaaS. Self-hosting Papermark without these means: limited analytics, limited email, no payments. Plan accordingly.

## Compatible install methods

| Infra       | Runtime                                                | Notes                                                          |
| ----------- | ------------------------------------------------------ | -------------------------------------------------------------- |
| Single VM   | Docker (community or build-your-own)                       | Self-host guides in repo                                            |
| Vercel      | **Official deployment target** (push-to-deploy)             | Matches the tech stack; managed Postgres via Neon/Supabase                |
| Managed     | Papermark Cloud (`papermark.com`)                              | Easiest; supports project                                                       |
| Kubernetes  | DIY                                                              | No official chart                                                                        |

## Inputs to collect

| Input             | Example                         | Phase     | Notes                                                              |
| ----------------- | ------------------------------- | --------- | ------------------------------------------------------------------ |
| Domain            | `docs.example.com`                | URL       | `NEXTAUTH_URL` must match                                             |
| Postgres          | creds                                 | DB        | Use managed (Neon, Supabase, RDS) for less ops                                  |
| S3-compatible     | bucket + creds                            | Storage   | For uploaded PDFs                                                                           |
| Resend API key    | from <https://resend.com>                   | Email     | Or alt: fall back to plain SMTP (check .env options)                                                 |
| Tinybird API key  | from <https://www.tinybird.co>                | Analytics | **Optional but core feature depends on it**                                                                      |
| Google OAuth creds  | from Google Console                          | Auth      | For Google login                                                                                                        |
| NEXTAUTH_SECRET   | random 32 chars                                   | Auth      | Don't rotate after deployment                                                                                                          |
| Stripe keys (opt) | if you want paid tiers                              | Billing   | Mostly for multi-tenant SaaS re-hosters                                                                                                            |

## Install via Docker (community)

Check repo for current Dockerfile / compose. A minimal stack:

```yaml
services:
  papermark:
    build: .
    container_name: papermark
    restart: unless-stopped
    depends_on: [db]
    ports:
      - "3000:3000"
    env_file: .env
    environment:
      DATABASE_URL: postgresql://papermark:<strong>@db/papermark
      NEXTAUTH_URL: https://docs.example.com
      NEXTAUTH_SECRET: <random-32-chars>
      # Storage
      STORAGE_ACCESS_KEY: ...
      STORAGE_SECRET_KEY: ...
      STORAGE_BUCKET: papermark-uploads
      STORAGE_ENDPOINT: https://s3.amazonaws.com
      # Email
      RESEND_API_KEY: ...
      # Analytics (optional)
      TINYBIRD_TOKEN: ...
      TINYBIRD_BASE_URL: https://api.tinybird.co
      # Auth providers
      GOOGLE_CLIENT_ID: ...
      GOOGLE_CLIENT_SECRET: ...

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: papermark
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: papermark
    volumes:
      - papermark-db:/var/lib/postgresql/data

volumes:
  papermark-db:
```

## Install via Vercel

1. Fork the repo
2. Connect to Vercel
3. Attach Neon/Supabase Postgres
4. Attach environment variables (NEXTAUTH_*, STORAGE_*, RESEND_API_KEY, TINYBIRD_TOKEN)
5. Deploy — matches the upstream + cloud stack perfectly

## First boot

1. Visit site → sign up (email magic link or Google OAuth)
2. Create team/workspace
3. Upload first PDF → get shareable link
4. Configure link settings:
   - Require email to view (lead-gen)
   - Passphrase
   - Expiration
   - Disable download
5. Share link → analytics populate as views happen
6. (Optional) Add custom domain + branding in Settings

## Data & config layout

- Postgres — users, teams, documents metadata, links, permissions
- S3 — PDF files, thumbnails
- Tinybird — analytics events (if configured)
- `.env` — all secrets

## Backup

```sh
# DB (CRITICAL)
pg_dump -U papermark papermark | gzip > papermark-$(date +%F).sql.gz

# S3 bucket backup: use aws s3 sync or rclone
aws s3 sync s3://papermark-uploads /backups/papermark-files/
```

Tinybird analytics events: external service; check Tinybird's retention + export.

## Upgrade

1. Releases: <https://github.com/papermark/papermark/releases>
2. Git-pull-and-build (Vercel handles; Docker = rebuild)
3. **Back up DB first** — schema migrations via Prisma
4. `npx prisma migrate deploy` before starting new version

## Gotchas

- **External-SaaS-heavy** — upstream's reference stack assumes Resend, Tinybird, Stripe, Vercel-hosted. Fully local self-host requires:
  - Swap Resend for SMTP (may require code changes beyond env)
  - Disable or swap Tinybird analytics — core tracking loses richness
  - Remove Stripe (if not needed; community edition doesn't require it for you, only if re-selling)
- **PDF rendering**: Papermark uses client-side + server-side PDF processing. Large PDFs stress the browser; break into smaller files for best UX.
- **"Built for fundraising" DNA** — many features (email gating, NDA acceptance, watermarks) target VC-deck use case. If you just want "share PDF privately," it's more than you need; something lighter (Nextcloud Files, Filegator) may suffice.
- **Analytics accuracy depends on JS execution** — recipients who disable JS or use ad-blockers generate fewer events. Tinybird handles the pipeline cleanly; self-hosted replacement analytics require Tinybird alternatives (self-hosted ClickHouse + event forwarder).
- **Geo-IP analytics** use cloud geo DB (MaxMind or similar) — self-hosting that requires licensing. Check current implementation.
- **Custom domains** — each workspace can have its own domain (e.g., `docs.acme.com` pointing at Papermark). DNS + TLS automation is handled by NextAuth + Let's Encrypt when deployed on Vercel; on Docker you manage TLS certs yourself.
- **Multi-tenant concerns**: Papermark is designed to isolate workspaces. Ensure RLS / Prisma queries scope by workspace; audit before multi-tenanting for external customers.
- **GDPR on viewer emails**: email gating = PII collection. Papermark doesn't auto-handle consent/DSAR. Add a Privacy page yourself.
- **NDA acceptance** — records "yes I accept NDA" but doesn't provide legal-grade e-signature with audit trail. For binding NDAs, use DocuSign / HelloSign and share only AFTER NDA is signed externally.
- **Video handling** — if you enable video uploads, processing is heavy. Use Mux/Cloudflare Stream or similar; don't try to self-host video transcoding unless you want to.
- **Watermarking + DRM** — watermarking is paid/planned; DRM is not supported (view-only but right-click save still works in practice).
- **Link revocation**: cached PDFs in the viewer's browser remain until purged. Revocation prevents new access but doesn't delete existing copies.
- **Papermark Cloud** is the upstream's hosted SaaS; reasonable if you want "features + managed."
- **AGPL-3.0** — strong copyleft; hosting a fork for customers = source disclosure.
- **Active development** — Papermark iterates quickly; read release notes for breaking env changes.
- **Mobile**: responsive web; PDF viewing on phones is OK but deck presentations look best on desktop.
- **Alternatives worth knowing:**
  - **DocSend (Dropbox)** — commercial; the product being cloned
  - **Vidyard / Loom** — video-share-with-analytics (narrower scope)
  - **Seismic / Highspot** — enterprise sales enablement; different scale
  - **Dotwrld / DocSign-like tools** — niche
  - **Nextcloud Files + share-by-link** — general file share; no view analytics
  - **Seafile + external access** — similar
  - **Choose Papermark if:** you want an OSS DocSend-alternative with analytics for decks/PDFs.
  - **Choose Nextcloud if:** you just need private file sharing and don't care about view analytics.

## Links

- Repo: <https://github.com/papermark/papermark>
- Website: <https://www.papermark.com>
- Docs: <https://www.papermark.com/docs>
- Self-host guide (in repo): <https://github.com/papermark/papermark#getting-started>
- Releases: <https://github.com/papermark/papermark/releases>
- Twitter: <https://twitter.com/papermarkio>
- Tinybird: <https://www.tinybird.co>
- Resend: <https://resend.com>
- Prisma: <https://www.prisma.io>
- Product Hunt launch: <https://www.producthunt.com/posts/papermark-3>

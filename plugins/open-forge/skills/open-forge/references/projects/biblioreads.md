---
name: biblioreads-project
description: BiblioReads recipe for open-forge. Covers Docker CLI and Docker Compose deployment of this privacy-focused alternative Goodreads frontend. Based on upstream README and .env.local.example at https://github.com/nesaku/BiblioReads.
---

# BiblioReads

Privacy-focused alternative frontend for Goodreads. Scrapes and proxies Goodreads content — no ads, no tracking, no account required. Built with Next.js. Upstream: <https://github.com/nesaku/BiblioReads>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host / VPS | Docker (single container) | Image `nesaku/biblioreads:latest` |
| Any Linux host / VPS | Docker Compose | Compose file from upstream Docker image repo |
| Vercel / Netlify / Cloudflare Pages | Serverless | Upstream's own public instance runs on Vercel |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| deploy | "Public URL for your BiblioReads instance (no trailing slash)?" | URL | Sets `NEXT_PUBLIC_HOST_URL` — required |
| identity | "Instance operator name (optional)?" | Free-text | Sets `NEXT_PUBLIC_INSTANCE_OPERATOR_NAME`; shown in instance list |
| identity | "Instance operator link (optional)?" | URL | Sets `NEXT_PUBLIC_INSTANCE_OPERATOR_LINK` |
| identity | "Hosting provider name (optional)?" | Free-text | Sets `NEXT_PUBLIC_INSTANCE_PROVIDER` |
| privacy | "Does your instance collect any user data?" | Yes / No | If Yes, fill out the `NEXT_PUBLIC_INSTANCE_*_DATA` vars and set `NEXT_PUBLIC_INSTANCE_CUSTOM_PRIVACY=true` |
| user-agent | "Custom User-Agent string to use when scraping Goodreads?" | Free-text | Sets `NEXT_PUBLIC_USER_AGENT`; recommended to set for polite scraping |

## Software-layer concerns

### Environment variables (from upstream `.env.local.example`)

| Variable | Required | Description |
|---|---|---|
| `NEXT_PUBLIC_HOST_URL` | ✅ | Full public URL of the instance, no trailing slash |
| `NEXT_PUBLIC_USER_AGENT` | Recommended | UA string sent to Goodreads when scraping |
| `NEXT_PUBLIC_INSTANCE_OPERATOR_NAME` | Recommended | Your name / handle for the instance list |
| `NEXT_PUBLIC_INSTANCE_OPERATOR_LINK` | Recommended | Link to your profile or site |
| `NEXT_PUBLIC_INSTANCE_PROVIDER` | Optional | Hosting provider name |
| `NEXT_PUBLIC_INSTANCE_COUNTRY` | Optional | Country code |
| `NEXT_PUBLIC_INSTANCE_CLOUDFLARE` | Optional | `true` if behind Cloudflare |
| `NEXT_PUBLIC_INSTANCE_CUSTOM_PRIVACY` | Optional | `true` if you collect any user data |
| `NEXT_PUBLIC_INSTANCE_PRIVACY_POLICY_URL` | Optional | URL to your privacy policy |
| `NEXT_TELEMETRY_DISABLED` | Optional | Set `1` to disable Next.js telemetry |

### Docker CLI (from upstream README)

```bash
docker run -d \
  --name biblioreads \
  -p 3000:3000 \
  --restart unless-stopped \
  nesaku/biblioreads:latest
```

Pass environment variables with `-e NEXT_PUBLIC_HOST_URL=https://your-instance.example.com` etc.

### Docker Compose

Upstream Docker Compose is in the separate [BiblioReads-Docker](https://github.com/nesaku/BiblioReads-Docker) repo. Basic pattern:

```yaml
services:
  biblioreads:
    image: nesaku/biblioreads:latest
    container_name: biblioreads
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_HOST_URL=https://your-instance.example.com
      - NEXT_PUBLIC_USER_AGENT=Mozilla/5.0 ...
      - NEXT_TELEMETRY_DISABLED=1
```

## Upgrade procedure

```bash
docker pull nesaku/biblioreads:latest
docker compose up -d   # or docker stop/rm + docker run
```

## Gotchas

- BiblioReads is a **scraper** — if Goodreads changes its HTML structure, content display may break until upstream publishes a fix.
- No persistent data storage: the container is stateless. No database or volume needed.
- `NEXT_PUBLIC_HOST_URL` is baked into the Next.js build at image build time for some public vars; if running from the pre-built image, set it as an env var at runtime (Next.js runtime config handles it).
- Do **not** use this for automation or bulk scraping — it proxies individual user requests, not mass data extraction. Aggressive use may get your server IP rate-limited by Goodreads.
- For public instances: if you collect page-view or device data, you must set the `NEXT_PUBLIC_INSTANCE_*_DATA` privacy disclosure variables.
- Default port `3000`; put behind a reverse proxy with TLS for public deployments.

## Links

- Upstream repo: <https://github.com/nesaku/BiblioReads>
- Docker image: <https://hub.docker.com/r/nesaku/biblioreads>
- Docker Compose repo: <https://github.com/nesaku/BiblioReads-Docker>
- Public instances list: <https://github.com/nesaku/BiblioReads#instances>

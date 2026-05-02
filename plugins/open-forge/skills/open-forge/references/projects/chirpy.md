# Chirpy

**Privacy-friendly, customizable comment system — a self-hosted Disqus alternative.**

- **Official site:** https://chirpy.dev
- **GitHub:** https://github.com/devrsi0n/chirpy
- **License:** AGPL-3.0

## What It Is

Chirpy is a drop-in comment widget for any website. Unlike Disqus it collects no third-party tracking data, supports anonymous sign-in, and lets you fully brand the widget to match your site's theme.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS/VM | Docker Compose | Primary deployment path |
| Vercel | Hosted | Official PaaS option (no self-hosting required) |

## Inputs to Collect

### All phases
- Domain / public URL for the widget endpoint
- OAuth provider credentials (GitHub, Google, or magic-link email)
- SMTP credentials (for email notifications)
- Database connection string (PostgreSQL)

## Software-Layer Concerns

- **Stack:** Next.js + tRPC + Prisma + PostgreSQL + TailwindCSS
- **Auth:** next-auth — supports GitHub OAuth, Google OAuth, and magic-link email
- **Analytics:** Tinybird integration (optional) for widget analytics
- **Config:** environment variables via `.env` file
- **Data:** PostgreSQL — managed via Prisma migrations (`prisma migrate deploy`)

### Key environment variables
```
DATABASE_URL=postgresql://user:pass@host:5432/chirpy
NEXTAUTH_URL=https://chirpy.example.com
NEXTAUTH_SECRET=<random 32-char string>
GITHUB_CLIENT_ID / GITHUB_CLIENT_SECRET  (if using GitHub OAuth)
SMTP_HOST / SMTP_PORT / SMTP_USER / SMTP_PASS  (email notifications)
```

## Upgrade Procedure

1. Pull the new image: `docker compose pull`
2. Run migrations: `docker compose run --rm app npx prisma migrate deploy`
3. Restart: `docker compose up -d`
4. Verify widget loads on your test page

## Gotchas

- **Database required:** Chirpy needs a live PostgreSQL instance — SQLite is not supported
- **OAuth setup:** You must register an OAuth app with at least one provider before first launch; magic-link email is the fallback if no OAuth is configured
- **NEXTAUTH_SECRET** must be a strong random value — used to sign JWTs; rotate carefully (all sessions invalidated)
- **Vercel alternative:** The project's own hosted service at chirpy.dev eliminates the self-hosting burden entirely if data sovereignty is not a requirement

## References

- README: https://github.com/devrsi0n/chirpy/blob/main/README.md
- Docs: https://chirpy.dev/docs
- Playground: https://chirpy.dev/play

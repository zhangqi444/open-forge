---
name: briefkasten
description: Briefkasten recipe for open-forge. Modern self-hosted bookmark manager with browser extension, full-text search, categories/tags, REST API, and OAuth login. Source: https://github.com/ndom91/briefkasten
---

# Briefkasten

Modern self-hosted bookmarking application. Saves links with automatic title/description extraction, supports categories, tags, full-text search, import/export of standard bookmark HTML, and a browser extension. Works with any Prisma-compatible database (MySQL, PostgreSQL, SQLite). Upstream: https://github.com/ndom91/briefkasten. Docs: https://docs.briefkastenhq.com.

Note: Briefkasten v2 (codebase: ndom91/sveltekasten) is in active development and will supersede v1. v1 is still functional but new installs should monitor v2 progress.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Vercel / Netlify deploy | Node.js (Next.js) | Easiest; connects to an external DB. |
| Self-hosted Node.js | Node.js 18+ | Clone, build, run with npm start. |
| Docker | Docker | Community Dockerfile in repo; no official published image. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Database connection string?" | Prisma-compatible: postgresql://user:pass@host:5432/db or SQLite path |
| setup | "App public URL?" | e.g. https://bookmarks.example.com — needed for OAuth callbacks (NEXTAUTH_URL) |
| setup | "NextAuth secret?" | Random string: openssl rand -hex 32 |
| auth | "OAuth provider(s)?" | GitHub, Google, GitLab, etc. — register app, provide client ID + secret |
| auth | "Enable email magic-link login?" | Requires SMTP config (EMAIL_SERVER, EMAIL_FROM) |

## Software-layer concerns

Key environment variables:

  DATABASE_URL=postgresql://user:pass@localhost:5432/briefkasten
  NEXTAUTH_URL=https://bookmarks.example.com
  NEXTAUTH_SECRET=<random-secret>
  # OAuth (example: GitHub)
  GITHUB_CLIENT_ID=<id>
  GITHUB_CLIENT_SECRET=<secret>
  # Optional: email magic-link
  EMAIL_SERVER=smtp://user:pass@smtp.example.com:587
  EMAIL_FROM=noreply@example.com

Self-hosted Node.js install:

  git clone https://github.com/ndom91/briefkasten.git
  cd briefkasten
  npm install
  cp .env.example .env   # fill in vars above
  npx prisma migrate deploy
  npm run build
  npm start              # listens on port 3000

Database: Briefkasten uses Prisma ORM. PostgreSQL (recommended), MySQL/MariaDB, or SQLite all work.
Run migrations on every upgrade: npx prisma migrate deploy

Browser extension: available for Chrome and Firefox. Point it at your instance URL.

## Upgrade procedure

  cd briefkasten
  git pull origin main
  npm install
  npx prisma migrate deploy
  npm run build
  # Restart via systemd / PM2 / etc.

## Gotchas

- OAuth redirect URI: register https://<your-domain>/api/auth/callback/<provider> exactly with the OAuth provider.
- NEXTAUTH_URL must match public URL exactly — mismatch causes login failures.
- v1 vs v2 split: v2 lives at ndom91/sveltekasten (SvelteKit rewrite). Check upstream before deploying v2.
- No built-in reverse proxy: run behind nginx/Caddy; app binds to port 3000 HTTP only.
- Run npx prisma generate after npm install on fresh deployments if Prisma client is missing.

## References

- Upstream README: https://github.com/ndom91/briefkasten#readme
- Official docs: https://docs.briefkastenhq.com
- Browser extension: https://github.com/ndom91/briefkasten-extension
- v2 repo: https://github.com/ndom91/sveltekasten

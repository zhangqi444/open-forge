# Kanba

**What it is:** Open-source, lightweight Trello alternative for makers and indie hackers. Kanban board with unlimited projects, team collaboration, dark/light mode, and optional Stripe billing. Built with Next.js, Tailwind CSS, shadcn/ui, and Supabase.

**Official URL:** https://kanba.co  
**GitHub:** https://github.com/Kanba-co/kanba  
**Stars:** 602

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Vercel | Next.js (serverless) | Easiest path; Supabase for DB |
| Any Node.js host | npm / Node.js | Self-host with Supabase project |
| Supabase | Backend-as-a-service | Required as database + auth backend |

---

## Inputs to Collect

### Before deploying
- Supabase project URL and keys (create a project at supabase.com)
- Site URL (e.g., `https://kanba.example.com`)
- NextAuth secret (random string)

### Environment Variables (.env.local)
- `NEXT_PUBLIC_SUPABASE_URL` — Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — Supabase anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` — Supabase service role key (server-side only)
- `NEXT_PUBLIC_SITE_URL` — Production site URL
- `NEXTAUTH_URL` — Same as site URL
- `NEXTAUTH_SECRET` — Random secret for NextAuth session signing
- `STRIPE_SECRET_KEY` — Stripe secret key (optional, for billing)
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` — Stripe public key (optional)
- `STRIPE_WEBHOOK_SECRET` — Stripe webhook secret (optional)

---

## Software-Layer Concerns

- **Supabase dependency:** Kanba requires a Supabase project for database and authentication — it is not a fully standalone deployment; you need either a cloud Supabase account or a self-hosted Supabase instance
- **Stripe billing:** Optional; omit Stripe env vars to disable billing features
- **Database:** Managed by Supabase (PostgreSQL under the hood)
- **API routes:** Uses Next.js API routes (not Supabase Edge Functions) for Stripe integration
- **Stripe webhook:** If using Stripe, configure webhook endpoint at `https://your-domain/api/stripe/webhook`

---

## Upgrade Procedure

1. Pull latest code: `git pull`
2. Install dependencies: `npm install`
3. Build: `npm run build`
4. Restart the server

For Vercel: redeploy via Vercel dashboard or `vercel --prod`.

---

## Gotchas

- Kanba requires Supabase — a fully air-gapped self-host requires also running Supabase locally (adds significant complexity)
- Copy `.env.example` → `.env.local` and fill in all required vars before first run
- Stripe is optional but the env vars must be present (can be dummy values) or the app may error on startup
- For Vercel deployment, add all env vars through the Vercel dashboard before deploying

---

## References

- GitHub: https://github.com/Kanba-co/kanba
- Kanba website: https://kanba.co
- Supabase self-host docs: https://supabase.com/docs/guides/self-hosting

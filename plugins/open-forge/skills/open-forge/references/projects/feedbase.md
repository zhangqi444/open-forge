# Feedbase

**Open source product management tool — collect and prioritize customer feedback, track feature requests, publish changelogs, and share product status pages.**
Official site: https://feedbase.app
Docs: https://docs.feedbase.app/self-hosting
GitHub: https://github.com/chroxify/feedbase

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Self-hosted (Next.js + Supabase) | See self-hosting docs |
| Vercel + Supabase | Managed | One-click deploy option |

---

## Inputs to Collect

### Required
- Supabase project URL and anon/service key
- App URL (for public hub)

---

## Software-Layer Concerns

### Self-hosting
Follow the official self-hosting guide:
https://docs.feedbase.app/self-hosting

### Tech stack
- **Framework**: Next.js (TypeScript)
- **Styling**: Tailwind CSS + shadcn/ui
- **Database & Auth**: Supabase
- **Hosting**: Vercel-compatible (or any Node.js host)

### Key features
- Customer feedback capture and prioritization
- Feature request tracking
- Changelog publishing
- Public product status/hub page
- Customizable public hub

---

## Upgrade Procedure

Pull latest from GitHub and redeploy. Check release notes for any Supabase migration steps.

---

## Gotchas

- Requires a Supabase project — self-hosting Supabase is possible but adds complexity
- Early-stage project — roadmap features (Roadmaps, GitHub/Linear integrations, analytics) not yet implemented
- License: AGPL v3

---

## References
- Self-hosting docs: https://docs.feedbase.app/self-hosting
- GitHub: https://github.com/chroxify/feedbase#readme

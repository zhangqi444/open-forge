# Mergeable

**What it is:** A better inbox for GitHub pull requests. Organizes PRs into configurable sections using flexible search queries, highlights pull requests where it's your turn to act (attention set), supports multiple GitHub instances including GitHub Enterprise, and stores all data locally in the browser — no GitHub App installation needed.

**Official URL:** https://github.com/pvcnt/mergeable
**Public instance:** https://app.usemergeable.dev
**Docs:** https://www.usemergeable.dev
**License:** MIT
**Stack:** TypeScript/Vite SPA; Helm chart for Kubernetes self-hosting

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Public hosted | Browser | Use https://app.usemergeable.dev — no setup needed |
| Kubernetes | Helm | Self-host the SPA; chart in `/helm/mergeable` |
| Any Linux VPS | Static file server / Nginx | Build from source and serve `dist/` |

> **Note:** Mergeable is a frontend SPA — it makes direct browser→GitHub API calls using your personal access token. No server-side component required for basic use.

---

## Inputs to Collect

### Runtime (configured in the app UI)
- GitHub personal access token (PAT) with `repo` scope — entered in app settings
- GitHub instance URL — for GitHub Enterprise, set the custom base URL in settings

### Pre-deployment (self-hosting only)
- No environment variables required — configuration is all client-side

---

## Software-Layer Concerns

**Easiest path:** Use the public instance at https://app.usemergeable.dev. Your token and data never leave your browser.

**Self-host with Helm (Kubernetes):**
```bash
helm install mergeable ./helm/mergeable
```
See the `/helm/mergeable` directory in the repo for chart values.

**Self-host with Node.js (build from source):**
```bash
git clone https://github.com/pvcnt/mergeable.git
cd mergeable
pnpm install
pnpm run build
# Serve the dist/ directory with any static file server (Nginx, Caddy, etc.)
```

**No persistent storage needed:** All configuration (tokens, sections, queries) is stored in browser `localStorage`. Clearing browser data clears Mergeable settings.

**Section queries:** Each section is defined by a GitHub search query. Examples:
- `is:open is:pr author:@me` — your open PRs
- `is:open is:pr review-requested:@me` — PRs awaiting your review
- `is:open is:pr team-review-requested:your-org/your-team`

**Keyboard shortcuts:** Built-in shortcuts for fast navigation between PRs.

**GitHub Enterprise:** Add your GHE URL in settings — Mergeable supports multiple GitHub instances simultaneously.

**Upgrade procedure (self-hosted):**
1. `git pull`
2. `pnpm install && pnpm run build`
3. Redeploy the `dist/` directory

---

## Gotchas

- **No Docker image published** — official self-hosting is via Helm or building from source; no `docker pull` option
- **Browser storage only** — settings and tokens are in `localStorage`; not shared across browsers/devices
- **PAT stored in browser** — be mindful on shared machines; use a scoped PAT (read-only `repo` access is sufficient)
- **No server-side processing** — all GitHub API calls come from your browser; GitHub rate limits apply per-user
- **No notifications** — Mergeable is a dashboard, not a notification system; refresh to see updates

---

## Links
- GitHub: https://github.com/pvcnt/mergeable
- Public instance: https://app.usemergeable.dev
- Docs / self-hosting guide: https://www.usemergeable.dev

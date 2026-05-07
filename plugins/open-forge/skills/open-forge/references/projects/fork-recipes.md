# Fork Recipes

**Personal recipe management web app** — Django-based frontend that works with the ForkApi backend to manage food recipe collections. Supports video/image recipes, categories, meal planning, shopping lists, recipe scraping from URLs, and optional AI features (OpenAI token).

**Official site:** https://mikebgrep.github.io/forkapi/latest/clients/
**Source:** https://github.com/mikebgrep/fork.recipes
**License:** BSD-3-Clause

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker Compose | Recommended; requires ForkApi backend |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Whether to enable AI features (requires OpenAI API token)
- SSL or no-SSL setup

### Phase 2 — Deploy
- ForkApi backend URL and credentials
- PostgreSQL credentials (used by ForkApi)
- OpenAI API token (optional, for recipe scraping, generation, translation, audio narration)
- Django `SECRET_KEY`

---

## Software-Layer Concerns

- **Two components:** `fork.recipes` (this Django frontend) + `forkapi` (Go/Python backend) — both required
- **Stack:** Django 5.x, Python, PostgreSQL
- **SSL:** SSL and no-SSL Docker Compose configurations provided
- **AI features** (all optional, require OpenAI token):
  - Recipe scraper from any URL
  - Generate recipes by ingredients
  - Translate recipes to other languages
  - Audio narration (English only)
  - Emoji insertion in recipe descriptions
- **Backup:** Built-in snapshot import/export for database backups

---

## Deployment

Follow the installation guide in the ForkApi documentation:
https://mikebgrep.github.io/forkapi/latest/clients/

Both `fork.recipes` (frontend) and `forkapi` (backend) must be deployed together. The documentation covers the full Docker Compose setup for both components.

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **ForkApi backend is required** — `fork.recipes` is the frontend only; it cannot function without the `forkapi` backend running
- **AI features are fully optional** — the app works without an OpenAI token; AI features are additive
- **OpenAI token costs apply** — recipe scraping, generation, and translation make API calls to OpenAI; monitor usage
- **Low release cadence** — last release was April 2025 (v4.1.1); check repository for current status

---

## Links

- Upstream README: https://github.com/mikebgrep/fork.recipes#readme
- ForkApi documentation: https://mikebgrep.github.io/forkapi/latest/
- ForkApi source: https://github.com/mikebgrep/forkapi

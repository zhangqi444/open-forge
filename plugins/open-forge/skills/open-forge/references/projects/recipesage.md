# RecipeSage

**Collaborative recipe keeper, meal planner, and shopping list organizer — import from any URL, PDF, or image.**
Official site: https://recipesage.com
GitHub: https://github.com/julianpoy/RecipeSage
Self-host resources: https://github.com/julianpoy/recipesage-selfhost

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Use the dedicated selfhost repo; multi-service stack |

---

## Inputs to Collect

### All phases
- `DOMAIN` — public hostname (e.g. `recipes.example.com`)
- `DATA_DIR` — host path for database and uploads
- SMTP credentials (optional) — for email features
- Third-party API keys (optional) — e.g. for nutrition auto-fill

---

## Software-Layer Concerns

### Config
- All configuration in `.env` using the selfhost repo template
- Use the selfhost-specific repo: https://github.com/julianpoy/recipesage-selfhost
- Do NOT use the main development repo to self-host — the selfhost repo is configured for easy deployment

### Data
- PostgreSQL database for all recipe data
- File storage volume for uploaded images and PDFs

### Ports
- `80` — main web UI (configurable)

### Install (selfhost repo)
```bash
git clone https://github.com/julianpoy/recipesage-selfhost
cd recipesage-selfhost
cp .env.example .env
# Edit .env with your settings
docker compose up -d
```

---

## Upgrade Procedure

1. `cd recipesage-selfhost && git pull`
2. `docker compose pull`
3. `docker compose up -d`
4. Check logs: `docker compose logs -f`

---

## Gotchas

- Use the **selfhost repo** (`julianpoy/recipesage-selfhost`), not the main repo — main repo is development-oriented
- License: AGPL-3.0 for non-commercial use; commercial use requires a separate license from the author
- AI cooking assistant is a built-in feature; configure the underlying model in the .env
- Import supports JSON-LD, Pepperplate, Living Cookbook, Paprika, Cookmate, Recipe Keeper, CopyMeThat, Evernote, CSV
- Works offline as a PWA once loaded — content syncs automatically

---

## References
- [Self-host Repo](https://github.com/julianpoy/recipesage-selfhost)
- [Documentation](https://docs.recipesage.com)
- [GitHub README](https://github.com/julianpoy/RecipeSage#readme)

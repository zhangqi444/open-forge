# SparkyBudget

> Personal finance management app — track checking, credit card, and loan accounts; manage budgets; analyze spending trends with a dark-themed dashboard. Supports SimpleFin for automatic transaction import. Docker Compose deployment with SQLite.

**Official URL:** https://github.com/CodeWithCJ/SparkyBudget  
**Community:** https://discord.gg/vGjn4b6CVB

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; SQLite included |
| Any Linux VPS/VM | Docker | Single container; needs volume for DB |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `SPARKY_DEMO` | Set to `Yes` to auto-generate demo data (optional) | `No` |
| SimpleFin token | From SimpleFin.org for automatic bank transaction import (optional) | paste into app on first run |

---

## Software-Layer Concerns

### Quick Start
```bash
mkdir sparkybudget && cd sparkybudget

# Download compose file and env template
wget https://raw.githubusercontent.com/CodeWithCJ/SparkyBudget/refs/heads/main/docker-compose.yaml
wget https://raw.githubusercontent.com/CodeWithCJ/SparkyBudget/refs/heads/main/.env-example

# Configure
mv .env-example .env
nano .env

# Start
docker compose pull && docker compose up -d
```

Access at http://localhost:5050

### SimpleFin Integration
SimpleFin connects to your bank for automatic transaction import:
1. Get a token from https://www.simplefin.org
2. Enter the token in the app on first run (stored as `access_url.txt` in the container)
3. To reset the token: `docker exec -it sparkybudget sh -c "rm /SparkyBudget/access_url.txt"` then restart

**Note:** The SimpleFin token can only be used once; generate a new token from SimpleFin if you need to re-authenticate.

### Demo Mode
Set `SPARKY_DEMO=Yes` in `.env` to auto-generate dummy accounts and transactions — useful for exploring the UI. **Back up your database first** if you are an existing user.

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/SparkyBudget` | SQLite database and app data — bind-mount to persist |

### Ports
- Default: `5050` — proxy with Nginx/Caddy for TLS

---

## Upgrade Procedure

1. Pull latest: `docker compose pull`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`
4. Database migrations run automatically

---

## Gotchas

- **SimpleFin token is one-use** — once consumed, you cannot reuse it; generate a new one from SimpleFin if the `access_url.txt` is deleted or corrupted
- **Demo data is destructive** — setting `SPARKY_DEMO=Yes` on an existing install will add dummy data to your real database; always back up first
- **SQLite** — all data in a single file; back up the database file regularly; no external database required
- **No multi-user** — designed for personal/household use; no multi-user account management

---

## Links
- GitHub: https://github.com/CodeWithCJ/SparkyBudget
- Discord: https://discord.gg/vGjn4b6CVB
- SimpleFin: https://www.simplefin.org
- .env example: https://raw.githubusercontent.com/CodeWithCJ/SparkyBudget/refs/heads/main/.env-example

# FoodCoopShop

**Web shop software for food cooperatives and local shops** — member management, order management, multi-producer support, flexible delivery rhythms, cashless payments via bank transfer, and self-service mode with barcode scanning. Available in German and English.

**Official site:** https://www.foodcoopshop.com
**Source:** https://github.com/foodcoopshop/foodcoopshop
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker Compose | Production recommended path |
| Any VPS / bare metal | PHP + MySQL (native) | Manual installation; see installation guide |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Language: German (`de`) or English (`en`)
- Whether using Docker or native PHP install

### Phase 2 — Deploy
- MySQL/MariaDB credentials
- Email/SMTP config for order notifications
- Admin account credentials
- `App.fullBaseUrl` (must match your domain, no trailing slash)

---

## Software-Layer Concerns

- **Stack:** PHP (CakePHP framework), MySQL/MariaDB
- **Config file:** `config/custom_config.php` — set `App.fullBaseUrl` to your domain
- **Data dirs:** `webroot/files/` for uploaded images and documents; must be writable
- **Docker image:** `foodcoopshop/foodcoopshop` — separate Docker repo: https://github.com/foodcoopshop/foodcoopshop-docker
- **Docs:** https://foodcoopshop.github.io
- **Supported delivery rhythms:** Weekly, bi-weekly, monthly, every first/last Friday of month, etc.
- **Decentralized network plugin:** Sync products between multiple FoodCoopShop installations

---

## Deployment (Docker)

```bash
git clone https://github.com/foodcoopshop/foodcoopshop-docker
cd foodcoopshop-docker
# Edit .env with your domain, DB credentials, mail config
docker compose up -d
```

Full installation guide: https://foodcoopshop.github.io/dev/installation-guide

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

For native installs, follow: https://foodcoopshop.github.io/dev/upgrade-guides

---

## Gotchas

- **`App.fullBaseUrl` must have no trailing slash** — incorrect URL causes login and redirect issues
- **PHP mail / SMTP required** for order confirmation emails; configure in `custom_config.php`
- **File permissions** — `webroot/files/` and `tmp/` must be writable by the web server user
- **Multi-language:** Interface is German-first; English translation is complete but German docs are more extensive
- **Gitpod/Ona dev environment:** Use `bash ./devtools/init-dev-setup.sh` after containers start; update `App.fullBaseUrl` to your Gitpod domain

---

## Links

- Upstream README: https://github.com/foodcoopshop/foodcoopshop#readme
- Documentation: https://foodcoopshop.github.io
- Docker repo: https://github.com/foodcoopshop/foodcoopshop-docker
- Demo (German): https://demo-de.foodcoopshop.com
- Demo (English): https://demo-en.foodcoopshop.com

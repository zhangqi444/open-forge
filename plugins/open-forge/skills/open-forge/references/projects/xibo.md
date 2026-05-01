# Xibo

**Open source digital signage platform — web-based CMS for managing content across screens, with player apps for Windows, Linux, Android, webOS, Tizen, and ChromeOS.**
Official site: https://xibosignage.com
GitHub (issues/docs): https://github.com/xibosignage/xibo
Docker: https://github.com/xibosignage/xibo-docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended and only supported deployment method |

---

## Inputs to Collect

### Required
- `config.env` — copy from `config.env.template` and fill in database credentials, CMS key, timezone
- Data directory path — for library, DB, backups

---

## Software-Layer Concerns

### Docker Compose installation
Docker Compose is the only recommended/supported way to deploy Xibo CMS:

```bash
# Download docker-compose.yaml and config.env.template from:
# https://github.com/xibosignage/xibo-docker
cp config.env.template config.env
# Edit config.env — set MYSQL_PASSWORD, CMS_KEY, etc.
docker compose up -d
```

Full installation guide: https://account.xibosignage.com/docs/setup/cms-installation-guides

### Data directory layout (DATA_DIR/shared/)
- `cms/library/` — media library storage
- `db/` — database storage
- `backup/` — automated daily DB backups
- `cms/web/theme/custom/` — custom themes
- `cms/custom/` — custom modules
- `cms/web/userscripts/` — user-hosted resources (available at `/userscripts/`)

### Components
- `xibosignage/xibo-cms` — the CMS web container
- `xibosignage/xibo-xmr` — Xibo Message Relay (real-time player commands)
- Players: Windows, Linux, Android, webOS, Tizen, ChromeOS (separate installs)

### Ports
- `80` — CMS web UI (default; configurable in compose)

---

## Upgrade Procedure

Follow the official upgrade guide — Xibo upgrades require specific steps and may include database migrations:
https://account.xibosignage.com/docs/setup/cms-installation-guides

---

## Gotchas

- Docker Compose is the only supported deployment method — bare metal is not supported
- `config.env` must be configured before first launch
- Players are separate downloads per platform; not included in the CMS Docker image
- Commercial cloud hosting and support available from Xibo Signage Ltd

---

## References
- Installation guide: https://account.xibosignage.com/docs/setup/cms-installation-guides
- Docker repo: https://github.com/xibosignage/xibo-docker
- User manual: https://xibosignage.com/manual/en/
- GitHub: https://github.com/xibosignage/xibo#readme

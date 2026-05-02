# Cloudron

**What it is:** A complete platform for running apps on your own server. Provides a one-click app store (100+ apps including Nextcloud, WordPress, Gitea, etc.), automatic SSL/TLS, DNS management, backups, user/SSO management, and updates — all through a single web dashboard. Turns a VPS into a managed PaaS.

> ⚠️ **Closed source.** Cloudron is proprietary software. Free tier allows up to 2 apps; paid plans for more.

**Official URL:** https://www.cloudron.io
**License:** Proprietary; free tier (2 apps) + paid plans
**Stack:** Proprietary; requires a fresh Ubuntu LTS server

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Ubuntu 22.04 / 24.04 LTS VPS | Native install (script) | Requires a dedicated/fresh server |
| DigitalOcean / Hetzner / Linode / Vultr | Native install | Officially tested providers |

> **Important:** Cloudron must be installed on a **dedicated, fresh** Ubuntu server. It takes over the server. Do not install alongside other services.

---

## Inputs to Collect

### Pre-deployment
- A fresh Ubuntu 22.04 or 24.04 LTS server (minimum 1GB RAM; 2GB+ recommended)
- A domain name — Cloudron manages DNS/SSL for all installed apps under subdomains
- Cloudron account — create at https://www.cloudron.io before installing

---

## Software-Layer Concerns

**Installation:**
```bash
wget https://cloudron.io/cloudron-setup -O cloudron-setup
chmod +x cloudron-setup
sudo ./cloudron-setup
```

After installation, visit `https://my.<your-domain>` to complete setup via the web wizard.

**DNS:** Cloudron can manage DNS automatically if you use a supported DNS provider (Cloudflare, Route53, etc.) or manually — it provisions Let's Encrypt SSL for each app automatically.

**Apps:** Install apps from the Cloudron App Store via the dashboard. Each app runs in its own container with isolated storage.

**Backups:** Configure S3-compatible storage or filesystem backups via the dashboard.

**Upgrade procedure:** Cloudron self-updates. Updates can be triggered from the dashboard or run automatically.

---

## Gotchas

- **Dedicated server required** — Cloudron takes full control of the host OS; do not install on a server running other services
- **Closed source** — proprietary platform; you cannot audit or modify it
- **Free tier: 2 apps max** — additional apps require a paid subscription (~$15/month for unlimited apps)
- **Domain required** — Cloudron is designed around subdomain-per-app; a domain is mandatory
- **Lock-in risk** — migrating apps off Cloudron requires manual export; the platform manages containers/data internally

---

## Links
- Website: https://www.cloudron.io
- Install guide: https://www.cloudron.io/get.html
- App store: https://www.cloudron.io/store/

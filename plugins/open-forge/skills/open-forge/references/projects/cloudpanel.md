---
name: CloudPanel
description: "Free modern server control panel for PHP/Node.js/Python/Static/Reverse Proxy apps. Bash installer. cloudpanel-io/cloudpanel-ce. Supports AWS, DigitalOcean, Hetzner, GCE, Azure, Oracle, Vultr. Ubuntu/Debian."
---

# CloudPanel

**Free, modern server control panel** focused on simplicity. Run PHP, Node.js, Static Websites, Reverse Proxies, and Python apps on a high-performance stack (NGINX + OpenLiteSpeed + MySQL/MariaDB + Redis + Varnish). Free Let's Encrypt SSL, Cloudflare integration, supports ARM + x86. Ready in ~1 minute.

Built + maintained by **CloudPanel.io** team. Community-driven CE (Community Edition) open-sourced on GitHub.

- Upstream repo: <https://github.com/cloudpanel-io/cloudpanel-ce>
- Website + docs: <https://www.cloudpanel.io>
- Discord: <https://discord.cloudpanel.io>

## Architecture in one minute

- **Bash installer** — installs directly onto a VPS/bare-metal Ubuntu or Debian host
- Stack: **NGINX** (or OpenLiteSpeed) + **MySQL 8** (or MariaDB) + **PHP** (multi-version) + **Node.js** + **Python** + **Redis** + **Varnish**
- Let's Encrypt TLS via built-in tooling
- Cloudflare integration for DNS + CDN
- Admin panel at `https://<server-ip>:8443`
- Resource: **medium** — always-on control panel daemon + web stack; needs ≥1 GiB RAM
- **Not a Docker-based tool** — installs directly on the OS

## Compatible install methods

| Infra                    | Install method                     | Notes                                             |
| ------------------------ | ---------------------------------- | ------------------------------------------------- |
| **Amazon Web Services**  | AMI marketplace                    | <https://www.cloudpanel.io/docs/v2/getting-started/amazon-web-services/installation/ami/> |
| **DigitalOcean**         | DO Marketplace 1-click             | <https://www.cloudpanel.io/docs/v2/getting-started/digital-ocean/installation/marketplace/> |
| **Hetzner Cloud**        | Bash installer                     | <https://www.cloudpanel.io/docs/v2/getting-started/hetzner-cloud/installation/installer/> |
| **Google Compute Engine**| Bash installer                     | <https://www.cloudpanel.io/docs/v2/getting-started/google-compute-engine/installation/installer/> |
| **Microsoft Azure**      | Bash installer                     | <https://www.cloudpanel.io/docs/v2/getting-started/microsoft-azure/installation/installer/> |
| **Oracle Cloud**         | Bash installer                     | <https://www.cloudpanel.io/docs/v2/getting-started/oracle-cloud/installation/installer/> |
| **Vultr**                | Vultr Marketplace                  | <https://www.cloudpanel.io/docs/v2/getting-started/vultr/installation/marketplace/> |
| **Other / Bare-metal**   | Bash installer                     | <https://www.cloudpanel.io/docs/v2/getting-started/other/> |

## Inputs to collect

| Input                 | Example                        | Phase   | Notes                                                                |
| --------------------- | ------------------------------ | ------- | -------------------------------------------------------------------- |
| Cloud provider        | AWS / Hetzner / DO / bare-metal| Infra   | Determines which installer path to follow                            |
| OS                    | Ubuntu 24.04 / Debian 12       | Infra   | Supported: Ubuntu 22.04, 24.04; Debian 11, 12, 13                   |
| Arch                  | x86 / ARM                      | Infra   | Both supported; use ARM for Ampere instances                         |
| Server IP / domain    | `203.0.113.10`                 | URL     | CloudPanel admin: `https://<ip>:8443` after install                  |
| Web technology        | PHP / Node.js / Python / Static | Config | Determines which site wizard path to use after install               |
| Let's Encrypt email   | `you@example.com`              | TLS     | Used for cert registration                                           |
| Cloudflare API token  | optional                       | DNS     | For Cloudflare DNS + CDN integration                                 |

## Install via bash installer (generic / Hetzner / GCE / Azure / Oracle / bare-metal)

```sh
curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh
# Review the script before running (verify checksum per upstream docs)
chmod +x install.sh
sudo bash install.sh
```

The installer runs ~1 minute. On completion it prints:

```
CloudPanel is now installed.
Open your browser and go to: https://<server-ip>:8443
```

For AWS (AMI), DigitalOcean, and Vultr: use the marketplace 1-click — no manual installation needed.

## First boot

1. Visit `https://<server-ip>:8443` — accept the self-signed cert warning (or configure a domain + Let's Encrypt).
2. Create the **admin account** on first visit.
3. Add a **site** via the Sites menu:
   - Choose technology: PHP, Node.js, Python, Static, or Reverse Proxy
   - Enter domain + PHP version (if PHP)
   - CloudPanel creates NGINX vhost + Let's Encrypt cert automatically
4. Deploy your app files to `/home/<user>/htdocs/<domain>/`.
5. Configure DB if needed (Sites → Database → Create Database).
6. Set up **SSH keys** for deploying via git pull / rsync.

## Data & config layout

- Sites: `/home/<user>/htdocs/<domain>/`
- CloudPanel config: `/etc/cloudpanel/`
- NGINX vhosts: `/etc/nginx/sites-enabled/`
- MySQL data: standard MySQL paths
- Logs: per-vhost under `/home/<user>/logs/`

## Backup

CloudPanel has a built-in **backup feature** in the UI (Sites → Backups → Create Backup). Also configure automated backups to S3-compatible storage in Settings → Backup.

```sh
# Manual DB dump example
mysqldump -u root -p <database> > backup-$(date +%F).sql
```

## Upgrade

CloudPanel updates via its own admin UI: Settings → CloudPanel → Update. Keep the OS updated separately with `apt upgrade`.

## Gotchas

- **Not Docker-based.** CloudPanel installs directly onto the OS. You can't `docker compose down` it — it runs as systemd services. Don't install it alongside other control panels (cPanel, Plesk, ISPConfig) or on a host already running NGINX/Apache.
- **Admin panel on port 8443** with a self-signed cert on first launch. Browsers will warn. Either: (a) use the IP temporarily, (b) configure a domain → Let's Encrypt → access via `https://panel.example.com:8443`.
- **Ubuntu/Debian only.** Supported OS: Ubuntu 22.04, 24.04; Debian 11, 12, 13. Not CentOS/RHEL. Use the right OS at provision time — it can't be changed post-install.
- **Single server tool.** CloudPanel manages one server. For multi-server setups, run separate instances.
- **Let's Encrypt rate limits.** Issuing certs for many domains quickly triggers rate limits (50 certs/domain/week). The built-in Let's Encrypt integration respects this, but rapid dev/test cycling can hit limits.
- **Cloudflare integration requires API token.** If you use Cloudflare for DNS, add the API token in CloudPanel → Cloudflare to automate DNS record creation when adding new sites.
- **PHP multi-version.** CloudPanel supports PHP 7.x–8.x in parallel. Each site uses its own PHP-FPM pool; version is set per-site in the site settings.
- **MySQL root password set during install.** It's shown once in the installer output — save it. Can also retrieve from CloudPanel UI: Settings → Database → Root Password.
- **ARM support.** Full ARM64 support for Ampere/Graviton instances — useful for cost-optimized Hetzner CAX or AWS Graviton deploys.

## Project health

Active, multiple cloud marketplace listings, Discord community, bi-lingual (EN/DE) support, CE edition open-source with enterprise features. Maintained by CloudPanel.io.

## Server-control-panel-family

- **CloudPanel** — modern, free, PHP/Node/Python/static, NGINX, fast to set up, Ubuntu/Debian
- **cPanel** — industry standard, paid, complex, legacy PHP-heavy setups
- **Plesk** — paid, Windows + Linux, broader mail server support
- **ISPConfig** — free, older UI, stronger mail features
- **HestiaCP** — free, lightweight, Nginx/Apache, good for VPS hosting resellers
- **Webmin** — legacy admin panel; lower-level
- **Coolify** — Docker-first, newer, apps vs hosting-control-panel distinction

**Choose CloudPanel if:** you want a clean, free, fast-to-set-up control panel for traditional PHP/Node/Python web hosting on Ubuntu/Debian without Docker overhead.

## Links

- Repo: <https://github.com/cloudpanel-io/cloudpanel-ce>
- Docs: <https://www.cloudpanel.io/docs/v2/>
- Discord: <https://discord.cloudpanel.io>
- HestiaCP (alt): <https://hestiacp.com>
- Coolify (alt): <https://coolify.io>

---
name: Vito
description: "Self-hosted server management + PHP app deployment platform. \"Self-hosted Forge/Ploi/RunCloud.\" Laravel + React. Provisions servers, deploys Laravel apps, manages DBs/firewalls/cron/SSL. MIT (verify). Active Discord + demo."
---

# Vito

Vito is **"Laravel Forge / Ploi / RunCloud / ServerAvatar — self-hosted"** — a web application that provisions, manages, and deploys PHP applications to your servers, from a single web UI. Connect an SSH-reachable server (VPS, bare metal, cloud), Vito provisions everything (nginx, PHP-FPM, MySQL/MariaDB, Redis, supervisor, certbot, firewall), then deploys your Laravel/PHP app from Git. Replaces the $12-40/mo commercial deployment SaaS with a self-hosted alternative.

Built + maintained by **vitodeploy org** + community. License: check repo (README does not explicitly state; follow LICENSE-file-verification-required convention — batch 97 precedent). Active; Discord + docs site + demo; plugins + workflows.

Use cases: (a) **freelance-dev / agency** deploying client sites + avoiding per-server fees on commercial PaaS (b) **small SaaS** self-hosting the deployment-control-plane (c) **Laravel specialist** — matches Laravel Forge's feature set (d) **cost-optimization** — replaces $12-40/mo SaaS with $5/mo VPS + your own labor (e) **data-ownership** — all server credentials + deploy keys stay in your control (f) **learning server management** — Vito's provisioning is auditable (g) **DIY WordPress/PHP-app hosting** for multiple clients.

Features (from upstream README):

- **Provisions + manages servers** via SSH
- **Deploys PHP apps** (Laravel-first; also generic PHP)
- **Database management** — MySQL + MariaDB
- **Firewall management** — UFW/iptables rules
- **SSL** — Let's Encrypt + custom certs
- **Supervisor** for queue workers
- **Cron jobs** management
- **SSH key deployment**
- **Custom + LetsEncrypt SSL**
- **REST API**
- **Plugins**
- **Export + Import** (config portability)
- **Workflows + Automations**
- **Domains + DNS management**

- Upstream repo: <https://github.com/vitodeploy/vito>
- Homepage / docs: <https://vitodeploy.com>
- Demo: <https://demo.vitodeploy.com>
- Install VPS: <https://vitodeploy.com/getting-started/installation.html#install-on-vps>
- Install Docker: <https://vitodeploy.com/getting-started/installation.html#install-via-docker>
- Roadmap: <https://github.com/orgs/vitodeploy/projects/5>
- Discord: <https://discord.gg/uZeeHZZnm5>

## Architecture in one minute

- **Laravel** (PHP) + **Inertia.js + React** frontend
- **MySQL / PostgreSQL** — DB
- **Redis** — cache/queues
- **SSH (PHPSecLib)** — connects to managed servers
- **Resource**: moderate — 500MB-1GB RAM for Vito itself; target servers are separate
- **Port 80/443** behind webserver

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **VPS bash installer** | **`bash <(curl -Ls ...install.sh)`**                           | **Upstream-primary**                                                               |
| **Docker**         | Upstream docker guide                                                     | **Alternative**                                                                        |
| Bare-metal Laravel | Composer install on LAMP/LEMP                                                            | DIY                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `vito.example.com`                                          | URL          | TLS recommended                                                                                    |
| DB                   | MySQL / PostgreSQL                                          | DB           | Laravel                                                                                    |
| `APP_KEY`            | Laravel                                                                                    | **CRITICAL** | **IMMUTABLE**                                                                                    |
| SSH private keys     | For provisioning + deploying to target servers                                                                                 | **CRITICAL** | **ROOT-ACCESS-CAPABLE credentials**                                                                                    |
| GitHub/GitLab tokens | For deploying from Git                                                                           | **CRITICAL** | **Grant cloning access**                                                                                                            |
| Cloudflare / DNS keys | For automatic domain management                                                                                                 | Integration  | Convenient                                                                                                                            |
| Admin creds          | First-boot registration                                                                                                                       | Bootstrap    | **MUST BE STRONG — this is the key to all your servers**                                                                                                                                            |

## Install via bash

```sh
bash <(curl -Ls https://raw.githubusercontent.com/vitodeploy/vito/3.x/scripts/install.sh)
```

⚠️ **"curl | sh" install-supply-chain-risk** (Kaneo 93 precedent): this pattern runs untrusted remote code. For production, prefer:
- Read the install script + review before running
- Use Docker method (containerized, easier to audit)
- Pin to specific commit, not branch

## First boot

1. Follow upstream install (VPS bash OR Docker)
2. Browse admin URL → register admin
3. Add first target server (IP + SSH key)
4. Provision the server (creates user, installs PHP/nginx/mysql)
5. Deploy first site: Git repo + branch + domain
6. Test deployment; verify site accessible
7. Add Let's Encrypt cert via Vito
8. Configure cron + supervisor for queue workers
9. Put Vito itself behind TLS + strong auth
10. Back up Vito DB + SSH keys (encrypted) + config

## Data & config layout

- Vito DB — servers, sites, SSH keys, deploy history
- `.env` — APP_KEY + DB + third-party tokens (DNS, Git)
- SSH private keys storage (DB-encrypted ideally)

## Backup

```sh
docker compose exec db pg_dump -U vito vito > vito-$(date +%F).sql
sudo tar czf vito-storage-$(date +%F).tgz storage/
```

## Upgrade

1. Releases: <https://github.com/vitodeploy/vito/releases>. Active.
2. Docker: pull + migrate.
3. Bash-install: re-run install script OR follow upstream upgrade path.
4. **Back up BEFORE major upgrades** — Vito holds keys to your entire infrastructure.

## Gotchas

- **HUB-OF-CREDENTIALS = CROWN-JEWEL TIER 1 — 10th TOOL**:
  - **SSH private keys with root/sudo on all managed servers** — ultimate infrastructure keys
  - **Git OAuth tokens** (GitHub, GitLab)
  - **DNS provider API keys** (Cloudflare, Route53)
  - **SMTP creds**
  - **Database credentials for all deployed apps**
  - **Admin account** = god-mode across all servers
  - **49th tool in hub-of-credentials family — CROWN-JEWEL Tier 1 (10th tool)**
  - **Attack scenario**: Vito compromise = attacker gets root-SSH access to every managed server = catastrophic
  - **CROWN-JEWEL Tier 1 now 10 TOOLS**: Octelium, Guacamole, Homarr, pgAdmin, WGDashboard, Lunar, Dagu, GrowChief, Mixpost, **Vito** — **NEW sub-category: infrastructure-control-plane**
  - **Recipe convention**: infrastructure-control-plane CROWN-JEWEL tier is perhaps the most sensitive — compromise cascades catastrophically.
- **`APP_KEY` IMMUTABILITY** (Laravel): **36th tool in immutability-of-secrets family.**
- **MFA + STRONG AUTH MANDATORY**: this is non-negotiable:
  - Enable 2FA/MFA on Vito admin login
  - Network-layer restriction: VPN-only access or IP allowlist
  - Audit log all actions
  - Rotate SSH keys if compromised
- **SECURE THE INSTALL SCRIPT**: curl|sh install is vulnerable to:
  - Remote code swap attack (if upstream compromised)
  - MITM if HTTPS fails or DNS poisoned
  - **Recipe convention**: curl|sh install-supply-chain-risk (Kaneo 93 precedent). Applicable to: Vito + many others.
- **SSH KEYS STORED AT-REST**: Vito stores private keys in its DB. Verify:
  - Encryption at rest (ideally)
  - DB access tightly controlled
  - Backup keys encrypted (gpg/age)
- **TARGET SERVER COMPROMISE from Vito compromise**: if Vito is breached, attacker pivots to every managed server. Mitigation:
  - Use separate SSH keys per server (not one master key)
  - Vito admin account = least-privilege principle (read-only roles for junior team members)
  - Monitor for unauthorized deploy actions
- **PROVISIONING SCRIPTS = SHELL EXECUTION ON MANAGED SERVERS**: Vito runs shell commands on target servers via SSH. Arbitrary-shell-exec is the design; secure Vito itself accordingly.
- **3rd tool in web-exposed-shell-exec-gateway family** (OliveTin 91, Dagu 94, Dispatcharr-FFmpeg-weak-variant 96, **Vito 99 — strong variant**) — distinct framing: Vito's shell-exec is BY-DESIGN deploying infrastructure. **Add to family-doc as "infrastructure-deployment-shell-exec sub-category".**
- **TRANSPARENT-MAINTENANCE**: active + docs + demo + Discord + roadmap + plugins. **41st tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: vitodeploy org + Discord community. **34th tool in institutional-stewardship — sole-founder-with-community sub-tier** (or transitional-to-team if multiple core maintainers visible).
- **LICENSE not explicitly stated in README**: follow LICENSE-file-verification-required convention (MediaManager 97 + Zipline 98). Verify LICENSE file before commercial use / agency-SaaS-redistribution. If license is AGPL, then offering Vito-as-a-SaaS (hosting it for others) triggers network-service-disclosure.
- **COMMERCIAL-TIER**: none visible in README; pure OSS. Sustainability relies on community + sponsor model OR is transitioning toward commercial tier (common for infrastructure tools).
- **PHP-FORGE-CATEGORY** emerging: Vito + Laravel Forge (commercial) + Ploi (commercial) + RunCloud (commercial) + ServerAvatar (commercial). Most commercial; Vito is ~only OSS entrant. **Recipe convention: "PHP-PaaS-category"** — commercial-SaaS-dominant niche with OSS challenger.
- **NEW CATEGORY: "infrastructure-control-plane"** tool class:
  - Coolify — self-host Vercel/Heroku-alike; PHP (batch-future)
  - Dokploy — Vercel-clone; Node
  - Dokku — Heroku-clone; bash
  - CapRover — self-host PaaS; Node
  - Cloudron — turnkey self-host hub; commercial-OSS
  - **Vito** — PHP/Laravel-focused subset
  - CasaOS — consumer-oriented; simpler
  - **Recipe convention: new category**; all share CROWN-JEWEL Tier 1 risk + infrastructure-control-plane architecture.
- **LARAVEL-FORGE-FEATURE-PARITY**: Vito specifically matches Forge's PHP-Laravel-deployment scope. For non-Laravel / non-PHP deployments, use Coolify / Dokploy / Dokku.
- **ALTERNATIVES WORTH KNOWING:**
  - **Laravel Forge** — commercial SaaS ($12-40/mo/server); polished; mature
  - **Ploi** — commercial SaaS; similar to Forge
  - **RunCloud** — commercial SaaS; general-PHP focus
  - **ServerAvatar** — commercial SaaS; cheaper tier
  - **Coolify** — OSS; broader than PHP (Node, Python, Go, Docker apps)
  - **Dokploy** — OSS; Vercel-like; Node-backend
  - **Dokku** — OSS; Heroku-like; minimal
  - **CapRover** — OSS; self-hosted PaaS
  - **Cloudron** — OSS-commercial-hybrid; turnkey; commercial features
  - **Ansible / SaltStack / Chef / Puppet** — config-management tools (broader + more work)
  - **Choose Vito if:** you want PHP/Laravel-focused + OSS + self-host Forge-alternative + web UI.
  - **Choose Coolify if:** you want polyglot + modern + self-host Vercel.
  - **Choose Forge if:** you accept commercial + want proven + polished.
  - **Choose Ansible if:** you want DIY + YAML config-management.
- **PROJECT HEALTH**: active + docs + demo + Discord + roadmap. Strong signals for a newer infrastructure tool.

## Links

- Repo: <https://github.com/vitodeploy/vito>
- Homepage: <https://vitodeploy.com>
- Demo: <https://demo.vitodeploy.com>
- Install VPS: <https://vitodeploy.com/getting-started/installation.html#install-on-vps>
- Install Docker: <https://vitodeploy.com/getting-started/installation.html#install-via-docker>
- Discord: <https://discord.gg/uZeeHZZnm5>
- Roadmap: <https://github.com/orgs/vitodeploy/projects/5>
- Coolify (alt polyglot): <https://coolify.io>
- Dokploy (alt): <https://dokploy.com>
- Dokku (alt): <https://dokku.com>
- CapRover (alt): <https://caprover.com>
- Laravel Forge (commercial alt): <https://forge.laravel.com>
- Ploi (commercial alt): <https://ploi.io>

---
name: YunoHost
description: "Self-hosting operating system. Python/Bash core on Debian. Catalog of 500+ one-click-install apps + SSOwat single-sign-on + user portal. AGPL-3.0. Funded by NLnet/NGI0 + EU. Large community + hosted translation platform."
---

# YunoHost

YunoHost is **"Sandstorm / Cloudron / Umbrel — but Debian-based + OSS + EU-funded"** — a self-hosting OS that makes it easy for non-sysadmins to run their own server. Core is Python + Bash on **Debian 12 (Bookworm)**. Catalog of **500+ one-click apps** (Nextcloud, Mastodon, Jellyfin, Synapse, etc.); each app packaged by community as a `ynh` package. Features SSOwat single-sign-on across all apps; Yunohost-portal user portal; Yunohost-Admin web UI; DNS-diagnosis + Let's Encrypt auto-config + firewall + backup tools.

Built + maintained by **YunoHost organization** + large community. License: **AGPL-3.0**. Funded by **NLnet Foundation / NGI0 PET** (Next Generation Internet / European Commission grant #825310) + Code Lutin + Globenet + Gitoyen + Tetaneutral + Octopuce. Active since 2012; GitLab CI + CodeQL; hosted Weblate translations.

Use cases: (a) **family self-hosting sysadmin-lite** — mom & dad's Nextcloud without them learning Linux (b) **associative/nonprofit hosting** — small NGO running Nextcloud + email + website (c) **privacy-conscious individual** — email + cloud + chat all self-hosted (d) **one-stop sign-on across all apps** — SSOwat provides SSO for Nextcloud + Mastodon + WordPress (e) **Debian-native self-hosting** — stays close to Debian; easy troubleshooting (f) **decentralization activism** — YunoHost ethos + EU funding (g) **replace GAFAM** — comprehensive alternative to Google/Apple/Facebook/Amazon/Microsoft services.

Features (per README + docs):

- **500+ apps** in catalog (Nextcloud, Mastodon, Jellyfin, WordPress, Matrix Synapse, Mailu, etc.)
- **SSOwat SSO** — unified login across all apps
- **Yunohost-portal** — user portal
- **Yunohost-Admin** — admin webUI
- **Let's Encrypt auto-config**
- **DNS diagnosis** + domain-management
- **Firewall management** + port-forwarding
- **Backup tool** — per-app backups
- **User + group management**
- **Multi-domain** hosting

- Upstream repo: <https://github.com/YunoHost/yunohost> (mirror — primary at GitLab)
- GitLab: <https://gitlab.com/yunohost/yunohost>
- Website: <https://yunohost.org>
- Install docs: <https://doc.yunohost.org/admin/get_started/install_on/>
- App catalog: <https://apps.yunohost.org>
- Issue tracker: <https://github.com/YunoHost/issues>
- Community chat: <https://doc.yunohost.org/community/chat_rooms/>
- Translation: <https://translate.yunohost.org>

## Architecture in one minute

- **Debian 12 (Bookworm)** OS base
- **Python + Bash** core
- **nginx** as reverse proxy
- **SSOwat** — Lua/OpenResty SSO
- **Dovecot / Postfix** — email
- **Slapd (OpenLDAP)** — user directory
- **Apps**: packaged `ynh` scripts install native + isolate via nginx confs + systemd units
- **Resource**: depends on apps; base YunoHost = 500MB-1GB RAM; add per-app

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Debian 12 install script** | **`curl | bash`**                                            | **Primary**                                                                        |
| **ISO install**    | Pre-built Debian + YunoHost ISO                                                                            | For fresh installs                                                                                   |
| **Raspberry Pi image** | Pre-built Pi image                                                                                                              | Home labs                                                                                   |
| **VPS**            | Install on existing Debian 12 VPS                                                                                                                   |                                                                                    |
| Docker             | Unofficial; community                                                                                                                   | NOT recommended                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Debian 12 fresh install | Bare-metal OR VPS                                                                                       | Infra        | **Fresh Debian** — not on existing heavily-customized systems                                                                                    |
| Domain               | `example.org`                                               | URL          | Main domain; DNS points to this host                                                                                    |
| Public IP (if home) | Static IP OR DynDNS                                        | Network      |                                                                                    |
| Ports open           | 22, 25, 53, 80, 443, 587, 993, 5222, 5269, …               | Network      | **Many ports** — self-hosted email requires SMTP open                                                                                    |
| Admin creds          | First-boot                                                                                 | Bootstrap    | Strong password                                                                                    |
| Users to create      | Per-member accounts                                                                                                   | Bootstrap    | LDAP-backed                                                                                    |

## Install (on fresh Debian 12)

```sh
# Follow the official install script:
curl https://install.yunohost.org | bash
# Then configure via web UI at https://<your-ip>/
```

## First boot

1. Fresh Debian 12 → run install script
2. Browse IP → complete post-install (domain + admin password)
3. Configure DNS (YunoHost diagnoses your setup)
4. Enable Let's Encrypt for admin domain
5. Install first app from catalog (e.g., Nextcloud)
6. Create regular users
7. Test SSO across apps
8. Configure backup
9. Enable firewall rules appropriate for selected apps
10. Review diagnosis tool weekly

## Data & config layout

- `/etc/yunohost/` — YunoHost config
- `/var/www/` — web-app content
- `/home/yunohost.app/<app>/` — app data dirs
- `/var/mail/` — Dovecot mailboxes
- `/home/<user>/` — user homes (Dovecot + apps)
- `/etc/nginx/conf.d/` — nginx confs per domain
- `/etc/yunohost/apps/<app>/backup/` — backup archives

## Backup

```sh
# Built-in: per-app backup
yunohost backup create --apps nextcloud --name nc-$(date +%F)
# Or full system backup
yunohost backup create --system --name yh-$(date +%F)
# Backups land in /home/yunohost.backup/archives/
# Offsite-copy to remote:
rsync -avP /home/yunohost.backup/ backup-host:/backups/yunohost/
```

## Upgrade

1. Releases: on YunoHost project channels; Debian-package-based
2. `yunohost tools upgrade` (YunoHost packages) OR `apt upgrade` (standard Debian)
3. App upgrades: `yunohost app upgrade <app>` per app OR bulk upgrade in UI
4. **BACKUP BEFORE MAJOR YUNOHOST VERSION UPGRADES** (Debian distro upgrade)

## Gotchas

- **WHOLE-OS TOOL = MAXIMUM THREAT SURFACE**:
  - YunoHost IS the OS, not an app on top
  - Compromise = root + ALL apps + ALL user data
  - **72nd tool in hub-of-credentials family — Tier 1 CROWN-JEWEL category: "OS-as-PaaS"**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "OS-as-PaaS" (holistic-server-management-tool)** — 1st tool named (YunoHost)
  - **CROWN-JEWEL Tier 1: 15 tools; 14 sub-categories**
- **SINGLE ADMIN ACCOUNT = SINGLE POINT OF COMPROMISE**:
  - Admin access = root on host = all apps + all user data
  - **MANDATORY**: strong password + 2FA for admin account
  - SSH keys + `PermitRootLogin no`
  - Separate admin-user from personal-user
- **SELF-HOSTED EMAIL COMPLEXITY**:
  - YunoHost includes Postfix + Dovecot + SpamAssassin + ClamAV
  - **Self-hosted email is HARD**: SPF + DKIM + DMARC + PTR + reputation + blacklist monitoring
  - Without perfect setup: your email goes to SPAM or is rejected
  - **Recipe convention: "self-hosted-email-deliverability-hazard" callout** (reinforces EspoCRM 103 precedent)
- **APP CATALOG TRUST MODEL**:
  - Apps in catalog are community-packaged
  - Quality varies — from "Tested+Maintained" ★★★ to "Unofficial" ★
  - **Recipe convention: "community-packaged-app-quality-tiers" callout**
  - **NEW recipe convention**
- **MULTI-APP SHARED SECRETS**:
  - User passwords stored in OpenLDAP
  - All apps authenticate against same directory
  - If LDAP compromised → all-apps compromised
  - **Centralized-auth = single-point-of-failure pattern**
  - **Recipe convention: "centralized-LDAP-auth-attack-vector" callout**
- **SSOwat SESSION-COOKIES + DOMAIN-WIDE**:
  - SSO cookies span domain — stolen cookie = all-apps access
  - HttpOnly + Secure + SameSite flags matter
- **DEBIAN-BASED = DEBIAN-SECURITY-MATURE**:
  - Benefit: apt-security for system packages
  - Benefit: well-understood threat model
  - **Recipe convention: "Debian-base positive-signal"** (widely-tested-OS-base)
  - **NEW positive-signal convention**
- **YUNOHOST IS OPINIONATED**:
  - Configures nginx/postfix/dovecot/slapd/fail2ban/etc. according to its model
  - Manual edits to these can break YunoHost upgrades
  - **Recipe convention: "opinionated-OS-don't-edit-underlying-configs" callout**
  - **NEW recipe convention**
- **MANY PORTS OPEN = MANY SERVICES EXPOSED**:
  - SMTP (25), submission (587), IMAPS (993), XMPP (5222/5269), HTTPS (443), SSH (22)
  - Each port = attack surface
  - Fail2ban is configured; review thresholds
- **DNS SETUP IS TRICKY**:
  - Need A/AAAA records + MX + SPF + DKIM + DMARC + DANE (optional)
  - YunoHost's diagnosis tool helps identify issues
  - **Ongoing monitoring**: diagnosis should be checked regularly
- **RESIDENTIAL-IP + SMTP = DELIVERABILITY PROBLEM**:
  - ISPs block/throttle outbound SMTP
  - Residential IPs often on spam blocklists (DUL, Spamhaus PBL)
  - **Mitigation**: SMTP relay (Mailjet, Postmark) OR VPS instead of home
- **AGPL-3.0 NETWORK-SERVICE-DISCLOSURE**:
  - YunoHost itself AGPL
  - Modifications must be disclosed
  - **14th+ tool in AGPL-network-service-disclosure convention**
- **EU-FUNDED = POLICY-ALIGNED**:
  - NLnet / NGI0 / EU grants = public-interest funding
  - Signal of public-good mission
  - **Recipe convention: "EU-public-interest-grant-funded positive-signal"** — institutional-backing beyond corporate sponsor
  - **NEW positive-signal convention** (YunoHost 1st named)
- **INSTITUTIONAL-STEWARDSHIP TIER**: **58th tool — "multi-sponsor + public-interest-funded + formal-organization" sub-tier** (**NEW sub-tier** — distinct from "founder-with-commercial-tier" and "large-community-project": YunoHost has NGO-like structure + EU funding + multiple sponsors + formal translation platform)
  - **NEW sub-tier: "EU-public-interest-funded project"** — 1st tool (YunoHost)
- **TRANSPARENT-MAINTENANCE**: active-since-2012 + GitLab+GitHub + CodeQL + CI + coverage + Weblate + chat-rooms + multi-sponsor + multi-repo-organization + ISO-releases + app-catalog. **66th tool in transparent-maintenance family** — one of the STRONGEST signal profiles.
- **ALTERNATIVES WORTH KNOWING:**
  - **Cloudron** — commercial PaaS-for-self-hosting; simpler UX
  - **Sandstorm** — OSS PaaS; grain-based sandboxing (different model)
  - **Umbrel** — home-server OS; crypto/Bitcoin focus
  - **CasaOS** — home-server OS; friendly UX
  - **FreedomBox** — Debian-Pure-Blends similar philosophy
  - **Runtipi** — newer docker-based
  - **DietPi** — minimal + optimized Debian; tool-of-choice-before-apps
  - **Choose YunoHost if:** you want Debian-native + 500+ catalog + SSO + email + AGPL + EU-funded + mature + large community.
  - **Choose Cloudron if:** you want commercial-support + polished UX (paid).
  - **Choose Umbrel / CasaOS if:** you want Docker-based + home-server focus.
  - **Choose FreedomBox if:** you're Debian-pure + want FSF-aligned.
- **PROJECT HEALTH**: 12+ years + EU-funded + GitLab+GitHub + Weblate + CI + CodeQL + multi-sponsor + 500+ apps + docs + chat + forum. **EXCEPTIONAL HEALTH.**

## Links

- GitHub: <https://github.com/YunoHost/yunohost>
- GitLab: <https://gitlab.com/yunohost/yunohost>
- Website: <https://yunohost.org>
- Docs: <https://doc.yunohost.org>
- App catalog: <https://apps.yunohost.org>
- Cloudron (alt commercial): <https://www.cloudron.io>
- Sandstorm (alt OSS): <https://sandstorm.io>
- Umbrel (alt home-server): <https://umbrel.com>
- CasaOS (alt home-server): <https://casaos.io>
- FreedomBox (alt Debian-pure): <https://www.freedombox.org>
- NLnet funding: <https://nlnet.nl>
- NGI0 PET: <https://nlnet.nl/PET>

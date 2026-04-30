---
name: mailcow (dockerized)
description: Full-featured self-hosted mail server suite. Postfix + Dovecot + Rspamd + SOGo + Clamd + SOLR + nginx + acme + Redis + MariaDB + Unbound — all wired together via docker-compose. Webmail, CalDAV/CardDAV, ActiveSync, DKIM/SPF/DMARC, per-domain admin, quarantine. GPL-3.0.
---

# mailcow (dockerized)

mailcow is the gold-standard "here's a mail server you can actually run yourself" project. It bundles ~15 Docker containers — each a best-in-class mail component — into a coherent, opinionated stack with:

- **Postfix** (SMTP), **Dovecot** (IMAP/POP3/LMTP + Sieve)
- **Rspamd** (spam filtering + DKIM signing)
- **SOGo** (webmail + CalDAV + CardDAV + ActiveSync)
- **ClamAV** (antivirus)
- **Solr** (IMAP full-text search)
- **Unbound** (recursive DNSSEC resolver)
- **acme.sh** (Let's Encrypt)
- **MariaDB** + **Redis** + **nginx**
- **Fail2ban-equivalent** in netfilter container
- **mailcow UI** — web admin for domains/users/aliases/quarantine/backups/settings

You run `./install.sh`, answer a few prompts, edit `mailcow.conf`, `docker compose up -d`, point DNS, done.

⚠️ **Mail hosting is hard.** Deliverability (not getting flagged as spam) requires perfect DNS (SPF/DKIM/DMARC/PTR/MX), a clean IP reputation, and sometimes regulatory (receiving mail for EU customers = GDPR territory). Self-hosting is feasible but every problem is YOUR problem.

- Upstream repo: <https://github.com/mailcow/mailcow-dockerized>
- Website: <https://mailcow.email>
- **Docs: <https://docs.mailcow.email>** — the single source of truth; README is just a link to them
- Community: <https://community.mailcow.email>
- Discord: <https://discord.gg/Vgp5Nuxu>

## Hard requirements (read before committing)

- **Dedicated public IPv4 with forward + reverse DNS.** PTR record must match your hostname (`mail.example.com` → IP → back to `mail.example.com`). Wrong PTR = mail flagged as spam.
- **Clean IP reputation.** Cheap VPS providers often have IPs on spam blocklists (check at <https://mxtoolbox.com/blacklists.aspx>). You'll fight an uphill battle if your IP is listed.
- **Outbound port 25 (SMTP) unblocked** — Hetzner, OVH, Vultr allow; AWS/GCP/Azure block by default.
- **Proper SPF + DKIM + DMARC DNS** records set up before sending any mail.
- **MX record** pointing at your mailcow host.
- **At least 6 GB RAM** (upstream minimum; 8+ GB comfortable).
- **Don't run on a shared host.** mailcow expects exclusive ports 25/80/110/143/443/465/587/993/995/4190/8083. Port conflicts break things subtly.
- **Backups matter.** mail loss = customer's angry phone call.

## Architecture in one minute

~15 Docker containers on a shared bridge network, orchestrated by a single docker-compose.yml + `mailcow.conf`. Key interaction:

- **Incoming mail**: port 25 → postfix → rspamd (spam) → dovecot (store)
- **Outgoing mail**: submission 465/587 → postfix → rspamd (sign with DKIM) → upstream SMTP
- **Users read mail**: webmail at `/SOGo/` or IMAP/POP3/ActiveSync from clients
- **Admin UI**: <https://mail.example.com> (domain + user + alias + quarantine management)

## Compatible install methods

| Infra                 | Runtime                                               | Notes                                                                     |
| --------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------- |
| Dedicated VPS         | Docker + `mailcow-dockerized`                         | **Only supported path**                                                    |
| Single VM (AWS/GCP/Azure) | ❌ port 25 usually blocked                        | Use a relay service (Mailgun, AmazonSES) for outbound, or pick a different cloud |
| Kubernetes            | ❌ not supported; containers expect specific networking | Don't try                                                             |
| Managed               | None from upstream — but consider **Migadu**, **Fastmail**, **mailu.io** SaaS |                                                           |

## Inputs to collect

| Input                   | Example                                      | Phase     | Notes                                                                |
| ----------------------- | -------------------------------------------- | --------- | -------------------------------------------------------------------- |
| Mail hostname (FQDN)    | `mail.example.com`                           | DNS       | **PERMANENT** — baked into many certs + configs                       |
| Public IP + PTR record  | IP + `mail.example.com`                      | DNS       | **Critical** for deliverability                                       |
| DNS records             | MX, SPF, DKIM (after setup), DMARC            | DNS       | See "DNS setup" section below                                         |
| Admin creds             | `admin` / admin-pw                            | Bootstrap | Default login — change immediately                                    |
| Timezone                | `America/New_York`                            | Runtime   | `TZ` in mailcow.conf                                                  |
| HTTP/HTTPS ports        | `80 / 443`                                    | Network   | Admin UI + SOGo webmail                                               |
| SMTP/IMAP ports         | `25 / 465 / 587 / 993 / 995 / 143 / 110`      | Network   | Standard mail ports — must be open inbound                            |

## Install (upstream path)

```sh
# On a dedicated VPS with Docker + docker-compose installed
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized

# Generate mailcow.conf (interactive — asks hostname, TZ, ports)
./generate_config.sh

# Edit mailcow.conf if needed (HTTP_BIND, HTTPS_BIND, SMTP_PORT, etc.)
# Default: binds to all interfaces

# Pull images + start
docker compose pull
docker compose up -d

# Watch logs until everything is up (2-5 min first time)
docker compose logs -f
```

Browse `https://mail.example.com` → log in `admin` / `moohoo` → **change password immediately**.

Then:

1. **Domains** → Add your domain → copy the DKIM public key
2. Set DNS:
   - `MX 10 mail.example.com.`
   - `mail.example.com. A <your-IP>`
   - SPF: `v=spf1 mx -all` (or `v=spf1 ip4:YOUR_IP -all`)
   - DKIM: `dkim._domainkey TXT "v=DKIM1; k=rsa; p=<public-key from UI>"`
   - DMARC: `_dmarc TXT "v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com"`
   - PTR: ask your hosting provider to set `<IP> PTR mail.example.com.`
3. **Mailboxes** → Add users
4. Test receiving: send from a Gmail to `test@example.com`
5. Test sending: check at <https://www.mail-tester.com> — aim for 10/10

## DNS checklist

A full deliverability-ready zone for `example.com`:

```
; Mail
example.com.         IN  MX   10  mail.example.com.
mail.example.com.    IN  A        <public-ip>
mail.example.com.    IN  AAAA     <public-ipv6>

; SPF
example.com.         IN  TXT  "v=spf1 mx -all"

; DKIM (key from mailcow UI)
dkim._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIIBIj..."

; DMARC
_dmarc.example.com.  IN  TXT  "v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com; ruf=mailto:postmaster@example.com; fo=1"

; Optional: MTA-STS + TLSRPT
_mta-sts.example.com. IN TXT "v=STSv1; id=20260430"
_smtp._tls.example.com. IN TXT "v=TLSRPTv1; rua=mailto:tlsrpt@example.com"

; Autodiscover (helps clients)
autoconfig.example.com. IN A <public-ip>
autodiscover.example.com. IN CNAME mail.example.com.
```

Plus PTR set via your hosting provider.

## Data & config layout

Inside `mailcow-dockerized/`:

- `mailcow.conf` — top-level config (hostname, TZ, ports, password strength)
- `data/` — volumes for every service:
  - `vmail-vol-1/` — **your mail** (Dovecot maildir)
  - `mysql-vol-1/` — MariaDB data
  - `redis-vol-1/` — Redis
  - `rspamd-vol-1/` — Rspamd learnings + maps
  - `clamd-db-vol-1/` — ClamAV signature DB
  - `solr-vol-1/` — IMAP search index (rebuildable)
  - `postfix-vol-1/`, `crypt-vol-1/` — queue + keys
- `docker-compose.yml` — do not edit by hand; use `docker-compose.override.yml` for customizations

## Backup

**Upstream ships a backup tool**: `./helper-scripts/backup_and_restore.sh`. Do NOT try to `tar` the data directories while running.

```sh
# Backup to /opt/mailcow-backups
./helper-scripts/backup_and_restore.sh backup all --delete-days 7

# Schedule via cron
0 2 * * * cd /opt/mailcow-dockerized && ./helper-scripts/backup_and_restore.sh backup all --delete-days 7 > /var/log/mailcow-backup.log 2>&1

# Offsite: rsync /opt/mailcow-backups to a second host (Borg / Restic / Kopia)
```

Restore: `./helper-scripts/backup_and_restore.sh restore` — interactive menu.

## Upgrade

```sh
cd mailcow-dockerized
./update.sh           # upstream's canonical upgrade script
# Takes 5-20 min; pulls new images, applies migrations, restarts
```

`update.sh` handles:

- Pulling git repo for compose + config changes
- Pulling new images
- Applying migrations
- Restarting services in correct order

**ALWAYS back up first.** mail downtime during upgrade = customer alerts.

Don't skip major versions — upstream tests consecutive versions; skipping = unsupported.

## Gotchas

- **IP reputation is everything for outbound.** A fresh VPS IP may take weeks to build reputation with Gmail/Microsoft. For business-critical mail, use a **relay service** (AWS SES, Mailgun, Postmark, SendGrid) for outbound while self-hosting inbound.
- **Port 25 blocked outbound** on AWS/GCP/Azure by default. Request unblock (AWS: SES + elastic IP), or use a relay. Hetzner/OVH/Vultr allow by default.
- **Reverse DNS (PTR) MUST match your hostname.** Set via hosting provider's panel, not mailcow. `mail.example.com` → IP → should resolve back to `mail.example.com`.
- **DKIM key rotation**: mailcow UI lets you regenerate; DNS update is manual.
- **Default admin password `moohoo`** — change on first login.
- **Let's Encrypt** is automatic via `acme-mailcow`; requires your FQDN to resolve to the mailcow host on port 80/443.
- **Receiving mail for wildcard** requires MX for each domain you want + proper reverse DNS.
- **SOGo webmail** is at `/SOGo/` (with capital SOGo); mailcow admin UI is at `/`.
- **ActiveSync (Exchange-like)** works via SOGo — iOS / Android can use it natively.
- **Memory**: start with 6 GB, allocate 8+ GB if running ClamAV + Solr. ClamAV DB alone is ~1.5 GB RAM.
- **ClamAV disable**: edit `mailcow.conf`: `SKIP_CLAMD=y` — cuts RAM use significantly but no AV scan.
- **Solr disable**: `SKIP_SOLR=y` — loses IMAP full-text search across messages but drops ~1 GB RAM.
- **IPv6** enabled by default via Docker compose (`ENABLE_IPV6=y`); disable with care (breaks some delivery when recipient has AAAA).
- **`docker-compose.override.yml`** is where customizations go; `docker-compose.yml` is overwritten by `update.sh`.
- **Quota management** is per-mailbox; set at user creation in UI.
- **Sieve filters** per-user via SOGo UI.
- **MAX_MESSAGE_SIZE** default ~50 MB; raise for large attachments.
- **Quarantine** holds spam-scoring messages; admins + users can release them.
- **No native migration tool from Exchange / Google Workspace** — use `imapsync` for mailbox migration.
- **Two-factor auth** for admin + users via WebAuthn / TOTP.
- **OIDC SSO** for the UI via Keycloak/Zitadel/etc. (v2024+).
- **GPL-3.0 license.** Modifying + redistributing = must share source.
- **Alternatives worth knowing:**
  - **Mailu** — simpler, less Ruby/PHP heavy, Python-based UI
  - **Mail-in-a-Box** — fully opinionated Ubuntu installer, even more hand-holding
  - **Poste.io** — single-container (proprietary free tier + paid)
  - **Stalwart** (separate recipe) — modern, Rust, all-in-one, promising
  - **Mailcow vs Mailu** decision: mailcow is more feature-complete + bigger community; Mailu is lighter + k8s-friendlier (not officially, but easier to adapt).
  - **Hosted**: Migadu, Fastmail, Posteo, Protonmail — save yourself the deliverability fight unless you specifically need self-hosted.

## Links

- Repo: <https://github.com/mailcow/mailcow-dockerized>
- Website: <https://mailcow.email>
- Docs: <https://docs.mailcow.email>
- Quick install: <https://docs.mailcow.email/getstarted/install/>
- Prerequisites: <https://docs.mailcow.email/prerequisite/prerequisite-system/>
- DNS configuration: <https://docs.mailcow.email/prerequisite/prerequisite-dns/>
- Backup / restore: <https://docs.mailcow.email/backup_restore/b_n_r-backup/>
- Update (upgrade): <https://docs.mailcow.email/maintenance/update/>
- Community: <https://community.mailcow.email>
- Discord: <https://discord.gg/Vgp5Nuxu>
- Deliverability test: <https://www.mail-tester.com>
- Blocklist check: <https://mxtoolbox.com/blacklists.aspx>

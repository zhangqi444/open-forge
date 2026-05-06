---
name: modoboa
description: Modoboa recipe for open-forge. Django-based mail hosting and management platform. Integrates with Postfix + Dovecot; adds admin panel, webmail, DMARC reports, Amavis frontend, and per-user Sieve filters. Self-hosted via official installer script or Docker. Source: https://github.com/modoboa/modoboa. Docs: https://modoboa.readthedocs.io.
---

# Modoboa

Mail hosting and management platform built on Django + Vue. Provides a modern web admin panel for managing mail domains, accounts, and aliases on top of Postfix (SMTP) and Dovecot (IMAP/POP3). Ships a webmail, DMARC report viewer, Amavis spam/antivirus frontend, per-user Sieve filters, calendar, and address book as extensions. Upstream: <https://github.com/modoboa/modoboa>. Docs: <https://modoboa.readthedocs.io>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal (Ubuntu 22.04/24.04) | Official installer script | Strongly recommended; configures Postfix, Dovecot, NGINX, and Modoboa together |
| VPS / bare metal | Manual Python/Django install | For advanced customisation; complex — follow docs carefully |
| VPS | Docker | Community Docker setup available; not as actively maintained as the installer |

> **Linux VPS strongly recommended:** Running a mail server requires a clean dedicated IP with good reputation, PTR record, and ports 25/587/993 open. Shared hosting or residential IPs are typically blocked by major providers.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Mail domain (e.g. example.com)?" | The domain users will have addresses on |
| hostname | "Server hostname (FQDN)?" | e.g. mail.example.com; must have A record and matching PTR/rDNS |
| db | "PostgreSQL or MySQL?" | Installer supports both |
| db | "Database password?" | For modoboa DB user |
| admin | "Admin email and password?" | First superuser account |
| tls | "TLS certificate via Let's Encrypt?" | Installer can auto-provision via certbot |

## Software-layer concerns

- Stack: Postfix (SMTP) + Dovecot (IMAP) + NGINX + Modoboa (Django app) + PostgreSQL/MySQL
- Config: /etc/modoboa/settings.py (Django settings); mail config in /etc/postfix/ and /etc/dovecot/
- Default ports: 25 (SMTP), 587 (submission), 993 (IMAPS), 995 (POP3S), 443 (web admin + webmail)
- Extensions (installed separately): modoboa-radicale (CalDAV/CardDAV), modoboa-amavis, modoboa-dmarc
- Database: central coordination point between Postfix, Dovecot, and Modoboa via SQL lookups
- Spam filtering: Amavis + SpamAssassin + ClamAV (optional, configured by installer)

### Install via official installer (recommended)

```bash
# On a fresh Ubuntu 22.04 VPS
sudo apt-get install -y python3-pip python3-venv git

# Get the installer
git clone https://github.com/modoboa/modoboa-installer.git
cd modoboa-installer

# Run (interactive; answers drive the full stack setup)
sudo python3 run.py --domain mail.example.com --hostname mail.example.com
```

Installer repo: https://github.com/modoboa/modoboa-installer  
Installer docs: https://modoboa-installer.readthedocs.io

### Post-install

1. Access admin panel at https://mail.example.com/admin (or /modoboa/)
2. Create your first domain and mailbox
3. Configure DNS: MX record → mail.example.com, SPF, DKIM, DMARC records
4. Test with: `swaks --to test@example.com --server mail.example.com`

### Key DNS records to set

```
@         MX   10  mail.example.com
mail      A        <server-ip>
mail      PTR      mail.example.com   (set at VPS provider)
@         TXT      "v=spf1 mx ~all"
_dmarc    TXT      "v=DMARC1; p=none; rua=mailto:dmarc@example.com"
mail._domainkey TXT  "<dkim-public-key from installer>"
```

## Upgrade procedure

1. Pull latest installer: `git pull` in modoboa-installer/
2. Re-run installer with `--upgrade` flag, or follow manual upgrade steps in docs
3. Django: `python manage.py migrate && python manage.py collectstatic`
4. Restart services: `sudo systemctl restart modoboa uwsgi nginx`
5. Check release notes: https://github.com/modoboa/modoboa/releases

## Gotchas

- **Clean IP required**: Port 25 is blocked by many ISPs and cloud providers (AWS, GCP, Oracle Cloud). Use a VPS provider that allows port 25 and has good IP reputation. Hetzner, OVH, and Contabo generally allow it.
- **PTR/rDNS record**: Your server IP must have a reverse DNS record pointing to your mail hostname. Set this at your VPS provider's control panel. Without it, many mail servers reject your emails.
- **SPF/DKIM/DMARC all required**: Modern mail servers will reject or spam-folder email from servers missing these DNS records. The installer generates DKIM keys; add all three record types.
- **Port 25 vs 587**: Port 25 is for server-to-server (MX delivery). Users should submit via port 587 (STARTTLS submission). Some providers block outbound 25 but allow 587.
- **Amavis/ClamAV RAM**: If you enable spam/AV scanning, ClamAV alone needs ~1 GB RAM. Total stack with AV needs 2–4 GB minimum.
- **Fresh server only**: The installer is designed for fresh Ubuntu servers. Running it on an existing server with other services may conflict.

## Links

- Upstream repo: https://github.com/modoboa/modoboa
- Docs: https://modoboa.readthedocs.io
- Installer repo: https://github.com/modoboa/modoboa-installer
- Installer docs: https://modoboa-installer.readthedocs.io
- Release notes: https://github.com/modoboa/modoboa/releases

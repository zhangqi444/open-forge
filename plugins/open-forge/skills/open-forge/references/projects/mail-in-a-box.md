---
name: Mail-in-a-Box
description: One-click email appliance that turns a fresh Ubuntu 22.04 LTS box into a complete mail server (SMTP/IMAP/CardDAV/CalDAV/webmail + DNS + DKIM/SPF/DMARC/DNSSEC + TLS + antispam + backups + control panel). CC0-1.0.
---

# Mail-in-a-Box

Mail-in-a-Box (MiaB) is **not a Docker app**. It's a collection of bash scripts (`setup/*.sh`) that turn a **dedicated, completely fresh** Ubuntu 22.04 LTS 64-bit machine into a working mail server. It installs and configures ~30 system packages (postfix, Dovecot, Nextcloud for CardDAV/CalDAV, z-push, Roundcube, nsd, spamassassin, fail2ban, duplicity, nginx, munin, …), publishes the right DNS records, auto-provisions Let's Encrypt certs, and gives you a web control panel for user/alias/DNS management.

Treat it as an appliance OS layer, not an app that fits into an existing stack. The goals are stated explicitly by the author:

> - Make deploying a good mail server easy.
> - Have automated, auditable, and idempotent configuration.
> - **Not** make a totally unhackable, NSA-proof server.
> - **Not** make something customizable by power users.

- Upstream repo: <https://github.com/mail-in-a-box/mailinabox>
- Website + setup guide: <https://mailinabox.email>
- Discussion forum (the only support channel): <https://discourse.mailinabox.email/>

## Compatible install methods

| Infra         | Runtime                              | Notes                                                                    |
| ------------- | ------------------------------------ | ------------------------------------------------------------------------ |
| Dedicated Ubuntu 22.04 LTS VM | `setup/start.sh`      | **The only supported path.** Must be 64-bit, fresh, no conflicting services |
| Dedicated bare metal          | Same                 | Same as VM                                                                |
| Docker                        | ❌ **Not supported**  | Author explicitly does not support this                                  |
| Kubernetes                    | ❌ **Not supported**  | See above                                                                 |
| VPS sharing with other apps   | ❌ **Not supported**  | MiaB reconfigures DNS, iptables, nginx, postfix — will conflict            |

## Inputs to collect

| Input                    | Example                                | Phase        | Notes                                                            |
| ------------------------ | -------------------------------------- | ------------ | ---------------------------------------------------------------- |
| Domain                   | `example.com`                          | DNS          | The main email domain                                            |
| Hostname                 | `box.example.com`                      | DNS          | FQDN of the server itself (used for HELO, MX, TLS SAN)          |
| Static IPv4 (+IPv6 ideal) | `203.0.113.42`                        | Networking   | **Required.** Dynamic IP or CGNAT = deliverability death         |
| PTR record               | `203.0.113.42` → `box.example.com`     | Deliverability | **Mandatory.** Ask your VPS provider to set the reverse DNS     |
| TCP ports                | 22, 25, 53, 80, 443, 465, 587, 993, 995, 4190 | Firewall | All required open — MiaB will open them itself via `ufw`         |
| DNS control              | at your registrar                      | DNS          | MiaB prefers "glue" records to be its authoritative DNS; otherwise provide instructions to paste into your existing DNS |
| First user email         | `you@example.com`                      | Bootstrap    | Set by `setup/firstuser.sh` after install                        |

## Install (upstream-documented)

Per <https://mailinabox.email/guide.html>:

```sh
# 1. Provision a fresh Ubuntu 22.04 LTS 64-bit VPS with a static IPv4 (and ideally IPv6).
#    Do not install Docker, nginx, mail software, or any web server on it beforehand.
# 2. Set a PTR record at your VPS provider pointing the IP → box.example.com.
# 3. SSH in as root (or `sudo -i`).
# 4. Install:
curl -s https://mailinabox.email/setup.sh | sudo -E bash
```

The script is interactive: it'll ask for the email address of the first user, for `box.example.com`, and walk you through DNS record publication at your registrar.

The whole install takes 10–20 minutes on a 1 GB RAM VPS (the minimum; 2 GB recommended). Reboot is not required.

### Using a specific release tag

Upstream recommends pinning to a release tag rather than running `main`:

```sh
git clone https://github.com/mail-in-a-box/mailinabox
cd mailinabox
git checkout v75         # or whatever current release is
sudo setup/start.sh
```

Release tags are on <https://github.com/mail-in-a-box/mailinabox/releases>.

## Post-install

- Control panel: `https://box.example.com/admin` — first user (set during install) is the admin.
- Webmail (Roundcube): `https://box.example.com/mail`
- Nextcloud (contacts + calendar only; not full Nextcloud): `https://box.example.com/cloud`

Autoconfig profiles for Thunderbird / Apple Mail / mobile email apps are served from `box.example.com/.well-known/autoconfig/`. Users set up their clients by entering email + password only — the client fetches server settings automatically.

## Daily operations

MiaB installs `/etc/cron.daily/mailinabox` which runs `management/daily_tasks.sh`:

- Checks certificate expiry; renews Let's Encrypt certs automatically
- Scans for low disk / failed services
- Emails the admin a daily status report

Check health manually at any time:

```sh
sudo management/status_checks.py
```

## Data & config layout

- `/home/user-data/` — all user email (in Maildir format), Nextcloud data, Roundcube prefs, DKIM keys
- `/home/user-data/backup/` — duplicity snapshots (incremental daily)
- Configuration: spread across `/etc/{postfix,dovecot,nginx,…}` in files owned + overwritten by MiaB scripts
- Control-panel-managed DNS: `/etc/nsd/` (MiaB runs its own authoritative DNS server for your mail domains)

## Backup

MiaB backs up `/home/user-data/` daily via `duplicity` to:

- **Local** disk (`/home/user-data/backup/encrypted/`) by default — insufficient for disaster recovery
- **S3, B2, rsync, MinIO, or SFTP remote** — configure in the admin UI under System → Backup Status

Backup encryption uses a password MiaB generates and stores at `/home/user-data/backup/secret_key.txt`. **Back up this file separately** — without it, your backups are unrecoverable.

```sh
# Manual backup:
sudo management/backup.py

# Verify backup integrity:
sudo management/backup.py --verify
```

## Upgrade

1. Pull new release tag: `cd /root/mailinabox && git fetch --tags && git checkout vXX`.
2. Run `sudo setup/start.sh` again — idempotent, upgrades in place.
3. Release notes: <https://github.com/mail-in-a-box/mailinabox/releases>.
4. **Do NOT upgrade past what your Ubuntu version supports.** MiaB major versions track specific Ubuntu LTS releases (v60+ = Ubuntu 22.04). Running `start.sh` on mismatched Ubuntu = broken box.
5. Ubuntu-version upgrades (e.g. 18.04 → 22.04) are documented manual migrations; usually easier to spin up a fresh box and `duplicity` restore backup.

## Gotchas

- **"Fresh Ubuntu 22.04 LTS" means FRESH.** MiaB will fail or break if another web server, mail stack, DNS server, or firewall is already configured. Docker co-existence is especially problematic — MiaB's iptables rules conflict with Docker's.
- **No Docker image, ever.** The author has explicitly rejected Dockerization. Third-party MiaB-in-Docker repos exist but are unsupported and diverge from upstream.
- **Customization = void warranty.** The author states "**Not** make something customizable by power users." Editing `/etc/postfix/main.cf` by hand will get your change overwritten on next upgrade. Use the admin control panel, or fork.
- **Port 25 ISP blocks kill deliverability.** AWS, GCP, Azure, most US residential ISPs block outbound :25. You need a VPS that allows SMTP (Hetzner, OVH, DigitalOcean-after-request, Linode, Vultr-after-request). Test before you install.
- **PTR (reverse DNS) is mandatory.** The IP → `box.example.com` PTR must match your HELO hostname, or Gmail/Outlook will greylist or reject your mail. Set at your VPS provider's control panel; not something MiaB can fix.
- **MiaB wants to be your authoritative DNS server.** If you use Cloudflare / Route53 for DNS, MiaB will still work but you have to manually paste DKIM/SPF/DMARC/TLSA/MTA-STS records into your existing DNS. Admin panel shows exactly what to publish.
- **DNSSEC setup requires glue records at your registrar.** MiaB enables DNSSEC by default; if your registrar doesn't support DS records, you must disable DNSSEC in MiaB (admin panel) or sending/receiving will break for DNSSEC-aware peers.
- **IPv6 recommended but optional.** Gmail + ProtonMail strongly prefer IPv6 senders. Adding an IPv6 AAAA + PTR after install is trivial; skipping leaves you in a slower-to-deliver tier.
- **`SMTPUTF8` is NOT supported.** International domain names (IDN) work for domain parts but not local parts of addresses. Clearly flagged in upstream README.
- **1 GB RAM minimum, but 2 GB is realistic.** spamassassin + ClamAV are memory-hungry. 1 GB instances OOM under attack bursts.
- **No tech support from the author.** The README is explicit: do not email / tweet Josh. Post on <https://discourse.mailinabox.email/> — community-driven.
- **Alternatives worth knowing:**
  - **iRedMail** — commercial, more customizable, distro-agnostic
  - **Modoboa** — French project, customizable admin UI
  - **Mailu** — Docker-native, opinionated, reasonably polished
  - **Mailcow (dockerized)** — Docker-native, more modern UI, active development
  - **Postal** (outbound transactional only)
  - **Roll-your-own Postfix/Dovecot/etc.**
- **Backups without the `secret_key.txt` are worthless.** Duplicity encrypts with this key. Lose it = lose the ability to restore.
- **Nextcloud included is a stripped-down install** — only the Contacts + Calendar apps. Don't expect to install arbitrary Nextcloud apps on it; this Nextcloud is owned + overwritten by MiaB.
- **The "quickstart" is still a full day**. Getting DNS right, letting records propagate, running the status check until green — plan 2–8 hours end-to-end.
- **Deliverability is hard-mode regardless.** Even with MiaB's best-in-class DKIM/SPF/DMARC/DNSSEC setup, Gmail's first impression of a new IP is "probably spam". Expect weeks of building sender reputation before critical mail lands in recipients' inboxes reliably.

## Links

- Repo: <https://github.com/mail-in-a-box/mailinabox>
- Setup guide: <https://mailinabox.email/guide.html>
- Releases: <https://github.com/mail-in-a-box/mailinabox/releases>
- Discourse forum: <https://discourse.mailinabox.email/>
- Security details: <https://github.com/mail-in-a-box/mailinabox/blob/main/security.md>
- Status check internals: <https://github.com/mail-in-a-box/mailinabox/blob/main/management/status_checks.py>
- Alternatives: iRedMail <https://www.iredmail.org/>, Mailu <https://mailu.io/>, Mailcow <https://mailcow.email/>, Modoboa <https://modoboa.org/>

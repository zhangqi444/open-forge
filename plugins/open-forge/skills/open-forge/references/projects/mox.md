---
name: Mox
description: "Modern, full-featured, secure, all-in-one self-hosted mail server — SMTP + IMAP4 + webmail + SPF/DKIM/DMARC/DANE/MTA-STS + per-user Bayesian spam filter, in a single Go binary. Goal: low-maintenance mail for your own domain. MIT."
---

# Mox

Mox is **a modern full-stack mail server in a single Go binary** — SMTP (receive/submit/deliver) + IMAP4 + Webmail + comprehensive anti-spam (Bayesian + reputation + tempering) + all the modern email auth standards (SPF / DKIM / DMARC / DANE / MTA-STS / TLSRPT / REQUIRETLS) + automatic TLS via ACME. Target use case: **run your own email for your own domain with minimum ops work**.

Distinct from:
- **Postfix + Dovecot + Rspamd + Roundcube + Certbot + OpenDKIM + ...** (the traditional stack, which mox replaces as a single binary)
- **Mailcow / Mailu / docker-mailserver** (Docker-compose stacks wrapping the traditional stack)
- **Proton Mail / Fastmail / Gmail** (hosted SaaS)

Created by **Mechiel Lukkien** (a mail-protocol veteran). The project is exceptionally well-engineered: heavily cross-referenced with the RFCs, automated interop tests vs Postfix, manually tested vs Gmail/Outlook/Yahoo/Proton. Still **actively developed** + **single primary maintainer** — read that as both "thoughtful design" and "bus factor risk" when planning production use.

Features:

- **SMTP** — receive, submit, deliver, with extensions (SIZE, PIPELINING, STARTTLS, AUTH, ENHANCEDSTATUSCODES, CHUNKING, REQUIRETLS, etc.)
- **IMAP4** — client access with extensions (IDLE, CONDSTORE, QRESYNC, MOVE, SPECIAL-USE, LIST-EXTENDED, etc.)
- **Webmail** — read/send from browser
- **Full email auth stack** — SPF, DKIM (signing + verification), DMARC, DMARC aggregate reports
- **DANE + MTA-STS** for inbound + outbound STARTTLS safety
- **REQUIRETLS** — sensitive mail refuses cleartext fallback
- **Bayesian spam filter** — per-user, learns from Junk/Non-Junk moves
- **Reputation tracking** — per-user learning of host/domain/sender reputation
- **Greylisting-like delays** for unknown senders
- **Internationalized email (EIA/IDN)** — unicode localparts + domains
- **Automatic TLS (ACME)** — Let's Encrypt + others
- **Account autodiscovery** — SRV records, Microsoft-style, Thunderbird autoconfig, Apple mobileconfig
- **Built-in HTTP server / reverse-proxy** — so port 443 can serve both mail-web and your websites
- **Webhooks + simple HTTP/JSON API** — for transactional mail sending/receiving
- **Prometheus metrics** + structured logging
- **`mox localserve`** — local mail testing environment
- **`mox quickstart`** — bootstrap a working setup in one command

- Upstream repo: <https://github.com/mjl-/mox>
- Website: <https://www.xmox.nl>
- Author: Mechiel Lukkien <mechiel@ueber.net>

## Architecture in one minute

- **Single statically-linked Go binary** — all protocols in-process
- **BoltDB / local disk** — accounts, messages, config
- **Config files**: `mox.conf` (server) + `domains.conf` (domains, accounts, aliases) — plain text, editable
- **Data layout**: per-account mailboxes on disk (Maildir-ish)
- **Resource**: very light — ~100-200 MB RAM idle for small deployments; scales
- **No external DBs needed** (unlike Postfix + MySQL/PG setups)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Dedicated VM       | **Native binary + systemd via `mox quickstart`**                   | **Upstream-recommended**                                                           |
| Dedicated VM       | Community Docker images                                                       | Works; networking can be tricky (port 25 passthrough)                                                                        |
| Cloud VPS          | **Needs PTR record + unblocked port 25** — most consumer ISPs block :25                 | Critical prerequisite                                                                                     |
| Raspberry Pi       | Possible but NOT recommended for production (residential IP + :25 blocks + deliverability)                               |                                                                                                                                         |
| Kubernetes         | Rare — mail servers don't benefit from K8s patterns                                                                                   |                                                                                                                                                                       |

## Inputs to collect

| Input                     | Example                                          | Phase        | Notes                                                                          |
| ------------------------- | ------------------------------------------------ | ------------ | ------------------------------------------------------------------------------ |
| Dedicated hostname        | `mail.example.com`                                     | DNS          | **Must be dedicated** to mail (not shared with web/other services); PTR matches                        |
| Domain(s)                 | `example.com` (email addresses), + any aliases                    | Config       | Added via `mox quickstart`                                                                             |
| Static public IP          | with **matching PTR record** (rDNS)                                    | Network      | **Mandatory** for deliverability — Gmail/Outlook reject mail from mismatched rDNS                                     |
| Unblocked port 25         | must reach + be reachable                                                          | Network      | Most residential/consumer ISPs block :25; VPS needed                                                                                           |
| DNS control               | Ability to add MX, SPF (TXT), DKIM (TXT), DMARC (TXT), MTA-STS, TLSRPT, DANE (TLSA) | DNS          | Required — mox prints the records to add                                                                                                                   |
| DNSSEC                    | recommended (enables DANE)                                                                                   | DNS          | Unbound resolver strongly recommended                                                                                                                                      |
| TLS cert (ACME)           | Let's Encrypt                                                                                                         | Security     | Auto via mox + port 80/443                                                                                                                                                               |
| Admin/account passwords   | Generated by `mox quickstart`                                                                                                    | Bootstrap    | Save securely                                                                                                                                                                                        |

## Install via `mox quickstart`

Per upstream README, a dedicated VM named `mail.example.com`:

```sh
# As root on the mail VM:
useradd -m -d /home/mox mox
cd /home/mox
# Download the binary matching your platform from:
# https://github.com/mjl-/mox/releases
# Or build from source: go install github.com/mjl-/mox@latest

./mox quickstart you@example.com
```

`quickstart` generates:
- `mox.conf` + `domains.conf`
- Admin + account passwords (printed)
- **All DNS records you must add** (MX, SPF, DKIM, DMARC, MTA-STS, TLSRPT, autoconfig, DANE TLSA)
- systemd unit install commands

Add the DNS records, start mox, verify with <https://mxtoolbox.com>, <https://dmarcian.com>, <https://internet.nl>. Send test mail to Gmail/Outlook; check delivery + auth headers.

## First boot

1. Run `mox quickstart` → follow all DNS-record instructions precisely
2. Verify DNS propagation (dig + external tools)
3. Start mox + verify listening on 25, 465, 587, 143, 993, 80, 443
4. Log in to webmail at `https://mail.example.com/webmail/`
5. Test send to Gmail + Outlook — check SPF/DKIM/DMARC pass in received headers
6. Test receive from Gmail + Outlook
7. Add additional accounts + aliases via admin UI or `domains.conf`
8. Configure Thunderbird/iOS autodiscovery via SRV records (mox prints them)

## Data & config layout

- `/home/mox/config/mox.conf` — server config
- `/home/mox/config/domains.conf` — domains, accounts, aliases
- `/home/mox/data/` — message store, BoltDB, ACME certs, logs
- Edit configs; `mox restart` or reload

## Backup

```sh
# Data (messages + state) — CRITICAL
mox stop                 # consistent snapshot
sudo tar czf mox-$(date +%F).tgz /home/mox/config /home/mox/data
mox start
```

**Email data is irreplaceable** + messages often have legal/retention significance. Back up daily + test restore.

## Upgrade

1. Releases: <https://github.com/mjl-/mox/releases>. Active; careful semver.
2. **Back up everything.**
3. Stop mox → replace binary → start → mox handles migrations.
4. Read release notes — occasionally requires manual steps for significant version jumps.

## Gotchas

- **Running your own mail server is HARD — even with mox.** Mox handles the software side beautifully; the **operational challenges are independent of software**:
  - **Deliverability**: Gmail/Outlook/Yahoo may silently classify your mail as spam for months until your IP's reputation builds. New IPs start as suspect.
  - **IP blocklists**: check <https://mxtoolbox.com/blacklists> — VPS IPs are often on lists. Request delisting individually.
  - **ISP block on :25**: most residential ISPs block outbound/inbound 25. Requires VPS.
  - **rDNS / PTR mismatch**: your VPS must have PTR = `mail.example.com`. VPS providers usually allow setting this (Hetzner, OVH, Linode, DO, Vultr all do; some cloud providers don't without opening a ticket).
  - **SPF/DKIM/DMARC**: all three MUST pass for modern deliverability. Mox configures + signs correctly; you must publish the DNS records precisely.
  - **Spam received**: even with Bayesian, expect spam. Tune filters.
- **Single maintainer**: mox is primarily one person (Mechiel). Excellent code + responsive, but plan for bus factor — have a migration plan (Postfix/Dovecot can read Maildirs; some tooling required).
- **Young project (pre-1.0 as of writing — check current)**: verify release status. Config format may still evolve. Pin versions; test upgrades.
- **DANE**: requires DNSSEC on your zone. If your registrar/DNS provider doesn't do DNSSEC, skip DANE and rely on MTA-STS.
- **MTA-STS**: requires HTTPS on `mta-sts.example.com` serving a policy file. Mox includes the webserver for this.
- **Webserver/reverse-proxy feature**: mox can serve websites on 443 too — useful to consolidate on one machine. Not a replacement for nginx at scale.
- **Port 465 vs 587**: modern clients use 465 (implicit TLS submission). 587 (STARTTLS submission) also supported.
- **IMAP limits**: mox's IMAP implementation is excellent but edge clients (very old Outlook versions, obscure mobile clients) may have issues. Test your client suite.
- **Migration from existing server**: use IMAP-sync tool (imapsync) to move mailboxes from Postfix/Dovecot to mox.
- **Not a groupware**: no calendar/contacts/CalDAV/CardDAV. Pair with Radicale / Baïkal / Nextcloud.
- **No LDAP/OIDC (yet)**: users are local; no directory integration. Check current status — on roadmap possibly.
- **Aliases + catch-all**: configured in `domains.conf` — straightforward.
- **Autodiscovery**: mox generates Thunderbird autoconfig + Outlook autodiscover + Apple mobileconfig — huge UX win, but clients support varies.
- **Webmail**: functional + clean; not as polished as Roundcube/SOGo. Improving.
- **Mailing list handling**: basic; not a Mailman replacement.
- **GDPR / privacy**: self-hosting = you are the data controller + processor; responsibilities apply. DPAs, retention, subject access rights all on you.
- **License**: **MIT** (Go Authors BSD-3 components; Public Suffix List MPL-2.0).
- **Legal hold**: for businesses, configure retention + legal-hold workflows separately; mox doesn't do compliance-grade discovery.
- **Alternatives worth knowing:**
  - **Postfix + Dovecot + Rspamd + Roundcube** — the traditional stack; huge flexibility; huge ops burden
  - **docker-mailserver** — Docker-based traditional stack wrapper
  - **Mailcow** — complete Docker email suite with full UI
  - **Mailu** — another Docker email stack
  - **Stalwart Mail Server** — another modern single-binary Rust mail server; similar target to mox
  - **Maddy Mail Server** — Go, modular; in the same single-binary-modern space
  - **Proton Mail / Fastmail / Tutanota / Mailbox.org** — hosted (recommended if you don't want to operate)
  - **SimpleLogin / AnonAddy** — email aliasing in front of primary mail (batch 63 SimpleLogin)
  - **Choose mox if:** modern single-binary + great defaults + you're willing to operate a mail server.
  - **Choose Stalwart if:** you prefer Rust or want a different modern-stack option.
  - **Choose Mailcow if:** you want a turnkey Docker suite + richer UI ecosystem.
  - **Choose hosted (Fastmail/Proton) if:** you value your time; don't self-host mail unless you have a reason.

## Links

- Repo: <https://github.com/mjl-/mox>
- Website: <https://www.xmox.nl>
- Releases: <https://github.com/mjl-/mox/releases>
- Author: <mailto:mechiel@ueber.net>
- internet.nl (test): <https://internet.nl>
- mxtoolbox (test): <https://mxtoolbox.com>
- Stalwart (alt modern): <https://stalw.art>
- Maddy (alt modern Go): <https://maddy.email>
- Mailcow (alt Docker): <https://mailcow.email>
- docker-mailserver (alt): <https://github.com/docker-mailserver/docker-mailserver>
- Postfix (alt traditional): <https://www.postfix.org>
- Fastmail (alt hosted): <https://www.fastmail.com>
- Proton Mail (alt hosted): <https://proton.me/mail>

---
name: AnonAddy / addy.io
description: "Self-hosted anonymous email forwarding — create unlimited aliases that forward to your real inbox, anonymously reply from them, encrypt via your GPG key. Laravel + MySQL + Postfix. Protects real email from spam + data-breach cross-referencing. AGPL-3.0."
---

# AnonAddy / addy.io

AnonAddy (rebranded to **addy.io**) is **"SimpleLogin + GPG + self-hostable"** — unlimited email aliases that forward to your real inbox, letting you give out distinct, revocable emails per service. Kill spam by deactivating an alias; identify which company sold your data by seeing which alias gets spam; reply anonymously without revealing your real address; **GPG-encrypt inbound mail** with your own key so even if the AnonAddy server is compromised, stored mail is unreadable.

Built + maintained by **Will Browning** (UK-based, solo core dev with community). Public about design, roadmap, death-contingency planning (FAQ includes "What happens to addy.io if you die?" — documented continuity).

Features (per FAQ):

- **Unlimited aliases** (self-hosted; cloud has tiered limits)
- **Standard aliases** (on-the-fly creation under your username subdomain or custom domain) + **shared-domain aliases** (pre-generated)
- **Custom domains** — `*@example.com` via MX + SPF + DKIM + DMARC setup
- **GPG/OpenPGP inbound encryption** — your public key encrypts mail before storage
- **Anonymous reply** — reply to forwarded emails without revealing your real address
- **Multiple recipients per alias**
- **Subject replacement** (hide sender-chosen subjects when encrypted)
- **Spoofing-detection banner** — warns when DMARC/SPF failed
- **Apps**: browser extension + Android + iOS + Raycast extension
- **2FA** + hardware key support
- **Open-source self-host** + **commercial cloud** (addy.io) that directly funds upstream

- Upstream repo: <https://github.com/anonaddy/anonaddy>
- Homepage (cloud): <https://addy.io>
- Docs: <https://addy.io/help/>
- Self-host guide: <https://addy.io/self-hosting/>
- Docker: <https://github.com/anonaddy/docker>
- Apps: Android, iOS, browser extension — linked from addy.io
- Support: <https://addy.io/contact/>
- FAQ (exhaustive — read this): <https://github.com/anonaddy/anonaddy/blob/master/README.md>

## Architecture in one minute

- **Laravel / PHP** web app (dashboard + API)
- **MySQL / MariaDB** — user data, aliases, keys
- **Postfix** + **custom MTA configuration** — the actual email forwarding is MTA-level
- **Redis** — sessions + queue
- **Supervisor** — runs Laravel queue workers
- **GPG** — integrates with gpg binary for key-based encryption
- **DNS**: MX + TXT SPF/DKIM/DMARC records for your domain
- **Resource**: modest — 1-2 GB RAM depending on mail volume

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Self-host guide** (Ubuntu/Debian — manual Postfix + Laravel)       | **Upstream-primary** — lengthy procedure                                                   |
| Docker             | **`anonaddy/docker`**                                                   | Simpler; still needs DNS + reverse MX                                                      |
| Managed            | **addy.io cloud** — tiered (Free / Lite / Pro)                                      | Non-self-host option                                                                                    |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `mail.example.com` (subdomain recommended)                       | URL          | Cannot use same domain for MX + as your own receiving inbox                      |
| DNS records          | MX (priority 10 → server) + SPF (`v=spf1 a mx ~all`) + DKIM + DMARC  | DNS          | **CRITICAL** — misconfigured = mail bounces or lands in spam                                     |
| Reverse DNS (PTR)    | PTR for VPS IP must match sending hostname                                | MTA          | Outbound deliverability                                                                                  |
| VPS with port 25     | **Most VPS providers BLOCK port 25 by default** (anti-spam)                          | Infra        | Check: DigitalOcean blocks; Hetzner unblocks on request; AWS blocks; Oracle Cloud blocks                                          |
| Postfix              | Configured for handoff to AnonAddy                                                          | MTA          | Follow upstream self-host guide step-by-step                                                                                         |
| GPG keyring          | per-user public keys                                                                                    | Encryption   | Users upload their own PGP pubkey                                                                                                                  |
| DMARC monitoring     | Consider external service (Dmarcian / Postmark free reports)                                                           | Deliverability | For early diagnosis of mis-sent mail                                                                                                                                           |

## Install

**Read upstream self-hosting guide end-to-end before starting.** AnonAddy self-hosting is one of the HARDEST self-host deployments — email is notoriously difficult.

High-level:
1. Provision VPS with port 25 unblocked, static IP, PTR matching your hostname
2. Set DNS: MX + A + SPF + DKIM (Postfix generates) + DMARC
3. Install stack: PHP, MySQL, Redis, Postfix, Supervisor, Nginx, Composer
4. Deploy AnonAddy Laravel app
5. Wire Postfix to AnonAddy for inbound + outbound handoff
6. Set up TLS (Let's Encrypt)
7. Test with external mail checks (mail-tester.com, dmarcian, port25 tools)
8. Sign up as first user; generate DKIM keys; publish DNS; test full flow

## First boot

1. Register as first user → admin
2. Set up GPG encryption for yourself
3. Add custom domain (if using)
4. Create first alias → test forwarding from external sender
5. Test reply-from-alias flow
6. Run external deliverability tests (mail-tester.com, DMARC report)
7. Download Android/iOS app + browser extension
8. Close open signup if personal/family use

## Data & config layout

- MySQL — user accounts, aliases, GPG pubkey fingerprints, domain config, stats
- `/var/spool/postfix/` — outgoing/incoming mail queues
- `/etc/postfix/main.cf` + `master.cf` — MTA config
- `storage/app/` (Laravel) — attachments (if storing failed deliveries)
- OpenDKIM / DKIM keys — `/etc/opendkim/keys/`

## Backup

```sh
mysqldump --single-transaction -u anonaddy -p anonaddy | gzip > anonaddy-$(date +%F).sql.gz
sudo tar czf anonaddy-config-$(date +%F).tgz /etc/postfix /etc/opendkim /etc/anonaddy /var/www/anonaddy/.env
```

**DKIM private key is THE critical secret** — lose it + DNS still announces corresponding public key → mail rejected. Back it up separately + store offline.

## Upgrade

1. Releases: <https://github.com/anonaddy/anonaddy/releases>.
2. Git-pull + `composer install --no-dev` + migrations.
3. **Back up DB + DKIM keys BEFORE upgrades.**

## Gotchas

- **SELF-HOSTING EMAIL IS HARD.** Expect days of DNS/deliverability debugging. If you're not already operating mail infrastructure, strongly consider the cloud tier (addy.io) that directly funds the project. Email self-hosting is infamous because ONE misconfiguration = mail bounces or spam-folders for months.
- **Port 25 blocking on most VPS providers**: DigitalOcean, AWS, Google Cloud, Oracle, Vultr = blocked by default. Hetzner unblocks on request. OVH varies. Check BEFORE choosing VPS.
- **IP reputation matters**: new VPS IPs often have poor reputation → outbound mail to Gmail/Outlook = spam folder for weeks. Warm up slowly. Or use outbound-relay (Mailgun / Postmark / Amazon SES) — AnonAddy supports this as "smarthost" pattern.
- **Cannot use same domain for MX + recipient**: if `example.com` has MX → AnonAddy, you cannot have `user@example.com` as a RECIPIENT address (mail loops). Use subdomain (`mail.example.com`) for aliases, keep `example.com` for your real inbox. FAQ is explicit.
- **DMARC alignment is subtle**: SPF covers envelope-sender; DKIM covers message-origin; DMARC requires alignment. AnonAddy's docs walk through this; follow exactly. Misconfiguration = outbound rejected.
- **GPG pubkey upload = server-side encryption of inbound mail**: only decryptable by user's private key. Even if AnonAddy server is compromised, user mail is encrypted at rest. HUGE privacy win.
- **Attachments inside encrypted mails** — GPG/PGP typically encrypts whole message including attachments. Verify per your setup.
- **Reply-from-alias requires matching outbound DKIM/SPF/DMARC.** The FAQ notes "I'm trying to reply from an alias but it keeps coming back / is rejected" — almost always DNS misconfiguration.
- **Don't store forwarded emails by default** — AnonAddy only stores mail in event of failed delivery (and only if user opts in). This is the privacy model; don't subvert it.
- **Custom domain requires TXT verification**: same as most domain-verification UX.
- **Bus-factor-1 with explicit death-contingency plan**: FAQ's "What happens to addy.io if you die?" answer = credit to Will Browning for transparency. Self-hosting mitigates this fully (your infra keeps running). Cloud users should read the plan.
- **AGPL-3.0**: if you offer AnonAddy-as-a-service commercially (i.e., compete with addy.io), AGPL §13 requires source disclosure of modifications. For personal/family use, identical to GPL (no extra obligation). Same pattern as WriteFreely/Zoraxy/Rallly/Kan batches 74-77.
- **Ethical commercial tier**: addy.io paid tiers directly fund upstream. Consider if your skills don't extend to Postfix/DKIM wrangling — your subscription = project sustainability.
- **Apps ecosystem**: Android + iOS + browser extension + Raycast — unusual breadth for a small project. Speaks to Will's commitment.
- **Privacy benefits are real but not foolproof**:
  - Aliases still require AnonAddy server to function (DNS MX points there)
  - Attachments + subjects can leak metadata unless GPG-encrypted
  - Legal requests to AnonAddy server can compel logs (unless self-host)
- **Hardware key 2FA support**: WebAuthn-style. Use it.
- **Alternatives worth knowing:**
  - **SimpleLogin** — similar scope; owned by Proton; OSS (AGPL); can self-host
  - **DuckDuckGo Email Protection** — free; cloud-only; less feature-rich
  - **Firefox Relay** — cloud-only; simpler
  - **Addy.io Cloud** — addy.io's own commercial tier (same code)
  - **Postfix + Sieve rules + forwarding** — DIY; no UI, no apps
  - **Choose AnonAddy (self-host) if:** have email-ops skills + want full privacy + custom domain.
  - **Choose addy.io cloud if:** want the feature set without email-ops pain.
  - **Choose SimpleLogin if:** want Proton-integrated ecosystem.

## Links

- Repo: <https://github.com/anonaddy/anonaddy>
- Docker: <https://github.com/anonaddy/docker>
- Homepage / cloud: <https://addy.io>
- Help docs: <https://addy.io/help/>
- Self-hosting guide: <https://addy.io/self-hosting/>
- FAQ: <https://github.com/anonaddy/anonaddy/blob/master/README.md>
- Releases: <https://github.com/anonaddy/anonaddy/releases>
- Sponsor: <https://github.com/sponsors/willbrowningme>
- SimpleLogin (alt): <https://simplelogin.io>
- Postfix: <http://www.postfix.org>
- Mail-tester: <https://www.mail-tester.com>
- Dmarcian: <https://dmarcian.com>
- DKIM + DMARC overview: <https://postmarkapp.com/guides/spf-dkim-dmarc>

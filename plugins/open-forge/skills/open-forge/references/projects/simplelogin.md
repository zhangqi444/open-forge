---
name: SimpleLogin
description: "Open-source email alias service — generate throwaway alias addresses that forward to your real inbox, reply anonymously, block/disable per-alias. Protects your identity from tracking. Runs against your own domain. Python/Flask + Postfix + Postgres. MIT. Acquired by Proton AG — cloud is Proton-run."
---

# SimpleLogin

SimpleLogin is **an email alias manager** — give every service you sign up with a unique `alias@yourdomain.com` address that forwards to your real inbox. Reply from the alias (SimpleLogin rewrites From). Disable an alias when spam starts, or when a vendor breaches + leaks. Your real email stays private, your inbox stays clean, breaches become lookup-tables for which vendor leaked.

> **Ownership + context:**
>
> - **SimpleLogin was acquired by Proton AG** (maker of ProtonMail/Proton VPN) in **2022**. The cloud service at **simplelogin.io** is now operated by Proton; it's included as part of **Proton Unlimited** / stand-alone paid plans.
> - **The self-hosted app is still open-source under MIT.** You can run it on your own server with your own domain.
> - Self-hosted = you own everything but must maintain a full mail server (Postfix + DKIM + DMARC + reverse DNS).

Use cases:

- **Sign up for every service with a unique alias** — `netflix@me.com`, `amazon@me.com`; leaks = you know which vendor
- **Throwaway for one-off downloads / trials**
- **Per-contact alias** — give `alice@me.com` to Alice only; if it leaks, you know
- **Privacy from data brokers**

Features:

- **Alias creation** — random (`abc123@me.com`) or custom (`netflix@me.com`)
- **Directories** — prefix pattern so any `netflix.anything@me.com` routes to you
- **Reply from alias** — recipient sees only the alias
- **Block** — spam-folder any alias instantly
- **Disable / delete** — kill an alias
- **Multiple custom domains** — use `me.com`, `me.net`, etc.
- **Subdomain aliases** — `anything@alias.me.com` catches all
- **Browser extension** — Chrome, Firefox, Safari, Edge — "use my alias" in signup forms
- **Mobile apps** — iOS, Android
- **PGP** — encrypt forwarded emails to your real address with your PGP key
- **Contact management** — create "contacts" (addresses that can email you through alias; others blocked)
- **Auto-create aliases on mail catch-all**
- **SSO** — OIDC/SAML (paid on cloud; configurable on self-host)

- Upstream repo: <https://github.com/simple-login/app>
- Website (cloud): <https://simplelogin.io>
- Docs: <https://simplelogin.io/docs/>
- Proton (parent): <https://proton.me>
- Android app: <https://play.google.com/store/apps/details?id=io.simplelogin.android>
- iOS app: <https://apps.apple.com/us/app/simplelogin/id1494359858>

## Architecture in one minute

SimpleLogin is **an email server with a web API + UI on top**. Components:

- **Web app (Python/Flask)** — web UI + API for alias management
- **Email handler (Python)** — receives mail on Postfix → processes → rewrites + forwards
- **Postfix** — actual MTA (SMTP in/out)
- **Postgres** — users + aliases + contacts + messages metadata
- **Redis** — cache + rate limits
- **nginx** — reverse proxy
- **Optional: webauthn / OIDC / SAML**

Runs as a Docker Compose stack with ~6 containers.

## Compatible install methods

| Infra         | Runtime                                      | Notes                                                                   |
| ------------- | -------------------------------------------- | ----------------------------------------------------------------------- |
| Single VM     | **Docker Compose (official README walkthrough)**  | **Upstream-documented path**                                                |
| Kubernetes    | Community manifests                                       | Possible; nontrivial (mail + DKIM + TLS)                                              |
| Managed       | **simplelogin.io** (Proton-operated)                                    | Use this if you don't want to run a mail server                                                |
| Raspberry Pi  | Viable for light use                                                          | Remember port 25 + reputation concerns                                                                  |

## Inputs to collect (READ THIS BEFORE INSTALLING)

| Input                | Example                             | Phase       | Notes                                                                    |
| -------------------- | ----------------------------------- | ----------- | ------------------------------------------------------------------------ |
| Main domain          | `app.mydomain.com`                      | URL         | SimpleLogin webapp                                                             |
| Mail domain          | `mydomain.com`                              | DNS         | Where alias addresses live                                                             |
| PTR (reverse DNS)    | points to `app.mydomain.com`                    | DNS         | **Required** for mail deliverability                                                                |
| Public IPv4 (ideally static) | server IP                                        | Network     | Port 25 inbound **reachable** + (ideally) outbound allowed                                                                 |
| MX record            | `mydomain.com. MX 10 app.mydomain.com.`                    | DNS         | Primary delivery target                                                                                              |
| DKIM                 | generated during install                                            | DNS         | TXT record                                                                                                                      |
| SPF                  | `v=spf1 mx -all`                                                         | DNS         | TXT record                                                                                                                                      |
| DMARC                | `v=DMARC1; p=quarantine; rua=...`                                                     | DNS         | TXT record                                                                                                                                                  |
| Postgres             | bundled via Compose                                                                    | DB          | Default fine                                                                                                                                                         |
| Admin user           | first signup; promote via DB                                                                            | Bootstrap   | First user is regular; promote to admin manually                                                                                                                                                 |
| PGP (opt)            | your public key                                                                                                 | Privacy     | Forward-encrypt                                                                                                                                                                 |

## Install via Docker Compose

**Follow the official self-hosting README carefully** — <https://github.com/simple-login/app#self-hosting>. Abbreviated:

```sh
mkdir sl && cd sl
# Download example compose + configs
wget https://raw.githubusercontent.com/simple-login/app/master/docker-compose.yml
# Generate DKIM keys
mkdir -p ~/sl/dkim
openssl genrsa -out ~/sl/dkim/dkim.key 1024
openssl rsa -in ~/sl/dkim/dkim.key -pubout -out ~/sl/dkim/dkim.pub.key
# Edit simplelogin.env per upstream template
# Launch
docker compose up -d
```

Postfix + SimpleLogin in its own compose stack; a separate Postfix systemd may need to be disabled on the host.

## DNS setup (summary)

```
# A/AAAA records
app.mydomain.com       A     1.2.3.4
mydomain.com           A     1.2.3.4

# MX
mydomain.com.          MX 10 app.mydomain.com.

# SPF
mydomain.com.          TXT   "v=spf1 mx -all"

# DKIM (key from install)
dkim._domainkey.mydomain.com.    TXT   "v=DKIM1; k=rsa; p=MIGfMA0G..."

# DMARC
_dmarc.mydomain.com.   TXT   "v=DMARC1; p=quarantine; rua=mailto:dmarc@mydomain.com"
```

PTR (reverse): set on your hosting provider control panel — `app.mydomain.com` ← 1.2.3.4.

## First boot

1. Browse `https://app.mydomain.com/` → register first user
2. Promote to admin via DB: `UPDATE "user" SET is_admin = true WHERE email = 'you@example.com';`
3. Log in → Profile → Domains → add custom domains
4. Install browser extension → point at `https://app.mydomain.com/` (not simplelogin.io)
5. Create first alias → test: send email from Gmail to the alias → should land in your real inbox
6. Reply from inbox → recipient sees alias as From

## Data & config layout

- `~/sl/db/` — Postgres
- `~/sl/upload/` — user uploads (attachments)
- `~/sl/dkim/` — DKIM keys
- `simplelogin.env` — all config + secrets

## Backup

```sh
# DB (CRITICAL — email mappings + aliases)
docker exec sl-db pg_dump -U simplelogin simplelogin | gzip > sl-db-$(date +%F).sql.gz
# Uploads
tar czf sl-uploads-$(date +%F).tgz ~/sl/upload/
# Config + DKIM
tar czf sl-config-$(date +%F).tgz ~/sl/dkim/ simplelogin.env
```

Losing DKIM key = you rotate; losing DB = all aliases lost + users locked out. Offsite backup mandatory.

## Upgrade

1. Releases: <https://github.com/simple-login/app/releases>. Active.
2. **Back up DB + DKIM + config.**
3. `docker compose pull && docker compose up -d` → migrations run automatically.
4. Read release notes for breaking env var changes.

## Gotchas

- **Email self-host is HARD.** Same prereq block as Mailu (batch 59): static IP, PTR, port 25 open, IP reputation warm-up, SPF+DKIM+DMARC all configured. **If you can't do mail ops, use simplelogin.io (cloud) instead.**
- **Port 25 outbound**: many cloud providers block :25. Solutions: use Mailgun/SES/Postmark as SMTP relay (SimpleLogin supports this via env vars).
- **Domain ownership** — mail domain = your identity. Don't self-host SimpleLogin on a domain you might lose.
- **Email deliverability**: new IP = lands in spam initially. Check <https://mxtoolbox.com/blacklists.aspx>. Warm up slowly.
- **Reply flow**: when you reply from your inbox to a forwarded alias message, SimpleLogin rewrites the From. If your email client changes the headers weirdly, replies may leak your real address. Test before relying.
- **Attachments**: SimpleLogin proxies attachments; size limits from SMTP stages apply.
- **Webextension endpoint**: point at your self-hosted URL, not the default simplelogin.io.
- **iOS/Android apps** — support custom API endpoints (for self-host).
- **Admin promotion**: first user is regular; manually promote via DB. Make sure to lock registration if public.
- **Anti-abuse**: public self-hosted SimpleLogin can be used by abusers to generate spam aliases. Lock down registration (invite-only) for private use.
- **GDPR**: you're now processing email metadata of senders — document your policy if running multi-user.
- **Multi-tenancy**: supported; each user gets their own domain/aliases; admin sees all.
- **PGP integration**: public-key encrypted forward to your real address. Set up your key in Profile → Preferences → PGP.
- **WebAuthn / 2FA**: enable for your admin account at minimum.
- **License**: MIT (for the app).
- **Proton acquisition**: the cloud now has Proton's backend; self-host code is unchanged MIT. If you worry about "will self-host be abandoned," watch upstream commit activity.
- **Alternatives worth knowing:**
  - **AnonAddy / addy.io** — another open-source alias service; Laravel-based; very similar concept
  - **DuckDuckGo Email Protection** — free SaaS from DuckDuckGo; no self-host
  - **Apple Hide My Email** — Apple-ecosystem-only
  - **Firefox Relay** — Mozilla's; SaaS
  - **Fastmail Masked Email** — paid Fastmail subscribers
  - **Mailu + catch-all** — roll your own with Mailu (separate recipe — batch 59)
  - **Plus-addressing** (`you+netflix@gmail.com`) — free but filterable by spammers
  - **Choose SimpleLogin (cloud) if:** zero ops + Proton ecosystem.
  - **Choose SimpleLogin (self-hosted) if:** you already run mail + want alias control.
  - **Choose AnonAddy/addy.io if:** you prefer PHP stack or want a non-Proton alternative.
  - **Choose DDG Email / Firefox Relay if:** just want it to work, no domain.

## Links

- Repo: <https://github.com/simple-login/app>
- Website: <https://simplelogin.io>
- Docs: <https://simplelogin.io/docs/>
- Self-hosting instructions (in README): <https://github.com/simple-login/app#self-hosting>
- Releases: <https://github.com/simple-login/app/releases>
- Roadmap: <https://github.com/simple-login/app/projects/1>
- Discussions: <https://github.com/simple-login/app/discussions>
- Proton (acquirer): <https://proton.me/mail/aliases>
- Android app: <https://play.google.com/store/apps/details?id=io.simplelogin.android>
- iOS app: <https://apps.apple.com/us/app/simplelogin/id1494359858>
- Chrome extension: <https://chrome.google.com/webstore/detail/dphilobhebphkdjbpfohgikllaljmgbn>
- Firefox add-on: <https://addons.mozilla.org/firefox/addon/simplelogin/>
- AnonAddy/addy.io alternative: <https://addy.io>

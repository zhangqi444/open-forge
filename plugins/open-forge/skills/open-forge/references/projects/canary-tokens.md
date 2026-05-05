---
name: canary-tokens
description: Canarytokens recipe for open-forge. Covers Docker Compose deployment (the upstream-recommended path) from https://github.com/thinkst/canarytokens-docker. Canarytokens is a honeytoken / tripwire system that alerts you when a planted token is triggered.
---

# Canarytokens

Honeytoken / tripwire system. Plant tokens (URLs, DNS entries, documents, AWS credentials, WireGuard configs, and more) in decoy locations; when a token is triggered the server sends an alert via email or webhook. Upstream: <https://github.com/thinkst/canarytokens>. Docker installer repo: <https://github.com/thinkst/canarytokens-docker>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS / bare metal | Docker Compose | Upstream-recommended. `thinkst/canarytokens-docker` ships `docker-compose.yml` + `docker-compose-letsencrypt.yml`. |
| Public-IP server | Docker Compose + Let's Encrypt | `docker-compose-letsencrypt.yml` adds Certbot + NGINX for TLS. Requires ports 80/443 reachable from internet. |
| Internal / air-gapped network | Docker Compose (HTTP only) | Strip NGINX / TLS; tokens only work on reachable domains. DNS tokens require the domain's NS records to point at the server. |

## Requirements (preflight)

- A publicly accessible domain (or subdomain) whose **NS records point at the server** — required for DNS-based tokens to trigger.
- Ports 80 and 443 (or 80 only for non-TLS) open inbound.
- Port 25 open inbound (for SMTP-based tokens; optional).
- At least one email provider configured for outbound alerts: **Mailgun**, **Sendgrid**, **Mandrill**, or raw SMTP. Only one provider may be active at a time.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| dns | "What domain will Canarytokens serve tokens on?" | Must have NS records pointing at this server's IP. |
| tls | "Email for Let's Encrypt / alert notifications?" | Used by Certbot and as CANARY_ALERT_EMAIL_FROM_ADDRESS. |
| smtp | "Which email provider: Mailgun / Sendgrid / Mandrill / raw SMTP?" | Only configure one; leave others blank. |
| smtp | "API key (or SMTP credentials) for the chosen provider?" | Mailgun: CANARY_MAILGUN_API_KEY; Sendgrid: CANARY_SENDGRID_API_KEY; SMTP: CANARY_SMTP_USERNAME + CANARY_SMTP_PASSWORD. |
| smtp | "From address for alert emails?" | CANARY_ALERT_EMAIL_FROM_ADDRESS. |
| smtp | "From display name?" | CANARY_ALERT_EMAIL_FROM_DISPLAY. |
| optional | "ipinfo.io API key for geo-enrichment of alerts?" | CANARY_IPINFO_API_KEY — optional but improves alert quality. |

## Install (Docker Compose)

Clone the installer repo (NOT the main canarytokens repo) and follow the upstream README:

```
git clone https://github.com/thinkst/canarytokens-docker
cd canarytokens-docker
# Edit frontend.env and switchboard.env per the env vars below
# HTTP only:
docker compose up -d
# With Let's Encrypt TLS:
docker compose -f docker-compose.yml -f docker-compose-letsencrypt.yml up -d
```

Do NOT fabricate install steps — follow the upstream README at <https://github.com/thinkst/canarytokens-docker>.

## Software-layer concerns

### Config files

| File | Purpose |
|---|---|
| `frontend.env` | Frontend process settings (domain, upload path, etc.) |
| `switchboard.env` | Switchboard settings (email provider, SMTP, alert throttling) |
| `certbot.env` | Let's Encrypt domain + email (only for TLS compose variant) |

### Key env vars — frontend.env

| Variable | Description |
|---|---|
| `CANARY_DOMAINS` | The token domain (e.g. `tokens.example.com`). Must match NS delegation. |
| `CANARY_NXDOMAINS` | NX-domain used for PDF tokens. |
| `CANARY_WEB_IMAGE_UPLOAD_PATH` | Upload path for web image tokens. Default: `/uploads`. |
| `CANARY_GOOGLE_API_KEY` | Optional Google Maps key for geo display. |
| `LOG_FILE` | Frontend log file name. Default: `frontend.log`. |

### Key env vars — switchboard.env

| Variable | Description |
|---|---|
| `CANARY_PUBLIC_DOMAIN` | Public domain (use instead of CANARY_PUBLIC_IP). |
| `CANARY_MAILGUN_API_KEY` | Mailgun API key. Set only one email provider. |
| `CANARY_MAILGUN_DOMAIN_NAME` | Mailgun sending domain. |
| `CANARY_MAILGUN_BASE_URL` | Set to `https://api.eu.mailgun.net` for EU Mailgun infrastructure. |
| `CANARY_SENDGRID_API_KEY` | Sendgrid API key. |
| `CANARY_MANDRILL_API_KEY` | Mandrill API key. |
| `CANARY_SMTP_SERVER` | SMTP server hostname. |
| `CANARY_SMTP_PORT` | SMTP port (must be StartTLS-capable, e.g. 587). |
| `CANARY_SMTP_USERNAME` | SMTP username. |
| `CANARY_SMTP_PASSWORD` | SMTP password. |
| `CANARY_ALERT_EMAIL_FROM_ADDRESS` | From address for alert emails. |
| `CANARY_ALERT_EMAIL_FROM_DISPLAY` | From display name. For AWS SES: `Display Name <addr@domain>`. |
| `CANARY_ALERT_EMAIL_SUBJECT` | Alert email subject line. Default: `"Alert"`. |
| `CANARY_MAX_ALERTS_PER_MINUTE` | Alert throttle per unique IP per minute. Default: `1000`. |
| `CANARY_IPINFO_API_KEY` | ipinfo.io key for geo-enrichment. |
| `CANARY_FORCE_HTTPS` | Set to force `https` scheme in generated token URLs. |
| `MAX_ALERT_FAILURES` | Webhook is disabled after this many consecutive failures. Default: `5`. |
| `ERROR_LOG_WEBHOOK` | URI for posting error logs. |

### Data directories

| Path | Contents |
|---|---|
| `./data/` | Redis AOF persistence (mapped into Redis container). |
| `./uploads/` | Uploaded images for web-image tokens. |
| `log-volume` (Docker named volume) | Frontend + switchboard log files. |

### Ports exposed by the switchboard container

| Port | Token type |
|---|---|
| 25 -> 2500 | SMTP-based tokens |
| 3306 | MySQL tokens |
| 53 / 53 UDP | DNS tokens |
| 6443 | Kubernetes tokens |
| 8083 | HTTP switchboard API |
| 51820 UDP | WireGuard tokens |

## Upgrade procedure

```
cd canarytokens-docker
git pull
docker compose pull
docker compose down && docker compose up -d
```

Check `docker compose logs frontend` and `docker compose logs switchboard` after restart.

## Gotchas

- **One email provider only.** Configure exactly one of Mailgun / Sendgrid / Mandrill / SMTP. Leave all others blank. Having two set causes undefined behaviour — upstream is explicit about this.
- **NS records are mandatory for DNS tokens.** The token domain's NS records must delegate to this server's IP. An A-record alone is not sufficient.
- **Mailgun EU requires `CANARY_MAILGUN_BASE_URL`.** Omitting it when using EU infrastructure causes silent delivery failures. Set to `https://api.eu.mailgun.net`.
- **SMTP must be StartTLS.** Raw SMTP without STARTTLS is not supported. Port 587 is the expected default. Anonymous SMTP is not supported.
- **AWS SES `CANARY_ALERT_EMAIL_FROM_DISPLAY` format.** Must be `Name <email@domain>` (with angle brackets) for SES to accept it.
- **Alert throttle.** In non-debug mode, at most `CANARY_MAX_ALERTS_PER_MINUTE` alerts per unique source IP are sent per minute. Triggered events are still recorded in Redis even when throttled.
- **Webhook failure auto-disable.** After 5 consecutive webhook errors, that webhook is silently disabled. Tune with `MAX_ALERT_FAILURES`.
- **Port conflicts.** Port 53 (DNS) and port 25 (SMTP) may already be in use on the host (systemd-resolved, Postfix). Stop those services first.

## Upstream docs

- Main README: <https://github.com/thinkst/canarytokens/blob/master/README.md>
- Docker installer README + install instructions: <https://github.com/thinkst/canarytokens-docker>
- FAQ / Wiki: <https://github.com/thinkst/canarytokens/wiki>

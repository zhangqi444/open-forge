---
name: OpnForm
description: "Beautiful open-source form builder + survey tool. No-code drag-drop; unlimited forms + submissions. Laravel+Vue. AGPL-3.0. Cloud tier at opnform.com. Slack/Discord/webhook integrations. Alternative to Typeform/Tally/Google Forms."
---

# OpnForm

OpnForm is **"Typeform / Tally / Google Forms / Jotform — self-hosted and yours"** — a polished open-source form builder. Drag-drop to define forms; publish anywhere (embed, direct URL, QR); collect submissions; get emailed/webhooked; analyze via built-in analytics. Free unlimited forms + submissions (no per-response upcharges). Great conditional logic, many input types (text, date, URL, file upload), Captcha protection. Commercial cloud tier at opnform.com funds dev; self-host as fully-featured alternative.

Built + maintained by **Julien Nahum** (OpnForm founder) + team + community. **License: AGPL-3.0**. Active + growing + managed Cloud (opnform.com) + Discord + Featurebase for feature requests. Rising star in OSS form-builder space.

Use cases: (a) **contact forms** on your website (b) **customer feedback surveys** — NPS, CSAT, open feedback (c) **event registration** — conferences, classes, volunteer signup (d) **lead capture** — marketing-qualified lead forms (e) **internal team surveys** — pulse surveys, decision polls (f) **application forms** — job apps, grant applications, program admissions (g) **replace paid SaaS** (Typeform, Jotform, Google Forms, Microsoft Forms) for reasons of privacy, cost, or customization.

Features (from upstream README):

- **No-code builder** — drag/drop form assembly
- **Unlimited forms + submissions** (self-host OR Cloud pro-tier)
- **Many input types** — text, date, URL, file upload, multi-choice, rating, scale, signature
- **Embed anywhere** — iframe, JS widget, direct URL
- **Email notifications** on submission
- **Integrations** — Slack, Discord, webhooks, Zapier
- **Form logic + conditional questions**
- **Captcha protection** (reCAPTCHA, hCaptcha)
- **Form analytics** — view counts, conversion, drop-off
- **Technical docs** + API at docs.opnform.com
- **Managed Cloud** option with support + backups + upgrades

- Upstream repo: <https://github.com/OpnForm/OpnForm>
- Homepage / managed Cloud: <https://opnform.com>
- Docs: <https://docs.opnform.com>
- Deployment guides: <https://docs.opnform.com/deployment>
- Helpdesk: <https://help.opnform.com>
- Discord: <https://discord.gg/YTSjU2a9TS>
- Feature requests: <https://feedback.opnform.com>
- Docker Hub: <https://hub.docker.com/r/jhumanj/opnform-api>
- Releases: <https://github.com/OpnForm/OpnForm/releases>

## Architecture in one minute

- **Laravel** (PHP) backend — API server
- **Vue.js** frontend — builder + form-render
- **MySQL / PostgreSQL** — DB
- **Redis** — caching / queues
- **Resource**: moderate — 500MB-1GB RAM depending on submission volume + file uploads
- **Split deployment**: separate API + client containers per docs

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Managed Cloud**  | **<https://opnform.com>** — fastest start, fully-managed        | **Cloud tier funds dev**                                                           |
| Docker (production) | Per upstream deployment guides                                           | Self-host production path                                                                                   |
| Docker development | Minimal setup per docs (local dev)                                                         | For testing/dev                                                                                              |
| Bare-metal Laravel | Composer + npm build                                                                                 | DIY                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `forms.example.com`                                         | URL          | TLS MANDATORY                                                                                    |
| DB                   | MySQL / Postgres                                            | DB           | Per docs                                                                                    |
| Admin creds          | First-boot registration                                                                           | Bootstrap    | Strong password                                                                                    |
| `APP_KEY`            | Laravel                                                                                      | **CRITICAL** | **IMMUTABLE**                                                                                                            |
| SMTP                 | For submission-notification emails                                                                                    | Email        | Core feature; configure early                                                                                                            |
| File upload storage  | Local or S3                                                                                                        | Storage      | Submissions with file uploads can grow                                                                                                                            |
| Captcha keys         | reCAPTCHA / hCaptcha API keys                                                                                                            | Integration  | Essential for public forms (spam prevention)                                                                                                                            |

## Install via Docker (production)

Per upstream docs at <https://docs.opnform.com/deployment> — production setup uses separate API + client containers + DB + Redis. Specific compose YAMLs provided upstream.

## First boot

1. Follow upstream deployment guide
2. Register first admin
3. Create first form in builder
4. Test embed + submission
5. Configure SMTP for notifications
6. Configure Captcha before going live (spam protection)
7. Put behind TLS reverse proxy
8. Back up DB + uploaded files

## Data & config layout

- DB — forms, submissions, users, workspaces
- File storage — uploaded submission attachments (MAY be significant)
- `.env` — secrets (APP_KEY, DB, SMTP, Captcha, integrations)

## Backup

```sh
docker compose exec db pg_dump -U opnform opnform > opnform-$(date +%F).sql
sudo tar czf opnform-files-$(date +%F).tgz storage/
```

## Upgrade

1. Releases: <https://github.com/OpnForm/OpnForm/releases>. Active.
2. Docker: pull + migrate.
3. Back up BEFORE major upgrades.

## Gotchas

- **FORMS COLLECT PERSONAL DATA = GDPR + CCPA + HIPAA (if health) ZONES**:
  - **GDPR applies** any time a form collects EU resident data: name, email, anything identifying
  - **Right to erasure** for submissions
  - **Lawful basis** — typically consent (form fill = implicit consent for the purpose stated)
  - **Data subject access request (DSAR)** procedure
  - **If collecting special-category data** (health, political opinion, religion, sexuality, biometric) → Article 9 special-category triggered; needs EXPLICIT consent + stricter safeguards
  - **CCPA (California)** — similar rights + opt-out-of-sale
  - **HIPAA (US)** — if collecting Protected Health Information, form must be HIPAA-compliant OR explicitly not-a-covered-entity
  - **Recipe convention: "data-collection-tool regulatory-framework" section**
- **SPAM + BOT ABUSE = #1 OPERATIONAL PROBLEM**: public forms on the internet get hammered by bots. Configure:
  - **Captcha mandatory** — hCaptcha (privacy-friendly) or reCAPTCHA
  - Rate-limiting per IP
  - Honeypot fields
  - Email validation (syntax + MX check)
  - **Spam filtering on integrations** (don't pipe to Slack/Discord unfiltered)
- **FILE UPLOAD = HIGHER RISK + STORAGE GROWTH**:
  - Malicious files uploaded by form-fillers (malware, phishing)
  - Storage fills quickly with attachments
  - Scan uploads (ClamAV integration if available)
  - Limit file types + sizes
  - Store in separate bucket not accessible via web
- **SURVEY + RESEARCH USE = SIMILAR TO LimeSurvey batch 90**: if using OpnForm for research (surveys, interviews), institutional review / ethics-board oversight applies. GDPR special-category + informed consent + data-retention policy. **15th tool in regulatory-crown-jewel with research sub-family overlap.**
- **HUB-OF-CREDENTIALS Tier 2**: OpnForm stores:
  - All form submissions (customer PII, feedback, opinions)
  - Integration webhook URLs + keys (Slack, Discord, Zapier, custom)
  - SMTP credentials
  - Captcha API keys
  - Admin + user accounts
  - **43rd tool in hub-of-credentials family — Tier 2.**
- **`APP_KEY` IMMUTABILITY** (Laravel): **29th tool in immutability-of-secrets family.**
- **FORM-EMBED + CSP**: embedding OpnForm on third-party sites requires CSP configuration. Verify CORS + CSP headers allow intended embedding; reject unintended.
- **EMAIL NOTIFICATION DELIVERABILITY**: transactional emails (submission notifications) need proper SPF/DKIM/DMARC configured on your SMTP → Gmail + Outlook deliverability. **Common homelab stumble.** Consider using Mailgun/Postmark/SendGrid/AWS SES for reliable delivery rather than DIY SMTP.
- **ANALYTICS TRACKING = ANOTHER GDPR SURFACE**: form-view counts + drop-off analytics track visitor behavior → GDPR cookie-consent concerns if tracking includes identifiable info. OpnForm's analytics appear first-party (server-side), which is cleaner than Google Analytics — still disclose in privacy notice.
- **COMMERCIAL-TIER**: **primary-SaaS-with-OSS-of-record** pattern (similar to Feedbin 89, CommaFeed 92) — opnform.com is the commercial tier, OSS is source-of-record + self-host option. **14+th commercial-tier entry.**
- **INSTITUTIONAL-STEWARDSHIP**: Julien Nahum (founder) + team + Discord. **19th tool in institutional-stewardship family — company sub-tier (OpnForm Inc / similar)**. Cloud-funding makes the project sustainable beyond sole-maintainer.
- **TRANSPARENT-MAINTENANCE**: AGPL + Docker Hub pulls metric + active commits + Featurebase for feature-tracking + helpdesk. **23rd tool in transparent-maintenance family.**
- **AGPL-3.0**: if you modify + offer as network service, must publish changes. Standard for primary-SaaS-OSS-of-record pattern (prevents competitors from lifting code + running hosted service without contributing back).
- **ALTERNATIVES WORTH KNOWING:**
  - **Formbricks** — AGPL; React; modern; similar positioning
  - **LimeSurvey** (batch 90) — PHP; mature; research-focused; GPL-2
  - **SurveyJS** — JS library (not full app)
  - **Formio** — MIT; modular platform; more dev-oriented
  - **Fider** — Go; feedback-specific (feature requests); MIT
  - **Forms.js / Formspark** — minimal DIY tools
  - **Typeform** — commercial SaaS incumbent; polished UX; ad-heavy
  - **Tally** — commercial SaaS; generous free tier
  - **Jotform** — commercial SaaS; feature-rich
  - **Google Forms** — commercial SaaS; integrated with Workspace
  - **Microsoft Forms** — commercial SaaS; integrated with 365
  - **Choose OpnForm if:** you want polished UX + self-host + AGPL + unlimited submissions + modern stack.
  - **Choose Formbricks if:** you want React stack + alternative positioning.
  - **Choose LimeSurvey if:** you want research + complex branching + GPL mature.
  - **Choose Typeform if:** you want SaaS + accept cost + commercial polish.
- **PROJECT HEALTH**: active + AGPL + Cloud funding + Discord + Featurebase + Helpdesk + good documentation + Docker. Well-supported + growing.

## Links

- Repo: <https://github.com/OpnForm/OpnForm>
- Homepage: <https://opnform.com>
- Docs: <https://docs.opnform.com>
- Cloud vs self-host: <https://docs.opnform.com/deployment/cloud-vs-self-hosting>
- Discord: <https://discord.gg/YTSjU2a9TS>
- Helpdesk: <https://help.opnform.com>
- Docker API: <https://hub.docker.com/r/jhumanj/opnform-api>
- Formbricks (alt): <https://formbricks.com>
- LimeSurvey (alt): <https://www.limesurvey.org>
- Typeform (commercial alt): <https://www.typeform.com>
- Tally (commercial alt): <https://tally.so>
- Jotform (commercial alt): <https://www.jotform.com>
- hCaptcha (privacy-friendly captcha): <https://www.hcaptcha.com>
- GDPR: <https://gdpr.eu>

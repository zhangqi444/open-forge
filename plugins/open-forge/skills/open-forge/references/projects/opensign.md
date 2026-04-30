---
name: OpenSign
description: "Free, open-source document e-signing platform — DocuSign / Adobe Sign / HelloSign / PandaDoc alternative. Multi-signer, templates, signing order, OTP verification for guests, PDF annotation, audit log. Parse Server backend + MongoDB + React. AGPL-3.0."
---

# OpenSign

OpenSign is **the open-source document e-signing platform** — a self-hostable alternative to DocuSign, Adobe Sign, HelloSign (Dropbox Sign), PandaDoc, SignNow, SignRequest, Smartwaiver, and Zoho Sign. Upload a PDF, drop signature/initial/date/checkbox widgets, invite signers, collect legally-meaningful e-signatures with audit trail + certificate-of-completion.

Built with **Parse Server** (Node.js BaaS framework) + **MongoDB** + **React** frontend.

Features:

- **Secure PDF e-signing** — hand-drawn, uploaded-image, typed, or saved signatures
- **Multi-signer** — sequential (signing order) or parallel
- **Email OTP for guest signers** — verify signer identity before allowing signature
- **Templates** — reusable PDF forms with pre-placed widgets; one-click sends
- **OpenSign Drive** — document storage within the platform
- **Expiring docs + rejection** — set expiry date; signer can reject with reason
- **Email templates** — customizable HTML invitations + reminders + completion
- **Audit log + certificate of completion** — who signed, when, from what IP, with device fingerprint (legally meaningful in many jurisdictions)
- **API** — programmatic document creation + signing
- **Webhooks** — signed/rejected/viewed events to your systems
- **Branding** — custom logo, colors, domain
- **Self-signing** — "Sign yourself" flow without inviting others
- **QR code signing** — mobile-friendly
- **i18n** — multi-language UI
- **SSO** — OIDC (enterprise edition)

- Upstream repo: <https://github.com/OpenSignLabs/OpenSign>
- Website / cloud: <https://www.opensignlabs.com>
- Docs: <https://docs.opensignlabs.com>
- API docs: <https://docs.opensignlabs.com/docs/API-docs/opensign-api-v-1>
- Discord: <https://discord.com/invite/xe9TDuyAyj>

## Architecture in one minute

- **Backend**: Parse Server (Node.js) — the open-source BaaS framework
- **DB**: MongoDB (Parse's native persistence)
- **Frontend**: React
- **Storage**: local filesystem or S3-compatible for PDFs
- **Email**: SMTP (Mailgun / SendGrid / SES / Mailtrap)
- **PDF manipulation**: server-side (pdf-lib)
- **Docker Compose** is the documented self-host path

## Compatible install methods

| Infra          | Runtime                                                        | Notes                                                                          |
| -------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM      | **Docker Compose (upstream-shipped)**                              | **Upstream-documented**                                                            |
| Single VM      | Native (Node.js + MongoDB + nginx)                                          | Works; more ops                                                                             |
| Kubernetes     | Community Helm / manifests                                                               | Works                                                                                                   |
| Cloud          | **OpenSign Cloud** at opensignlabs.com                                                            | Free tier + paid tiers; hosted                                                                                  |
| Managed        | OpenSign Enterprise (via the company)                                                                       | Paid on-prem + support                                                                                                      |

## Inputs to collect

| Input              | Example                                 | Phase      | Notes                                                                     |
| ------------------ | --------------------------------------- | ---------- | ------------------------------------------------------------------------- |
| Public URL         | `sign.example.com`                          | URL        | Must be HTTPS; PDFs + signing flow need it                                        |
| MongoDB            | connection string                                  | DB         | Bundled or external                                                                      |
| SMTP               | host / port / user / pass                                  | Email      | Required for invites + OTP; critical                                                                |
| JWT / app secrets  | long random                                                     | Security   | Generate via `openssl rand -hex 32`                                                                          |
| Storage            | local or S3                                                                | Files      | PDFs + signed artifacts                                                                                                  |
| Admin user         | created on first boot                                                                    | Bootstrap  | First-signup → admin                                                                                                              |

## Install via Docker Compose

Upstream ships a `docker-compose.yml`. Abbreviated structure:

```yaml
services:
  opensign:
    image: opensignlabs/opensign:latest             # pin in prod
    container_name: opensign
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      MONGODB_URI: mongodb://mongo:27017/opensign
      MASTER_KEY: change-this                        # Parse Server master key
      APP_ID: opensign
      SERVER_URL: https://sign.example.com/app
      PUBLIC_URL: https://sign.example.com
      SMTP_HOST: smtp.example.com
      SMTP_PORT: 587
      SMTP_USER: mailuser
      SMTP_PASS: secret
      SMTP_FROM: "OpenSign <no-reply@example.com>"
    depends_on:
      - mongo
  mongo:
    image: mongo:6
    restart: unless-stopped
    volumes:
      - ./mongo:/data/db
```

Put behind Caddy/Traefik/nginx for TLS.

## First boot

1. Browse `https://sign.example.com` → register → first user may or may not be admin depending on env config
2. Upload a test PDF → drop signature widget → invite a signer via email
3. Sign from signer perspective → verify OTP email flow
4. Download signed PDF + audit certificate — verify the embedded signature in Adobe Acrobat / Foxit
5. Configure custom branding + email templates

## Data & config layout

- MongoDB — documents, templates, users, signing sessions, audit logs
- PDF storage — filesystem or S3
- Env vars — all config

## Backup

```sh
# Mongo dump (CRITICAL — legal audit trail)
docker exec opensign-mongo mongodump --db opensign --archive | gzip > opensign-db-$(date +%F).gz
# PDF storage
tar czf opensign-files-$(date +%F).tgz files/
# env/.env
cp .env opensign-env-$(date +%F).bak
```

**Audit logs have legal weight — back up religiously + retain per your compliance requirements (7 years in US/EU for some contracts).**

## Upgrade

1. Releases: <https://github.com/OpenSignLabs/OpenSign/releases>. Active.
2. Back up Mongo + files.
3. `docker compose pull && docker compose up -d`. Parse migrations auto.

## Gotchas

- **Legal enforceability** — e-signatures are legally binding in most jurisdictions (US ESIGN Act, EU eIDAS, India IT Act, etc.), but enforceability depends on signer identity verification + audit trail + consent. OpenSign's OTP + audit + certificate-of-completion hits common requirements. **Consult a lawyer for high-value contracts.**
- **Email OTP is the identity-verification backbone** — SMTP must be rock solid. If emails don't arrive, signers can't verify → workflow breaks. Use transactional email provider (Mailgun/SendGrid/SES), not Gmail SMTP.
- **HTTPS mandatory** — signers see the URL; browsers warn on insecure; some signers will refuse to sign on HTTP.
- **Certificate of Completion**: automatically generated. Verify it's embedded in the downloaded PDF (Adobe validates it).
- **Signature types**: draw, upload image, type. Be aware: typed signatures carry less legal weight than drawn+audited in contested cases.
- **Signer authentication levels**:
  - None (click "Sign") — low assurance
  - Email OTP — medium (default)
  - Add: ID verification / SMS OTP / knowledge-based auth — higher (may need integrations)
- **Data residency** — if EU signers or GDPR-covered data, host in EU region.
- **Retention policy** — document signed PDFs + audit logs retention per regulation. Don't auto-delete; they may be needed for 7+ years.
- **Storage**: PDFs accumulate. Move to S3 with lifecycle → Glacier for cold retention.
- **Rate limiting** — prevent abuse. Reverse proxy or built-in.
- **API tokens**: treat like passwords. Rotate on staff changes.
- **Webhooks**: verify signatures (OpenSign signs webhook payloads with a secret) on your receiver.
- **Mobile signing**: QR code + mobile-friendly signing page. Test on actual phones before going live.
- **Watermarks**: built-in for pending docs (optional).
- **Compared to DocuSign**: OpenSign covers 80-90% of DocuSign's core signing features. Missing: some enterprise workflow automation, advanced identity verification (DocuSign ID Verify), deep CRM integrations (but has webhooks + API).
- **Compared to Documenso**: another open-source e-sign (Next.js + Postgres); different architecture + simpler install; fewer features (separate recipe likely).
- **License**: AGPL-3.0. Check LICENSE for specifics; enterprise edition has its own terms.
- **Commercial options**: OpenSign Cloud (SaaS) has free + paid; OpenSign Enterprise for on-prem with support.
- **Alternatives worth knowing:**
  - **Documenso** — Next.js + Postgres; cleaner UX; fewer advanced features (separate recipe likely)
  - **SignServer** — Java-based; enterprise-grade digital signature (PKI); different use case
  - **DocuSeal** — Rails-based; also self-hostable (separate recipe likely)
  - **LibreSignOffice** / **LibreSign** (Nextcloud app) — Nextcloud ecosystem
  - **DocuSign** / **Adobe Sign** / **HelloSign** / **SignNow** / **PandaDoc** (SaaS)
  - **BoldSign** (SaaS, free tier)
  - **Choose OpenSign if:** you want the most feature-complete OSS DocuSign alternative with multi-signer, templates, OTP, audit.
  - **Choose Documenso if:** you want modern UX + simpler self-host + lighter footprint.
  - **Choose DocuSeal if:** Rails ecosystem + simpler workflows.
  - **Choose DocuSign (SaaS) if:** enterprise integrations + global identity verification matter most.

## Links

- Repo: <https://github.com/OpenSignLabs/OpenSign>
- Website: <https://www.opensignlabs.com>
- Docs: <https://docs.opensignlabs.com>
- API docs: <https://docs.opensignlabs.com/docs/API-docs/opensign-api-v-1>
- Installation guide: <https://docs.opensignlabs.com/docs/self-hosted/install-opensign-in-local-environment>
- Docker Hub: <https://hub.docker.com/r/opensignlabs/opensign>
- Releases: <https://github.com/OpenSignLabs/OpenSign/releases>
- Discord: <https://discord.com/invite/xe9TDuyAyj>
- Twitter: <https://twitter.com/opensignlabs>
- Blog: <https://www.opensignlabs.com/blog>
- Parse Server (underlying): <https://parseplatform.org>
- Documenso (alt): <https://github.com/documenso/documenso>
- DocuSeal (alt): <https://github.com/docusealco/docuseal>

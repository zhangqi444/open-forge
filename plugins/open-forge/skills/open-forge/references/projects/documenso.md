---
name: Documenso
description: Open-source DocuSign alternative. Upload a PDF, add signer fields, send for signature, collect cryptographically signed PDFs. Node.js (Next.js/Remix) + Postgres + optional S3. AGPL-3.0 (community) / commercial (Enterprise).
---

# Documenso

Documenso is the OSS drop-in for DocuSign / HelloSign / Dropbox Sign / Adobe Sign. You upload a PDF, drop text/signature/date/checkbox fields on it, email it to signers; they sign in-browser; you receive the final signed PDF with an embedded digital signature (PKCS#7 / CAdES) that PDF viewers recognize.

Community edition includes core signing workflows + audit trail + certificates. Enterprise adds team features (org admin, SSO, white-label, advanced auth, compliance features).

- Upstream repo: <https://github.com/documenso/documenso>
- Website: <https://documenso.com>
- Docs: <https://docs.documenso.com>
- Self-hosting: <https://docs.documenso.com/self-hosting>
- Docker install: <https://docs.documenso.com/self-hosting/deployment/docker-compose>
- Cloud: <https://documenso.com> (hosted tier)

## Architecture in one minute

- **`documenso`** — Node.js web app (Next.js / Remix during migration period)
- **Postgres 15+** — main DB (users, documents, templates, fields, recipients, audit log)
- **PKCS#12 signing certificate** — mounted as a file or provided via env; used to sign completed PDFs
- **Optional S3** — document storage backend (replaces local disk); recommended for prod
- **Optional SMTP** — for sending "please sign this" emails and receipts

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                                     |
| ----------- | ---------------------------------------------------- | ------------------------------------------------------------------------- |
| Single VM   | Docker Compose (upstream-documented)                 | **Recommended**                                                            |
| Single VM   | Docker with external Postgres + S3                   | For production                                                             |
| Kubernetes  | Community manifests / Helm                            | Works; stateless app + external DB + S3                                    |
| Managed     | Documenso Cloud                                       | <https://documenso.com/pricing>                                            |
| Vercel      | Serverless (works, but signing cert storage is tricky) | Self-hosted on Vercel documented in self-hosting docs                    |

## Inputs to collect

| Input                                | Example                                      | Phase     | Notes                                                            |
| ------------------------------------ | -------------------------------------------- | --------- | ---------------------------------------------------------------- |
| Public URL                           | `https://documenso.example.com`              | DNS       | `NEXT_PUBLIC_WEBAPP_URL` — baked into email links                 |
| `NEXTAUTH_SECRET`                    | `openssl rand -base64 32`                    | Security  | NextAuth.js session signing                                       |
| `NEXT_PRIVATE_ENCRYPTION_KEY`        | `openssl rand -base64 32` (≥32 chars)        | Security  | **Critical** — encrypts stored document secrets                   |
| `NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY` | `openssl rand -base64 32` (≥32 chars)    | Security  | For key rotation; can be same as primary initially                |
| Postgres creds                       | user/pw/db                                   | DB        | Postgres 15+                                                      |
| **PKCS#12 signing certificate**      | `cert.p12` file + passphrase                | Security  | **REQUIRED** — without it, signed PDFs are "unsigned"; see below  |
| SMTP                                 | host/port/user/pass/from                     | Email     | Required for workflow emails                                      |
| Optional S3                          | bucket/region/access-key/secret              | Storage   | Offload document storage                                          |

## Install via Docker Compose

From <https://docs.documenso.com/self-hosting/deployment/docker-compose>:

```yaml
name: documenso-production

services:
  database:
    image: postgres:15
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER:?err}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:?err}
      - POSTGRES_DB=${POSTGRES_DB:?err}
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${POSTGRES_USER}']
      interval: 10s
      retries: 5
    volumes:
      - database:/var/lib/postgresql/data

  documenso:
    image: documenso/documenso:v1.11.0      # pin; avoid :latest in prod
    restart: unless-stopped
    depends_on:
      database: { condition: service_healthy }
    env_file: [.env]
    ports:
      - ${PORT:-3000}:${PORT:-3000}
    volumes:
      - /opt/documenso/cert.p12:/opt/documenso/cert.p12:ro

volumes:
  database:
```

`.env` (core):

```sh
# Database
POSTGRES_USER=documenso
POSTGRES_PASSWORD=<strong>
POSTGRES_DB=documenso

# Secrets — all ≥32 chars
NEXTAUTH_SECRET=<openssl rand -base64 32>
NEXT_PRIVATE_ENCRYPTION_KEY=<openssl rand -base64 32>
NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY=<openssl rand -base64 32>

# Public URL
NEXT_PUBLIC_WEBAPP_URL=https://documenso.example.com
NEXT_PRIVATE_INTERNAL_WEBAPP_URL=http://localhost:3000

# Database URL (must match Postgres creds above)
NEXT_PRIVATE_DATABASE_URL=postgresql://documenso:<strong>@database:5432/documenso
NEXT_PRIVATE_DIRECT_DATABASE_URL=postgresql://documenso:<strong>@database:5432/documenso

# SMTP
NEXT_PRIVATE_SMTP_TRANSPORT=smtp-auth
NEXT_PRIVATE_SMTP_HOST=smtp.example.com
NEXT_PRIVATE_SMTP_PORT=587
NEXT_PRIVATE_SMTP_USERNAME=<user>
NEXT_PRIVATE_SMTP_PASSWORD=<pw>
NEXT_PRIVATE_SMTP_FROM_NAME=Documenso
NEXT_PRIVATE_SMTP_FROM_ADDRESS=noreply@example.com

# Signing certificate
NEXT_PRIVATE_SIGNING_PASSPHRASE=<cert-password>

# Optional: restrict signup
# NEXT_PRIVATE_ALLOWED_SIGNUP_DOMAINS=example.com,acme.org
```

## The signing certificate (required, non-negotiable)

Documenso signs finalized PDFs with a PKCS#12 certificate. Without one, PDFs won't have a verifiable digital signature.

### Development / internal: self-signed

```sh
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes \
  -subj "/CN=Documenso Self-Signed"
openssl pkcs12 -export -out cert.p12 -inkey key.pem -in cert.pem \
  -password pass:<strong>
```

Place on host:

```sh
sudo mkdir -p /opt/documenso
sudo cp cert.p12 /opt/documenso/cert.p12
sudo chown 1001:1001 /opt/documenso/cert.p12        # UID 1001 = container user
sudo chmod 400 /opt/documenso/cert.p12
```

### Production: CA-issued or HSM-backed

For signatures PDF viewers trust without warnings, get a certificate from a **AATL (Adobe Approved Trust List)** CA (GlobalSign, Sectigo, DigiCert). Even better: store the private key in an HSM (Google Cloud HSM integration documented at <https://docs.documenso.com/self-hosting/configuration/signing-certificate/google-cloud-hsm>).

**Never generate or store the cert inside the container.** Container rebuild = cert gone = existing signatures can't be re-verified, new signatures inconsistent across replicas.

### Alternative: base64-encoded cert via env

If file mounting isn't available:

```sh
NEXT_PRIVATE_SIGNING_LOCAL_FILE_CONTENTS=<base64 of cert.p12>
```

## Data & config layout

Inside Postgres:

- `User`, `Team`, `TeamMember` — auth + orgs
- `Document`, `DocumentData`, `Recipient`, `Field`, `Signature` — the signing workflow
- `Template` — reusable document templates with pre-placed fields
- `AuditLog` — who viewed / signed / rejected / resent, with timestamps + IPs

Local filesystem (container-side):

- `/opt/documenso/cert.p12` — signing cert
- Document PDFs stored either in Postgres (via `DocumentData.data`) or S3 (if configured)

## Backup

```sh
# DB is the single source of truth
docker compose exec -T database pg_dump -U documenso documenso | gzip > documenso-db-$(date +%F).sql.gz

# S3 bucket (if used) — rely on S3 versioning + bucket replication

# Certificate + secrets
cp /opt/documenso/cert.p12 documenso-cert-$(date +%F).p12
grep -E '^NEXT_PRIVATE_ENCRYPTION_KEY|^NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY|^NEXTAUTH_SECRET|^NEXT_PRIVATE_SIGNING_PASSPHRASE' .env > documenso-secrets-$(date +%F).txt
```

**Signing cert + encryption keys + passphrase** must be preserved. Lose them → document signatures become unverifiable and any secrets stored in the DB (potentially including API tokens) become unreadable.

## Upgrade

1. Releases: <https://github.com/documenso/documenso/releases>. Frequent, semver-ish.
2. `docker compose pull && docker compose up -d`. Prisma migrations run on startup.
3. Read release notes — env var names have changed across minor versions during the Next.js → Remix migration.
4. Backup DB before every upgrade.
5. **Don't share a DB** across Documenso versions; schema evolves between releases.

## Gotchas

- **Without a signing certificate, nothing gets "signed"** in the digital-signature-verifiable sense. Documenso will run, but completed PDFs lack the PKCS#7 signature object — they're just "documents with drawn signatures". Set up `NEXT_PRIVATE_SIGNING_PASSPHRASE` + mount cert.
- **Self-signed cert = PDF viewers show "unknown signer" warning.** Adobe Reader / Foxit / macOS Preview will flag as untrusted. For serious use, get an AATL cert.
- **Encryption keys ≥32 chars required.** Shorter = startup fails with cryptic error.
- **Losing encryption keys** = losing ability to decrypt stored document secrets. Back them up separately, not in the same git repo as the compose file.
- **UID 1001** is the container user; cert must be readable by it. `chown 1001:1001 cert.p12 && chmod 400 cert.p12` on the host.
- **Next.js → Remix migration ongoing.** Upstream has been porting the web app from Next.js to Remix; some env vars changed during this. Pin a version + read release notes before upgrading.
- **SMTP is de-facto mandatory.** Password reset, signer invitation, "signed" receipts all go via email. Without, workflow is broken.
- **Signer identity verification is email-based by default.** Signers click a link in their email; that's the "auth". Add 2FA / SMS verification per-signer in document settings for stronger signer binding.
- **No built-in OCR, field detection, etc.** Field placement is manual in the editor. If you need "drop a PDF and it auto-finds signature locations", look at **DocuSeal** (similar project with AI field-detection beta).
- **Public signup** is open by default. Restrict with `NEXT_PRIVATE_ALLOWED_SIGNUP_DOMAINS` to limit to your org's email domains.
- **Audit trail** is stored in Postgres and exported with each finalized PDF as a separate attachment. Legally useful for proving who signed when.
- **S3 storage backend** strongly recommended for prod — storing large PDFs in Postgres `bytea` bloats the DB fast.
- **Webhook support** (document signed / completed events) for downstream automation. Events signed with a per-webhook secret.
- **API tokens** can be issued per-user for programmatic document creation + sending.
- **Template feature** lets you create a document once with field placeholders, then reuse with different recipients.
- **Multi-signer ordering** (sequential vs parallel) per document.
- **HSM integration** (Google Cloud HSM / AWS KMS) for production-grade signing — PDF remains verifiable even if Documenso is compromised, as the key never leaves the HSM.
- **AGPL-3.0 community + commercial Enterprise.** Enterprise adds: SSO (SAML / OIDC at the org level), advanced team features, white-label branding, compliance add-ons (HIPAA, etc.), priority support.
- **Cloud version** is the SaaS at documenso.com; revenue supports the open core.
- **Alternatives worth knowing:**
  - **DocuSeal** — similar OSS, simpler UI, AI field detection
  - **OpenSign** — OSS with stronger team features, React-based
  - **SignWell** — commercial SaaS
  - **Dropbox Sign (HelloSign)** — commercial SaaS
  - **PDF Agrippa / Pdf-Signer** (CLI) — if you just need to sign, not request signatures

## Links

- Repo: <https://github.com/documenso/documenso>
- Website: <https://documenso.com>
- Docs: <https://docs.documenso.com>
- Self-hosting overview: <https://docs.documenso.com/self-hosting>
- Docker Compose deployment: <https://docs.documenso.com/self-hosting/deployment/docker-compose>
- Signing certificate setup: <https://docs.documenso.com/self-hosting/configuration/signing-certificate>
- Google Cloud HSM: <https://docs.documenso.com/self-hosting/configuration/signing-certificate/google-cloud-hsm>
- Environment variables: <https://docs.documenso.com/self-hosting/configuration/environment-variables>
- Releases: <https://github.com/documenso/documenso/releases>
- Docker Hub: <https://hub.docker.com/r/documenso/documenso>
- Cloud: <https://documenso.com/pricing>

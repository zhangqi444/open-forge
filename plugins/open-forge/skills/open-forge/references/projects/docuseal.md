---
name: DocuSeal
description: Self-hosted document signing (DocuSign alternative). Drag-and-drop PDF field editor, send-for-signature workflows, audit log, signing via web or email link, mobile-friendly, REST API. Ruby on Rails + SQLite/Postgres/MySQL. AGPL-3.0 (OSS) / commercial Pro + Cloud.
---

# DocuSeal

DocuSeal is the pragmatic OSS DocuSign/HelloSign/Documenso competitor. Upload a PDF, drag signature/text/date/checkbox fields onto it, send via email or share a link, collect cryptographically-backed signed PDFs. Simpler + faster to deploy than Documenso (no required PKCS#12 cert on day one — signing cert is auto-generated).

- **Visual PDF field editor** — drag signature fields, initials, text, date, number, select, checkbox, image, file upload, stamp
- **Reusable templates** — define a form once, send it to 1000 people
- **Multi-signer flows** — ordered or parallel signer sequences
- **Auto-generated signing certificates** OR bring your own X.509 / PKCS#12 for AATL-trusted signatures
- **Audit trail** — who viewed, signed, IP, UA, timestamp; embedded into the final PDF
- **Email signing** OR **shareable link**
- **White-label** (Pro) — custom domain, branding, senders
- **REST API** — create submissions, templates, and documents programmatically
- **Mobile-first UI** — signing works great on phones

Simpler setup vs Documenso (`DocuSeal` auto-generates the signing key on first run; Documenso requires you to provide one explicitly).

- Upstream repo: <https://github.com/docusealco/docuseal>
- Website: <https://www.docuseal.com>
- Docs: <https://www.docuseal.com/docs>
- Docker Hub: <https://hub.docker.com/r/docuseal/docuseal>
- Cloud: <https://www.docuseal.com/pricing>

## Architecture in one minute

- **`docuseal/docuseal`** — single Rails monolith image; embedded Puma server
- **DB**: SQLite (default, bundled), PostgreSQL, or MySQL via `DATABASE_URL`
- **Volume `/data`** — uploads, SQLite DB file, generated signing keys, PDFs
- **Optional Caddy sidecar** for automatic TLS (upstream's full compose uses this)

Notable: uses **Rails + ActiveStorage** for file handling. Can use local disk or S3/GCS/Azure Blob for document storage.

## Compatible install methods

| Infra       | Runtime                                            | Notes                                                                     |
| ----------- | -------------------------------------------------- | ------------------------------------------------------------------------- |
| Single VM   | Docker (`docuseal/docuseal:<VERSION>`) + SQLite   | **Simplest** — single container, bundled DB                                |
| Single VM   | Docker Compose (app + Postgres + Caddy)            | **Upstream-documented with auto-TLS**                                      |
| Single VM   | Docker Compose with external Postgres               | For prod                                                                    |
| Kubernetes  | Community charts                                     | Not upstream-maintained                                                     |
| Managed     | DocuSeal Cloud                                       | <https://www.docuseal.com/pricing>                                          |

## Inputs to collect

| Input                  | Example                              | Phase     | Notes                                                                 |
| ---------------------- | ------------------------------------ | --------- | --------------------------------------------------------------------- |
| `HOST`                 | `docs.example.com`                   | DNS       | Domain name for auto-TLS via Caddy sidecar                              |
| `DATABASE_URL`         | `postgresql://user:pw@pg:5432/docuseal` | DB     | Optional — default is SQLite in `/data`                                   |
| Data volume            | `./docuseal:/data`                    | Storage   | SQLite DB + uploads + signing keys + PDFs                                 |
| `SECRET_KEY_BASE`      | `openssl rand -hex 64`                | Security  | Rails session + cookie signing (auto-generated if not set)              |
| S3/GCS/Azure (opt.)    | bucket + creds                         | Storage   | For ActiveStorage — offload PDF storage                                   |
| SMTP                   | host/port/user/pw/from                 | Email     | For signing invitations + receipts                                        |
| Signing cert (opt.)    | your own PKCS#12 for AATL trust        | Security  | Auto-generated if none supplied                                           |

## Install via Docker (simplest — SQLite)

```sh
docker run -d --name docuseal \
  --restart unless-stopped \
  -p 3000:3000 \
  -v $(pwd)/docuseal:/data \
  docuseal/docuseal:latest
```

Pin version (recommended for prod):

```sh
docker run -d --name docuseal \
  -p 3000:3000 \
  -v $(pwd)/docuseal:/data \
  docuseal/docuseal:1.x.x
```

Browse `http://<host>:3000`.

## Install via Docker Compose (with Caddy auto-TLS + Postgres)

Upstream's `docker-compose.yml`:

```yaml
services:
  app:
    image: docuseal/docuseal:latest
    depends_on:
      postgres: { condition: service_healthy }
    ports:
      - "3000:3000"
    volumes:
      - ./docuseal:/data
    environment:
      - FORCE_SSL=${HOST}
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/docuseal

  postgres:
    image: postgres:18
    volumes:
      - './pg_data:/var/lib/postgresql/18/docker'
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: docuseal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  caddy:
    image: caddy:latest
    command: caddy reverse-proxy --from $HOST --to app:3000
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./caddy:/data/caddy
    environment:
      - HOST=${HOST}
```

Start with:

```sh
sudo HOST=docs.example.com docker compose up -d
```

Make sure DNS points `docs.example.com` → host. Caddy auto-issues Let's Encrypt cert.

## First boot

1. Browse `https://docs.example.com`
2. Create your admin account (first-user-is-admin)
3. **Templates** → **Create** → upload a PDF, drag fields onto it
4. **Send** → enter signer emails + subject + message
5. Signers receive email with signing link → sign in browser → all parties get receipts

## Signing certificate

By default, DocuSeal **auto-generates** a signing certificate on first run and stores it in `/data/`. Good enough for internal use — signatures are cryptographically present but PDF viewers show "unknown signer" since the cert is self-signed.

For **AATL-trusted signatures** (Adobe Reader shows green checkmark), upload your own certificate via Admin → Company Settings → Signing Certificate.

## Data & config layout

Inside `/data/`:

- `docuseal.sqlite3` (SQLite mode) — DB
- `storage/` — uploaded PDFs + generated signed PDFs (via ActiveStorage)
- `certs/` — auto-generated signing certificate + key
- `uploads/` — temporary upload area

## Backup

```sh
# Entire data volume covers everything
docker run --rm -v "$(pwd)/docuseal:/src" -v "$(pwd):/backup" alpine \
  tar czf /backup/docuseal-$(date +%F).tgz -C /src .

# If using external Postgres:
docker compose exec -T postgres pg_dump -U postgres docuseal | gzip > docuseal-db-$(date +%F).sql.gz
```

**`certs/` directory is critical**: losing the signing cert = all previously-signed documents become unverifiable (signatures can't be checked against the same cert). Back up the cert + key off-host.

## Upgrade

1. Releases: <https://github.com/docusealco/docuseal/releases>. Frequent.
2. `docker compose pull && docker compose up -d`. Rails migrations run on startup.
3. **Back up `/data` before every version bump** — Rails migrations are one-way.
4. Changelog: <https://github.com/docusealco/docuseal/releases>.
5. SQLite → Postgres migration: use Rails' `db:migrate` path OR export/import via `rake docuseal:export` + `rake docuseal:import` (depending on version).

## Gotchas

- **Auto-generated signing cert = self-signed** — PDF viewers flag as untrusted. For "Adobe-green-checkmark" production use, upload your own AATL cert.
- **Losing `certs/` directory** = future verification of previously-signed PDFs becomes problematic. **Back up off-host**.
- **SQLite scales to small/medium teams.** For >50 users or >10k documents/year, switch to Postgres.
- **S3/GCS/Azure storage highly recommended for prod** — local disk storage of PDFs grows fast and makes DR harder.
- **`FORCE_SSL=<HOST>`** tells Rails to require HTTPS (sets `config.force_ssl = true`). Needed behind a TLS-terminating proxy.
- **Caddy sidecar is a nice touch** for auto-TLS but binds port 80/443 — conflicts with existing reverse proxies. Omit if you have your own.
- **Default Postgres creds in upstream compose are `postgres:postgres`** — change before exposing anywhere.
- **Email (SMTP) is strongly recommended** — signing invitations + receipts go via email. Without, you can only use shareable link mode.
- **Template-based workflows** are the power-user pattern. Build a template once, send to hundreds.
- **API** key per-account from Settings → API — programmatic submission creation, signer management.
- **Webhooks** for "document signed / declined / opened" events — integrate with your CRM / automation.
- **White-label (custom domain, branding, custom sender email)** is Pro-only.
- **Multi-tenant / team features** (Pro) — separate companies/brands in one install.
- **Accessibility**: WCAG AA compliant per upstream claims.
- **Mobile signing UX** is a strong suit — works great on phones without a native app.
- **Versioning**: template edits create new versions; existing submissions lock to their template version.
- **Not end-to-end encrypted** — the server sees the PDF contents. For zero-knowledge signing, consider a different model.
- **AGPL-3.0** — public SaaS = source-sharing obligation. Private/internal = fine.
- **DocuSeal vs Documenso trade-offs**: DocuSeal starts simpler (auto-generated cert, SQLite default); Documenso has a more explicit, production-minded setup (mandatory cert provision, UID 1001 file ownership). Both are excellent.
- **Alternatives worth knowing:**
  - **Documenso** — OSS, very active, more production-minded from day 1
  - **OpenSign** — OSS, React + Parse backend, strong team features
  - **SignWell / Dropbox Sign (HelloSign)** — commercial SaaS
  - **DocuSign / Adobe Sign** — enterprise SaaS
  - **SignServer** — Java, more low-level; AATL sign-as-a-service
  - **PDF editors** (not signing workflows): BentoPDF, Stirling-PDF

## Links

- Repo: <https://github.com/docusealco/docuseal>
- Website: <https://www.docuseal.com>
- Docs: <https://www.docuseal.com/docs>
- Self-hosting: <https://www.docuseal.com/docs/self-hosting/install>
- Environment variables: <https://www.docuseal.com/docs/self-hosting/env-vars>
- API docs: <https://www.docuseal.com/docs/api>
- Mobile app (iOS): <https://apps.apple.com/app/docuseal/id6503409455>
- Mobile app (Android): <https://play.google.com/store/apps/details?id=com.docuseal.app>
- Docker Hub: <https://hub.docker.com/r/docuseal/docuseal>
- Releases: <https://github.com/docusealco/docuseal/releases>
- Discord: <https://discord.gg/qygYCDGck9>
- Pricing: <https://www.docuseal.com/pricing>

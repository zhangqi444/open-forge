---
name: InvoicePlane
description: "Long-running self-hosted PHP invoicing application. Invoices, quotes, clients, payments, recurring invoices, PDF export, e-invoicing prep. Active; PHP 8.2+. License: check repo. Community-stewarded legacy — FusionInvoice fork long-maintained."
---

# InvoicePlane

InvoicePlane is **"Invoice Ninja / Akaunting / Crater / Siwapp — self-hosted + PHP + community-stewarded"** — a mature libre web application for managing invoices, quotes, clients, and payments. Lineage: forked from FusionInvoice (commercial-turned-abandoned) and has been community-stewarded since. Version 1.7.0 (2024+) adds PHP 8.2+ compatibility + significant security fixes (XSS, LFI, log poisoning). Active development + Crowdin-translated + community-driven.

Built + maintained by **InvoicePlane community** (post-FusionInvoice fork). License: check repo (README doesn't state explicitly). Active; wiki docs; community forums; issue tracker; contribution guide; translations via Crowdin.

Use cases: (a) **freelancer/consultant billing** — lightweight Invoice-Ninja-alternative (b) **small business** — invoicing + quotes + recurring (c) **PHP-ecosystem shops** — fits existing LAMP/LEMP stacks (d) **multi-language client base** — strong translation coverage (e) **escape Invoice Ninja's forced-cloud-tier** or QuickBooks subscription (f) **legacy-stable invoicing** — stable tool you can deploy + forget (g) **e-invoicing prep** — 1.7.0 added e-invoicing field support for EU mandatory e-invoicing.

Features (per README + CHANGELOG):

- **Invoice + quote management**
- **Client + payment tracking**
- **Recurring invoices**
- **PDF export**
- **E-invoicing field support** (1.7.0+)
- **QR codes for payments**
- **Email templates + SMTP**
- **Multi-language** (Crowdin)
- **Sumex (Swiss medical billing) support**
- **PHP 8.1/8.2/8.3+ support** (1.7.0+)

- Upstream repo: <https://github.com/InvoicePlane/InvoicePlane>
- Website: <https://www.invoiceplane.com>
- Wiki: <https://wiki.invoiceplane.com>
- Forums: <https://community.invoiceplane.com>
- Translations: <https://translations.invoiceplane.com>

## Architecture in one minute

- **PHP 8.1+** (CodeIgniter framework)
- **MySQL / MariaDB** — DB
- **Resource**: low — 128-256MB RAM (PHP-FPM)
- **Port**: 80/443 via nginx/Apache

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **LAMP/LEMP**      | **Upload files to webroot + run /index.php/setup**              | **Primary (PHP-typical)**                                                          |
| Docker             | 3rd-party images (linuxserver.io, jaredfraser)                              | Community-maintained                                                                                   |
| Shared hosting     | cPanel-style (matches PHP ecosystem)                                                                     | Easy                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `invoices.example.com`                                      | URL          | TLS required                                                                                    |
| DB                   | MySQL / MariaDB                                             | DB           |                                                                                    |
| Admin creds          | First-boot wizard                                                                                | Bootstrap    | Strong                                                                                    |
| SMTP                 | For invoice emails                                                                           | Email        | **Required for core workflow**                                                                                    |
| Business details     | Company name, address, tax ID, logo                                                                                 | Config       | On invoices                                                                                    |
| Payment methods      | Bank transfer, Stripe/PayPal integration                                                                                                      | Business     | Optional                                                                                                            |

## Install

1. Download latest release: <https://github.com/InvoicePlane/InvoicePlane/releases>
2. Upload to webroot
3. Create MySQL DB + user
4. Browse `/index.php/setup`
5. Wizard configures .env + creates tables
6. Create admin user
7. Upload company logo (PNG/JPG — SVG is blocked since 1.7.0 for security)
8. Configure SMTP + send test email
9. Create first client + issue first invoice
10. Put behind TLS

## Data & config layout

- MySQL DB — all invoices, clients, payments
- `ipconfig.php` / `.env` — config
- `uploads/` — invoice attachments, client files, logos

## Backup

```sh
mysqldump -u invoiceplane -p invoiceplane > invoiceplane-$(date +%F).sql
sudo tar czf invoiceplane-uploads-$(date +%F).tgz uploads/
```

## Upgrade

1. Releases: <https://github.com/InvoicePlane/InvoicePlane/releases>. Active; 1.7.0 major security release (PHP 8.2+, XSS/LFI fixes).
2. **ALWAYS backup before upgrade** (1.7.0 shows need — security fixes, schema changes).
3. Replace files; run `/index.php/setup` for migrations.
4. **Check PHP version** — 1.7.0+ requires PHP 8.1+.
5. **SVG LOGO NOTICE** for 1.7.0: convert any SVG logos to PNG/JPG (SVG uploads now blocked).

## Gotchas

- **FUSIONINVOICE LINEAGE = COMMUNITY-STEWARD-OF-LEGACY-TOOL (5th tool)**:
  - FusionInvoice was commercial; forked to open-source InvoicePlane after FusionInvoice's license change
  - InvoicePlane community has stewarded it for ~decade
  - **5th tool in community-steward-of-legacy-tool class** (Baikal 98 4th; Keystone 89 1st; FreshRSS 89 2nd; others 3rd/4th). InvoicePlane joins the class.
  - **Recipe convention: "post-commercial-fork community-steward" sub-tier** — FusionInvoice is specifically a commercial-turned-fork (Baikal + others are more organic).
- **FINANCIAL DATA = HIGH-SENSITIVITY + REGULATORY**:
  - Invoices contain: client names + addresses + VAT IDs + bank details + payment records
  - Under GDPR: client PII protected — access logging, deletion requests, data-portability
  - Tax authority record-keeping obligations (varies by jurisdiction; typically 7-10 years)
  - **58th tool in hub-of-credentials family — "financial-records sub-tier"** (formally 6th regulatory-crown-jewel sub-family of hub-of-credentials overall; financial-records is distinct from research, healthcare, LIFELOG, physical-security)
  - Actually, **financial-records regulatory-crown-jewel sub-family** was already named (prior precedent); InvoicePlane is 2nd tool in that sub-family. Need family-doc to enumerate all tools in each sub-family.
- **IMMUTABILITY-OF-SECRETS + HISTORICAL RECORDS**:
  - Invoices are LEGAL RECORDS; historic invoice numbers + amounts are immutable (tax + legal-liability)
  - Don't delete closed invoices; archive instead
  - **Recipe convention: "legal-record-immutability" callout** — applies to invoicing + accounting + audit-log tools
  - **NEW recipe convention: "legal-record-immutability"** (1st tool: InvoicePlane)
- **PHP SECURITY LANDSCAPE**:
  - Long PHP history = many accumulated CVEs across versions; 1.7.0 specifically addresses XSS + LFI + log-poisoning
  - **CodeIgniter (3.x)** base; EOL potentially; check if upstream migrates to CI4 or newer framework
  - PHP-FPM + up-to-date version + proper SELinux/AppArmor profile = defense-in-depth
  - **Recipe convention: "PHP-legacy-framework security-posture-dependency"** — applies to tools built on older CodeIgniter/CakePHP/Symfony
- **HUB-OF-CREDENTIALS**:
  - Client PII + contact details
  - Financial records (invoices, payments, tax)
  - Bank account info (IBAN, account numbers)
  - SMTP creds
  - Optional Stripe/PayPal API keys
  - Admin account = all financial data
  - **58th tool — Tier 2 with financial-records regulatory-sub-family.**
- **E-INVOICING MANDATE (EU)**:
  - EU 2024: e-invoicing becoming mandatory (France, Italy, Poland, Spain rolling out)
  - ZUGFeRD/Factur-X/PEPPOL formats
  - InvoicePlane's 1.7.0 e-invoicing fields = preparing but not full-compliance
  - **Recipe convention: "EU e-invoicing regulatory-deadline callout"** — growing concern 2024-2027
- **LOG POISONING**: 1.7.0 fixed. Older versions vulnerable. **Upgrade immediately if on <1.7.0 and exposing publicly.**
- **SVG UPLOAD BLOCKED IN 1.7.0**: existing SVG logos won't render; convert to PNG/JPG before upgrade.
- **DEFAULT-CREDS-RISK**: verify setup wizard forces strong admin password; OSS invoicing tools often ship weak defaults. Flag if applicable.
- **TRANSPARENT-MAINTENANCE**: active + wiki + community forums + translations-platform + detailed-changelog + security-fix-disclosure in changelog. **50th tool in transparent-maintenance family — 50-tool MILESTONE!**
- **INSTITUTIONAL-STEWARDSHIP**: InvoicePlane community + org. **43rd tool — post-commercial-fork community-steward sub-tier.**
- **LICENSE CHECK**: README doesn't state. Repo typically labeled MIT or AGPL. Verify LICENSE file (LICENSE-file-verification-required convention).
- **INVOICING-CATEGORY**:
  - **InvoicePlane** — PHP; stable; community-fork
  - **Invoice Ninja** — PHP; feature-rich; has forced-cloud-tier push
  - **Akaunting** — PHP (Laravel); full accounting + invoicing
  - **Crater** — Laravel; modern; JS-frontend
  - **Siwapp** — PHP (Symfony)
  - **Paperwork** — older invoicing+CRM
  - **Manager.io** — commercial-but-free-for-desktop; cross-platform
  - **Choose InvoicePlane if:** you want stable + PHP + community + low-resource + EU-compliant-enough.
  - **Choose Akaunting if:** you want full accounting integration.
  - **Choose Crater if:** you want modern JS-frontend + Laravel.
  - **Choose Invoice Ninja if:** you want feature-richest + willing-to-navigate-commercial-tier-pressure.
- **PROJECT HEALTH**: active + PHP 8.2+ support added + security-focused 1.7.0 release + community + forums + wiki. Strong signals for a mature/stable tool.

## Links

- Repo: <https://github.com/InvoicePlane/InvoicePlane>
- Website: <https://www.invoiceplane.com>
- Wiki: <https://wiki.invoiceplane.com>
- Community: <https://community.invoiceplane.com>
- Translations: <https://translations.invoiceplane.com>
- FusionInvoice origin: historical; InvoicePlane is the live fork
- Invoice Ninja (alt): <https://invoiceninja.com>
- Akaunting (alt): <https://akaunting.com>
- Crater (alt): <https://craterapp.com>
- Siwapp (alt): <https://github.com/siwapp/siwapp>
- EU e-invoicing info: <https://digital-strategy.ec.europa.eu/en/policies/einvoicing>

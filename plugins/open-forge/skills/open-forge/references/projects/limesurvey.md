---
name: LimeSurvey
description: "World's leading open-source online survey platform — multilingual, GDPR-compliant, advanced question logic, 900+ templates, plugins + integrations (SAML/LDAP). PHP + MySQL/Postgres/MariaDB/MSSQL. GPL-2.0-or-later. LimeSurvey GmbH commercial-cloud + support offerings."
---

# LimeSurvey

LimeSurvey is **"the open-source SurveyMonkey / Qualtrics alternative"** — arguably the #1 open-source survey platform since 2006, used by businesses, academic institutions, teachers, governments, financial institutes, and researchers in 80+ countries. Advanced question types (30+), conditional logic / question branching, customizable templates, multilingual surveys (80+ languages), GDPR-compliant data collection, anonymization, 2FA, RemoteControl API (XML-RPC / JSON-RPC), plugin ecosystem, SAML/LDAP integration. Self-host for data sovereignty; LimeSurvey GmbH offers commercial cloud + commercial support.

Built + maintained by **LimeSurvey GmbH** (Germany) + active community since 2006. **License: GPL-2.0-or-later**. Mature + widely-trusted in the academic/research community especially.

Use cases: (a) **academic research surveys** with complex question logic + multilingual (b) **employee engagement surveys** — HR tooling with anonymization (c) **market research + customer feedback** (d) **government / public consultation** — transparent data collection (e) **student / course evaluations** — LMS-integratable (f) **mass questionnaires** — event feedback, volunteer coordination.

Features (from upstream README):

- **Unlimited surveys + questions**
- **30+ question types** — free-text, multiple-choice, matrix, ranking, etc.
- **900+ survey templates**
- **Easy LimeSurvey editor**
- **On-brand surveys** — fonts, colors, logo, CSS, JavaScript injection
- **Multilingual surveys** — 80+ languages
- **Skip logic + question branching**
- **Easy sharing** — public link, QR code, social
- **Closed access mode** — personal link, invite-only
- **Responses + statistics** + advanced analytics
- **RemoteControl API** — XML-RPC + JSON-RPC
- **Google Analytics integration**
- **Data security + anonymization** — built-in
- **Two-factor authentication**
- **GDPR compliance features**
- **WCAG 2.0 accessibility compliance**
- **Plugins** — question themes, survey themes, audit log, ExportR, ExportSTATAxml, AuthCAS, etc.
- **Integrations** — SAML, LDAP, SURFconext, REST, Remote Control

- Upstream repo: <https://github.com/LimeSurvey/LimeSurvey>
- Homepage: <https://www.limesurvey.org>
- Manual: <https://www.limesurvey.org/manual>
- Downloads: <https://community.limesurvey.org/downloads/>
- Bug tracker: <https://bugs.limesurvey.org>
- Forums: <https://forums.limesurvey.org>
- Demo (admin): <https://demo.limesurvey.org/admin>
- Discord: <https://discord.gg/DEjguXn>

## Architecture in one minute

- **PHP 7.4+** (8.x recommended) with mbstring + PDO extensions
- **DB**: MySQL 8.0+, MariaDB 10.3.38+, PostgreSQL 12+, or MSSQL 2016+
- **Apache 2.4+ / nginx 1.1+** — any PHP-ready web server
- **Resource**: moderate — 512MB-1GB RAM; scales with response volume + concurrent respondents
- **Port 80/443** via web server

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Stable release download** | **`community.limesurvey.org/downloads/`** → unzip → web server | **Upstream-primary**                                                               |
| Manual git deploy  | Git clone + installer wizard                                              | For dev                                                                                              |
| Docker             | Community images: `martialblog/limesurvey`, `adamzammit/limesurvey`                     | Not upstream-official                                                                                     |
| Shared hosting     | Any LAMP shared host                                                                                      | Historic strength                                                                                                  |
| LimeSurvey Cloud   | Commercial SaaS                                                                                                        | For non-self-host path                                                                                                                  |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `surveys.example.com`                                       | URL          | TLS MANDATORY                                                                                    |
| DB                   | MySQL/MariaDB/PostgreSQL/MSSQL                                     | DB           | UTF-8mb4 for MySQL/MariaDB                                                                                    |
| Admin user + password | At installer wizard                                                       | Bootstrap    | **Strong password + enable 2FA**                                                                                    |
| Base URL             | Same as Domain                                                                                      | Config       | For share-link generation                                                                                                            |
| Encryption key       | For field-level encryption of sensitive responses                                                                  | **CRITICAL** | **IMMUTABLE** — enable BEFORE collecting data                                                                                                                                            |
| SMTP                 | For invitation + notification emails                                                                                                                | Outbound     | Essential for invite-only surveys                                                                                                                                                                  |
| SAML / LDAP (opt)    | For institution SSO                                                                                                                                            | Auth         | Mature integration                                                                                                                                                                                           |

## Install

1. Download stable release from <https://community.limesurvey.org/downloads/>
2. Unzip to web root: `/var/www/limesurvey/`
3. Set file permissions per install docs
4. Create DB + user
5. Browse to `https://surveys.example.com/` → installer wizard
6. Configure DB + admin credentials + base URL
7. Installer creates schema + first admin
8. Delete install directory files per post-install step

## First boot

1. Log in as admin
2. **Enable data encryption** (system settings) → field-level encryption key
3. Configure SMTP → send test email
4. Enable 2FA for admin accounts
5. Create survey groups + user roles (e.g., researchers, analysts, anonymous-respondents)
6. Install essential plugins (audit log for compliance)
7. Configure privacy defaults (anonymize by default? track IPs?)
8. Create first survey → test the full response → analysis flow
9. Put behind TLS reverse proxy
10. Configure backups + rotation

## Data & config layout

- `/var/www/limesurvey/application/config/config.php` — DB creds + encryption config
- `/var/www/limesurvey/tmp/` — file uploads; sessions
- `/var/www/limesurvey/upload/` — participant-uploaded files
- `/var/www/limesurvey/plugins/` — installed plugins
- **DB** — ALL surveys, questions, responses, users, audit trail

## Backup

```sh
# DB
mysqldump -ulimesurvey -p${DB_PASSWORD} limesurvey > limesurvey-$(date +%F).sql
# Uploads + config
sudo tar czf limesurvey-files-$(date +%F).tgz /var/www/limesurvey/upload /var/www/limesurvey/application/config
# Encryption key (in config.php + DB): password-manager backup
```

**RESEARCH DATA CRITICALITY** — same principle as Bigcapital (batch 90): data loss is irrecoverable + has compliance/legal implications. Test restore discipline.

## Upgrade

1. Releases: <https://community.limesurvey.org/downloads/>. Regular.
2. Upgrade via admin UI's built-in updater OR manual file replacement + DB migration.
3. **Back up DB + files + config BEFORE upgrade** — research data is irreplaceable.
4. Major versions = breaking schema changes; test in staging.
5. Plugin compatibility — update plugins AFTER core upgrade.

## Gotchas

- **RESEARCH / SURVEY DATA = PII-RICH CROWN JEWEL**: surveys often collect:
  - **Respondent identity** (even if anonymized, metadata can re-identify)
  - **Sensitive categories** — health, financial, political opinions, sexual orientation, religion (GDPR "special category" data — stricter protection requirements)
  - **Open-text responses** — can contain anything (PII, confidential info, legal-liability-triggering content)
  - **23rd tool in hub-of-credentials family + Tier 2 (crown-jewel proper)** — same sensitivity class as Bigcapital / Chartbrew / Hi.Events.
- **GDPR DEFAULTS MUST BE REVIEWED**: LimeSurvey has GDPR features but DEFAULTS may not match your jurisdiction's requirements. Explicitly configure:
  - IP address logging (anonymize / don't store by default if researching anonymously)
  - User-agent logging
  - Referrer logging
  - Session data retention
  - **Consent / privacy notice** within survey (LimeSurvey has a "Terms & Conditions" feature; use it)
  - **Data-retention schedule** — delete old responses per retention policy
  - **Right to erasure implementation** — define process for respondent-delete-request
- **IRB / ETHICS-REVIEW for academic use**: if you're running academic research, your institution's IRB/ethics board must approve your LimeSurvey setup + data handling. Don't collect data before IRB approval.
- **ENCRYPTION KEY IMMUTABILITY**: LimeSurvey supports field-level encryption for sensitive responses. **19th tool in immutability-of-secrets family** (encryption key). Enable BEFORE collecting sensitive data; changing keys mid-study is painful. Back up the key separately from the DB.
- **PARTICIPANT-UPLOADED FILES**: question types allow file upload → respondents can upload PDFs, images, etc. **Malware-scan uploaded files** (ClamAV or external AV) — hostile respondents can upload malicious files. Same class as osTicket (batch 89) attachment caution.
- **EMAIL INVITATIONS**: invite-only surveys email participants. **SPF + DKIM + DMARC mandatory** on your sending domain or invites go to spam. Same discipline as every-transactional-email tool (osTicket, FreeScout, Hi.Events).
- **LIMESURVEY GmbH COMMERCIAL TIER**:
  - **LimeSurvey Cloud** — hosted SaaS (same product, hosted; **"hosted-SaaS-of-OSS-product"** tier per taxonomy batch 89)
  - **Commercial support contracts** — paid support for self-hosters (**"services-around-OSS"** tier)
  - **Enterprise features** in commercial offerings may differ from free GPL version — check current product matrix
- **GPL-2.0-OR-LATER LICENSE**: GPL compliance for embedding or redistribution. If you build derivative surveys-as-a-service + redistribute modified LimeSurvey, GPL-2+ copyleft kicks in.
- **PLUGIN ECOSYSTEM** — plugin-as-RCE applies (Shaarli / Piwigo / pyLoad batches 87/88): plugins execute PHP code; install only from official LimeSurvey plugin repo or trusted sources.
- **RESEARCH-GRADE EXPORT FORMATS** (ExportSTATA, ExportR plugins): serious academic research uses R / STATA / SPSS for analysis. LimeSurvey's export plugins bridge to these tools — unique strength vs commercial alternatives. Validate export compatibility with your analysis pipeline BEFORE fielding a big survey.
- **XML-RPC / JSON-RPC RemoteControl API**: programmatic survey management. **API tokens = full-admin-equivalent access**. Scope + rotate + monitor API use. Same discipline as any-admin-API.
- **BEWARE OF CUSTOM-JS/CSS INJECTION**: LimeSurvey allows custom JS + CSS per survey for branding. **Malicious admin or compromised admin account = XSS in respondent browsers.** Scope admin roles tightly; don't grant "custom JS" permission freely.
- **ACCESSIBILITY (WCAG 2.0)**: for government / EU / public-sector surveys, accessibility compliance is often legally required. LimeSurvey claims WCAG 2.0 support; **verify with your specific survey templates** + test with screen-reader tools before fielding.
- **SAML / LDAP institutional auth**: mature integration for universities / large orgs. Use institutional SSO to avoid account sprawl.
- **BACKUP RESTORE DISCIPLINE**: research data = irreplaceable. Test restore drills. Same warning as Bigcapital 90, Chartbrew 86, 2FAuth 86.
- **RESPONSE-DATA PSEUDONYMIZATION vs RETENTION**: like accounting data (Bigcapital), research data retention may need to be preserved LONG after GDPR's right-to-erasure might kick in (for research reproducibility). Resolve via pseudonymization (replace direct identifiers with tokens; retain responses).
- **Performance at scale**: for a major survey with 10,000+ respondents landing in minutes, pre-scale DB + PHP-FPM + tune LimeSurvey's session store (Redis-backed recommended). For 100,000+ concurrent respondents (viral public survey), you need CDN + autoscaling web tier + Postgres/MySQL optimized properly.
- **Institutional-stewardship by-company**: LimeSurvey GmbH is a German company; commercially-stable. **12th tool in institutional-stewardship family** — company-backed + long-running variant (like TryGhost, Deciso).
- **Alternatives worth knowing:**
  - **SurveyJS** — JavaScript library + self-host backend; modern dev-friendly
  - **Formbricks** — open-source survey platform + in-product micro-surveys
  - **Typeform** — commercial SaaS (premium polish)
  - **Google Forms** — free commercial SaaS; simpler
  - **Microsoft Forms** — Office 365 bundled
  - **Alchemer (SurveyGizmo)** / **Qualtrics** — commercial SaaS enterprise research
  - **Jotform** — commercial SaaS form-building
  - **Tellform** — OSS form builder (simpler than LimeSurvey)
  - **Choose LimeSurvey if:** you want mature + GPL + multilingual + research-grade features + self-host or GmbH-hosted.
  - **Choose Formbricks if:** you want modern developer-friendly + product-embedded surveys.
  - **Choose Google Forms if:** you want simple free + don't need research features.
  - **Choose Qualtrics if:** you want enterprise polish + deep research features + accept commercial.

## Links

- Repo: <https://github.com/LimeSurvey/LimeSurvey>
- Homepage: <https://www.limesurvey.org>
- Manual: <https://www.limesurvey.org/manual>
- Downloads: <https://community.limesurvey.org/downloads/>
- Bug tracker: <https://bugs.limesurvey.org>
- Forums: <https://forums.limesurvey.org>
- Demo: <https://demo.limesurvey.org/admin>
- Discord: <https://discord.gg/DEjguXn>
- Formbricks (alt): <https://formbricks.com>
- SurveyJS (library alt): <https://surveyjs.io>
- Typeform (commercial alt): <https://www.typeform.com>
- Qualtrics (enterprise alt): <https://www.qualtrics.com>

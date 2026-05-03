---
name: OpenEMR
description: "Free + open-source electronic health records (EHR) + medical practice management — integrated EHR, scheduling, electronic billing, patient portal, ONC-certified, 30+ languages, FHIR API. Deployed in 100+ countries. PHP + MySQL. GPL-3.0."
---

# OpenEMR

OpenEMR is **the dominant free + open-source electronic health records platform** — a full EHR + practice management system covering clinical notes, prescriptions (e-prescribing via RXCUI), scheduling, billing (including X12 clearinghouse integration), patient portal, laboratory integration, immunization tracking, and more. **ONC-certified** for Meaningful Use Stage III — i.e., qualifies under US federal health-IT programs. **Inferno-tested FHIR API** for modern interoperability. Deployed in 100+ countries by small practices, NGOs, and some large health networks (notably in developing nations where commercial EHRs are unaffordable).

Sponsored/supported by volunteer + professional community via OpenEMR project + [open-emr.org](https://open-emr.org). 20+ years of continuous development.

> **⚠️ This is regulated software handling PHI (Protected Health Information).** If you deploy OpenEMR for clinical use in the US, EU, UK, Canada, or any regulated jurisdiction, you are responsible for HIPAA/GDPR/PIPEDA compliance. Self-hosting does NOT absolve compliance obligations; it transfers them to YOU as covered entity / data controller.

Features:

- **Full EHR** — encounter notes, problem list, medications, allergies, immunizations, vitals
- **Practice management** — scheduling, billing, claims
- **Patient portal** — appointments, messaging, results
- **E-prescribing** via RxNorm/RXCUI
- **Electronic billing** — X12 837/835 claims + ERA
- **FHIR API** (R4) — modern interop; Inferno-certified
- **Lab integrations** — HL7 v2 + FHIR
- **Internationalization** — 30+ languages, multi-currency, international code sets
- **ONC Health-IT Certification** — Stage III Meaningful Use
- **Portal + messaging**
- **Reports** — clinical, financial, operational
- **Modular** — enable/disable features per practice

- Upstream repo: <https://github.com/openemr/openemr>
- Homepage: <https://open-emr.org>
- Wiki: <https://open-emr.org/wiki/>
- Community forum: <https://community.open-emr.org>
- Docker docs: <https://github.com/openemr/openemr/blob/master/DOCKER_README.md>
- FHIR docs: <https://github.com/openemr/openemr/blob/master/FHIR_README.md>
- API docs: <https://github.com/openemr/openemr/blob/master/API_README.md>
- Security: <https://github.com/openemr/openemr/blob/master/.github/SECURITY.md>
- Professional support (paid): listed on open-emr.org

## Architecture in one minute

- **PHP 8.x** (LAMP/LEMP) — Apache or Nginx
- **MySQL 8+ / MariaDB 10.5+** — primary DB
- **Redis (optional)** — sessions + caching
- **Node 24+** for building assets
- **Composer + npm** for dependencies
- **Official Docker image** + Docker Compose bundle
- **Resource**: moderate — PHP-FPM + DB; 1-2 GB RAM for small practice; scales up

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker Compose bundle**                                          | **Upstream-recommended for modern deploys**                                        |
| VPS / bare-metal   | LAMP/LEMP + source                                                         | Traditional path; more setup                                                                           |
| Managed hosting    | **Professional support vendors** via open-emr.org                                                  | For practices that need SLAs + HIPAA-ready hosts                                                                       |
| Kubernetes         | Possible; community Helm charts                                                                               | Scale; overkill for small practices                                                                                                    |
| Windows            | Stack installers (XAMPP-based) — discouraged for production                                                                                   | Development only                                                                                                                                   |

## Inputs to collect

| Input                    | Example                                    | Phase        | Notes                                                                        |
| ------------------------ | ------------------------------------------ | ------------ | ---------------------------------------------------------------------------- |
| Domain                   | `ehr.clinic.example.com`                       | URL          | **TLS is MANDATORY** for any real deployment                                         |
| DB (MySQL/MariaDB)       | separate service or managed                    | DB           | Plan backup + HA if critical                                                                 |
| Admin user               | create during setup wizard                               | Bootstrap    | **Strong password + MFA for admin** — regulatory requirement                                                                 |
| Clinic branding          | logo / name / addresses                                            | Config       | Via admin UI                                                                                                 |
| SMTP                     | for patient notifications                                                      | Email        | Deliverable SMTP (SendGrid/Postmark/etc.)                                                                                                     |
| Backup / DR plan         | documented + tested                                                                       | Compliance   | Not optional for clinical use                                                                                                                                    |

## Install via Docker Compose

```yaml
# Simplified — see DOCKER_README.md for current official compose bundle
services:
  openemr:
    image: openemr/openemr:8.1.1                         # pin exact version
    restart: unless-stopped
    ports:
      - "443:443"
      - "80:80"
    environment:
      MYSQL_HOST: mariadb
      MYSQL_USER: openemr
      MYSQL_PASS: CHANGE_STRONG
      OE_USER: admin
      OE_PASS: CHANGE_STRONG_ADMIN
    volumes:
      - ./sites:/var/www/localhost/htdocs/openemr/sites
      - ./logs:/var/log
    depends_on:
      - mariadb

  mariadb:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: CHANGE_ROOT_PASS
      MYSQL_DATABASE: openemr
      MYSQL_USER: openemr
      MYSQL_PASSWORD: CHANGE_STRONG
    volumes:
      - ./db:/var/lib/mysql
```

Browse `https://<host>/` → setup wizard → log in as admin.

## First boot

1. Run setup wizard (if image doesn't pre-seed): DB config, admin creds, site name
2. **Change default admin password immediately** (like every batch-68+ tool)
3. Configure TLS via reverse proxy or bind-mounted cert
4. Configure facilities (addresses, tax IDs, NPIs)
5. Configure users + roles (clinician, biller, scheduler, admin)
6. Enable MFA for all users with PHI access
7. Configure code sets (ICD-10, CPT, RxCUI) — defaults included
8. Set up billing — X12 clearinghouse credentials if doing electronic claims
9. Enable audit logs (REQUIRED for HIPAA)
10. **Back up DB + `sites/` volumes.** Test restore.

## Data & config layout

- `/var/www/localhost/htdocs/openemr/sites/` — per-site config + uploaded documents (patient scans, ID cards)
- `openemr` MySQL database — ALL clinical + scheduling + billing data
- `/var/log/` — logs (audit logs MUST be retained per HIPAA)

## Backup

```sh
mysqldump -u root -p --single-transaction --routines --triggers openemr > openemr-$(date +%F).sql
sudo tar czf openemr-sites-$(date +%F).tgz sites/ logs/
```

**HIPAA** / GDPR requires:
- Encrypted backups
- Tested restore procedure
- Retention: 6 years (HIPAA) / varies (jurisdiction)
- Audit log retention: 6 years minimum (HIPAA)
- Off-site + geographically-distant copy

## Upgrade

1. Releases: <https://github.com/openemr/openemr/releases>. Active (20+ year project).
2. Read upgrade guide for target version — breaking DB schema changes possible.
3. **Full DB dump + file backup before every upgrade.** Test restore.
4. Minor versions: usually in-place upgrade.
5. Major versions: test on staging copy first. ALWAYS.

## Gotchas

- **This is regulated software for regulated data.** Running OpenEMR for real clinical use means you + your practice are responsible for HIPAA (US), GDPR (EU), PIPEDA (Canada), etc. The software enables compliance but doesn't enforce it. Review:
  - Access control + MFA
  - Audit log retention + integrity
  - Backup encryption + retention
  - Incident response + breach notification process
  - BAAs (Business Associate Agreements) with hosting + email providers
  - Data sovereignty (where is PHI stored / transiting?)
- **Strong passwords + MFA on every account with PHI access.** Default admin creds must be changed on day zero.
- **TLS mandatory.** Never serve OpenEMR over HTTP. Use Let's Encrypt or internal CA; ideal: TLS 1.2+ with modern cipher suites.
- **Audit logs are a regulatory requirement**, not a nice-to-have. Enable + retain. Don't store audit logs on the same DB server as the app (integrity concern) if you can avoid.
- **Backup encryption**: PHI in backup files = PHI. Encrypt at rest (GPG, age, Duplicacy — batch 70 — with strong keys). Test restore.
- **Vendor support**: for real clinics, consider **paid professional support** from OpenEMR ecosystem vendors (listed on open-emr.org). ONC-certified status benefits from certified deployment; many practices DIY + hire vendor for periodic audit.
- **Upgrade discipline**: 20-year-old codebase with heavy schema migrations. NEVER upgrade production without testing on copy. Read release notes.
- **FHIR API**: powerful; enables modern interop (Apple Health, patient apps, other EHRs). Gate properly — API access is PHI access.
- **Language support**: 30+ languages — great for international practices. Test carefully — some translations lag behind English by features.
- **Small-practice focus**: OpenEMR works for solo practices to mid-size groups. Very-large hospital deployments are rare (commercial systems like Epic/Cerner dominate there).
- **Developing-world deployments**: significant user base in Africa, Asia, Latin America where commercial EHRs are unaffordable. Affects feature prioritization.
- **Windows XAMPP-stack installers**: discouraged for production; OK for dev/training.
- **Patient portal = public-facing**: harden extra carefully; rate-limit; disable if not using.
- **Community health**: Open Collective funded; active + sustained. Not bus-factor-1. Well-established project governance.
- **License**: **GPL-3.0** — modifications to public-facing deployments must be published. Check obligations.
- **Alternatives worth knowing:**
  - **OpenMRS** — similar open EHR; more developing-world focus
  - **GNU Health** — FOSS health + hospital mgmt
  - **Bahmni** — OpenMRS-based hospital package
  - **LibreHealth EHR** — OpenEMR fork; less active
  - **Mirth Connect (NextGen Connect)** — integration engine, not EHR
  - **Commercial**: Epic, Cerner (Oracle Health), athenahealth, eClinicalWorks, DrChrono
  - **Choose OpenEMR if:** established OSS EHR + multi-specialty + ONC-certified + global deployment.
  - **Choose OpenMRS if:** developing-world focus + custom module-heavy.
  - **Choose GNU Health if:** hospital-scale + bioinformatics angle + GNU philosophy.

## Links

- Repo: <https://github.com/openemr/openemr>
- Homepage: <https://open-emr.org>
- Wiki: <https://open-emr.org/wiki/>
- Community forum: <https://community.open-emr.org>
- Docker README: <https://github.com/openemr/openemr/blob/master/DOCKER_README.md>
- FHIR README: <https://github.com/openemr/openemr/blob/master/FHIR_README.md>
- API README: <https://github.com/openemr/openemr/blob/master/API_README.md>
- Security policy: <https://github.com/openemr/openemr/blob/master/.github/SECURITY.md>
- Open Collective: <https://opencollective.com/openemr>
- ONC Certification: <https://www.open-emr.org/wiki/index.php/OpenEMR_Certification_Stage_III_Meaningful_Use>
- HIPAA overview (HHS): <https://www.hhs.gov/hipaa/>
- GDPR overview: <https://gdpr.eu>
- OpenMRS (alt): <https://openmrs.org>
- GNU Health: <https://www.gnuhealth.org>

---
name: Fasten Health
description: "Self-hosted Personal Health Record (PHR). Community OSS; Fasten Connect is separate commercial product. NOT an EHR integration — manual entry + FHIR-bundle import only. Active; maintained by community; Discord; funded commercial parallel."
---

# Fasten Health (Fasten OnPrem)

Fasten OnPrem is **"Apple Health Records / Epic MyChart — but self-hosted + OSS + manual-entry/FHIR-import-only"** — an open-source self-hosted **Personal Health Record (PHR)** app. Create, manage, view patient medical data in your control. **IMPORTANT**: the OSS OnPrem version **does NOT integrate with EHRs/providers directly** — that's the separate commercial "Fasten Connect" product ($$$, for businesses/clinical-trials/research). OnPrem users must manually enter data OR import FHIR bundles obtained elsewhere.

Built + maintained by **fastenhealth org** (community + commercial-parallel company). License: check LICENSE file. Active; GitHub Actions CI; Discord; newsletter; docs at docs.fastenhealth.com; React frontend + Go backend. Fasten Connect (commercial) integrates with 50,000+ healthcare institutions.

Use cases: (a) **personal medical records consolidation** — across multiple providers (b) **family medical history tracker** — your + your kids' + aging-parents' records (c) **travel-ready health records** — PDF export of allergies, meds, conditions (d) **chronic-condition management** — long-term tracking in one place (e) **FHIR-bundle import** if you've exported from a provider (f) **privacy-preserving alternative** to Apple Health Records sync (g) **personal-research-data-hub** — link to wearables + labs (manual) (h) **replacement for paper folder** of medical records.

Features (per README + docs):

- **Personal Health Record** (PHR)
- **Manual data entry** — core workflow
- **FHIR bundle import** — if you have exported FHIR data
- **Multi-record types** — visits, labs, prescriptions, allergies, etc.
- **Patient-view orientation** (not clinician)
- **React + Go** stack
- **NOT** EHR integration (that's Fasten Connect commercial)

- Upstream repo: <https://github.com/fastenhealth/fasten-onprem>
- Docs: <https://docs.fastenhealth.com>
- Fasten Connect (commercial parallel): <https://www.fastenhealth.com>
- Discord: <https://discord.gg/Bykz6BAN8p>

## Architecture in one minute

- **Go** backend
- **React** frontend (Angular-based per README — may be React now)
- **SQLite** — DB
- **Resource**: low-moderate — 300-500MB RAM
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images**                                             | **Primary**                                                                        |
| Source             | Go build                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `health.example.com`                                        | URL          | TLS MANDATORY — HEALTH DATA                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong + MFA REQUIRED                                                                                    |
| Data volume          | For SQLite + uploads                                        | Storage      |                                                                                    |
| FHIR bundles (opt)   | Provider exports                                            | Import       | If available                                                                                    |
| Encryption (at rest) | Disk encryption (not app)                                                                                 | Security     |                                                                                    |

## Install via Docker

Follow: <https://docs.fastenhealth.com>

```yaml
services:
  fasten:
    image: ghcr.io/fastenhealth/fasten-onprem:latest        # **pin version**
    volumes:
      - fasten-data:/opt/fasten/db
    ports: ["8080:8080"]
    restart: unless-stopped

volumes:
  fasten-data: {}
```

## First boot

1. Start → browse web UI
2. Create account; enable MFA
3. Manually enter or FHIR-import first records
4. Configure categories
5. Put behind TLS reverse proxy
6. Encrypt disk at rest
7. Back up religiously

## Data & config layout

- `/opt/fasten/db/` — SQLite DB + uploaded PDFs/images

## Backup

```sh
# SQLite + attachments:
sudo tar czf fasten-$(date +%F).tgz fasten-data/
# Consider encrypted backup (age, GPG, borg-with-encryption)
```

## Upgrade

1. Releases: <https://github.com/fastenhealth/fasten-onprem/releases>. Active.
2. Docker pull + restart
3. **BACK UP BEFORE** — health data is irreplaceable

## Gotchas

- **PERSONAL HEALTH RECORD = TOP-OF-CROWN-JEWEL**:
  - Medical records = most-sensitive personal data category
  - US: HIPAA (provider-side) + various state-laws
  - EU: GDPR Art. 9 "special category data" (explicit-consent-required)
  - Federal laws: GINA (genetic), ADA (disability-related), HITECH
  - **90th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **HEALTHCARE-CROWN-JEWEL sub-family NOW 4 TOOLS** — SparkyFitness (94) + Garmin-Grafana (98) + Papermerge-for-medical (103) + **Fasten Health (107)** — **Fasten is PURE-healthcare (not a secondary use-case)**
  - **Sub-family formalized at 4 tools** — solidifying
  - **NEW CROWN-JEWEL Tier 1 sub-category formalized: "personal-health-record-tool"** (Fasten 1st pure-PHR; Gramps has genealogy overlap)
  - **CROWN-JEWEL Tier 1: 23 tools; 20 sub-categories**
- **OSS vs COMMERCIAL CLEAR SEPARATION**:
  - Fasten OnPrem = community OSS = no EHR-integration
  - Fasten Connect = commercial = has 50k+ provider-integrations
  - README explicitly clarifies the separation
  - **Recipe convention: "OSS-tier-without-EHR-integration vs commercial-tier-with-integrations" clear-split positive-signal** — honest positioning
  - **NEW recipe convention** (Fasten 1st formally)
- **HIPAA + GDPR OBLIGATIONS FOR SELF-HOSTERS**:
  - If you host OWN records for yourself → largely outside HIPAA (patient-held data)
  - If you host for OTHERS → possibly regulated (business associate agreement, legal risk)
  - EU-based users → GDPR applies even for personal-data
  - **Recipe convention: "self-host-for-self-vs-others legal distinction" callout**
  - **NEW recipe convention**
- **DISK ENCRYPTION AT REST**:
  - Not-app-level; operating-system level
  - LUKS / Bitlocker / FileVault on the host
  - **Recipe convention: "disk-encryption-at-rest required for health-tools" callout**
  - **NEW recipe convention** (Fasten 1st)
- **BACKUP ENCRYPTION**:
  - Backups must be encrypted (not rsync-clear)
  - Tools: age, GPG, borg-with-encryption, restic
  - **Recipe convention: "encrypted-backups-mandatory for health-tools" callout**
- **MANUAL-ENTRY ONLY = LIMITED USEFULNESS**:
  - Without EHR-integration, data must be manually typed
  - Typos / incompleteness = inaccurate medical record
  - Decision: is this worth it vs just PDF-folder?
  - **Recipe convention: "manual-entry-data-accuracy-limit" callout**
- **FHIR-BUNDLE IMPORT**:
  - FHIR (Fast Healthcare Interoperability Resources) is the modern standard
  - Some US providers allow patient-initiated FHIR exports (via Meaningful Use laws)
  - Apple/Google Health export FHIR bundles
  - **Recipe convention: "FHIR-standard-support positive-signal"** — interoperability
  - **NEW positive-signal convention** (Fasten 1st)
- **ENCRYPTION AT REST = MINIMUM**:
  - Encrypt disk
  - App-level encryption of sensitive fields is rare
  - **Recipe convention: "app-level-encryption-gap" callout** (field-level encryption uncommon)
- **2FA MANDATORY**:
  - Due to health-data-sensitivity
  - TOTP app minimum
  - **Recipe convention: "MFA-mandatory for health-tools" callout**
  - **NEW recipe convention**
- **COMMERCIAL-TIER-TAXONOMY**:
  - "OSS-without-feature" + "commercial-with-feature"
  - Distinct from other models: Dittofeed (106) is feature-gated-closed-source; Fasten is **separate-product-ecosystem**
  - **NEW sub-category: "parallel-commercial-product-with-different-capabilities"** — 1st tool named (Fasten Health)
- **REQUEST-PROVIDERS FORM**:
  - Community can request provider-integration-via-Connect
  - Signals Connect's commercial-interest in provider-addition
- **INSTITUTIONAL-STEWARDSHIP**: fastenhealth org + community + commercial-parallel. **76th tool — community-with-commercial-parallel sub-tier** (**NEW sub-tier** — distinct from "founder-with-commercial-tier" because OnPrem is community-maintained, Connect is the commercial arm)
  - **NEW sub-tier: "community-OSS-with-commercial-parallel-product"** — 1st tool named (Fasten Health)
- **TRANSPARENT-MAINTENANCE**: active + CI + Discord + newsletter + docs + clear-OSS-vs-commercial-split + screenshots. **84th tool in transparent-maintenance family.**
- **PHR-CATEGORY (rare OSS):**
  - **Fasten OnPrem** — Go; self-hosted; PHR
  - **OpenEMR** — EHR; different scope (clinician-facing)
  - **OpenMRS** — EHR; different scope
  - **Librehealth** — EHR
  - **Apple Health Records** (commercial; iOS only)
  - **Google Health** (discontinued/various)
  - **Microsoft HealthVault** (discontinued 2019)
- **ALTERNATIVES WORTH KNOWING:**
  - **OpenEMR / OpenMRS** — if you're a clinician (EHR, not PHR)
  - **Paper folder** — minimum viable PHR
  - **Apple Health Records** — if you're all-Apple
  - **Choose Fasten OnPrem if:** you want OSS + self-hosted + patient-side PHR + FHIR-import capable.
- **PROJECT HEALTH**: active + commercial-parallel (funded) + Discord + docs + CI. Strong despite OSS being secondary to commercial business.

## Links

- Repo: <https://github.com/fastenhealth/fasten-onprem>
- Docs: <https://docs.fastenhealth.com>
- Commercial: <https://www.fastenhealth.com>
- Discord: <https://discord.gg/Bykz6BAN8p>
- FHIR standard: <https://www.hl7.org/fhir/>
- OpenEMR (alt EHR): <https://www.open-emr.org>
- OpenMRS (alt EHR): <https://openmrs.org>

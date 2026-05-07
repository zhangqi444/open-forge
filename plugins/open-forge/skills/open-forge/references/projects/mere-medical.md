---
name: mere-medical
description: Mere Medical recipe for open-forge. Self-hosted personal health record app that aggregates medical records from Epic MyChart, Cerner, OnPatient, VA, and other patient portals. Privacy-focused, offline-first PWA. Docker. Source: https://github.com/cfu288/mere-medical
---

# Mere Medical

Self-hosted personal health record web app. Aggregates and syncs medical records from multiple patient portals (Epic MyChart, Cerner, OnPatient, VA, Healow, Veradigm) into a single timeline view. Privacy-focused (data stays on your server), offline-first PWA, and supports thousands of hospitals and clinics. React + Node.js. Docker. GPL-3.0 licensed.

> **Note:** Requires third-party API credentials (OAuth client IDs) from each patient portal you want to connect — these must be registered separately with Epic, Cerner, etc.

Upstream: <https://github.com/cfu288/mere-medical> | Demo: <https://demo.meremedical.co> | Docs: <https://meremedical.co>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker | Recommended |
| DigitalOcean | App Platform | 1-click deploy available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | PUBLIC_URL | Public URL of the instance, e.g. https://health.example.com |
| config (optional) | ONPATIENT_CLIENT_ID + SECRET | Register at https://onpatient.com/o/applications/ |
| config (optional) | EPIC_CLIENT_ID / EPIC_CLIENT_ID_DSTU2 / EPIC_CLIENT_ID_R4 | Register at https://fhir.epic.com |
| config (optional) | EPIC_SANDBOX_CLIENT_ID (+ DSTU2/R4 variants) | Epic sandbox credentials |
| config (optional) | CERNER_CLIENT_ID | Register at https://code.cerner.com |
| config (optional) | VERADIGM_CLIENT_ID | Register at Veradigm developer portal |
| config (optional) | VA_CLIENT_ID | Register at https://developer.va.gov |
| config (optional) | HEALOW_CLIENT_ID + SECRET | Register at Healow/eClinicalWorks developer portal |

## Software-layer concerns

- **Offline-first PWA** — installs on mobile devices from the browser; data cached locally for offline access
- **FHIR-based** — uses FHIR (Fast Healthcare Interoperability Resources) APIs to fetch records from compatible patient portals
- No built-in database server — data stored client-side (IndexedDB) in the browser; the server is stateless
- Third-party API registration required for each portal provider — client IDs are issued by healthcare systems, not by Mere Medical

## Install — Docker Compose

```yaml
services:
  app:
    image: cfu288/mere-medical:latest
    ports:
      - '4200:80'
    environment:
      - PUBLIC_URL=https://health.example.com
      # Add only the portals you've registered for:
      - ONPATIENT_CLIENT_ID=${ONPATIENT_CLIENT_ID}
      - ONPATIENT_CLIENT_SECRET=${ONPATIENT_CLIENT_SECRET}
      - EPIC_CLIENT_ID=${EPIC_CLIENT_ID}
      - EPIC_CLIENT_ID_DSTU2=${EPIC_CLIENT_ID_DSTU2}
      - EPIC_CLIENT_ID_R4=${EPIC_CLIENT_ID_R4}
      - EPIC_SANDBOX_CLIENT_ID=${EPIC_SANDBOX_CLIENT_ID}
      - EPIC_SANDBOX_CLIENT_ID_DSTU2=${EPIC_SANDBOX_CLIENT_ID_DSTU2}
      - EPIC_SANDBOX_CLIENT_ID_R4=${EPIC_SANDBOX_CLIENT_ID_R4}
      - CERNER_CLIENT_ID=${CERNER_CLIENT_ID}
      - VERADIGM_CLIENT_ID=${VERADIGM_CLIENT_ID}
      - VA_CLIENT_ID=${VA_CLIENT_ID}
      - HEALOW_CLIENT_ID=${HEALOW_CLIENT_ID}
      - HEALOW_CLIENT_SECRET=${HEALOW_CLIENT_SECRET}
```

```bash
docker compose up -d
# Access at http://yourserver:4200
```

## Install — Docker run

```bash
docker run -d \
  --name mere-medical \
  --restart unless-stopped \
  -p 4200:80 \
  -e PUBLIC_URL=https://health.example.com \
  -e ONPATIENT_CLIENT_ID=<ID_HERE> \
  -e ONPATIENT_CLIENT_SECRET=<SECRET_HERE> \
  -e EPIC_CLIENT_ID=<ID_HERE> \
  cfu288/mere-medical:latest
```

## Upgrade procedure

```bash
docker pull cfu288/mere-medical:latest
docker compose up -d
```

## Gotchas

- **API registration is the hard part** — you need to register your self-hosted instance as an OAuth app with each patient portal provider (Epic, Cerner, etc.) to get client IDs. This process varies per provider and may require approval.
- **PUBLIC_URL must match your OAuth redirect URI** — the URL you register with each portal must match `PUBLIC_URL` exactly, or OAuth callbacks will fail.
- **Single-developer project** — maintained by a full-time medical resident; updates may be infrequent. "Pre-release" label has been there since 2022 but backward compatibility is generally maintained.
- **Data lives in the browser** — Mere Medical is stateless on the server side. Records are stored in the browser's IndexedDB. Clearing browser data deletes your health records. Use the export feature to back up.
- Omit env vars for portals you haven't registered — unused portal env vars can be left out entirely.

## Links

- Source: https://github.com/cfu288/mere-medical
- Documentation: https://meremedical.co
- Demo: https://demo.meremedical.co
- Epic FHIR registration: https://fhir.epic.com
- Cerner registration: https://code.cerner.com
- VA API registration: https://developer.va.gov

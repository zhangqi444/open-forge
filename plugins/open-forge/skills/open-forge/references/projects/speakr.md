---
name: Speakr
description: "Self-hosted AI transcription + intelligent note-taking for recordings & meetings. Whisper / WhisperX ASR + LLM for summarization + voice profiles + OIDC. Python. AGPL-3.0. Active; sole-maintainer murtaza-nasir. Alpha 0.8.x."
---

# Speakr

Speakr is **"Otter.ai / Fireflies.ai / Descript — self-hosted + AGPL + private"** — transforms audio recordings into organized, searchable, intelligent notes. Record in-browser or upload; Whisper/WhisperX transcription with speaker identification (voice profiles via embeddings); LLM-powered chat + semantic search across your recording archive. Designed for privacy-conscious individuals + groups whose conversations can't leave their infrastructure.

Built + maintained by **murtaza-nasir** (sole maintainer) + community. License: **AGPL-3.0** (explicit). Active; alpha status (0.8.x); docs site at murtaza-nasir.github.io/speakr; Docker image at learnedmachine/speakr; CI-tested; OIDC + SSO support; rich feature-set expanding.

Use cases: (a) **meeting transcription + summarization** — replace $10-29/mo/seat Otter.ai (b) **interview archive** — journalists, qualitative researchers, anthropologists (c) **legal discovery** — attorney-client recordings (with appropriate legal framework) (d) **medical documentation** — doctor-patient visits (with HIPAA nuance) (e) **therapy session notes** — with explicit client consent (f) **lecture capture** — students + professors (g) **podcast production** — transcript for editing + SEO (h) **voice-first journaling** — ramble-to-AI workflow (i) **compliance recording** — financial advice calls, insurance sales (j) **executive coaching** — session review.

Features (per README):

- **Smart recording & upload** (browser + mobile + file)
- **AI transcription with speaker ID** — Whisper/WhisperX
- **Voice profiles** with embeddings (WhisperX required)
- **REST API v1** + Swagger
- **OIDC SSO** — Keycloak, Azure AD, Google, Auth0, Pocket ID
- **Audio-transcript sync** — click to jump, follow mode
- **Interactive chat** — ask questions about recordings
- **Inquire mode** — semantic search
- **Internationalization** (EN/ES/FR/DE/ZH/RU)
- **Sharing** (internal + public + group)
- **Group tags + retention policies** — auto-delete
- **Smart tagging with AI prompts** — tag-prompt-stacking

- Upstream repo: <https://github.com/murtaza-nasir/speakr>
- Docs: <https://murtaza-nasir.github.io/speakr>
- Docker Hub: <https://hub.docker.com/r/learnedmachine/speakr>
- Releases: <https://github.com/murtaza-nasir/speakr/releases>

## Architecture in one minute

- **Python** (Flask/FastAPI) + web frontend
- **SQLite / Postgres** — DB
- **Whisper / WhisperX** — ASR (external service or bundled)
- **OpenAI-compatible LLM endpoint** — for chat, summaries, tag-prompt processing
- **Vector store** — for semantic search (likely FAISS or chroma)
- **Resource**: moderate-to-heavy — 2-8GB RAM + GPU strongly recommended for real-time Whisper
- **Port**: configurable

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`learnedmachine/speakr`**                                     | **Primary**                                                                        |
| Docker Compose     | Upstream docs                                                   | Recommended                                                                                   |
| Bare-metal Python  | uv / pip install                                                                                    | DIY                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `speakr.example.com`                                        | URL          | TLS MANDATORY                                                                                    |
| DB                   | SQLite / Postgres                                           | DB           |                                                                                    |
| ASR endpoint         | Whisper / WhisperX server URL                              | **CRITICAL** | **GPU strongly recommended**                                                                                    |
| LLM endpoint         | OpenAI-compatible: OpenAI / Anthropic proxy / local LocalAI / Ollama | **CRITICAL** | **IF using OpenAI/Anthropic direct = transcripts sent offsite**                                                                                    |
| `SECRET_KEY`         | Flask session                                                                                 | **CRITICAL** | **IMMUTABLE**                                                                                    |
| Admin creds          | First-boot                                                                                 | Bootstrap    | Strong + MFA                                                                                    |
| OIDC config          | (optional) SSO                                                                                                      | SSO          |                                                                                                            |
| SMTP                 | Notifications + invites                                                                                                                                  | Email        |                                                                                                                                            |
| Storage              | Audio files (can be LARGE)                                                                                                                                  | Storage      | TBs for heavy use                                                                                                                                            |

## Install via Docker

Follow upstream quick-start: <https://murtaza-nasir.github.io/speakr/getting-started>

```yaml
services:
  speakr:
    image: learnedmachine/speakr:0.8.15-alpha        # **pin alpha version**
    ports: ["8899:8899"]
    restart: unless-stopped
    volumes:
      - ./speakr-data:/data
      - ./speakr-instance:/app/instance
    environment:
      SECRET_KEY: ${SECRET_KEY}
      ASR_BASE_URL: "http://whisperx:9000"
      OPENAI_BASE_URL: "http://ollama:11434/v1"
      OPENAI_API_KEY: "dummy-for-local"
      OPENAI_MODEL: "llama3:8b"
      # or OPENAI_BASE_URL=https://api.openai.com/v1 + real OPENAI_API_KEY
  # whisperx + llm services alongside
```

## First boot

1. Pre-requisites: Whisper/WhisperX service + LLM service
2. Start Speakr; browse to URL
3. Register admin; configure OIDC (optional)
4. Upload a test recording; verify transcription + speaker ID
5. Test chat + inquire (semantic search)
6. Configure retention policies
7. Enable MFA
8. Set up group tags + sharing
9. Put behind TLS reverse proxy
10. Back up DB + audio dir

## Data & config layout

- `/data/` — audio files (LARGE; plan storage)
- `/app/instance/` — DB + embeddings + config
- Vector store — embeddings for semantic search

## Backup

```sh
sudo tar czf speakr-$(date +%F).tgz speakr-data/ speakr-instance/
```

## Upgrade

1. Releases: <https://github.com/murtaza-nasir/speakr/releases>. Active; alpha 0.8.x.
2. Docker: pull + restart; migrations auto-run.
3. **Alpha = expect breaking changes**; back up before every upgrade.

## Gotchas

- **RECORDINGS = EXTREMELY-SENSITIVE DATA** (HIGHEST TIER):
  - Meeting audio captures: confidential business strategy, legal discussions, medical info, personal conversations
  - Voice biometrics (voice profiles) = biometric-identifier under GDPR Art.9 + BIPA (Illinois)
  - Transcripts are searchable → more usable than raw audio → more dangerous if leaked
  - **63rd tool in hub-of-credentials family — CROWN-JEWEL Tier 1 (12th tool)** — meeting-recording-and-AI-derivative-data sensitivity matches or exceeds password-manager risk
  - **CROWN-JEWEL Tier 1 now 12 TOOLS**: Octelium, Guacamole, Homarr, pgAdmin, WGDashboard, Lunar, Dagu, GrowChief, Mixpost, Vito, Sshwifty, **Speakr** — **NEW sub-category: "meeting-recording-repository"**
- **LEGAL RECORDING CONSENT**:
  - **US**: two-party-consent states (CA, FL, IL, MD, MA, MT, NV, NH, PA, WA) — all participants must consent
  - **One-party-consent states** — recording is legal with ONE participant's knowledge (but ethical issues remain)
  - **EU (GDPR)**: explicit consent required; legitimate-interest MAY apply for business purposes with proportionality test
  - **Always display recording indicator** — consent-reminder UX; mandatory in many jurisdictions
  - **Recipe convention: "audio-recording-consent-framework" callout** — applies to Speakr, any recording tool
  - **NEW recipe convention**
- **HIPAA / MEDICAL USE**:
  - Speakr is not HIPAA-certified out-of-the-box
  - BAA (Business Associate Agreement) = legally required with any 3rd-party service touching PHI
  - If using OpenAI/Anthropic LLM for medical transcripts → BAA with them; OpenAI offers one on paid plans
  - Self-hosted LocalAI/Ollama with local Whisper = no offsite PHI → closer to HIPAA-compliant but still needs full compliance audit
  - **Recipe convention: "HIPAA-Business-Associate-Agreement-requirement" callout** for medical use cases
- **BIPA / VOICE BIOMETRICS (Illinois)**:
  - Speakr voice profiles = biometric identifiers
  - BIPA: written consent + retention policy + deletion schedule
  - **HEALTHCARE-CROWN-JEWEL sub-family enhanced with voice-biometric-specific risk**
- **AGPL-3.0 NETWORK-SERVICE-DISCLOSURE**:
  - Hosting Speakr-as-a-SaaS for clients = AGPL-triggered
  - Modifications must be disclosed
  - **Recipe convention reinforced** (Worklenz 100 + Stoat 101 precedent)
- **LLM CHOICE = PRIVACY DETERMINANT**:
  - OpenAI API = transcripts sent to OpenAI (training opt-out available but data still travels)
  - Anthropic API = transcripts sent to Anthropic
  - LocalAI / Ollama = transcripts stay local
  - **Speakr's privacy claim depends on LLM choice** — pick accordingly
  - **Recipe convention: "LLM-provider-privacy-cascading-dependency"** — tools that accept arbitrary LLM backends should flag this
  - **NEW recipe convention**
- **ASR-AUDIO-TRANSCRIPTION-SERVICE-CATEGORY** (subset of AI-model-serving-tool category):
  - **3rd AI-model-serving-tool**: Speaches 96, Willow 101 (WIS), **Speakr 102** (ASR via Whisper/WhisperX)
  - **NEW sub-category: "ASR-transcription-service"** — retroactively applies to Speaches
- **PUBLIC SHARING = DATA-LEAK RISK**:
  - Public shared-links expose recording content
  - Speakr has "admin-controlled public sharing" which is good
  - Still: audit + expire + password-protect public shares
- **HUB-OF-CREDENTIALS TIER 1**:
  - All recorded audio + transcripts
  - Voice biometric profiles
  - OIDC tokens (federated identity)
  - LLM API keys (potentially expensive if leaked → used for crypto mining)
  - SMTP creds
  - Group memberships + sharing permissions
  - Admin = god mode over all recordings
- **AUTO-DELETION + RETENTION POLICIES**:
  - Speakr has retention policies — good for compliance (GDPR right-to-erasure, CCPA deletion)
  - Tag-protection prevents auto-deletion for critical recordings
  - **Recipe convention: "retention-policy-as-compliance-feature"** — positive signal
- **SECRET_KEY IMMUTABILITY**: **42nd tool in immutability-of-secrets family.**
- **SOLE-MAINTAINER + ALPHA**:
  - murtaza-nasir solo
  - Alpha 0.8.x — not production-ready by upstream's own framing
  - **Recipe convention: "alpha-status-production-deployment-warning"** (standard for pre-1.0)
  - **49th tool in institutional-stewardship — sole-maintainer-with-community sub-tier (25th)**
- **TRANSPARENT-MAINTENANCE**: active + docs site + Docker + AGPL-explicit + i18n + rich-feature-roadmap + screenshots-docs. **56th tool in transparent-maintenance family.**
- **DATA-PORTABILITY**:
  - Audio files on disk = portable (just copy)
  - Transcripts in DB = can be exported via API
  - Voice profile embeddings = specific to Speakr; not portable
- **ALTERNATIVES WORTH KNOWING:**
  - **Otter.ai** (commercial SaaS) — polished; expensive at scale
  - **Fireflies.ai** (commercial SaaS) — meeting-bot focus
  - **Descript** (commercial) — editing + transcription
  - **Whisper CLI + custom scripts** — DIY; no UI
  - **Transcribee** — OSS; simpler
  - **Plaud.ai** (commercial hardware) — dedicated recorder
  - **Buzz** — OSS; Mac-focused desktop app; simpler
  - **Choose Speakr if:** you want comprehensive features + self-host + AGPL + AI-enrichment.
  - **Choose Buzz if:** you want simpler desktop tool.
  - **Choose Otter.ai if:** you want commercial + polished + can accept cloud.
- **PROJECT HEALTH**: active + comprehensive feature-set + docs + alpha-noted + CI + i18n. Strong signals for rapidly-maturing alpha.

## Links

- Repo: <https://github.com/murtaza-nasir/speakr>
- Docs: <https://murtaza-nasir.github.io/speakr>
- Docker: <https://hub.docker.com/r/learnedmachine/speakr>
- Releases: <https://github.com/murtaza-nasir/speakr/releases>
- WhisperX (ASR): <https://github.com/m-bain/whisperX>
- Otter.ai (commercial alt): <https://otter.ai>
- Fireflies.ai (commercial alt): <https://fireflies.ai>
- Descript (commercial alt): <https://www.descript.com>
- Buzz (OSS alt): <https://github.com/chidiwilliams/buzz>
- BIPA (Illinois): <https://www.ilga.gov/legislation/ilcs/ilcs3.asp?ActID=3004>
- US two-party consent states: <https://www.matthiesenlaw.com/surveys-by-state/two-party-consent-states/>

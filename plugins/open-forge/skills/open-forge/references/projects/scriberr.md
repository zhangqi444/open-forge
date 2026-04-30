---
name: Scriberr
description: "Open-source offline audio-transcription app. Self-hosted + privacy-focused + performance-tuned. Go + Svelte (likely); Whisper-based. rishikanthc sole maintainer. ⚠️ DEVELOPMENT PAUSED (as of README update) — maintainer affected by eBay layoffs; seeking collaborators."
---

# Scriberr

Scriberr is **"OpenAI Whisper — but self-hosted + web-UI + offline + privacy-first"** — an open-source offline audio transcription application designed for self-hosters who value privacy + performance. Upload audio → local Whisper-based transcription → browse transcripts. No cloud dependency.

Built + maintained by **Rishikanth (rishikanthc)**. License: check LICENSE. **⚠️ DEVELOPMENT PAUSED** (per README update) — maintainer affected by eBay layoffs; prioritizing job-search. **NOT ABANDONED** — but active development suspended. Seeking community collaborators.

Use cases: (a) **privacy-first meeting transcription** — recordings stay local (b) **podcast-to-transcript** — generate show notes (c) **lecture transcription** — student workflows (d) **interview archive** — journalist's private recordings (e) **voice-memo search** — Whisper gives searchable text (f) **accessibility** — generate captions for videos (g) **compliance** — data-sovereignty requirements (h) **journalist source-protection** — recordings never leave self-hosted infrastructure.

Features (per README):

- **Offline audio transcription** (Whisper-based)
- **Web UI** for upload + browse
- **Self-hosted**
- **Privacy-focused** — data doesn't leave server
- Check upstream for format support + language support

- Upstream repo: <https://github.com/rishikanthc/Scriberr>
- Website: <https://scriberr.app>
- Docs: <https://scriberr.app/docs>
- API Ref: <https://scriberr.app/api>
- Ko-Fi: <https://ko-fi.com/H2H41KQZA3>

## Architecture in one minute

- Check upstream (likely Go/Python backend + Svelte/React frontend)
- **Whisper model** (OpenAI open-source; local inference)
- **CPU or GPU** — GPU much faster
- **Resource**: moderate-high (CPU transcription slow; GPU fast but needs NVIDIA)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images likely**                                      | Check repo                                                                        |
| **CPU**            | Slow but works                                                                            | Minimal hardware                                                                                   |
| **GPU (NVIDIA)**   | Much faster                                                                                                            | Hardware-dependent                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `transcribe.example.com`                                    | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| Audio upload volume  | Storage                                                     | Storage      | Audio files can be large                                                                                    |
| Whisper model        | tiny / base / small / medium / large                        | AI           | Quality vs speed tradeoff                                                                                    |
| GPU (opt)            | NVIDIA CUDA                                                 | Hardware     | Much faster transcription                                                                                    |

## Install via Docker

Follow: <https://scriberr.app/docs>

```yaml
services:
  scriberr:
    image: (check upstream)        # **pin version**
    volumes:
      - scriberr-data:/app/data
      - scriberr-models:/app/models
    ports: ["8080:8080"]
    # GPU (optional):
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

volumes:
  scriberr-data: {}
  scriberr-models: {}
```

## First boot

1. Start → browse web UI
2. Configure Whisper model (start small; upgrade if CPU can handle)
3. Upload first audio; measure transcription time
4. Put behind TLS reverse proxy
5. Back up transcripts

## Data & config layout

- Audio uploads + transcripts + Whisper model weights
- Model weights large (tiny ~75MB, large ~3GB)

## Backup

Transcripts are valuable; audio replayable (keep originals elsewhere).

## Upgrade

⚠️ **DEVELOPMENT PAUSED** (per maintainer's README update). No guaranteed cadence. Consider:

- Pinning to last-known-good version
- Watching for community-PR merges
- Monitoring for maintainer's return or community-fork

## Gotchas

- **⚠️ DEVELOPMENT PAUSED — HONEST ASSESSMENT**:
  - Maintainer (rishikanthc) affected by eBay layoffs (Apr 2026 batch — ~800 roles)
  - README explicitly states: "Development is paused for now, but NOT abandoned"
  - Maintainer open to community-contributors
  - **Recipe convention: "development-paused-maintainer-life-circumstances" HONEST-CALLOUT**
  - **NEW recipe convention** (Scriberr 1st formally) — important for consumers
  - **Don't interpret as abandoned**: different from abandonware; temporary hiatus
- **TRANSPARENT-MAINTAINER-CIRCUMSTANCES POSITIVE-SIGNAL**:
  - Maintainer publicly honest about personal situation affecting project
  - Better than silent-stall; gives users informed-consent for deployment
  - **Recipe convention: "transparent-maintainer-circumstances positive-signal"** — paradoxically positive despite stall
  - **NEW positive-signal convention** (Scriberr 1st) — honest > silent
- **100th HUB-OF-CREDENTIALS TIER 2 🎯 100-TOOL MILESTONE**:
  - Audio content = INTIMATE data (conversations, meetings, private recordings)
  - Transcripts searchable = enhanced privacy risk (analytic-over-content)
  - **100th tool in hub-of-credentials family — Tier 2** 🎯
  - **🎯 100-TOOL MILESTONE in hub-of-credentials family**
- **AUDIO = INTIMATE-MEDIA SUB-FAMILY**:
  - Private conversations, journalist-sources, medical-appointments, therapy sessions, ...
  - Higher sensitivity than text
  - **NEW sub-family: "intimate-audio-content-risk"** (1st — Scriberr)
  - Adjacent to "intimate-video-content" (camera tools), "intimate-annotations" (reading tools)
- **LOCAL-WHISPER = PRIVACY-FIRST POSITIVE-SIGNAL**:
  - No cloud transcription = no data-exfil to OpenAI
  - Reinforces "self-hosted-LLM/AI positive-signal" from prior tools
  - **Recipe convention: "local-AI-inference-privacy-first positive-signal"**
  - **NEW positive-signal convention** (Scriberr 1st formally)
- **GPU-OPTIONAL / CPU-FALLBACK**:
  - Works on CPU (slow for large audio) or GPU (fast)
  - Hardware-dependent tool but not hardware-MANDATORY
  - **Hardware-dependent-tool: 3 tools** (prior 2 + **Scriberr** as GPU-optional variant)
  - **3-tool milestone**
- **WHISPER-BASED = UPSTREAM-DEPENDENCY**:
  - Whisper is OpenAI-released OSS
  - Future model updates depend on OpenAI + community-maintained versions (faster-whisper, whisper.cpp)
  - **Recipe convention: "OSS-model-upstream-dependency" callout**
- **KO-FI FUNDING**:
  - Alternative to Patreon/GitHub Sponsors
  - **Recipe convention: "Ko-Fi-funding positive-signal"**
  - **NEW positive-signal convention** (Scriberr 1st formally)
- **MAINTAINER ALSO LOOKING FOR OPPORTUNITIES** (per README):
  - AI/ML engineer or researcher
  - **Community signal**: help human in addition to software
  - Unusual openness
- **SOLE-MAINTAINER RISK** (extended):
  - Sole-maintainer + paused-development = high-risk for production-deploy
  - **Recipe convention: "sole-maintainer-bus-factor-1 risk"** (standard sole-maintainer applies)
- **PAUSED-BUT-NOT-ABANDONED DISTINCTION**:
  - Different from "abandonware"
  - **Recipe convention: "paused-but-not-abandoned distinction"** — important category
  - **NEW recipe convention** (Scriberr 1st formally)
- **AI-MODEL-SERVING-TOOL: 4 tools** (prior 3 + **Scriberr**) — 4-tool milestone approaching
- **INSTITUTIONAL-STEWARDSHIP**: sole-maintainer (rishikanthc) + honest-about-life-circumstances + Ko-Fi. **86th tool — sole-maintainer-paused-honestly sub-tier** (**NEW sub-tier**).
  - **NEW sub-tier: "sole-maintainer-in-life-transition-honest"** (Scriberr 1st)
- **TRANSPARENT-MAINTENANCE**: docs + Ko-Fi + API-ref + website + honest-pause-notice. **94th tool in transparent-maintenance family** (honest-maintenance, not active-maintenance).
- **TRANSCRIPTION-CATEGORY:**
  - **Scriberr** — Whisper-based; paused
  - **Whisperx** — research-oriented
  - **whisper.cpp** — C++ + CPU-fast
  - **faster-whisper** — Python faster Whisper
  - **Deepgram / AssemblyAI** (commercial) — cloud APIs
  - **Aiko** — Mac-native
  - **Subtitle Edit** — GUI desktop tool
- **ALTERNATIVES WORTH KNOWING:**
  - **whisper.cpp** — if you want CLI + CPU-optimized
  - **faster-whisper** — if you want Python library
  - **Aiko** — if you're Mac-first
  - **Choose Scriberr if:** you want web-UI + self-hosted + privacy — BUT verify pause-status + consider fork/backup plan
- **PROJECT HEALTH**: ⚠️ **PAUSED** (honest) + sole-maintainer + Ko-Fi + docs. **Deploy with awareness of hiatus**.

## Links

- Repo: <https://github.com/rishikanthc/Scriberr>
- Website: <https://scriberr.app>
- whisper.cpp (alt): <https://github.com/ggerganov/whisper.cpp>
- faster-whisper (alt): <https://github.com/SYSTRAN/faster-whisper>
- OpenAI Whisper (original): <https://github.com/openai/whisper>

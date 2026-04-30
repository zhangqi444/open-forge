---
name: Speaches
description: "OpenAI-API-compatible TTS+STT+translation server. faster-whisper (transcription) + piper/kokoro (TTS). \"Ollama for speech models.\" Dynamic model loading. GPU+CPU. MIT. Active. Replaces OpenAI's Whisper+TTS API for privacy/cost."
---

# Speaches

Speaches is **"Ollama, but for speech models"** — an OpenAI-API-compatible server for streaming **transcription (speech-to-text)**, **translation**, and **speech generation (text-to-speech)**. Speech-to-Text is powered by **faster-whisper**; Text-to-Speech by **Piper** and **Kokoro** (the latter ranked #1 in the TTS Arena). All your OpenAI-API-using tools (SDKs, Zapier integrations, apps, LLM agents) should work with Speaches out-of-the-box by just changing the `base_url`. Dynamic model loading (load on request, unload on inactivity). Supports CPU + GPU.

Built + maintained by **speaches-ai** / community. **License: MIT**. Active; documentation at speaches.ai; Docker-Compose deployment.

Use cases: (a) **private transcription** — dictation + meeting notes + audio-to-text without OpenAI-API round-trip (b) **local TTS voice synthesis** — articles-to-audio, notification-read-aloud, accessibility (c) **replace OpenAI Whisper API + Realtime API for cost/privacy** (d) **home-assistant voice pipeline** — Whisper+Piper for fully-local voice (e) **video transcription workflows** — batch-process recordings (f) **speech-to-speech LLM agents** — audio in → LLM thinks → audio out (g) **streaming transcription** — SSE stream as audio is transcribed (real-time captioning).

Features (from upstream README):

- **OpenAI-API compatible** — drop-in replacement for Whisper + Audio + Realtime endpoints
- **Audio chat completions** — audio in / audio out
- **Streaming transcription** via SSE
- **Dynamic model load/unload** — memory-efficient
- **Kokoro TTS** — #1 in TTS Arena (free + MIT via hexgrad)
- **Piper TTS** — fast + lightweight (many voices)
- **GPU and CPU** support (CUDA primary)
- **Realtime API** (OpenAI realtime-compatible)
- **Docker Compose / Docker** deploy
- **Highly configurable**

- Upstream repo: <https://github.com/speaches-ai/speaches>
- Homepage + docs: <https://speaches.ai>
- Installation: <https://speaches.ai/installation/>
- Configuration: <https://speaches.ai/configuration/>
- Realtime API usage: <https://speaches.ai/usage/realtime-api>
- Docker Hub: likely `ghcr.io/speaches-ai/speaches`
- faster-whisper: <https://github.com/SYSTRAN/faster-whisper>
- Piper TTS: <https://github.com/rhasspy/piper>
- Kokoro TTS: <https://huggingface.co/hexgrad/Kokoro-82M>

## Architecture in one minute

- **Python** — FastAPI-style
- **faster-whisper** — CTranslate2-optimized Whisper for STT
- **piper** + **kokoro** — TTS models
- **Dynamic model loading**: models loaded on first request; unloaded after inactivity
- **Resource**: **GPU strongly recommended** for Whisper large + realtime
  - CPU-only: small Whisper works; Kokoro CPU-OK; real-time is strained
  - GPU: 8-16GB VRAM for Whisper-large + Kokoro
- **Port 8000** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Per docs: GPU variant with `deploy.resources.reservations`**    | **Primary path (GPU)**                                                             |
| Docker (CPU)       | CPU-only image variant                                                    | Lower-performance OK for small Whisper + Kokoro                                                                                   |
| Bare-metal Python  | `pip install speaches` + run                                                                | DIY; useful for dev                                                                                               |
| **NOT RECOMMENDED** | **Public-exposing this server**                                                                                     | Anyone with access can use your GPU / flood you; authenticate + firewall                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| GPU available        | Nvidia CUDA?                                                | **CRITICAL** | **Decides variant**                                                                                    |
| Models to run        | Whisper (tiny/base/small/medium/large), Kokoro, Piper voices | Config       | Affects VRAM sizing                                                                                    |
| API key / auth       | If exposing beyond localhost                                                                           | **CRITICAL** | **Upstream auth story is limited; use proxy + auth**                                                                                    |
| Storage for models   | `~/.cache/huggingface` or bind-mount                                                                             | Storage      | Models are multi-GB                                                                                                            |
| OpenAI-compat base URL | Where clients should point their `base_url`                                                                                    | URL          | `http://speaches:8000/v1`                                                                                                                            |

## Install via Docker compose (GPU variant, per docs)

```yaml
services:
  speaches:
    image: ghcr.io/speaches-ai/speaches:latest-cuda    # **pin version**
    restart: unless-stopped
    ports: ["8000:8000"]
    volumes:
      - ./speaches-cache:/root/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

## First boot

1. Start → verify logs show GPU detected (or CPU-only intentional)
2. `curl http://host:8000/v1/audio/transcriptions` — test endpoint
3. Upload a test audio file; verify transcription
4. Test TTS: `curl -X POST http://host:8000/v1/audio/speech -d '...'`
5. Point your OpenAI-using tool at `base_url=http://speaches:8000/v1`
6. Verify client works end-to-end
7. **DO NOT expose publicly** without auth / reverse-proxy with password
8. Monitor GPU usage + memory

## Data & config layout

- `~/.cache/huggingface` — downloaded model weights (multi-GB)
- Config via env vars
- No user DB; no accounts; stateless session model

## Backup

- Models are redownloadable — back up only if bandwidth is expensive.
- No user data to back up.

## Upgrade

1. Releases: <https://github.com/speaches-ai/speaches/releases>. Active + recent project.
2. Docker: pull + restart; reload models.
3. Watch for breaking API changes in pre-1.0 project.

## Gotchas

- **OPENAI-API-COMPATIBLE = BIG WIN FOR ECOSYSTEM**: any tool that uses OpenAI's Whisper + Audio + Realtime APIs should work by changing `base_url`. This is Speaches's killer feature. Similar to how LocalAI + Ollama expose OpenAI-compat endpoints.
- **GPU STRONGLY RECOMMENDED** for:
  - Whisper-large (real-time on GPU; slow on CPU)
  - Realtime API (streaming bidirectional)
  - Multiple concurrent requests
  - **CPU-only is fine for**: occasional dictation, small Whisper, Kokoro-only
- **MODEL LICENSES VARY**:
  - **faster-whisper / Whisper**: MIT (code) + OpenAI model license (research-use by OpenAI; commercial-use-open question)
  - **Piper**: MIT; models individually-licensed (most permissive)
  - **Kokoro**: **MIT-licensed model** — unusual + generous for TTS models (most are restrictive)
  - **Verify model-specific licenses** before commercial use. Recipe convention: **"model-license-audit"** for AI-serving tools. Applicable to: Speaches, LocalAI, Ollama (model-license inheritance).
- **AUDIO DATA = PRIVACY-SENSITIVE**: uploaded audio may contain:
  - Personal conversations (meetings, family, medical)
  - Confidential business info
  - Confessions / secrets
  - **Logs should not retain audio beyond necessary** — configure log retention
  - **Don't expose Speaches publicly** — anyone with access can upload audio + GPU-abuse
- **HUB-OF-CREDENTIALS: LIGHT → NONE**: Speaches itself is stateless-compute-oriented. No user DB. API-key env if auth-enabled. **6th tool in stateless-tool-rarity** (OpenSpeedTest 91, Moodist 93, dashdot 93, Redlib 95 no-OAuth, Converse 96, **Speaches 96**).
- **BUT THE DATA FLOWING THROUGH IS SENSITIVE** — audio in transit + transcripts out. If you proxy requests from an LLM chain, transcripts become part of conversation context. Treat transcripts as conversation-history-sensitive.
- **OPEN-ACCESS-GPU ATTACK**: if exposed publicly without auth, attackers can submit arbitrary audio to drain your GPU cycles + costs (if cloud). Mitigation:
  - Reverse-proxy auth (nginx basic-auth or oauth2-proxy)
  - Rate limiting
  - IP allowlist
  - VPN-only access
- **REALTIME API = LOW-LATENCY REQUIREMENT**: bidirectional streaming needs WebSocket + low network latency. Don't run Realtime API over high-latency or spotty links.
- **PIPER VOICE QUALITY** — fast but robotic-ish (good for notifications / low-compute).
- **KOKORO VOICE QUALITY** — excellent (ranked #1 TTS Arena). Higher compute.
- **BATCH vs STREAMING MODE**:
  - Batch: full-audio-in, full-transcript-out (like Whisper CLI)
  - Streaming: SSE chunks as audio transcribes (real-time captioning)
  - Choose based on use case
- **TRANSPARENT-MAINTENANCE**: MIT + active commits + docs + demo + SSE-streaming demo. **28th tool in transparent-maintenance family.**
- **SOLE-MAINTAINER-RISK**: speaches-ai account + GitHub activity suggests small team or individual. **Risk factor for a still-maturing project.** Pin to specific versions; have fallback (OpenAI Whisper, local cli tools).
- **INSTITUTIONAL-STEWARDSHIP**: speaches-ai org + contributors. **23rd tool in institutional-stewardship family** — likely sole-maintainer-with-small-community sub-tier (maturity still emerging).
- **MIT LICENSE**: permissive + commercial-reuse friendly.
- **MODEL-SERVING-TOOL category** — Speaches joins the emerging category of:
  - **Ollama** — LLM serving
  - **LocalAI** — LLM serving + multi-modal
  - **vLLM** — LLM serving high-perf
  - **text-generation-webui** — LLM serving with UI
  - **ComfyUI / Automatic1111** — image-generation serving
  - **Speaches** — speech (STT + TTS + speech-to-speech)
  - **Piper HTTP wrapper / whisper.cpp server** — simpler alternatives
  - **Recipe convention: "AI-model-serving-tool" category** — tools that host AI models for local inference. Common gotchas: model licenses, GPU requirements, model-cache sizing, OpenAI-compat endpoints, public-exposure-GPU-drain-risk.
- **HOME ASSISTANT VOICE INTEGRATION**: Speaches can power HA's local voice pipeline (Whisper STT + Piper TTS). Reinforces fully-local-HA-voice narrative.
- **NEWER-PROJECT VELOCITY**: Speaches is relatively new (2024). Active velocity; APIs may change. Pin versions; test upgrades.
- **ALTERNATIVES WORTH KNOWING:**
  - **whisper.cpp** — C++ Whisper; low-dependency; single binary; for STT only
  - **whisper.cpp server** — HTTP wrapper around whisper.cpp
  - **faster-whisper-server** — CTranslate2 + HTTP wrapper
  - **Piper HTTP** — HTTP wrapper around Piper for TTS only
  - **Coqui TTS** — broader TTS framework; MPL-2.0; diverse voices
  - **Bark / Tortoise-TTS / XTTS** — higher-quality-but-slower TTS models
  - **LocalAI** — broader multi-modal (LLM + TTS + STT + image); OpenAI-compat
  - **Home Assistant Wyoming** — HA's voice-pipeline protocol (uses piper + whisper under the hood)
  - **OpenAI Whisper / TTS API** — commercial; fastest + easiest; not private
  - **ElevenLabs** — commercial TTS; best quality; paid
  - **Google / Azure STT/TTS** — commercial enterprise
  - **Choose Speaches if:** you want ONE server for STT+TTS+speech-speech + OpenAI-compat + easy Docker + GPU.
  - **Choose whisper.cpp if:** you want STT-only + minimal dependencies.
  - **Choose LocalAI if:** you want LLM+everything in one.
  - **Choose OpenAI API if:** you want easiest + accept commercial + don't need privacy.
- **PROJECT HEALTH**: newer + active + MIT + OpenAI-compat + well-positioned. Watch for 1.0 release + API stabilization.

## Links

- Repo: <https://github.com/speaches-ai/speaches>
- Homepage + docs: <https://speaches.ai>
- Installation: <https://speaches.ai/installation/>
- Configuration: <https://speaches.ai/configuration/>
- Realtime API: <https://speaches.ai/usage/realtime-api>
- faster-whisper: <https://github.com/SYSTRAN/faster-whisper>
- Piper TTS: <https://github.com/rhasspy/piper>
- Kokoro model: <https://huggingface.co/hexgrad/Kokoro-82M>
- TTS Arena: <https://huggingface.co/spaces/Pendrokar/TTS-Spaces-Arena>
- whisper.cpp (alt): <https://github.com/ggerganov/whisper.cpp>
- Coqui TTS (alt): <https://github.com/coqui-ai/TTS>
- LocalAI (alt broader): <https://localai.io>
- OpenAI API (commercial alt): <https://platform.openai.com/docs/guides/speech-to-text>
- ElevenLabs (commercial TTS): <https://elevenlabs.io>

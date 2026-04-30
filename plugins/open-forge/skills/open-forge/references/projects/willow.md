---
name: Willow
description: "Open-source local voice assistant (Alexa/Google Home alternative). ESP32-S3-BOX hardware + Willow Inference Server for STT/TTS/LLM. Pairs with Home Assistant / openHAB / Rhasspy. Tovera-commercial backer. Active. License: check repo."
---

# Willow

Willow is **"Alexa / Google Home / Siri — open-source + local-first + hardware-based"** — an open-source voice-assistant platform running on ESP32-S3-BOX devices (~$50 hardware). Pair with the **Willow Inference Server (WIS)** for fast local STT (speech-to-text), TTS (text-to-speech), and LLM inference. Integrates with Home Assistant, openHAB, and Rhasspy for command execution. All voice processing can be 100% local — zero cloud dependency.

Built + maintained by **Tovera Inc. (toverainc)** — commercial company behind the project + community. License: check repo (LICENSE file). Active; Willow Inference Server released as separate component; docs site at heywillow.io; GitHub Discussions for community support; hardware distribution to early adopters.

Use cases: (a) **replace Alexa/Google Home** with zero cloud and hardware you control (b) **home automation voice control** via Home Assistant integration (c) **privacy-first smart home** — voice never leaves LAN (d) **local STT/TTS for any application** — WIS serves other apps over WebRTC/HTTP too (e) **LLM voice interface** — ask a local Llama/Mistral via voice (f) **business/retail voice UX** — kiosk, reception, call center (g) **accessibility** — hands-free control for mobility-limited users (h) **off-grid / air-gapped deployments** — voice assistant that works without internet.

Features (from upstream README + docs at heywillow.io):

- **ESP32-S3-BOX** hardware target (commodity, ~$50)
- **Willow Inference Server** — STT + TTS + LLM on GPU
- **Home Assistant** + **openHAB** + **Rhasspy** integrations
- **WebRTC support** (WIS)
- **Local-first** — zero cloud dependency with WIS
- **Wake word detection**
- **Multi-room** (multiple Willow devices)

- Upstream repo: <https://github.com/toverainc/willow>
- WIS repo: <https://github.com/toverainc/willow-inference-server>
- Docs: <https://heywillow.io>
- Tovera Inc.: <https://tovera.com>
- Discussions: <https://github.com/toverainc/willow/discussions>

## Architecture in one minute

- **ESP32-S3-BOX** device → captures audio → streams to WIS
- **WIS** (GPU server) → Whisper STT → LLM (optional) → TTS → returns audio
- **Home Assistant** / **openHAB** / **Rhasspy** → receives command (voice-to-intent → action)
- **Resource**: WIS needs GPU (recommended NVIDIA with CUDA; Whisper models are memory-hungry — 8GB+ VRAM for large models)
- **Network**: LAN-only works; internet-optional for updates

## Compatible install methods

| Component          | Deployment                                                      | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Willow firmware** | **Flashed to ESP32-S3-BOX via USB**                            | **Hardware**                                                                        |
| **WIS**            | **Docker + GPU**                                                | **Server**                                                                        |
| Smart-home backend | Home Assistant / openHAB / Rhasspy                                                | Command target                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| ESP32-S3-BOX hardware | ~$50 on AliExpress / Digikey                               | Hardware     | Specific SKU matters                                                                                    |
| WIS host             | GPU server (NVIDIA recommended)                            | **CRITICAL** | Without WIS, Willow uses cloud STT (not private)                                                                                    |
| WiFi SSID + password | ESP32 connects here                                        | **CRITICAL** | **Stored on device — device capture = creds exposure**                                                                                    |
| WIS URL              | `wss://wis.example.com:19000`                              | Config       |                                                                                    |
| HA / openHAB URL + token | For command execution                                                                                 | Integration  |                                                                                    |
| Wake word            | "Hi, ESP" / "Alexa" / custom                                                                                   | UX           |                                                                                                            |

## Install (high-level)

1. Acquire ESP32-S3-BOX hardware
2. Flash Willow firmware (via web-flasher at heywillow.io)
3. Deploy WIS on GPU host (Docker + NVIDIA container runtime)
4. Device connects to WiFi + WIS
5. Configure HA/openHAB integration
6. Test: "Hey Willow, turn on the kitchen light"
7. Refine wake word + response voice

## Data & config layout

- **WIS**: model cache (Whisper + TTS + optional LLM), GPU memory
- **ESP32 devices**: WiFi creds + WIS URL in flash
- **Home Assistant**: token for Willow

## Backup

- **WIS models**: backup optional; re-downloadable
- **Device configs**: backup via web flasher export
- **HA integration config**: covered by HA backup

## Upgrade

1. Willow firmware: OTA via web UI or reflash
2. WIS: Docker pull + restart
3. Releases: <https://github.com/toverainc/willow/releases> + <https://github.com/toverainc/willow-inference-server/releases>

## Gotchas

- **VOICE DATA = HIGHLY-PRIVATE + CAN CAPTURE FAMILY CONVERSATIONS**:
  - Always-on microphones listen in home/office
  - Wake-word false triggers = private conversations streamed to WIS
  - **Local WIS mitigates** but on-device buffer could be exfiltrated if device compromised
  - **59th tool in hub-of-credentials family — PHYSICAL-SECURITY-CROWN-JEWEL sub-family (2nd tool after Viseron 99)** — but voice-surveillance subset
  - **NEW sub-category: "always-on-microphone-risk"** within PHYSICAL-SECURITY-CROWN-JEWEL (Willow 1st)
  - **Legal**: audio-recording laws vary by jurisdiction (two-party-consent states in US, GDPR in EU)
- **FAMILY/HOUSEHOLD CONSENT**: every household member must know:
  - Always-on mic is listening for wake-word
  - Audio sent to WIS (local) for processing
  - Guests should be informed (GDPR, common courtesy)
- **WIFI CREDENTIALS ON-DEVICE**:
  - ESP32 stores WiFi SSID + password in flash
  - Device theft / dumpster-dive = WiFi compromise
  - **Mitigation**: separate IoT VLAN with restricted access + unique WiFi for IoT devices
- **WIS = LOCAL AI-MODEL-SERVING-TOOL** (Speaches 96 category):
  - **2nd tool in AI-model-serving-tool category** (Speaches 96 was 1st; WIS 2nd)
  - Shares concerns: model-license-audit, GPU-requirement, open-access-GPU-attack-surface
  - **Recipe convention reinforced**: AI-model-serving tools require review of model licenses (Whisper = MIT; TTS models vary; LLMs vary WIDELY)
- **WAKE-WORD DETECTION ≠ VOICE AUTHENTICATION**:
  - Anyone in the room can issue commands
  - No speaker-verification (unlike some commercial systems with voice-ID)
  - **Physical access = command access** — don't make Willow able to unlock doors without additional auth
- **LLM-VIA-VOICE INTERFACE RISKS**:
  - Voice → LLM → action is a NEW attack surface
  - Prompt-injection via audio (yell "Ignore previous instructions" — works!)
  - LLM hallucinations → wrong action
  - **Recipe convention: "voice-LLM-prompt-injection-surface" callout** — applies to any voice-to-LLM bridge
  - **NEW convention**
- **HARDWARE DEPENDENCY** = unusual for self-hosted tools:
  - Willow is software+hardware; buying ESP32-S3-BOX is a prerequisite
  - Supply chain + geopolitics affect availability (Chinese electronics distribution)
  - **Recipe convention: "hardware-dependent tool" category** — rare in self-host world
- **COMMERCIAL-BACKER INSTITUTIONAL-STEWARDSHIP**:
  - Tovera Inc. is the commercial backer
  - **44th tool in institutional-stewardship — commercial-backed-open-source sub-tier** (similar to Umami, Plausible, Ghost, Chatwoot — companies that fund development while keeping OSS)
  - Counts under founder-with-commercial-tier-funded-development sub-tier
- **BETA-STATUS**: README starts with "Hello Willow users!" implying early-adopter phase. Expect breaking changes, firmware updates, evolving architecture. Back up device configs + WIS configs.
- **NETWORK-ISOLATION RECOMMENDED**:
  - Put Willow devices on IoT VLAN
  - WIS on trusted VLAN
  - Firewall between
  - Prevents IoT-device compromise from pivoting to main network
- **POWER-DRAIN**: always-on device + GPU WIS idle — significant baseline power cost (~50-200W for WIS GPU idle). Plan electricity accordingly.
- **WISE DEFAULTS**:
  - Disable cloud fallback if privacy matters
  - Don't expose WIS to public internet
  - Rotate integration tokens
- **TRANSPARENT-MAINTENANCE**: active + docs site + Discussions + hardware-distribution to early-adopters + WIS released + commercial-backer. **51st tool in transparent-maintenance family.**
- **LICENSE CHECK**: verify LICENSE (LICENSE-file-verification-required convention).
- **VOICE-ASSISTANT-CATEGORY (OSS subset)**:
  - **Rhasspy** — older; Python; wide device support; active community
  - **Mycroft** — famously-struggled commercially; ecosystem-fragmented
  - **Home Assistant Year-of-the-Voice** — official HA voice (Piper + Whisper integrations)
  - **OpenVoiceOS (OVOS)** — Mycroft-community-fork
  - **Willow** — hardware-included + WIS-integrated; modern
  - **ESPHome voice-assistant** — similar ESP32-based; HA-integrated
  - **Commercial**: Alexa / Google / Siri / Bixby / HomePod
- **ALTERNATIVES WORTH KNOWING:**
  - **Rhasspy** — if you want pure-software + existing hardware
  - **Home Assistant voice assistant** — if you want HA-first + Piper + Whisper
  - **ESPHome voice** — if you're already ESPHome-native
  - **OpenVoiceOS** — if you want Mycroft-lineage + community
  - **Choose Willow if:** you want turnkey ESP32-hardware + WIS + WebRTC + commercial-backed.
  - **Choose Rhasspy if:** you want max-device-support + pure-software.
  - **Choose HA-voice if:** you want HA-native + polished.
- **PROJECT HEALTH**: active + docs + commercial-backer + Discussions + hardware-distribution + WIS-released-as-separate-project. Strong signals for a hardware-software hybrid.

## Links

- Repo: <https://github.com/toverainc/willow>
- WIS: <https://github.com/toverainc/willow-inference-server>
- Docs: <https://heywillow.io>
- Tovera: <https://tovera.com>
- Rhasspy (alt): <https://rhasspy.readthedocs.io>
- Home Assistant voice: <https://www.home-assistant.io/voice_control/>
- OpenVoiceOS (alt): <https://openvoiceos.github.io>
- ESPHome voice: <https://esphome.io/components/voice_assistant.html>
- ESP32-S3-BOX hardware: <https://github.com/espressif/esp-box>

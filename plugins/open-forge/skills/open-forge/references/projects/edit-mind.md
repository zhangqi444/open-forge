---
name: EditMind
description: "AI-powered video editing automation tool. Node.js. Docker. IliasHad/edit-mind. Automatic captions, highlight clips, viral short clips, B-roll suggestions from your video content."
---

# EditMind

**AI-powered video editing automation tool.** Upload video content; EditMind automatically generates captions, identifies highlight clips, creates viral short-form clips for social media, and suggests B-roll inserts. Self-hostable alternative to expensive AI video editing SaaS tools.

Built + maintained by **IliasHad**.

- Upstream repo: <https://github.com/IliasHad/edit-mind>
- Docs: see repo README + inline documentation

## Architecture in one minute

- **Node.js** backend + web UI
- Requires external AI service connections (OpenAI / compatible LLM + transcription API)
- Docker deployment
- Resource: **medium** — Node.js + AI inference calls to external APIs

## Compatible install methods

| Infra        | Runtime                | Notes                             |
| ------------ | ---------------------- | --------------------------------- |
| **Docker**   | see repo Dockerfile    | **Primary** — build from source   |
| **Node**     | `npm install && npm run dev` | Local development              |

## Inputs to collect

| Input                    | Example                        | Phase    | Notes                                                                        |
| ------------------------ | ------------------------------ | -------- | ---------------------------------------------------------------------------- |
| OpenAI API key           | `sk-...`                       | AI       | Required for clip analysis + caption generation                              |
| Domain (optional)        | `video.example.com`            | URL      | Reverse proxy + TLS for production                                           |

## Install via Docker

```bash
git clone https://github.com/IliasHad/edit-mind.git
cd edit-mind
# Review and copy example env file (if present)
# Set OPENAI_API_KEY and any other required env vars
docker compose up -d   # if compose file exists, else: docker build -t edit-mind . && docker run ...
```

Or run locally:
```bash
npm install
# Configure .env with API keys
npm run dev
```

## First boot

1. Clone repo + configure environment variables (OpenAI API key).
2. Deploy via Docker or run with Node.
3. Visit the web UI.
4. Upload a video file.
5. Select desired automation tasks (captions, highlights, viral clips, B-roll).
6. Let AI process → download results.

## Gotchas

- **Early-stage project.** EditMind is a newer tool; expect rough edges and evolving API. Review the current README for the exact setup steps — they may have changed since this recipe was written.
- **OpenAI API costs.** Video transcription + LLM analysis of long videos can consume meaningful API credits. Monitor usage and set billing alerts in OpenAI dashboard.
- **Video processing is compute-intensive.** Even with AI APIs doing the heavy lifting, handling large video files requires adequate server RAM + disk space.
- **Check current README.** For exact Docker run steps, env variables, and feature status — refer directly to <https://github.com/IliasHad/edit-mind/blob/main/README.md>.

## Project health

Active development. Solo-maintained by IliasHad. Check GitHub for latest status.

## AI-video-editing-family comparison

- **EditMind** — Node.js, captions + highlights + viral clips + B-roll, self-hosted, OpenAI-powered
- **Whisper (OpenAI)** — transcription only; no editing; CLI
- **Descript** — SaaS, polished, expensive; the commercial reference
- **Opus Clip** — SaaS, viral clip extraction; not self-hosted
- **AutoCut** — Python, caption-based auto-cut; local model option

**Choose EditMind if:** you want a self-hosted AI video editing automation tool and are comfortable with an early-stage project using OpenAI APIs.

## Links

- Repo: <https://github.com/IliasHad/edit-mind>

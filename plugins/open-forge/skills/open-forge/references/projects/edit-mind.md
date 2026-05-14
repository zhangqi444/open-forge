---
name: EditMind
description: "Local-first video knowledge base with multi-modal AI analysis. Node.js + Python + Docker. IliasHad/edit-mind. Index videos with YOLO, DeepFace, Whisper, and ChromaDB; search semantically via natural language."
---

# EditMind

**Local-first video knowledge base.** Index your video library with multi-modal AI analysis — face recognition, transcription, object and text detection, scene analysis — then search your videos (or specific video scenes) using natural language. Runs fully locally, respects privacy, and is Docker-ready.

Built + maintained by **IliasHad**. Active development; not yet production-ready.

> **Development Status:** Currently in **active development** and **not yet production-ready**. Expect incomplete features and occasional bugs.

- Upstream repo: <https://github.com/IliasHad/edit-mind>
- Docs: see repo README + inline documentation

## Architecture

| Area | Technology |
|------|-----------|
| **Monorepo** | pnpm workspaces |
| **Containerization** | Docker, Docker Compose |
| **Web Service** | React Router V7, TypeScript, Vite |
| **Background Jobs** | Node.js, Express.js, BullMQ |
| **ML Service** | Python, PyAV, PyTorch, OpenAI Whisper, Google Gemini or Ollama |
| **Vector Database** | ChromaDB |
| **Relational DB** | PostgreSQL (via Prisma ORM) |

## Compatible install methods

| Infra        | Runtime                      | Notes                                  |
| ------------ | ---------------------------- | -------------------------------------- |
| **Docker**   | Docker Compose               | **Primary** — all services together    |
| **Desktop**  | Commercial desktop app       | macOS/Windows one-click installer (paid); Apple Silicon GPU support |
| **Node**     | `pnpm install` (dev)         | Local development                      |

## Inputs to collect

| Input                    | Example                        | Phase    | Notes                                                                     |
| ------------------------ | ------------------------------ | -------- | ------------------------------------------------------------------------- |
| Video directory          | `/path/to/videos`              | Storage  | Watched for new video files to index                                      |
| AI provider              | Google Gemini / Ollama         | AI       | NLP/semantic search backend; Gemini API key or Ollama running locally     |
| Port                     | (see compose)                  | Network  | Web UI port                                                               |

## Install via Docker

```bash
git clone https://github.com/IliasHad/edit-mind.git
cd edit-mind
# Configure .env (AI provider keys, video paths, etc.)
docker compose up -d
```

See the [Setup Video](https://www.youtube.com/watch?v=WVNuP8ic3uY) for a walkthrough.

## Core Features

- **Video Indexing:** Background service watches for new video files and queues AI-powered analysis
- **AI Analysis:** Face recognition (DeepFace), transcription (Whisper), object & text detection (YOLO), scene analysis
- **Semantic Search:** ChromaDB vector database for natural language search of video content
- **Local / Private:** All processing runs on your own hardware; no cloud required

## Gotchas

- **Not production-ready.** EditMind is under active development; expect rough edges and breaking changes.
- **AI model downloads.** First run downloads Whisper, YOLO, and other model weights — allocate disk space accordingly.
- **GPU helps.** Transcription and object detection are much faster with a GPU; CPU works but is slow for large libraries.
- **Check current README.** Tech stack and setup steps evolve quickly — refer directly to <https://github.com/IliasHad/edit-mind/blob/main/README.md> for latest instructions.
- **Desktop app (paid).** A commercial macOS/Windows desktop app with one-click install and Apple GPU support is available separately. The self-hosted Docker version is free.

## Project health

Active development. Solo-maintained by IliasHad. Pre-v1.0 alpha stage.

## Links

- Repo: <https://github.com/IliasHad/edit-mind>
- Demo video: <https://www.youtube.com/watch?v=YrVaJ33qmtg>
- Desktop app: <https://shop.edit-mind.com/>

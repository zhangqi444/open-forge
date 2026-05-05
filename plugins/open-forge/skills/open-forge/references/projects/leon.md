---
name: Leon
description: "Open-source personal AI assistant server — agentic, tool-using, locally-runnable assistant with memory, native skills, and support for local (Ollama) or cloud LLMs. Node.js. MIT."
---

# Leon

Leon is an open-source personal AI assistant designed to run on your own server. It provides an agentic execution model — it can understand goals, use tools, execute multi-step workflows, and maintain memory — with support for both local LLMs (Ollama) and cloud providers, keeping your data under your control.

Created by Louis Grenard (grenlouis). Version 2.0 is in active developer preview (February 2026) with a major architectural overhaul from the original 2019 intent-classification model.

Use cases: (a) privacy-conscious personal AI assistant on your own hardware (b) home lab AI agent with tool-using capabilities (c) developer platform for building custom AI skills and workflows (d) locally-running alternative to cloud AI assistants.

**Note:** As of early 2026, Leon v2.0 is in Developer Preview on the `develop` branch. Documentation is still catching up; the old docs largely reflect legacy architecture. For current state, see `core/context/LEON.md` and `core/context/ARCHITECTURE.md` in the repo.

Features:

- **Agentic execution** — smart mode (auto-chooses), controlled mode (deterministic native skills), agent mode (step-by-step planning)
- **Local + cloud LLMs** — Ollama (local privacy), OpenAI, Anthropic, and other providers
- **Memory** — layered memory: durable preferences, day-to-day context, recent conversation
- **Native skills** — structured `Skills → Actions → Tools → Functions` pipeline
- **Agent skills** — `SKILL.md`-backed skills for agentic workflows
- **Tool use** — real tools for task execution, not just plain text responses
- **Context awareness** — grounded in your actual environment and setup
- **Privacy-first** — runs fully locally with Ollama; no forced cloud dependency
- **Node.js** — easy to run on any machine; lightweight server

- Upstream repo: https://github.com/leon-ai/leon
- Homepage: https://getleon.ai/
- Docs: https://docs.getleon.ai/ (note: legacy docs; v2 docs in progress)
- Roadmap: https://roadmap.getleon.ai/
- Discord: https://discord.gg/MNQqqKg

## Architecture

- **Node.js** server (TypeScript)
- **TCP server** in v2.0 for communication between components
- **LLM backend** — configurable: Ollama (local) or cloud API
- **Skills** — structured directories with SKILL.md + action files
- **Memory** — file-based layered memory system
- **Web client** — browser-based chat UI

## Compatible install methods

| Infra       | Runtime             | Notes                                                        |
|-------------|---------------------|--------------------------------------------------------------|
| Local PC    | Node.js (npm)       | Primary use case; runs on your own machine                   |
| VPS/Server  | Node.js             | For always-on server deployment                              |
| Docker      | Dockerfile in repo  | Check repo for current Docker support status                 |

## Inputs to collect

| Input         | Example                       | Phase   | Notes                                                         |
|---------------|-------------------------------|---------|---------------------------------------------------------------|
| LLM provider  | Ollama / OpenAI / Anthropic   | Config  | Ollama recommended for full local operation                   |
| Ollama model  | `llama3`, `mistral`           | Config  | Any Ollama-compatible model                                   |
| API key (opt) | `OPENAI_API_KEY=...`          | Config  | Only if using cloud providers                                 |
| Port          | `1337` (default)              | Config  | Leon web UI port                                              |

## Install (develop branch — v2 preview)

```sh
# Clone develop branch for v2
git clone -b develop https://github.com/leon-ai/leon.git
cd leon

npm install
npm run setup  # or check CONTRIBUTING.md for current setup steps
npm start
```

For the stable legacy v1 (master branch):
```sh
git clone https://github.com/leon-ai/leon.git
cd leon
npm install
npm run setup
npm start
```

Open `http://localhost:1337` for the web UI.

See https://github.com/leon-ai/leon for current setup instructions — the setup process is actively changing during v2 development.

## Skills architecture

Leon skills follow a structured hierarchy:

```
Skills/
  personal-assistant/
    schedule/
      SKILL.md          # describes the skill
      index.js          # action implementation
      config/
        schema.json     # inputs schema
```

For v2 agent skills, `SKILL.md` drives agentic execution — Leon reads the skill file to understand how to use the skill, similar to OpenClaw AgentSkills.

## Gotchas

- **v2 is Developer Preview** — the `develop` branch is not stable for production use. APIs change. Documentation lags behind code. Best suited for developers willing to read the source.
- **Legacy docs don't apply to v2** — docs.getleon.ai mostly describes v1 intent-classification architecture. For v2, read `core/context/LEON.md` and `core/context/ARCHITECTURE.md` in the repo.
- **v1 (master) is stable but limited** — if you want the simpler, more documented experience, `master` branch has the original intent-based assistant. Less capable but well-documented.
- **Ollama must be running separately** — if using local LLMs, install and run Ollama independently before starting Leon. Leon calls Ollama's API; it doesn't embed Ollama.
- **Memory is file-based** — Leon's memory lives in local files. For multi-device use, sync the memory directory. No built-in cloud sync.
- **Skill ecosystem is small** — unlike commercial assistants, Leon's third-party skill ecosystem is limited. You'll likely need to write skills for your specific use cases.
- **Not a voice assistant (primarily)** — Leon focuses on text interaction. Voice input/output may be available as a feature but is not the primary interface.
- **Alternatives:** Home Assistant (home automation AI assistant), Khoj (knowledge base + web search), Open-WebUI (LLM chat frontend), Vane (AI search engine), or commercial: Siri/Alexa/Google Assistant.

## Links

- Repo: https://github.com/leon-ai/leon
- Homepage: https://getleon.ai/
- Architecture (v2): https://github.com/leon-ai/leon/blob/develop/core/context/ARCHITECTURE.md
- Leon context (v2): https://github.com/leon-ai/leon/blob/develop/core/context/LEON.md
- Roadmap: https://roadmap.getleon.ai/
- Blog: https://blog.getleon.ai/
- Discord: https://discord.gg/MNQqqKg
- Releases: https://github.com/leon-ai/leon/releases

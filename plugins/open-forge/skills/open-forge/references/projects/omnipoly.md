# OmniPoly

**What it is:** A unified web frontend for self-hosted language tools — LibreTranslate (translation), LanguageTool (grammar checking), and Ollama (AI-powered sentiment analysis and interesting sentence extraction). Provides a single interface that remembers your preferences, supports file upload/download, and only shows features for the backends you've configured.

**Official URL:** https://github.com/kWeglinski/OmniPoly
**Docker Hub:** `kweg/omnipoly:latest`
**License:** MIT
**Stack:** Static frontend; Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; add alongside LibreTranslate/LanguageTool |
| Homelab | Docker | Lightweight frontend container |

> **Prerequisites:** You need at least one backend running (LibreTranslate and/or LanguageTool). Ollama is optional for AI features. OmniPoly itself is just a frontend — it doesn't include any translation/grammar engine.

---

## Inputs to Collect

### Pre-deployment (environment variables)
- `LIBRETRANSLATE` — URL of your LibreTranslate instance (e.g. `http://libretranslate:5000`)
- `LIBRETRANSLATE_API_KEY` — API key if your instance requires one
- `LANGUAGE_TOOL` — URL of your LanguageTool instance (e.g. `http://languagetool:8010`)
- `OLLAMA` — URL of your Ollama instance (e.g. `http://ollama:11434`)
- `OLLAMA_MODEL` — Ollama model to use (e.g. `llama3.2`)

### Optional
- `THEME` — `pole` | `light` | `dark` (default: `dark`)
- `LANGUAGE_TOOL_PICKY` — `true` to enable picky mode in LanguageTool
- `LIBRETRANSLATE_LANGUAGES` — JSON array of ISO 639 codes to limit translation languages (e.g. `'["pl","en"]'`)
- `LANGUAGE_TOOL_LANGUAGES` — JSON array of lang-Region codes to limit grammar check languages (e.g. `'["pl-PL","en-GB"]'`)
- `DEFAULT_TAB` — `translate` | `language-check` | `harper` (overrides user preference)
- `DEFAULT_TARGET_LANGUAGE` — ISO 639 code for default translation target
- `DISABLE_DICTIONARY` — `true` to disable "add word to dictionary" feature
- `DEBUG` — `true` to log text sent to tools and raw responses

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  omnipoly:
    image: kweg/omnipoly:latest
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - LANGUAGE_TOOL=http://languagetool:8010
      - LANGUAGE_TOOL_PICKY=true
      - LIBRETRANSLATE=http://libretranslate:5000
      - LIBRETRANSLATE_API_KEY=your_api_key
      - OLLAMA=http://ollama:11434
      - OLLAMA_MODEL=llama3.2
      - THEME=dark
      # Optional filters:
      # - LIBRETRANSLATE_LANGUAGES='["pl","en"]'
      # - LANGUAGE_TOOL_LANGUAGES='["pl-PL","en-GB"]'
```

**Feature visibility:** Features not configured via env vars are automatically hidden in the UI — if you don't set `OLLAMA`, the AI tab won't appear. Disable specific backends by simply omitting their env vars.

**Backends to pair with:**
- LibreTranslate: `github.com/LibreTranslate/LibreTranslate`
- LanguageTool: `github.com/languagetool-org/languagetool`
- Ollama: `github.com/ollama/ollama`

**Supported features:**
- Text and file translation (upload, translate, download)
- Grammar check with error highlighting and one-click corrections
- Personal dictionary (add words to suppress false positives)
- AI sentiment analysis and interesting sentence extraction
- Auto full-display mode for short translations
- Language filters to limit dropdown options

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **Frontend only** — OmniPoly does not include LibreTranslate, LanguageTool, or Ollama; deploy those separately
- **At least one backend required** — deploying with no backends configured shows an empty UI
- **Note JSON quoting in compose** — `LIBRETRANSLATE_LANGUAGES` and `LANGUAGE_TOOL_LANGUAGES` must be quoted JSON arrays inside the env string (e.g. `'["pl","en"]'`)
- **Harper tab** — `DEFAULT_TAB=harper` references an alternative grammar backend; only set this if you know what you're using

---

## Links
- GitHub: https://github.com/kWeglinski/OmniPoly
- LibreTranslate: https://github.com/LibreTranslate/LibreTranslate
- LanguageTool: https://github.com/languagetool-org/languagetool
- Ollama: https://github.com/ollama/ollama

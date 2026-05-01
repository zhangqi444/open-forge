# RSSBox

**Self-hosted RSS feed translator and aggregator — translate RSS titles/content via DeepL or OpenAI, bilingual display, keyword/AI filtering, full-text fetching, and feed merging by tag.**
Official site: https://rssbox.app/en
GitHub: https://github.com/versun/RSSBox

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended — includes Redis |

---

## Inputs to Collect

### Required
- `SITE_URL` — public URL of your instance (e.g. `http://your-server:8000`)
- `CSRF_TRUSTED_ORIGINS` — same as `SITE_URL` (comma-separated if multiple)

### Optional (for translation)
- DeepL API key — for DeepL translation engine
- OpenAI-compatible API key + base URL — for LLM-based translation/summarization
- `DEFAULT_TARGET_LANGUAGE` — default translation target (e.g. `Chinese Simplified`, `English`)

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  rssbox:
    image: versun/rssbox
    environment:
      - SITE_URL=http://your-server:8000
      - REDIS_URL=redis://rssbox_redis:6379/0
      - CSRF_TRUSTED_ORIGINS=http://your-server:8000
      - DEFAULT_TARGET_LANGUAGE=English
      - PORT=8000
      - DEBUG=0
    volumes:
      - ./data:/app/data
    ports:
      - 8000:8000
    restart: always
    depends_on:
      - rssbox_redis

  rssbox_redis:
    image: redis:latest
    volumes:
      - ./data:/data
    restart: always
```

### Ports
- `8000` — web UI

### Key features
- Translate RSS feed titles or full content
- Bilingual display (original + translated)
- Subscribe to translated RSS or JSON output
- Per-source translation engine selection
- Cache translated content to minimize API costs
- Token/character usage tracking per source
- AI content summarization
- Full-text fetching
- Keyword filtering and AI intelligent filtering
- Combine multiple feeds into one via tags (with filters)

### Supported translation engines
- DeepL
- Any OpenAI-compatible API (GPT, local LLMs, etc.)

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- `SITE_URL` and `CSRF_TRUSTED_ORIGINS` must match the URL you use to access the app — mismatches cause CSRF errors
- Redis is required — included in the official compose file
- Translation API keys are added per-source in the UI, not in env vars

---

## References
- Documentation: https://rssbox.app/en
- GitHub: https://github.com/versun/RSSBox#readme

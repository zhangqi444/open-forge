# Investbrain

**Smart open-source investment tracker with multi-provider market data, AI chat grounded on your portfolio, and DCA/performance analytics.**
Official site: https://investbra.in
GitHub: https://github.com/investbrainapp/investbrain

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended — includes NGINX + app |

---

## Inputs to Collect

### Required
- `APP_URL` — public URL (e.g. https://invest.example.com)
- `APP_PORT` — exposed HTTP port (default: 8000)

### Market data (pick one provider)
- `MARKET_DATA_PROVIDER` — yahoo (default), twelvedata, alphavantage, alpaca, or finnhub
- Provider API key — `ALPHAVANTAGE_API_KEY`, `FINNHUB_API_KEY`, `ALPACA_API_KEY`/`ALPACA_API_SECRET`, or `TWELVEDATA_API_SECRET`
- `MARKET_DATA_REFRESH` — refresh cadence in minutes (default: 30)

### AI chat (optional)
- `AI_CHAT_ENABLED` — true/false (default: false)
- `CHAT_PROVIDER` — openai, anthropic, gemini, azure, groq, xai, deepseek, mistral, or ollama
- `CHAT_MODEL` — model name (defaults to provider's current best)
- Provider API key — `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.
- `OLLAMA_BASE_URL` — if using local Ollama (default: http://localhost:11434)

### Other
- `APP_TIMEZONE` — timezone for daily change captures (default: UTC)
- `DAILY_CHANGE_TIME` — time to capture daily change snapshot (default: 23:00)
- `REGISTRATION_ENABLED` — allow new user registration (default: true)

---

## Software-Layer Concerns

### Install
```bash
curl -O https://raw.githubusercontent.com/investbrainapp/investbrain/main/docker-compose.yml
# Edit environment variables in the compose file
docker compose up -d
# Access at http://localhost:8000/register
```

### Reference files
- Compose: https://github.com/investbrainapp/investbrain/blob/main/docker-compose.yml
- Env example: https://github.com/investbrainapp/investbrain/blob/main/.env.example

### Stack
- Laravel PHP application
- NGINX reverse proxy (included in compose)
- Built-in extensible market data provider interface with fallback chain

---

## Upgrade Procedure

```bash
docker compose stop
docker compose pull
docker compose up -d
```

---

## Gotchas

- `APP_KEY` is set automatically on first install — do not change it after data exists
- Environment changes require container restart to take effect (config is cached at runtime)
- Yahoo Finance is the default market data provider and requires no API key
- AI chat is disabled by default; enabling requires an API key for your chosen provider
- Ollama (local LLMs) is supported for AI chat via OpenAI-compatible API

---

## References
- GitHub: https://github.com/investbrainapp/investbrain#readme
- Compose file: https://github.com/investbrainapp/investbrain/blob/main/docker-compose.yml
- Env example: https://github.com/investbrainapp/investbrain/blob/main/.env.example

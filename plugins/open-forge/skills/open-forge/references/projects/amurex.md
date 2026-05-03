# Amurex

> AI-powered meeting assistant backend — transcribes meetings, extracts action items, generates summaries, and provides real-time suggestions. Pairs with a browser extension for Google Meet/Teams. Self-host the backend to keep meeting data on your infrastructure.

**Official URL:** https://github.com/thepersonalaicompany/amurex-backend  
**Browser Extension:** https://chrome.google.com/webstore/detail/amurex/dckidmhhpnfhachdpobgfbjnhfnmddmc

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | `docker build` + `docker run`; compose file included |
| Any Linux VPS/VM | Docker Compose | `docker compose up` |
| Any Linux | Python 3.11 (manual) | virtualenv + `python index.py` |

**Requires:** Supabase (cloud or self-hosted), Redis

---

## Inputs to Collect

### Phase: Pre-Deploy (Required)
| Input | Description | Example |
|-------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | `https://xyz.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anon/public API key | `eyJ...` |
| `REDIS_URL` | Redis hostname | `redis` or `localhost` |
| `REDIS_PORT` | Redis port | `6379` |
| `REDIS_USERNAME` | Redis username (if auth enabled) | `default` |
| `REDIS_PASSWORD` | Redis password | secret |
| `RESEND_API_KEY` | Resend.com API key for email notifications | `re_...` |
| `RESEND_NOREPLY` | Sender email address | `noreply@example.com` |

### Phase: LLM (choose one mode)
| Input | Description | Example |
|-------|-------------|---------|
| `CLIENT_MODE` | `ONLINE` (cloud APIs) or `LOCAL` (Ollama) | `ONLINE` |
| `OPENAI_API_KEY` | OpenAI key (ONLINE mode) | `sk-...` |
| `GROQ_API_KEY` | Groq key (ONLINE mode, optional) | `gsk_...` |
| `MISTRAL_API_KEY` | Mistral key (ONLINE mode, optional) | secret |
| `OLLAMA_ENDPOINT` | Ollama URL (LOCAL mode) | `http://ollama:11434` |

---

## Software-Layer Concerns

### Architecture
- **Backend** (this repo): Python/FastAPI server handling transcription, summaries, RAG search
- **Browser extension**: Chrome extension that captures audio from Google Meet/Teams and sends to your backend
- **Supabase**: Used for auth + data storage (meetings table, file storage bucket); can use Supabase cloud or self-hosted Supabase
- **Redis**: Used for async job queuing

### Supabase Setup
1. Create a Supabase project (cloud at supabase.com or self-hosted)
2. Run migrations from `supabase/migrations/` to create the `meetings` table
3. Create a storage bucket named `meeting_context_files`
4. Copy Project URL and anon key into your `.env`

### LOCAL Mode (Ollama)
When `CLIENT_MODE=LOCAL`:
- Install Ollama and pull a model
- Install `fastembed` for local embeddings — **comment out `fastembed==0.4.2` from `requirements.txt`** if running locally without GPU (it tries to compile CUDA bindings)
- Set `OLLAMA_ENDPOINT` to your Ollama URL

### Data Directories
No persistent volumes needed for the app itself — all data lives in Supabase + Redis.

### Ports
- FastAPI default: `8000` — configure in your compose or run args

---

## Upgrade Procedure

1. Pull latest: `docker pull` or `git pull` + rebuild
2. Check `supabase/migrations/` for new migration files and apply them to your Supabase project
3. Stop: `docker compose down`
4. Rebuild + start: `docker compose up --build -d`
5. Check logs: `docker compose logs -f`

---

## Gotchas

- **Supabase is required** — unlike most recipes, this app does not bundle its own database; you must have Supabase (cloud or self-hosted) set up first
- **fastembed on CPU** — if you're not using LOCAL mode, comment out `fastembed` from `requirements.txt` before building; it has heavy native dependencies that fail in some environments
- **Browser extension** — users need the Chrome extension installed and pointed at your backend URL; there is no built-in web UI for end users
- **Resend required** — email notifications use Resend.com's API; you need an account (free tier available) for the notification features to work
- **AGPL license** — if you modify and deploy this backend, you must publish your changes under the same license

---

## Links
- GitHub (backend): https://github.com/thepersonalaicompany/amurex-backend
- Chrome extension: https://chrome.google.com/webstore/detail/amurex/dckidmhhpnfhachdpobgfbjnhfnmddmc
- Discord: https://discord.gg/ftUdQsHWbY

# PWgen

> Self-hosted secure password and passphrase generator. Generates passwords with configurable length, character classes, and homoglyph exclusion, or passphrases from word lists (English/Finnish/French or custom). Checks generated passwords against the HaveIBeenPwned API. Runs as a single Docker container. AGPL-3.0.

**Official URL:** https://pwgen.joonatanh.com (demo)  
**GitHub:** https://github.com/jocxfin/pwgen  
**Docker Hub:** https://hub.docker.com/r/jocxfin/pwgen

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Single container; no external DB |
| Any Linux VPS/VM | Docker Compose | For compose-managed deployments |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Default |
|-------|-------------|---------|
| `NO_API_CHECK` | Disable HaveIBeenPwned check (for air-gapped/private networks) | `false` |
| `PW_LENGTH` | Default password length | `12` |
| `PP_WORD_COUNT` | Default passphrase word count | `4` |
| `MULTI_GEN` | Generate up to 5 passwords at once | `true` |

---

## Software-Layer Concerns

### Quick Start (Docker)
```bash
docker run -d \
  -p 5069:5069 \
  --name pwgen \
  --restart unless-stopped \
  jocxfin/pwgen:latest
```

Access at http://localhost:5069

### Offline / Air-Gapped Mode
```bash
docker run -d -p 5069:5069 -e NO_API_CHECK=true jocxfin/pwgen:latest
```

Disables the HaveIBeenPwned API check — all generation stays local.

### Full Configuration via Environment Variables
```bash
docker run -d -p 5069:5069 \
  -e NO_API_CHECK=false \
  -e PW_LENGTH=16 \
  -e PW_INCLUDE_UPPERCASE=true \
  -e PW_INCLUDE_DIGITS=true \
  -e PW_INCLUDE_SPECIAL=true \
  -e PW_EXCLUDE_HOMOGLYPHS=true \
  -e PP_WORD_COUNT=4 \
  -e PP_CAPITALIZE=true \
  -e PP_SEPARATOR_TYPE=dash \
  -e PP_MAX_WORD_LENGTH=12 \
  -e PP_INCLUDE_NUMBERS=false \
  -e PP_INCLUDE_SPECIAL_CHARS=false \
  -e PP_LANGUAGE=en \
  -e PP_HIDE_LANG=false \
  -e MULTI_GEN=true \
  -e GENERATE_PP=true \
  -e SHOW_SAVE_SETTINGS=true \
  -e ROBOTS_ALLOW=false \
  jocxfin/pwgen:latest
```

### Custom Word Lists
Mount a custom `.txt` word list (one word per line) and point `PP_LOCAL_WORDLIST` at it:
```bash
docker run -d -p 5069:5069 \
  -e PP_LOCAL_WORDLIST=/app/custom_wordlist.txt \
  -v /path/to/wordlist.txt:/app/custom_wordlist.txt \
  jocxfin/pwgen:latest
```

Custom URL word lists are also supported via `PP_LANGUAGE_CUSTOM` (must start with `https://raw.githubusercontent.com/` and be a `.txt` file by default; disable URL validation with `DISABLE_URL_CHECK=true`).

### Ports
- Default: `5069` — reverse-proxy with Nginx/Caddy for TLS if exposing publicly

---

## Upgrade Procedure

1. Pull latest: `docker pull jocxfin/pwgen:latest`
2. Stop and remove: `docker stop pwgen && docker rm pwgen`
3. Re-run with the same flags (stateless — no persistent data to migrate)

---

## Gotchas

- **Stateless** — no database; all settings are ephemeral or stored in a browser cookie (when `SHOW_SAVE_SETTINGS=true`). Re-deploying loses nothing server-side
- **HaveIBeenPwned check is k-anonymity** — only the first 5 chars of the SHA-1 hash are sent; the full password never leaves the browser/server. Still, set `NO_API_CHECK=true` on isolated networks where outbound HTTPS is blocked
- **`PP_SEPARATOR_TYPE` options** — valid values: `space`, `dash`, `number`, `special`, `custom` (use `PP_USER_DEFINED_SEPARATOR` for custom)
- **`BASE_PATH`** — set this if deploying under a sub-path (e.g. `/tools/pwgen`); leave empty for root

---

## Links
- GitHub: https://github.com/jocxfin/pwgen
- Docker Hub: https://hub.docker.com/r/jocxfin/pwgen
- Live demo: https://pwgen.joonatanh.com

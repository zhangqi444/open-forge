# HitKeep

**Privacy-first web analytics in a single binary** — Go-based analytics platform with embedded DuckDB and NSQ. No PostgreSQL, Redis, or ClickHouse required. Covers traffic, goals, funnels, ecommerce, UTM attribution, Search Console import, and AI-era crawler/LLM referral analytics. Cookie-less by default.

**Official site:** https://hitkeep.com
**Source:** https://github.com/pascalebeier/hitkeep
**License:** MIT
**Demo:** https://demo.hitkeep.com/share/7a55968bb42df256512fbe7ff73ab88f29dd45c236eddc818bd66420b4ffbaad

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Single binary | Download and run; no external dependencies |
| Any VPS / bare metal | Docker Compose | Official Docker image available |
| Kubernetes | Helm / manifest | Supported; see docs |

---

## Inputs to Collect

### Phase 1 — Planning
- Public URL for the HitKeep instance
- Whether to use binary or Docker deployment
- Storage path for embedded DuckDB data

### Phase 2 — Deploy
- `HITKEEP_JWT_SECRET` — long random string for JWT signing (`openssl rand -base64 48`)
- `-public-url` flag — full public URL (e.g. `https://analytics.example.com`)
- SMTP config (optional, for email reports and invitations)

---

## Software-Layer Concerns

- **Single binary:** Embeds DuckDB (OLAP database) and NSQ (message queue); no external services needed
- **Cookie-less tracking:** Default tracking script uses no cookies; Do Not Track header respected
- **Tracking script:** Add `<script src="https://your-instance/tracker.js" defer></script>` to tracked sites
- **Reports:** Traffic, events, goals, funnels, ecommerce, UTM, email reports, Search Console aggregates
- **AI analytics:** Tracks crawler fetches and LLM-referred visits (AI visibility reporting)
- **Auth:** Passkeys, TOTP 2FA, site/team permissions, share links, audit logs, API clients
- **MCP server:** Read-only MCP analytics server for AI agent access
- **Data dir:** `/var/lib/hitkeep/data` (Docker) or configured path (binary)

---

## Deployment

```bash
# Binary (fastest start)
wget https://github.com/PascaleBeier/hitkeep/releases/latest/download/hitkeep-linux-amd64
chmod +x hitkeep-linux-amd64
export HITKEEP_JWT_SECRET="$(openssl rand -base64 48)"
./hitkeep-linux-amd64 -public-url="https://analytics.example.com"
# Visit https://analytics.example.com and create your first account
```

```yaml
# docker-compose.yml
services:
  hitkeep:
    image: pascalebeier/hitkeep:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - hitkeep_data:/var/lib/hitkeep/data
    environment:
      HITKEEP_JWT_SECRET: replace-with-long-random-string
    command:
      - "-public-url=https://analytics.example.com"

volumes:
  hitkeep_data: {}
```

Full installation guides: https://hitkeep.com/guides/installation/

---

## Upgrade Procedure

```bash
# Binary: download new release binary, replace, restart
# Docker:
docker compose pull
docker compose up -d
```

---

## Gotchas

- **`HITKEEP_JWT_SECRET` is mandatory** — server won't start without it; use a long random string
- **`-public-url` must match your domain** — used in tracking script URLs and email links; wrong value breaks tracking
- **DuckDB data volume must persist** — losing `/var/lib/hitkeep/data` means losing all analytics data
- **Very new project** — first commits in Feb 2026; actively developed but may have rough edges; current release is a snapshot
- **S3 archiving available** — for long-term data archiving beyond the local DuckDB store; see docs

---

## Links

- Upstream README: https://github.com/pascalebeier/hitkeep#readme
- Documentation: https://hitkeep.com/guides/introduction/
- Installation guides: https://hitkeep.com/guides/installation/
- API docs: https://hitkeep.com/api/
- Demo: https://demo.hitkeep.com/share/7a55968bb42df256512fbe7ff73ab88f29dd45c236eddc818bd66420b4ffbaad

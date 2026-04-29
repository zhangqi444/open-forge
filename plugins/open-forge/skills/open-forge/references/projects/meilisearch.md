---
name: meilisearch-project
description: Meilisearch recipe for open-forge. MIT-licensed Rust search engine with hybrid (semantic + full-text) search, typo tolerance, faceted search, and sub-50ms queries. Covers upstream-blessed install paths — cURL installer, Homebrew (macOS), APT (Debian/Ubuntu), Docker (`getmeili/meilisearch`), and build-from-source. Includes the canonical production hardening (master key, HTTPS at the edge, systemd unit).
---

# Meilisearch

MIT-licensed Rust search engine. Fast full-text search with built-in hybrid semantic search, typo tolerance, faceting, geo, tenant tokens. Upstream: <https://github.com/meilisearch/meilisearch>. Docs: <https://www.meilisearch.com/docs>.

Single binary; uses LMDB under the hood for the index. Default port `:7700`. Configured via env vars (preferred) or CLI flags.

**Open-core context.** Meilisearch itself is 100% MIT — no feature is paywalled in the OSS build. Meilisearch Cloud is the company's paid hosted offering; the only thing it adds over self-host is managed infra + Meilisearch Cloud AI (the embedding providers layer). Conversational search / vector search / replication are in the OSS binary.

## Compatible install methods

All five methods below are upstream-documented at <https://www.meilisearch.com/docs/learn/self_hosted/install_meilisearch_locally>:

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| cURL installer | <https://install.meilisearch.com> | ✅ | Download latest stable binary. Good for dev / one-off. |
| Homebrew (macOS) | `brew install meilisearch` | ✅ | macOS dev. |
| APT (Debian/Ubuntu) | <https://www.meilisearch.com/docs/learn/self_hosted/install_meilisearch_locally#apt> | ✅ | Production Linux install with systemd. |
| Docker | <https://hub.docker.com/r/getmeili/meilisearch> | ✅ | The most common production shape on selfh.st stacks. |
| Build from source | `cargo build --release` | ✅ | Custom Rust builds / contributors. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method? (curl / brew / apt / docker / source)" | `AskUserQuestion` | Drives section. |
| platform | "Target OS + arch?" | Free-text (Linux glibc 2.35+ amd64/arm64, macOS 14+, Windows Server 2022+) | Per upstream's supported-OS matrix. |
| secrets | "Master key?" | Free-text (sensitive, ≥16 bytes) | **MANDATORY** for production. Sets `MEILI_MASTER_KEY`. Without it, Meilisearch runs in unprotected mode with a big warning banner. |
| env | "`MEILI_ENV` = `production` or `development`?" | `AskUserQuestion` | `production` disables the web dashboard at `/` and enforces the master-key requirement. |
| dns | "Public domain?" | Free-text | For reverse-proxy + TLS. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | Meilisearch does not terminate TLS itself in production. |
| storage | "Data dir?" | Free-text, default `/var/lib/meilisearch/data.ms` | Passed as `--db-path` / `MEILI_DB_PATH`. |

## Install — cURL (one-liner)

```bash
# Download the latest stable binary into $PWD
curl -L https://install.meilisearch.com | sh

# Launch (dev mode, no master key — banner will warn loudly)
./meilisearch

# Production — set master key + env
./meilisearch \
  --master-key="$(openssl rand -hex 32)" \
  --env production \
  --db-path /var/lib/meilisearch/data.ms \
  --http-addr 0.0.0.0:7700
```

## Install — Homebrew (macOS)

```bash
brew update && brew install meilisearch
meilisearch --master-key="$(openssl rand -hex 32)" --env production
```

LaunchAgent/brew-services support is not officially documented — upstream recommends the binary + systemd approach on Linux servers.

## Install — APT (Debian/Ubuntu — production)

```bash
# 1. Add Meilisearch's APT repo
echo "deb [trusted=yes] https://apt.fury.io/meilisearch/ /" | sudo tee /etc/apt/sources.list.d/fury.list
sudo apt-get update
sudo apt-get install -y meilisearch

# 2. Generate master key
MASTER_KEY=$(openssl rand -hex 32)

# 3. Create config file
sudo mkdir -p /etc/meilisearch /var/lib/meilisearch
sudo tee /etc/meilisearch/config.toml > /dev/null <<EOF
db_path = "/var/lib/meilisearch/data.ms"
env = "production"
http_addr = "127.0.0.1:7700"
master_key = "${MASTER_KEY}"
no_analytics = true
EOF

# 4. Systemd unit
sudo useradd --system --no-create-home --shell /usr/sbin/nologin meilisearch || true
sudo chown -R meilisearch:meilisearch /var/lib/meilisearch /etc/meilisearch

sudo tee /etc/systemd/system/meilisearch.service > /dev/null <<'EOF'
[Unit]
Description=Meilisearch
After=network.target

[Service]
Type=simple
User=meilisearch
Group=meilisearch
ExecStart=/usr/bin/meilisearch --config-file-path /etc/meilisearch/config.toml
Restart=always
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now meilisearch
sudo systemctl status meilisearch
sudo journalctl -u meilisearch -f
```

Save the master key somewhere durable — you'll need it for every API call.

## Install — Docker

```yaml
# compose.yaml
services:
  meilisearch:
    image: getmeili/meilisearch:v1.16   # pin a specific tag; `latest` drifts
    container_name: meilisearch
    restart: unless-stopped
    ports:
      - "7700:7700"
    environment:
      MEILI_MASTER_KEY: ${MEILI_MASTER_KEY}
      MEILI_ENV: production
      MEILI_NO_ANALYTICS: "true"
    volumes:
      - ./meili_data:/meili_data
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--spider", "http://localhost:7700/health"]
      interval: 30s
      timeout: 5s
      retries: 3
```

```bash
echo "MEILI_MASTER_KEY=$(openssl rand -hex 32)" > .env
docker compose up -d
curl -H "Authorization: Bearer $(grep MASTER_KEY .env | cut -d= -f2)" \
  http://localhost:7700/version
```

### Tag pinning

Upstream releases versions as `v1.15`, `v1.15.1`, `v1.16`, etc. **Don't use `latest`** — major / minor bumps can require re-indexing, and you want to opt in deliberately.

## Install — Build from source

```bash
# Rust 1.89+ (per upstream Dockerfile)
curl https://sh.rustup.rs -sSf | sh
git clone https://github.com/meilisearch/meilisearch.git
cd meilisearch
cargo build --release -p meilisearch
./target/release/meilisearch --help
```

## Reverse proxy (Caddy example)

```caddy
search.example.com {
    reverse_proxy 127.0.0.1:7700
}
```

## First-use smoke test

```bash
MASTER_KEY="<your-key>"
BASE=http://localhost:7700

# Health
curl -s "${BASE}/health"

# Create an index + add docs
curl -s -X POST "${BASE}/indexes" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"uid":"movies","primaryKey":"id"}'

curl -s -X POST "${BASE}/indexes/movies/documents" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d '[{"id":1,"title":"The Matrix"},{"id":2,"title":"Inception"}]'

# Search (async — wait ~1s for indexing)
sleep 2
curl -s "${BASE}/indexes/movies/search?q=matrix" \
  -H "Authorization: Bearer ${MASTER_KEY}"
```

## API key model

Master key = admin god-key. **Never embed it in a client.** Generate scoped API keys for actual usage:

```bash
# Derive default keys (default admin key + default search key) — already created
curl -s "${BASE}/keys" -H "Authorization: Bearer ${MASTER_KEY}"

# Create a scoped search-only key for a specific index
curl -s -X POST "${BASE}/keys" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"name":"movies-search","actions":["search"],"indexes":["movies"],"expiresAt":null}'
```

Client code uses the scoped key; master stays on the server / secrets manager.

## Data layout

| Path (Linux native) | Path (Docker) | Content |
|---|---|---|
| `/var/lib/meilisearch/data.ms/` | `/meili_data/data.ms/` | LMDB index. Backups = snapshot this dir while the server is stopped, OR use Meilisearch's snapshot/dumps API. |
| `/etc/meilisearch/config.toml` | (env vars in compose) | Config. |

**Backup via dumps API** (safe while running):

```bash
curl -X POST "${BASE}/dumps" -H "Authorization: Bearer ${MASTER_KEY}"
# → taskUid; poll /tasks/<uid> for status. Dumps land in <db-path>/dumps/
```

Restore on a new instance: `meilisearch --import-dump path/to/dump.dump`.

## Upgrade procedure

```bash
# 1. Back up
curl -X POST "${BASE}/dumps" -H "Authorization: Bearer ${MASTER_KEY}"

# 2. Read release notes — major/minor bumps sometimes require re-indexing
# https://github.com/meilisearch/meilisearch/releases

# 3. APT: sudo apt-get update && sudo apt-get install --only-upgrade meilisearch
#    Docker: bump image tag + docker compose pull + up -d
#    Binary: redownload from install.meilisearch.com

# 4. Start + check version
sudo systemctl restart meilisearch  # or docker compose up -d
curl -s "${BASE}/version" -H "Authorization: Bearer ${MASTER_KEY}"
```

If a version bump requires index migration (rare but happens), upstream's release notes say "import a dump of your old index." The upgrade is: dump on old version → install new version on fresh data dir → `--import-dump`.

## Gotchas

- **No master key = no security.** Without `MEILI_MASTER_KEY`, Meilisearch runs wide open and anyone on the network can read/write every index. Always set a master key.
- **`MEILI_ENV=development` exposes a web dashboard at `/`.** The dashboard uses the master key directly. Fine for local dev; disable (`MEILI_ENV=production`) before exposing the service.
- **No built-in TLS.** Terminate at a reverse proxy (Caddy / nginx / Traefik). Upstream's docs explicitly recommend this.
- **LMDB file size grows, doesn't shrink.** Meilisearch maps a big sparse file for the LMDB env. `du -sh` shows a lot of disk; the actual used portion is much smaller. To shrink: dump → fresh instance → restore.
- **`latest` tag drift.** On Docker, pin an explicit tag (`v1.16`). Upstream pushes `latest` on every release; auto-updaters like Watchtower can bring in a breaking version.
- **Analytics opt-out.** By default Meilisearch phones home anonymous usage stats. Set `MEILI_NO_ANALYTICS=true` (or `no_analytics = true` in config.toml) to disable.
- **glibc 2.35+ requirement on Linux.** Verify with `ldd --version`. Ubuntu 22.04+ / Debian 12+ are fine. Older distros need the Docker install or a statically-linked custom build.
- **Dump/snapshot distinction.** A *dump* is a cross-version portable backup (slow, big, resumable). A *snapshot* is a fast binary copy of the LMDB (same-version only). Use dumps for long-term backups.
- **Semantic search needs an embedder config.** Hybrid search works out-of-box only after you configure an embedder (`settings/embedders`). Options: Meilisearch Cloud AI, OpenAI, HuggingFace, Ollama, or a user-provided vector.
- **Rate limiting is on you.** Meilisearch has no built-in rate limit. Put it behind a reverse proxy that enforces per-key limits if you expose it publicly.

## Links

- Upstream repo: <https://github.com/meilisearch/meilisearch>
- Docs site: <https://www.meilisearch.com/docs>
- Install docs: <https://www.meilisearch.com/docs/learn/self_hosted/install_meilisearch_locally>
- Production checklist: <https://www.meilisearch.com/docs/learn/self_hosted/configure_meilisearch_at_launch>
- Security / API keys: <https://www.meilisearch.com/docs/learn/security/master_api_keys>
- Docker image: <https://hub.docker.com/r/getmeili/meilisearch>
- Releases: <https://github.com/meilisearch/meilisearch/releases>

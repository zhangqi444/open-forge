# Storyteller

**What it is:** A self-hosted platform for creating and reading eBooks with synced narration. Feed it an audiobook and an ebook you already own — Storyteller's forced-alignment algorithm automatically synchronizes them so you can read and listen simultaneously. Includes a web interface and iOS/Android mobile apps.

**Official URL:** https://gitlab.com/storyteller-platform/storyteller
**Docs:** https://storyteller-platform.gitlab.io/storyteller/
**Registry:** `registry.gitlab.com/storyteller-platform/storyteller:latest`
**License:** AGPLv3
**Stack:** TypeScript/Node.js monorepo (API + web + mobile); optional CUDA GPU acceleration

> ⚠️ **Security notice:** Versions before 2.3.21 are affected by CVE-2025-66478 (critical Next.js vulnerability). Upgrade to 2.3.21+ immediately if running an older version.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| GPU server | Docker Compose + NVIDIA runtime | Speeds up alignment significantly |
| macOS / Windows | Docker Compose (named volumes) | Use named volumes for better I/O performance |
| NixOS | Nix flake | `flake.nix` included in repo |

---

## Inputs to Collect

### Pre-deployment
- `STORYTELLER_SECRET_KEY` — cryptographically random string; store in a file for Docker secrets
  ```bash
  openssl rand -base64 32 > STORYTELLER_SECRET_KEY.txt
  ```
- Data directory — where your books and library will live (e.g. `~/Documents/Storyteller`)
- NVIDIA runtime (optional) — for GPU-accelerated alignment

### Runtime
- Upload via web UI: provide both the audiobook file and the ebook file
- Storyteller handles alignment automatically (no manual timestamps needed)

---

## Software-Layer Concerns

**Docker Compose quick start:**
```bash
git clone https://gitlab.com/storyteller-platform/storyteller.git
cd storyteller
openssl rand -base64 32 > STORYTELLER_SECRET_KEY.txt
docker compose up -d
```

**`compose.yaml`:**
```yaml
services:
  web:
    image: registry.gitlab.com/storyteller-platform/storyteller:latest
    # Uncomment for CUDA GPU acceleration:
    # runtime: nvidia
    volumes:
      - ~/Documents/Storyteller:/data:rw
    environment:
      - STORYTELLER_SECRET_KEY_FILE=/run/secrets/secret_key
    ports:
      - "8001:8001"
    secrets:
      - secret_key

secrets:
  secret_key:
    file: ./STORYTELLER_SECRET_KEY.txt
```

**Default port:** `8001`

**Data directory:** All books, metadata, and processed audio stored at the mount point (default: `~/Documents/Storyteller`). Back this up — it contains your entire library.

**macOS/Windows performance:** Use a named Docker volume instead of a bind mount for significantly better filesystem I/O.

**GPU acceleration (CUDA):** Uncomment `runtime: nvidia` in `compose.yaml`; requires NVIDIA Container Toolkit installed on host.

**Password reset:**
```bash
docker exec -it <container> /docker-scripts/reset-password.sh
```

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`
3. Check release notes at https://gitlab.com/storyteller-platform/storyteller/-/releases for migration steps

---

## Gotchas

- **CVE-2025-66478** — versions before 2.3.21 have a critical Next.js vulnerability; upgrade immediately
- **Alignment is CPU/GPU-intensive** — processing a full audiobook can take minutes to hours on CPU; GPU dramatically reduces this
- **You must provide both files** — Storyteller needs an audiobook (MP3/M4B/etc.) AND an ebook (EPUB) you already own; it does not fetch or download content
- **AGPL-3.0** — modifications must be open-sourced if deployed publicly
- **Mobile apps available** — iOS and Android apps connect to your self-hosted instance
- **Named volumes recommended on macOS/Windows** — bind mounts have poor I/O on non-Linux hosts; see VS Code devcontainer docs for details
- **Single container** — API + web UI are combined; no separate database container needed

---

## Links
- GitLab: https://gitlab.com/storyteller-platform/storyteller
- Docs: https://storyteller-platform.gitlab.io/storyteller/
- Releases: https://gitlab.com/storyteller-platform/storyteller/-/releases
- Discord: https://discord.gg/KhSvFqcrza
- How the algorithm works: https://storyteller-platform.gitlab.io/storyteller/docs/how-it-works/the-algorithm

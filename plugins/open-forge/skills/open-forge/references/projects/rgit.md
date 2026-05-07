# rgit

**Ultra-fast Git repository browser** — a cgit/gitweb clone written in Rust. Uses RocksDB for metadata caching and gitoxide for on-demand file loading. Supports dark mode. Works exclusively with bare Git repositories.

**Official site / demo:** https://git.inept.dev  
**Source:** https://github.com/w4/rgit  
**License:** WTFPL

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker | Primary recommended path |
| Linux | Cargo binary | Build from source or `cargo install` |
| NixOS | NixOS module | First-class NixOS support |

---

## Requirements

- Bare Git repositories (rgit does not work with non-bare repos)
- Docker, or Rust toolchain (for native install)

---

## Inputs to Collect

### Provision phase
| Input | Description | Default |
|-------|-------------|---------|
| `REPO_PATH` | Path to directory containing bare git repositories | — |
| `BIND_ADDRESS` | Address and port to listen on | `[::]:3333` |
| `DB_PATH` | Path for RocksDB metadata cache | `/tmp/rgit-cache.db` |
| `REFRESH_INTERVAL` | How often to re-index repositories | `5m` |

---

## Software-layer Concerns

### Quick Start (Docker Compose)
```yaml
services:
  rgit:
    image: ghcr.io/w4/rgit:main
    command:
      - "[::]:8000"
      - /git
      - -d /tmp/rgit-cache.db
    volumes:
      - /path/to/bare-repos:/git:ro
    ports:
      - 8000:8000
    environment:
      - REFRESH_INTERVAL=5m
    restart: unless-stopped
```

Access at `http://localhost:8000`.

### Native install
```bash
# Install via Cargo
cargo install --git https://github.com/w4/rgit

# Run
rgit [::]:3333 /path/to/my-bare-repos -d /tmp/rgit-cache.db
```

### NixOS module
```nix
services.rgit = {
  enable = true;
  bindAddress = "[::]:3333";
  dbStorePath = "/tmp/rgit.db";
  repositoryStorePath = "/path/to/my-bare-repos";
};
```

### Repository metadata
Configure per-repo metadata inside the bare repository:

**Description** — edit the `description` file inside the bare repo:
```
echo "My project description" > /path/to/repo.git/description
```

**Owner** — edit `config` inside the bare repo:
```ini
[gitweb]
    owner = "Your Name"
```

### Linux permissions
If Docker reports "is not owned by the current user":
```yaml
# docker-compose.override.yml
services:
  rgit:
    user: "1000:1000"  # UID:GID matching the repo directory owner
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```
RocksDB cache rebuilds automatically on restart. The first index after upgrade may take slightly longer.

---

## Gotchas

- **Bare repos only.** rgit will not display non-bare repositories. Create bare repos with `git init --bare` or `git clone --bare`.
- **Exported repos only.** By default Git bare repos are not "exported". Create a `git-daemon-export-ok` file in each repo: `touch /path/to/repo.git/git-daemon-export-ok`.
- **New repos take up to `REFRESH_INTERVAL` to appear.** Default is 5 minutes. Reduce the interval or restart the container to index immediately.
- **DB path in Docker.** The default cache DB at `/tmp/rgit-cache.db` is ephemeral. Mount a volume if you want to preserve the cache across restarts (speeds up initial load).
- **Read-only.** rgit is a viewer only — no push/pull via HTTP. Combine with Gitea, Forgejo, or `git-http-backend` for write access.

---

## References

- Upstream README: https://github.com/w4/rgit#readme

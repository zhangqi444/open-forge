# minimal-git-server

**Lightweight containerized git server with CLI management** — Docker/Podman container running a minimal SSH-based git server. Configured via a single `config.yml` file defining accounts and SSH public keys. Includes a CLI for repository management (list, create, rename, remove) that's easy to embed in scripts.

**Official site:** https://github.com/mcarbonne/minimal-git-server
**Source:** https://github.com/mcarbonne/minimal-git-server
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker | Primary supported path |
| Any VPS / bare metal | Podman | Also tested and supported |

---

## Inputs to Collect

### Phase 1 — Planning
- Port to expose SSH on (default example: 20222)
- User accounts and their SSH public keys

### Phase 2 — Deploy
- `config.yml` — accounts with usernames, UIDs, and SSH public keys
- `external_hostname` and `external_port` — for git clone URL display

---

## Software-Layer Concerns

- **Config file:** Single `config.yml` defines all accounts, UIDs, and authorized public keys
- **Three required volumes:**
  - `/srv/ssh` — persists generated server SSH host keys
  - `/srv/git` — stores all git repositories
  - `/srv/config.yml` — mounted read-only; account/key configuration
- **CLI via SSH:** Manage repos by SSHing in with a special command syntax: `ssh ACCOUNT@HOSTNAME -p PORT create project/repo`
- **No web UI** — pure SSH-based access; no browser interface

---

## Deployment

```yaml
# docker-compose.yml
services:
  git-server:
    image: ghcr.io/mcarbonne/minimal-git-server:2
    restart: unless-stopped
    ports:
      - "20222:22"
    volumes:
      - ./ssh:/srv/ssh
      - ./git:/srv/git
      - ./config.yml:/srv/config.yml:ro
```

```yaml
# config.yml
external_hostname: git.example.com
external_port: 20222
accounts:
  - user: alice
    uid: 1001
    keys:
      - "ssh-ed25519 AAAA... alice@laptop"
  - user: bob
    uid: 1002
    keys:
      - "ssh-rsa AAAA... bob@desktop"
```

```bash
# Create a repository
ssh alice@git.example.com -p 20222 create myproject/myrepo

# Clone it
git clone ssh://alice@git.example.com:20222/myproject/myrepo
```

---

## Upgrade Procedure

Use a pinned major tag (e.g. `:2`) for stability and auto-updates via Watchtower or podman-auto-update:
```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **Use major version tag** (`:2`) not `:latest` for auto-updates to avoid breaking changes across major versions
- **UIDs must be unique** across accounts — duplicate UIDs cause permission issues
- **No web interface** — if you need a web UI (browse code, issues, PRs), use Gitea or Forgejo instead; this is purely SSH git hosting
- **`/srv/ssh` volume must persist** — losing it regenerates host keys, which will cause "host key changed" warnings for all users
- **Read-only config mount** — `config.yml` is mounted `:ro`; edit on the host and restart the container to apply changes

---

## Links

- Upstream README: https://github.com/mcarbonne/minimal-git-server#readme
- GitHub Container Registry: ghcr.io/mcarbonne/minimal-git-server

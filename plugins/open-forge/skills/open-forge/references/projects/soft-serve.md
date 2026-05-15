---
name: Soft Serve
description: "Tasty self-hostable Git server by Charm with a TUI over SSH. Clone over SSH/HTTP/Git, Git LFS, create repos via `git push`, public/private repos, collaborator access via SSH keys, user access tokens. Single Go binary. MIT."
---

# Soft Serve

Soft Serve is **the Git server by [Charm](https://charm.sh)** — the people behind `bubbletea`, `lipgloss`, and a lot of beautifully-designed terminal UIs. Single Go binary (`soft`). You run `soft serve`, it creates a `data/` directory, listens on SSH, HTTP, and Git protocols, and you have a Git server.

The standout feature: **an SSH-native TUI** for browsing the server. Run `ssh yourhost` and you get a repo-list UI, with commit browser, file tree, syntax-highlighted diffs, all rendered via Charm's terminal styling libs.

Features:

- **Clone over SSH / HTTP / Git protocol** — all three
- **Git LFS** — both HTTP and SSH backends
- **SSH-accessible TUI** — navigate repos + files + commits without opening a browser
- **Create repos on demand** — either in the UI or via `git push` to a new repo path
- **Access control via SSH public keys**
  - Anonymous (read-only or disabled)
  - Collaborators (SSH keys granted access)
  - Public vs private repos
  - User access tokens (for HTTPS clone auth)
- **Web UI** — read-only, browse repos/commits/tree (if enabled)
- **SSH-accessible CLI** — `ssh yourhost repo list`, `ssh yourhost repo tree repo-name`, etc.
- **Webhooks** — basic HTTP webhooks on push
- **Print file over SSH with syntax highlighting** — `ssh yourhost repo blob repo-name path/to/file.go -c -l`
- **Single binary** — ~15 MB; no database; SQLite internal

Not for: full GitHub replacement. No PRs, no issues, no actions. It's a pure Git hosting server with a delightful CLI UX.

- Upstream repo: <https://github.com/charmbracelet/soft-serve>
- Charm: <https://charm.sh>
- Docker: <https://github.com/charmbracelet/soft-serve/blob/main/docker.md>
- Nightly: <https://nightly.link/charmbracelet/soft-serve/workflows/nightly/main>

## Architecture in one minute

- **Single Go binary** (`soft`)
- **SSH server** on port 23231 (default) — hosts TUI + Git access
- **HTTP server** on port 23232 — Git HTTP + optional web UI
- **Git protocol** on port 9418 — traditional `git://`
- **Data dir** — holds SQLite DB (users, repos metadata, access), SSH host keys, and bare repos
- **Config** — either env vars (`SOFT_SERVE_*`) or a YAML in data dir

## Compatible install methods

| Infra        | Runtime                                    | Notes                                                           |
| ------------ | ------------------------------------------ | --------------------------------------------------------------- |
| Single VM    | **Native binary** (Homebrew / apt / yum / nix / winget) | **Upstream-preferred**                                              |
| Single VM    | **Docker** official image                                 | Also good                                                                   |
| Raspberry Pi | arm64 binary                                                     | Homelab Git hosting — excellent fit                                                  |
| Kubernetes   | Deploy Docker image + PVC                                              | Works; single replica                                                                       |
| Managed      | — (no SaaS; Charm is just the author)                                             |                                                                                                     |

## Inputs to collect

| Input            | Example                                | Phase      | Notes                                                                    |
| ---------------- | -------------------------------------- | ---------- | ------------------------------------------------------------------------ |
| Host / domain    | `git.example.com`                          | DNS        | SSH + HTTP hostnames                                                             |
| SSH port         | 23231 (default) or 22                          | Network    | 22 if Soft Serve is the only SSH on the host                                                    |
| Admin SSH key    | your public key                                       | Bootstrap  | Set `SOFT_SERVE_INITIAL_ADMIN_KEYS` on first boot                                                         |
| Data dir         | `/var/lib/soft-serve`                                        | Storage    | All state                                                                                                     |
| HTTP public URL  | `https://git.example.com/git`                                       | URL        | For HTTPS clone URLs                                                                                                  |
| Allow register   | anonymous create-on-push                                                 | Config     | Enable/disable per `allow-keyless`                                                                                                |

## Install (native)

```sh
# macOS / Linux via Homebrew
brew install charmbracelet/tap/soft-serve

# Debian/Ubuntu
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install soft-serve

# Just run it
SOFT_SERVE_INITIAL_ADMIN_KEYS="$(cat ~/.ssh/id_ed25519.pub)" \
SOFT_SERVE_DATA_PATH=/var/lib/soft-serve \
soft serve
```

Systemd unit (simplified):
```ini
[Unit]
Description=Soft Serve Git Server
After=network.target

[Service]
Type=simple
User=git
Environment="SOFT_SERVE_DATA_PATH=/var/lib/soft-serve"
Environment="SOFT_SERVE_INITIAL_ADMIN_KEYS=ssh-ed25519 AAAA... admin"
ExecStart=/usr/bin/soft serve
Restart=always

[Install]
WantedBy=multi-user.target
```

## Install (Docker)

```yaml
services:
  soft-serve:
    image: charmcli/soft-serve:v0.11.6         # pin minor
    container_name: soft-serve
    restart: unless-stopped
    environment:
      SOFT_SERVE_INITIAL_ADMIN_KEYS: "ssh-ed25519 AAAA... admin"
      SOFT_SERVE_HTTP_PUBLIC_URL: "https://git.example.com"
      SOFT_SERVE_SSH_PUBLIC_URL: "ssh://git.example.com:23231"
    volumes:
      - ./data:/soft-serve
    ports:
      - "23231:23231"      # SSH
      - "23232:23232"      # HTTP
      - "9418:9418"        # Git protocol (optional)
```

## First boot

1. Start server; admin key from `SOFT_SERVE_INITIAL_ADMIN_KEYS` auto-granted admin
2. SSH to the server: `ssh -p 23231 git.example.com` → TUI opens
3. Settings: `ssh -p 23231 git.example.com settings set anon-access read-only` (for public-read repos)
4. Create a repo:
   ```sh
   # Either from TUI, or via git push:
   cd my-project
   git remote add origin ssh://git@git.example.com:23231/my-project
   git push -u origin main
   # Soft Serve creates the repo on first push (if allowed)
   ```
5. Add collaborator:
   ```sh
   ssh -p 23231 git.example.com repo collab add my-project alice 'ssh-ed25519 AAAA...'
   ```

## Data & config layout

- `$SOFT_SERVE_DATA_PATH/` (default: `./data/`)
  - `soft-serve.db` — SQLite (users, repos, access tokens, config)
  - `ssh_host_*_key` — SSH host keys (persist across restarts)
  - `repos/` — bare `.git` directories
  - `config.yaml` — generated on first run (or skip and use env vars)
  - `lfs/` — Git LFS objects

## Backup

```sh
sudo systemctl stop soft-serve
tar czf soft-serve-$(date +%F).tgz /var/lib/soft-serve/
sudo systemctl start soft-serve
```

Bare Git repos + DB + LFS objects. All recoverable via tar.

## Upgrade

1. Releases: <https://github.com/charmbracelet/soft-serve/releases>. Active; `0.x` series.
2. Back up data dir.
3. Native: replace `soft` binary → restart.
4. Docker: bump tag → restart.
5. Pre-1.0: expect schema + config changes; read release notes.

## Gotchas

- **Pre-1.0 software.** `0.x` API + config format can change. Pin versions + read release notes before upgrading.
- **No PRs / issues / wiki** — this is a Git hosting server, not a full forge. For workflow features, pair with Gitea/Forgejo or external tools (code review via patches? use `git format-patch` + email).
- **SSH host key drift** — back up `ssh_host_*_key` files; otherwise clients will hit "REMOTE HOST IDENTIFICATION HAS CHANGED" after re-init.
- **Port 22 vs 23231** — if you want native `git@host:repo.git` URLs (without a port), run Soft Serve on 22; that requires moving your OS SSH daemon to another port. Many people leave Soft Serve on 23231 and use `ssh://` URLs or `~/.ssh/config` Host entry.
- **`~/.ssh/config` entry** is recommended for users:
  ```
  Host git.example.com
    Port 23231
    User git
  ```
- **Anonymous access** — default is `read-only`; set to `no-access` for private-only instances. `read-write` for fully-open homelab usage.
- **Create-on-push** — controlled by `allow-keyless`; enable for "push to create" ergonomics.
- **Access tokens** — for HTTPS clones without password prompt; create per-user.
- **Git LFS** — works over both HTTP and SSH; storage grows — rotate if needed.
- **Webhook** signing — basic HMAC support; verify in your receiver.
- **No mirror feature** — for bidirectional GitHub mirror, use a cron `git push` or external tool.
- **Performance**: single-process; fine for 100s of repos + a few collaborators. For hundreds of active users, this isn't the right tool.
- **Charm's design aesthetic**: Soft Serve is opinionated about beautiful output. If you dislike fancy TUIs, the plain CLI subcommands still work.
- **License**: MIT.
- **Alternatives worth knowing:**
  - **Gitea** — full forge (issues, PRs, wiki, Actions, pages); still lightweight (separate recipe)
  - **Forgejo** — community fork of Gitea (separate recipe)
  - **GitLab** — full DevOps platform; heavy (separate recipe — batch 59)
  - **Gitolite** — SSH-key-based Git access; older, no UI
  - **Gogs** — older minimal forge
  - **cgit / GitWeb / gitiles** — read-only web interfaces on top of bare Git
  - **rmate / upsource** — commercial
  - **Choose Soft Serve if:** you want beautiful SSH-native Git hosting + only need push/pull/LFS/keys; don't need PRs/issues.
  - **Choose Gitea/Forgejo if:** you want PRs + issues + a web forge UX.
  - **Choose gitolite if:** you want the simplest key-based-access-only server and don't need any UI.

## Links

- Repo: <https://github.com/charmbracelet/soft-serve>
- Charm homepage: <https://charm.sh>
- Releases: <https://github.com/charmbracelet/soft-serve/releases>
- Docker setup: <https://github.com/charmbracelet/soft-serve/blob/main/docker.md>
- Nightly builds: <https://nightly.link/charmbracelet/soft-serve/workflows/nightly/main>
- Try demo: `ssh git.charm.sh`
- Bubbletea (TUI framework used): <https://github.com/charmbracelet/bubbletea>
- Lipgloss (styling): <https://github.com/charmbracelet/lipgloss>
- Gitea alternative: <https://github.com/go-gitea/gitea>
- Forgejo alternative: <https://codeberg.org/forgejo/forgejo>
- Gitolite alternative: <https://gitolite.com>

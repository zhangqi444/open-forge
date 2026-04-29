---
name: code-server-project
description: code-server recipe for open-forge. MIT-licensed VS Code in a browser (Coder's open-source product). Covers the upstream-official install paths (install.sh, npm, standalone tarball, apt/rpm, Docker, Helm) and the single-container `codercom/code-server` image. Not Coder Cloud (different product, different scope).
---

# code-server (VS Code in the browser)

MIT-licensed — run VS Code on a remote server, access it via a browser. Maintained by Coder. Distinct from Coder Cloud / Coder Workspaces (those are commercial platform products).

**Upstream README (canonical):** lives in the repo at https://github.com/coder/code-server (the file is auto-generated so tooling like this fetches `docs/install.md` for the install matrix)
**Install docs:** https://github.com/coder/code-server/blob/main/docs/install.md
**FAQ:** https://github.com/coder/code-server/blob/main/docs/FAQ.md
**Docker image:** `codercom/code-server` (Docker Hub, official)

> [!NOTE]
> Upstream ships **many** install methods (per `docs/install.md`): install.sh, npm, standalone tarball, apt/rpm packages, Arch (AUR), Artix, macOS (brew), Docker, Helm, Windows, Raspberry Pi, Termux, and various cloud providers. This recipe documents the most open-forge-relevant paths; for exotic targets, follow `docs/install.md` verbatim.

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | install.sh (native) | ✅ default | One-line install; uses distro package manager when possible |
| localhost | Docker | ✅ | Single-container `codercom/code-server` |
| localhost | npm | ✅ | `npm install -g code-server` — works everywhere Node works |
| byo-vps | Docker | ✅ | Recommended — easy cleanup, predictable |
| byo-vps | native | ✅ | install.sh + systemd user unit |
| aws/ec2 | Docker | ✅ | Preferred for predictable home directory |
| hetzner/cloud-cx | native | ✅ | |
| raspberry-pi | install.sh (standalone) | ✅ | Official arm64/armhf builds |
| kubernetes | official Helm | ✅ | `coder-charts/code-server` first-party |
| Windows | exe / winget | ✅ | Install method works but Windows users typically use VS Code itself |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain to host code-server on?" | Free-text | e.g. `code.example.com` |
| tls | "Email for Let's Encrypt notices?" | Free-text | |
| auth | "Auth mode?" | AskUserQuestion: password (default) / none / proxy | Default is a generated password in `~/.config/code-server/config.yaml` |
| auth (if password) | "Set a custom password?" | Free-text (sensitive) | Or accept the auto-generated one |
| work | "Host path for user's workspace files?" | Free-text | Mapped to `/home/coder/project` in Docker; in native install it's the shell user's home |
| extensions | "Preload extensions?" | Free-text (marketplace IDs) | e.g. `ms-python.python eamodio.gitlens` |
| user | "System user to run as (native install)?" | Free-text | Normal user account, not root |

## Install methods

### 1. install.sh (upstream canonical, native)

Source: https://github.com/coder/code-server/blob/main/docs/install.md#installsh

```bash
curl -fsSL https://code-server.dev/install.sh | sh
```

Detects Debian/Ubuntu/Fedora/Arch/macOS/FreeBSD and uses the right package manager; falls back to a standalone archive at `~/.local`.

Useful flags:
- `--dry-run` — print what would happen
- `--method standalone` — force tarball install to `~/.local`
- `--prefix /usr/local` — system-wide install
- `--version X.Y.Z` — pin version

Then run as a systemd user service:

```bash
systemctl --user enable --now code-server
```

### 2. Docker (upstream image)

Source: https://github.com/coder/code-server/blob/main/docs/install.md#docker

```bash
docker run -d --name code-server \
  -p 127.0.0.1:8080:8080 \
  -v "$HOME/.config:/home/coder/.config" \
  -v "$PWD:/home/coder/project" \
  -e DOCKER_USER=$USER \
  --user "$(id -u):$(id -g)" \
  --restart unless-stopped \
  codercom/code-server:latest
```

Runs as your UID/GID so files created in `/home/coder/project` are owned by you on the host. First password shows up in `~/.config/code-server/config.yaml`.

Docker Compose equivalent:

```yaml
services:
  code-server:
    image: codercom/code-server:latest
    container_name: code-server
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    user: "1000:1000"
    environment:
      DOCKER_USER: coder
    volumes:
      - ./config:/home/coder/.config
      - ./project:/home/coder/project
```

### 3. npm

```bash
npm install -g code-server
code-server
```

Requires Node.js 20+. Useful on hosts where you already manage Node versions.

### 4. Debian / Ubuntu (apt)

```bash
curl -fOL https://github.com/coder/code-server/releases/download/v<VERSION>/code-server_<VERSION>_amd64.deb
sudo dpkg -i code-server_<VERSION>_amd64.deb
sudo systemctl enable --now code-server@$USER
```

### 5. Helm (official)

Source: https://github.com/coder/code-server/blob/main/docs/install.md#helm

```bash
helm repo add coder-v2 https://helm.coder.com/v2
# Chart actually lives at coder-charts/code-server
helm install code-server coder-charts/code-server
```

Check the doc at install.md#helm for the canonical repo URL at the version you pull — Coder has moved chart repos occasionally.

## Software-layer concerns

### Auth

Default: password auth. Password is in `~/.config/code-server/config.yaml`:

```yaml
bind-addr: 127.0.0.1:8080
auth: password
password: <auto-generated>
cert: false
```

Modes:
- `password` — single password (default)
- `none` — no auth (only safe behind another auth layer — Cloudflare Access, Tailscale, etc.)
- `hashed-password` — store bcrypt hash instead of plaintext

For multi-user setups, run one code-server per user (different config dirs, different ports). There's no multi-user mode.

### Paths

| Thing | Path |
|---|---|
| Config file | `~/.config/code-server/config.yaml` |
| User data (settings, extensions) | `~/.local/share/code-server/` |
| Extension dir | `~/.local/share/code-server/extensions/` |
| Workspace | anywhere the shell user can reach |

In the Docker image, the `coder` user's home is `/home/coder/`.

### Reverse proxy

code-server speaks WebSockets for the live editor channel. Caddy handles this automatically:

```caddy
code.example.com {
  reverse_proxy 127.0.0.1:8080
}
```

Nginx needs `proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade";`. See `docs/guide.md` for a worked config.

### Extensions

Microsoft's official VS Code marketplace is **not accessible** from code-server (terms of service). The upstream uses [Open VSX Registry](https://open-vsx.org/) by default — a community-run mirror. Most mainstream extensions are present; some proprietary ones (GitHub Copilot, Pylance, Live Share) aren't. Workarounds exist but aren't officially supported.

### Terminal / shell

code-server includes an integrated terminal that runs as the same Unix user as code-server. On Docker, that's the `coder` user (or the UID you passed in). The terminal has the same privileges — if you run code-server as root, the terminal is root.

## Upgrade procedure

### install.sh / native

Re-run:

```bash
curl -fsSL https://code-server.dev/install.sh | sh
systemctl --user restart code-server
```

or update via your package manager (`apt upgrade code-server`, `dnf upgrade code-server`).

### Docker

```bash
docker pull codercom/code-server:latest
docker stop code-server && docker rm code-server
docker run ... (re-run install)
```

### Helm

```bash
helm repo update
helm upgrade code-server coder-charts/code-server
```

Extensions + settings persist in `~/.local/share/code-server/`. Release notes: https://github.com/coder/code-server/releases

## Gotchas

- **Password is world-readable in the config file on a shared host.** `chmod 600 ~/.config/code-server/config.yaml` if other users can log into the host.
- **Running as root is tempting but wrong.** If code-server runs as root, the terminal is root. Set up a dedicated user or run Docker with `--user`.
- **Microsoft marketplace ≠ Open VSX.** If users expect Copilot, Pylance, Live Share, set expectations. Some extensions like Pylance are explicitly blocked by Microsoft's TOS; others work fine via Open VSX.
- **WebSocket passthrough.** Nginx default config drops WS; UI looks "frozen" (loads but editor doesn't update). Use Caddy or configure Upgrade/Connection headers.
- **Performance on small VPS.** The editor + language servers can push 1-2 GB RAM easily. `t3.small` (2 GB) is a floor; `t3.medium` is comfortable.
- **Git credentials.** If you `git push` from inside code-server, you need SSH keys or a PAT mounted into the user's home. Default Docker image runs as `coder` with an empty `~/.ssh`.
- **No built-in clipboard sync with the host browser for everything.** Copy-from-editor works; copy-from-terminal works; but the OS-level clipboard behavior varies per browser.
- **Latest tag moves.** Pin versions (`codercom/code-server:4.x.x`) in prod to avoid surprise upgrades.
- **code-server is NOT Coder Workspaces.** If a user says "I want Coder," clarify — Coder Workspaces is a separate commercial platform product built around code-server + infra provisioning. code-server is the browser-editor only.
- **File permissions when binding a host path.** Use `--user "$(id -u):$(id -g)"` with the Docker image so files you create inside code-server are owned by you on the host, not by UID 1000.
- **`DOCKER_USER` env var is a display-name hint.** The shell prompt inside the editor uses it. It doesn't actually create a user.

## TODO — verify on subsequent deployments

- [ ] End-to-end test with the official Helm chart on k3s.
- [ ] Document the OAuth / OIDC reverse-proxy pattern (Authelia / Authentik / Pocket ID) for multi-user deployments.
- [ ] Tailscale Funnel pattern for exposing single-user code-server without public DNS.
- [ ] Native install with `systemctl --user` on a non-systemd-lingered user (`loginctl enable-linger`).
- [ ] Windows install — exercise winget path for completeness.

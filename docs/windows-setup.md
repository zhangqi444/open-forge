# Windows setup

open-forge itself is OS-agnostic — the AI coding tool runs on your machine, and every deploy ultimately runs in Docker/Podman on Linux (either a cloud VM, WSL2, Docker Desktop's VM, or a bare-metal Linux box).

**For Windows, we strongly recommend WSL2.** Native Windows + Docker Desktop works for pure-Docker recipes, but anything that expects `bash`, `curl | sh`, or POSIX paths (most of them) is smoother from inside WSL2.

---

## Option A — WSL2 (recommended)

### 1. Install WSL2

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

Reboot when prompted. By default this installs Ubuntu. If WSL was already installed and you want a fresh Ubuntu:

```powershell
wsl --install -d Ubuntu
wsl --set-default-version 2
```

Verify:

```powershell
wsl --status
wsl -l -v     # should show Ubuntu, VERSION 2
```

### 2. Install Docker Desktop (with WSL2 backend)

- Download: <https://www.docker.com/products/docker-desktop/>
- During setup, keep **"Use WSL 2 based engine"** enabled.
- After install: Docker Desktop → **Settings → Resources → WSL Integration** → enable your Ubuntu distro.

### 3. Install your AI coding tool inside WSL2

Open the Ubuntu shell (`wsl` from PowerShell, or launch "Ubuntu" from the Start menu) and install one of:

- **Claude Code**: `curl -fsSL https://claude.ai/install.sh | bash`
- **Codex CLI**: `npm i -g @openai/codex`
- **Aider**: `pip install aider-chat`
- **Cursor / Continue.dev**: Install on Windows; point their integrated terminal at WSL.

### 4. Verify

Inside WSL2:

```sh
docker --version
docker run hello-world
git --version
curl --version
```

All four should succeed. If `docker` complains about "Cannot connect to the Docker daemon", re-check step 2 (WSL integration).

### 5. Install open-forge

In Claude Code (or equivalent):

```
/plugin marketplace add zhangqi444/open-forge
/plugin install open-forge@open-forge
```

Or for other platforms, follow [`docs/platforms/`](platforms/).

---

## Option B — Native Windows + Docker Desktop (no WSL)

Works for deploys that are *only* Docker (no shell scripts, no `curl | sh` steps). Many recipes will still work because Docker Desktop abstracts the Linux VM, but some (native-binary installs, Ansible-style scripts) expect a real POSIX shell.

1. Install Docker Desktop — <https://www.docker.com/products/docker-desktop/>
2. Enable **Hyper-V** OR the **WSL2 backend** (the installer will ask).
3. Install Git for Windows — <https://git-scm.com/download/win> — includes **Git Bash** which provides a minimal POSIX shell.
4. Install your AI coding tool (Claude Code, Cursor, etc.) per its Windows instructions.
5. Run all open-forge commands from **Git Bash**, not CMD or PowerShell.
6. Verify: `docker --version && docker run hello-world`.

If you hit "command not found: curl" or shell-script errors, switch to Option A (WSL2).

---

## Version requirements

- **Windows 10** build 19041+ or **Windows 11** (any) — required for WSL2
- **WSL kernel** 5.10.16.3 or newer (`wsl --update` to refresh)
- **Docker Desktop** 4.x or newer
- **Git** 2.30+
- **Node.js** 20+ (if using npm-distributed AI coding tools)

---

## Troubleshooting

### "Cannot connect to the Docker daemon"

- Docker Desktop is not running → start it.
- If running inside WSL2: Docker Desktop → Settings → Resources → WSL Integration → enable your distro → restart WSL (`wsl --shutdown` from PowerShell, then re-open terminal).

### "`curl: (7) Failed to connect to 127.0.0.1 port 7890`" or `gh`/`git` clone fails with a proxy error

Git was configured (often by earlier tooling) to use a local HTTP proxy that is no longer running. This is a common Windows gotcha — see issue [#27](https://github.com/zhangqi444/open-forge/issues/27).

Check whether a stale proxy is configured:

```sh
git config --global --get http.proxy
git config --global --get https.proxy
```

If a proxy is configured and its endpoint is not available, either **bypass** for one command:

```sh
git -c http.proxy= -c https.proxy= clone <url>
```

…or **unset** the proxy for the session / permanently:

```sh
# Temporarily
git config --global --unset http.proxy
git config --global --unset https.proxy

# Or for one shell session
export HTTP_PROXY= HTTPS_PROXY=
```

Then retry your fork / clone. Same check applies to `gh` — it inherits Git's proxy settings.

### `gh auth login` fails with "device flow" timeout on corporate networks

Often the same proxy root cause. Run the proxy check above.

### WSL2 Ubuntu terminal is slow / `PATH` shows Windows entries

Windows `PATH` entries bleed into WSL by default (every directory!). Edit `/etc/wsl.conf` inside WSL:

```ini
[interop]
appendWindowsPath = false
```

Then `wsl --shutdown` and reopen.

### Line endings mangle shell scripts (`^M: command not found`)

Git for Windows defaults to `core.autocrlf=true`. In WSL2, set:

```sh
git config --global core.autocrlf input
```

For existing checkouts with bad line endings, run `dos2unix <file>` or `find . -type f -exec dos2unix {} +`.

### Ports 80 / 443 already in use

Docker Desktop won't bind them if IIS, Skype (old), or another service is listening. On Windows, run `netstat -ano | findstr :80` to find the PID and stop the offending service.

---

## See also

- [Platform-specific guides](platforms/) — Codex, Cursor, Aider, Continue.dev
- Main [README](../README.md)
- [Docker Desktop docs](https://docs.docker.com/desktop/windows/)
- [WSL2 docs](https://learn.microsoft.com/windows/wsl/)

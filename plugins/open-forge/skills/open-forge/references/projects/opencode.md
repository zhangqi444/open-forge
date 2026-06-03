---
name: opencode-project
description: OpenCode recipe for open-forge — open-source AI coding agent for the terminal (github.com/anomalyco/opencode). Runs as an interactive TUI, headless API server (`opencode serve`), or web UI (`opencode web`); also available as a desktop app (BETA). Covers every upstream-blessed install method documented at https://opencode.ai/docs/#install (verified per CLAUDE.md § *Strict doc-verification policy*): install script (`curl | bash`), npm/bun/pnpm/yarn global install, Homebrew (`anomalyco/tap/opencode` tap and official formula), Chocolatey (Windows), Scoop (Windows), Arch Linux (pacman + AUR paru), Mise, Nix, and Docker (`ghcr.io/anomalyco/opencode`). Pairs with `references/runtimes/{native,docker}.md` and `references/infra/localhost.md`.
---

# OpenCode — AI coding agent for the terminal

An open-source AI coding agent. OpenCode operates interactively in your terminal (TUI mode), can run as a headless API server, and exposes a web UI. It edits files, runs bash commands, reads your codebase, and works with any LLM provider via configurable API keys.

Two built-in agents switchable with `Tab`:
- **build** — default; full-access agent for development work.
- **plan** — read-only; analysis and exploration, asks permission before running bash commands.

Config dir: `~/.config/opencode/` (or per project `opencode.json`). No daemon by default — each `opencode` invocation is an interactive session.

Upstream: <https://github.com/anomalyco/opencode> — docs at <https://opencode.ai/docs>.

---

## Compatible combos

Verified against <https://opencode.ai/docs/#install> (README `dev` branch) per strict-doc policy. Eleven upstream-blessed install methods:

| How (install method) | Module | Notes |
|---|---|---|
| **Install script** (recommended, all platforms) | `runtimes/native.md` + project section below | `curl -fsSL https://opencode.ai/install \| bash`. Upstream README leads with this. |
| **npm / bun / pnpm / yarn** | `runtimes/native.md` + project section below | `npm i -g opencode-ai@latest` and equivalents. Requires Node.js runtime. |
| **Homebrew tap** (macOS + Linux, most current) | `runtimes/native.md` + project section below | `brew install anomalyco/tap/opencode`. Upstream recommends for always-current releases. |
| **Homebrew official formula** (macOS + Linux, less frequent) | `runtimes/native.md` + project section below | `brew install opencode`. Maintained by Homebrew team; updated less often. |
| **Chocolatey** (Windows) | `runtimes/native.md` + project section below | `choco install opencode`. Upstream recommends WSL for best experience on Windows. |
| **Scoop** (Windows) | `runtimes/native.md` + project section below | `scoop install opencode`. |
| **Arch Linux — pacman** (stable) | `runtimes/native.md` + project section below | `sudo pacman -S opencode`. |
| **Arch Linux — AUR** (latest) | `runtimes/native.md` + project section below | `paru -S opencode-bin`. |
| **Mise** (any OS) | `runtimes/native.md` + project section below | `mise use -g github:anomalyco/opencode`. |
| **Nix** | `runtimes/native.md` + project section below | `nix run nixpkgs#opencode` or `nix run github:anomalyco/opencode` for dev branch. |
| **Docker** | `runtimes/docker.md` + project section below | `ghcr.io/anomalyco/opencode` — upstream-published via GitHub Actions. |
| **Binary release** | (manual) | Download from <https://github.com/anomalyco/opencode/releases>. Pointer only. |
| **Desktop app (BETA)** | (vendor-managed) | Available at <https://opencode.ai/download>. `.dmg`/`.exe`/`.deb`/`.rpm`/`.AppImage`. Pointer — not a server deploy. |

> **Source:** <https://opencode.ai/docs/#install> and <https://github.com/anomalyco/opencode/blob/dev/README.md>

---

## Inputs to collect

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "Where?" | `AskUserQuestion`: localhost (Mac / Linux / WSL2 / Windows) / Remote SSH'd VM | Most users are on localhost. |
| preflight | "How?" | `AskUserQuestion`: Install script / npm (or bun/pnpm/yarn) / Homebrew / Chocolatey / Scoop / Arch (pacman/AUR) / Mise / Nix / Docker | Filtered by OS |
| provision | "LLM provider?" | `AskUserQuestion`: OpenCode Zen (hosted, simplest) / Anthropic / OpenAI / Google Gemini / AWS Bedrock / Azure OpenAI / Ollama / Other | Drives API key prompt |
| provision | "API key for `<provider>`?" | Free-text (sensitive) | Use `/connect` in TUI or env var. Do not log. |
| provision | "Which project to start with?" | Free-text (path) or "later" | OpenCode benefits from running `/init` once per project. |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.install_method` | `script` / `npm` / `brew-tap` / `brew-official` / `choco` / `scoop` / `pacman` / `aur` / `mise` / `nix` / `docker` |
| `outputs.binary_path` | Where `opencode` CLI is installed |
| `outputs.config_path` | `~/.config/opencode/config.json` or project-local `opencode.json` |
| `outputs.provider` | LLM provider chosen |
| `outputs.mode` | `tui` / `server` / `web` |

---

## Software-layer concerns (apply to every install method)

### What you're installing

The `opencode` binary (a single self-contained CLI). It:
- Reads files in the current working directory.
- Talks to an LLM provider's API.
- Edits files, runs bash commands per-session.
- Shells out to `git` as needed.

No daemon by default — `opencode` is an interactive CLI session. For server mode, `opencode serve` exposes an HTTP API on a local port.

### Configuration

OpenCode uses a JSON config file:

| Path | Scope |
|---|---|
| `~/.config/opencode/config.json` | Global user config |
| `<project-root>/opencode.json` | Per-project config (safe to commit — no secrets) |

The config file handles provider selection, model overrides, custom agents, MCP servers, LSP servers, keybinds, themes, and permissions. Credentials are set separately via `/connect` in the TUI or as env vars — never hardcode API keys into `opencode.json`.

### Provider configuration

OpenCode works with any LLM provider. The easiest path for new users is **OpenCode Zen** (curated hosted models):

```
# In the TUI
/connect
# Select "opencode", visit https://opencode.ai/auth, copy API key, paste.
```

For other providers, set the relevant env var or use `/connect` with the appropriate provider:

| Provider | Env var |
|---|---|
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| Google Gemini | `GEMINI_API_KEY` |
| AWS Bedrock | AWS credentials via standard AWS CLI profile |
| Azure OpenAI | `AZURE_OPENAI_API_KEY` + `AZURE_OPENAI_ENDPOINT` |
| Ollama (local) | `OLLAMA_HOST` (default `http://localhost:11434`) |

For the full providers directory, see <https://opencode.ai/docs/providers#directory>.

### Agents and modes

- `opencode` — launch interactive TUI
- `opencode serve` — headless API server (local HTTP endpoint, default port 4096)
- `opencode web` — web UI accessible via browser
- Switch between **build** (default, full access) and **plan** (read-only) agents with `Tab` key in TUI.

### Initialization

After first launch in a project:

```bash
cd /path/to/project
opencode
# Then in the TUI:
/init
```

This analyzes the project and creates `AGENTS.md` in the project root. **Commit this file to git** — it helps OpenCode understand project structure on future sessions.

### Terminal requirements

OpenCode's TUI needs a modern terminal emulator for best results:
- WezTerm (cross-platform, recommended)
- Alacritty (cross-platform)
- Ghostty (Linux + macOS)
- Kitty (Linux + macOS)

For Windows, WSL2 + any of the above is the upstream-recommended path (see <https://opencode.ai/docs/windows-wsl>).

---

## Native install methods

### Install script (recommended, Mac / Linux)

> **Source:** <https://opencode.ai/docs/#install>

```bash
curl -fsSL https://opencode.ai/install | bash
```

The script respects install-path env vars (priority order):

```bash
# Custom install dir
OPENCODE_INSTALL_DIR=/usr/local/bin curl -fsSL https://opencode.ai/install | bash

# XDG-compliant path
XDG_BIN_DIR=$HOME/.local/bin curl -fsSL https://opencode.ai/install | bash
```

Default install path priority:
1. `$OPENCODE_INSTALL_DIR` if set
2. `$XDG_BIN_DIR` if set
3. `$HOME/bin` if it exists
4. `$HOME/.opencode/bin` (fallback)

After install, verify: `opencode --version`.

### npm / bun / pnpm / yarn

> **Source:** <https://opencode.ai/docs/#install>

Package name on npm is `opencode-ai` (not `opencode`).

```bash
# npm
npm install -g opencode-ai@latest

# Bun
bun install -g opencode-ai

# pnpm
pnpm install -g opencode-ai

# Yarn
yarn global add opencode-ai
```

Requires Node.js (or Bun runtime). Upgrade: re-run with `@latest`.

> Note from upstream: Bun support on Windows is currently in progress.

### Homebrew — anomalyco/tap (recommended on macOS + Linux)

> **Source:** <https://opencode.ai/docs/#install>

Upstream recommends this tap for the most up-to-date releases:

```bash
brew install anomalyco/tap/opencode
```

Upgrade: `brew upgrade anomalyco/tap/opencode`.

### Homebrew — official formula (macOS + Linux)

> **Source:** <https://opencode.ai/docs/#install>

```bash
brew install opencode
```

Maintained by the Homebrew team; updated less frequently than the anomalyco tap. Upgrade: `brew upgrade opencode`.

### Chocolatey (Windows)

> **Source:** <https://opencode.ai/docs/#install>

```powershell
choco install opencode
```

Upgrade: `choco upgrade opencode`.

> Upstream tip: For the best Windows experience, use WSL. See <https://opencode.ai/docs/windows-wsl>.

### Scoop (Windows)

> **Source:** <https://opencode.ai/docs/#install>

```powershell
scoop install opencode
```

Upgrade: `scoop update opencode`.

### Arch Linux — pacman (stable)

> **Source:** <https://opencode.ai/docs/#install>

```bash
sudo pacman -S opencode
```

### Arch Linux — AUR (latest)

> **Source:** <https://opencode.ai/docs/#install>

```bash
paru -S opencode-bin
```

Or with yay: `yay -S opencode-bin`.

### Mise (any OS)

> **Source:** <https://opencode.ai/docs/#install>

```bash
mise use -g github:anomalyco/opencode
```

Upgrade: `mise upgrade opencode-ai`.

### Nix

> **Source:** README at <https://github.com/anomalyco/opencode/blob/dev/README.md>

```bash
# nixpkgs stable
nix run nixpkgs#opencode

# Latest dev branch
nix run github:anomalyco/opencode
```

For persistent install via `home-manager`, add `nixpkgs#opencode` to your packages list.

### Binary release (manual)

> **Source:** <https://github.com/anomalyco/opencode/releases>

Download a pre-built binary from the Releases page, make it executable, and move it to a directory on `$PATH`:

```bash
# Example (Linux x64)
chmod +x opencode-linux-x64
mv opencode-linux-x64 /usr/local/bin/opencode
opencode --version
```

### Desktop app (BETA)

> **Source:** <https://opencode.ai/download> and README

Available at <https://opencode.ai/download> or from the Releases page.

| Platform | Artifact |
|---|---|
| macOS (Apple Silicon) | `opencode-desktop-mac-arm64.dmg` |
| macOS (Intel) | `opencode-desktop-mac-x64.dmg` |
| Windows | `opencode-desktop-windows-x64.exe` |
| Linux | `.deb`, `.rpm`, or `.AppImage` |

Via package managers (where available):

```bash
# macOS (Homebrew cask)
brew install --cask opencode-desktop

# Windows (Scoop extras bucket)
scoop bucket add extras
scoop install extras/opencode-desktop
```

This is the desktop GUI wrapper, still in BETA. open-forge's scope covers the CLI/server install; the desktop app is a pointer.

---

## Docker

> **Source:** <https://opencode.ai/docs/#install> — Docker section

Upstream publishes an official container image to GitHub Container Registry:

```bash
docker run -it --rm ghcr.io/anomalyco/opencode
```

For working with a local project, bind-mount your repo:

```bash
docker run -it --rm \
  --volume "$(pwd):/workspace" \
  --workdir /workspace \
  ghcr.io/anomalyco/opencode
```

Pass API keys via env vars:

```bash
docker run -it --rm \
  --volume "$(pwd):/workspace" \
  --workdir /workspace \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  ghcr.io/anomalyco/opencode
```

### Server mode in Docker

To run OpenCode as a headless API server in a container:

```bash
docker run -d \
  --name opencode-server \
  -p 4096:4096 \
  --volume "$(pwd):/workspace" \
  --workdir /workspace \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  ghcr.io/anomalyco/opencode serve
```

Pair with [`references/runtimes/docker.md`](../runtimes/docker.md) for compose, port, and lifecycle management.

### Docker-specific gotchas (OpenCode-only)

- **TUI in Docker requires a TTY.** Always pass `-it` (interactive + TTY) for TUI mode; without it the interface won't render.
- **Git config inside container.** OpenCode may use git to read project context; set git user in the container or rely on the bind-mounted `.git/config`.
- **API keys via env vars**, not mounted files — avoids secrets appearing in `docker inspect` history.
- **Server mode (`opencode serve`) works without a TTY.** Use `-d` + `-p 4096:4096` for containerized server deployments.

---

## Server mode (`opencode serve`)

OpenCode can run as a headless HTTP API server — useful for IDE integrations, CI pipelines, and custom tooling:

```bash
opencode serve
# Default port: 4096
```

See <https://opencode.ai/docs/server/> for the API reference. Pair with `references/modules/tunnels.md` if the server needs to be accessible beyond localhost.

---

## Per-cloud / per-PaaS pointers

OpenCode is primarily a developer-workstation tool. The most common deploy is on localhost (or a remote dev VM).

| Where | Adapter | Recommended path |
|---|---|---|
| **localhost** (Mac / Linux / WSL2) | `infra/localhost.md` | Install script or Homebrew tap |
| **Windows native** | `infra/localhost.md` | Scoop, Chocolatey, or npm; WSL strongly recommended by upstream |
| **SSH'd-into remote dev VM** | `infra/byo-vps.md` | Same as localhost — `curl | bash` inside the SSH session |
| **Docker on any host** | `runtimes/docker.md` | `ghcr.io/anomalyco/opencode` |
| **Headless server / CI** | `infra/byo-vps.md` | `opencode serve` + tunnel if remote access needed |

---

## Verification before marking `provision` done

- `opencode --version` prints a version string from any directory.
- `opencode --help` shows usage without errors.
- `cd <project> && opencode` opens the TUI (requires TTY).
- `opencode serve` starts the API server and prints the listening port.
- (Provider check) In the TUI, type a short prompt and verify the LLM responds.
- (Init check) `/init` in the TUI creates `AGENTS.md` in the project root.

---

## Consolidated gotchas

- **Terminal requirement.** OpenCode's TUI needs a modern terminal (WezTerm, Alacritty, Ghostty, Kitty). Apple Terminal and older Windows Terminal may have rendering issues. On Windows, WSL + a modern terminal is the upstream-recommended path.
- **npm package name is `opencode-ai`, not `opencode`.** Installing `opencode` via npm installs an unrelated package.
- **Homebrew tap vs official formula.** `anomalyco/tap/opencode` gets upstream releases faster. If freshness matters, use the tap.
- **Nix `flake.nix` is a dev shell, not a production package.** Use `nix run nixpkgs#opencode` or `nix run github:anomalyco/opencode` for end-user install; the `flake.nix` in the repo is for contributors.
- **`opencode serve` default port is 4096.** Configure an alternate port in `opencode.json` if 4096 is taken.
- **API keys are sensitive.** Use `/connect` in the TUI or env vars — never paste raw keys into chat or commit them to `opencode.json`. See `references/modules/credentials.md`.
- **Older versions (< 0.1.x) must be removed before installing.** The upstream README includes a removal note; check `which opencode` and remove any pre-0.1.x binary before installing.
- **Desktop app is BETA.** For production/server use, stick to the CLI binary.
- **Per-project `AGENTS.md`.** Running `/init` creates this file — commit it to git. It dramatically improves OpenCode's understanding of project structure on subsequent sessions.

---

## TODO — verify on subsequent deployments

- **Install script path priority** — verify `OPENCODE_INSTALL_DIR` and `XDG_BIN_DIR` env-var overrides on Linux and macOS.
- **npm / bun install on Windows native** — Bun support on Windows is in-progress per upstream; verify when resolved.
- **Homebrew tap freshness** — confirm `anomalyco/tap/opencode` vs `brew install opencode` version lag in practice.
- **Arch pacman vs AUR** — verify `opencode-bin` AUR package is from `anomalyco/opencode` and not an unrelated package.
- **Docker TTY rendering** — verify TUI renders correctly under `docker run -it`; test on Linux and macOS Docker Desktop.
- **`opencode serve` API surface** — document available endpoints and auth when <https://opencode.ai/docs/server/> is more complete.
- **Nix `nixpkgs#opencode`** — verify this package name in nixpkgs; `nix search nixpkgs opencode` to confirm.
- **Desktop app stability** — currently BETA; note when it graduates to stable.
- **Provider `/connect` flows** — verify which providers support the in-TUI `/connect` wizard vs manual env-var-only config.
- **Windows WSL path** — add a pointer to `references/modules/wsl.md` if/when that module is written.

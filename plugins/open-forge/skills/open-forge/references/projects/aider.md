---
name: aider-project
description: Aider recipe for open-forge — AI pair-programming CLI agent (github.com/Aider-AI/aider, ~25k★). Different category from chat UIs (Open WebUI / LibreChat) and RAG workspaces (AnythingLLM) — runs in the developer's terminal alongside their git repo, edits files via diffs, auto-commits per change with attribution. Pairs with any LLM provider (Anthropic / OpenAI / DeepSeek / Gemini / OpenRouter / Ollama / vLLM / any OpenAI-compatible) and any local model that meets the context-length floor. Covers every upstream-blessed install method documented under `aider/website/docs/install/*` (verified per CLAUDE.md § *Strict doc-verification policy*): `aider-install` (recommended, isolated Python 3.12 env), uv-based one-liner script (`curl/iwr | sh`), uv direct install, pipx, plain pip, plus Docker (`paulgauthier/aider` core + `paulgauthier/aider-full` with all extras), GitHub Codespaces (pointer), and Replit (pipx-based). Pairs with `references/runtimes/{native,docker}.md`.
---

# Aider — AI pair programming in your terminal

A CLI tool that pairs with you on a git repo: you describe the change, Aider reads the relevant files, drafts a diff, applies it, and `git commit`s with itself as the author. No web UI, no daemon, no server-side state — Aider is a Python process that talks to an LLM, edits files in your working directory, and shells out to git.

Default config dir: `~/.aider/` for caches + tag-graph; per-repo state in `.aider.tags.cache.v3/`, `.aider.chat.history.md`, `.aider.input.history` inside the repo. Configuration via flags, env vars (per-provider API keys), or `.aider.conf.yml` / `.aider.model.settings.yml` next to the repo or under `~/`. Default Python: 3.12 (the recommended `aider-install` flow installs an isolated 3.12); pip / pipx accept Python 3.9-3.12.

Upstream: <https://github.com/Aider-AI/aider> — docs at <https://aider.chat>.

## Compatible combos

Verified against `aider/website/docs/install.md` + `docs/install/{docker,codespaces,replit,optional}.md` per strict-doc policy. Eight upstream-blessed install methods:

| How (install method) | Module | Notes |
|---|---|---|
| **`aider-install`** (recommended) | `runtimes/native.md` + project section below | `python -m pip install aider-install && aider-install`. Creates an isolated Python 3.12 env for Aider; tracks Python version automatically. The path upstream's README leads with. |
| **One-liner uv installer** (Mac / Linux / Windows) | project section below | `curl -LsSf https://aider.chat/install.sh \| sh` (Mac/Linux) or `powershell -ExecutionPolicy ByPass -c "irm https://aider.chat/install.ps1 \| iex"` (Windows). Wraps `uv` to do the same isolated-env install as `aider-install`. |
| **uv direct** | `runtimes/native.md` + project section below | `uv tool install --force --python python3.12 --with pip aider-chat@latest`. For users who already manage `uv` themselves. |
| **pipx** | `runtimes/native.md` + project section below | `pipx install aider-chat`. Python 3.9–3.12 supported. Familiar for Python devs who already use pipx for other CLIs. |
| **pip** (with venv) | `runtimes/native.md` + project section below | `python -m pip install -U --upgrade-strategy only-if-needed aider-chat`. Python 3.9–3.12. Upstream explicitly discourages without a venv. |
| **Docker — core** | `runtimes/docker.md` + project section below | `paulgauthier/aider`. Smaller image; voice + browser-GUI extras need re-install per container start. |
| **Docker — full** | `runtimes/docker.md` + project section below | `paulgauthier/aider-full`. Includes all extras (interactive help, browser GUI, Playwright scraping). |
| **GitHub Codespaces** | (vendor-managed) | Pointer — runs the same install methods above inside the codespace terminal. Upstream docs include a video walkthrough. |
| **Replit** | (vendor-managed) | Pointer — pipx-based per upstream's `replit-pipx.md` include. |

Aider is fundamentally a CLI tool that runs on the developer's workstation (or inside a Codespace / Replit). There's no "production server" deploy. open-forge's role is to walk a user through one-time install + initial config, not orchestrate a long-running service.

## Inputs to collect

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to install?" | (inferred from "Aider" in user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: localhost (Mac / Linux / WSL2 / Windows) / GitHub Codespaces / Replit / SSH'd-into remote VM | Most users are localhost. Codespaces / Replit are pointers. |
| preflight | "How?" (dynamic from combo) | `AskUserQuestion`: `aider-install` (recommended) / one-liner script / uv direct / pipx / pip / Docker core / Docker full | Filtered by infra (Codespaces/Replit always use the in-terminal install) |
| preflight | "Python source?" | `AskUserQuestion`: System Python 3.9–3.12 / let `aider-install` provision Python 3.12 / use `uv`'s bundled Python | Most users let aider-install handle Python; Linux distro Python may be too old or missing pip. |
| provision | "LLM provider?" | `AskUserQuestion`: Anthropic / OpenAI / Google Gemini / DeepSeek / OpenRouter / Azure OpenAI / Bedrock / Ollama (local) / vLLM (local) / Other OpenAI-compatible | Drives `--model` flag + `--api-key` flag pattern |
| provision | "API key for `<provider>`?" | Free-text (sensitive) | Pasted into `~/.env` (Aider auto-loads) or `.env` next to the repo, OR set as env var (`ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / etc.). Do not paste into chat. |
| provision | "Default model?" | `AskUserQuestion`: claude-3-7-sonnet / o3-mini / gpt-4o / deepseek-chat / deepseek-reasoner / Custom (free-text) | Sets `--model` default in `.aider.conf.yml` |
| provision | "Optional extras?" | `AskUserQuestion`: Voice (microphone input) / Browser (web GUI) / Playwright (web scraping) / None | Drives `--extras` install per `docs/install/optional.md` |
| provision | "Repo to start with?" | Free-text (path to existing repo) or "later" | Aider runs `cd <repo> && aider`; needs a git repo |
| provision | "Auto-commit policy?" | `AskUserQuestion`: Default (auto-commit per change) / `--no-auto-commits` / `--dirty-commits` | Sets the commit policy in `.aider.conf.yml` |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.install_method` | `aider-install` / `uv` / `pipx` / `pip` / `docker-core` / `docker-full` / `codespaces` / `replit` |
| `outputs.python_path` | Where `aider` itself lives (e.g. `~/.aider-install/venv/bin/aider` for aider-install, `~/.local/bin/aider` for pipx) |
| `outputs.config_path` | `~/.aider.conf.yml` and/or `<repo>/.aider.conf.yml` |
| `outputs.env_path` | `~/.env` and/or `<repo>/.env` |
| `outputs.default_model` | `claude-3-7-sonnet` / `o3-mini` / etc. |
| `outputs.providers` | List of configured LLM providers |

## Software-layer concerns (apply to every install method)

### What you're installing

A single Python package (`aider-chat` on PyPI) that exposes the `aider` CLI. No daemon, no web server, no database. Aider operates entirely on the developer's workstation:

- Reads files in the current working directory (must be a git repo).
- Talks to an LLM provider's API.
- Edits files via diffs (search/replace blocks or unified diffs depending on the model).
- Shells out to `git add`, `git commit -m "...", git diff` per change.

The "service architecture" is one Python process spawned per `aider` invocation. Aider exits when the user `^D`s the chat or types `/exit`.

### Config files

Aider reads config from multiple locations (later ones override earlier):

| Path | Purpose |
|---|---|
| `~/.aider.conf.yml` | Per-user defaults (model, edit format, auto-commit policy, etc.) |
| `<repo>/.aider.conf.yml` | Per-repo overrides (different model per project, etc.) |
| `~/.aider.model.metadata.json` | User-defined model metadata (custom context-length, cost-per-token) |
| `~/.aider.model.settings.yml` | Per-model settings (edit format, weak-model pairing) |
| `~/.env` | API keys (Aider auto-loads via `python-dotenv`) |
| `<repo>/.env` | Per-repo env vars / API keys |
| `<repo>/.aiderignore` | gitignore-style allowlist for which files Aider can edit |

The `.env` files are the right place for API keys — keeps them out of `~/.aider.conf.yml` (which users sometimes commit by mistake) and out of shell history.

### Per-repo state

Aider writes to a few hidden paths inside the repo:

- `.aider.tags.cache.v3/` — tree-sitter symbol cache (gitignored by default).
- `.aider.chat.history.md` — Markdown transcript of every Aider session in this repo. Useful for review; potentially sensitive.
- `.aider.input.history` — readline-style history of user prompts.
- `.aider.llm.history` — full LLM API request/response log (debug-only; can grow large).

Recommend adding all of these to `.gitignore`:

```
.aider*
```

### Model providers

Aider speaks to any LLM via [LiteLLM](https://github.com/BerriAI/litellm) under the hood. Provider selection is via `--model <provider/model>` syntax:

| Provider | `--model` | API key env var |
|---|---|---|
| Anthropic | `sonnet`, `claude-3-7-sonnet-20250219`, `claude-3-5-haiku` | `ANTHROPIC_API_KEY` |
| OpenAI | `o3-mini`, `gpt-4o`, `gpt-4o-mini` | `OPENAI_API_KEY` |
| Google Gemini | `gemini/gemini-2.0-pro`, `gemini/gemini-2.0-flash` | `GEMINI_API_KEY` |
| DeepSeek | `deepseek`, `deepseek-reasoner` | `DEEPSEEK_API_KEY` |
| OpenRouter | `openrouter/<provider>/<model>` (e.g. `openrouter/anthropic/claude-3.7-sonnet`) | `OPENROUTER_API_KEY` |
| Azure OpenAI | `azure/<deployment-name>` | `AZURE_API_KEY` + `AZURE_API_BASE` + `AZURE_API_VERSION` |
| Bedrock | `bedrock/anthropic.claude-3-5-sonnet-...` | AWS creds via env / IAM |
| Ollama (local) | `ollama_chat/<model>` (e.g. `ollama_chat/llama3.2`, `ollama_chat/qwen2.5-coder`) | `OLLAMA_API_BASE` (default `http://127.0.0.1:11434`) |
| vLLM / LocalAI / any OpenAI-compatible | `openai/<model>` with `OPENAI_API_BASE=https://your.endpoint/v1` | `OPENAI_API_KEY` (placeholder OK) |

For the full list of supported models + their LiteLLM mappings, see `aider --models`.

### Pair-pattern: Anthropic Sonnet (or GPT-4o) for the "edit" model + a cheaper "weak" model

Aider uses two models per session: a strong "edit" model (drafts diffs, decides when to commit) and a weak "summarizer" model (compresses long chats, names commits). Default pairing is sensible (Sonnet → Haiku, GPT-4o → GPT-4o-mini). Override:

```bash
aider --model sonnet --weak-model haiku
aider --model gpt-4o --weak-model gpt-4o-mini
aider --model deepseek-reasoner --weak-model deepseek-chat   # DeepSeek's two-tier
```

For local Ollama: pair a strong + cheap pair from your local model library.

### `.aiderignore` + repo permissions

By default, Aider can read+edit any file in the repo. Restrict via `.aiderignore` (gitignore syntax):

```
# In .aiderignore
node_modules/
*.lock
secret/
infra/terraform/state/
```

Aider still reads ignored files when the user `/add`s them explicitly, but won't auto-add or auto-edit. Treat `.aiderignore` as the safety boundary for "don't let the LLM rewrite my package-lock.json".

### Optional extras

Per `docs/install/optional.md`, Aider has several optional features that need extra install steps:

| Extra | Install | What it adds |
|---|---|---|
| **Voice** | `pip install aider-chat[voice]` (or via `aider-install` with `--full`) | `/voice` command for microphone-to-prompt transcription |
| **Browser GUI** | `pip install aider-chat[browser]` | `aider --browser` opens a Streamlit-based web UI as an alternative to terminal |
| **Playwright** (for web scraping) | `playwright install --with-deps chromium` after install | Lets Aider fetch + scrape URLs the user `/web`s during chat |
| **Help docs RAG** | (auto-installed by aider-install) | `/help` command searches Aider's own docs for the user |

The `paulgauthier/aider-full` Docker image bundles all of these; the `paulgauthier/aider` core image bundles none and prompts to install on first use.

### Composing with Ollama / Open WebUI / LibreChat / OpenClaw / Hermes / AnythingLLM

- **Ollama** as local backend — `aider --model ollama_chat/qwen2.5-coder:32b` with Ollama running on the same machine. For larger models, use a beefier remote Ollama: set `OLLAMA_API_BASE=http://<host>:11434`.
- **Open WebUI / LibreChat / AnythingLLM** as a routing layer — generate a per-user API key in their UI, then `aider --model openai/gpt-4o --openai-api-key <key> --openai-api-base http://<host>:3000/v1` (or whichever port the UI exposes). Aider sees them as plain OpenAI-compatible endpoints.
- **OpenClaw / Hermes** (agents themselves) — running both Aider and OpenClaw/Hermes as separate agents in the same dev workflow is fine; they don't need to know about each other. Aider for code edits, OpenClaw/Hermes for higher-level orchestration / messaging.

---

## Native install methods

Five upstream-blessed Python install methods, all documented in `aider/website/docs/install.md`. Pick by user preference; `aider-install` is what upstream's README leads with.

### `aider-install` (recommended)

```bash
python -m pip install aider-install
aider-install
```

What this does (per upstream):

- Installs the `aider-install` PyPI package using whatever Python the user has (3.8–3.13).
- Running `aider-install` then sets up an isolated environment for Aider with Python 3.12. If the user doesn't have Python 3.12, `aider-install` downloads + installs one just for Aider.
- The Aider CLI lands somewhere on PATH (e.g. `~/.aider-install/bin/aider`).

After install, `aider --version` works from any directory. Subsequent upgrades: re-run `aider-install` (it picks up the latest aider-chat).

### One-liner uv-based installer (Mac / Linux / Windows)

Same isolated-env install, packaged as a curl-pipe-shell. Underneath, it uses `uv` to manage the Python + venv.

```bash
# Mac / Linux (curl)
curl -LsSf https://aider.chat/install.sh | sh

# Mac / Linux (wget alternative for systems without curl)
wget -qO- https://aider.chat/install.sh | sh

# Windows PowerShell
powershell -ExecutionPolicy ByPass -c "irm https://aider.chat/install.ps1 | iex"
```

Pair with [`references/runtimes/native.md`](../runtimes/native.md) for the OS-prereq + curl/wget install bits.

### uv direct

If the user already runs `uv` for other Python tools:

```bash
# If uv isn't installed yet
python -m pip install uv

# Install Aider in an isolated, uv-managed Python 3.12 env
uv tool install --force --python python3.12 --with pip aider-chat@latest
```

`uv tool install` puts the binary on PATH automatically (typically `~/.local/bin/aider`). Upgrade: `uv tool upgrade aider-chat`. List: `uv tool list`. Uninstall: `uv tool uninstall aider-chat`.

### pipx

Familiar for Python devs who already use `pipx`:

```bash
# If pipx isn't installed yet
python -m pip install pipx
python -m pipx ensurepath          # adds ~/.local/bin to PATH; restart shell after

pipx install aider-chat
```

Python 3.9–3.12 supported. Upgrade: `pipx upgrade aider-chat`. Uninstall: `pipx uninstall aider-chat`.

### plain pip (with venv)

Upstream explicitly discourages `pip install` without a venv (the dependency closure is large and clashes with system Python). Inside a venv it's fine:

```bash
python -m venv ~/aider-venv
source ~/aider-venv/bin/activate    # Windows: ~/aider-venv/Scripts/activate
python -m pip install -U --upgrade-strategy only-if-needed aider-chat

# Run
aider <args>

# Or run via module form (works without venv activation)
python -m aider <args>
```

Python 3.9–3.12. The `--upgrade-strategy only-if-needed` flag keeps Aider's deps stable when other packages share the venv.

### System package managers (discouraged by upstream)

Per `install.md`: *"While aider is available in a number of system package managers, they often install aider with incorrect dependencies."* Upstream recommends NOT using `apt install aider`, `dnf install aider`, `brew install aider`, etc. — even when they exist.

If a user insists, document it as community-maintained per CLAUDE.md § *Strict doc-verification policy*'s flagging requirement. Better path: `pipx` (or one of the other Python-isolated methods).

### Daemon lifecycle — there is none

Aider doesn't run as a service. Each `aider` invocation is an interactive CLI session that exits when the user quits. No systemd / launchd / Scheduled-Task setup needed.

For Aider-driven CI / scripted runs (rare but supported), use `--message "..." --yes` to run non-interactively:

```bash
aider --message "Update CHANGELOG.md with release notes for v1.2.3" --yes --no-stream src/CHANGELOG.md
```

### Native-install gotchas (Aider-only)

- **Python version mismatch is the #1 install failure mode.** `aider-install` and the one-liner script handle this by provisioning Python 3.12 themselves; pipx + pip rely on the user having 3.9–3.12. If the system Python is 3.8 or 3.13+, prefer `aider-install`.
- **`pip install aider-chat` without a venv is fragile.** Aider has a deep dependency tree (LiteLLM, tree-sitter, prompt_toolkit, …) that often clashes with other tools' versions. Upstream warns about this; honor it.
- **PATH refresh after install.** `pipx ensurepath` and `aider-install` both modify shell rc files; users may need to open a new shell or `exec $SHELL -l` before `aider --version` works.
- **`.env` precedence is per-cwd.** Running `aider` from a directory without a `.env` falls back to `~/.env` and shell env vars. Surprises happen when a user cd's into a sub-repo with its own `.env` overriding global settings.
- **`aider --models`** lists every supported LiteLLM model; useful for verifying provider-name spelling before paying for a wrong-model API call.
- **Optional extras** are NOT installed by default. `aider --voice` will prompt to install on first use (and may need `apt install portaudio19-dev` or similar OS-level deps). Same for `--browser` (Streamlit) and `/web` (Playwright + Chromium).

---

## Docker

When the user wants Aider in a container — common in CI runners, dev containers, or when the host Python is too old / locked-down for a pip install. Pair with [`references/runtimes/docker.md`](../runtimes/docker.md).

Upstream docs: <https://aider.chat/docs/install/docker.html>. Two upstream-blessed images:

| Image | Size | When |
|---|---|---|
| `paulgauthier/aider` | ~smaller | Aider core only. Voice / browser GUI / Playwright extras need re-install on first use; since containers are ephemeral, those reinstalls happen every container start. |
| `paulgauthier/aider-full` | ~larger | Aider + every optional extra pre-installed. Heavier image; saves the per-container reinstall. |

### Aider core

```bash
docker pull paulgauthier/aider
docker run -it \
  --user "$(id -u):$(id -g)" \
  --volume "$(pwd):/app" \
  paulgauthier/aider \
  --openai-api-key "$OPENAI_API_KEY" \
  [...other aider args...]
```

### Aider full

```bash
docker pull paulgauthier/aider-full
docker run -it \
  --user "$(id -u):$(id -g)" \
  --volume "$(pwd):/app" \
  paulgauthier/aider-full \
  --openai-api-key "$OPENAI_API_KEY" \
  [...other aider args...]
```

### How to use it

Run from the **root of your git repo**. The `--volume $(pwd):/app` flag bind-mounts your repo into the container at `/app`, which is Aider's working directory.

Aider needs to know your git author info, but the container doesn't have your global git config. Set per-repo before `docker run`:

```bash
git config user.email "you@example.com"
git config user.name "Your Name"
```

### Docker-specific gotchas (Aider-only — verbatim from `docs/install/docker.md`)

- **`/run` runs in the container, not on the host.** When you use Aider's in-chat `/run` command, it executes shell commands *inside the docker container*. Tests, build commands, etc. run in the container's environment — not your local one. May need to `docker run` with an image that has your project's runtime baked in, or skip `/run` for those use cases.
- **`/voice` won't work** unless you give the docker container access to the host's audio device. The container has `libportaudio2` installed, so it should work in principle — figuring out the host-audio-passthrough is the unsolved part. Alsa / PulseAudio sockets are the typical paths; not pursued in upstream's docs.
- **Per-container ephemerality of extras.** `paulgauthier/aider` core re-prompts to install optional extras on every `docker run` because the previous container's pip changes don't persist. Use `paulgauthier/aider-full` to avoid this.
- **`--user $(id -u):$(id -g)`** is critical — without it, files Aider commits to the bind-mount land as root-owned on the host, breaking subsequent host-side `git` operations.
- **API keys via `--openai-api-key` / `--anthropic-api-key` flags or env-var pass-through (`-e ANTHROPIC_API_KEY`)** — don't put keys in `--volume`-mounted `.env` files when iterating, since Aider's chat history will record cwd contents.

---

## GitHub Codespaces

Per `docs/install/codespaces.md`, Aider works inside a Codespace's built-in Terminal pane — no special setup beyond the standard install methods.

Upstream docs: <https://aider.chat/docs/install/codespaces.html>.

### Install + run

Open the Codespace's Terminal pane and run any of the standard install methods:

```bash
# Recommended inside a Codespace
python -m pip install aider-install
aider-install

# Or pipx — Codespaces typically have pipx pre-installed
pipx install aider-chat

# Or the one-liner uv installer
curl -LsSf https://aider.chat/install.sh | sh
```

Then `cd /workspaces/<your-repo>` (the standard Codespaces repo path) and run `aider --model <provider>` with the matching API key.

Upstream's docs include a video walkthrough (linked at <https://aider.chat/assets/codespaces.mp4>). open-forge can narrate the steps but can't drive the Codespace UI.

### Codespaces-specific gotchas

- **API keys via Codespace secrets.** Don't paste keys into the Terminal — set them at *Settings → Codespaces → Repository secrets* on GitHub, then they're auto-populated as env vars (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.) inside every Codespace launched from that repo.
- **Codespace teardown loses Aider state.** A Codespace that's deleted (vs paused) wipes the `~/.aider/` cache + per-repo `.aider.*` files. Aider re-builds the tag-graph on next launch (slow first run).
- **Codespace billing applies to LLM-API usage too.** The Codespace's network egress is paid; Aider's API calls go through it.
- **Pre-built Codespaces** (`.devcontainer.json`) can bake Aider in: `postCreateCommand: "python -m pip install aider-install && aider-install"`. Saves install time per Codespace.

---

## Replit

Per `docs/install/replit.md`, Aider supports Replit via the `pipx` install path. The page is a thin pointer to a shared `replit-pipx.md` include.

Upstream docs: <https://aider.chat/docs/install/replit.html>.

### Install + run

In the Replit Shell pane:

```bash
pipx install aider-chat
aider --model sonnet --api-key anthropic=<key>
```

Replit's Nix-based environment usually has `pipx` available; if not, `pip install --user pipx` first.

### Replit-specific gotchas

- **Replit's filesystem is the repl's working directory.** `aider` Just Works™ from the shell as long as the repl is initialized as a git repo (which Replit does by default).
- **Replit Secrets for API keys.** Set `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` in the repl's *Secrets* tab; they auto-populate as env vars in the shell.
- **Replit's free tier has CPU + RAM caps** that Aider can saturate when scanning a large repo's tag graph. Free tier works for small repos; paid tier or move to a Codespace / desktop for bigger ones.
- **Replit's "Always-On" feature** doesn't apply to Aider — it's not a long-running service. Each `aider` invocation is a one-shot interactive session.

---

## Per-cloud / per-PaaS pointers

Aider is fundamentally a developer-workstation tool. There's no "deploy Aider to a cloud VM" use case unless the user wants a remote pair-programming workspace.

| Where | Adapter | Recommended path |
|---|---|---|
| **localhost** (Mac / Linux / WSL2 / Windows) | `infra/localhost.md` | `aider-install` or one-liner uv script |
| **GitHub Codespaces** | (vendor-managed) | Per *GitHub Codespaces* section above; also `.devcontainer.json` pre-bake |
| **Replit** | (vendor-managed) | Per *Replit* section above; pipx |
| **SSH'd-into remote dev VM** (cloud workstation, beefier hardware than laptop) | `infra/byo-vps.md` | Same as localhost — `aider-install` works inside the SSH session; cd into the cloned repo |
| **CI runner** (GitHub Actions, GitLab CI, etc.) | (out of CI scope for open-forge) | `pip install aider-chat` in a Python action; run `aider --message "..." --yes` for non-interactive |
| **Docker on any host** | `runtimes/docker.md` | `paulgauthier/aider` or `paulgauthier/aider-full` |

For **always-on cloud dev environments** (where the dev SSH's into a beefier remote box for pair programming), the AWS / Hetzner / DO / GCP infra adapters under `references/infra/` all work — same `aider-install` flow inside the SSH session as on localhost. open-forge's adapters take care of the VM provisioning; Aider install is one curl-pipe away after that.

---

## Verification before marking `provision` done

- `aider --version` prints a version string from any directory.
- `aider --models` lists available models (confirms LiteLLM is wired up).
- `cd <test-repo> && aider --help` shows usage without errors (confirms PATH + Python env).
- Round-trip: `cd <test-repo> && aider --model <provider>` opens the chat prompt; type `/help` and verify it responds; type `/exit`.
- (If using a remote LLM) Confirm one real prompt → diff → commit cycle on a throwaway file. The first real chat exercises the provider API key, the model selection, the diff parser, and `git commit` integration in one shot.
- (Docker) `docker run --rm -it paulgauthier/aider --version` returns the same version string.
- (Optional extras enabled) `aider --voice` opens the microphone prompt without ImportError; `aider --browser` opens Streamlit on the default port.

---

## Consolidated gotchas

Universal:

- **Python version pin (3.9–3.12 for pipx/pip; 3.12 baked-in for `aider-install`).** System Python 3.13+ on bleeding-edge distros (Fedora 41, Arch) breaks `pip install aider-chat`. Use `aider-install` or the one-liner script in those cases.
- **API keys go in `~/.env` or `<repo>/.env`, not in `~/.aider.conf.yml`.** Keeps secrets out of repo-mounted config that users sometimes commit by mistake.
- **`.aiderignore` is the safety boundary.** Without it, Aider can edit any tracked file the LLM thinks is relevant. Always set up before letting Aider near critical files (`package-lock.json`, terraform state, etc.).
- **Aider auto-commits per change by default.** Surprise-friendly for some users (clean history); annoying for others (interrupts manual rebasing). Toggle via `--no-auto-commits` or `auto_commits: false` in `.aider.conf.yml`.
- **Chat history is written to `<repo>/.aider.chat.history.md`.** Sensitive prompts persist there. `.gitignore` it; rotate / clear on a schedule for multi-user repos.
- **System package managers (`apt install aider`, `brew install aider`, etc.) are explicitly discouraged by upstream** — install dependencies wrong. Always prefer `aider-install`, uv, or pipx.
- **Docker `--user $(id -u):$(id -g)`** is mandatory for clean file ownership on the bind mount.
- **Two models per session** (strong + weak) — pick a sensible pair, not just one. Default pairs (Sonnet+Haiku, GPT-4o+GPT-4o-mini) are correct.

Per-method gotchas live alongside each section above:

- **Native install** — see *Native-install gotchas*.
- **Docker** — see *Docker-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.
- **Codespaces** — see *Codespaces-specific gotchas*.
- **Replit** — see *Replit-specific gotchas*.

---

## TODO — verify on subsequent deployments

- **First end-to-end `aider-install` on Linux + macOS** — verify the isolated Python 3.12 provisioning, the binary-on-PATH placement, and the upgrade path (re-running `aider-install`).
- **One-liner uv installer on all three OSes** — verify Mac/Linux `curl | sh` + Windows `irm | iex` paths; verify the `wget` fallback on systems without curl.
- **uv direct install** — verify `uv tool install aider-chat` against the latest `uv` release; verify `uv tool upgrade` works.
- **pipx install** — verify against `pipx ensurepath` clean-shell behavior; verify `pipx upgrade aider-chat` cleanly.
- **plain pip in a venv** — verify the `--upgrade-strategy only-if-needed` flag actually preserves stable deps.
- **Docker core + full** — verify both images on a real LLM provider; verify the per-container reinstall behavior of optional extras for `paulgauthier/aider`; verify `--user` UID-mapping on macOS (where Docker Desktop's UID semantics differ).
- **Codespaces** end-to-end — verify the Codespace-secrets auto-population pattern; verify `.devcontainer.json` `postCreateCommand` install.
- **Replit** end-to-end — verify the Replit Secrets pattern; verify pipx works on Replit's Nix env.
- **Composing with Ollama** locally — verify `ollama_chat/<model>` provider name + the `OLLAMA_API_BASE` env-var format. Pair with a coding-tuned model (`qwen2.5-coder:32b`, `deepseek-coder-v2`).
- **Composing with Open WebUI / LibreChat / AnythingLLM** as upstream routers — verify the `--openai-api-base http://<host>:<port>/v1` + per-user API key flow; check whether the consumer's auth + model permissions propagate as expected.
- **Optional extras install paths** (Voice / Browser / Playwright) — never validated. Test on Linux + macOS; document OS-level dep gotchas (`portaudio19-dev`, etc.).
- **`aider --message ... --yes` non-interactive runs in CI** — verify the exit-code semantics (non-zero on any failure?), the chat-history-file location in ephemeral runners.
- **`.aiderignore` enforcement** — verify Aider respects it for both implicit context-gathering (the tag graph) and explicit `/add` (which docs say bypasses it).
- **Chat-history rotation / clearing** — document the procedure for multi-user repos (chat history accumulates across sessions; multiple devs see each other's prompts).
- **Auto-commit attribution** — verify the commit author / committer fields when Aider commits; document how to override (`AIDER_GIT_COMMIT_AUTHOR=...` if it exists).
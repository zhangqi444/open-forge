# GitButler

Modern Git client and version control interface built for AI-powered and parallel development workflows. GitButler lets you work on multiple branches simultaneously, stack branches, reorder commits without interactive rebase, and integrates with forges (GitHub, GitLab, Gitea). Features a desktop GUI (Tauri/Svelte) and a `but` CLI. Built on Rust. Upstream: <https://github.com/gitbutlerapp/gitbutler>. Docs: <https://docs.gitbutler.com>.

> **Note:** GitButler is a **desktop application** — it runs on your local machine and connects to any Git remote (GitHub, GitLab, self-hosted Gitea, etc.). There is no self-hosted server component. "Self-hosted" here means the app is free/open-source and you own your Git data.

## Compatible install methods

Verified against upstream docs at <https://gitbutler.com/downloads>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Desktop download (macOS/Windows/Linux) | <https://gitbutler.com/downloads> | ✅ | Primary install. Binaries for all platforms. |
| Homebrew (macOS/Linux) | `brew install --cask gitbutler` | Community (Homebrew Cask) | macOS / Linux desktop. |
| Build from source | <https://github.com/gitbutlerapp/gitbutler#development> | ✅ | Developers or cutting-edge builds. |

## Inputs to collect

No server inputs — GitButler is a local desktop app. It connects to Git remotes using your existing Git credentials (SSH keys, HTTPS tokens, etc.).

## Software-layer concerns

### Core concepts

GitButler replaces the traditional Git branch workflow with **virtual branches**:

- You can have multiple "lanes" of changes open simultaneously without stashing or committing incomplete work.
- Changes are tracked virtually and pushed to real Git branches on push.
- **Stacked branches**: stack multiple dependent branches on top of each other and push them as a PR series.
- **Commit mutations**: squash, reorder, amend commits with drag-and-drop.

### CLI (`but`)

GitButler ships a `but` CLI alongside the desktop app:

```bash
# Show help
but --help

# List virtual branches
but branch list

# Push all virtual branches
but branch push
```

The CLI is useful for scripting, CI hooks, and AI agent integrations.

### AI/agent integration

GitButler has agent hooks and MCP server support, allowing AI coding agents (Cursor, Claude Code, etc.) to manage branches and commits through GitButler instead of raw Git.

### Forge integrations

GitButler integrates with:
- **GitHub** — Create PRs, stacked PRs, view CI status
- **GitLab** — MR creation
- **Gitea / Forgejo** — Self-hosted Git forgejo support

Configure under Settings → Forge in the desktop app.

### Data directories

| Path | Contents |
|---|---|
| Project's `.git/` | Standard Git objects, GitButler virtual branch metadata stored in `refs/gitbutler/` |
| `~/.gitbutler/` | App config, telemetry opt-out, preferences |

GitButler stores its virtual branch state inside the Git repository itself — no external database.

## Upgrade procedure

- **Desktop app:** Built-in auto-updater. Or download the latest from <https://gitbutler.com/downloads>.
- **Homebrew:** `brew upgrade --cask gitbutler`
- **Source:** `git pull && cargo build --release`

## Gotchas

- **Not a Git replacement — a Git enhancer.** GitButler works *on top of* Git. Your repo is still a standard Git repo and works with all standard tooling.
- **Virtual branches vs. real branches.** Virtual branches are GitButler's concept. They get pushed as real branches when you push/create PRs.
- **Unstaged-by-default model.** GitButler auto-assigns uncommitted file changes to virtual branches based on file ownership. This can feel surprising if you're used to the Git staging area.
- **Desktop app only — no headless server mode.** GitButler cannot run as a background service waiting for commits. The GUI or CLI must be run interactively.
- **License: FSL (Functional Source License).** GitButler uses the FSL, which converts to Apache 2.0 after 2 years. It is source-available but not OSI-approved open-source today.

## Links

- Upstream: <https://github.com/gitbutlerapp/gitbutler>
- Website: <https://gitbutler.com>
- Docs: <https://docs.gitbutler.com>
- Downloads: <https://gitbutler.com/downloads>
- Blog: <https://blog.gitbutler.com>

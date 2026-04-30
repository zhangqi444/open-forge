# Using open-forge with OpenAI Codex

Codex (the OpenAI coding agent in ChatGPT and the open-source Codex CLI) can ingest open-forge as a system-prompt extension or a workspace-level instruction set. open-forge becomes a deployment runbook Codex follows whenever the user asks to self-host something.

> **Best-effort:** Codex doesn't have Claude Code's plugin auto-loading. The user must load the open-forge content explicitly (as a system prompt, in workspace files, or by referencing the cloned repo). Once loaded, Codex uses it the same way Claude Code does.

## Install

Two paths, pick one:

### Option A — system-prompt embedding (ChatGPT Codex with custom instructions)

1. Generate a paste-ready system prompt:

   ```bash
   git clone https://github.com/zhangqi444/open-forge
   cd open-forge
   ./scripts/build-dist.sh codex
   # Outputs: dist/codex/system-prompt.md
   ```

2. Open ChatGPT → **Settings** → **Personalization** → **Custom Instructions** → paste `dist/codex/system-prompt.md` into the *"How would you like ChatGPT to respond?"* box.

3. (Optional) Set a context-window-friendly slimmer version: `./scripts/build-dist.sh codex --slim` produces `dist/codex/system-prompt-slim.md` with just the architectural skeleton.

### Option B — workspace files (Codex CLI)

1. Clone `open-forge` into your project's parent directory:

   ```bash
   git clone https://github.com/zhangqi444/open-forge ../open-forge
   ```

2. When invoking Codex CLI, point it at the open-forge content:

   ```bash
   codex --include-files ../open-forge/CLAUDE.md \
         --include-files ../open-forge/plugins/open-forge/skills/open-forge/SKILL.md \
         --include-dir ../open-forge/plugins/open-forge/skills/open-forge/references/
   ```

   Or use Codex's project-level config (`.codex/config.toml` if available in your version).

## Invoke

Once loaded, just ask in natural language:

> *"Self-host OpenClaw on AWS Lightsail with Bedrock pre-wired."*

Codex will recognize the deploy intent, look up the recipe in the loaded content, and follow the phased workflow.

If Codex doesn't auto-trigger, prompt explicitly:

> *"Follow the open-forge skill instructions to self-host OpenClaw on AWS Lightsail."*

## Tool translation

| open-forge concept (Claude Code term) | Codex equivalent |
|---|---|
| `AskUserQuestion` (structured choice) | Codex asks a multi-line question with bulleted options; user replies free-text |
| `WebFetch` (read upstream docs) | Codex's `web_search` / `fetch_url` tool, depending on Codex variant |
| `mcp__github__issue_write` (post feedback issue) | Codex shells out to `gh issue create` (preferred) or prints a prefilled URL for the user to open |
| Persistent state file (`~/.open-forge/deployments/<name>.yaml`) | Same path; Codex reads/writes via filesystem tool. Resume across sessions works if the user keeps the workspace open or re-loads the file at session start. |

## Limitations

- **No auto-trigger.** Claude Code triggers the skill from the description-match. Codex needs an explicit prompt referencing self-hosting.
- **State-file resume** depends on Codex retaining file context across sessions. Re-loading the YAML at the start of a new conversation is reliable; auto-discovery is not.
- **Tool-name fidelity** varies. Codex's tool surface differs from Claude Code's (e.g. no `AskUserQuestion`); the agent improvises but may produce less consistent UX.
- **Issue-posting via the GitHub MCP server** isn't available in Codex; fall back to `gh` CLI or prefilled-URL paths per `references/modules/feedback.md`.

## Example session

```
User: Self-host Vaultwarden on a Hetzner CX22.

Codex: I'll follow the open-forge recipe at references/projects/vaultwarden.md.

       Combo: Hetzner Cloud CX × Docker.
       Phases I'll run: preflight → provision → dns → tls → smtp → hardening.

       For preflight, I need:
         - Hetzner API token (file path / env var name / paste — see credential
           handling rules in CLAUDE.md § Credential handling)
         - Domain you want to use

User: token at ~/.secrets/hcloud, domain vault.example.com

Codex: [Reads ~/.secrets/hcloud via shell tool]
       [Runs hcloud server create ...]
       ...
```

## Reporting issues / contributing

Same as for Claude Code — file a [GitHub issue](https://github.com/zhangqi444/open-forge/issues/new/choose) using the templates. The skill drafts feedback automatically; for Codex you can ask:

> *"Draft a recipe-feedback issue for this deployment per references/modules/feedback.md."*

Codex will produce the sanitized draft; you review + post via `gh issue create` or browser.

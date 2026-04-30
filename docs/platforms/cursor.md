# Using open-forge with Cursor

Cursor's `.cursor/rules/` directory holds Markdown rule files the IDE auto-loads into the AI context. open-forge's recipes + modules drop straight in.

## Install

Two paths, pick one:

### Option A — drop into your project (per-project)

1. Clone open-forge alongside your project:

   ```bash
   git clone https://github.com/zhangqi444/open-forge ~/code/open-forge
   ```

2. Generate the Cursor-flavored rules bundle:

   ```bash
   cd ~/code/open-forge
   ./scripts/build-dist.sh cursor
   # Outputs: dist/cursor/*.mdc
   ```

3. Copy the bundle into your project's Cursor rules directory:

   ```bash
   mkdir -p /path/to/your/project/.cursor/rules/
   cp dist/cursor/*.mdc /path/to/your/project/.cursor/rules/
   ```

   Restart Cursor or run **Cmd+Shift+P** → **Reload Window**.

### Option B — global rules (all projects)

For Cursor's User Rules (apply to all projects):

1. Open Cursor → **Settings** → **General** → **Rules for AI**.
2. Paste the contents of `dist/cursor/00-skill.mdc` (or `dist/cursor/00-skill-slim.mdc` for a context-friendly version) into the *Rules for AI* text area.
3. Save. Now any Cursor session in any project knows about open-forge.

## File layout

`dist/cursor/` contains:

- `00-skill.mdc` — top-level invocation rule (always-loaded)
- `01-credentials.mdc` — credential-handling patterns (loaded when sensitive input is involved)
- `02-feedback.mdc` — post-deploy feedback flow
- `10-projects-<software>.mdc` — per-software recipes (loaded contextually)
- `20-infra-<cloud>.mdc` — per-infra adapters
- `30-runtimes-<runtime>.mdc` — runtime modules

Each `.mdc` file has Cursor's frontmatter for scoping:

```yaml
---
description: open-forge skill — self-host any open-source app on your own infrastructure
globs: ["**/*.md", "**/Dockerfile*", "**/docker-compose*.yml"]
alwaysApply: true
---
```

## Invoke

Cursor auto-loads always-applied rules into context. Just ask:

> *"Self-host OpenClaw on AWS Lightsail with Bedrock pre-wired."*

If you want the skill to drive an agentic flow (multi-step), use **Composer** mode (Cmd+I) and ask the deploy question — Cursor's agent will follow the phased workflow.

## Tool translation

| open-forge concept | Cursor equivalent |
|---|---|
| `AskUserQuestion` (structured choice) | Cursor prompts in chat with bulleted options; user types reply or clicks suggestion |
| `WebFetch` | Cursor's `@Web` context provider or built-in browse tool |
| `mcp__github__issue_write` | Cursor agent runs `gh issue create` via terminal tool (preferred) or prints prefilled URL |
| Persistent state file | Same path (`~/.open-forge/deployments/<name>.yaml`); Cursor reads/writes via filesystem tool. Composer mode keeps state across the session. |

## Limitations

- **Composer mode required for autonomous multi-step deploys.** Single-question chat works for one-shot tasks but won't handle the phased workflow as cleanly.
- **`@` mentions** for context loading work — `@Codebase` finds recipes; `@File` references specific recipe files.
- **Always-apply vs auto-apply globs.** The `00-skill.mdc` rule sets `alwaysApply: true` so it loads everywhere. Per-recipe rules use globs to load contextually (e.g. only when working with Compose files).

## Example session (Composer mode)

```
User (Cmd+I): Self-host Vaultwarden on a Hetzner CX22 with Cloudflare for DNS.

Cursor: Loading recipe references/projects/vaultwarden.md and infra
        adapter references/infra/hetzner/cloud-cx.md from open-forge.

        Phases I'll run:
          1. preflight — verify hcloud CLI is installed + authenticated
          2. provision — create CX22 server, allocate floating IP
          3. dns — print A-records for you to add at Cloudflare
          4. tls — Let's Encrypt cert via the Caddy reverse proxy
          5. smtp — Vaultwarden's email config
          6. hardening — rotate the admin token

        For preflight: do you have an hcloud API token in a file or
        env var? (per credentials.md, paste is last-resort)
```

## Reporting issues / contributing

Same as Claude Code — [GitHub issue templates](https://github.com/zhangqi444/open-forge/issues/new/choose). Cursor agents can run `gh issue create` directly via the terminal tool, so the post-deploy feedback flow works end-to-end.

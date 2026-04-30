# Using open-forge with any AI agent

For platforms not covered by a dedicated guide (Anthropic API direct, OpenAI Assistants, custom LangChain / AutoGen / smolagents agents, self-built tools-using LLMs, etc.), this is the platform-neutral integration guide. open-forge is fundamentally a library of platform-agnostic markdown — any agent that can read text and execute shell commands can use it.

## Install

1. Clone the repo into a path your agent can read:

   ```bash
   git clone https://github.com/zhangqi444/open-forge ~/code/open-forge
   ```

2. Generate the single-file generic bundle (or use the canonical files directly):

   ```bash
   cd ~/code/open-forge
   ./scripts/build-dist.sh generic
   # Outputs: dist/generic/open-forge-bundle.md
   ```

   The bundle concatenates SKILL.md + CLAUDE.md + the credential & feedback modules + a recipe index. Suitable for pasting into a system prompt or feeding as a single document to any agent.

3. (Alternative) Point your agent at the canonical paths:

   ```
   System prompt:
     Follow the instructions at the following paths:
       - ~/code/open-forge/CLAUDE.md
       - ~/code/open-forge/plugins/open-forge/skills/open-forge/SKILL.md
       - ~/code/open-forge/plugins/open-forge/skills/open-forge/references/modules/credentials.md
       - ~/code/open-forge/plugins/open-forge/skills/open-forge/references/modules/feedback.md

     For per-deploy recipes, look up:
       ~/code/open-forge/plugins/open-forge/skills/open-forge/references/projects/<software>.md
       ~/code/open-forge/plugins/open-forge/skills/open-forge/references/infra/<cloud>/<service>.md
       ~/code/open-forge/plugins/open-forge/skills/open-forge/references/runtimes/<runtime>.md
   ```

## What your agent needs to support

open-forge expects an agent with the following capabilities:

| Capability | Required | Notes |
|---|---|---|
| Read local text files | ✅ Yes | Recipes are markdown; agent must be able to load them on demand |
| Execute shell commands | ✅ Yes | Skill orchestrates `aws`, `ssh`, `docker`, `kubectl`, etc. |
| Ask the user structured questions | ⚠️ Helpful | If your agent doesn't have first-class structured choice (Claude Code's `AskUserQuestion`), the agent asks in prose with options listed. Less polished but works. |
| Fetch URLs | ⚠️ Recommended | For Tier 2 deploys (live-derived from upstream docs). If unavailable, user pastes upstream content into chat. |
| Persistent file storage between sessions | ⚠️ Recommended | For state-file resume (`~/.open-forge/deployments/<name>.yaml`). If unavailable, user re-loads the YAML at the start of each session. |
| Run `gh issue create` (or similar GitHub integration) | ⚠️ Recommended | For the post-deploy feedback flow. If unavailable, fall back to the prefilled-URL path per `references/modules/feedback.md`. |

If your agent has all five, the experience matches Claude Code's. If it has only the required two (read files + run shell), open-forge still works — just more prose-heavy interaction.

## Tool translation

The open-forge content uses Claude Code-specific tool names in some places (mostly historical). Translate as you load:

| Claude Code term | Generic capability | Your agent's tool |
|---|---|---|
| `AskUserQuestion` | "Ask user for one of N choices" | (your platform's structured-prompt API, if any; otherwise prose) |
| `WebFetch` | "Fetch URL content" | (your fetch / browse tool) |
| `mcp__github__*` | "GitHub API" | `gh` CLI shell-out, or the GitHub MCP server, or the GitHub REST API directly |
| State file at `~/.open-forge/deployments/<name>.yaml` | Persistent JSON/YAML store | (filesystem, if available; otherwise inline in chat history) |

Phase 2 of the multi-platform support effort genericizes these references in SKILL.md itself. Until then, treat Claude Code-specific tool names as descriptive of the *capability needed*, not the literal tool to call.

## Invocation pattern

Once the content is loaded into your agent's context, the user's prompt should look like:

> *"Self-host OpenClaw on AWS Lightsail with Bedrock pre-wired."*

The agent should:

1. Look up `references/projects/openclaw.md` for the recipe.
2. Look up `references/infra/aws/lightsail.md` for the infra adapter.
3. Note the runtime is bundled (vendor blueprint) so no separate runtime module needed.
4. Run preflight from `references/modules/preflight.md`.
5. Walk through phases per SKILL.md § Phased workflow, asking the user only what's genuinely needed.
6. Apply credential-handling patterns from `references/modules/credentials.md` for any sensitive input.
7. After `hardening`, offer the post-deploy feedback flow per `references/modules/feedback.md`.

If the user's request doesn't match a verified recipe, fall back to **Tier 2** (live-derived) per CLAUDE.md § Two-tier coverage model.

## Limitations

- **No auto-trigger.** Generic agents don't auto-load open-forge on intent — the user explicitly invokes it. For best UX, set up a slash command or alias.
- **Tool-name fidelity** depends entirely on what your agent supports. The skill is designed to degrade gracefully (prose questions if no structured prompts; user-pasted upstream content if no fetch tool), but the experience varies.
- **State-file resume** depends on persistent file storage. Stateless agents (one prompt = one session) need the user to save and re-load the state file manually.
- **Issue-posting** for the feedback loop needs *some* way to call GitHub. `gh` CLI is the most portable; a prefilled URL works as an always-available fallback.

## Example session (any tools-using LLM)

```
User: I want to self-host Vaultwarden on a Hetzner CX22.

Agent: I'm following the open-forge skill at
       ~/code/open-forge/plugins/open-forge/skills/open-forge/SKILL.md.

       [reads SKILL.md + references/projects/vaultwarden.md +
        references/infra/hetzner/cloud-cx.md]

       Combo: Hetzner Cloud CX × Docker.
       I'll run preflight → provision → dns → tls → smtp → hardening →
       feedback.

       Preflight: do you have your Hetzner API token in a file or env
       var? (Per references/modules/credentials.md, paste is last
       resort.)

User: env var HCLOUD_TOKEN

Agent: [verifies $HCLOUD_TOKEN is set]
       [runs hcloud server create ...]
       ...
```

## Reporting issues / contributing

The post-deploy feedback flow asks the user to opt into a GitHub issue. Most agents will end up using the prefilled-URL path:

```
https://github.com/zhangqi444/open-forge/issues/new?template=recipe-feedback.yml&title=...&body=...
```

The user reviews the redacted draft in chat, then opens the URL in a browser to submit. See `references/modules/feedback.md` § Submission paths for the full hierarchy.

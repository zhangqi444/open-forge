# Using open-forge with Continue.dev

Continue.dev is an open-source IDE assistant (VS Code, JetBrains). It supports custom commands, context providers, and prompt libraries — open-forge plugs into all three.

## Install

1. Clone open-forge:

   ```bash
   git clone https://github.com/zhangqi444/open-forge ~/code/open-forge
   ```

2. Generate the Continue-flavored config:

   ```bash
   cd ~/code/open-forge
   ./scripts/build-dist.sh continue
   # Outputs:
   #   dist/continue/config.snippet.yaml   (paste into your continue config)
   #   dist/continue/prompts/*.md          (per-recipe prompt files)
   ```

3. Merge `dist/continue/config.snippet.yaml` into your `~/.continue/config.yaml`:

   ```yaml
   # ~/.continue/config.yaml
   contextProviders:
     - name: file
       params:
         baseDir: ~/code/open-forge/plugins/open-forge/skills/open-forge

   prompts:
     - name: self-host
       description: "Deploy a self-hostable app via open-forge recipes"
       systemMessage: |
         You are an expert at deploying self-hostable open-source apps. Follow the
         open-forge skill at ~/code/open-forge/plugins/open-forge/skills/open-forge/SKILL.md.
         Use the recipe under references/projects/ that matches the user's request;
         if no recipe exists, follow the Tier 2 (live-derived) fallback per CLAUDE.md.

   slashCommands:
     - name: deploy
       description: "Self-host an open-source app"
       prompt: "self-host"
   ```

4. Reload Continue (Cmd+Shift+P → **Developer: Reload Window**).

## Invoke

Use the slash command in Continue's chat:

> `/deploy Self-host OpenClaw on AWS Lightsail with Bedrock pre-wired.`

Or invoke the prompt by name:

> `@self-host Self-host Vaultwarden on a Hetzner CX22.`

You can also reference specific recipes via `@file`:

> `@file references/projects/openclaw.md @file references/infra/aws/lightsail.md Now follow the recipe.`

## Tool translation

| open-forge concept | Continue equivalent |
|---|---|
| `AskUserQuestion` (structured choice) | Continue's chat doesn't have first-class structured prompts; agent asks in prose with options listed |
| `WebFetch` | Continue's `@URL` context provider — paste a URL, agent reads the content |
| `mcp__github__issue_write` | Continue's terminal context provider can run `gh issue create`; or use the prefilled-URL fallback |
| Persistent state file | Filesystem operations work via Continue's tool-use (when enabled in config) |

## Limitations

- **Tool-use (agent mode) varies by model.** Continue's tool-use is model-dependent; Claude / GPT-4 work well, smaller models may struggle with the multi-step phased workflow.
- **No auto-trigger on description match.** Continue uses explicit slash commands or `@` mentions; the open-forge skill description is informational, not a trigger.
- **Context provider scoping.** The `file` provider above loads the entire `references/` tree; for large catalogs consider per-recipe context providers (`@file references/projects/<name>.md`) to keep context tight.

## Example session

```
User: /deploy Self-host Vaultwarden on a Hetzner CX22.

Continue: Loading the recipe at references/projects/vaultwarden.md and
          infra adapter references/infra/hetzner/cloud-cx.md from the
          file context provider.

          Combo: Hetzner Cloud CX × Docker.
          Phases: preflight → provision → dns → tls → smtp → hardening
          → feedback.

          For preflight, I need your Hetzner API token. Three safer
          paths (per references/modules/credentials.md):
            1. File path (e.g. ~/.secrets/hcloud)
            2. Env var name (e.g. HCLOUD_TOKEN)
            3. Paste — last resort, will need to rotate after deploy

User: 2, HCLOUD_TOKEN
Continue: [reads $HCLOUD_TOKEN via terminal tool]
          [runs hcloud server create ...]
          ...
```

## Reporting issues / contributing

Continue's terminal context provider can run `gh issue create` for posting feedback. Or use the prefilled-URL fallback per `references/modules/feedback.md` § Submission paths.

# Using open-forge with Aider

Aider is terminal-based AI pair programming. It's already in the open-forge catalog as a deployable target — and it can also be used as the *agent* that drives an open-forge deploy. Aider can `--read` files into context and follow `CONVENTIONS.md`-style guidance.

## Install

1. Clone open-forge:

   ```bash
   git clone https://github.com/zhangqi444/open-forge ~/code/open-forge
   ```

2. Generate the Aider-flavored bundle:

   ```bash
   cd ~/code/open-forge
   ./scripts/build-dist.sh aider
   # Outputs:
   #   dist/aider/CONVENTIONS.md         (concatenated SKILL.md + CLAUDE.md core)
   #   dist/aider/read-files.txt         (one-per-line file paths to --read)
   #   dist/aider/.aider.conf.yml        (drop-in config)
   ```

## Invoke

### One-shot (recommended for a single deploy)

```bash
aider --message "Self-host OpenClaw on a Hetzner CX22" \
      --read ~/code/open-forge/dist/aider/CONVENTIONS.md \
      $(cat ~/code/open-forge/dist/aider/read-files.txt | xargs -I{} echo "--read {}")
```

### Project-level (recurring deploys to the same target)

Drop `dist/aider/.aider.conf.yml` into your project root:

```yaml
# .aider.conf.yml
read:
  - ~/code/open-forge/CLAUDE.md
  - ~/code/open-forge/plugins/open-forge/skills/open-forge/SKILL.md
  - ~/code/open-forge/plugins/open-forge/skills/open-forge/references/modules/credentials.md
  - ~/code/open-forge/plugins/open-forge/skills/open-forge/references/modules/feedback.md

auto-commits: false      # open-forge state files shouldn't be auto-committed
```

Then `aider` in that project loads open-forge automatically.

### Conventions file

Aider auto-loads `CONVENTIONS.md` from the project root. The bundle's `CONVENTIONS.md` distills SKILL.md + CLAUDE.md into Aider's preferred format:

```bash
cp ~/code/open-forge/dist/aider/CONVENTIONS.md /path/to/your/project/
```

## Tool translation

| open-forge concept | Aider equivalent |
|---|---|
| `AskUserQuestion` (structured choice) | Aider asks via chat with bulleted options; user replies in terminal |
| `WebFetch` | Aider doesn't have a native fetch tool; user pastes upstream doc content, or `aider` shells out to `curl` via the `/run` command |
| `mcp__github__issue_write` | Aider's `/run gh issue create ...` — works if `gh` is authenticated locally |
| Persistent state file | Same path; Aider operates on the file directly via its filesystem ops |

## Limitations

- **No native browser/fetch.** For Tier 2 deploys (live-derived from upstream docs), Aider can't fetch upstream pages on its own. Either (a) clone the relevant docs repo locally and `--read` the files, or (b) the user pastes upstream content into chat for Aider to use.
- **Recipe loading is per-invocation.** Unlike Claude Code's auto-load on intent, Aider's `--read` is explicit. The `read-files.txt` approach loads everything; for large catalogs this fills context. Use per-recipe `--read` for tighter context.
- **No structured `AskUserQuestion`.** Aider's chat interface is plain text; the agent will phrase questions as prose with options listed.

## Example session

```bash
$ aider --message "Self-host OpenClaw on a Hetzner CX22 with Bedrock" \
        --read ~/code/open-forge/dist/aider/CONVENTIONS.md \
        --read ~/code/open-forge/plugins/open-forge/skills/open-forge/references/projects/openclaw.md \
        --read ~/code/open-forge/plugins/open-forge/skills/open-forge/references/infra/hetzner/cloud-cx.md \
        --read ~/code/open-forge/plugins/open-forge/skills/open-forge/references/runtimes/docker.md

aider> Following the open-forge skill flow.

       Combo: Hetzner Cloud CX × Docker (OpenClaw via the AWS Lightsail
       blueprint isn't available on Hetzner — falling back to Docker
       runtime + manual Bedrock IAM, see openclaw.md § AWS EC2 setup
       for the IAM script).

       For preflight: do you have your Hetzner API token in a file
       or env var? (per credentials.md, paste is last-resort)

User> hcloud token at ~/.config/hcloud/token

aider> /run cat ~/.config/hcloud/token | head -c 20
       [reads token, never echoes it back]
       /run hcloud server create --type cx22 --image ubuntu-24.04 ...
       ...
```

## Reporting issues / contributing

Use Aider's `/run gh issue create ...` to file recipe-feedback issues per the open-forge templates. The skill's drafted issue body can be passed via `--body-file`.

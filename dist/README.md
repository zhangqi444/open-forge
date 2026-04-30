# dist/ — platform-specific distribution bundles

Auto-generated bundles for AI coding tools other than Claude Code. Each subdirectory packages the open-forge skill in the format that platform expects.

| Subdirectory | What's in it | Used by |
|---|---|---|
| `codex/` | `system-prompt.md` (full) + `system-prompt-slim.md` (lightweight) | Codex (ChatGPT custom instructions; Codex CLI workspace files) |
| `cursor/` | `.mdc` rule files with Cursor frontmatter | Cursor's `.cursor/rules/` |
| `aider/` | `CONVENTIONS.md` + `read-files.txt` + `.aider.conf.yml` | Aider |
| `continue/` | `config.snippet.yaml` | Continue.dev's `~/.continue/config.yaml` |
| `generic/` | `open-forge-bundle.md` (single-file concatenation) | Any LLM agent with tool use |

## Regenerate after upstream changes

The bundles are concatenations of the canonical content (`CLAUDE.md`, `plugins/open-forge/skills/open-forge/SKILL.md`, `references/modules/credentials.md`, `references/modules/feedback.md`). When those change, regenerate via:

```bash
./scripts/build-dist.sh all       # all five platforms
./scripts/build-dist.sh codex     # just one
```

Run from the repo root.

## Per-platform usage

See [`docs/platforms/`](../docs/platforms/) — one guide per platform with install instructions, tool translations, limitations, and example sessions.

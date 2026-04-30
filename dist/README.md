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

### Who runs this?

| Actor | When |
|---|---|
| **AI coding session processing an issue** (per [CLAUDE.md § Processing incoming issues](../CLAUDE.md#processing-incoming-issues)) | Whenever a patch touches `CLAUDE.md` / `SKILL.md` / `references/modules/{credentials,feedback}.md`. Required step in `### 3. Author the patch`. |
| **Maintainer** (manual edits) | Same trigger — if you hand-edit a canonical source, regenerate before opening the PR. |
| **CI** (safety net) | [`.github/workflows/dist-bundles.yml`](../.github/workflows/dist-bundles.yml) runs the build script on every PR and fails if `dist/` is stale. Catches both bot- and human-authored PRs that forgot to regenerate. |

If you see a CI failure on `dist-bundles-up-to-date`, the fix is always: run `./scripts/build-dist.sh all` from the repo root, commit the changes, push.

## Per-platform usage

See [`docs/platforms/`](../docs/platforms/) — one guide per platform with install instructions, tool translations, limitations, and example sessions.

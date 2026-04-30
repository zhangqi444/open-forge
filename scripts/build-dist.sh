#!/usr/bin/env bash
# build-dist.sh — generate platform-specific distribution bundles from canonical sources.
#
# Usage:
#   ./scripts/build-dist.sh <platform>
#
# Platforms:
#   codex      — system-prompt for ChatGPT Codex / Codex CLI
#   cursor     — .mdc rule files for .cursor/rules/
#   aider      — CONVENTIONS.md + read-files.txt + .aider.conf.yml
#   continue   — config snippet + per-recipe prompt files for Continue.dev
#   generic    — single-file concatenated bundle for any tools-using LLM
#   all        — run all of the above
#
# Output: dist/<platform>/* (gitignored except the build script itself)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$REPO_ROOT/plugins/open-forge/skills/open-forge"
REFS_DIR="$SKILL_DIR/references"
DIST_DIR="$REPO_ROOT/dist"

usage() {
  grep '^#' "$0" | grep -v '^#!' | sed 's/^# \{0,1\}//'
  exit 1
}

[[ $# -lt 1 ]] && usage

PLATFORM="$1"

build_codex() {
  echo "→ Building Codex bundle…"
  mkdir -p "$DIST_DIR/codex"

  cat > "$DIST_DIR/codex/system-prompt.md" <<EOF
# open-forge skill (Codex system prompt)

You are an expert at deploying self-hostable open-source apps. You operate as the open-forge skill — see the canonical content below.

When the user asks to self-host a service, follow the phased workflow (preflight → provision → dns → tls → smtp → inbound → hardening → feedback) defined in SKILL.md. Look up the matching recipe in references/projects/<software>.md and the matching infra adapter in references/infra/<cloud>/<service>.md.

If no recipe matches, fall back to Tier 2 (live-derived) per CLAUDE.md § Two-tier coverage model.

Tool names like AskUserQuestion / WebFetch / mcp__github__* are Claude Code-specific — use Codex's equivalents (prose questions with options listed; web_search / fetch_url; gh CLI shell-out).

For credential collection, follow references/modules/credentials.md — five patterns prioritized from "secret never enters chat" to "last-resort paste with risk acknowledgement."

After hardening, offer the post-deploy feedback flow per references/modules/feedback.md.

---

EOF
  cat "$REPO_ROOT/CLAUDE.md" >> "$DIST_DIR/codex/system-prompt.md"
  echo -e "\n\n---\n" >> "$DIST_DIR/codex/system-prompt.md"
  cat "$SKILL_DIR/SKILL.md" >> "$DIST_DIR/codex/system-prompt.md"
  echo -e "\n\n---\n" >> "$DIST_DIR/codex/system-prompt.md"
  cat "$REFS_DIR/modules/credentials.md" >> "$DIST_DIR/codex/system-prompt.md"
  echo -e "\n\n---\n" >> "$DIST_DIR/codex/system-prompt.md"
  cat "$REFS_DIR/modules/feedback.md" >> "$DIST_DIR/codex/system-prompt.md"

  # Slim version: just SKILL.md + credentials, no per-recipe content
  cat > "$DIST_DIR/codex/system-prompt-slim.md" <<EOF
# open-forge skill (slim Codex system prompt)

When the user asks to self-host a service, look up the matching recipe at:
  https://github.com/zhangqi444/open-forge/tree/main/plugins/open-forge/skills/open-forge/references/projects/<software>.md

Follow the phased workflow + credential-handling patterns below. Tool names are Claude Code's; use Codex equivalents.

---

EOF
  cat "$SKILL_DIR/SKILL.md" >> "$DIST_DIR/codex/system-prompt-slim.md"
  echo -e "\n\n---\n" >> "$DIST_DIR/codex/system-prompt-slim.md"
  cat "$REFS_DIR/modules/credentials.md" >> "$DIST_DIR/codex/system-prompt-slim.md"

  echo "  ✓ dist/codex/system-prompt.md ($(wc -l < "$DIST_DIR/codex/system-prompt.md") lines)"
  echo "  ✓ dist/codex/system-prompt-slim.md ($(wc -l < "$DIST_DIR/codex/system-prompt-slim.md") lines)"
}

build_cursor() {
  echo "→ Building Cursor bundle…"
  mkdir -p "$DIST_DIR/cursor"

  # Top-level skill rule (always-applied)
  cat > "$DIST_DIR/cursor/00-skill.mdc" <<EOF
---
description: open-forge skill — self-host any open-source app on your own infrastructure
alwaysApply: true
---

EOF
  cat "$SKILL_DIR/SKILL.md" >> "$DIST_DIR/cursor/00-skill.mdc"

  # Slim version of skill rule
  cat > "$DIST_DIR/cursor/00-skill-slim.mdc" <<EOF
---
description: open-forge skill (slim) — self-host open-source apps; full content at github.com/zhangqi444/open-forge
alwaysApply: true
---

When the user asks to self-host a service, follow the open-forge phased workflow:
preflight → provision → dns → tls → smtp → inbound → hardening → feedback.

Look up the matching recipe at github.com/zhangqi444/open-forge/tree/main/plugins/open-forge/skills/open-forge/references/projects/<software>.md.

Apply credential-handling patterns from references/modules/credentials.md (five patterns; paste is last-resort).

After hardening, offer the post-deploy feedback flow per references/modules/feedback.md.

Tool names in the canonical content (AskUserQuestion, WebFetch, mcp__github__*) are Claude Code-specific — use Cursor equivalents (prose prompts with options; @Web; gh CLI via terminal tool).
EOF

  # Credentials rule (loads when sensitive context detected)
  cat > "$DIST_DIR/cursor/01-credentials.mdc" <<EOF
---
description: Credential-handling patterns for open-forge — five patterns prioritizing safer alternatives over chat paste
globs: ["**/*.env*", "**/secrets/**", "**/credentials/**"]
---

EOF
  cat "$REFS_DIR/modules/credentials.md" >> "$DIST_DIR/cursor/01-credentials.mdc"

  # Feedback rule (loads when post-deploy / drafting issue)
  cat > "$DIST_DIR/cursor/02-feedback.mdc" <<EOF
---
description: open-forge post-deploy feedback flow — sanitization + multi-step consent + GitHub issue submission
---

EOF
  cat "$REFS_DIR/modules/feedback.md" >> "$DIST_DIR/cursor/02-feedback.mdc"

  echo "  ✓ dist/cursor/00-skill.mdc"
  echo "  ✓ dist/cursor/00-skill-slim.mdc"
  echo "  ✓ dist/cursor/01-credentials.mdc"
  echo "  ✓ dist/cursor/02-feedback.mdc"
}

build_aider() {
  echo "→ Building Aider bundle…"
  mkdir -p "$DIST_DIR/aider"

  # CONVENTIONS.md — auto-loaded by Aider from project root
  cat > "$DIST_DIR/aider/CONVENTIONS.md" <<EOF
# Aider conventions — open-forge skill

When the user asks to self-host a service, follow the open-forge phased workflow + recipe content below.

Tool names like AskUserQuestion, WebFetch, mcp__github__* are Claude Code-specific — use Aider equivalents:
- Structured choice → ask in chat with bulleted options; user replies in terminal
- WebFetch → /run curl <url> via Aider's shell capability, or user pastes upstream content
- GitHub issue posting → /run gh issue create (preferred), or prefilled URL fallback

State file at ~/.open-forge/deployments/<name>.yaml — Aider operates on it via filesystem ops.

---

EOF
  cat "$SKILL_DIR/SKILL.md" >> "$DIST_DIR/aider/CONVENTIONS.md"
  echo -e "\n\n---\n" >> "$DIST_DIR/aider/CONVENTIONS.md"
  cat "$REFS_DIR/modules/credentials.md" >> "$DIST_DIR/aider/CONVENTIONS.md"

  # read-files.txt — list of files to --read
  cat > "$DIST_DIR/aider/read-files.txt" <<EOF
$REPO_ROOT/CLAUDE.md
$SKILL_DIR/SKILL.md
$REFS_DIR/modules/credentials.md
$REFS_DIR/modules/feedback.md
$REFS_DIR/modules/preflight.md
EOF

  # .aider.conf.yml — drop-in config
  cat > "$DIST_DIR/aider/.aider.conf.yml" <<EOF
# Drop this file into your project root (or merge with existing config) to load
# open-forge as default context for every Aider session in the project.

read:
  - $REPO_ROOT/CLAUDE.md
  - $SKILL_DIR/SKILL.md
  - $REFS_DIR/modules/credentials.md
  - $REFS_DIR/modules/feedback.md

auto-commits: false   # open-forge state files at ~/.open-forge/ shouldn't be auto-committed
EOF

  echo "  ✓ dist/aider/CONVENTIONS.md"
  echo "  ✓ dist/aider/read-files.txt"
  echo "  ✓ dist/aider/.aider.conf.yml"
}

build_continue() {
  echo "→ Building Continue.dev bundle…"
  mkdir -p "$DIST_DIR/continue"

  # config.snippet.yaml — to merge into ~/.continue/config.yaml
  cat > "$DIST_DIR/continue/config.snippet.yaml" <<EOF
# Add to ~/.continue/config.yaml. Merge into existing top-level keys.

contextProviders:
  - name: file
    params:
      baseDir: $SKILL_DIR

prompts:
  - name: self-host
    description: "Deploy a self-hostable app via open-forge recipes"
    systemMessage: |
      You are the open-forge skill. When the user asks to self-host a service,
      look up the matching recipe at $REFS_DIR/projects/<software>.md and
      follow the phased workflow defined in $SKILL_DIR/SKILL.md.

      Apply credential-handling patterns from references/modules/credentials.md
      (five patterns; paste is last-resort).

      Tool names like AskUserQuestion / WebFetch / mcp__github__* are Claude
      Code-specific — use Continue equivalents (prose with options listed,
      @Web context provider, gh CLI via terminal).

slashCommands:
  - name: deploy
    description: "Self-host an open-source app via open-forge"
    prompt: "self-host"
EOF

  echo "  ✓ dist/continue/config.snippet.yaml"
}

build_generic() {
  echo "→ Building generic bundle…"
  mkdir -p "$DIST_DIR/generic"

  # Single-file concatenated bundle
  cat > "$DIST_DIR/generic/open-forge-bundle.md" <<EOF
# open-forge — single-file bundle for any tools-using LLM agent

This is a concatenation of the canonical open-forge skill content. Feed it as a system prompt or a long-context document to any LLM agent that supports tool use. The agent acts as a deployment runbook for self-hostable open-source apps.

For per-recipe content (~180 individual recipes under references/projects/), browse:
  https://deepwiki.com/zhangqi444/open-forge

Tool names like AskUserQuestion, WebFetch, mcp__github__* are Claude Code-specific — read as capabilities (structured-choice prompt; URL fetch; GitHub API) and use your platform's equivalents.

---

EOF
  cat "$REPO_ROOT/CLAUDE.md" >> "$DIST_DIR/generic/open-forge-bundle.md"
  echo -e "\n\n---\n" >> "$DIST_DIR/generic/open-forge-bundle.md"
  cat "$SKILL_DIR/SKILL.md" >> "$DIST_DIR/generic/open-forge-bundle.md"
  echo -e "\n\n---\n" >> "$DIST_DIR/generic/open-forge-bundle.md"
  cat "$REFS_DIR/modules/credentials.md" >> "$DIST_DIR/generic/open-forge-bundle.md"
  echo -e "\n\n---\n" >> "$DIST_DIR/generic/open-forge-bundle.md"
  cat "$REFS_DIR/modules/feedback.md" >> "$DIST_DIR/generic/open-forge-bundle.md"

  echo "  ✓ dist/generic/open-forge-bundle.md ($(wc -l < "$DIST_DIR/generic/open-forge-bundle.md") lines)"
}

case "$PLATFORM" in
  codex)    build_codex ;;
  cursor)   build_cursor ;;
  aider)    build_aider ;;
  continue) build_continue ;;
  generic)  build_generic ;;
  all)
    build_codex
    build_cursor
    build_aider
    build_continue
    build_generic
    ;;
  *) usage ;;
esac

echo
echo "Done. Bundles in: $DIST_DIR/"

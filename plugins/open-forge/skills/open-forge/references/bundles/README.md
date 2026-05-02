---
name: bundles
description: Curated multi-software deployment bundles for open-forge — recipe-of-recipes that pair commonly-co-deployed apps with cross-software config (e.g. point Open WebUI at the Ollama in this bundle). Lowers the barrier to entry for new users who know what they want to accomplish but not which exact software to pick.
---

# Curated bundles

Each bundle here is a **recipe-of-recipes**: a named goal ("I want a private AI homelab") mapped to a specific combination of software recipes from `references/projects/` plus the cross-software config that makes them work together. Bundles don't replace the per-software recipes — they orchestrate them.

When the user invokes a bundle, the skill walks through each constituent software in the right order, stopping where the user's input is needed, and applying any cross-software wiring noted in the bundle.

## When to use a bundle vs a single recipe

| | Single recipe | Bundle |
|---|---|---|
| User says... | *"Self-host Ghost on Hetzner"* | *"Set up an AI homelab on my old Mac mini"* |
| Skill picks... | `references/projects/ghost.md` | `references/bundles/ai-homelab.md` (which loads `ollama.md` + `open-webui.md` + ...) |
| Order of operations | Single phased workflow | Per-software phased workflows in dependency order |

If the user names a single software, use the single-recipe path. If they describe a goal, check if a bundle matches.

## Available bundles

| Bundle | Goal | Constituent recipes |
|---|---|---|
| [`ai-homelab.md`](ai-homelab.md) | Private LLM + chat UI + RAG workspace + pair-programming, all on one box | Ollama · Open WebUI · AnythingLLM · Aider |
| [`privacy-stack.md`](privacy-stack.md) | Network-wide ad blocking + private password vault + mesh VPN for remote access | Pi-hole · Vaultwarden · Headscale · wg-easy |

More bundles get added when 3+ users (or one repeat user) explicitly ask for the same combination — same demand-driven graduation criteria as Tier 2 → Tier 1 software recipes per CLAUDE.md.

## Authoring a new bundle

A bundle file specifies:

1. **Goal**: one-sentence statement of the user-facing outcome.
2. **Constituent recipes**: which `references/projects/*.md` files to load, in dependency order (foundation first — e.g. Ollama before Open WebUI, since Open WebUI points at Ollama).
3. **Recommended infra/runtime combo**: defaults that make sense for the bundle (e.g. AI homelab → localhost or single-VPS with GPU; privacy stack → Raspberry Pi or low-cost VPS).
4. **Cross-software config**: env vars / DNS / ports that one recipe needs from another (e.g. *"Set Open WebUI's `OLLAMA_BASE_URL` to `http://ollama:11434` since they share a Compose network"*).
5. **Combined inputs**: the union of inputs the constituent recipes need, in the phase order they're collected.
6. **Verification**: what "the whole bundle works" looks like (e.g. *"Open WebUI loads and lists Ollama-hosted models without manual config"*).
7. **Out-of-scope notes**: what the bundle deliberately doesn't cover (e.g. *"AI homelab doesn't ship a reverse proxy / TLS — assumes localhost or you front it with your own Caddy / Traefik"*).

## Why bundles aren't speculative recipe authoring

Per CLAUDE.md § *Tier 2 → Tier 1 graduation criteria*: don't author Tier 1 recipes speculatively from a "popular self-host" list. Bundles are **not** new recipes — they're an orchestration layer over recipes that already exist (and have their own demand-signal track records). The AI-homelab bundle ships only because Ollama / Open WebUI / AnythingLLM / Aider are all already Tier 1 with first-deploy verification. If a constituent recipe gets demoted, the bundle goes with it.

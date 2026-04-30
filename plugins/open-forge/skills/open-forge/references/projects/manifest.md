---
name: Manifest
description: "Smart model router for AI agents — routes each query to the cheapest/smallest-sufficient LLM (API keys, subscriptions, local models, custom providers). Can cut AI costs ~70%. Fallback on failures. Beta. Node.js + TypeScript. License per repo."
---

# Manifest

Manifest is **a smart model router for LLM agents and AI applications** — instead of calling one expensive frontier model for every request, Manifest routes each query to **the right-sized model** based on complexity, specificity, and custom routing rules. Simple questions go to cheap/small models (sometimes local); hard questions go to GPT-4o / Claude Opus / Gemini Ultra. Up to **~70% AI cost reduction** claimed. Supports API keys, consumer subscriptions, local models (Ollama, LM Studio), and custom providers.

Positioning: similar space to **OpenRouter** (routing marketplace) and **LiteLLM** (proxy + routing library), but focused on **cost-routing for agents** rather than marketplace or SDK unification.

> **⚠️ Status: BETA.** Upstream README explicitly marks status as beta. APIs + behavior may change; evaluate fitness for production carefully.

Features:

- **Smart routing** — by query complexity + specificity + custom HTTP headers
- **Provider mixing** — API keys (OpenAI, Anthropic, Google), subscription accounts, local models (Ollama), custom providers
- **Cost tracking** — per-query + aggregate $-tracking; budgets + alerts
- **Fallback** — if provider A fails, automatically try B, C, D
- **Notifications + limits** — stop runaway costs before they compound
- **Cloud version** available at <https://app.manifest.build> + self-hostable

- Upstream repo: <https://github.com/mnfst/manifest>
- Website: <https://manifest.build>
- Cloud: <https://app.manifest.build>
- Discord: <https://discord.gg/FepAked3W7>
- Docker Hub: <https://hub.docker.com/r/manifestdotbuild/manifest>

## Architecture in one minute

- **Node.js / TypeScript** backend + web UI
- **Proxy model**: applications point to Manifest as the OpenAI-compatible endpoint; Manifest forwards to the routed provider
- **Database**: embedded or external (check repo for current config)
- **Docker-first deployment**
- **Small footprint** — couple hundred MB RAM idle
- **NOT a model-serving runtime** — it routes to external or local model servers; doesn't run models itself

## Compatible install methods

| Infra              | Runtime                                                           | Notes                                                                          |
| ------------------ | ----------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker (`manifestdotbuild/manifest`)**                              | **Upstream-recommended**                                                           |
| Single VM          | Node.js from source                                                           | For dev                                                                                    |
| Kubernetes         | Community manifests                                                                            | Small; Deployment + Service                                                                                 |
| Managed            | **app.manifest.build** (cloud)                                                                              | Upstream-hosted                                                                                                         |
| Raspberry Pi       | Fine (it's a router, not a model runner)                                                                                   |                                                                                                                                   |

## Inputs to collect

| Input                     | Example                                    | Phase        | Notes                                                                 |
| ------------------------- | ------------------------------------------ | ------------ | --------------------------------------------------------------------- |
| Domain                    | `manifest.example.com`                         | URL          | Behind TLS                                                                     |
| Provider API keys         | OpenAI, Anthropic, Google, Mistral, xAI, etc.     | Setup        | Each provider you want to route to                                                    |
| Local models              | Ollama/LM Studio URL                                    | Setup        | If using local fallback                                                                                   |
| Routing rules             | e.g., "simple → Haiku, complex → Opus"                           | Policy       | Set in Manifest UI                                                                                                        |
| Budget limits             | monthly $ per provider or total                                         | Governance   | Configure to prevent runaway costs                                                                                                                   |
| Admin account             | first user via setup                                                                | Bootstrap    | Protect this key                                                                                                                                                  |

## Install via Docker

```yaml
services:
  manifest:
    image: manifestdotbuild/manifest:latest           # pin in prod — status is beta!
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
    environment:
      DATABASE_URL: "file:./dev.db"                     # check upstream for current env
      # Provider keys:
      OPENAI_API_KEY: sk-...
      ANTHROPIC_API_KEY: sk-ant-...
```

(Environment variables shown here are illustrative — **check the current upstream README** for the actual env var names, since the project is in beta and config may have evolved.)

Browse `http://<host>:3000/` → create admin + set up first routing rule.

## First boot

1. Browse → create admin user
2. Add provider keys (OpenAI, Anthropic, local Ollama URL, etc.)
3. Create a routing rule — e.g., "default to `claude-3-5-haiku`; route complex queries (>1k context) to `claude-3-5-sonnet`; fallback to `gpt-4o-mini`"
4. Point your LLM app at Manifest's OpenAI-compatible endpoint (e.g., `https://manifest.example.com/v1`)
5. Watch dashboard for cost tracking
6. Set monthly budget alerts
7. Add fallback chain for reliability

## Data & config layout

- `/app/data/` (container) — local DB + config
- Env vars — provider API keys
- **Treat provider keys + Manifest URL as credentials** — anyone with the endpoint can burn your API budget

## Backup

```sh
# Data dir + env (config + costs + routing history)
sudo tar czf manifest-$(date +%F).tgz data/
# Also back up env vars separately (to restore provider keys)
```

Cost-tracking history is valuable for audit but not mission-critical.

## Upgrade

1. Releases: <https://github.com/mnfst/manifest/releases>. Active.
2. **Beta status**: expect breaking changes. Read release notes carefully.
3. Docker: bump tag; back up data first.
4. Test routing rules after upgrade.

## Gotchas

- **Beta status** — production use at your own risk. Pin exact versions; have a fallback plan if Manifest goes down (direct provider endpoints).
- **Manifest is a SPOF** for your AI traffic — if Manifest is down, your agents can't call LLMs. Run HA or have a bypass escape hatch (direct provider credentials in env).
- **Key concentration risk** — Manifest holds keys for ALL your providers. Compromise of the Manifest host = all provider keys exposed. Rotate + scope keys per-provider (OpenAI usage limits, Anthropic org caps).
- **Cost-tracking accuracy**: depends on Manifest correctly parsing provider response usage metadata. Reconcile monthly with actual provider invoices — don't treat Manifest's dashboard as authoritative.
- **Routing correctness = quality tradeoff**: routing a hard query to a cheap model = wrong answer. Routing rules need tuning + observation; start conservative (route only obvious-cheap traffic) + expand.
- **Latency overhead**: proxy adds ~tens of ms; usually insignificant vs LLM time. For latency-critical paths, consider bypassing for highest-tier users.
- **OpenAI-compatible API**: most clients work out of the box. Some providers (Anthropic, Google) have different API shapes — Manifest translates. Edge cases (tool use, vision, streaming) may have gaps; test.
- **Local model routing** (Ollama) can be very cost-effective for simple queries + privacy. Test output quality vs hosted before heavy reliance.
- **Budget alerts**: configure email/Slack/webhook. Critical for catching runaway agents.
- **Rate limiting**: Manifest can respect provider rate limits + route around. Consult current docs for config.
- **Custom providers**: extend via plugin/config to add non-standard endpoints (private Azure deployments, self-hosted vLLM/TGI, OpenRouter itself).
- **Comparison to OpenRouter**: OpenRouter is a marketplace (they add markup + provide unified billing). Manifest routes your own keys — you own the cost relationship with each provider.
- **Comparison to LiteLLM**: LiteLLM is an SDK/proxy library — more of a "call N providers with unified SDK" tool, slightly different focus than Manifest's cost-router framing.
- **Comparison to Helicone / LangSmith / Langfuse**: those are observability/monitoring proxies; Manifest is specifically a cost-router. Some overlap in dashboard features.
- **Agent frameworks** (LangChain, Autogen, CrewAI, LangGraph) work with Manifest by pointing at its OpenAI endpoint.
- **Cloud vs self-hosted**: cloud is turnkey but keys live at Manifest's servers. Self-host for privacy-sensitive / compliance cases.
- **License**: check repo LICENSE file — specific license.
- **Alternatives worth knowing:**
  - **OpenRouter** — marketplace router; unified billing
  - **LiteLLM** — SDK + proxy; developer-focused
  - **Helicone** — observability + some routing
  - **Langfuse** — LLM observability (separate focus)
  - **Portkey** — API gateway for LLMs; commercial
  - **vLLM / TGI** — self-hosted model serving (separate focus — Manifest routes TO these)
  - **OpenLLM** — model serving
  - **Direct provider SDKs** — no router; choose wisely which model to call in code
  - **Choose Manifest if:** multi-provider cost optimization + fallback + want a self-hostable router.
  - **Choose OpenRouter if:** you want one bill + one SDK + the widest model catalog + don't care about markup.
  - **Choose LiteLLM if:** developer-first SDK-based unified calls.
  - **Choose direct SDKs if:** single provider, simple logic.

## Links

- Repo: <https://github.com/mnfst/manifest>
- Website: <https://manifest.build>
- Cloud: <https://app.manifest.build>
- Discord: <https://discord.gg/FepAked3W7>
- Docker Hub: <https://hub.docker.com/r/manifestdotbuild/manifest>
- Releases: <https://github.com/mnfst/manifest/releases>
- OpenRouter (alt, marketplace): <https://openrouter.ai>
- LiteLLM (alt, SDK+proxy): <https://github.com/BerriAI/litellm>
- Helicone (alt, observability): <https://helicone.ai>
- Portkey (alt, gateway): <https://portkey.ai>
- Langfuse (alt, observability): <https://langfuse.com>

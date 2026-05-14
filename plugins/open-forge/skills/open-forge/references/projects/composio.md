---
name: Composio
description: "Integration platform for AI agents and LLMs — connect 250+ apps and services (GitHub, Slack, Gmail, etc.) to AI agents via standardized tool interfaces for Python and TypeScript. Python/TypeScript. MIT."
---

# Composio

Composio is an integration platform that connects AI agents and LLMs to 250+ external apps and services (GitHub, Slack, Gmail, Jira, Salesforce, databases, and more) via standardized, authentication-managed tool interfaces.

Instead of writing custom integration code for each app, AI agent developers use Composio's SDK to get pre-built, auth-handled "tools" that agents (built with LangChain, LlamaIndex, OpenAI Agents, CrewAI, etc.) can call. Composio handles OAuth flows, credential storage, and API normalization.

Maintained by ComposioHQ. Licensed under MIT License. Composio.dev is the managed SaaS offering.

Use cases: (a) AI agents that need to interact with real-world apps (b) LLM pipelines that trigger GitHub issues, send Slack messages, read emails (c) developer productivity automation with AI (d) agentic workflows that span multiple SaaS tools.

**Note:** `depends_3rdparty: true` in the awesome-selfhosted catalog — Composio's self-hosted mode connects to external third-party services by design. The platform itself is self-hostable but the *integrations* call external APIs.

Features:

- **250+ integrations** — GitHub, Slack, Gmail, Google Calendar, Jira, Salesforce, Notion, Linear, HubSpot, databases, and more
- **Framework support** — LangChain, LlamaIndex, OpenAI Agents, CrewAI, Autogen, Vercel AI SDK, custom
- **Auth management** — handles OAuth 2.0, API keys, and other auth flows; stores credentials securely
- **Tool normalization** — each integration exposes standardized function signatures; agents don't need to know API details
- **Python + TypeScript SDKs** — first-class support for both ecosystems
- **Custom tools** — define your own tools alongside built-in integrations
- **Webhooks and triggers** — event-driven tool invocations (e.g., trigger agent when GitHub issue is created)
- **Multi-user support** — per-user auth contexts; agents can act on behalf of different users
- **CLI** — `composio` CLI for managing connections and configurations

- Upstream repo: https://github.com/ComposioHQ/composio
- Homepage: https://composio.dev/
- Docs: https://docs.composio.dev/
- PyPI: https://pypi.org/project/composio/

## Architecture

Composio has two modes:

1. **Composio SaaS** (composio.dev) — hosted API; developers get an API key; all auth and tool management handled by Composio's cloud. Fastest to get started.
2. **Self-hosted** — run the Composio backend server locally or on your own infrastructure. Credentials stored on your own hardware. Requires Docker or direct Python setup.

Self-hosted components:
- **Composio server** — manages auth connections, tool definitions, credential vault
- **Python/TS SDK** — client library used in agent code; calls either the hosted or self-hosted server
- **Database** — stores user connections and credentials (PostgreSQL)

## Compatible install methods

| Infra       | Runtime              | Notes                                                           |
|-------------|----------------------|-----------------------------------------------------------------|
| SaaS        | composio.dev         | Easiest; free tier available; no self-hosting needed            |
| Docker      | docker compose       | Self-hosted; includes server + DB                               |
| Python      | pip install composio | SDK only (SaaS backend); no server setup                        |
| Kubernetes  | Helm chart (planned) | Check docs for current k8s support                              |

## Inputs to collect

| Input          | Example                    | Phase    | Notes                                                        |
|----------------|----------------------------|----------|--------------------------------------------------------------|
| API key        | from composio.dev or self-hosted | Auth | Required in SDK initialization                              |
| LLM provider   | OpenAI, Anthropic, etc.    | LLM      | Composio provides tools; your LLM orchestrates them          |
| App connections| GitHub, Slack, etc.        | Connect  | Each app requires one-time auth (OAuth or API key)           |

## Python SDK quickstart

```bash
pip install composio-core composio-langchain  # or composio-openai, composio-crewai, etc.

# Authenticate with Composio (SaaS or self-hosted)
composio login
# or set env: COMPOSIO_API_KEY=your_key

# Connect an app (one-time OAuth flow)
composio apps add github
```

```python
from composio_langchain import ComposioToolSet, Action
from langchain_openai import ChatOpenAI
from langchain.agents import initialize_agent

toolset = ComposioToolSet()
tools = toolset.get_tools(actions=[
    Action.GITHUB_CREATE_ISSUE,
    Action.SLACK_SEND_MESSAGE,
    Action.GMAIL_SEND_EMAIL,
])

llm = ChatOpenAI(model="gpt-4o")
agent = initialize_agent(tools, llm, agent="openai-functions-agent")
agent.invoke({"input": "Create a GitHub issue titled 'Bug in login flow' in my repo"})
```

## TypeScript SDK quickstart

```bash
npm install @composio/core @composio/openai-agents @openai/agents
```

```typescript
import { Composio } from '@composio/core';
import { OpenAIAgentsProvider } from '@composio/openai-agents';

const composio = new Composio({ provider: new OpenAIAgentsProvider() });
const tools = await composio.tools.get('user@example.com', {
  toolkits: ['GITHUB', 'SLACK'],
});
// Pass tools to your agent...
```

## Self-hosted setup (Docker)

```sh
git clone https://github.com/ComposioHQ/composio.git
cd composio
docker compose -f docker/docker-compose.yml up -d

# Set self-hosted URL in your code
export COMPOSIO_BASE_URL=http://localhost:9000
```

See https://docs.composio.dev/self-hosting for current self-hosted setup instructions.

## Gotchas

- **MIT License** — Composio is now licensed under MIT. Full permissive use; you can self-host, modify, and build on it freely including for commercial purposes.
- **depends_3rdparty** — Composio itself runs locally, but every integration call goes to an external API (GitHub, Slack, etc.). It's not a fully offline tool; it reduces the integration code burden but doesn't eliminate external dependencies.
- **Auth credentials stored server-side** — in self-hosted mode, OAuth tokens and API keys for connected apps are stored in your Composio database. Secure your database and server appropriately.
- **Multi-user auth contexts** — when building apps where different end-users have different app connections (e.g., each user connects their own GitHub), Composio's `entity_id` / user-scoped connections handle this. Important to understand before building multi-tenant agents.
- **SDK vs server version compatibility** — pin SDK versions alongside your server version in self-hosted setups. Composio moves fast; mismatches can cause API schema errors.
- **Rate limits from underlying APIs** — Composio's tool calls hit real APIs. GitHub, Slack, Gmail etc. all have rate limits. High-frequency agent loops can exhaust them quickly.
- **Tool count ≠ quality** — 250+ integrations vary in completeness. Core apps (GitHub, Slack, Gmail) are well-tested; niche integrations may have gaps. Check the specific action list for your target app before committing.
- **Alternatives:** LangChain Tools (lower-level, build your own), n8n (visual workflow automation, self-hosted), Zapier (SaaS-only), MCP (Anthropic's Model Context Protocol; emerging standard for LLM tool integration).

## Links

- Repo: https://github.com/ComposioHQ/composio
- Homepage: https://composio.dev/
- Docs: https://docs.composio.dev/
- Integrations list: https://composio.dev/tools
- PyPI: https://pypi.org/project/composio/
- npm: https://www.npmjs.com/package/@composio/core
- Discord: https://discord.gg/composio
- Self-hosting docs: https://docs.composio.dev/self-hosting

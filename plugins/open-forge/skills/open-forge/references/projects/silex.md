---
name: Silex
description: "Visual static-site builder. GrapesJS-based WYSIWYG; static HTML/CSS output; CMS integrations (WordPress/Strapi/GraphQL); 11ty-compatible; Node.js. AGPL. Silex Labs non-profit (1000+ weekly users since 2009). Transparent finances via Open Collective."
---

# Silex

Silex is **"Webflow / Wix / Squarespace — but AGPL + non-profit + no lock-in + static-HTML-output"** — a free/libre visual website builder. Drag-and-drop with GrapesJS; exports clean HTML/CSS; host anywhere; **no tracking, no subscription, no lock-in**. Real web skills transferable (HTML/CSS/JAMstack). Integrations: **WordPress + Strapi + Squidex + any GraphQL CMS**. 11ty-compatible static-site generation. Coming-soon desktop app (Tauri) with offline + AI MCP-server integration.

Built + maintained by **Silex Labs** — **non-profit org recognized as being of general interest** + community since **2009**. License: **AGPL**. Active; 1000+ weekly users; 23,000+ accounts; transparent finances on **Open Collective**. Installable on YunoHost / CapRover / Elest.io.

Use cases: (a) **web agencies** — visual workflow + scalable client-work (b) **freelance webdesigners** — client sites without code; export standard HTML (c) **WordPress frontend** — GraphQL-bind to WP + ditch theme layer (d) **no-code with escape-hatch** — go beyond Wix with full CSS (e) **JAMstack-compatible** — 11ty output → Netlify/Vercel/CF Pages (f) **host anywhere** — static output = max portability (g) **replace Webflow** on ethical grounds (h) **teaching HTML/CSS visually** — real output for learners.

Features (per README):

- **GrapesJS visual editor** — drag-and-drop
- **Static HTML output**
- **CMS integrations** — WordPress, Strapi, Squidex, GraphQL
- **11ty compatible**
- **Plugin system** — JS/TS server + client plugins
- **SEO tools** — meta tags, Open Graph
- **Desktop app** (coming; Tauri)
- **AI / MCP server** integration (roadmap)

- Upstream repo: <https://github.com/silexlabs/Silex>
- Website: <https://www.silex.me>
- Try online: <https://v3.silex.me>
- Docs: <https://docs.silex.me>
- Silex Labs non-profit: <https://www.silexlabs.org>
- Open Collective (finances): <https://opencollective.com/silex>

## Architecture in one minute

- **Node.js** (Express-based)
- **GrapesJS** WYSIWYG frontend
- **Storage**: filesystem / GitLab / S3 / custom connectors
- **Resource**: low-moderate — 200-500MB RAM
- **Port 6805** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images**                                             | **Primary**                                                                        |
| **Node.js**        | **`npx @silexlabs/silex`**                                      | **Zero-install**                                                                        |
| **CapRover / YunoHost / Elest.io** | **One-click**                                                                           | Platforms                                                                                   |
| **Desktop app**    | Tauri (alpha)                                                                                                             | Offline                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `builder.example.com`                                       | URL          | TLS                                                                                    |
| Storage backend      | Filesystem / GitLab / S3 / custom                           | Storage      |                                                                                    |
| Output hosting       | Static-host target (CF Pages, Netlify, etc.)                                                                                 | Output       |                                                                                    |
| CMS (opt)            | WordPress/Strapi/GraphQL endpoint                                                                                                         | Integration  |                                                                                    |
| Admin auth           | Per-deployment                                                                                                            | Auth         |                                                                                                                                            |

## Install via npx / Node

```sh
npx @silexlabs/silex
# Open http://localhost:6805
```

## Install via Docker

```yaml
services:
  silex:
    image: silexlabs/silex:latest        # **pin version**
    ports: ["6805:6805"]
    volumes:
      - silex-storage:/root/.silex
    restart: unless-stopped

volumes:
  silex-storage: {}
```

## First boot

1. Run Silex → open `:6805`
2. Create account (or connect GitLab)
3. Design first page visually
4. Export HTML/CSS → deploy to host
5. Configure CMS binding (optional)
6. Install plugins (if needed)

## Data & config layout

- `/root/.silex/` — user data + sites
- Storage may also use GitLab (configurable)
- Published output = separate static host

## Backup

```sh
sudo tar czf silex-$(date +%F).tgz silex-storage/
# If GitLab-backed: your GitLab repo is the source-of-truth
```

## Upgrade

1. Releases: <https://github.com/silexlabs/Silex/releases>. Active.
2. Docker pull + restart
3. Since 2009: stable release cadence; check CHANGELOG
4. **v3 is current major**; v2 → v3 was major rewrite — check migration docs

## Gotchas

- **STATIC-SITE-OUTPUT = PORTABILITY POSITIVE-SIGNAL**:
  - HTML/CSS output works anywhere
  - No lock-in to Silex hosting
  - **"Zero-lock-in" pattern extended**: now 5 tools (Flatnotes + Basic Memory + Gramps + Raneto + Silex)
  - **Zero-lock-in: 5 tools** 🎯 **5-tool MILESTONE for zero-lock-in**
- **NON-PROFIT + GENERAL-INTEREST RECOGNITION**:
  - Silex Labs = French non-profit ("reconnue d'intérêt général")
  - Eligibility for tax-deductible donations
  - **Recipe convention: "general-interest-non-profit positive-signal"** — legally-recognized public-benefit
  - **NEW positive-signal convention** (Silex 1st)
- **TRANSPARENT FINANCES VIA OPEN COLLECTIVE**:
  - Open Collective shows all income + expenses
  - Unusual level of transparency
  - **Recipe convention: "Open-Collective-transparent-finances positive-signal"**
  - **NEW positive-signal convention** (Silex 1st named)
- **AGPL-3.0 NETWORK-SERVICE-DISCLOSURE**:
  - Self-hosting + exposing to network = AGPL
  - Modifications must be disclosed
  - **15th tool in AGPL-network-service-disclosure**
- **2009-ORIGIN = EXCEPTIONAL LONGEVITY**:
  - 16+ years in project history
  - Survived multiple framework eras
  - **Recipe convention: "decade-plus-OSS-project" extended** — Silex joins Gramps (2001), EspoCRM (1+decade)
  - **"Decade-plus" positive-signal: 3 tools**
- **HUB-OF-CREDENTIALS TIER 3**:
  - Low PII; static-site-builder typically doesn't store customer data
  - GitLab / S3 tokens (if configured) = medium sensitivity
  - **83rd tool in hub-of-credentials family — Tier 3**
- **STORAGE-BACKEND-FLEXIBILITY**:
  - Filesystem / GitLab / S3 / custom connector
  - Pluggable architecture
  - **Recipe convention: "pluggable-storage-backend" positive-signal**
- **CMS INTEGRATIONS = HEADLESS-CMS WORKFLOW**:
  - Design in Silex; content from WordPress/Strapi; output static
  - Decouple design from content = JAMstack
- **MCP SERVER INTEGRATION (ROADMAP)**:
  - Desktop app will have MCP server for AI integration
  - AI can read/edit Silex projects
  - **Recipe convention: "MCP-server tools category" extended** (Basic Memory 102 was 1st; Silex is 2nd when shipped)
  - **Reinforces "MCP-server tools" category** — watch for Silex desktop-MCP ship date
- **"NO-CODE-WITH-ESCAPE-HATCH"**:
  - Unlike Wix/Squarespace: can always edit CSS/JS
  - **Recipe convention: "no-code-with-code-escape-hatch" positive-signal**
  - **NEW positive-signal convention**
- **INSTITUTIONAL-STEWARDSHIP**: Silex Labs non-profit + 16+ years + community. **69th tool — general-interest-non-profit sub-tier** (**NEW sub-tier**).
  - **NEW sub-tier: "general-interest-non-profit organization"** — 1st tool named (Silex; Silex Labs)
  - Distinct from YunoHost's "EU-public-interest-funded project" (funding-focused) vs Silex Labs' "org-is-the-non-profit" (legal-structure-focused)
- **TRANSPARENT-MAINTENANCE**: active since 2009 + AGPL + CI + releases + translation-via-crowdin-likely + Open-Collective + manifesto + non-profit-status + 1000+ weekly users. **77th tool in transparent-maintenance family.**
- **NO-CODE-CATEGORY (crowded):**
  - **Silex** — OSS; AGPL; static output
  - **Webflow** — commercial; dominant
  - **Wix / Squarespace** — commercial; mass-market
  - **Plasmic** — OSS + commercial; React component builder
  - **Grapesjs standalone** — the library Silex is built on
  - **Webstudio** — OSS visual builder
  - **Framer** — commercial
- **ALTERNATIVES WORTH KNOWING:**
  - **Webstudio** — OSS alternative; React-focused
  - **Plasmic** — OSS + commercial; React-component-builder
  - **GrapesJS** standalone — if you want the library not the platform
  - **Choose Silex if:** you want AGPL + non-profit + static output + long-history + host-anywhere.
- **PROJECT HEALTH**: 16-year-old + non-profit + AGPL + Open-Collective + CI + docs + active + community + translations. EXCEPTIONAL.

## Links

- Repo: <https://github.com/silexlabs/Silex>
- Website: <https://www.silex.me>
- Manifesto: <https://www.silex.me/manifesto/>
- Docs: <https://docs.silex.me>
- Open Collective: <https://opencollective.com/silex>
- Silex Labs: <https://www.silexlabs.org>
- GrapesJS: <https://grapesjs.com>
- Webstudio (alt OSS): <https://webstudio.is>
- Plasmic (alt): <https://www.plasmic.app>
- 11ty: <https://www.11ty.dev>

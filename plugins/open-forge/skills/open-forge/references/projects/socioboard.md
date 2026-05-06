---
name: socioboard
description: Socioboard recipe for open-forge. Covers Docker Compose install from source. Socioboard is an open-source social media management, analytics, and reporting platform supporting nine social networks. Note — last release was 2019; development activity is very low.
---

# Socioboard

Open-source social media management, analytics, and reporting platform. Supports nine social media networks, team collaboration, post scheduling, RSS feed integration, and automated email reports. Upstream: <https://github.com/socioboard/Socioboard-5.0>. Website: <https://socioboard.com>.

**License:** GPL-3.0 · **Language:** Node.js · **Default port:** 5001 · **Stars:** ~1,400

> **⚠️ Maintenance status:** Socioboard 5.0 has had minimal development activity since 2019 (last release tag: 4.1.0, 2019-11-15). The codebase depends on third-party social media APIs that change frequently. Expect to encounter broken integrations and unmaintained dependencies. Evaluate alternatives (Postiz, Mixpost) for active-development social media management.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/socioboard/Socioboard-5.0#docker> | ✅ | Recommended — containerizes the multi-service app. |
| Manual (Node.js) | <https://github.com/socioboard/Socioboard-5.0#installation> | ✅ | Bare-metal installs with full control. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| social_networks | "Which social networks to integrate? (Twitter/X, Facebook, Instagram, LinkedIn, YouTube, etc.)" | AskUserQuestion | Determines API key collection. |
| api_keys | "Social platform API keys and secrets for selected networks?" | Free-text (sensitive) | Per selected network. |
| database | "MySQL host, database name, username, password?" | Free-text (sensitive) | All methods. |
| domain | "What URL will Socioboard be served at?" | Free-text | All methods. |
| smtp | "SMTP host/port/user/password for email reports?" | Free-text (sensitive) | Optional. |

## Install — Docker Compose

Reference: <https://github.com/socioboard/Socioboard-5.0>

```bash
git clone https://github.com/socioboard/Socioboard-5.0.git
cd Socioboard-5.0

# Review and edit docker-compose.yml for your environment
# Set MySQL credentials, API keys, and domain
nano docker-compose.yml

docker compose up -d
```

> **Note:** The repo may not have a `docker-compose.yml` in root — check for it in subdirectories (`src/`, `setup/`) or build from source with the included Dockerfile.

## Install — Manual (Node.js)

Requirements: Node.js 14.x (older LTS — the codebase predates Node 16+), MySQL 5.7+, Redis.

```bash
git clone https://github.com/socioboard/Socioboard-5.0.git
cd Socioboard-5.0

# Install dependencies
npm install

# Configure environment
cp .env.example .env
nano .env  # set DB, Redis, API keys, domain

# Initialize database
# Import the SQL schema from the repo (check /setup/ or /database/ directory)
mysql -u root -p < setup/socioboard.sql

# Start the application
npm start
# or
node app.js
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Node.js version | Likely requires Node.js 12-14 LTS (the 2019-era codebase). Node 18+ may break due to deprecated APIs. Use `nvm` to pin a compatible version. |
| Database | MySQL 5.7+ or MariaDB. Redis for session/queue management. |
| Social API credentials | Each connected social network requires a developer app with API keys. Facebook, Instagram, and LinkedIn have restricted APIs — approval may be needed. |
| Twitter/X API | Twitter API v1.1 (used by Socioboard) is deprecated/restricted. Twitter/X now requires paid API access for most endpoints. Core scheduling features may be broken. |
| Dependency age | `npm audit` will show many high-severity vulnerabilities from 2019-era dependencies. Do not expose to the public internet without a security review. |
| Port | Default 5001. Put behind nginx with TLS for any non-local access. |

## Upgrade procedure

No upstream upgrade path documented. To update:

```bash
git pull origin master
npm install
# Restart app
```

Check for SQL migration scripts in the repo — apply manually if present.

## Gotchas

- **Stale codebase:** The last release was 2019. Social media APIs (especially Twitter/X and Meta) have changed significantly. Expect broken integrations for most platforms without custom patching.
- **Twitter/X API:** Twitter API v1 is dead. v2 requires a paid plan for write operations. Socioboard's Twitter integration is effectively non-functional for posting without significant code changes.
- **Old Node.js required:** The app likely won't run on Node.js 18+. Use nvm to install and pin Node 14 LTS.
- **Vulnerable dependencies:** `npm audit` will show critical vulnerabilities. Do not expose to the internet without a full dependency audit and update.
- **Consider alternatives:** For active-development social media management, consider [Postiz](https://github.com/gitroomhq/postiz-app) (7k+ stars, active) or [Mixpost](https://github.com/inovector/mixpost) instead.

## Upstream links

- GitHub: <https://github.com/socioboard/Socioboard-5.0>
- Website: <https://socioboard.com>
- Active alternative — Postiz: <https://github.com/gitroomhq/postiz-app>

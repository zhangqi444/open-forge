---
name: graphweaver
description: Graphweaver recipe for open-forge. Code-first GraphQL API builder that connects multiple data sources (PostgreSQL, MySQL, SQLite, REST, SaaS) into a single unified API with built-in admin panel, auth, and permissions. Node.js/TypeScript. CLI scaffolding via npx. Source: https://github.com/exogee-technology/graphweaver
---

# Graphweaver

Code-first GraphQL API server that unifies multiple data sources — PostgreSQL, MySQL, SQLite, REST APIs, and SaaS platforms — behind a single GraphQL endpoint. Auto-generates CRUD resolvers with full customization support: override any resolver, add custom types, define row/column-level permissions, and cross-filter across data sources. Includes a built-in admin panel UI. Built on Node.js/TypeScript; scaffolded via the Graphweaver CLI. MIT license. Upstream: https://github.com/exogee-technology/graphweaver. Docs: https://graphweaver.com/docs. Demo: https://demo.graphweaver.com.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| npx CLI (new project) | Linux / macOS / Windows | Recommended; scaffolds a TypeScript project |
| Docker | Linux | Containerize the scaffolded project |
| npm / node | Linux / macOS / Windows | Run directly as a Node.js app |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| init | "Project name?" | Directory name for the scaffolded project |
| db | "Data source type?" | PostgreSQL, MySQL, SQLite, REST, etc. |
| db | "Database connection string?" | e.g. postgresql://user:pass@host:5432/mydb |
| auth | "Enable authentication?" | Built-in auth with magic links, TOTP, passkeys |
| port | "Port?" | Default: 9001 |

## Software-layer concerns

### Prerequisites

  # Node.js 22+ (LTS or current)
  # PNPM 9+ (Graphweaver uses PNPM workspaces)
  # A supported data source (PostgreSQL, MySQL, SQLite, etc.)

  # Install PNPM if needed:
  npm install -g pnpm

### Create a new project via CLI

  npx graphweaver@latest new
  # Follow the prompts:
  # - Project name
  # - Select data source(s) to connect
  # - Enter connection string

  cd my-project
  pnpm install

### Project structure (scaffolded)

  src/
    schema/
      index.ts          # GraphQL schema entry point
      <entity>.ts       # Per-entity resolver definitions
    index.ts            # Server entry point
  graphweaver.config.ts # Graphweaver configuration
  package.json

### Run in development mode

  pnpm dev
  # Starts the GraphQL server at http://localhost:9001/graphql
  # Admin panel at http://localhost:9001

### Environment variables

  DATABASE_URL    Connection string for the primary data source
  PORT            Server port (default: 9001)
  AUTH_SECRET     Secret key for JWT signing (if auth enabled)

### Connect multiple data sources

  # In src/schema/index.ts:
  import { PostgreSQLProvider } from '@graphweaver/db';
  import { RestProvider } from '@graphweaver/rest';

  // Each data source is a provider; entities are mapped to providers
  // Cross-source queries are resolved automatically

### Auth (built-in)

  # Graphweaver has a built-in auth module supporting:
  # - Magic link (passwordless email)
  # - TOTP (time-based OTP)
  # - Passkeys (WebAuthn)
  # - OAuth2/OIDC (via plugins)
  # Configure in graphweaver.config.ts

### Row/column-level permissions

  // Example: restrict a field to admins only
  @Field(() => String, { adminUIOptions: { readonly: true } })
  @ReadOnly()
  sensitiveField: string;

### Build for production

  pnpm build
  pnpm start
  # Or: NODE_ENV=production node dist/index.js

### Docker (containerize the scaffolded project)

  FROM node:22-alpine
  WORKDIR /app
  COPY package.json pnpm-lock.yaml ./
  RUN npm install -g pnpm && pnpm install --frozen-lockfile
  COPY . .
  RUN pnpm build
  EXPOSE 9001
  CMD ["pnpm", "start"]

### Ports

  9001/tcp   # GraphQL API + Admin panel (default)

### Reverse proxy (nginx)

  location / {
      proxy_pass http://127.0.0.1:9001;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
  }

## Upgrade procedure

  # Update Graphweaver packages in your project:
  pnpm update @graphweaver/core @graphweaver/db @graphweaver/admin-ui
  pnpm build
  # Restart the service

## Gotchas

- **PNPM required**: Graphweaver uses PNPM workspaces. Attempting to use npm or yarn may fail due to workspace resolution differences.
- **Node.js 22+ required**: The CLI enforces Node 22+. Check with `node --version`.
- **Code-first means TypeScript**: Graphweaver is not a no-code tool. You write TypeScript resolvers; the CLI scaffolds the boilerplate. Expect to write code for anything beyond basic CRUD.
- **Admin panel is included**: The admin panel UI is served from the same port as the GraphQL API. It's auto-generated from your schema.
- **Multiple data sources**: Cross-source filtering is a key feature — you can query PostgreSQL records filtered by data from a REST API. Configure each source as a separate provider.
- **Auth is optional but built-in**: You can add auth without a separate auth service. The built-in module supports magic links, TOTP, and passkeys with minimal config.
- **Not a SaaS**: Fully self-hosted. Your data and API stay on your infrastructure.

## References

- Upstream GitHub: https://github.com/exogee-technology/graphweaver
- Documentation: https://graphweaver.com/docs
- Demo: https://demo.graphweaver.com
- npm: https://www.npmjs.com/package/graphweaver

---
name: KeystoneJS
description: "Developer-first headless CMS and web application framework — define your schema in TypeScript, get a powerful GraphQL API and beautiful Admin UI automatically. Node.js. MIT."
---

# KeystoneJS

Keystone (Keystone 6) is a developer-centric headless CMS and web application framework built on Node.js and TypeScript. You define your data schema in code, and Keystone automatically generates a GraphQL API, a REST API, and a polished Admin UI — no boilerplate required.

Maintained by Thinkmill. MIT licensed. Version 6 (current, published as `@keystone-6/*`) is a complete rewrite from Keystone 5.

Use cases: (a) headless CMS backend for Next.js/Remix/Astro frontends (b) custom content management apps with complex relationships (c) GraphQL API backend with admin interface (d) developer teams wanting schema-as-code instead of GUI-configured CMS (e) replacing Strapi or Directus for TypeScript-heavy teams.

Features:

- **Schema-as-code** — define your data model in TypeScript; Keystone generates everything else
- **GraphQL API** — auto-generated, fully typed; supports queries, mutations, filtering, ordering, pagination
- **REST API** — available alongside GraphQL
- **Admin UI** — beautiful, auto-generated management interface; customizable with React
- **Auth** — built-in authentication: sessions, password auth, magic links; role-based access control
- **Relations** — one-to-one, one-to-many, many-to-many with full GraphQL support
- **Images & files** — built-in image/file fields with local and cloud storage backends
- **Document editor** — rich text editor with embedded content types (BYO renderer)
- **TypeScript-first** — full type safety throughout; generated types for your schema
- **Hooks** — lifecycle hooks (beforeCreate, afterUpdate, etc.) for custom logic
- **Access control** — field-level and list-level access control rules in code

- Upstream repo: https://github.com/keystonejs/keystone
- Homepage: https://keystonejs.com/
- Docs: https://keystonejs.com/docs
- npm: https://www.npmjs.com/package/@keystone-6/core

## Architecture

- **Node.js** (v18+) — TypeScript/JavaScript runtime
- **PostgreSQL** or **SQLite** — database (via Prisma ORM)
- **Prisma** — ORM layer; Keystone generates Prisma schema from your Keystone schema
- **GraphQL** — Apollo Server underpins the API
- **Next.js** — Admin UI is a Next.js app (embedded, not a separate deployment)
- **Optional: Redis** — for session storage at scale

Keystone is a **code-first framework** — there's no pre-built Docker image to download. You create a Node.js project with Keystone as a dependency and define your schema.

## Compatible deploy methods

| Infra       | Runtime              | Notes                                                         |
|-------------|----------------------|---------------------------------------------------------------|
| VPS         | Node.js + PostgreSQL | Standard production; PM2 or systemd process management        |
| Docker      | Custom Dockerfile    | Build your own image; no official image                       |
| Vercel      | Serverless           | Supported for API + Admin UI; needs external PostgreSQL       |
| Railway     | Auto-detect          | Excellent Keystone hosting; PostgreSQL included               |
| Render      | Web service          | Good option with managed PostgreSQL                           |

## Inputs to collect

| Input        | Example                          | Phase   | Notes                                              |
|--------------|----------------------------------|---------|----------------------------------------------------|
| Database URL | `postgresql://user:pass@host/db` | DB      | PostgreSQL recommended for production              |
| Session secret| `cryptographically-random-string` | Auth   | For signing session cookies                        |
| Port         | `3000`                           | Config  | Default; configurable                              |

## Quick start

```sh
npx create-keystone-app@latest my-project
cd my-project
npm run dev
```

Open `http://localhost:3000` for Admin UI, `http://localhost:3000/api/graphql` for GraphQL playground.

See https://keystonejs.com/docs/getting-started for the full walkthrough.

## Schema example

```typescript
// keystone.ts
import { config } from '@keystone-6/core';
import { list } from '@keystone-6/core';
import { text, relationship, timestamp, select, checkbox } from '@keystone-6/core/fields';

export default config({
  db: {
    provider: 'postgresql',
    url: process.env.DATABASE_URL!,
  },
  lists: {
    Post: list({
      fields: {
        title: text({ validation: { isRequired: true } }),
        content: text({ ui: { displayMode: 'textarea' } }),
        publishedAt: timestamp(),
        status: select({
          options: [{ label: 'Draft', value: 'draft' }, { label: 'Published', value: 'published' }],
          defaultValue: 'draft',
        }),
        author: relationship({ ref: 'Author.posts', many: false }),
      },
    }),
    Author: list({
      fields: {
        name: text({ validation: { isRequired: true } }),
        email: text({ isIndexed: 'unique' }),
        posts: relationship({ ref: 'Post.author', many: true }),
      },
    }),
  },
});
```

Running `npm run dev` with this schema generates:
- Full CRUD GraphQL API for Posts and Authors
- Relationship queries (`post.author`, `author.posts`)
- Admin UI with list views, edit forms, and relationship pickers

## GraphQL API usage

```graphql
# Query posts
query {
  posts(where: { status: { equals: "published" } }) {
    id
    title
    publishedAt
    author {
      name
    }
  }
}

# Create a post
mutation {
  createPost(data: {
    title: "Hello World"
    status: "draft"
    author: { connect: { id: "author-id" } }
  }) {
    id
    title
  }
}
```

## Production deployment

```sh
# Build
npm run build

# Start production server
npm start
```

Set environment variables:
```env
DATABASE_URL=postgresql://user:pass@host:5432/keystone
SESSION_SECRET=long-random-secret-string-here
```

## Gotchas

- **Not a traditional CMS** — Keystone doesn't have a pre-built content model. You define everything in code. This is powerful but means a developer must be involved for schema changes, unlike Strapi's GUI-based model builder.
- **Prisma migrations required** — schema changes require running `prisma migrate` (Keystone wraps this as `keystone prisma migrate dev`). In production, run migrations as part of your deployment pipeline.
- **Admin UI is a Next.js build** — `npm run build` compiles the Admin UI. Changes to your schema require a rebuild and redeployment.
- **PostgreSQL recommended for production** — SQLite works for development and small projects but lacks concurrent write support for production. Use PostgreSQL.
- **No built-in image CDN** — Keystone can store uploaded images locally or in S3/cloud, but it doesn't provide image resizing/CDN. Use Thumbor, imgproxy, or a CDN like Cloudflare in front of stored images.
- **Keystone 5 vs 6** — Keystone 5 (`@keystonejs/*`) is the old version in maintenance mode. Keystone 6 (`@keystone-6/*`) is the current version. Don't mix up npm package names.
- **Alternatives:** Strapi (GUI schema builder, broader ecosystem, Node.js), Directus (no-code friendly, PostgreSQL-backed), Payload CMS (TypeScript-first, also schema-as-code), Sanity (SaaS-first, real-time collaboration), Contentful (SaaS only).

## Links

- Repo: https://github.com/keystonejs/keystone
- Homepage: https://keystonejs.com/
- Documentation: https://keystonejs.com/docs
- Getting started: https://keystonejs.com/docs/getting-started
- Examples: https://github.com/keystonejs/keystone/tree/main/examples
- npm: https://www.npmjs.com/package/@keystone-6/core
- Community (Slack): https://community.keystonejs.com/

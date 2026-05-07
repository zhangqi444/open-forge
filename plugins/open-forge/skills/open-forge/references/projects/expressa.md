---
name: expressa
description: Expressa recipe for open-forge. Data-driven extendable REST API middleware for Node.js/Express with JSON schema-based collection management and a built-in admin interface. Source: https://github.com/thomas4019/expressa
---

# Expressa

Data-driven extendable API middleware for Node.js/Express. Define collections as JSON schema, get instant REST endpoints + an admin interface. Supports MongoDB, PostgreSQL, or JSON-file backends. Not a framework — just middleware that integrates with existing Express apps.

Upstream: <https://github.com/thomas4019/expressa>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux/macOS/Windows | Node.js 12+ | Embed in existing Express app or run standalone |
| Any | Docker (custom image) | No official Docker image — wrap in a Dockerfile |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | Node.js version (≥12 recommended) | Check upstream for current compat |
| config | Database backend choice: MongoDB / PostgreSQL / JSON-files | MongoDB and PostgreSQL require separate service |
| config | MongoDB URI or PostgreSQL connection string (if applicable) | e.g. `mongodb://localhost/mydb`, `postgres://user:pass@host/db` |
| config | App port | Default: 3000 |

## Software-layer concerns

### Config paths / env vars

Expressa is configured programmatically in `app.js`. There is no `.env` or config file by convention; pass DB connection strings as environment variables and read them in code:

```js
const express = require('express');
const app = express();
const expressa = require('expressa');

app.use('/admin', expressa.admin({ apiurl: '/api/' }));
app.use('/api', expressa.api({
  db: process.env.DATABASE_URL  // or pass a connection config object
}));

app.listen(process.env.PORT || 3000);
```

### Data dirs

- **JSON-files backend**: data stored in `./collections/` relative to the app root. Mount as a volume if containerised.
- **MongoDB / PostgreSQL**: data stored in the respective external service — no local data dir.

### REST API shape

Once collections are defined in the admin UI, each collection gets:

| Method | Endpoint | Description |
|---|---|---|
| POST | `/users/login` | Auth (JSON body with `email` + `password`) |
| GET | `/:collection` | List all documents |
| GET | `/:collection/:id` | Get one document |
| GET | `/:collection/?query={..}` | MongoDB-style query |
| POST | `/:collection/` | Create document |
| PUT | `/:collection/:id` | Replace document |
| POST | `/:collection/:id/update` | Partial update (mongo update query) |
| DELETE | `/:collection/:id` | Delete document |
| GET | `/:collection/schema` | Get collection schema |

## Install

```bash
mkdir myapp && cd myapp
npm init -y
npm install expressa express body-parser
```

`app.js` minimal example:

```js
const express = require('express');
const app = express();
const expressa = require('expressa');

app.use('/admin', expressa.admin({ apiurl: '/api/' }));
app.use('/api', expressa.api());

app.listen(3000, () => console.log('Running on :3000'));
```

Start:

```bash
node --use-strict app.js
```

Open `http://localhost:3000/admin/` to define collections and manage data.

## Upgrade procedure

```bash
npm update expressa
# Restart the app
```

No built-in migration tooling — verify collection schemas and data after upgrading major versions.

## Gotchas

- **No official Docker image** — wrap in your own Dockerfile if deploying in a container.
- **JSON-files backend is not production-safe for concurrent writes** — use MongoDB or PostgreSQL for multi-user or high-throughput scenarios.
- **New users can self-register by default** — configure permission rules in the admin interface to restrict access before exposing to the internet.
- **Development-stage project** — API surface may change between versions; pin to a specific version in `package.json` for stable production use.

## Links

- Upstream README: <https://github.com/thomas4019/expressa>
- npm: <https://www.npmjs.com/package/expressa>

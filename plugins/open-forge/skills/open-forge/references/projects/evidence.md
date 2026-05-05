---
name: evidence-project
description: Evidence recipe for open-forge. Business intelligence as code — SQL + markdown report generator. Node.js. Upstream: https://github.com/evidence-dev/evidence
---

# Evidence

Business intelligence as code. Generates data-driven reports and dashboards as static websites from SQL queries and markdown files. SQL statements inside markdown files run queries against your data sources; charts and components render the results. Supports PostgreSQL, MySQL, BigQuery, Snowflake, DuckDB, CSV, SQLite, and more via plugins. Upstream: https://github.com/evidence-dev/evidence. Docs: https://docs.evidence.dev

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS/bare-metal | Node.js (CLI build + static serve) | Primary method: npx / npm run build generates static site |
| Docker host | Docker (official image) | Docker image available for containerized builds |
| Netlify / Vercel / Cloudflare Pages | Static site deployment | Recommended for continuous publishing workflows |
| Any static file server (nginx, Caddy, S3) | Static HTML output | Build once, serve anywhere |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Node.js version (18+ required) | Check upstream docs for current LTS requirement |
| datasource | Data source type (PostgreSQL, MySQL, DuckDB, CSV, BigQuery, etc.) | One or more sources configured in sources/ directory |
| datasource | Data source connection string / credentials | Per-source .env or evidence settings file |
| deploy | Where to serve the output? (self-hosted static, Netlify, Vercel, etc.) | Determines deploy workflow |
| deploy | Build schedule? (cron or CI/CD triggered) | Data reports need periodic rebuilds for fresh data |

## Software-layer concerns

### Installation (CLI)

```bash
# Create a new Evidence project
npm create evidence@latest my-project
cd my-project
npm install

# Start development server (live reload)
npm run dev
```

Dev server: http://localhost:3000

### Directory structure

```
my-project/
  pages/           # Markdown report files (.md)
  sources/         # Data source connections
  components/      # Optional custom components
  .env.local       # Local credentials (gitignore this!)
```

### Connecting a data source

Sources are configured in `sources/<source-name>/connection.yaml`:

```yaml
name: my_db
type: postgresql
```

Credentials go in `.env.local` or environment variables:

```
EVIDENCE_SOURCE__my_db__host=localhost
EVIDENCE_SOURCE__my_db__database=mydb
EVIDENCE_SOURCE__my_db__user=user
EVIDENCE_SOURCE__my_db__password=secret
```

Full connector docs: https://docs.evidence.dev/core-concepts/data-sources/

### Writing reports

Reports are standard Markdown files in `pages/`. SQL blocks run queries; component tags render charts:

```markdown
# Sales Report

```sql orders
select * from orders where date > '2024-01-01'
```

<BarChart data={orders} x=date y=amount />
```

### Building for production

```bash
npm run build
# Output: .evidence/template/build/ — serve as static files
```

### Docker

See Docker options in docs: https://docs.evidence.dev/deployment/self-host/

### Self-hosted static serving (nginx example)

```nginx
server {
    root /var/www/evidence-build;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Data refresh strategy

Evidence is build-time: queries run at build time, not live. To refresh data:

- Set up a cron job or CI/CD pipeline to run `npm run build` periodically
- Or use Evidence Cloud for managed scheduling

## Upgrade procedure

```bash
npm update @evidence-dev/evidence
# or to a specific version:
npm install @evidence-dev/evidence@latest
```

Check changelog: https://github.com/evidence-dev/evidence/releases

## Gotchas

- Build-time queries — data is not live; the site reflects data at build time. Schedule rebuilds for fresh reports.
- Credentials must not be committed — keep `.env.local` in .gitignore; use environment secrets in CI/CD.
- Not a live dashboard server — Evidence builds static HTML; it is not a live OLAP server like Metabase or Superset.
- Node.js 18+ required — older Node versions are not supported.
- Source plugin required per database — each data source type (PostgreSQL, MySQL, BigQuery, etc.) needs its corresponding `@evidence-dev/` plugin installed.
- SvelteKit under the hood — Evidence builds a SvelteKit app; most SvelteKit deployment patterns apply.

## Links

- Upstream repo: https://github.com/evidence-dev/evidence
- Documentation: https://docs.evidence.dev
- Data sources: https://docs.evidence.dev/core-concepts/data-sources/
- Self-host deployment: https://docs.evidence.dev/deployment/self-host/
- Examples: https://evidence.dev/examples
- Slack community: https://slack.evidence.dev

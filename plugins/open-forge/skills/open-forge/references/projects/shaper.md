---
name: Shaper
description: Open-source SQL-driven data dashboard tool powered by DuckDB. Build analytics dashboards by writing SQL with special type annotations. Supports multiple data sources, PDF/PNG/CSV export, scheduled reports, and embedded analytics with white-labeling.
website: https://taleshape.com/shaper/docs
source: https://github.com/taleshape-com/shaper
license: proprietary
stars: 1108
tags:
  - analytics
  - dashboards
  - sql
  - business-intelligence
  - duckdb
platforms:
  - Docker
---

# Shaper

Shaper is a SQL-first data dashboard tool built on DuckDB. You define visualizations entirely in SQL by appending type annotations (e.g., `::BARCHART_STACKED`, `::XAXIS`, `::LABEL`) to SELECT columns. It supports querying multiple data sources, embedded analytics with JWT row-level security, automated PDF/CSV/Excel reports, and white-labeling.

Source: https://github.com/taleshape-com/shaper  
Docs: https://taleshape.com/shaper/docs/  
Getting started: https://taleshape.com/shaper/docs/getting-started/

> **License note**: The `taleshape-com/shaper` repository does not have a standard OSS license file prominently displayed — check https://github.com/taleshape-com/shaper/blob/main/LICENSE before production use. Managed hosting available via Taleshape.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker | Recommended; single-container deployment |
| Local machine | Docker | Quickstart for evaluation |
| Kubernetes | Docker image | See deployment guide |

## Inputs to Collect

**Phase: Planning**
- Port to expose (default: `5454`)
- Data sources to connect (CSV files, PostgreSQL, MySQL, SQLite, etc.)
- Whether to enable authentication/JWT for row-level security
- Persistence volume path for dashboards and config

## Software-Layer Concerns

**Quickstart (evaluation):**
```bash
docker run --rm -it -p 5454:5454 taleshape/shaper
# Open http://localhost:5454/new
```

**Production Docker Compose:**
```yaml
services:
  shaper:
    image: taleshape/shaper:latest
    restart: unless-stopped
    ports:
      - 5454:5454
    volumes:
      - shaper_data:/data
      - ./datasources:/datasources:ro   # mount your data files

volumes:
  shaper_data:
```

**Dashboard SQL syntax:**
```sql
-- Title annotation
SELECT 'Sessions per Week'::LABEL;

-- Bar chart with x-axis, category breakdown
SELECT
  date_trunc('week', created_at)::XAXIS,
  category::CATEGORY,
  count()::BARCHART_STACKED
FROM my_dataset
GROUP BY ALL ORDER BY ALL;

-- Metric card
SELECT count()::METRIC FROM orders WHERE status = 'completed';
```

**Supported chart types (via annotations):**
- `::BARCHART`, `::BARCHART_STACKED`, `::LINECHART`, `::AREACHART`
- `::METRIC` (KPI cards), `::TABLE`, `::PIECHART`

**Data sources:** DuckDB can query CSV, Parquet, JSON, PostgreSQL, MySQL, SQLite, S3, and more via DuckDB extensions.

**Ports:**
- `5454` → Web UI + API

## Upgrade Procedure

1. `docker pull taleshape/shaper:latest`
2. `docker-compose down && docker-compose up -d`
3. Check release notes: https://github.com/taleshape-com/shaper/releases

## Gotchas

- **License**: Verify the license terms before commercial use — the repo's license situation is not a standard well-known OSS license; check the LICENSE file
- **DuckDB-powered**: Shaper uses DuckDB as its query engine — powerful for analytical queries but not a transactional database replacement
- **New project**: Repository is relatively young with sparse commit history; expect API/syntax changes
- **Embedded analytics**: White-label embedding and JWT row-level security require understanding of the embedding API — see deployment guide
- **Data sovereignty**: Taleshape offers managed hosting for regulated industries (HIPAA, GDPR, SOC2); for self-hosted, all data stays on your infrastructure
- **No multi-user auth built-in**: Access control for the admin interface is minimal by default; put behind a reverse proxy with auth (Authelia, Nginx basic auth) for multi-user environments

## Links

- Upstream README: https://github.com/taleshape-com/shaper/blob/main/README.md
- Documentation: https://taleshape.com/shaper/docs/
- Getting started: https://taleshape.com/shaper/docs/getting-started/
- Deployment guide: https://taleshape.com/shaper/docs/deploy-to-production/
- Releases: https://github.com/taleshape-com/shaper/releases

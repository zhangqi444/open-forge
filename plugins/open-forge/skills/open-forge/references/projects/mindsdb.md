---
name: MindsDB
description: "AI query engine and federated data platform — connect 200+ data sources, run semantic search, and build conversational analytics agents via a SQL-compatible interface with AI extensions. Python. Elastic License 2.0 (ELv2) core; some components MIT."
---

# MindsDB

MindsDB is an **AI query engine** that sits on top of your existing data sources and lets you query them — plus AI models — using a SQL-like language. Think of it as a "middleware brain": connect your MySQL database, your Postgres warehouse, your Salesforce CRM, your MongoDB collections, and dozens more; then query across all of them together AND run AI operations (text generation, semantic search, classification, forecasting) against that data using simple SQL syntax.

The core idea: **bring AI to data rather than moving data to AI.** Instead of building ETL pipelines to export data into a training environment, you write `CREATE MODEL` and `SELECT` statements that invoke AI models directly against live data. You can also create **Knowledge Bases** (vector stores backed by embeddings) and build **AI agents** that answer natural-language questions about your data.

Use cases: (a) conversational analytics chatbots ("ask questions about your database in plain English") (b) intelligent search over documents + structured data (c) automated data enrichment pipelines (d) predictive analytics + forecasting (e) ETL augmented with LLM transformations (f) federated queries across heterogeneous data sources.

Features:

- **200+ data source integrations** — MySQL, Postgres, MongoDB, Salesforce, Snowflake, BigQuery, Redis, Slack, GitHub, HubSpot, and many more
- **AI/ML integrations** — OpenAI, Anthropic, Hugging Face, LangChain, Ollama, Google Gemini, and custom models
- **Knowledge Bases** — vector + structured hybrid search; ingest documents, databases, files
- **SQL-like query language** — `CREATE MODEL`, `SELECT` with `WHERE`, `JOIN` against AI models
- **AI Agents** — define agents with tools (data sources + APIs); query in natural language
- **Jobs + Triggers** — schedule recurring queries; trigger on data changes (CDC-style)
- **REST API** — programmatic access to all MindsDB operations
- **MindsDB Cloud** — hosted version; or self-host via Docker

- Upstream repo: <https://github.com/mindsdb/mindsdb>
- Homepage: <https://mindsdb.com>
- Docs: <https://docs.mindsdb.com>
- Cloud: <https://cloud.mindsdb.com>

## Architecture in one minute

- **Python** application (Flask-based REST API + custom SQL parser)
- **MySQL-wire-protocol compatible** — connect any MySQL client (DBeaver, TablePlus, mysql CLI) to MindsDB and issue queries
- **Handlers** — each data source / AI provider is a "handler" (plugin); 200+ handlers ship in the repo
- **Predictor storage** — trained model artifacts stored locally or in cloud storage
- **Vector store** — embedded ChromaDB or configurable external stores (Pinecone, Weaviate, pgvector, etc.)
- **Resource**: moderate — 2–4 GB RAM for basic usage; more for large model operations

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | `docker pull mindsdb/mindsdb`                                  | **Recommended self-host path**                                                 |
| Docker Compose     | multi-container with external DB                               | Persistent volumes; production-grade                                           |
| pip (Python)       | `pip install mindsdb`                                          | Dev / exploration; Python 3.8+                                                 |
| MindsDB Cloud      | <https://cloud.mindsdb.com>                                    | Fully managed; free tier available                                             |
| Kubernetes         | Helm chart available                                           | Horizontal scaling for enterprise                                              |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Data source creds    | MySQL host/port/user/pass, Postgres DSN, Salesforce token   | Integrations | Per handler type                                                         |
| AI provider API keys | `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`                       | AI models    | For LLM-backed operations                                                |
| Storage backend      | local filesystem or S3/GCS path                             | Persistence  | Where model artifacts + KB data live                                     |
| Port mappings        | `47334` (HTTP), `47335` (MySQL wire protocol)               | Networking   | Expose for client connections                                            |
| Auth config          | username + password or cloud SSO                            | Security     | Enable auth in production                                                |

## Install (Docker path)

```sh
# Pull and run — exposes HTTP API on 47334, MySQL protocol on 47335
docker run -d \
  --name mindsdb \
  -p 47334:47334 \
  -p 47335:47335 \
  -v $(pwd)/mindsdb_data:/root/mindsdb_storage \
  mindsdb/mindsdb

# Or with environment variables for API keys
docker run -d \
  --name mindsdb \
  -p 47334:47334 \
  -p 47335:47335 \
  -v $(pwd)/mindsdb_data:/root/mindsdb_storage \
  -e OPENAI_API_KEY=sk-... \
  mindsdb/mindsdb
```

Browse to `http://localhost:47334` for the MindsDB Studio UI.

```yaml
# docker-compose.yml (persistent + external config)
version: "3.8"
services:
  mindsdb:
    image: mindsdb/mindsdb
    ports:
      - "47334:47334"
      - "47335:47335"
    volumes:
      - mindsdb_data:/root/mindsdb_storage
    environment:
      - MINDSDB_STORAGE_DIR=/root/mindsdb_storage
    restart: unless-stopped

volumes:
  mindsdb_data:
```

## First boot

1. Browse to `http://localhost:47334` → MindsDB Studio opens
2. Connect a data source (left panel → "Add Data Source" → choose handler)
3. Verify connection: `SHOW DATABASES;` in the SQL editor
4. Create your first model:

```sql
-- Example: text classification using OpenAI
CREATE MODEL sentiment_classifier
PREDICT sentiment
USING
  engine = 'openai',
  prompt_template = 'Classify the sentiment of this text as positive, negative, or neutral: {{text}}',
  model_name = 'gpt-4o-mini';
```

5. Query the model against your data:

```sql
SELECT t.review_text, s.sentiment
FROM my_db.reviews AS t
JOIN sentiment_classifier AS s
WHERE t.created_at > '2024-01-01';
```

6. Create a Knowledge Base for semantic search:

```sql
CREATE KNOWLEDGE BASE product_docs
USING
  model = 'text-embedding-3-small',
  storage = 'chromadb';

INSERT INTO product_docs (content)
SELECT body FROM my_db.documentation_pages;
```

7. Query the Knowledge Base:

```sql
SELECT content, relevance
FROM product_docs
WHERE content = 'how do I reset my password?'
LIMIT 5;
```

## Core concepts

### Handlers / Integrations
Each data source or AI provider is a "handler". Connect via:
```sql
CREATE DATABASE my_postgres
WITH ENGINE = 'postgres',
PARAMETERS = {
  "host": "db.example.com",
  "port": 5432,
  "database": "analytics",
  "user": "readonly",
  "password": "..."
};
```

### Models
Declarative AI model definitions:
```sql
CREATE MODEL forecaster
PREDICT future_revenue
USING
  engine = 'statsforecast',
  time_column = 'date',
  group_columns = ['region'];
```

### Agents
```sql
CREATE AGENT analyst_agent
USING
  model = 'gpt-4o',
  skills = ['sql_tool', 'web_search'],
  description = 'Answer questions about company sales data';

SELECT answer FROM analyst_agent
WHERE question = 'What were the top 5 products last quarter?';
```

### Jobs (scheduled automation)
```sql
CREATE JOB refresh_predictions (
  RETRAIN sales_forecast
)
START '2024-01-01 06:00:00'
REPEAT EVERY day;
```

## Data and config layout

- `/root/mindsdb_storage/` — all persistent state
  - `config/config.json` — main MindsDB config (storage paths, integrations, auth)
  - `predictors/` — trained model artifacts
  - `knowledge_bases/` — vector store data (ChromaDB by default)
  - `integrations/` — handler configs + credentials

## Backup

```sh
# Stop MindsDB, snapshot the storage volume
docker stop mindsdb
tar czf mindsdb-backup-$(date +%F).tgz ./mindsdb_data/
docker start mindsdb

# For cloud-backed storage (S3, GCS), use native bucket snapshots
```

## Upgrade

1. Check releases: <https://github.com/mindsdb/mindsdb/releases>
2. Review changelog — handler APIs can change between minor versions
3. Back up storage volume FIRST
4. `docker pull mindsdb/mindsdb` then stop + remove the old container and re-run with the same volume mount

## Gotchas

- **License: Elastic License 2.0 (ELv2), not OSI open source.** You can run MindsDB for internal use; you cannot offer MindsDB as a managed service/SaaS to others without a commercial agreement. Confirm license fit for your deployment model. Some handlers/components use MIT.
- **"SQL" is not standard SQL.** MindsDB uses a SQL-*like* DSL with custom extensions (`CREATE MODEL`, `JOIN` against AI models, etc.). MySQL clients can connect to the MySQL wire port, but queries must be MindsDB syntax — you cannot use standard ORM queries against it.
- **API key exposure risk.** AI provider keys (OpenAI, Anthropic, etc.) are stored in MindsDB's config. Protect the storage volume and restrict network access to MindsDB's ports. Do not expose ports 47334/47335 publicly without authentication.
- **Resource consumption scales with AI operations.** Running LLM inference against large datasets via `SELECT ... JOIN openai_model` will make many API calls — and cost money. Use `LIMIT`, preview on small samples first, use cheaper models for bulk operations.
- **Cold-start latency for models.** First query after loading a model can be slow (model warm-up, API round trips). Not suitable as a low-latency (<100ms) query path for production user-facing queries.
- **Handlers have variable quality.** With 200+ integrations, not all handlers are equally mature. Check handler-specific docs and GitHub issues before committing to a handler for production use.
- **Knowledge Base sync is manual by default.** After inserting docs into a Knowledge Base, the embeddings are generated once at insert time. Updates to source data do not automatically re-embed — set up a Job to periodically re-sync.
- **MindsDB Cloud vs self-host trade-offs:** Cloud handles scaling + auth + upgrades; self-host gives full data control + no SaaS dependency. For sensitive data (medical, financial), self-host is typically required.
- **Python package install (`pip install mindsdb`) is large** (~1–2 GB with all handler deps). Use Docker for cleaner isolation.
- **No built-in query result caching.** Repeated identical AI queries will re-invoke the model (and re-incur API costs). Add caching at the application layer for frequently repeated queries.
- **Alternatives worth knowing:**
  - **Weaviate** — dedicated vector database; semantic search only; no SQL federated queries
  - **LlamaIndex** — Python framework for RAG; code-first vs SQL-first
  - **LangChain** — agent + chain framework; integrates with MindsDB as a handler
  - **Airbyte** — data integration/ETL without the AI layer; use with dbt + LLM separately
  - **Cube.dev** — semantic layer / BI tool; SQL-based but no native AI model integration
  - **MotherDuck + DuckDB** — fast analytical SQL across data sources; pair with LLM tools externally
  - **Choose MindsDB if:** you want AI + SQL together; your team already thinks in SQL; you need federated queries across many source types with AI transformations in one place.
  - **Choose LlamaIndex/LangChain if:** you prefer Python code-first; you need fine-grained control over RAG pipelines.
  - **Choose Weaviate/Pinecone if:** pure vector search is the primary need with no SQL federation requirement.

## Links

- Repo: <https://github.com/mindsdb/mindsdb>
- Homepage: <https://mindsdb.com>
- Docs: <https://docs.mindsdb.com>
- Cloud: <https://cloud.mindsdb.com>
- Docker Hub: <https://hub.docker.com/r/mindsdb/mindsdb>
- Handlers list: <https://docs.mindsdb.com/integrations/data-overview>
- Community Slack: <https://mindsdb.com/joincommunity>
- Releases: <https://github.com/mindsdb/mindsdb/releases>

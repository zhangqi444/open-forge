# InvenioRDM

**Scalable research data management platform** — turn-key institutional repository for research data and publications. Developed by CERN. Powers Zenodo and many university repositories. Beautiful UI, DOI minting, access controls, communities, versioning, and REST API.

**Official site / docs:** https://inveniordm.docs.cern.ch  
**Source:** https://github.com/inveniosoftware/invenio-app-rdm  
**Demo:** https://inveniordm.web.cern.ch/  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker Compose (via invenio-cli) | Primary install method |
| Kubernetes | Helm chart | Production-scale deployments |

---

## System Requirements

- Docker + Docker Compose
- Python 3.x (for `invenio-cli` install tool)
- `invenio-cli` (PyPI package)

---

## Inputs to Collect

### Provision phase
| Input | Description |
|-------|-------------|
| Instance name | Repository display name |
| `INVENIO_SITE_UI_URL` | Public HTTPS URL |
| `INVENIO_SITE_API_URL` | API endpoint URL |
| Admin email | Initial admin user |

---

## Software-layer Concerns

### Installation via invenio-cli (recommended)
```bash
pip install invenio-cli

# Initialize a new instance
invenio-cli init rdm -c v12.0

cd my-site

# Start services (DB, Redis, ES/OpenSearch, MQ)
invenio-cli services setup

# Run the application
invenio-cli run
```

Full installation guide: https://inveniordm.docs.cern.ch/install/

### Docker Compose (underlying stack)
`invenio-cli` manages a Docker Compose stack internally. The stack includes:

| Service | Purpose |
|---------|---------|
| `web-ui` | Flask web application |
| `web-api` | REST API |
| `worker` | Celery background workers |
| `postgresql` | Primary database |
| `redis` | Caching and session store |
| `opensearch` | Full-text search and indexing |
| `rabbitmq` | Task queue (Celery broker) |

### Configuration
Key config lives in `invenio.cfg` (Python file):
```python
INVENIO_SITE_UI_URL = "https://your-domain.org"
INVENIO_SITE_API_URL = "https://your-domain.org/api"
```

See https://inveniordm.docs.cern.ch/customize/ for the full configuration reference.

### Features
- Upload, publish, and discover research datasets, publications, software
- DOI minting and registration
- Versioning of records and files
- Communities (group-managed collections)
- Granular access controls (open, embargoed, restricted)
- REST API and OAI-PMH harvesting
- Multilingual metadata support
- Statistics (views, downloads)
- Vocabularies (licenses, subjects, funding)
- Built on the Invenio Framework (CERN)

---

## Upgrade Procedure

```bash
# Pull latest images
invenio-cli packages update

# Run DB migrations
invenio-cli shell
# Inside shell:
invenio alembic upgrade
```

Follow the [upgrade guide](https://inveniordm.docs.cern.ch/upgrade/) for each version.

---

## Gotchas

- **Complex stack.** Seven services running simultaneously. Requires significant RAM (8GB+ recommended) for local development.
- **`invenio-cli` is required** — do not attempt to manually manage the Docker Compose stack without it. The CLI handles migrations, secrets, and config generation.
- **HTTPS required in production.** Many features (DOI registration, OAuth) require a valid TLS certificate.
- **DOI registration** requires an account with DataCite or another DOI registration agency.
- **Powered by CERN.** This is the codebase behind Zenodo (https://zenodo.org) and used by dozens of universities globally.
- **Python version matters.** Check `invenio-cli` docs for the required Python version for your target InvenioRDM version.

---

## References

- Install guide: https://inveniordm.docs.cern.ch/install/
- Customization guide: https://inveniordm.docs.cern.ch/customize/
- Upstream README: https://github.com/inveniosoftware/invenio-app-rdm#readme
- Demo: https://inveniordm.web.cern.ch/

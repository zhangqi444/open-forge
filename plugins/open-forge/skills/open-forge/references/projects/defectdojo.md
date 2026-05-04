---
name: defectdojo
description: DefectDojo recipe for open-forge. OWASP flagship DevSecOps and vulnerability management platform. Aggregates findings from 180+ security scanners, deduplicates, tracks remediation, and generates reports.
---

# DefectDojo

OWASP Flagship DevSecOps, ASPM, and vulnerability management platform. Ingests findings from 180+ security scanning tools (SAST, DAST, SCA, container scanning), deduplicates across scans, tracks remediation, and generates compliance reports. Upstream: <https://github.com/DefectDojo/django-DefectDojo>. Docs: <https://documentation.defectdojo.com/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Standard self-hosted deployment |
| Kubernetes / Helm | Production K8s |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Domain for DefectDojo?" | For reverse-proxy TLS |
| preflight | "Admin password?" | Obtained from initializer logs on first run |

## Docker Compose quickstart

```bash
git clone https://github.com/DefectDojo/django-DefectDojo
cd django-DefectDojo
docker compose up -d
```

Wait ~3 minutes for first init to complete, then get admin credentials:

```bash
docker compose logs initializer | grep "Admin password"
```

- UI: http://localhost:8080
- Default username: `admin`

Full guide: <https://documentation.defectdojo.com/getting_started/installation/>

## Key services in the stack

| Service | Role |
|---|---|
| `django-defectdojo` | Main Django app |
| `nginx` | Web server / reverse proxy |
| `postgres` | Database |
| `celery-worker` | Async task queue |
| `redis` | Celery broker |

## CI/CD integration

Upload scan results from any of 180+ supported importers:

```bash
# Upload a Trivy JSON scan result
curl -X POST "http://localhost:8080/api/v2/import-scan/" \
  -H "Authorization: Token <your-api-token>" \
  -F "scan_type=Trivy Scan" \
  -F "engagement=<engagement-id>" \
  -F "file=@trivy-report.json"
```

Supported scanners include: Trivy, Grype, Snyk, Burp Suite, OWASP ZAP, Semgrep, Bandit, SonarQube, Checkov, Terraform, Nuclei, and 170+ more.

## Software-layer concerns

- Port: `8080` (HTTP UI + API)
- API: `http://localhost:8080/api/v2/` (DRF browsable API at `/api/v2/doc/`)
- Auth: token-based API auth; create tokens in Profile → API v2 Key
- Deduplication: DefectDojo auto-deduplicates findings across multiple scans of the same product
- Products / Engagements / Tests: hierarchical structure — Product → Engagement → Test → Finding
- SLA tracking: configure SLA policy per severity; DefectDojo tracks overdue findings

## Upgrade procedure

```bash
cd django-DefectDojo
git pull
docker compose pull
docker compose up -d
```

DB migrations run automatically on startup.

## Gotchas

- First initialization takes 2–3 minutes — wait for `initializer` container to exit before logging in
- Admin password is auto-generated on first run and printed in `initializer` logs — save it
- `docker compose up` (not `docker compose up -d`) for first run makes it easier to see the admin password in output
- Celery worker is required for async tasks (notifications, deduplication background jobs) — don't skip it
- For production, disable debug mode and configure proper database backups

## Links

- GitHub: <https://github.com/DefectDojo/django-DefectDojo>
- Docs: <https://documentation.defectdojo.com/>
- Installation: <https://documentation.defectdojo.com/getting_started/installation/>
- Supported scanners: <https://documentation.defectdojo.com/integrations/parsers/>

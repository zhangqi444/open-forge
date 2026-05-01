# Mayan EDMS

**The most advanced, scalable, and mature open source document management system — full DMS with workflows, OCR, metadata, permissions, and cabinet organization.**
Official site: https://www.mayan-edms.com
Docs: https://docs.mayan-edms.com
GitLab: https://gitlab.com/mayan-edms/mayan-edms

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended — official compose file provided |

---

## Inputs to Collect

### Required
- Review and edit `.env` file (database credentials, secret key, etc.)

---

## Software-Layer Concerns

### Docker Compose (official)
```bash
curl https://gitlab.com/mayan-edms/mayan-edms/-/raw/master/docker/docker-compose.yml -O
curl https://gitlab.com/mayan-edms/mayan-edms/-/raw/master/docker/.env -O
docker compose up --detach
```

The official compose file and `.env` template are the canonical deployment method. Review and update `.env` before starting.

### Key features
- Document storage with full-text search and OCR
- Metadata schemas and cabinet organization
- Workflow and state management
- Role-based access control with detailed permissions
- REST API
- Cabinets, tags, smart links between documents
- Batch actions and bulk processing
- Multi-format document support (PDF, Office, images, and more)

---

## Upgrade Procedure

Follow the official upgrade documentation:
https://docs.mayan-edms.com/parts/installation.html

---

## Gotchas

- Configuration is done via the `.env` file — edit it before first launch
- Full installation and upgrade docs: https://docs.mayan-edms.com/parts/installation.html

---

## References
- Installation guide: https://docs.mayan-edms.com/parts/installation.html
- Documentation: https://docs.mayan-edms.com
- GitLab: https://gitlab.com/mayan-edms/mayan-edms

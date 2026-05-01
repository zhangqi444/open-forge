# WeddingShare (Memtly)

**Self-hosted event photo sharing — rebranded to Memtly for broader event support.**
New project: https://github.com/Memtly/Memtly.Community
Docs: https://docs.memtly.com
GitHub (original): https://github.com/Cirx08/WeddingShare

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Via Memtly.Community repo |

---

## Inputs to Collect

### All phases
- `DOMAIN` — public hostname (e.g. `photos.example.com`)
- `DATA_DIR` — host path for uploaded photos

---

## Software-Layer Concerns

### Note on Rebranding
WeddingShare has rebranded to **Memtly** to support non-wedding events. The original `Cirx08/WeddingShare` repository is archived. New deployments should use the Memtly repository and docs.

### Config
- Refer to https://docs.memtly.com for current configuration options

### Data
- Photo uploads stored in a mounted data directory

---

## Upgrade Procedure

1. Follow instructions at https://docs.memtly.com

---

## Gotchas

- Original WeddingShare repo is archived; use Memtly.Community for new installs
- Rebranding motivated by demand from conferences, birthdays, and other non-wedding events
- Frontend and backend were restructured during the rebrand

---

## References
- [Memtly Community Repo](https://github.com/Memtly/Memtly.Community)
- [Memtly Docs](https://docs.memtly.com)
- [Original WeddingShare README](https://github.com/Cirx08/WeddingShare#readme)

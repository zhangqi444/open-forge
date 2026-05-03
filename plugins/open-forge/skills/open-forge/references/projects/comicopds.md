# ComicOPDS

**What it is:** Lightweight OPDS catalog server for comics and ebooks — lets you browse and download your comic library via any OPDS-compatible reader app.
**Official URL:** https://gitea.baerentsen.space/FrederikBaerentsen/ComicOPDS
**Repo:** https://gitea.baerentsen.space/FrederikBaerentsen/ComicOPDS

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

## Inputs to Collect

### Deploy phase
- Port to expose
- Comics/ebooks library path (mount as volume)

## Software-Layer Concerns

- **Config:** Environment variables (see upstream)
- **Data dir:** Read-only mount of comic library
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image and restart.

## Gotchas

- Read-only OPDS server — does not manage or organize files
- Compatible with Moon+ Reader, Chunky, Panels, and other OPDS clients
- No web UI for reading — only catalog browsing and download

## References

- [Gitea Repo](https://gitea.baerentsen.space/FrederikBaerentsen/ComicOPDS)

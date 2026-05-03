# Hubzilla

**What it is:** Federated community platform supporting ActivityPub and Zot protocols — blogs, forums, file storage, wikis, and social networking with fine-grained privacy controls.
**Official URL:** https://hubzilla.org
**Repo:** https://framagit.org/hubzilla/core

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Community Docker setups available |
| Any Linux | Bare metal (PHP) | Official installation method |

## Inputs to Collect

### Deploy phase
- Domain/hostname (permanent)
- Web server (Apache/Nginx)
- PHP 7.4+ and required extensions
- MySQL/MariaDB credentials
- Admin username and email

## Software-Layer Concerns

- **Config:** .htconfig.php in webroot
- **Data dir:** store/ directory for uploaded files
- **Key env vars:** N/A — PHP config file

## Upgrade Procedure

```bash
cd /path/to/hubzilla
git pull
php util/update.php
```

## Gotchas

- Federated with ActivityPub AND Zot (Nomadic Identity) — complex federation model
- "Nomadic identity" lets users move/clone accounts across hubs
- Requires PHP with multiple extensions (curl, gd, imagick, etc.)
- More complex than typical fediverse software

## References

- [Official Site](https://hubzilla.org)
- [Install Docs](https://framagit.org/hubzilla/core/-/blob/main/install/INSTALL.txt)

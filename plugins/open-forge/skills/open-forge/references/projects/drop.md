# Drop

Open-source game distribution platform — self-hosted Steam/GameVault alternative for DRM-free games.

- **Official site:** https://droposs.org
- **Docs:** https://docs.droposs.org/
- **Repo:** https://github.com/Drop-OSS/drop
- **Forum:** https://forum.droposs.org
- **Discord:** https://discord.gg/ACq4qZp4a9
- **License:** AGPL 3.0

---

## What it does

Drop lets you host your own game library and distribute DRM-free games to users, similar to how Steam or GameVault works but fully self-hosted.

Design principles:
- **Flexible** — extensible architecture with interfaces and abstractions
- **Secure** — authentication required; supports username/password, SSO, and multiple auth mechanisms; no unauthenticated access possible
- **User-friendly** — clean UI with advanced features available

---

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker / Compose | Recommended; see official quickstart |
| Any Linux server | Native | Check docs for native install instructions |

---

## Inputs to collect

Refer to the official quickstart guide at https://docs.droposs.org/docs/guides/quickstart for current environment variables, volume paths, and port configuration — the upstream README defers entirely to the docs site.

Typical self-hosted game platform requirements:
- Storage path for game files (can be large — plan accordingly)
- Admin credentials / SSO configuration
- Database connection (check docs for embedded vs external DB)
- Domain / reverse proxy config for HTTPS

---

## Software-layer concerns

### Storage
Game libraries can be very large (tens to hundreds of GB). Ensure the volume backing game file storage has sufficient capacity and appropriate I/O performance.

### Authentication
Drop enforces authentication on all routes — no anonymous access. Configure at minimum a local admin account; SSO can be added later.

### Compose (placeholder — verify against docs)
```yaml
# See https://docs.droposs.org/docs/guides/quickstart for the canonical compose file.
# Do not rely on this placeholder; upstream docs may have changed.
services:
  drop:
    image: ghcr.io/drop-oss/drop:latest   # verify image name in docs
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./data:/data
      - /path/to/games:/games
    environment:
      - DATABASE_URL=...    # check docs
```

---

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check the [changelog](https://github.com/Drop-OSS/drop/releases) for migration notes before major version upgrades.

---

## Gotchas

- Upstream README is minimal — the docs site (https://docs.droposs.org/) is the authoritative source; always check there before deploying.
- Game file storage can grow very large; plan disk capacity before provisioning.
- AGPL license: if you modify Drop and offer it as a network service, you must publish your modifications.
- Authentication is always required; there is no "public" mode.

---

## Further reading

- Quickstart guide: https://docs.droposs.org/docs/guides/quickstart
- Full docs: https://docs.droposs.org/
- GitHub releases: https://github.com/Drop-OSS/drop/releases
- Community forum: https://forum.droposs.org
- Discord: https://discord.gg/ACq4qZp4a9
- Contributing guide: https://github.com/Drop-OSS/drop/blob/main/CONTRIBUTING.md

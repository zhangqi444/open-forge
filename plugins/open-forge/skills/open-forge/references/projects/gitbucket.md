# GitBucket

GitHub-compatible Git platform written in Scala. GitBucket is a self-hosted Git service offering repository hosting, issues, pull requests, wiki, and a plugin ecosystem — all accessible via a GitHub-compatible API.

**Official site:** https://github.com/gitbucket/gitbucket

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker / Docker Compose | Official image on Docker Hub |
| Any Linux host | WAR deployment | Requires Java 17; run `java -jar gitbucket.war` |
| Kubernetes | Helm (community) | community charts available |

---

## Inputs to Collect

### Phase 1 — Planning
- Preferred port (default `8080`)
- External URL / domain for clone URLs
- Storage path for data (`HOME/.gitbucket` or custom)
- Database backend: embedded H2 (default, file-based) or external MySQL/PostgreSQL

### Phase 2 — Deployment
- `GITBUCKET_PORT` — port to expose
- Database connection details if using MySQL/PostgreSQL
- SSH port for Git-over-SSH (default `29418`)

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  gitbucket:
    image: gitbucket/gitbucket:latest
    ports:
      - "8080:8080"
      - "29418:29418"       # Git over SSH
    volumes:
      - gitbucket-data:/gitbucket
    environment:
      - JAVA_OPTS=-Xmx512m
    restart: unless-stopped

volumes:
  gitbucket-data:
```

### Config Paths
- Data dir: `/gitbucket` (inside container) or `~/.gitbucket` on host
- `gitbucket.conf` — main config (base URL, SMTP, SSH settings)
- Database config in `database.conf` (H2 default; switch to MySQL/PostgreSQL for production)

### Environment Variables
| Variable | Description |
|----------|-------------|
| `JAVA_OPTS` | JVM tuning (e.g. `-Xmx512m`) |
| `GITBUCKET_PORT` | HTTP port (default 8080) |

### Initial Credentials
Default admin login: **root / root** — **change immediately after first login**.

### Git-over-SSH
SSH port `29418` must be mapped and open. Set base URL in admin settings so clone URLs resolve correctly.

### External Database
Switch from embedded H2 to MySQL or PostgreSQL via System Administration → Database. Back up H2 data first; migration script provided in the UI.

---

## Upgrade Procedure

1. Pull new image: `docker pull gitbucket/gitbucket:latest`
2. Stop container, replace WAR or pull image, restart.
3. GitBucket auto-runs DB schema migrations on startup.
4. Verify at admin → System → Database.

---

## Gotchas

- **Default password is `root`** — must be changed on first login.
- **H2 is not suitable for production** — migrate to MySQL 8+ or PostgreSQL for multi-user deployments.
- **SSH port 29418** is non-standard; firewall rules and clone URL base must be configured in admin settings.
- **Plugins** extend functionality (wiki, CI integration, Slack notifications); install via admin → Plugins.
- **GitHub API compatibility** allows many GitHub-aware tools (e.g., CI agents) to work with GitBucket out of the box.
- **Java 17 required** for the WAR distribution.

---

## References
- GitHub: https://github.com/gitbucket/gitbucket
- Wiki / docs: https://github.com/gitbucket/gitbucket/wiki
- Docker Hub: https://hub.docker.com/r/gitbucket/gitbucket
- Plugins: https://github.com/gitbucket/gitbucket/wiki/Community-Plugins

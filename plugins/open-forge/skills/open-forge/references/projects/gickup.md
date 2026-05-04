---
name: gickup
description: Recipe for Gickup — a tool to mirror/backup Git repositories across hosting providers.
---

# Gickup

Tool for cloning and mirroring Git repositories from one hosting provider to another (or to local disk / S3). Runs on a schedule via cron or one-shot. Supports GitHub, GitLab, Codeberg/Forgejo, Gitea, Gogs, Bitbucket, OneDev, Sourcehut, and arbitrary Git hosts as sources. Destinations include all of the above plus local filesystem and S3. Upstream: <https://github.com/cooperspencer/gickup>. Docs: <https://cooperspencer.github.io/gickup-documentation/>. License: Apache-2.0. ~2K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/cooperspencer/gickup#how-to-run-the-docker-image> | ✅ | Recommended for scheduled runs via cron |
| Binary | <https://github.com/cooperspencer/gickup/releases> | ✅ | Bare-metal or systemd timer |
| Go build from source | <https://github.com/cooperspencer/gickup#compile-the-binary-version> | ✅ | Development |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| software | "Which source hosting provider(s)?" | Multi-select: GitHub / GitLab / Gitea / Codeberg / Bitbucket / Gogs / OneDev / Sourcehut / other | All methods |
| software | "API token for each source?" | Sensitive string per provider | All methods |
| software | "Where to mirror to? (local path / another Gitea / S3 / etc.)" | Free-text | All methods |
| software | "Run on a cron schedule or one-shot?" | cron expression / one-shot | Docker / binary |

## Software-layer concerns

### Docker Compose

```yaml
version: "3"
services:
  gickup:
    image: buddyspencer/gickup:latest
    volumes:
      - ./conf.yml:/gickup/conf.yml
      - ./repos:/repos   # local destination, if using local backend
    command: ["/gickup/conf.yml"]
    restart: unless-stopped
    # Uncomment to set local timezone for cron expressions:
    # environment:
    #   - TZ=America/New_York
```

### Configuration file (`conf.yml`)

The entire configuration lives in a single YAML file. Minimal example — mirror all repos from a GitHub user to a local directory:

```yaml
source:
  github:
    - token: ghp_your_token_here
      user: your-github-username

destination:
  local:
    - path: /repos
      structured: true   # organises into /repos/<provider>/<user>/<repo>
```

Annotated multi-provider example (see upstream `conf.example.yml` for full reference):
<https://github.com/cooperspencer/gickup/blob/main/conf.example.yml>

### Cron scheduling (within conf.yml)

```yaml
cron: "0 2 * * *"   # run at 2 AM daily
```

If `cron` is omitted, Gickup runs once and exits — suitable for a systemd timer or Kubernetes CronJob.

### Supported source providers

- GitHub (token, ssh, username/password; includes gists, starred, wikis, issues)
- GitLab (token, ssh; includes wikis)
- Codeberg / Forgejo (token, ssh)
- Gitea (token, ssh)
- Gogs (token, ssh)
- Bitbucket (app password)
- OneDev (token)
- Sourcehut (token)
- Any (`url:` list — plain Git clone)

### Supported destination providers

GitHub, GitLab, Codeberg/Forgejo, Gitea, Gogs, OneDev, Sourcehut, **local filesystem**, **S3**

### Repository filters (per source)

```yaml
filter:
  stars: 50               # minimum star count
  lastactivity: 6m        # only repos active in last 6 months
  excludearchived: true
  excludeforks: true
  languages:
    - go
    - python
```

### Data directory

`/repos` (or your configured `destination.local.path`) — the mirrored repos. No internal database; state is the filesystem.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No database migrations. All configuration is in `conf.yml`.

## Gotchas

- **Token scopes**: GitHub token needs `repo` scope to mirror private repos; `public_repo` is sufficient for public-only mirroring.
- **Rate limits**: Mirroring many repos quickly can hit provider API rate limits. Use the `filter` options to limit scope, or stagger cron runs.
- **SSH vs HTTPS**: SSH cloning requires mounting an SSH key into the container (`-v ~/.ssh:/root/.ssh:ro`).
- **Destination auth**: When mirroring to another Gitea/Forgejo, the destination token must have permission to create repositories.
- **`structured: true` recommended**: Without it, all repos land flat in the destination directory, which can cause name collisions across orgs.
- **`issues: true` is local-only**: Issue backups only work with the local filesystem destination, not remote Git hosts.

## Links

- GitHub: <https://github.com/cooperspencer/gickup>
- Docs: <https://cooperspencer.github.io/gickup-documentation/>
- Docker Hub: <https://hub.docker.com/r/buddyspencer/gickup>
- Example config: <https://github.com/cooperspencer/gickup/blob/main/conf.example.yml>

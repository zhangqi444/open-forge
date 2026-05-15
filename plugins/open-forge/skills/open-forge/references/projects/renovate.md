---
name: renovate
description: Recipe for Renovate — automated dependency update bot supporting 90+ package managers and 10+ Git platforms.
---

# Renovate

Automated dependency update tool. Scans repositories for dependency references (npm, Docker, Helm, GitHub Actions, pip, Maven, Gradle, Go modules, and 90+ more), detects newer versions, and opens pull/merge requests to update them automatically. Supports GitHub, GitLab, Gitea, Forgejo, Bitbucket, Azure DevOps, and more. Self-hosted via Docker or as a CLI. Highly configurable via `renovate.json`. Upstream: <https://github.com/renovatebot/renovate>. Docs: <https://docs.renovatebot.com>. License: AGPL-3.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (self-hosted) | <https://docs.renovatebot.com/self-hosted-configuration/> | Yes | Recommended; run on a schedule via cron or CI |
| npm global | `npm install -g renovate` | Yes | Run directly on host without Docker |
| Mend Renovate app (cloud) | <https://github.com/apps/renovate> | Yes (managed) | GitHub/Bitbucket cloud — no self-hosting needed |
| GitLab CI pipeline | <https://docs.renovatebot.com/getting-started/running/#gitlab-runner> | Yes | Run inside GitLab CI on a schedule |
| GitHub Actions | <https://docs.renovatebot.com/getting-started/running/#github-actions> | Yes | Run via GitHub Actions on a schedule |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| software | Git platform? | github / gitlab / gitea / bitbucket / azure | Required |
| software | Platform API token? | Personal access token with repo + PR permissions | Required |
| software | Repositories to scan? | owner/repo or :all: | Required; comma-separated list or :all: for all accessible repos |
| software | GitHub token for release notes? | GitHub PAT (read-only) | Optional; improves changelogs in PRs |
| infra | Schedule (cron expression)? | e.g. 0 2 * * * | Optional; controls when Renovate runs |

## Software-layer concerns

### Docker run (simplest)

```bash
docker run --rm \
  -e RENOVATE_TOKEN=your_platform_token \
  -e RENOVATE_PLATFORM=github \
  -v /tmp/renovate:/tmp/renovate \
  renovate/renovate:43.180 \
  owner/repo1 owner/repo2
```

### Docker Compose with scheduled cron

```yaml
services:
  renovate:
    image: renovate/renovate:43.180
    restart: "no"    # run once then exit; use cron or a loop to schedule
    environment:
      RENOVATE_TOKEN: your_platform_token
      RENOVATE_PLATFORM: github        # or gitlab, gitea, etc.
      RENOVATE_AUTODISCOVER: "true"    # scan all accessible repos
      RENOVATE_GIT_AUTHOR: "Renovate Bot <renovate@example.com>"
      LOG_LEVEL: debug
    volumes:
      - /tmp/renovate:/tmp/renovate
      - ./config.js:/usr/src/app/config.js:ro   # optional global config
```

Run via cron: `0 */6 * * * docker compose -f /opt/renovate/docker-compose.yml up --no-log-prefix`

### config.js (global self-hosted config)

```javascript
module.exports = {
  platform: 'github',
  token: process.env.RENOVATE_TOKEN,
  repositories: [
    'owner/repo1',
    'owner/repo2',
  ],
  // Optional: onboarding PR to add renovate.json to repos that lack it
  onboarding: true,
  onboardingConfig: {
    extends: ['config:recommended'],
  },
  // Rate limiting
  prHourlyLimit: 2,
  prConcurrentLimit: 10,
};
```

### Per-repo renovate.json

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "schedule": ["before 3am on monday"],
  "prCreation": "not-pending",
  "labels": ["dependencies"],
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true
    }
  ]
}
```

### Gitea / self-hosted Git platform

```javascript
module.exports = {
  platform: 'gitea',
  endpoint: 'https://gitea.example.com',
  token: process.env.RENOVATE_TOKEN,
  gitAuthor: 'Renovate Bot <renovate@gitea.example.com>',
  repositories: ['org/repo'],
};
```

## Upgrade procedure

```bash
docker pull renovate/renovate:43.180
# Re-run via cron or manually
```

Renovate releases very frequently (often daily). Pinning a version is recommended for stability; use Renovate itself to keep it updated.

## Gotchas

- Token permissions: the platform token needs: repo read/write, PR/MR create, and commit status. For GitLab, use a Project/Group token with `api` scope.
- `RENOVATE_AUTODISCOVER`: convenient but can create PRs on unexpected repos. Start with an explicit `repositories` list.
- Rate limits: GitHub and GitLab have API rate limits. Use `prHourlyLimit` and `prConcurrentLimit` to avoid hitting them.
- onboarding PR: by default, Renovate opens an "onboarding" PR to add `renovate.json` to repos. Disable with `onboarding: false` if you pre-configure repos.
- Disk space: Renovate clones repos to `/tmp/renovate`. Bind-mount this to a persistent volume or regularly prune it.
- No persistent daemon: Renovate is a run-once CLI tool. Use cron, GitHub Actions, or a loop container to run it periodically.
- Self-hosted requires outbound internet: to fetch package metadata from npm, PyPI, Docker Hub, etc. Air-gapped installs need a private registry mirror.

## Links

- GitHub: <https://github.com/renovatebot/renovate>
- Docs: <https://docs.renovatebot.com>
- Self-hosting guide: <https://docs.renovatebot.com/self-hosted-configuration/>
- Docker Hub: <https://hub.docker.com/r/renovate/renovate>
- Mend hosted app (GitHub): <https://github.com/apps/renovate>
- Configuration options reference: <https://docs.renovatebot.com/configuration-options/>

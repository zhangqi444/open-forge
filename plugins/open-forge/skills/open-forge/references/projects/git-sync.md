# git-sync

**CLI tool to backup and sync all your Git repositories locally — supports GitHub, GitLab, Bitbucket, Gitea, and Forgejo. Bare clones by default for minimal storage, with periodic cron sync.**
Docs/Wiki: https://github.com/AkashRajpurohit/git-sync/wiki
GitHub: https://github.com/AkashRajpurohit/git-sync

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker | Config file mounted into container |
| Any Linux | Binary (Go) | Download from GitHub releases |
| Any Linux | systemd | Systemd unit file provided in repo |

---

## Inputs to Collect

### Required
- `username` — your Git platform username
- `tokens` — list of personal access tokens (needs `repo` scope)
- `backup_dir` — local path where repos will be cloned
- `platform` — `github`, `gitlab`, `bitbucket`, `gitea`, or `forgejo`

### Optional
- `cron` — schedule (e.g. `0 0 * * *` for daily at midnight)
- `include_forks` / `exclude_repos` / `include_orgs` — filter what gets backed up
- Notification config (ntfy, Gotify)

---

## Software-Layer Concerns

### config.yaml (required)
Default location: `~/.config/git-sync/config.yaml`

```yaml
username: your-username
tokens:
  - your-personal-access-token
backup_dir: /backups
platform: github
clone_type: bare        # bare (default), shallow, mirror, or full
cron: 0 0 * * *         # run daily at midnight
concurrency: 5
include_forks: false
include_wiki: true
include_issues: false
include_repos: []
exclude_repos: []
include_orgs: []
retry:
  count: 3
  delay: 10             # seconds
notification:
  enabled: false
telemetry:
  enabled: true         # anonymous; set false to opt out
```

### Docker
```bash
docker run -d \
  -v /path/to/config.yaml:/git-sync/config.yaml \
  -v /path/to/backups:/backups \
  ghcr.io/akashrajpurohit/git-sync \
  --config /git-sync/config.yaml --backup-dir /backups
```

### Clone types
- `bare` — minimal disk usage, full git history (default)
- `shallow` — recent history only
- `mirror` — full mirror including refs
- `full` — standard working-tree clone

---

## Upgrade Procedure

- Docker: pull latest image and re-run
- Binary: download new release from GitHub releases

---

## Gotchas

- Token needs `repo` scope to read private repositories
- `bare` clones are not directly usable as working directories — use `git clone <bare-path>` to restore
- `include_issues` backup is only supported for GitHub and GitLab
- Periodic backup setup guide: https://github.com/AkashRajpurohit/git-sync/wiki/Setup-Periodic-Backups

---

## References
- Wiki / Documentation: https://github.com/AkashRajpurohit/git-sync/wiki
- GitHub: https://github.com/AkashRajpurohit/git-sync#readme

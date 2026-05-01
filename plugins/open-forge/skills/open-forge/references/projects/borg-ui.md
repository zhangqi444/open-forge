---
name: Borg UI
description: "Modern web interface for BorgBackup. Docker. karanhudia/borg-ui. Repository management, live backup progress, archive browsing, restore, schedules, Apprise notifications, SSH remote machines."
---

# Borg UI

**Modern web interface for BorgBackup.** Run backups, browse archives, restore files, manage repositories, and automate schedules from a single UI — without dropping to the CLI. Supports local, SSH, and SFTP Borg repositories. Live backup progress, pre/post hooks, 100+ Apprise notification services, remote machine management with SSH key deployment. Multi-arch (amd64, arm64, armv7). AGPL-3.0.

Built + maintained by **Karan Hudia**.

- Upstream repo: <https://github.com/karanhudia/borg-ui>
- Docs: <https://docs.borgui.com>
- Docker Hub: <https://hub.docker.com/r/ainullcode/borg-ui>
- Discord: <https://discord.gg/5KfVa5QkdQ>
- Website: <https://borgui.com>

## Architecture in one minute

- Web UI (frontend) + backend API — shipped as a single Docker image
- Port **8081**
- Persistent data in `/data` volume (config, job state, schedules)
- BorgBackup binary bundled in the container
- Connects to BorgBackup repositories on local mounts, SSH hosts, or SFTP
- Resource: **low** — runs on any machine that also runs BorgBackup

## Compatible install methods

| Infra        | Runtime                    | Notes                                                   |
| ------------ | -------------------------- | ------------------------------------------------------- |
| **Docker**   | `ainullcode/borg-ui`       | **Primary** — Docker Hub                                |

## Inputs to collect

| Input                      | Example                         | Phase    | Notes                                                                                   |
| -------------------------- | ------------------------------- | -------- | --------------------------------------------------------------------------------------- |
| Local mount for backups    | `/home/yourusername:/local:rw`  | Storage  | Mount host paths you want to back up into the container                                 |
| Borg data + cache volumes  | `borg_data:/data`               | Storage  | Persistent Borg UI config + cache                                                       |
| SSH key (for remote repos) | generate inside container       | Auth     | Borg UI can manage SSH key deployment to remote machines                                |
| Apprise URL (optional)     | various                         | Notify   | Any of 100+ Apprise notification services for backup alerts                             |

## Install via Docker

```bash
docker run -d \
  --name borg-web-ui \
  -p 8081:8081 \
  -v borg_data:/data \
  -v borg_cache:/home/borg/.cache/borg \
  -v /home/yourusername:/local:rw \
  ainullcode/borg-ui:latest
```

Visit `http://localhost:8081`. Default login: `admin` / `admin123` — **change immediately**.

## Install via Docker Compose

```yaml
services:
  borg-ui:
    image: ainullcode/borg-ui:latest
    container_name: borg-web-ui
    ports:
      - "8081:8081"
    volumes:
      - borg_data:/data
      - borg_cache:/home/borg/.cache/borg
      - /home/yourusername:/local:rw    # mount what you want to back up
    restart: unless-stopped

volumes:
  borg_data:
  borg_cache:
```

Add additional `-v /path/to/backup-source:/mnt/source:ro` volume mounts for each directory you want to include in backups.

## First boot

1. Deploy container.
2. Visit `http://localhost:8081` → log in with `admin` / `admin123`.
3. **Change the admin password immediately** (Settings → Change Password).
4. Add a **repository** (Repositories → Add):
   - Local: path inside the container (e.g. `/local/backups/myrepo`)
   - SSH: `user@host:/path/to/repo`
   - Initialize the repo if it doesn't exist yet.
5. Create a **backup job** — select source paths + repository + compression.
6. Set up a **schedule** (cron-like) for automated backups.
7. Configure **notifications** via Apprise for failure/success alerts.
8. Test: run a manual backup → browse the archive → verify restore works.
9. Optionally set up **remote machine** management (SSH key deployment for remote Borg repos).
10. Put behind TLS if accessing remotely.

## Features overview

| Feature | Details |
|---------|---------|
| Repository management | Add/remove local, SSH, and SFTP Borg repos |
| Live backup progress | Real-time progress bar + file count + transfer rate |
| Archive browser | Browse contents of any archive; restore files/dirs |
| Restore workflow | Select archive → browse → trigger restore |
| Schedules | Cron-based automated backup schedules |
| Pre/post hooks | Run commands before/after backup jobs |
| Notifications | 100+ Apprise services (email, Slack, Discord, etc.) |
| Remote machines | SSH key deployment + storage visibility on remote hosts |
| Maintenance | Borg check + prune + compact from the UI |
| BorgBackup 1.x + 2.x | Supports both Borg generations |
| Multi-arch | amd64, arm64, armv7 |

## Backup of Borg UI itself

Borg UI config lives in `/data` — back it up so you don't lose repository passwords + schedules:

```sh
docker compose stop borg-ui
sudo tar czf borg-ui-config-$(date +%F).tgz <borg_data_volume>/
docker compose start borg-ui
```

> The actual backup archives are in your Borg repository, not in `/data`. `/data` holds only Borg UI's config (repo configs, schedules, notification settings, credentials).

## Upgrade

1. Releases: <https://github.com/karanhudia/borg-ui/releases>
2. `docker compose pull && docker compose up -d`

## Gotchas

- **Default credentials are `admin` / `admin123`.** Change immediately — this is well-known.
- **Mount source directories into the container.** BorgBackup runs inside the container — it can only back up paths that are mounted in. Map everything you want backed up as Docker volumes or bind mounts.
- **Borg repository passwords are stored by Borg UI.** They're in `/data` — treat the volume as sensitive. If you lose `/data`, you lose the passphrase and can't decrypt your archives.
- **Cache volume speeds up Borg operations.** The `borg_cache` volume holds Borg's local cache (index of repository contents). Without it, every operation re-reads the repository from scratch. Don't skip this volume mount.
- **SSH repos require key setup.** Borg UI can generate + deploy SSH keys to remote machines (Remote Machines feature). Do this before adding SSH repositories.
- **BorgBackup 2 beta support.** Borg 2 is a significant protocol change; Borg UI supports it but test workflows carefully if using Borg 2 repos.
- **`borg-ui-runtime-base` image is internal.** The README notes this — don't use it directly; it's a CI artifact. Use `ainullcode/borg-ui`.
- **AGPL-3.0 license.** Serving modified Borg UI over a network requires source publication.
- **Coverage is 58–81%.** Upstream is transparent about test coverage — a younger project; verify critical workflows (restore especially) after upgrades.
- **Enterprise support available.** If you need commercial support or a larger rollout, the team offers enterprise options at borgui.com/buy.

## Project health

Active development, Docker CI (GitHub Actions), Docker Hub, docs site, Discord, multi-arch, test suites. Solo-maintained by Karan Hudia. AGPL-3.0.

## BorgBackup-UI-family comparison

- **Borg UI** — Docker, full web UI, schedules, Apprise, remote machine management, archive browser
- **Vorta** — Qt desktop GUI for BorgBackup; local machine only; no web UI
- **Borgmatic** — CLI wrapper for BorgBackup automation; no web UI
- **BorgBase** — SaaS Borg repository hosting; not a UI for self-hosted repos

**Choose Borg UI if:** you want a web-based dashboard for your self-hosted BorgBackup repositories — running backups, browsing archives, and managing schedules without CLI.

## Links

- Repo: <https://github.com/karanhudia/borg-ui>
- Docs: <https://docs.borgui.com>
- Docker Hub: <https://hub.docker.com/r/ainullcode/borg-ui>
- Discord: <https://discord.gg/5KfVa5QkdQ>
- BorgBackup docs: <https://borgbackup.readthedocs.io>
- Borgmatic (CLI alt): <https://torsion.org/borgmatic>

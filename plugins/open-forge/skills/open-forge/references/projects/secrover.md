---
name: secrover
description: Recipe for Secrover — open-source security audit report generator. Scans dependencies (osv-scanner), code (opengrep), and domains (SSL, headers, ports). Runs via Docker one-shot or scheduled cron. Exports HTML reports to SFTP/S3/WebDAV/Google Drive.
---

# Secrover

Open-source security audit report generator. Upstream: https://github.com/Secrover/Secrover

Generates clear, actionable HTML security reports by scanning: dependencies (osv-scanner — all languages), code (opengrep static analysis — all languages), and domains (SSL cert, HSTS, HTTP→HTTPS redirect, TLS versions, open ports, security headers, hosting location). Config-driven via YAML. Runs as a Docker one-shot command, GitHub Actions workflow, or scheduled cron. Exports reports via rclone to SFTP, WebDAV, SMB, S3, or Google Drive.

Demo: https://demo.secrover.org

## Compatible combos

| Method | Notes |
|---|---|
| Docker one-shot | Run manually to generate a report on demand |
| GitHub Actions | Copy workflow from secrover-demo repo — auto-generates and deploys to GitHub Pages |
| Self-hosted cron | Schedule recurring scans via built-in cron support |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | config.yaml | List of repos and domains to scan — see format below |
| preflight | Output directory | Where the HTML report will be written |
| private repos (opt) | GitHub PAT | Fine-grained token with Contents: Read-only for private repos |
| export (opt) | rclone destination | SFTP/WebDAV/SMB/S3/Google Drive config for remote report delivery |

## config.yaml format

```yaml
project:
  name: My Project

domains:
  - example.com
  - subdomain.example.com

repos:
  - url: https://github.com/your-org/your-repo
    description: "Main application"
    branch: "main"

  - url: https://github.com/your-org/private-repo
    description: "Private service"
    branch: "main"
    token: ghp_your_pat_here   # or use GITHUB_TOKEN env var
```

## Software-layer concerns

**One-shot pattern:** Secrover runs, generates the report, and exits. It is not a long-running web server.

**Output:** HTML report file written to the output directory. Serve it via GitHub Pages, nginx, S3 static hosting, or any static file server.

**Private repositories:** Pass a GitHub PAT (fine-grained, Contents: Read-only) either inline in config.yaml or via environment variable.

**Remote export:** Uses rclone — configure rclone destination in the Docker run command or environment. See upstream README for export configuration.

**No persistent data:** Stateless — each run generates a fresh report. No database, no volume needed beyond the output directory.

## Docker run (one-shot)

```bash
docker run --rm \
  -v $(pwd)/config.yaml:/app/config.yaml \
  -v $(pwd)/reports:/app/reports \
  secrover/secrover:latest
```

The HTML report is written to `./reports/`.

For private repos, add:
```bash
  -e GITHUB_TOKEN=ghp_your_token \
```

## GitHub Actions (recommended for automation)

Copy the workflow from the demo repository:
https://github.com/secrover/secrover-demo/blob/main/.github/workflows/secrover.yml

This pulls the latest Secrover image, runs scans, generates an HTML report, and deploys to GitHub Pages automatically.

## Upgrade procedure

```bash
docker pull secrover/secrover:latest
```

No state to migrate — stateless tool.

## Gotchas

- **One-shot, not a daemon** — Secrover exits after generating the report. Use cron, GitHub Actions, or a task scheduler to run it on a schedule.
- **Report is HTML** — designed to be published/served as a static file, not viewed directly from the container.
- **osv-scanner + opengrep require cloning repos** — repos are cloned temporarily during the scan; sufficient disk space and network access required.
- **Private repo HTTPS only** — SSH clone is not supported. Use HTTPS with a PAT.

## Links

- Upstream repository: https://github.com/Secrover/Secrover
- Docker Hub: https://hub.docker.com/r/secrover/secrover
- Demo report: https://demo.secrover.org
- Demo GitHub Actions workflow: https://github.com/secrover/secrover-demo

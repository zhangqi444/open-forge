---
name: trufflehog
description: TruffleHog recipe for open-forge. Covers Docker and binary installation for scanning Git repos, filesystems, S3, GitHub/GitLab orgs, and CI/CD pipelines for leaked credentials and secrets. Sourced from https://github.com/trufflesecurity/trufflehog.
---

# TruffleHog

Secrets discovery, classification, validation, and analysis tool. Finds leaked credentials (API keys, database passwords, private keys, tokens) across Git history, filesystems, S3 buckets, GitHub/GitLab orgs, CI logs, and more. Classifies 800+ secret types and validates liveness by attempting authentication. Upstream: https://github.com/trufflesecurity/trufflehog. By Truffle Security.

TruffleHog is primarily a CLI scanner, not a persistent server — it runs on demand or in CI/CD pipelines. An enterprise SaaS version (TruffleHog Enterprise) exists for continuous monitoring.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker | https://github.com/trufflesecurity/trufflehog#docker | One-off scans; no install needed |
| Binary (GitHub Releases) | https://github.com/trufflesecurity/trufflehog/releases | Persistent local installs |
| Homebrew (macOS) | https://github.com/trufflesecurity/trufflehog#homebrew | macOS dev machines |
| CI/CD integration | https://github.com/trufflesecurity/trufflehog#-ci-integration | GitHub Actions, GitLab CI |
| Pre-commit hook | https://github.com/trufflesecurity/trufflehog#-pre-commit-hook | Block commits with secrets |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Scan Git repo, filesystem, S3, GitHub org, or GitLab?" | Drives which subcommand to use |
| target | "Target URL, path, or org name?" | Required for all modes |
| auth | "GitHub/GitLab token for private repos or org-wide scanning?" | Optional; increases rate limits and access |
| output | "JSON output for pipeline integration, or human-readable?" | --json flag |

## Docker usage

Scan a public GitHub org:
```sh
docker run --rm -it trufflesecurity/trufflehog:latest \
  github --org=trufflesecurity --only-verified
```

Scan current directory:
```sh
docker run --rm -it \
  -v "$PWD:/pwd" \
  trufflesecurity/trufflehog:latest \
  filesystem /pwd --only-verified
```

Scan a Git repo (including full history):
```sh
docker run --rm -it trufflesecurity/trufflehog:latest \
  git https://github.com/myorg/myrepo --only-verified
```

## Binary install

```sh
# Linux/macOS via install script
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin

# Verify
trufflehog --version
```

## Common subcommands

| Subcommand | Scans |
|---|---|
| git | Git repo (local or remote); full history by default |
| github | GitHub repos and/or entire org |
| gitlab | GitLab repos and/or group |
| filesystem | Local directory tree |
| s3 | S3 bucket |
| gcs | Google Cloud Storage bucket |
| circleci | CircleCI build logs |
| docker | Docker image layers |
| jenkins | Jenkins build logs |

## CI/CD integration (GitHub Actions)

```yaml
# .github/workflows/trufflehog.yml
name: Secret Scan
on: [push, pull_request]
jobs:
  trufflehog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # full history required
      - uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified
```

## Pre-commit hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.x.x   # pin to a release tag
    hooks:
      - id: trufflehog
        name: TruffleHog
        args: ["git", "file://.", "--since-commit", "HEAD", "--only-verified", "--fail"]
```

## Key flags

| Flag | Purpose |
|---|---|
| --only-verified | Only report secrets that are confirmed live (reduces noise) |
| --json | Machine-readable JSON output |
| --concurrency N | Parallel workers (default: CPU count) |
| --since-commit SHA | Scan only commits after this SHA |
| --branch NAME | Scan specific branch only |
| --fail | Exit with non-zero code if secrets found (for CI gates) |
| --no-update | Skip version check |

## Upgrade procedure

```sh
# Docker: pull latest tag
docker pull trufflesecurity/trufflehog:latest

# Binary: re-run install script or download new release
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
```

## Gotchas

- **--only-verified reduces false positives** — raw scan without this flag generates many findings that may be test/demo keys; use --only-verified in CI gates.
- **Full Git history scan is slow on large repos** — use --since-commit to limit scope in PR checks; run full history scan separately on a schedule.
- **Rate limits** — GitHub org scanning without a token hits API rate limits quickly; provide a token via GITHUB_TOKEN env var or --token flag.
- **No persistent server** — TruffleHog is a CLI tool; for continuous monitoring of real-time commits, use the GitHub Actions integration or TruffleHog Enterprise.
- **Docker image vs binary** — the Docker image adds overhead for simple local scans; the binary is faster for repeated use.
- **AGPL-3.0 license** — the open-source CLI is AGPL-3.0; review license implications if bundling in a proprietary product.

## Links

- GitHub: https://github.com/trufflesecurity/trufflehog
- Releases: https://github.com/trufflesecurity/trufflehog/releases
- Docs: https://trufflesecurity.com/trufflehog
- Docker Hub: https://hub.docker.com/r/trufflesecurity/trufflehog
- CI integration: https://github.com/trufflesecurity/trufflehog#-ci-integration

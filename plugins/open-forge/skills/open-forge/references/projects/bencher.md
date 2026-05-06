---
name: bencher
description: Bencher recipe for open-forge. Continuous benchmarking platform that catches performance regressions in CI, tracking benchmark results over time with a web console, REST API, and CLI. Source: https://github.com/bencherdev/bencher
---

# Bencher

Continuous benchmarking suite that catches performance regressions in CI — the benchmark equivalent of unit tests for performance. Consists of the bencher CLI (runs benchmarks, publishes results), a REST API server, a web console for tracking/graphing results over time, and optional bare metal runner support for low-variance measurements. Upstream: https://github.com/bencherdev/bencher. Docs: https://bencher.dev/docs/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Bencher Cloud (SaaS) | Any | Free tier available. No self-hosting needed. |
| Self-hosted (Docker) | Docker | Run your own API server + console. |
| Self-hosted (binary) | Linux/macOS/Windows | Download bencher-api binary directly. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Self-hosted or Bencher Cloud?" | Cloud is easiest; self-host for private/on-prem. |
| setup (self-hosted) | "Public URL for Bencher?" | e.g. https://bencher.example.com — set as BENCHER_API_URL |
| setup | "Admin email?" | First admin account |
| storage | "Database path?" | SQLite by default; path configured via env var |

## Software-layer concerns

### Bencher Cloud (recommended for most users)

  # Install CLI
  curl --proto '=https' --tlsv1.2 -sSfL https://bencher.dev/download/install-cli.sh | sh
  # Or: cargo install bencher_cli

  # Sign up and create a project at https://bencher.dev
  # Get an API token from the console

  # Track benchmarks (example with cargo bench):
  bencher run \
    --project <project-slug> \
    --token <api-token> \
    --branch main \
    --testbed localhost \
    cargo bench

### Self-hosted install

Documentation: https://bencher.dev/docs/tutorial/self-hosted/

  # Download the bencher-api server binary from GitHub releases
  # https://github.com/bencherdev/bencher/releases

  # Configure environment:
  export BENCHER_API_URL=https://bencher.example.com
  export DATABASE_PATH=/data/bencher.db
  export BENCHER_SECRET_KEY=$(openssl rand -hex 32)

  # Run API server
  ./bencher-api

  # The web console is served by a separate process or can be run as a static site
  # See upstream docs for full self-hosted setup

### CI integration (GitHub Actions example)

  - uses: bencherdev/bencher@main
    with:
      project: my-project
      token: ${{ secrets.BENCHER_API_TOKEN }}
      branch: ${{ github.head_ref }}
      testbed: ubuntu-latest
      threshold-measure: latency
      threshold-test: t_test
      threshold-upper-boundary: 0.99
      err: true
      command: cargo bench

### Supported benchmark harnesses

Bencher adapts output from many frameworks automatically:
- Rust: cargo bench, Criterion, Iai
- Python: pytest-benchmark, airspeed velocity
- Go: go test -bench
- JavaScript: Benchmark.js
- C/C++: Google Benchmark, Catch2
- Custom: JSON output format supported

## Upgrade procedure

  # Self-hosted: download new binary from GitHub releases and restart
  # Back up SQLite database before upgrading
  # CLI: cargo install --force bencher_cli

## Gotchas

- **Self-hosted docs are sparse**: the primary supported use case is Bencher Cloud. Self-hosted setup requires reading the source/issues for full configuration details.
- **Bare Metal runners**: the low-variance (<2%) bare metal runners are a paid Cloud feature. Self-hosted uses standard infrastructure.
- **Branch tracking**: Bencher tracks results per branch. CI must pass the correct branch name for meaningful history.
- **Thresholds**: statistical thresholds (t-test, z-score, etc.) must be configured per project/branch/testbed/measure combination. Defaults are permissive.
- **Alert fatigue**: start with permissive thresholds and tighten over time as benchmark variance becomes understood.

## References

- Upstream GitHub: https://github.com/bencherdev/bencher
- Docs: https://bencher.dev/docs/
- Self-Hosted Quickstart: https://bencher.dev/docs/tutorial/self-hosted/
- Bare Metal Quickstart: https://bencher.dev/docs/tutorial/bare-metal/
- GitHub Actions integration: https://bencher.dev/docs/how-to/github-actions/

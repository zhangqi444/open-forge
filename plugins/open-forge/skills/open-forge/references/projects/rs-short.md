---
name: rs-short
description: rs-short recipe for open-forge. Lightweight Rust-based URL shortener with caching, spam-bot protection, and phishing detection. Source at https://git.42l.fr/42l/rs-short (Anubis-protected; direct README fetch not available at catalog-build time).
---

# rs-short

Lightweight URL shortener written in Rust. Features built-in caching, spam-bot protection, and phishing detection. MPL-2.0. Source: https://git.42l.fr/42l/rs-short. Live demo: https://s.42l.fr (operated by La Contre-Voie).

> **Note:** The upstream Gitea instance (git.42l.fr) is protected by Anubis bot-proof challenges. Install docs were not fetchable at catalog-build time. The upstream repository is the authoritative source for current install instructions.

## Compatible install methods

| Method | When to use |
|---|---|
| Cargo (Rust build) | Standard for a Rust binary |
| Docker | Check upstream for image availability |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| config | "Short domain / base URL?" | URL | e.g. https://s.yourdomain.com — used in generated short links |
| network | "Port to listen on?" | Number | Default varies; check upstream config |
| storage | "Database backend?" | Config | Check upstream for supported stores (likely SQLite or PostgreSQL) |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Rust |
| Features | Caching, spam-bot protection, phishing detection |
| License | MPL-2.0 |
| Upstream | https://git.42l.fr/42l/rs-short (Anubis-protected) |

## Install

Upstream install documentation is at https://git.42l.fr/42l/rs-short.

General Rust binary install approach:

```bash
git clone https://git.42l.fr/42l/rs-short
cd rs-short
cargo build --release
# Configure via config file (see upstream docs)
./target/release/rs-short
```

See upstream README for complete configuration reference including database setup, caching options, bot-protection config, and phishing-list integration.

## Upgrade procedure

```bash
git pull
cargo build --release
# Restart service
```

## Gotchas

- Upstream behind bot protection: git.42l.fr uses Anubis proof-of-work challenge. Automated fetches (scripts, curl) will fail. Browse to the repo directly in a browser.
- Phishing detection requires a list source: Check upstream docs for how phishing detection is configured and what list(s) it consumes.
- Bot protection is a feature, not just a gotcha: rs-short includes its own anti-spam/anti-bot protection for submitted links — useful for public-facing deployments.

## Links

- Source: https://git.42l.fr/42l/rs-short
- Demo: https://s.42l.fr

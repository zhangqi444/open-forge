---
name: Fava
description: "Web interface for Beancount double-entry bookkeeping. Provides charts, budget tracking, portfolio view, CSV/spreadsheet import, and a full-featured editor for .beancount ledger files. Python/Flask. MIT."
---

# Fava

**What it is:** A web frontend for Beancount - the plain-text double-entry accounting system. Fava adds a rich browser-based UI with charts, income/expense reports, balance sheets, budget tracking, and an in-browser editor. Your data stays in plain .beancount text files.

**Official site:** https://beancount.github.io/fava/  
**GitHub:** https://github.com/beancount/fava  
**Docs:** https://beancount.github.io/fava/usage.html  
**License:** MIT  
**Demo:** https://fava.pythonanywhere.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/macOS | pip install | Simplest; fava CLI serves directly |
| Docker | docker run / compose | Unofficial images available (e.g. yegle/fava) |
| Any | Python virtualenv | Recommended for isolation |

---

## Inputs to Collect

### Pre-install
- Path to existing .beancount ledger file(s)
- Whether multiple ledgers are needed (fava can serve multiple)
- Desired port (default: 5000)
- Whether to expose publicly (needs auth/reverse proxy)

### Runtime
- Beancount file path(s)
- --host flag (default: 127.0.0.1; set to 0.0.0.0 for network access)
- --port flag (default: 5000)
- --prefix if running behind a reverse proxy at a subpath

---

## Software-Layer Concerns

### Data files
- Your .beancount ledger file(s) - these ARE your data; back them up
- Fava itself is stateless - all state is in the ledger files
- No database required

### Key config
- Fava options are set as directives inside the .beancount file:
  ```
  2020-01-01 custom "fava-option" "auto-reload" "true"
  2020-01-01 custom "fava-option" "currency-column" "100"
  ```
- See full options: https://beancount.github.io/fava/options.html

### Ports
- 5000 TCP - default HTTP port

---

## Quick Start

```bash
pip3 install fava
fava ledger.beancount
# Visit http://localhost:5000
```

### Serve multiple ledgers
```bash
fava personal.beancount business.beancount
```

### Network-accessible (with reverse proxy)
```bash
fava --host 0.0.0.0 --port 5000 ledger.beancount
```

### Docker (community image example)
```yaml
services:
  fava:
    image: yegle/fava:latest
    ports:
      - "5000:5000"
    volumes:
      - ./ledger:/data:ro
    environment:
      - BEANCOUNT_FILE=/data/ledger.beancount
    restart: unless-stopped
```

---

## Upgrade Procedure

```bash
pip3 install --upgrade fava
# Restart fava process
```

---

## Gotchas

- Fava is a frontend only - it requires Beancount to be installed and a valid .beancount file to exist
- No built-in authentication - if exposing to the internet, put it behind a reverse proxy with auth (nginx + basic auth, Authelia, etc.)
- auto-reload fava-option is useful in development but can cause high CPU on large ledgers
- Beancount v2 and v3 have different APIs; check fava compatibility with your Beancount version
- Fava extensions can add import rules, custom reports, etc. - see https://beancount.github.io/fava/extensions.html

---

## Upstream Docs

- Getting started: https://beancount.github.io/fava/usage.html
- Fava options reference: https://beancount.github.io/fava/options.html
- Extensions: https://beancount.github.io/fava/extensions.html
- Beancount docs: https://beancount.github.io/docs/

---
name: kibitzr
description: Kibitzr recipe for open-forge. Lightweight personal web assistant that monitors web pages and RSS feeds, applies transforms (CSS/XPath selectors, scripts, AI), and triggers notifications or automations. Python app, Docker-deployable. Source: https://github.com/kibitzr/kibitzr
---

# Kibitzr

Lightweight personal web assistant and automation engine. Define checks in a YAML config file: fetch a URL (or RSS), extract content with CSS/XPath selectors, apply transforms (jinja2, bash, Python, or AI), and trigger actions (Slack, email, Telegram, IFTTT, custom scripts). Think of it as a YAML-configured, self-hosted Zapier for watching web pages. Python app with a Docker image. MIT license. Upstream: https://github.com/kibitzr/kibitzr. Docs: https://kibitzr.readthedocs.io.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker | Linux | Recommended — avoids dependency complexity |
| pip (virtualenv) | Linux / macOS | For local/dev use |
| pip (system) | Linux | Works; virtualenv preferred |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | "kibitzr.yml location?" | Directory to mount into container |
| creds | "kibitzr-creds.yml location?" | Sensitive credentials file (keep out of git) |
| schedule | "Check interval?" | Defined per-check in kibitzr.yml (e.g. every 5m) |

## Software-layer concerns

### Method 1: Docker (recommended)

  # Create your config directory:
  mkdir ~/kibitzr && cd ~/kibitzr

  # Generate an example config:
  docker run -v $PWD:/root --rm peterdemin/kibitzr init

  # Run kibitzr:
  docker run -d \
    --name kibitzr \
    --restart unless-stopped \
    -v $PWD:/root \
    peterdemin/kibitzr run

### docker-compose.yml

  version: "3"
  services:
    kibitzr:
      image: peterdemin/kibitzr:latest
      container_name: kibitzr
      restart: unless-stopped
      volumes:
        - ./config:/root
      working_dir: /root
      command: run

### Method 2: pip install

  python3 -m venv venv
  source venv/bin/activate
  pip install kibitzr

  # Initialize example config:
  kibitzr init

  # Run:
  kibitzr run

### kibitzr.yml structure

  # Example: watch a web page and send a Slack notification when it changes
  checks:
    - name: "Example page change"
      url: https://example.com/status
      period: 5m
      changes:
        - notify:
            - slack:
                url: https://hooks.slack.com/services/...

  # Example: extract text with CSS selector
  checks:
    - name: "Latest headline"
      url: https://news.ycombinator.com
      period: 1h
      transform:
        - css: "a.storylink"
        - first: true
      notify:
        - telegram:
            token: "BOT_TOKEN"
            chat_id: "CHAT_ID"

### kibitzr-creds.yml (keep out of version control)

  # Store API keys and passwords here:
  slack:
    url: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
  telegram:
    token: YOUR_BOT_TOKEN
    chat_id: YOUR_CHAT_ID

### Transform pipeline

  Transforms are applied in sequence to the fetched content:
  - css: "<selector>"     — extract by CSS selector
  - xpath: "<expr>"       — extract by XPath
  - tag: "<tag>"          — extract by HTML tag
  - jinja2: "<template>"  — template the value
  - bash: "<script>"      — pipe through bash
  - python: "<code>"      — pipe through Python
  - first: true           — take first result from a list
  - text: true            — convert HTML to plain text

### Notification targets

  Slack, Telegram, email (SMTP), IFTTT, custom bash/Python scripts, Pushover, Gitter

### Ports

  None — kibitzr is a headless agent with no web UI.
  # Optionally expose a simple status page with --http flag (experimental)

## Upgrade procedure

  # Docker:
  docker pull peterdemin/kibitzr:latest
  docker restart kibitzr

  # pip:
  source venv/bin/activate
  pip install --upgrade kibitzr

## Gotchas

- **No web UI**: Kibitzr is entirely config-file driven. Edit `kibitzr.yml` and restart the container to apply changes.
- **Firefox dependency for dynamic pages**: Checking pages that require JavaScript execution uses Firefox as a fetcher. Inside Docker this is pre-configured; native installs need Firefox + geckodriver installed separately.
- **Credentials file**: Keep `kibitzr-creds.yml` out of version control (add to `.gitignore`). It contains API tokens in plaintext.
- **Period syntax**: Schedules are per-check and use natural language: `5m`, `1h`, `daily`, `every Monday at 9:00`.
- **Git dependency for `changes` transform**: The `changes` notifier (notify only when content changes) requires `git` to be available; the Docker image includes it.
- **lxml compilation**: On native install, CSS/XPath transforms need `lxml`. If `pip install kibitzr` fails due to missing headers, install `python3-dev` and `libxml2-dev`.
- **Quiet by default**: Kibitzr logs to stdout. Run `docker logs -f kibitzr` to monitor activity.

## References

- Upstream GitHub: https://github.com/kibitzr/kibitzr
- Documentation: https://kibitzr.readthedocs.io
- Docker Hub: https://hub.docker.com/r/peterdemin/kibitzr

---
name: octobot
description: OctoBot recipe for open-forge. Open-source cryptocurrency trading bot with web UI, backtesting, and 15+ exchange integrations. Self-hosted via Docker Compose or Python. Source: https://github.com/Drakkar-Software/OctoBot. Docs: https://www.octobot.cloud/en/guides.
---

# OctoBot

Open-source cryptocurrency trading bot with a visual web interface. Automates trading strategies (grid, DCA, crypto basket, AI-driven, TradingView signals) across 15+ exchanges (Binance, Coinbase, Hyperliquid, MEXC, etc.). Includes backtesting engine, paper trading, and Telegram interface. Upstream: <https://github.com/Drakkar-Software/OctoBot>. Docs: <https://www.octobot.cloud/en/guides>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose | Recommended; bundles Watchtower for auto-updates |
| VPS / bare metal | Python (pip/git) | For development or code customisation |
| Raspberry Pi | Docker or Python | Officially supported; min 250 MB RAM, 1 GHz CPU |
| DigitalOcean | 1-Click Marketplace | Official DO marketplace listing |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Docker Compose or Python install?" | Drives install path |
| exchange | "Which exchange(s)?" | Binance, Coinbase, Hyperliquid, MEXC, or others — needs API key + secret |
| exchange | "Exchange API key and secret?" | Read-only keys for paper trading; trade-enabled for live |
| port | "Which port should OctoBot web UI listen on?" | Default: 80 (maps to container port 5001) |
| telegram | "Enable Telegram interface?" | Optional; requires bot token from BotFather |

## Software-layer concerns

- Config: stored in ./user/ directory (mounted volume); edit via web UI or JSON files
- Default port: 80 (mapped from internal 5001)
- Data dirs:
  - ./logs — OctoBot log files
  - ./backtesting — historical OHLCV data for backtesting
  - ./tentacles — strategy plugins/modules
  - ./user — user config, exchange API keys, portfolio data
- Tentacles: OctoBot's plugin system for strategies, exchange connectors, services. Install via web UI or CLI.
- Auto-update: the official docker-compose.yml includes Watchtower for automatic image updates (disable if you want pinned versions)
- Min hardware: 1 core, 250 MB RAM, 1 GB disk

### Docker Compose

```yaml
version: "3"
services:
  octobot:
    image: drakkarsoftware/octobot:stable
    volumes:
      - ./logs:/octobot/logs
      - ./backtesting:/octobot/backtesting
      - ./tentacles:/octobot/tentacles
      - ./user:/octobot/user
    ports:
      - "${PORT:-80}:5001"
    restart: always

  watchtower:
    image: containrrr/watchtower
    restart: always
    command: --cleanup --include-restarting
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

Remove the `watchtower` service if you want to control upgrade timing manually.

### Access web UI

Open `http://localhost` (or your server IP) after startup. First-run wizard guides exchange setup and strategy selection.

## Upgrade procedure

1. If using Watchtower: automatic (Watchtower pulls and restarts on new image)
2. Manual: `docker compose pull && docker compose up -d`
3. Check release notes: https://github.com/Drakkar-Software/OctoBot/releases

## Gotchas

- **API key permissions**: Use read-only keys for paper trading/backtesting. Only enable trade permissions for live trading — and never enable withdrawal permissions.
- **Exchange rate limits**: OctoBot respects CCXT rate limits, but aggressive strategies on many pairs can hit exchange limits. Start conservatively.
- **Backtesting data**: Historical OHLCV data is downloaded from the exchange and cached in ./backtesting. First backtest on a new pair/timeframe can be slow.
- **Tentacles**: Strategies are tentacles — community tentacles exist but carry the usual risks of third-party code executing financial transactions.
- **Paper trading first**: Always run in paper trading (simulator) mode before going live. The backtesting results don't account for slippage, exchange fees, or API latency.
- **Port conflict**: Default port 80 may conflict with other services. Override with `PORT=8080` env var or edit the compose file.
- **Watchtower**: The default compose includes Watchtower which auto-updates ALL running containers, not just OctoBot. Remove or configure `--scope` if running other containers.

## Links

- Upstream repo: https://github.com/Drakkar-Software/OctoBot
- Docs / guides: https://www.octobot.cloud/en/guides
- Docker Hub: https://hub.docker.com/r/drakkarsoftware/octobot
- DigitalOcean Marketplace: https://marketplace.digitalocean.com/apps/octobot
- Release notes: https://github.com/Drakkar-Software/OctoBot/releases
- Discord: https://discord.com/invite/vHkcb8W
- Telegram channel: https://t.me/OctoBot_Project

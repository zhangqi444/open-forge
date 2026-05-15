---
name: Rotki
description: "Self-hosted privacy-focused crypto + financial portfolio manager, accounting, and analytics. Data stored encrypted locally. DeFi/CeFi tracking across many exchanges + chains; tax reporting. Python + Electron/Vue. AGPL-3.0. Free core + Rotki Premium (commercial) for advanced features."
---

# Rotki

Rotki is **"the self-hosted privacy-first alternative to CoinTracker / Koinly / CoinLedger"** — a portfolio manager + accounting + tax-analytics tool for crypto-heavy users. The differentiator vs competitors: **your financial data never leaves your machine** — no SaaS cloud syncing your transaction history to a vendor's DB. Rotki runs **locally** (desktop app via Electron, or self-hosted Docker), connects to exchanges + chains + DeFi protocols via read-only APIs, and stores everything in a **locally-encrypted SQLite DB**.

Built + maintained by **rotki** (Lefteris Karapetsas + team; chartlenhen Greek word = "little red"; German fork-joke origin). **AGPL-3.0** for core + **Rotki Premium** (commercial subscription) for advanced features. Long-running; well-funded; crypto-ecosystem veterans.

Use cases: (a) **annual crypto tax reporting** without handing Koinly / CoinTracker your whole history (b) **multi-exchange + multi-chain portfolio consolidation** — see your total holdings across Coinbase + Kraken + Binance + self-custody wallets + Ethereum + Bitcoin + Solana + ~all chains (c) **DeFi position tracking** — track lending / AMM / staking positions (d) **accounting + PnL** across years + events (e) **privacy-focused-crypto-user** who refuses cloud SaaS for financial data.

Features:

- **Portfolio tracker** — all-chains, all-exchanges, all-wallets
- **Tax reports** — FIFO / LIFO / ACB / HIFO cost-basis methods; per-jurisdiction
- **DeFi integrations** — Uniswap, Aave, Compound, MakerDAO, Curve, Yearn, Lido, + more
- **CEX integrations** — Binance, Coinbase, Kraken, Bitfinex, Bitstamp, KuCoin, OKX, Gemini, Poloniex, Bittrex, + more via read-only API keys
- **On-chain wallet tracking** — BTC, ETH (+ L2s), Solana, Cosmos, Polkadot, many more
- **Historical PnL calculations** — for every trade / transfer / DeFi action
- **Transaction history viewer** with annotations
- **Price database** — built-in + integrations (CoinGecko, CryptoCompare)
- **Data stored ENCRYPTED locally** — user-controlled key
- **Export** — CSV, PDF reports
- **Multi-user profiles** on same Rotki install (each with own password-derived encryption)
- **Dark mode** + responsive UI

- Upstream repo: <https://github.com/rotki/rotki>
- Homepage: <https://rotki.com>
- Premium: <https://rotki.com/products/>
- Feature coverage: <https://rotki.com/products/details>
- Documentation: <https://docs.rotki.com>
- Discord: <https://discord.rotki.com>
- Hiring: <https://rotki.com/jobs/>
- Twitter/X: <https://x.com/rotkiapp>

## Architecture in one minute

- **Python** backend + **Vue / Electron** frontend
- **SQLite** — encrypted local DB per user
- **Desktop app** (Electron) + **Docker** (self-hosted) paths
- **Resource**: modest — 400-800MB RAM; disk grows with transaction history + price history
- **Outbound-only**: Rotki talks to exchange APIs + blockchain RPCs + price sources. **NEVER sends YOUR data to rotki.com servers** (Premium features are signature-verified cryptographically against rotki.com for subscription validity; data stays local)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Desktop (Electron) | **Downloads for Win/Mac/Linux**                                 | **Primary path** — the app is fundamentally a desktop tool                         |
| Docker             | `rotki/rotki` (multi-arch) for self-hosted server mode                    | For NAS / always-on access                                                                 |
| AppImage / Flatpak (Linux) | Packaging community                                                           | Works                                                                                                  |
| Source build       | Python + npm + Electron                                                                                 | For devs                                                                                                             |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| User account password | **Strong + unique** — derives encryption key                | **CRITICAL** | **IMMUTABLE** — losing = losing all data                                                                         |
| Exchange API keys    | READ-ONLY keys from each exchange                                       | Integration  | **Never use trading / withdrawal-enabled keys**                                                                          |
| Wallet addresses     | Public addresses only (no private keys)                                           | Integration  | On-chain tracking; safe to provide                                                                             |
| Tax jurisdiction     | US / DE / UK / FR / etc.                                                                      | Config       | For proper cost-basis method                                                                                                          |
| Premium subscription (opt)                       | rotki.com account                                                                                             | Upgrade      | Unlocks advanced features                                                                                                                   |

## Install (desktop — primary path)

Download from <https://rotki.com> → install → launch → create user profile with password.

## Install (Docker — self-hosted)

```yaml
services:
  rotki:
    image: rotki/rotki:v1.43.0         # **pin version** in prod
    restart: unless-stopped
    volumes:
      - ./rotki-data:/data
    ports: ["4242:4242"]
```

Desktop app can connect to the Docker backend for UI. Check <https://docs.rotki.com> for current Docker path + WebSocket connection setup.

## First boot

1. Launch Rotki → **Create New Account**
2. **Choose a strong, UNIQUE password** — this derives the encryption key
3. Add exchanges: paste READ-ONLY API keys (NEVER trading keys; never withdrawal keys)
4. Add wallets: paste public addresses (no private keys ever)
5. Add DeFi protocols: authorize on-chain read access
6. Wait for initial sync (can be long for active traders)
7. Review transactions; correct any misclassifications
8. Generate first tax report (if applicable)
9. **BACK UP encrypted DB** → `$HOME/.rotki/` (varies by OS)
10. **BACK UP password** → password manager

## Data & config layout

- `$HOME/.rotki/` (Linux/macOS) or `%APPDATA%/rotki/` (Windows) — user data
- Per-user encrypted SQLite DB
- Price cache database (shared across users)
- Logs

## Backup

- **Export via UI**: Settings → Data & Security → Backup
- **Manual**: back up the user's encrypted SQLite file + rotki.com subscription tokens
- **Store password in password manager** — without it, backup is useless

## Upgrade

1. Releases: <https://github.com/rotki/rotki/releases>. Frequent.
2. Desktop: in-app updater OR download new version.
3. Docker: pull latest tag.
4. **Back up BEFORE upgrade** — major version DB schema changes happen.
5. Changelog at <https://github.com/rotki/rotki/blob/develop/docs/changelog.rst>.

## Gotchas

- **Password IS the encryption key** — lose it, lose your data. No recovery, no backdoor, no email-reset (that would defeat local-encryption privacy). **Back up the password SEPARATELY from the data.** Password manager with cloud-sync is appropriate IF your threat model accepts a password-manager-compromise risk. For higher-security: hardware-written copy in a physical safe.
- **`Account password` IMMUTABILITY** — changing password re-encrypts DB but requires old password. Forgetting old password mid-change = brick. **12th tool in immutability-of-secrets family** (after Black Candy, Lychee, Forgejo, Fider, FreeScout, Nexterm, Wakapi, Statamic, Vikunja, PMS, 2FAuth, Chartbrew).
- **API KEY SECURITY**: the #1 gotcha for new crypto-tool users.
  - **ONLY use READ-ONLY API keys.** Never trading-enabled, never withdrawal-enabled.
  - **Scope IP allowlist** if exchange supports it.
  - **Periodically rotate** keys.
  - **Rotki can't steal funds if keys are READ-ONLY** — even if Rotki were compromised. Defense-in-depth via API-key-scope.
- **Hub-of-credentials crown-jewel** — Rotki stores read-only API keys for every exchange + wallet addresses + (for Premium) rotki.com subscription tokens. If the Rotki DB is stolen + decrypted, attackers see your financial picture + can attempt to abuse READ-ONLY API keys (spam calls, rate-limit issues). **10th tool in hub-of-credentials family.** Defense-in-depth:
  - Strong unique password (encryption-at-rest)
  - Full-disk encryption on the host
  - Rotki's data dir NOT on cloud-sync-ed folder (Dropbox / iCloud / Google Drive) unless encryption is trustworthy
- **DeFi integration complexity**: DeFi protocols change frequently. Rotki's coverage is extensive but not perfect. For obscure protocols, manual annotation may be needed.
- **Tax calculation is ACCOUNTING, not ADVICE** — Rotki gives you data + default cost-basis methods. Final tax treatment depends on your jurisdiction + your accountant's interpretation. **Rotki reports are INPUT to your tax prep, not OUTPUT for filing.** Upstream is clear about this.
- **Price-source accuracy varies**: CoinGecko + CryptoCompare differ on obscure tokens. Rotki pulls both; you can override per-asset. For tax-critical trades, double-check.
- **Crypto-specific scam surface**: anyone asking for your Rotki password or your exchange API keys or your wallet SEED phrase is trying to steal from you. **Rotki never needs your seed phrase.** Only public addresses.
- **Initial sync is LONG** for active traders: months of history to pull from exchanges + chains. Run first sync on a stable connection; budget hours or days.
- **Rotki Premium commercial-tier-funds-upstream**: AGPL-3 core is fully functional; Premium adds advanced analytics + more data history + detailed DeFi coverage. Standard "feature-gate" tier. Subscription validated cryptographically by rotki.com signature checks — your data is NOT transmitted to rotki.com; only subscription-validity is verified.
- **Multi-user profiles**: one install, multiple password-encrypted user profiles. Useful for couple/family privacy separation.
- **Jurisdiction-specific tax features** (US / DE / UK / ...) vary in depth. Test yours before trusting.
- **DB size grows with transaction history + cached prices**. Active traders may have GB-sized DBs. Plan disk.
- **AGPL-3 + commercial-tier** — same governance family as Synapse (84), Grafana-post-change, MongoDB-post-SSPL. AGPL keeps community core honest; commercial tier funds development. Transparent + sustainable.
- **Project health**: Lefteris-led + funded (Premium + crypto-ecosystem sponsorships) + hiring + Discord + long-history + AGPL. Strong.
- **Alternatives worth knowing:**
  - **Koinly / CoinTracker / CoinLedger** — commercial SaaS (your data in their cloud)
  - **Accointing** — commercial
  - **TokenTax** — commercial + tax-prep service
  - **Manual spreadsheets** — for small-portfolio, simple situations
  - **Zerion / DeBank** — DeFi-only portfolio viewers (web-based, read-only by address)
  - **Choose Rotki if:** you want **privacy + self-sovereignty** + willingness to run desktop/Docker + willing to pay Premium for advanced features.
  - **Choose Koinly / CoinTracker if:** you prefer cloud SaaS convenience + accept financial-data-in-vendor-cloud tradeoff.
  - **Choose Zerion / DeBank if:** you only need DeFi viewer, not accounting.

## Links

- Repo: <https://github.com/rotki/rotki>
- Homepage: <https://rotki.com>
- Docs: <https://docs.rotki.com>
- Premium: <https://rotki.com/products/>
- Feature coverage: <https://rotki.com/products/details>
- Discord: <https://discord.rotki.com>
- Changelog: <https://github.com/rotki/rotki/blob/develop/docs/changelog.rst>
- Docker Hub: <https://hub.docker.com/r/rotki/rotki>
- Koinly (commercial alt): <https://koinly.io>
- CoinTracker (commercial alt): <https://www.cointracker.io>
- Zerion (DeFi viewer): <https://zerion.io>
- DeBank (DeFi viewer): <https://debank.com>

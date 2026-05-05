---
name: btcpay-server-project
description: BTCPay Server recipe for open-forge. Free and open-source Bitcoin payment processor. Covers Docker-based deployment (the recommended production method via btcpayserver-docker), configuration, and upgrade. Derived from https://docs.btcpayserver.org/Deployment/ and https://github.com/btcpayserver/btcpayserver-docker.
---

# BTCPay Server

Free and open-source Bitcoin payment processor. Upstream: <https://github.com/btcpayserver/btcpayserver>. Documentation: <https://docs.btcpayserver.org/>. Deployment guide: <https://docs.btcpayserver.org/Deployment/>.

BTCPay Server allows you to accept Bitcoin (and other cryptocurrencies) without fees or intermediaries. It includes an invoicing system, point of sale, payment requests, Lightning Network support, and integrations with e-commerce platforms (WooCommerce, Shopify, etc.).

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker (btcpayserver-docker) | <https://docs.btcpayserver.org/Docker/> | yes | Recommended production method. Uses docker-compose with lunanode/LunaNode or any VPS. |
| LunaNode web deployment | <https://launchbtcpay.lunanode.com/> | upstream-recommended | One-click VPS + BTCPay provisioning. |
| Third-party hosting | <https://docs.btcpayserver.org/ThirdPartyHosting/> | community | Managed BTCPay instances. Out of scope for open-forge. |
| Manual / bare-metal | <https://docs.btcpayserver.org/Deployment/> | yes | Advanced: build from source (.NET 10+). Not recommended for most users. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What is the domain/hostname for this BTCPay instance?" | FQDN e.g. btcpay.example.com | Required for TLS and URL generation. |
| preflight | "Which Lightning Network implementation?" | options: LND / c-lightning / eclair / None | LND is default in btcpayserver-docker. |
| preflight | "Which additional cryptocurrencies to support?" | Multi-select: Bitcoin / Litecoin / Monero / etc. | Bitcoin is always included. |
| config | "SMTP server for email notifications?" | host:port | Optional. Used for password resets and notifications. |
| config | "Reverse proxy type?" | options: NGINX / Caddy / None | btcpayserver-docker bundles NGINX + Let's Encrypt by default. |

## Docker install (btcpayserver-docker)

Upstream: <https://docs.btcpayserver.org/Docker/>

BTCPay Server's primary deployment method uses the btcpayserver-docker repository, which manages a suite of docker-compose fragments assembled at deploy time.

### Quick deploy

```bash
# On a fresh Ubuntu/Debian server
git clone https://github.com/btcpayserver/btcpayserver-docker
cd btcpayserver-docker

# Set required environment variables
export BTCPAY_HOST="btcpay.example.com"
export NBITCOIN_NETWORK="mainnet"
export BTCPAYGEN_CRYPTO1="btc"
export BTCPAYGEN_LIGHTNING="lnd"
export BTCPAYGEN_REVERSEPROXY="nginx"
export BTCPAYGEN_ADDITIONAL_FRAGMENTS=""

. ./btcpay-setup.sh -i
```

The setup script generates a docker-compose.yml, starts all services, and configures NGINX with Let's Encrypt TLS automatically.

### Environment variables

| Variable | Example | Description |
|---|---|---|
| BTCPAY_HOST | btcpay.example.com | Public domain for this instance |
| NBITCOIN_NETWORK | mainnet | mainnet / testnet / regtest |
| BTCPAYGEN_CRYPTO1 | btc | Primary cryptocurrency |
| BTCPAYGEN_LIGHTNING | lnd | Lightning impl: lnd / clightning / eclair / (empty for none) |
| BTCPAYGEN_REVERSEPROXY | nginx | nginx / caddy / (empty) |
| BTCPAYGEN_ADDITIONAL_FRAGMENTS | opt-save-storage | Optional feature fragments |

### Data directories

| Path | Contents |
|---|---|
| /var/lib/docker/volumes/generated_btcpay_datadir | BTCPay Server app data |
| /var/lib/docker/volumes/generated_bitcoin_datadir | Bitcoin node blockchain data |
| /var/lib/docker/volumes/generated_lnd_datadir | LND Lightning node data |

### Ports

| Port | Use |
|---|---|
| 80 | HTTP (redirects to 443) |
| 443 | HTTPS Web UI |
| 9735 | Bitcoin Lightning Network peer connections |

## Software-layer concerns

- **Disk space**: A full Bitcoin mainnet node requires 600 GB+ of disk. Use `opt-save-storage` fragment to prune the blockchain and reduce requirements.
- **Sync time**: Initial Bitcoin blockchain sync takes 1-3 days on a typical VPS. BTCPay is not fully operational until sync completes.
- **Lightning wallet**: After deploying with LND, fund the Lightning wallet and open channels before accepting Lightning payments.
- **Firewall**: Open ports 80, 443 (web) and 9735 (Lightning P2P) in your VPS firewall.

## Upgrade procedure

```bash
cd btcpayserver-docker
git pull
. ./btcpay-setup.sh -i
```

Or use the Update button in BTCPay Server's admin UI (Server Settings -> Maintenance -> Update).

## Gotchas

- **Domain required at setup**: BTCPay requires a real domain with DNS pointing to the server before running setup — Let's Encrypt cert provisioning fails on bare IPs.
- **Not suitable for low-resource VMs**: Minimum recommended specs are 2 vCPU, 8 GB RAM, 600 GB SSD for mainnet with Lightning.
- **First-run admin token**: After deploy, navigate to the domain to create the first admin account. This must be done quickly — the token is time-limited.
- **Lightning backup**: Back up the LND seed phrase and channel backups (static channel backup). Loss of LND data without backups means loss of Lightning funds.
- **Testnet first**: For development/testing, set NBITCOIN_NETWORK=testnet to avoid real funds.

## Links

- GitHub: <https://github.com/btcpayserver/btcpayserver>
- Docker deployment repo: <https://github.com/btcpayserver/btcpayserver-docker>
- Documentation: <https://docs.btcpayserver.org/>
- Deployment guide: <https://docs.btcpayserver.org/Deployment/>
- Docker deployment docs: <https://docs.btcpayserver.org/Docker/>

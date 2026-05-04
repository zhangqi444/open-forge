# BTCPay Server

Self-hosted, open-source Bitcoin (and Lightning Network) payment processor. Allows merchants and individuals to accept Bitcoin payments directly — no fees, no middleman, non-custodial. Supports Lightning Network (LND, Core Lightning, Eclair), Tor, multi-tenant instances, Point of Sale, crowdfunding, and a full-node reliant wallet. Upstream: <https://github.com/btcpayserver/btcpayserver>. Docs: <https://docs.btcpayserver.org>.

BTCPay Server is a complex multi-service stack: it requires a full (or pruned) Bitcoin node, NBXplorer (block explorer), PostgreSQL, and optionally a Lightning Network node. The recommended install is via the **btcpayserver-docker** setup script, which generates and manages a Docker Compose stack automatically.

BTCPay listens on port `443` (HTTPS) by default via nginx. Port `80` is used for Let's Encrypt cert issuance. Port `9735` is needed for Lightning Network.

## Compatible install methods

Verified against upstream docs at <https://docs.btcpayserver.org/Deployment/>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| btcpayserver-docker (bash setup script) | <https://github.com/btcpayserver/btcpayserver-docker> | ✅ | **Recommended.** Generates Docker Compose config for your chosen crypto/lightning setup. Handles TLS, nginx, and automatic updates. |
| LunaNode / Azure one-click | <https://docs.btcpayserver.org/LunaNodeWebDeployment/> | ✅ | Easiest cloud deploy. Managed setup via web wizard. |
| Manual Docker Compose | <https://docs.btcpayserver.org/Docker/> | ✅ | Advanced users who need custom compose configuration. |
| Kubernetes (community) | Community-supported | Community | Not officially supported upstream. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | "Domain for BTCPay Server? (must have A record pointing to server)" | Free-text (e.g. `btcpay.example.com`) | All |
| network | "Bitcoin network?" | `AskUserQuestion`: `mainnet` / `testnet` / `regtest` | All |
| lightning | "Lightning Network implementation?" | `AskUserQuestion`: `Core Lightning (CLN)` / `LND` / `Eclair` / `None` | All |
| storage | "Enable node pruning? (reduces storage from ~600GB to ~5GB)" | Yes/No | btcpayserver-docker |
| proxy | "Reverse proxy?" | `AskUserQuestion`: `nginx` / `none` | btcpayserver-docker |

## Software-layer concerns

### btcpayserver-docker setup (recommended)

Requires a public domain with DNS pointing to your server before running:

```bash
sudo su -
mkdir BTCPayServer && cd BTCPayServer
git clone https://github.com/btcpayserver/btcpayserver-docker
cd btcpayserver-docker

# Configure environment
export BTCPAY_HOST="btcpay.example.com"
export NBITCOIN_NETWORK="mainnet"
export BTCPAYGEN_CRYPTO1="btc"
export BTCPAYGEN_REVERSEPROXY="nginx"
export BTCPAYGEN_LIGHTNING="clightning"        # or "lnd", "eclair", or omit for none
export BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage-s"  # pruned node (~5GB)
export BTCPAY_ENABLE_SSH=true

. ./btcpay-setup.sh -i
```

The script:
- Installs Docker and Docker Compose
- Generates a full Docker Compose stack tailored to your choices
- Configures systemd service for auto-start on reboot
- Requests Let's Encrypt TLS certificate automatically

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `BTCPAY_HOST` | External domain | Must have DNS A record pointing to server |
| `NBITCOIN_NETWORK` | Bitcoin network | `mainnet`, `testnet`, or `regtest` |
| `BTCPAYGEN_CRYPTO1` | Primary cryptocurrency | `btc` |
| `BTCPAYGEN_LIGHTNING` | Lightning implementation | `clightning`, `lnd`, `eclair`, or omit |
| `BTCPAYGEN_REVERSEPROXY` | Reverse proxy | `nginx` (handles TLS) |
| `BTCPAYGEN_ADDITIONAL_FRAGMENTS` | Optional feature fragments | `opt-save-storage-s` = pruned node |
| `BTCPAY_ENABLE_SSH` | Enable SSH access management | `true` |

### Services in the generated stack

| Service | Role |
|---|---|
| `btcpayserver` | Main BTCPay Server application |
| `nbxplorer` | Lightweight Bitcoin block explorer |
| `postgres` | PostgreSQL database |
| `bitcoind` | Bitcoin Core full/pruned node |
| `clightning` / `lnd` | Lightning Network node (if configured) |
| `nginx` | Reverse proxy + TLS termination |
| `letsencrypt-nginx` | Let's Encrypt certificate management |
| `tor` | Tor hidden service (optional) |

### Post-install management

Common maintenance commands (from the `btcpayserver-docker` directory):

```bash
# Update BTCPay Server
. btcpay-update.sh

# Change domain
. changedomain.sh new.domain.com

# View all services
docker compose -f Generated/docker-compose.generated.yml ps

# View BTCPay logs
docker compose -f Generated/docker-compose.generated.yml logs btcpayserver -f
```

### Data directories

| Path | Contents |
|---|---|
| `~/.bitcoin` or Docker volume | Bitcoin blockchain data |
| `Generated/` | Auto-generated Docker Compose and config files |
| PostgreSQL volume | BTCPay metadata, invoices, stores |
| Lightning volume | Lightning wallet and channel data |

## Upgrade procedure

```bash
cd ~/BTCPayServer/btcpayserver-docker
. btcpay-update.sh
```

The update script pulls new images, recreates containers, and applies any migrations automatically. Do not `docker compose pull` manually — use the provided update script.

## Gotchas

- **Requires a public domain with DNS.** Let's Encrypt TLS requires port 80/443 reachable and a valid domain. Self-signed certs or local-only installs require manual TLS configuration.
- **Bitcoin full node needs ~600GB storage (pruned ~5GB).** The `opt-save-storage-s` fragment enables pruning, which is fine for payment processing but means you can't serve historical blockchain data.
- **Lightning Network wallets must be backed up.** If you lose `~/.lightning` or the LND wallet, you lose Lightning funds. Back up the seed/channel state regularly.
- **Initial sync takes days.** A fresh Bitcoin node needs days to sync the full blockchain. Initial block download (IBD) with pruning still requires downloading and verifying the full chain.
- **Don't edit Generated/ files manually.** The `btcpay-setup.sh` regenerates these files. Put customizations in the environment variables and re-run setup.
- **Multi-tenant hosting requires care.** If you host BTCPay for multiple users, review the server policies under Server Settings → Policies to control registration and store creation.
- **Port requirements:** Port 443 (HTTPS), 80 (Let's Encrypt), 9735 (Lightning P2P), 8333 (Bitcoin P2P) should be open.

## Links

- Upstream: <https://github.com/btcpayserver/btcpayserver>
- Docker setup repo: <https://github.com/btcpayserver/btcpayserver-docker>
- Docs: <https://docs.btcpayserver.org>
- Deployment options: <https://docs.btcpayserver.org/Deployment/>
- Lightning Network guide: <https://docs.btcpayserver.org/LightningNetwork/>
- FAQ: <https://docs.btcpayserver.org/FAQ/>

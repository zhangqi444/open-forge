---
name: SHKeeper
description: Open-source self-hosted cryptocurrency payment processor. Accepts BTC, LTC, DOGE, ETH, XMR, and more without fees or intermediaries. Kubernetes/Helm-based deployment. MIT licensed.
website: https://shkeeper.io/
source: https://github.com/vsys-host/shkeeper.io
license: MIT
stars: 561
tags:
  - cryptocurrency
  - payments
  - bitcoin
  - ecommerce
platforms:
  - Docker
  - Kubernetes
---

# SHKeeper

SHKeeper is an open-source, self-hosted cryptocurrency payment processor. It combines gateway and merchant functionality, letting you accept payments in BTC, LTC, DOGE, ETH, XMR, and more with no third-party fees or intermediaries. Integrates with WooCommerce, WHMCS, OpenCart, and PrestaShop via ready-made modules.

Official site: https://shkeeper.io/
Source: https://github.com/vsys-host/shkeeper.io
Demo: https://demo.shkeeper.io/ (admin/admin, testnet)
API docs: https://shkeeper.io/api/
Knowledge base: https://shkeeper.io/kb/

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux server | Kubernetes (k3s) + Helm | Primary supported install method |
| Any Linux VM | Docker Compose | Community/alternative method |

## Inputs to Collect

**Phase: Planning**
- Which cryptocurrencies to enable (BTC, LTC, DOGE, ETH, XMR, etc.)
- Whether to run full nodes or use lightweight wallets
- Server IP/domain for dashboard access
- Storage class for Kubernetes (local-path for k3s default)
- Auto-SSL needed (cert-manager)

**Phase: First Boot**
- Admin password (change default on first login)
- API key for connecting to e-commerce platform

## Software-Layer Concerns

Install on fresh Ubuntu 22 (k3s + Helm):

```bash
# Install k3s
curl -sfL https://get.k3s.io | sh -
mkdir /root/.kube && ln -s /etc/rancher/k3s/k3s.yaml /root/.kube/config

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Create values.yaml (enable desired coins):

```yaml
storageClassName: local-path

btc:
  enabled: true
ltc:
  enabled: true
doge:
  enabled: true
monero:
  enabled: true
  fullnode:
    enabled: true
```

Install SHKeeper helm chart:

```bash
helm repo add vsys-host https://vsys-host.github.io/helm-charts
helm repo add mittwald https://helm.mittwald.de
helm repo update
helm install kubernetes-secret-generator mittwald/kubernetes-secret-generator
helm install -f values.yaml shkeeper vsys-host/shkeeper
# Access at http://<server-ip>:5000/
```

Auto-SSL with cert-manager:

```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true
# Then configure ingress in values.yaml with your domain
```

E-commerce integrations:
- WooCommerce: https://shkeeper.io/kb/woocommerce
- WHMCS: https://shkeeper.io/kb/whmcs
- OpenCart 3 and PrestaShop 8 modules available from dashboard

API authentication:

```bash
curl -H "X-Shkeeper-Api-Key: YOUR_API_KEY" \
  https://shkeeper.example.com/api/v1/crypto
```

Dashboard port: 5000 (HTTP, or configure ingress for HTTPS)

## Upgrade Procedure

1. helm repo update
2. helm upgrade -f values.yaml shkeeper vsys-host/shkeeper
3. Check release notes: https://github.com/vsys-host/shkeeper.io/commits/main/

## Gotchas

- **Kubernetes-first**: Primary install is k3s + Helm; Docker Compose may work but is community-supported only
- **Full nodes disk**: BTC full node needs ~500GB, XMR ~100GB+; initial sync takes days to weeks
- **Testnet demo**: Public demo uses testnet — test your API integration before going to production
- **Wallet security**: Live crypto wallets on your server — enable wallet encryption, restrict access, back up wallet data regularly
- **Payout flow**: Incoming payments accumulate in SHKeeper wallets; configure payout rules to forward funds to a cold wallet
- **No gateway fees**: SHKeeper charges nothing, but on-chain network transaction fees still apply per coin

## Links

- Upstream README: https://github.com/vsys-host/shkeeper.io/blob/master/README.md
- Knowledge base: https://shkeeper.io/kb/
- API documentation: https://shkeeper.io/api/
- Demo: https://demo.shkeeper.io/
- Helm charts: https://github.com/vsys-host/helm-charts
- Tutorial video: https://www.youtube.com/watch?v=yYK_JAm1_hg

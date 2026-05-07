# DePay

**Web3 cryptocurrency payment widget** — embed peer-to-peer crypto payment buttons on any website. Accepts payments directly into your wallet (no intermediary). Supports Ethereum Virtual Machine (EVM) chains and Solana Virtual Machine (SVM). Self-hostable widget library.

**Official site:** https://depay.com  
**Source:** https://github.com/depayfi/widgets  
**Configurator:** https://app.depay.com/integrations/new  
**Demo:** https://depayfi.github.io/widgets/demo.bundle.html  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any web app | CDN script tag | No server required; purely client-side |
| Any web app | npm package (React/Node.js) | For integration into JS frameworks |

---

## Inputs to Collect

| Input | Description |
|-------|-------------|
| Wallet address | Your crypto wallet address to receive payments |
| Accepted tokens | Which tokens/chains to accept |
| Amount | Payment amount in fiat or token |

---

## Software-layer Concerns

### Via CDN (simplest)
```html
<script defer async src="https://integrate.depay.com/widgets/v13.js"></script>
```

### Via npm (React)
```bash
npm install @depay/widgets ethers react react-dom --save
# or
yarn add @depay/widgets ethers react react-dom
```

```javascript
import DePayWidgets from '@depay/widgets'

DePayWidgets.Payment({
  accept: [{
    blockchain: 'ethereum',
    amount: 20,
    token: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', // USDC
    receiver: '0xYourWalletAddress'
  }]
})
```

### Server-Side Rendering (SSR / Next.js)
DePay Widgets are client-side only. In Next.js, use dynamic import with `ssr: false`:
```javascript
const DePayWidgets = dynamic(() => import('@depay/widgets'), { ssr: false })
```

### Configuration UI
Use the visual configurator at https://app.depay.com/integrations/new to generate integration code without writing it manually.

### Supported platforms
- **EVM chains:** Ethereum, Polygon, BSC, Arbitrum, Optimism, Avalanche, Base, and more
- **SVM:** Solana

### EVM-only package (smaller bundle)
```bash
npm install @depay/widgets-evm
```

---

## Upgrade Procedure

```bash
npm update @depay/widgets
```
Or update the CDN script version number (e.g., `v13.js` → `v14.js` when new major is released).

---

## Gotchas

- **Peer-to-peer only** — payments go directly wallet-to-wallet. There is no escrow, refund mechanism, or dispute resolution built-in.
- **Wallet required on receiver side** — you need a self-custodial Web3 wallet to receive payments.
- **Client-side only** — the widget runs entirely in the browser. No backend is needed, but also means no server-side payment verification out of the box. Implement webhooks or on-chain verification for order fulfillment.
- **SSR incompatible** — must be loaded client-side only in SSR frameworks (Next.js, Nuxt, etc.).
- **Not for fiat payments** — DePay is crypto-only. There is no fiat (credit card) support.

---

## References

- Upstream README: https://github.com/depayfi/widgets#readme
- Documentation: https://depay.com/docs
- Configurator: https://app.depay.com/integrations/new

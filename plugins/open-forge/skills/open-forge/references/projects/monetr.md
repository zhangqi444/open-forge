# monetr

**Self-hosted budgeting app focused on recurring expenses — clearly shows how much is left after bills, inspired by the defunct Simple bank app.**
Official site: https://monetr.app
Docs: https://monetr.app/documentation/install/
GitHub: https://github.com/monetr/monetr

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker / Kubernetes | See install docs |

---

## Inputs to Collect

### Required
- Plaid API credentials (Client ID + Client Secret) — for bank account linking
  - Sign up: https://dashboard.plaid.com/signup

---

## Software-Layer Concerns

### Installation
Follow the official self-hosting guide:
https://monetr.app/documentation/install/

### Key features
- Budgeting around recurring expenses (bills, subscriptions)
- Shows clearly how much is left over after planned spending
- Bank account sync via Plaid
- Inspired by Simple (defunct) bank app

---

## Upgrade Procedure

See release notes and official docs: https://monetr.app/documentation/

---

## Gotchas

- Requires Plaid sandbox or production credentials for bank account linking — no bank sync without Plaid
- Full self-hosting setup requires Kubernetes or Docker; see official docs for specifics

---

## References
- Self-hosting docs: https://monetr.app/documentation/install/
- GitHub: https://github.com/monetr/monetr#readme

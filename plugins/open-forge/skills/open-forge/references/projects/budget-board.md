# Budget Board

**Self-hosted personal finance tracker — Mint alternative with accounts, transactions, budgets, goals, trends charts, SimpleFIN/LunchFlow sync, ML auto-categorization, and 2FA/OIDC auth.**
Official docs: https://budgetboard.net
GitHub: https://github.com/teelur/budget-board

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended — see docs for compose file |

---

## Inputs to Collect

### Required
- Database credentials
- App secret / JWT secret

### Optional
- SimpleFIN or LunchFlow credentials — for automatic account/transaction sync
- OIDC provider credentials — if using SSO instead of local auth

---

## Software-Layer Concerns

### Setup
Full docker-compose setup is documented at https://budgetboard.net (installation guide).

### Key features
- Accounts and assets management (checking, savings, credit cards, property)
- Transaction recording and categorization
- Monthly budgets per category
- Financial goals tracking
- Customizable trends charts (filter by date, account, category)
- CSV transaction import
- SimpleFIN and LunchFlow integration for automatic bank sync
- ML-based auto-categorization (trained on your own transactions)
- Automatic categorization rules
- Local auth with 2FA, or OIDC SSO
- Multi-language: English, German, French, Simplified Chinese

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Automatic bank sync requires a SimpleFIN or LunchFlow account (third-party services)
- ML auto-categorization improves over time as you categorize more transactions
- OIDC login requires configuring an external identity provider
- Full setup instructions at https://budgetboard.net — no docker-compose.yml in the repo root

---

## References
- Documentation / setup guide: https://budgetboard.net
- GitHub: https://github.com/teelur/budget-board#readme

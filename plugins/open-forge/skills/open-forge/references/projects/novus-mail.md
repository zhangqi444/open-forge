# Nortix Mail (Novus Mail)

**Self-hosted disposable email server — create throwaway addresses for sign-ups without exposing your real email. Node.js + simple web UI, TLS optional, auto-detects domain.**
GitHub: https://github.com/Zhoros/NortixMail

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Node.js bare metal | Node.js + npm required |

---

## Inputs to Collect

### Required
- Domain name pointing to the server (port 25 must be open/accessible)
- Port 25 open on the host — required to receive inbound SMTP

### Optional
- TLS certificate + private key (`.crt` and `.key` files) — for encrypted mail transfer

---

## Software-Layer Concerns

### Docker Compose
```bash
git clone https://github.com/Zhoros/NortixMail
cd NortixMail
docker compose up -d
```

### Ports
- `80` — web UI
- `25` — SMTP (inbound mail); do not change if using a reverse proxy (most reverse proxies cannot forward SMTP)

### TLS (optional)
Copy your certificate and key files into the `data/` folder. Nortix Mail auto-detects which file is the cert and which is the key by content — file names and extensions don't matter.

### Configuration
Edit `data/config.json` to adjust:
- Mail refresh interval
- Number of emails shown per page

### Data portability
All data lives in the `data/` folder — copy it to migrate to another server.

### Bare metal
```bash
npm install && cd front && npm install && npm run build && cd .. && node main.js
```
Listens on port 80 (HTTP) and port 25 (SMTP).

---

## Upgrade Procedure

1. git pull
2. docker compose up -d --build

---

## Gotchas

- Port 25 must be reachable from the internet for inbound mail — many VPS providers block it by default; request unblocking
- Without TLS, mail in transit can theoretically be read by anyone in the path (ISP/host); TLS is recommended for better privacy
- This is a disposable email tool, not a full mail server — not intended for sending mail

---

## References
- GitHub: https://github.com/Zhoros/NortixMail#readme

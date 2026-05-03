# Dovel

**What it is:** Simple and easy-to-use self-hosted mail server — a minimalist SMTP/IMAP server designed for personal use and small teams.
**Official URL:** https://dovel.email/server/index.html
**GitHub:** N/A

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | See upstream for details |

## Inputs to Collect

### Deploy phase
- Domain/hostname (must have proper MX, SPF, DKIM, DMARC DNS records)
- Port 25 (SMTP) availability — many VPS providers block this
- TLS certificate (Let's Encrypt recommended)

## Software-Layer Concerns

- **Config:** See upstream documentation
- **Data dir:** Persistent volume for mail storage
- **Key env vars:** See upstream docs

## Upgrade Procedure

Pull latest image and restart. Back up mail data first.

## Gotchas

- Running a mail server requires proper DNS setup (MX, SPF, DKIM, DMARC)
- Port 25 is blocked by many VPS providers by default — check before deploying
- IP reputation matters for deliverability; new IPs are often initially distrusted
- Consider mail forwarding services (Mailgun, SES) for outbound if deliverability is critical

## References

- [Official Site](https://dovel.email/server/index.html)

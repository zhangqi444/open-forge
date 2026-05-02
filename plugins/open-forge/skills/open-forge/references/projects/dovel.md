# Dovel

**What it is:** A simple and easy-to-use self-hosted mail server. Handles SMTP sending and receiving for your own domains. Designed to be low-friction to set up compared to full mail stacks like Mailcow or Mailu.

> ⚠️ **Limited documentation / custom license.** Source and documentation at https://dovel.email/server/index.html — verify current status before deploying.

**Official URL:** https://dovel.email
**Docs:** https://dovel.email/server/index.html
**License:** Custom (see upstream)
**Stack:** Not fully disclosed; refer to upstream docs

---

## Compatible Combos

See upstream documentation at https://dovel.email/server/index.html for current installation instructions and system requirements.

---

## Inputs to Collect

### Typical mail server requirements
- Domain with DNS control — MX, SPF, DKIM, DMARC records required
- Ports — SMTP (25), submission (587), SMTPS (465), IMAP (143/993) — ensure VPS provider allows port 25 outbound
- Reverse DNS (PTR) record — critical for deliverability; configure with your VPS provider

---

## Gotchas

- **Port 25 may be blocked** — many VPS providers (AWS, GCP, Azure, Hetzner) block outbound port 25 by default; verify before choosing a host for mail
- **DNS setup is mandatory** — mail without correct SPF/DKIM/DMARC records will be rejected or marked spam by major providers
- **Custom license** — review the license at https://dovel.email before deploying in a commercial context
- **Established alternatives:** [Mailcow](https://github.com/mailcow/mailcow-dockerized), [Mailu](https://github.com/Mailu/Mailu), and [Stalwart Mail](https://github.com/stalwartlabs/mail-server) are widely used open-source self-hosted mail server stacks

---

## Links
- Website: https://dovel.email
- Server docs: https://dovel.email/server/index.html

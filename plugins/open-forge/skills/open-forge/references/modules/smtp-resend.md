---
name: smtp-resend
description: Configure Resend as the outbound SMTP provider. Read during the `smtp` phase when the user chooses Resend. Contains host/port/auth values and the verification steps.
---

# Outbound email via Resend

Resend is a developer-friendly transactional email API that also exposes SMTP credentials.

## Prerequisites

- A Resend account with a **verified sending domain** (or at least a verified single sender). Without domain verification, Resend refuses the send with a clear error in its dashboard.
- An API key from `https://resend.com/api-keys`. Format: `re_<random>`.

If the user hasn't verified a domain yet, point them at Resend's dashboard and wait — don't attempt SMTP until verification is green.

## SMTP settings

| Field | Value |
|---|---|
| Host | `smtp.resend.com` |
| Port | `465` |
| Secure (implicit TLS) | `true` |
| User | `resend` (literal string — NOT the account email) |
| Pass | the `re_...` API key |
| From | any address on a verified domain; friendly name optional |

Port 587 with STARTTLS also works if the app insists on it.

## Inputs to collect

- `smtp_api_key` — the `re_...` key
- `smtp_from_address` — e.g. `hello@example.com` on a verified domain
- `smtp_from_name` — display name, e.g. `Aria Zhang`

## Applying to the app

Hand off to the project recipe — each app stores mail config differently. Ghost, for example, puts it in `/opt/bitnami/ghost/config.production.json` as a nested `mail` block. See `references/projects/ghost.md` for the exact JSON shape.

Generic shape (Nodemailer-style, which most Node apps accept):

```json
{
  "transport": "SMTP",
  "from": "'<Display Name>' <<from-address>>",
  "options": {
    "host": "smtp.resend.com",
    "port": 465,
    "secure": true,
    "auth": {
      "user": "resend",
      "pass": "re_..."
    }
  }
}
```

## Verification

1. Restart the app.
2. In the app's admin UI, send a test email — most apps have a "Send test" button in account or email settings.
3. Check the recipient inbox (including spam).
4. Open `https://resend.com/logs` and confirm the send appears with status `delivered` (or `bounced` / `complained` if something went wrong).

If the test fails:

- **`authentication failed`** — user string isn't `resend`, or the API key was mis-pasted.
- **`domain not verified`** — finish Resend's DNS setup (SPF, DKIM, Return-Path).
- **No error but no delivery** — check Resend's log; the message may have been suppressed due to a prior bounce.

## Security

After verifying, rotate the API key if it was pasted into the chat. Create a new key, update the app config, delete the old key in Resend. Log this in the hardening phase.

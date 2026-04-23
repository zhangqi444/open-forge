---
name: inbound-improvmx
description: Set up inbound email forwarding with ImprovMX. Read during the optional `inbound` phase when the user wants `hello@<domain>` (etc.) to forward to an existing inbox.
---

# Inbound email forwarding via ImprovMX

Most self-hosted web apps don't need to *receive* mail, but the user often wants `hello@<domain>` or similar to forward to their real inbox. Running a full mail server for this is overkill. ImprovMX offers free forwarding on custom domains.

## When to use this

- User wants `<alias>@<domain>` → their existing Gmail / Fastmail / etc.
- User does NOT want to run IMAP / a mailbox on the instance.

If the user wants to send **from** the alias (reply-as), they need both:

1. Inbound forwarding (this file), and
2. The outbound SMTP provider (`smtp-*.md`) configured with the alias as an allowed From address on a verified domain.

Often the same domain is used for both — so SPF/DKIM for outbound must coexist with ImprovMX's MX records for inbound.

## Setup

1. Sign up at `https://improvmx.com/` and add the domain.
2. ImprovMX prints two MX records to add at the registrar:

   ```
   Type  Host  Priority  Value
   MX    @     10        mx1.improvmx.com
   MX    @     20        mx2.improvmx.com
   ```

3. Add an SPF record so ImprovMX can forward without SPF failures:

   ```
   Type  Host  Value
   TXT   @     v=spf1 include:spf.improvmx.com ~all
   ```

   If the user already has an outbound SPF record (e.g. from Resend: `include:amazonses.com` or similar), **merge** the `include:` tokens into one TXT — do not publish two SPF records on the apex.

4. In the ImprovMX dashboard, create aliases: e.g. `hello@<domain>` → `user@gmail.com`.

## Verification

```bash
dig +short MX "$DOMAIN" @1.1.1.1
# Expect mx1.improvmx.com and mx2.improvmx.com

dig +short TXT "$DOMAIN" @1.1.1.1
# Expect a v=spf1 record that includes spf.improvmx.com
```

Send a test email from a third-party (phone, different account) to `hello@<domain>`. Confirm:

- Arrival in the destination inbox.
- ImprovMX dashboard shows the forward event.

## Gotchas

- **Multiple SPF records**: Only ONE SPF record per domain is valid. If the user had a previous SPF, combine `include:` directives instead of adding a second TXT.
- **DMARC considerations**: If the domain publishes a strict DMARC policy (`p=reject`), forwarded mail may fail DMARC on the destination side because the original sender's DKIM doesn't cover the forwarding hop. ImprovMX handles ARC/SRS to mitigate, but strict receivers (some corporate inboxes) may still reject. For a personal blog this rarely matters.
- **Catch-all vs explicit aliases**: ImprovMX lets you set `*@<domain>` → one inbox. Convenient, but attracts spam. Prefer explicit aliases.

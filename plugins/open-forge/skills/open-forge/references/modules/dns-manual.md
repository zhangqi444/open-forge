---
name: dns-manual
description: Guide the user through manually adding DNS records at their registrar and verifying propagation. Used by open-forge during the `dns` phase. Registrar-agnostic.
---

# Manual DNS setup

open-forge does not automate registrar APIs (they vary wildly and most personal users don't keep API tokens handy). Instead, print the exact records and poll until they resolve.

## What to print

Given `domain` and `canonical` preference (`www` or `apex`), print a copy-pasteable block:

```
At your DNS registrar, add these records:

  Type   Host                 Value
  A      @                    <PUBLIC_IP>
  A      www                  <PUBLIC_IP>

(You can omit the second one if you never want www to work, but most TLS tools
expect both to resolve so they can issue a cert covering both.)
```

If the infra provides an apex-alias feature (e.g. Route 53 ALIAS), mention it — but the A-record approach works universally.

## Which to make canonical

- **`canonical: www`** — Safer across all infra/DNS combinations. Required if the infra cannot answer at the apex (rare for Lightsail-style VPSes, but common for managed platforms).
- **`canonical: apex`** — Cleaner URL, but some registrars or CDNs have edge cases at apex.

Default to asking the user. Record the choice as `inputs.canonical`.

## Verifying propagation

Poll from the user's machine:

```bash
dig +short "$DOMAIN" @1.1.1.1
dig +short "www.$DOMAIN" @1.1.1.1
```

Use a public resolver (`@1.1.1.1` or `@8.8.8.8`) to bypass ISP caches. Expect both to return the static IP.

Typical propagation time:

- Many modern registrars: under 60 seconds.
- TTL-cached resolvers or older providers: 5–30 minutes.
- Worst case (TTL 3600+): up to an hour.

Poll every 15–30 seconds for up to ~15 minutes before suggesting the user double-check the registrar. Do not mark the phase done until both hosts resolve to the expected IP.

## Before proceeding to TLS

TLS issuance via ACME HTTP-01 requires the domain(s) to already resolve to the instance and port 80 to be reachable. Never start the TLS phase until DNS is verified.

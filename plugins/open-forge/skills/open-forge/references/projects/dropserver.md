# Dropserver

**Application platform for personal web services** — run small web apps (appspaces) written in TypeScript/Deno in isolated sandboxes on your own server. Each app gets its own appspace with user management, migrations, and access control handled by the platform.

**Official site:** https://dropserver.org
**Source:** https://github.com/teleclimber/Dropserver
**License:** Apache-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VPS (x86_64) | ds-host binary | Server daemon; Linux/x86_64 only |
| Local dev (Linux/Mac) | ds-dev binary | Development tool; run apps locally |

---

## Inputs to Collect

### Phase 1 — Planning
- Linux x86_64 host (required for `ds-host`)
- Deno version to install separately (not bundled)
- Domain for the server instance

### Phase 2 — Deploy
- Deno installation path (must be accessible to `ds-host`)
- Server config file (data directories, ports, domain)

---

## Software-Layer Concerns

- **Two binaries:**
  - `ds-host` — production server; runs apps in sandboxed Deno environments; Linux x86_64 only
  - `ds-dev` — local development tool; Linux and Mac; for building/testing Dropserver apps
- **Deno required separately** — not bundled; install Deno on the host before running `ds-host`
- **App code runs in Deno sandbox** — TypeScript/JavaScript app logic executes in isolated Deno processes
- **Appspaces** — each deployed app instance gets its own appspace with isolated data, users, and migrations
- **Frontend:** Vue 3 admin UI for managing apps, appspaces, and users

---

## Deployment

Follow the official ds-host setup guide:
https://dropserver.org/docs/ds-host/

Key steps:
1. Install Deno on the host
2. Download the `ds-host` binary for Linux x86_64 from GitHub releases
3. Create a config file specifying data directories, Deno path, and domain
4. Run `ds-host` (or set up as a systemd service)
5. Access the admin UI to upload app packages and create appspaces

For local development:
https://dropserver.org/docs/ds-dev/

---

## Upgrade Procedure

1. Download new `ds-host` binary from GitHub releases
2. Stop the running `ds-host` instance
3. Replace the binary
4. Start `ds-host` — it will run any pending migrations automatically

---

## Gotchas

- **Linux x86_64 only** for `ds-host` production server — no ARM, no macOS for server use
- **Alpha-quality software** — some goroutine/memory leaks exist; some features are incomplete; treat with caution
- **Security warning:** Do not run on a public internet VM with sensitive data until the project matures; treat the VM as isolated
- **Inspect app code** before running — Dropserver is designed to run untrusted code; review what you deploy
- **Deno must be installed manually** — `ds-host` expects a Deno binary at a configured path; version compatibility matters
- **No Docker image** — official deployment is via binary; community images may exist but are not official

---

## Links

- Upstream README: https://github.com/teleclimber/Dropserver#readme
- ds-host setup: https://dropserver.org/docs/ds-host/
- ds-dev guide: https://dropserver.org/docs/ds-dev/
- Project site: https://dropserver.org

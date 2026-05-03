---
name: rapidforge-project
description: Lightweight self-hosted platform for building and deploying webhooks, APIs, and scheduled tasks using Bash or Lua scripts. Upstream: https://github.com/rapidforge-io/rapidforge
---

# RapidForge

Lightweight, self-hosted platform for quickly creating webhooks, APIs, periodic tasks, and dynamic pages using Bash or Lua scripts. Clean web UI, SQLite backend, single binary with no dependencies. Built-in OAuth2/bearer auth, event logging, drag-and-drop page builder, and self-updater. Upstream: <https://github.com/rapidforge-io/rapidforge>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Pre-built binary | [Releases page](https://github.com/rapidforge-io/release) | ✅ | Recommended — single binary, no deps |
| Build from source | [GitHub README](https://github.com/rapidforge-io/rapidforge#or-build-from-source) | ✅ | Development |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Binary download or build from source?" | options | All |
| config | Port to run on (default varies) | number | All |

## Binary install

Source: <https://github.com/rapidforge-io/release>

1. Download the latest binary for your platform from the [releases page](https://github.com/rapidforge-io/release).
2. Make it executable and run:

```bash
chmod +x rapidforge
./rapidforge
```

On first start, RapidForge creates an admin user and prints the credentials to stdout (once only). Log in and change your password.

## Build from source

```bash
git clone https://github.com/rapidforge-io/rapidforge.git
cd rapidforge
mise install   # requires https://mise.jdx.dev/
make build
./rapidforge
```

## Key features

- Create HTTP endpoints (webhooks/APIs) with custom paths and methods
- Schedule scripts with cron-like syntax
- Build dynamic pages with drag-and-drop editor and embedded scripts
- Bash and Lua supported; built-in HTTP and JSON libraries
- OAuth2 integration + bearer token auth
- SQLite — zero-configuration, serverless database
- Built-in self-updater

## Upgrade procedure

Download the new binary from the [releases page](https://github.com/rapidforge-io/release) and replace the existing one. RapidForge also has a built-in self-update mechanism.

## Gotchas

- Admin password is shown **once** on first start — save it immediately.
- No Docker image documented in the README — binary install is the supported method.
- Requires [mise](https://mise.jdx.dev/) for source builds (manages Go and Node.js versions).
- Full configuration and deployment guides at <https://rapidforge.io/docs>.

## References

- GitHub: <https://github.com/rapidforge-io/rapidforge>
- Releases: <https://github.com/rapidforge-io/release>
- Documentation: <https://rapidforge.io/docs>

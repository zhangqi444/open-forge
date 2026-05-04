---
name: webstudio
description: Webstudio recipe for open-forge. Open-source visual development platform (no-code/low-code website builder). AGPL-3.0. Self-hosting via the Webstudio CLI and Node.js + PostgreSQL stack. NOTE: the project's primary focus is the SaaS offering; self-hosting is significantly more complex.
---

# Webstudio

Open-source visual development platform — a drag-and-drop website and web-app builder that outputs clean semantic HTML and CSS. Upstream: <https://github.com/webstudio-is/webstudio>. Site: <https://webstudio.is>. Docs: <https://docs.webstudio.is/>.

Webstudio can be self-hosted using the Webstudio CLI (`npx webstudio`) on top of Node.js 18+ and PostgreSQL, with media/assets stored on local disk or an S3-compatible service. The project's primary focus is its hosted SaaS offering at webstudio.is; self-hosting is significantly more complex and the cloud version (free tier available) is the easier option for most users.

| | |
|---|---|
| **License** | AGPL-3.0 (note: `sdk-components-animation` package has a separate proprietary EULA — see Gotchas) |
| **Stars** | ~5 K |
| **GitHub** | <https://github.com/webstudio-is/webstudio> |
| **Site** | <https://webstudio.is> |

## Compatible install methods

| Method | Upstream docs | First-party? | When to use |
|---|---|---|---|
| Webstudio CLI (`npx webstudio`) | <https://docs.webstudio.is/self-hosting> | ✅ | Primary self-hosting path. Node.js + PostgreSQL required. |
| Webstudio Cloud (hosted) | <https://webstudio.is> | ✅ | Hosted SaaS; free tier available. No server required. Out of scope for open-forge. |

## Inputs to collect

Phase-keyed prompts. Ask at the phase where each is needed.

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Self-host or use Webstudio Cloud? (Cloud is easier — free tier available)" | Options: `Self-host` / `Cloud (out of scope)` | Determines whether to proceed with this recipe. |
| infra | "Node.js 18+ and PostgreSQL available on the target host?" | Confirm | Self-host. Both are hard prerequisites. |
| software | "PostgreSQL connection string? (e.g. `postgresql://user:pass@localhost:5432/webstudio`)" | Free-text (sensitive) | Self-host. Set as `DATABASE_URL`. |
| software | "Auth secret? (random string for session signing — generate with `openssl rand -hex 32`)" | Free-text (sensitive) | Self-host. Set as `AUTH_SECRET`. |
| software | "Set up GitHub OAuth login? (optional — required if no other OAuth provider is configured)" | Options: `Yes` / `No` | Self-host. |
| software | "GitHub OAuth Client ID and Secret?" | Free-text (sensitive) | Only if GitHub OAuth selected. |
| software | "Set up Google OAuth login? (optional)" | Options: `Yes` / `No` | Self-host. |
| software | "Google OAuth Client ID and Secret?" | Free-text (sensitive) | Only if Google OAuth selected. |
| software | "Media/asset storage: local filesystem or S3-compatible?" | Options: `Local filesystem` / `S3-compatible` | Self-host. |

After each prompt, write the value into the state file under `inputs.*`.

## Software-layer concerns

### Prerequisites

- Node.js 18+
- PostgreSQL (any recent version)
- A configured OAuth provider (GitHub and/or Google) — Webstudio has no built-in username/password auth

### Key environment variables

| Variable | Description | Required |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string (`postgresql://user:pass@host:5432/dbname`) | ✅ |
| `AUTH_SECRET` | Random secret for session token signing | ✅ |
| `GITHUB_CLIENT_ID` | GitHub OAuth app Client ID | One of GitHub or Google must be configured |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth app Client Secret | One of GitHub or Google must be configured |
| `GOOGLE_CLIENT_ID` | Google OAuth app Client ID | Optional if GitHub is configured |
| `GOOGLE_CLIENT_SECRET` | Google OAuth app Client Secret | Optional if GitHub is configured |

### Install via CLI

```bash
npx webstudio
```

This interactive CLI bootstraps a local Webstudio instance, sets up the database schema, and starts the server. Follow the prompts and provide the environment variables above.

### Data storage

| Data type | Where it lives |
|---|---|
| Projects, pages, components | PostgreSQL (via `DATABASE_URL`) |
| Uploaded media / assets | Local filesystem or S3-compatible object storage |

### Self-hosting docs

Full self-hosting instructions: <https://docs.webstudio.is/self-hosting>

There is no official pre-built Docker image. Self-hosting requires either the CLI toolchain or building from source.

## Upgrade procedure

Webstudio does not publish a versioned Docker image or a dedicated upgrade command. The general upgrade path for CLI-based installs:

```bash
# Pull the latest CLI and rebuild
npx webstudio@latest
```

Refer to the self-hosting docs (<https://docs.webstudio.is/self-hosting>) for any migration steps required between versions, as the upgrade procedure may change between releases.

## Gotchas

- **Self-hosting is significantly more complex than using the cloud version.** The project's primary focus is the hosted SaaS at webstudio.is, which offers a free tier. Self-hosting requires managing Node.js, PostgreSQL, OAuth credentials, and asset storage yourself. Evaluate whether self-hosting is necessary before proceeding.
- **The `sdk-components-animation` package is proprietary.** This package is not covered by the AGPL-3.0 license — it has a separate EULA. Review that EULA before using or distributing it in a self-hosted deployment.
- **No official pre-built Docker image.** Unlike most self-hostable apps, there is no `docker pull webstudio` path. Self-hosting requires the CLI toolchain (`npx webstudio`) or building from the source repository.
- **No built-in username/password authentication.** Webstudio ships with social OAuth login only (GitHub and Google out of the box). You must configure at least one OAuth provider before any user can log in. There is no fallback admin account or local auth.

## Links

- Site: <https://webstudio.is>
- Docs: <https://docs.webstudio.is/>
- Self-hosting docs: <https://docs.webstudio.is/self-hosting>
- GitHub: <https://github.com/webstudio-is/webstudio>

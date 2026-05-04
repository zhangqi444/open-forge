# Bruno

Open-source API client and IDE for exploring and testing APIs. Bruno stores collections as plain-text files (`.bru` format) directly in your filesystem — no cloud sync, no forced accounts. Works seamlessly with Git for version control of API collections. A privacy-focused alternative to Postman and Insomnia. Upstream: <https://github.com/usebruno/bruno>. Docs: <https://docs.usebruno.com>.

> **Note:** Bruno is primarily a **desktop application** (Electron-based for Windows, macOS, Linux). There is no self-hosted server component — "self-hosted" here means the app is free, open-source, and keeps all data local. Collections live on your filesystem and can be committed to Git.

## Compatible install methods

Verified against upstream docs at <https://github.com/usebruno/bruno#installation>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Download binary (macOS/Windows/Linux) | <https://www.usebruno.com/downloads> | ✅ | Desktop app. Primary install method. |
| Homebrew (macOS/Linux) | `brew install bruno` | ✅ | macOS / Linux desktop. |
| Chocolatey (Windows) | `choco install bruno` | Community | Windows desktop. |
| Snap (Linux) | `snap install bruno` | Community | Linux snap store. |
| Flatpak (Linux) | `flatpak install flathub com.usebruno.Bruno` | Community | Linux Flatpak. |
| apt (Debian/Ubuntu) | See <https://github.com/usebruno/bruno/discussions/269> | Community | Linux package manager. |
| npm CLI (`@usebruno/cli`) | `npm install -g @usebruno/cli` | ✅ | Headless CI/CD execution of Bruno collections. |

## Inputs to collect

No server inputs needed — Bruno is a local desktop application. For the CLI runner:

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| cli | "Path to Bruno collection directory?" | Free-text | CLI runner |
| cli | "Environment to use?" | Free-text (matches `.bru` env file name) | CLI runner |

## Software-layer concerns

### Collection format (`.bru` files)

Bruno uses a human-readable plain-text format called **Bru**. Each request is a `.bru` file:

```bru
meta {
  name: Get Users
  type: http
  seq: 1
}

get {
  url: {{baseUrl}}/users
  body: none
  auth: bearer
}

headers {
  Accept: application/json
}

auth:bearer {
  token: {{apiToken}}
}
```

Collections are directories of `.bru` files — commit them to Git like any other code.

### Environment variables

Environments are stored as `.bru` env files in a `environments/` subdirectory of the collection. They can hold variables like `baseUrl`, `apiToken`, etc. Secret values can be stored in a `.gitignore`d `environments/*.bru.secret` file.

### CLI runner (CI/CD integration)

Run collections headlessly in CI:

```bash
# Install
npm install -g @usebruno/cli

# Run a collection
bru run --env Production /path/to/collection

# Run a specific request
bru run request.bru --env Production

# Output JUnit XML for CI
bru run --env Production --output results.xml --format junit
```

### Data storage

| Location | Contents |
|---|---|
| Collection directory | `.bru` request files, `bruno.json` (collection config) |
| `environments/` | Environment variable files |
| `~/.config/bruno/` (or OS equivalent) | App settings, preferences |

No database. No cloud. No accounts required.

## Upgrade procedure

- **Desktop app:** Bruno has a built-in auto-updater. Or download the latest from <https://www.usebruno.com/downloads>.
- **Homebrew:** `brew upgrade bruno`
- **npm CLI:** `npm update -g @usebruno/cli`

## Gotchas

- **Desktop-only — no web UI or server.** Bruno does not have a self-hosted web interface. It's a local desktop app. If you need a shared team API workspace, use a shared Git repo for collections.
- **Offline-only by design.** There are no plans to add cloud sync. This is intentional. Collaboration happens through Git.
- **Commercial versions exist.** Bruno has a free open-source tier and paid plans ("Bruno Enterprise") with team features. Core functionality is free.
- **`bru` CLI is separate from the app.** The CLI (`@usebruno/cli`) is an npm package for headless/CI use. Install it separately.
- **"Bruno" trademark.** The name "Bruno" is trademarked. If you fork, use a different name.
- **Secret management.** Never commit `.bru.secret` environment files. Add them to `.gitignore`. Use CI environment variables or a secrets manager for production tokens.

## Links

- Upstream: <https://github.com/usebruno/bruno>
- Website: <https://www.usebruno.com>
- Docs: <https://docs.usebruno.com>
- Downloads: <https://www.usebruno.com/downloads>
- CLI (`@usebruno/cli`): <https://www.npmjs.com/package/@usebruno/cli>
- Collection format (Bru): <https://docs.usebruno.com/bru-language-design>

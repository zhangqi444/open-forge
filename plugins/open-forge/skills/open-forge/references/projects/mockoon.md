---
name: mockoon
description: Mockoon recipe for open-forge. Open-source API mocking tool with a desktop app and CLI. Design and run mock REST APIs locally — no account required.
---

# Mockoon

Open-source API mocking tool. Design mock APIs with a desktop GUI, then run them locally or in CI via the CLI. Supports unlimited mock servers and routes, OpenAPI import/export, JSON templating, proxy mode, and request logging. No remote deployment or account required for core use. Upstream: <https://github.com/mockoon/mockoon>. Docs: <https://mockoon.com/docs/latest/about/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Desktop app (macOS/Windows/Linux) | Design and run mocks locally with GUI |
| CLI (`@mockoon/cli`) | Headless / CI / Docker / server deployment |
| Docker (CLI image) | Self-hosted mock API server |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which method: desktop, CLI, or Docker?" | Drives install path |
| preflight | "Mockoon environment file (.json)?" | Export from desktop app; used by CLI/Docker |

## Desktop app install

| OS | Method |
|---|---|
| macOS | `brew install --cask mockoon` or download from [mockoon.com/download](https://mockoon.com/download/) |
| Windows | `winget install mockoon` or Windows Store |
| Linux | `snap install mockoon` or download AppImage |

## CLI install

```bash
npm install -g @mockoon/cli

# Run a mock from an exported environment file
mockoon-cli start --data ./my-environment.json --port 3001
```

## Docker (self-hosted mock server)

```bash
docker run -d \
  -p 3001:3001 \
  -v /path/to/my-environment.json:/data/mock.json \
  mockoon/cli:latest \
  start --data /data/mock.json --port 3001
```

Or with Docker Compose:

```yaml
version: "3.9"
services:
  mock-api:
    image: mockoon/cli:latest
    command: start --data /data/mock.json --port 3001
    ports:
      - "3001:3001"
    volumes:
      - ./my-environment.json:/data/mock.json
    restart: unless-stopped
```

## Software-layer concerns

- Desktop app runs mock servers locally; each environment (mock server) runs on a configurable port
- CLI image: `mockoon/cli` (Docker Hub)
- Environment files (`.json`) are exported from the desktop app and consumed by CLI/Docker
- Supports OpenAPI 3.0 import/export — import a spec to auto-generate mock routes
- Proxy mode: forward unmatched requests to a real API (useful for partial mocking)
- HTTPS: supported via CLI `--tls` flag

## Upgrade procedure

- Desktop: auto-update notification in app; or re-download from website
- CLI: `npm update -g @mockoon/cli`
- Docker: `docker pull mockoon/cli:latest`, restart container

## Gotchas

- Mockoon Cloud (paid) adds team sync, hosted mocks, and AI-assisted mock generation — not required for self-hosting
- Environment files are plain JSON — keep them in version control
- The desktop app and CLI use the same environment file format
- No persistent state by default — mock responses are defined in the environment file, not a database

## Links

- GitHub: <https://github.com/mockoon/mockoon>
- Docs: <https://mockoon.com/docs/latest/about/>
- Download: <https://mockoon.com/download/>
- Docker Hub (CLI): <https://hub.docker.com/r/mockoon/cli>

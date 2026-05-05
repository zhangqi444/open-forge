---
name: google-webfonts-helper
description: "Self-host Google Fonts hassle-free — browse the full Google Fonts catalog, download font files (eot, ttf, svg, woff, woff2) and get ready-made CSS snippets for self-hosting. Node.js. MIT."
---

# google-webfonts-helper

google-webfonts-helper is a web app and API that makes self-hosting Google Fonts trivial. Browse the full Google Fonts catalog, select a font, choose weights and character sets, and get the font files (all formats) plus copy-paste CSS `@font-face` snippets — all ready to drop into your project.

Created by Mario Ranftl. A public instance runs at gwfh.mranftl.com; self-host if you need an internal/offline tool or want to guarantee availability.

`depends_3rdparty: true` — the app fetches font metadata and files from Google Fonts API. Without internet access to Google's font servers, the font catalog won't be available.

Use cases: (a) download Google Fonts for self-hosting on your web server (b) internal tool for teams that need GDPR-compliant font delivery without loading from Google's CDN (c) automate font downloads in build pipelines via the REST API (d) air-gapped intranet sites needing fonts without external CDN.

Features:

- **Full Google Fonts catalog** — browse and search all available Google Font families
- **All font formats** — downloads eot, ttf, svg, woff, woff2 for maximum browser compatibility
- **CSS snippet generation** — ready-made `@font-face` CSS for any subset/weight combination
- **Multiple character subsets** — latin, latin-ext, cyrillic, greek, etc.
- **Font weight selection** — pick exactly the weights you need (400, 700, italic, etc.)
- **REST API** — programmatic access; use in build scripts/pipelines
- **Simple self-hosting** — Node.js app; no database; docker-ready

- Upstream repo: https://github.com/majodev/google-webfonts-helper
- Public instance: https://gwfh.mranftl.com/fonts
- API docs: available at `/api/fonts` on any running instance

## Architecture

- **Node.js** web server
- **No database** — font metadata fetched from Google Fonts API at runtime; optionally cached
- **No persistent storage required** — stateless; font files served on demand
- **Docker-ready** — official Dockerfile in repo

## Compatible install methods

| Infra       | Runtime        | Notes                                               |
|-------------|----------------|-----------------------------------------------------|
| Docker      | Docker         | Simplest; one command                               |
| Node.js     | npm start      | Clone + install + start                             |
| VPS         | Docker or Node | Behind nginx reverse proxy                          |

## Inputs to collect

| Input     | Example               | Phase  | Notes                                                  |
|-----------|-----------------------|--------|--------------------------------------------------------|
| Port      | `3000`                | Config | Default port                                           |
| Domain    | `fonts.example.com`   | URL    | Optional; for internal use behind reverse proxy        |

## Quick start (Docker)

```sh
docker run -d \
  -p 3000:3000 \
  --name google-webfonts-helper \
  ghcr.io/majodev/google-webfonts-helper:latest
```

Open `http://localhost:3000/fonts`.

## Quick start (Node.js)

```sh
git clone https://github.com/majodev/google-webfonts-helper.git
cd google-webfonts-helper
npm install
npm start
# → http://localhost:3000
```

## API usage (for build pipelines)

```bash
# List all fonts
curl http://localhost:3000/api/fonts

# Get specific font details
curl http://localhost:3000/api/fonts/roboto

# Download font files (via the web UI download button)
# The UI generates a ZIP of all font files for the selected variant
```

Example API response for a font:
```json
{
  "id": "roboto",
  "family": "Roboto",
  "variants": ["100", "100italic", "300", "300italic", "regular", "italic", "500", ...],
  "subsets": ["latin", "latin-ext", "cyrillic", "cyrillic-ext", "greek", "greek-ext", "vietnamese"],
  "category": "sans-serif",
  "version": "v47",
  "lastModified": "2023-09-14"
}
```

## CSS output example

After selecting Roboto 400+700 (latin), the tool generates:

```css
/* roboto-400-latin */
@font-face {
  font-display: swap;
  font-family: 'Roboto';
  font-style: normal;
  font-weight: 400;
  src: url('../fonts/roboto-v47-latin-regular.eot');
  src: url('../fonts/roboto-v47-latin-regular.eot?#iefix') format('embedded-opentype'),
       url('../fonts/roboto-v47-latin-regular.woff2') format('woff2'),
       url('../fonts/roboto-v47-latin-regular.woff') format('woff'),
       url('../fonts/roboto-v47-latin-regular.ttf') format('truetype'),
       url('../fonts/roboto-v47-latin-regular.svg#Roboto') format('svg');
}
```

Place font files in your project and point the CSS paths accordingly.

## Gotchas

- **Requires internet access to Google Fonts API** — the app queries Google's font API to build its catalog. Without outbound internet access, the font list won't load. Not suitable for fully air-gapped environments (you'd need to cache/pre-populate the data).
- **Font license is Google Fonts' license** — fonts are typically Open Font License (OFL) or Apache 2.0. Verify the specific font's license before use in commercial products (most are OFL which is very permissive).
- **GDPR motivation** — many European sites self-host Google Fonts to avoid GDPR issues with loading fonts from Google's CDN (which logs visitor IPs). This tool makes that easy, but you still need to handle font caching and HTTP/2 push yourself.
- **Low maintenance cadence** — the project is stable but not actively developed (commits are infrequent). It works well as-is; no concern unless Google changes their Fonts API format.
- **SVG fonts are legacy** — the eot and svg formats are only needed for very old browsers (IE8, old iOS). If you only need modern browsers, woff2 + woff is sufficient.
- **Alternatives:** Download directly from Google Fonts website (manual, one font at a time), `google-webfonts-helper` npm CLI tools, Fontsource (npm packages for self-hosting fonts).

## Links

- Repo: https://github.com/majodev/google-webfonts-helper
- Public instance: https://gwfh.mranftl.com/fonts
- Docker image: https://github.com/majodev/google-webfonts-helper/pkgs/container/google-webfonts-helper

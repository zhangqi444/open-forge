---
name: gollum-project
description: Gollum recipe for open-forge. Covers Docker and Ruby gem install as documented at https://github.com/gollum/gollum.
---

# Gollum

Git-based wiki system. Pages are stored as human-editable markup files (Markdown, AsciiDoc, Org, RST, Textile, etc.) in a Git repository. Compatible with GitHub and GitLab wikis — clone your remote wiki and browse/edit it locally. Upstream: <https://github.com/gollum/gollum>. Docs: <https://github.com/gollum/gollum/wiki>.

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker | <https://hub.docker.com/r/gollumwiki/gollum> | No Ruby environment required; recommended for most |
| Ruby gem | <https://github.com/gollum/gollum#as-a-ruby-gem> | Direct install on a system with Ruby ≥ 2.5 |
| Build from source | <https://github.com/gollum/gollum#running-from-source> | Development or latest commits |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Where is (or where should) the wiki Git repo live?" | Host directory path | Bind-mounted at `/wiki` inside container. Must be a git repo (`git init` first if new). |
| preflight | "Which port should Gollum listen on?" | Number (default `4567`) | |
| auth (optional) | "Enable authentication?" | Yes/No | Gollum has no built-in auth — use reverse proxy (Nginx/Caddy with basic auth) |

## Docker quick-start (from upstream README)

```bash
# Initialize a new wiki repo (once):
mkdir my-wiki && cd my-wiki && git init

# Run Gollum:
docker run -d \
  --name gollum \
  -p 4567:4567 \
  -v $(pwd)/my-wiki:/wiki \
  gollumwiki/gollum
```

Visit `http://localhost:4567`.

To use with an existing GitHub/GitLab wiki:
```bash
git clone https://github.com/<user>/<repo>.wiki.git my-wiki
docker run -d --name gollum -p 4567:4567 -v $(pwd)/my-wiki:/wiki gollumwiki/gollum
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Wiki storage | The mounted directory IS the git repository. All pages are committed files. |
| Git required | The wiki directory must be a valid git repo (`git init`). Gollum commits every save. |
| Supported markup | Markdown, AsciiDoc, MediaWiki, Org-mode, reStructuredText, Textile, Creole, RDoc — auto-detected by file extension |
| Port | Default `4567`. Change with `--port <n>` flag passed after the image name. |
| Authentication | None built-in. Protect with Nginx/Caddy basic auth or an OAuth proxy (e.g. `oauth2-proxy`). |
| Diagrams | Mermaid and PlantUML supported (PlantUML requires a running PlantUML server; pass `--plantuml-url`). |
| Mathematics | KaTeX or MathJax via `--mathjax` or `--katex` flag. |
| File uploads | Enable with `--allow-uploads page` (per-page) or `--allow-uploads dir` (shared dir). |
| Base path | If running behind a reverse proxy at a sub-path: `--base-path /wiki` flag. |

## Upgrade procedure

Per <https://github.com/gollum/gollum/releases>:

1. Pull the new image: `docker pull gollumwiki/gollum`
2. Stop and remove the old container: `docker stop gollum && docker rm gollum`
3. Start a new container with the same volume mount (all wiki content is in the git repo — no data loss).

For gem installs: `gem update gollum`.

No database migrations — all data is stored as files in the git repo.

## Gotchas

- **Git repo required**: the wiki directory must already be `git init`-ed. Running Gollum against a plain directory fails with a confusing error.
- **No auth out of the box**: anyone who can reach port 4567 can edit the wiki. Always put Gollum behind a reverse proxy with authentication in any non-trusted-network scenario.
- **Commits show as "Anonymous"**: configure git user in the container with `-e GIT_AUTHOR_NAME="Wiki Bot" -e GIT_AUTHOR_EMAIL="wiki@example.com"` or Gollum's `--user-icons` setting.
- **PlantUML**: requires an external PlantUML server (`--plantuml-url https://www.plantuml.com/plantuml`) — it does not bundle PlantUML itself.
- **Large wikis and search**: full-text search requires `--full-text-search` and a Solr/SQLite backend — not enabled by default.

## Links

- Upstream README: <https://github.com/gollum/gollum>
- Wiki (full docs): <https://github.com/gollum/gollum/wiki>
- Docker Hub: <https://hub.docker.com/r/gollumwiki/gollum>
- Screenshots: <https://github.com/gollum/gollum/wiki/Screenshots>

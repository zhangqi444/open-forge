---
name: MkDocs
description: Static documentation site generator — Markdown sources + a single YAML config become a browsable HTML site. NOT a long-running service.
---

# MkDocs

> **Heads-up: MkDocs is a static site generator, not a self-hosted service.** There is no daemon to deploy. You run `mkdocs build` to produce a `site/` directory of static HTML, then serve it with any web server (nginx, caddy, Cloudflare Pages, GitHub Pages, etc.). The `mkdocs serve` command exists only as a local development server. The recipe below covers the two self-hosting paths that actually make sense: serve the built site from nginx/caddy, or build it in CI and ship it.

- Upstream repo: <https://github.com/mkdocs/mkdocs>
- Docs: <https://www.mkdocs.org/>
- PyPI: `mkdocs` — `pip install mkdocs`
- Popular theme (separate package): `mkdocs-material` — <https://squidfunk.github.io/mkdocs-material/>

## Compatible install methods

| Goal                             | Approach                                                             | Notes                                                                             |
| -------------------------------- | -------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Local authoring                  | `pip install mkdocs` + `mkdocs serve`                                | Dev server on 127.0.0.1:8000 with live reload                                     |
| Host built docs on your own box  | Build → copy `site/` to any static web server (nginx, caddy, httpd)  | Recommended production path                                                       |
| Host with Docker                 | `squidfunk/mkdocs-material` image, or build in CI → nginx image      | No official "mkdocs-as-a-service" image; Material maintains a build-tool image    |
| GitHub/GitLab hosted             | `mkdocs gh-deploy` or GitLab Pages CI                                | Easiest if you don't want your own server                                         |

## Inputs to collect

| Input                   | Example                         | Phase   | Notes                                                                      |
| ----------------------- | ------------------------------- | ------- | -------------------------------------------------------------------------- |
| Site domain             | `docs.example.com`              | Runtime | Terminate TLS in your reverse proxy, not in MkDocs                         |
| `site_url`              | `https://docs.example.com/`     | Build   | Required in `mkdocs.yml` for correct sitemap + canonical + absolute links  |
| Python version          | 3.9+                            | Build   | MkDocs 1.6+ requires Python 3.9+                                           |
| Theme                   | `material` / `readthedocs` / ...| Build   | Pin theme version alongside MkDocs                                         |
| Plugin set              | `search`, `awesome-pages`, ...  | Build   | Declared in `mkdocs.yml > plugins:`                                        |

## Install via Python + nginx (recommended self-hosting)

On any Linux box with Python 3.9+:

```sh
python3 -m venv venv
. venv/bin/activate
pip install 'mkdocs==1.6.1' 'mkdocs-material==9.5.44'   # pin versions

# New project scaffold (skip if you already have docs/)
mkdocs new mysite
cd mysite

# Build
mkdocs build --strict     # --strict turns warnings into errors; fail CI on dead links
```

`mkdocs build` produces `site/`. Point nginx at it:

```
server {
    listen 80;
    server_name docs.example.com;
    root /srv/docs.example.com/site;
    index index.html;
    location / { try_files $uri $uri/ =404; }
}
```

Redeploy = rebuild `site/` and `rsync` it to the server.

## Install via Docker (build image)

Use the Material-maintained image if you are also using the Material theme; it bundles MkDocs + Material + common plugins.

```sh
docker run --rm -it -v "$PWD":/docs -p 8000:8000 \
  squidfunk/mkdocs-material:9.5.44 serve --dev-addr 0.0.0.0:8000
```

For a build-only step in CI:

```sh
docker run --rm -v "$PWD":/docs squidfunk/mkdocs-material:9.5.44 build --strict
```

Then deploy `site/` via nginx/caddy/S3/whatever. Do **not** run `mkdocs serve` in production — it's a dev server.

## Install via `mkdocs gh-deploy`

If GitHub Pages is acceptable:

```sh
mkdocs gh-deploy --force
```

Builds and pushes `site/` to the `gh-pages` branch. Configure custom domain + TLS in the repo's Pages settings.

## Data & config layout

- `mkdocs.yml` — site metadata, nav, theme, plugins. Check into git.
- `docs/` — Markdown sources (and any assets). Check into git.
- `site/` — build output. **Never** check into git; add to `.gitignore`.
- `overrides/` — theme overrides (Material convention).

## Upgrade

1. Check release notes: <https://github.com/mkdocs/mkdocs/releases>.
2. Bump pinned versions in `requirements.txt` / `pyproject.toml` for both MkDocs and every theme/plugin.
3. `pip install -U -r requirements.txt`
4. `mkdocs build --strict` — the `--strict` flag surfaces deprecated features and broken refs before you ship.
5. Rebuild and redeploy. No DB, no state to migrate.

## Gotchas

- **It's not a server.** Do not expose `mkdocs serve` to the internet — it's single-threaded, has no TLS, no auth, and reloads on file change. Only use it locally.
- **`site_url` is load-bearing.** If you host under a subpath (e.g. `https://example.com/docs/`), set `site_url` accordingly or relative links break.
- **Plugin version skew** is the most common breakage. A MkDocs minor bump can break plugins that haven't kept up. Pin everything; upgrade together.
- **Material theme is a separate package** under a different license (MIT for Material; Material for MkDocs Insiders is sponsor-only). Don't confuse "MkDocs" with "MkDocs Material".
- **Windows line endings in Markdown** can mess up heading anchors; configure git `core.autocrlf=input` in the repo.
- **`mkdocs gh-deploy` force-pushes `gh-pages`.** You will overwrite anything you manually committed there.
- **Search plugin indexes at build time.** If you have a very large site (1000+ pages), the default client-side JS search will be slow; consider `mkdocs-material`'s prebuilt index or an external search like Meilisearch.

## Links

- Docs: <https://www.mkdocs.org/>
- Configuration reference: <https://www.mkdocs.org/user-guide/configuration/>
- Releases: <https://github.com/mkdocs/mkdocs/releases>
- Theme catalog: <https://github.com/mkdocs/catalog>
- Material theme: <https://squidfunk.github.io/mkdocs-material/>
- Material Docker image: <https://hub.docker.com/r/squidfunk/mkdocs-material>

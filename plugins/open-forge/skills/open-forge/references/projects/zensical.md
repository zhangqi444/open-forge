---
name: zensical
description: Recipe for Zensical — a modern static site generator by the creators of Material for MkDocs. Covers Docker (official image) and pip install methods, per upstream README at https://github.com/zensical/zensical and Docker Hub at https://hub.docker.com/r/zensical/zensical.
---

# Zensical

Modern static site generator built by the creators of [Material for MkDocs](https://github.com/squidfunk/mkdocs-material). Write documentation in Markdown and produce a professional, searchable, multilingual (60+ languages) static site. Outputs a self-contained directory — no database or server runtime required to serve the built site. Official site: <https://zensical.org/>. Upstream: <https://github.com/zensical/zensical>.

## Compatible combos

| Method | Runtime | When to use |
|---|---|---|
| Docker image (`zensical/zensical`) | Docker | Dev preview server or CI build — no Python install needed |
| pip (`pip install zensical`) | Python ≥ 3.8 | Local authoring, CI pipelines |
| Hosted static output | Any static host (GitHub Pages, Netlify, Caddy, nginx, S3, etc.) | Serving the _built_ site — Zensical itself only builds, it does not serve |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Where will you serve the built site?" | Static host — Zensical builds to `site/`; hosting is out of scope for this recipe |
| preflight | "Install via Docker or pip?" | Docker requires no Python; pip preferred for local authoring |
| config | "Site name?" | Set as `site_name` in `mkdocs.yml` |
| config | "Site URL?" | Set as `site_url` in `mkdocs.yml`; used in the generated sitemap |

## Software-layer concerns

- **Config file**: `mkdocs.yml` at the project root (same schema as MkDocs). Zensical extends MkDocs — existing `mkdocs.yml` files from Material for MkDocs projects migrate directly.
- **Docs directory**: `docs/` by default (override with `docs_dir:` in `mkdocs.yml`).
- **Build output**: `site/` by default (override with `site_dir:`). The `site/` directory contains a fully self-contained static site — upload it to any static host.
- **Themes**: Zensical ships its own theme. Existing Material for MkDocs themes are compatible via the `material` theme name.
- **Plugins**: MkDocs plugins are compatible; install them into the same Python environment.

## Using the Docker image

Official image: `zensical/zensical`. Tags: `latest`, `major.minor.patch`, `major.minor`, `major`.

### Preview as you write (dev server)

```bash
# Mount the project directory to /docs; Zensical auto-reloads on file changes
docker run --rm -it -p 8000:8000 -v "${PWD}:/docs" zensical/zensical
```

Open http://localhost:8000 to preview the site. The server rebuilds automatically when source files change.

### Build the site

```bash
docker run --rm -it -v "${PWD}:/docs" zensical/zensical build
```

Built output lands in `site/` on the host. No database or ongoing server required to serve the result.

### Specific version

```bash
docker run --rm -it -v "${PWD}:/docs" zensical/zensical:1.0 build
```

## Using pip

```bash
pip install zensical

# Start dev server
zensical serve

# Build
zensical build

# Create a new project
zensical new my-project
```

Add to `requirements.txt` or `pyproject.toml` for reproducible builds:

```
zensical>=1.0
```

## Upgrade procedure

### Docker

Pull the latest (or a specific) tag and re-run:

```bash
docker pull zensical/zensical:latest
docker run --rm -it -v "${PWD}:/docs" zensical/zensical build
```

### pip

```bash
pip install --upgrade zensical
```

Check the changelog at https://zensical.org/about/changelog/ before upgrading across major versions — theme configuration keys may change.

## Gotchas

- **Zensical builds; it does not serve.** The `docker run` dev server is for local preview only. For production, deploy the `site/` output to a static host. Running the container publicly is not the intended use case.
- **MkDocs compatibility.** Zensical is a superset of MkDocs. Existing `mkdocs.yml` files from MkDocs + Material for MkDocs projects work without changes. Pure MkDocs-only projects (no Material theme) may need minor `mkdocs.yml` adjustments.
- **Zensical Spark (commercial tier).** The open-source version is fully functional. Zensical Spark (https://zensical.org/spark/) is a paid subscription for professional/organisational use — it is not required for self-hosting.
- **`site/` should be gitignored.** Add `site/` to `.gitignore`; regenerate from `docs/` in CI rather than committing the build output.
- **Python version.** The Docker image ships the correct Python. For pip installs, Python >= 3.8 is required.

## References

- Upstream README: https://github.com/zensical/zensical
- Docker Hub: https://hub.docker.com/r/zensical/zensical
- Documentation: https://zensical.org/docs/
- Get started: https://zensical.org/docs/get-started/

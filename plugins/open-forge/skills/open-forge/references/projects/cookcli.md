---
name: CookCLI
description: "CLI and web server for Cooklang recipe files. Docker or binary. Rust. cooklang/cookcli. Shopping lists, meal planning, recipe browsing, pantry tracking, UNIX scripting integration."
---

# CookCLI

**Command-line tools and web server for Cooklang recipe files.** Read, display, and manage `.cook` format recipes; generate shopping lists; plan meals with menu files; browse recipes from any device via the built-in web UI; track pantry inventory. Designed for UNIX scripting integration — use with pipes, cron, and shell scripts.

Built + maintained by **cooklang team**. MIT license.

- Upstream repo: <https://github.com/cooklang/cookcli>
- Cooklang format: <https://cooklang.org>
- Demo: <https://demo.cooklang.org>
- GHCR: `ghcr.io/cooklang/cookcli`

## What is Cooklang?

Cooklang is a plain-text markup format for recipes. Ingredients are annotated with `@`, cookware with `#`, and timers with `~`. A `.cook` file is human-readable and git-friendly:

```
Add @onions{1%medium}, diced, and @garlic{2%cloves} to a #pan{}.
Cook for ~{10%minutes} on medium heat.
```

CookCLI is the tool for working with these files.

## Architecture in one minute

- **Rust** binary — fast, portable, single executable
- **Web server mode** — serves a recipe browser UI on port **9080**
- No database — recipes live as `.cook` files in your filesystem
- Docker: single container; mount your recipe directory as `/recipes`
- Resource: **tiny** — Rust binary; near-zero overhead

## Compatible install methods

| Infra        | Runtime                       | Notes                                               |
| ------------ | ----------------------------- | --------------------------------------------------- |
| **Docker**   | `ghcr.io/cooklang/cookcli`    | **Primary** — GHCR; mount recipes dir               |
| **Homebrew** | `brew install cookcli`        | macOS/Linux; for CLI use                            |
| **Binary**   | GitHub Releases               | Single Rust binary; all platforms                   |

## Install via Docker (web server)

```yaml
services:
  cookcli:
    image: ghcr.io/cooklang/cookcli:latest
    ports:
      - "9080:9080"
    volumes:
      - ./recipes:/recipes
    restart: unless-stopped
```

Visit `http://localhost:9080` — browse all your recipes in the web UI.

## CLI usage

```bash
# Seed sample recipes to try
cook seed

# Display a recipe
cook recipe "Neapolitan Pizza.cook"

# Generate a shopping list from multiple recipes
cook shopping-list "Pizza.cook" "Pasta.cook"

# Plan a week (menu file)
cook shopping-list "Weekly Plan.menu"

# Start web server
cook server --port 9080 --path ./recipes

# List all recipes
cook list
```

## Key commands

| Command | Description |
|---------|-------------|
| `cook recipe <file>` | Display a recipe in human-readable format |
| `cook shopping-list <files>` | Generate a shopping list from one or more recipes/menus |
| `cook server` | Start the recipe browser web server |
| `cook list` | List all recipes in the current directory |
| `cook seed` | Populate sample recipes to try |
| `cook report` | Generate reports about your recipe collection |

## Menu files

Cooklang menu files (`.menu`) define meal plans. Reference recipes with `@`, set servings:

```
---
servings: 2
---
==Monday==
Dinner: @./Pasta Carbonara{}
==Tuesday==
Dinner: @./Neapolitan Pizza{}
```

Then `cook shopping-list "Weekly Plan.menu"` generates a consolidated shopping list scaled to your servings.

## Web UI features

- Browse all recipes by name / ingredient / tag
- View individual recipes with scaled ingredient amounts
- Mobile-friendly — accessible from phone while cooking
- No login required (intended for local/LAN use)

## Gotchas

- **File permissions in Docker.** If you mount your recipe directory and see permission errors, the default container user is `1000:1000`. Add `user: "UID:GID"` in the compose (where UID:GID matches your host user) to avoid issues. Run `id -u && id -g` to find your IDs.
- **Plain-text files — no backup needed beyond git.** Your recipes are `.cook` files — just plain text. Keep them in a git repo for version history, sharing, and backup. No database to dump.
- **Web server is read-only.** The web UI displays recipes; it doesn't have an editor. Edit `.cook` files directly in your preferred text editor.
- **Shopping list aggregation.** When generating a shopping list from multiple recipes, CookCLI aggregates ingredients by name and unit. Ingredients with the same name but different units (e.g. `milk{1%cup}` and `milk{200%ml}`) may not merge — normalise your units for best results.
- **Pantry tracking.** CookCLI supports pantry state tracking — mark ingredients as available and subtract them from shopping lists. See the docs for pantry file format.
- **UNIX pipes work great.** `cook shopping-list *.cook | sort | uniq` — combine with standard Unix tools for powerful workflows.

## Backup

Recipes are `.cook` plain-text files — commit to git:

```sh
cd recipes && git init && git add . && git commit -m "my recipes"
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Rust development, GHCR, Homebrew, binary releases (all platforms), demo site. Maintained by cooklang team. MIT license.

## Recipe-management-family comparison

- **CookCLI + Cooklang** — Rust, plain-text `.cook` files, CLI + web UI, shopping lists, meal planning, git-friendly
- **Tandoor Recipes** — Django, full web app with DB, image upload, nutritional info, import from URLs
- **Mealie** — FastAPI+Vue, recipe manager, meal planner, shopping lists, URL import, richer UI
- **Grocy** — PHP, household management including recipes + pantry + shopping; much broader scope

**Choose CookCLI if:** you prefer plain-text recipes in git, want a lightweight CLI + web browser for cooking, and like the UNIX-scripting approach to meal planning and shopping lists.

## Links

- Repo: <https://github.com/cooklang/cookcli>
- Cooklang format: <https://cooklang.org>
- Demo: <https://demo.cooklang.org>
- GHCR: `ghcr.io/cooklang/cookcli`

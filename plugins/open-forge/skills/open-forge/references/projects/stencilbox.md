---
name: stencilbox-project
description: Static site generator that builds data-driven sites from YAML files using templates. Upstream: https://github.com/jamesread/StencilBox
---

# StencilBox

Static site generator that builds data-driven, super-speedy simple static sites from YAML files and sleek templates. Designed for self-hosters who want a fast homepage of links, or sysadmins who want non-technical users to create pages without Git or tooling. Upstream: <https://github.com/jamesread/StencilBox>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | [Installation Guide](https://jamesread.github.io/StencilBox/index.html) | ✅ | Recommended self-hosted install |
| Source / Manual | [GitHub](https://github.com/jamesread/StencilBox) | ✅ | Development or customisation |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | options | All |
| config | Port to expose StencilBox on | number | Docker |
| config | Path to your YAML site configs | path | Docker |

## Docker install

Source: <https://jamesread.github.io/StencilBox/index.html>

Full installation guide and documentation is at the upstream docs site. Docker is the recommended install method.

Key points:
- Supports multiple build configs — multiple sites from a single container.
- Pages are generated as static HTML from YAML data files; no scripts run in the browser.
- Built-in templates: iframe-sidebar, links-homepage, status-page.
- No internet connection required; no telemetry; no premium tier.

## Configuration

- Site definitions are YAML data files mounted into the container.
- Multiple build configs are managed via the admin web interface.
- See [upstream documentation](https://jamesread.github.io/StencilBox/index.html) for full configuration reference.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- No Docker Compose example in the README — refer to the [full docs](https://jamesread.github.io/StencilBox/index.html) for container setup details.
- StencilBox does not support Markdown — it is focused on rendering YAML data into pages.

## References

- Upstream docs: <https://jamesread.github.io/StencilBox/index.html>
- GitHub: <https://github.com/jamesread/StencilBox>

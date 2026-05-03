---
name: docker-php-startpage-project
description: PHP-based browser startpage that runs in Docker, with service status checks and customisable link layouts. Upstream: https://github.com/loganmarchione/docker-php-startpage
---

# docker-php-startpage

Runs a PHP-based startpage in Docker. Everything is server-side PHP — the container performs URL status checks and serves a fast, customisable homepage. Inspired by mafl and starbase-80. Upstream: <https://github.com/loganmarchione/docker-php-startpage>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | [GitHub README](https://github.com/loganmarchione/docker-php-startpage#example-usage) | ✅ | Recommended |
| Docker run | [Docker Hub](https://hub.docker.com/r/loganmarchione/docker-php-startpage) | ✅ | Quick start |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | options | All |
| config | Port to expose the startpage on (default 8888) | number | All |
| config | Path to store user config files | path | All |

## Docker Compose install

Source: <https://github.com/loganmarchione/docker-php-startpage>

```yaml
version: '3'
services:
  startpage:
    container_name: docker-php-startpage
    restart: unless-stopped
    ports:
      - '8888:80'
    volumes:
      - 'user_includes:/var/www/html/user_includes'
    image: loganmarchione/docker-php-startpage:latest

volumes:
  user_includes:
    driver: local
```

## Configuration

| Item | Details |
|---|---|
| Web port | 80 (inside container), expose on host as desired |
| User config volume | `/var/www/html/user_includes` — mount your `config.json` and custom files here |
| Image tags | `latest` or semantic version (e.g. `1.2.3`) |
| Environment variables | None |
| Architectures | linux/amd64, linux/arm64, linux/arm/v7 |

Works out of the box using a sample `config.json`. Mount a volume at `/var/www/html/user_includes` for your own configuration.

See [FEATURES.md](https://github.com/loganmarchione/docker-php-startpage/blob/master/FEATURES.md) for detailed usage.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- The container must be able to reach the URLs you add, since status checks are performed server-side.
- Use a pinned semantic version tag (e.g. `1.2.3`) if you want to avoid unexpected changes from `latest`.

## References

- GitHub: <https://github.com/loganmarchione/docker-php-startpage>
- Docker Hub: <https://hub.docker.com/r/loganmarchione/docker-php-startpage>
- Features doc: <https://github.com/loganmarchione/docker-php-startpage/blob/master/FEATURES.md>

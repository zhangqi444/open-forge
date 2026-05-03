---
name: faridoon-project
description: Self-hosted chat quote board — save and publish favourite chat quotes (inspired by bash.org). Upstream: https://github.com/jamesread/Faridoon
---

# Faridoon

Self-hosted web app for saving and publishing favourite chat quotes for others to see. Inspired by bash.org (now offline). Supports user login/registration with admin and non-admin roles, an approval system for guest submissions, and automatic username highlighting. Upstream: <https://github.com/jamesread/Faridoon>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker + MySQL | [Documentation](https://jamesread.github.io/Faridoon/) | ✅ | Recommended |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Confirm reading upstream docs before proceeding" | info | All |
| config | MySQL database credentials | string | All |
| config | Domain / URL for the install | URL | All |

## Install

Source: <https://jamesread.github.io/Faridoon/>

The recommended install method is Docker connected to a MySQL database. Full documentation (including Docker Compose example) is at the upstream docs site above. Faridoon runs well on 1 vCPU / 1 GB RAM.

## Features

- Automatic highlighting of usernames in quotes
- Semi-intelligent removal of line breaks and weird characters
- User login/registration with admin and non-admin roles
- Approval system for guest and non-admin submissions
- Configuration via environment variables or config file
- No internet connection required; no telemetry; no paywalled features

## Upgrade procedure

Follow upstream documentation. Pull the latest Docker image and restart.

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- No Docker Compose file in the GitHub repository root — see the [docs site](https://jamesread.github.io/Faridoon/) for full setup.
- Project is production-maturity per upstream badge but is independently maintained with no commercial backing.

## References

- Documentation: <https://jamesread.github.io/Faridoon/>
- GitHub: <https://github.com/jamesread/Faridoon>
- Discord: <https://discord.gg/jhYWWpNJ3v>

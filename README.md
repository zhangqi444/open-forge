# open-forge

Self-host open-source apps on your own cloud, guided by Claude Code.

Given a project and a cloud provider, open-forge walks you through provisioning, DNS, TLS, outbound email (SMTP), and inbound email. It captures the non-obvious gotchas that usually cost hours the first time: proxy misconfigurations, non-interactive certbot flags, mail config quirks, DNS propagation, etc.

## Supported today (v0.1)

| Project | Infra | Status |
|---|---|---|
| Ghost | AWS Lightsail (Bitnami blueprint) | ✅ |

More coming.

## Install

In Claude Code:

```
/plugin marketplace add zhangqi444/open-forge
/plugin install open-forge@open-forge
```

## Use

Tell Claude what you want to deploy:

> "I want to self-host Ghost on AWS Lightsail."

The `open-forge` skill will take it from there — collecting inputs, running AWS CLI + SSH commands, guiding you through DNS and SMTP setup, and recording state so you can resume across sessions.

## How it works

- **Phased workflow**: preflight → provision → DNS → TLS → outbound email → inbound email → hardening. Each phase is verifiable and resumable.
- **State file**: `~/.open-forge/deployments/<name>.yaml` records inputs, outputs, and completed phases.
- **Progressive disclosure**: the skill loads only the references it needs for your chosen project + infra combo.
- **Autonomous with `--dry-run`**: runs AWS CLI / SSH directly by default; pass `--dry-run` to print commands without executing.

## Repo layout

```
open-forge/
├── .claude-plugin/marketplace.json     # marketplace manifest
└── plugins/
    └── open-forge/                     # the plugin
        ├── .claude-plugin/plugin.json
        └── skills/open-forge/
            ├── SKILL.md
            ├── references/
            │   ├── projects/           # per-project recipes (ghost.md, ...)
            │   ├── infra/              # per-infra adapters (lightsail.md, ...)
            │   └── modules/            # cross-cutting (dns, tls, smtp, inbound)
            └── scripts/
```

## Contributing

To add a new project: drop a `references/projects/<name>.md` recipe.
To add a new infra: drop a `references/infra/<name>.md` adapter.
See existing files for the expected shape.

## License

MIT

---
name: Self Host Blocks
description: Modular NixOS-based server management system for self-hosting. Standardized module interfaces, best practices baked in, VM-tested service configurations, focused on long-term maintainability.
website: https://github.com/ibizaman/selfhostblocks
source: https://github.com/ibizaman/selfhostblocks
license: GPL-3.0
stars: 455
tags:
  - nixos
  - server-management
  - infrastructure
  - self-hosting
  - devops
platforms:
  - NixOS
---

# Self Host Blocks

Self Host Blocks (SHB) is a NixOS-based server management system for self-hosting services. It provides a collection of NixOS modules with standardized, opinionated interfaces that enforce best practices — making services look and behave consistently. Focused on long-term maintainability over ease of initial installation. All service configurations are verified with NixOS VM tests.

Source: https://github.com/ibizaman/selfhostblocks
Docs: https://ibizaman.github.io/selfhostblocks/
Matrix: #selfhostblocks:matrix.org

Note: Self Host Blocks is **NixOS-only**. It is not Docker- or Ansible-based. If you are not running NixOS, this project is not applicable.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| NixOS server / VPS | NixOS flakes | Required — NixOS only |
| NixOS homelab | NixOS modules | With Skarabox companion for setup |

## Inputs to Collect

**Phase: Planning**
- Existing NixOS configuration (flakes-based)
- Services to deploy (Nextcloud, Jellyfin, Gitea, etc.)
- Domain names for each service
- SSL/TLS strategy (ACME/Let's Encrypt integrated)
- Secret management approach (sops-nix or agenix recommended)

## Software-Layer Concerns

**Add SHB as a flake input:**

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:mic92/sops-nix";
    self-host-blocks.url = "github:ibizaman/selfhostblocks";
  };

  outputs = { self, nixpkgs, sops-nix, self-host-blocks, ... }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      modules = [
        sops-nix.nixosModules.sops
        self-host-blocks.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

**Enable a service (example: Nextcloud):**

```nix
# configuration.nix
{
  shb.nextcloud = {
    enable = true;
    domain = "cloud.example.com";
    subdomain = "cloud";
    ssl = config.shb.certs.certs.letsencrypt."example.com";
    adminPassFile = config.sops.secrets."nextcloud/adminpass".path;
    # ... other options
  };
}
```

**Contracts system:** SHB introduces "contracts" — standardized interfaces between modules. For example, all services accept the same `ssl` contract, the same `backup` contract, etc., so changing a backend (e.g., switching from PostgreSQL to a different DB) requires minimal config changes.

**Secrets management (sops-nix example):**

```nix
{
  sops.secrets."nextcloud/adminpass" = {
    owner = "nextcloud";
  };
}
```

**Services available in SHB** (check docs for current list):
- Nextcloud, Gitea, Forgejo
- Jellyfin, Home Assistant
- Authelia (SSO/OIDC)
- Nginx (reverse proxy, shared by all services)
- Prometheus + Grafana (monitoring)
- Restic (backups)
- And more — see https://ibizaman.github.io/selfhostblocks/

## Upgrade Procedure

1. Update flake inputs: `nix flake update`
2. Review changelog for breaking changes: https://github.com/ibizaman/selfhostblocks/releases
3. Rebuild: `nixos-rebuild switch --flake .#myserver`
4. NixOS's atomic upgrades mean you can roll back with `nixos-rebuild --rollback` if needed

## Gotchas

- **NixOS only**: Self Host Blocks is exclusively for NixOS — not compatible with Debian, Ubuntu, or Docker-based setups
- **Flakes required**: SHB uses Nix flakes; ensure `experimental-features = nix-command flakes` is set
- **Learning curve**: NixOS and flakes have a significant learning curve — not suitable as a first self-hosting project
- **Long-term focus**: SHB prioritizes maintainability over quick setup; initial configuration takes longer but upgrades are more reliable
- **VM tests**: All included service configs are tested with NixOS VM tests — higher confidence than untested Docker compose files
- **Skarabox companion**: The related [Skarabox](https://github.com/ibizaman/skarabox) project provides automated server provisioning to complement SHB

## Links

- Source: https://github.com/ibizaman/selfhostblocks
- Documentation: https://ibizaman.github.io/selfhostblocks/
- Releases: https://github.com/ibizaman/selfhostblocks/releases
- Skarabox (provisioning companion): https://github.com/ibizaman/skarabox
- Matrix chat: #selfhostblocks:matrix.org

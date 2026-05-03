# Kontoj

**What it is:** Web tool to help manage and automate account creation on web services, configured via a JSON file.
**Official URL:** https://kontoj.galaksio.tech
**GitHub:** https://github.com/galaksiotech/kontoj

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker / static web server | Lightweight frontend app |

## Inputs to Collect

### Deploy phase
- Port to expose
- Path to your services.json config file

## Software-Layer Concerns

- **Config:** services.json file defining service list and autofill CSS selectors
- **Data dir:** Minimal; no database
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image and restart. Update services.json as needed.

## Gotchas

- Services list defined entirely in JSON; validate against the provided schema
- Autoload requires placing services.json at the root and configuring config.json
- No user accounts built-in

## References

- [GitHub](https://github.com/galaksiotech/kontoj)

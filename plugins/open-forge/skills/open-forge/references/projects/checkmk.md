---
name: checkmk
description: Checkmk recipe for open-forge. Complete IT monitoring solution for servers, networks, cloud, containers, and applications. Raw Edition is free and fully open-source.
---

# Checkmk

Complete IT monitoring solution covering servers, networks, cloud resources, containers, and applications. Auto-discovers hosts and services. Raw Edition (CRE) is free and fully open-source (GPL). Enterprise and Cloud editions add commercial features and support. Upstream: <https://github.com/Checkmk/checkmk>. Docs: <https://docs.checkmk.com/>.

## Editions

| Edition | License | Notes |
|---|---|---|
| Raw (CRE) | GPL / open-source | Full-featured monitoring; community support |
| Enterprise (CEE) | Commercial | Advanced features, professional support |
| Cloud (CCE) | Commercial | SaaS-optimized, AWS/Azure/GCP integrations |

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (official image) | Quickest start; good for evaluation and small setups |
| DEB/RPM package | Official recommended production install on Linux |
| Checkmk Appliance | Hardware/VM appliance with built-in OS |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Raw (free) or Enterprise (commercial) edition?" | Drives which image/package to use |
| preflight | "Site name?" | Checkmk uses named "sites"; default often `mysite` |
| preflight | "Admin password?" | Set after first container start |

## Docker quickstart (Raw Edition)

```bash
docker run -dit \
  -p 8080:5000 \
  -p 8000:8000 \
  --tmpfs /opt/omd/sites/mysite/tmp:uid=1000,gid=1000 \
  -v monitoring:/omd/sites \
  --name monitoring \
  -h monitoring \
  checkmk/check-mk-raw:latest
```

- UI: http://localhost:8080/mysite
- Default admin username: `cmkadmin`
- Get initial password: `docker logs monitoring 2>&1 | grep "cmkadmin"`

Full Docker guide: <https://docs.checkmk.com/latest/en/introduction_docker.html>

## Monitoring agents

Checkmk uses lightweight agents on monitored hosts:

```bash
# On each monitored Linux host — install the Checkmk agent
# Download from Checkmk UI: Setup → Agents → Linux
wget http://<checkmk-host>:8080/mysite/check_mk/agents/check-mk-agent_<version>_all.deb
dpkg -i check-mk-agent_*.deb
```

## Software-layer concerns

- Port `5000` (mapped to 8080 in example): Checkmk web UI
- Port `8000`: agent receiver (push monitoring); used by agent v2+
- Volume `/omd/sites` — persist this; contains all site data (config, RRD graphs, history)
- `--tmpfs` mount for `/tmp` is required for performance
- Checkmk supports SNMP, TCP checks, cloud APIs, Docker, Kubernetes monitoring — all without agents for network devices
- Auto-discovery: Checkmk scans hosts and auto-creates service checks

## Upgrade procedure

1. Pull new image: `docker pull checkmk/check-mk-raw:latest`
2. Stop and remove old container (data persists in volume)
3. Start new container with same volume and port bindings
4. Checkmk applies site updates automatically on start

Full upgrade guide: <https://docs.checkmk.com/latest/en/update.html>

## Gotchas

- `--tmpfs` mount is **required** — without it, performance degrades significantly
- Volume path `/omd/sites` (not the container path `/opt/omd/sites`) is what must be persisted
- Each monitored host needs the Checkmk agent installed (or SNMP configured for network devices)
- Raw Edition uses Nagios core; Enterprise uses CMC (Checkmk Microcore) for better performance at scale
- Container hostname (`-h monitoring`) should match the site name for proper internal routing

## Links

- GitHub: <https://github.com/Checkmk/checkmk>
- Docker intro: <https://docs.checkmk.com/latest/en/introduction_docker.html>
- Full docs: <https://docs.checkmk.com/>
- Docker Hub: <https://hub.docker.com/r/checkmk/check-mk-raw>

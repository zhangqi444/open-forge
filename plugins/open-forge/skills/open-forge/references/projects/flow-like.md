# Flow-Like

**Rust-powered visual workflow automation engine — drag-and-drop blocks, fully typed data lineage, runs locally on laptop/phone/server with no cloud dependency required.**
Official site: https://flow-like.com
GitHub: https://github.com/TM9657/flow-like
Docs: https://docs.flow-like.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| macOS / Windows / Linux | Desktop App | Primary deployment method |
| Any | Web App | https://app.flow-like.com (hosted) |
| Any Linux | Build from source | Rust + Bun + Node required |

---

## Inputs to Collect

### Desktop App
- Download from: https://flow-like.com/download
- No server-side config needed for local use

### Self-hosted / From Source
- Rust toolchain (latest stable)
- Bun + Node.js
- mise (toolchain manager, optional)

---

## Software-Layer Concerns

### Quick start (desktop)
Download and install from https://flow-like.com/download — available for macOS, Windows, Linux.

### Build from source
```bash
git clone https://github.com/TM9657/flow-like
cd flow-like
mise trust && mise install   # install Rust, Bun, Node, Python, uv
bun install                  # install Node packages
# follow docs for build steps
```

### SDKs
- Node.js/TypeScript: npm install @flow-like/sdk
- Additional languages: see docs

### Performance
- Rust engine: ~244,000 workflows/sec, ~0.6ms latency per workflow
- Runs on resource-constrained devices (phones, edge hardware, Raspberry Pi)

### Features
- 900+ built-in nodes: APIs, databases, file processing (Excel/CSV/PDF), AI/LLM, messaging, IoT
- Full data lineage and audit trails — every input/output recorded
- Local LLM support (download and run models locally)
- MCP server integration

---

## Upgrade Procedure

- Desktop: auto-updates or re-download from https://flow-like.com/download
- From source: git pull, rebuild

---

## Gotchas

- Primary UX is the desktop app — self-hosting the backend separately requires building from source
- Fully offline-capable; no internet required for local workflow execution
- AI workflow nodes can use local or cloud models — configure per node
- License: check repo (FOSSA badge in README)
- Mobile app is listed as "coming soon"

---

## References
- Download: https://flow-like.com/download
- Documentation: https://docs.flow-like.com
- GitHub: https://github.com/TM9657/flow-like#readme

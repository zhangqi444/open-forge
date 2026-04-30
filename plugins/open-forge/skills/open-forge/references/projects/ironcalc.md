---
name: IronCalc
description: "Modern in-browser spreadsheet engine — Rust-based xlsx-compatible spreadsheet (engine + xlsx reader/writer + WASM for browser). Work-in-progress ecosystem: embeddable in Python/JS/Node, with different UI ‘skins' (web, terminal, desktop planned). Apache-2.0 + MIT dual-licensed."
---

# IronCalc

IronCalc is **"a modern spreadsheet engine, not just another spreadsheet UI"** — a **Rust-based** spreadsheet core that reads + writes **xlsx** files, runs formulas, and is **embeddable from multiple languages** (Python, JavaScript via WebAssembly, Node.js, with R / Julia / Go planned). The project ships a **web UI skin** (the self-hostable spreadsheet in a browser) and plans **terminal + desktop skins**. The pitch: **"build the best spreadsheet engine, then put whatever UI you want on top."** Open-source alternative to Excel-the-engine (not necessarily Excel-the-app), plus an embeddable library for developers who need spreadsheet-compute in their own apps.

Built + maintained by **IronCalc org** — small core team + community. **Apache-2.0 + MIT** dual-licensed (pick your preferred). Active development; upstream is **explicit: "new, modern, work-in-progress"** — not yet feature-parity with Excel / LibreOffice Calc, but genuinely usable + rapidly improving.

Use cases: (a) **self-hosted web spreadsheet** (privacy vs Google Sheets / Excel Online) (b) **embeddable spreadsheet compute** in your SaaS/tool (Python data-ops, JS business-rules-engine, Node back-end calc) (c) **xlsx reader/writer for automation** (read + compute without launching Excel / LibreOffice) (d) **browser-side compute** via WASM without a server round-trip (e) **new-project greenfield** where you want modern Rust foundations over legacy C++ (LibreOffice) or cloud-only (Google Sheets).

Components:

- **Core engine** (Rust) — formulas, dependency graph, recalc
- **xlsx reader/writer** — interop with Excel files
- **WASM bindings** — run in browser
- **Python bindings** — import-as-library
- **JS/Node bindings** — same
- **Web UI skin** (the spreadsheet you can self-host)
- **Desktop app** (planned)
- **Terminal skin** (planned)

- Upstream repo: <https://github.com/ironcalc/IronCalc>
- Crate docs: <https://docs.rs/ironcalc>
- Discord: <https://discord.gg/zZYWfh3RHJ>
- Code coverage: <https://codecov.io/gh/ironcalc/IronCalc>
- Actions (build/test): <https://github.com/ironcalc/IronCalc/actions>
- `LICENSE-MIT`: <https://github.com/ironcalc/IronCalc/blob/main/LICENSE-MIT>
- `LICENSE-Apache-2.0`: <https://github.com/ironcalc/IronCalc/blob/main/LICENSE-Apache-2.0>

## Architecture in one minute

- **Rust** core — pure compute engine; no I/O dependencies at the library level
- **WASM compile target** for browser embedding
- **Optional web UI** Rust-backed service + frontend for self-host
- **Resource**: small — Rust binary fits easily in a modest container
- **Port 2080** in the reference docker-compose

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker Compose     | **Upstream `docker compose up --build`**                        | **Primary path for self-host web skin**                                            |
| `cargo build`      | Native Rust build                                                         | For library / dev use                                                                      |
| `pip install` (when published)                              | Python bindings                                                                      | For embedding                                                                                          |
| npm (WASM) / npmjs.org                                      | JS embedding                                                                                      | For embedding                                                                                                       |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Port                 | `2080`                                                      | Network      | Default in upstream compose                                                                                    |
| TLS reverse proxy    | Per your infra                                                          | Network      | For non-localhost access                                                                                    |
| Persistence (if any) | Check current version                                                                    | Storage      | Spreadsheet save/load behavior depends on UI skin; check upstream                                                                                           |
| Embedding language   | Rust / Python / JS / Node                                                                                  | Dev          | Pick the binding matching your host app                                                                                              |

## Install (self-host web UI) via Docker

Per upstream:
```sh
git clone https://github.com/ironcalc/IronCalc.git
cd IronCalc
docker compose up --build
# → http://localhost:2080
```

Pin a specific git tag or image version for production once you pick one.

Library / embedding paths:
- Rust: `cargo add ironcalc` (check crate availability)
- Python: via PyPI (once published) or build from source
- JS (WASM): upstream npm package or build from source

## First boot

1. `docker compose up --build` → browse `http://localhost:2080`
2. Create a sheet → enter formulas → test
3. Import xlsx file → verify round-trip
4. Export → open in Excel/LibreOffice → verify compatibility
5. For embedding: pick binding (Python/JS/Rust) → follow per-language guide
6. For self-host in prod: TLS reverse proxy + auth layer (**no native auth in web skin today — add reverse-proxy auth**)

## Data & config layout

- **Depends on skin + version**. Current web-UI skin is primarily engine-demonstration; persistent multi-user spreadsheet storage is a roadmap item — verify in current docs.
- **xlsx files** — read/write interop format
- **In-memory state** — current working sheet lives in process memory

## Backup

- **xlsx export** is the portable format — export your critical spreadsheets periodically
- **If using as library** — spreadsheets live in your host app's storage; back up that
- **No dedicated persistence layer to back up** in the current web skin — save xlsx out

## Upgrade

1. Releases: <https://github.com/ironcalc/IronCalc/releases>. **Active + WIP — breaking changes possible.**
2. READ RELEASE NOTES — formula-function additions/fixes + engine-behavior changes.
3. For library use: pin version; test upgrade paths.
4. For web skin: rebuild Docker compose.

## Gotchas

- **"Work-in-progress" — take it seriously.** Upstream is explicit: this is a new project. Feature parity with Excel / LibreOffice / Google Sheets is incomplete. Known-limitation areas likely include:
  - **Formula coverage** — many functions supported, not all 400+ Excel functions yet
  - **Chart support** — likely limited / not-yet in web skin
  - **Pivot tables** — complex feature; check current state
  - **Macros / VBA** — not planned (intentional — security + scope)
  - **Advanced formatting** — conditional formatting may be partial
  - **Collaborative editing** — check; likely roadmap
  - **Same "transparent-status" family** as Dim (batch 84 slowing), Wakapi (81 PRs closed), pad-ws (85 dev-only). **6th tool** in the transparent-maintenance-mode family. Respect the signal. Use for non-critical workflows; pilot on small data first.
- **xlsx round-trip fidelity varies** — reading/writing xlsx is a massive spec; IronCalc's implementation will have edge cases. **Round-trip test your actual files** (open in IronCalc → save → re-open in Excel) before committing to IronCalc as primary tool.
- **Apache-2.0 + MIT dual-license** — ultra-permissive. You can use IronCalc in commercial / closed-source / redistributed products without reciprocity obligations. Rare quality in the modern OSS landscape (where AGPL + BSL are dominant for new projects). **Use this rarity.** Same permissive-license-as-ecosystem-asset framing as Caddy, Redis-pre-license-change, Grafana-pre-AGPL.
- **Security surface for self-host web skin**: today, IronCalc web skin is engine-demonstration quality — **no built-in auth, minimal hardening**. Expose behind reverse proxy + auth (Authelia, Authentik, basic-auth) if deploying for team use. Don't put directly on the public internet. Check upstream for auth/multi-user roadmap before assuming current state.
- **Embedding-focused design → evaluate for YOUR integration**: IronCalc's real selling point is "embeddable engine in any language" — evaluate the binding ergonomics for your stack. Rust + WASM + Python are most-mature; Node / JS works; R / Julia / Go are aspirational per upstream.
- **Formula-engine quality** is the most critical dimension to evaluate. Test with your actual spreadsheets:
  - Financial formulas (NPV, IRR, PMT)
  - Lookup (VLOOKUP, XLOOKUP, INDEX/MATCH)
  - Array formulas + dynamic arrays
  - Date / time functions (worldwide edge cases)
  - Text functions (REGEX if you depend on it)
- **Work-in-progress + active community**: Discord is active; file issues for missing functions. Upstream is **responsive to real use cases** — contributing a formula or a bug report is valued.
- **Browser-WASM performance**: the WASM build makes in-browser compute possible (no server round-trip for every formula). For latency-sensitive dashboards + calculators in web apps, this is a killer feature vs server-side spreadsheet services.
- **No cloud-sync / collaborative editing** as a first-class feature today — if you need Google-Sheets-style multi-cursor real-time editing, IronCalc is not there yet. Track roadmap or contribute.
- **Developer audience**: IronCalc is a developer-first project right now. End-users looking for "Excel I can self-host" today should evaluate **LibreOffice Calc** (desktop) or **OnlyOffice / Collabora** (server-side collaborative with Nextcloud integration) first. Revisit IronCalc in 12-24 months for end-user-ready status.
- **Project health**: small core + active Rust codebase + Discord + Apache/MIT + transparent WIP status + steady commit cadence. Low-but-non-zero bus-factor; permissive license = forkable if it ever stalls. **Worth tracking.**
- **Alternatives worth knowing:**
  - **LibreOffice Calc** — mature desktop spreadsheet; ODS native + xlsx interop; no easy embed
  - **OnlyOffice Docs** — server-side collaborative spreadsheet (AGPL) + Nextcloud integration
  - **Collabora Online** — LibreOffice-based server collab
  - **Luckysheet** / **Univer** — JS/TS in-browser spreadsheet libraries
  - **Handsontable** — JS library (dual-licensed; commercial for most orgs)
  - **AG Grid** — grid component, not full spreadsheet
  - **Google Sheets / Excel Online** — commercial cloud
  - **Choose IronCalc if:** you want embeddable Rust-based modern engine + permissive license + willing to ride WIP.
  - **Choose OnlyOffice / Collabora if:** you want collaborative server-side end-user-ready today.
  - **Choose Handsontable / Luckysheet / Univer if:** you want JS-library-in-webpage scope.
  - **Choose LibreOffice Calc if:** you want desktop-first mature Excel-alternative.

## Links

- Repo: <https://github.com/ironcalc/IronCalc>
- Crate (Rust): <https://docs.rs/ironcalc>
- Discord: <https://discord.gg/zZYWfh3RHJ>
- Code coverage: <https://codecov.io/gh/ironcalc/IronCalc>
- Apache-2.0 license: <https://github.com/ironcalc/IronCalc/blob/main/LICENSE-Apache-2.0>
- MIT license: <https://github.com/ironcalc/IronCalc/blob/main/LICENSE-MIT>
- LibreOffice Calc (alt, desktop): <https://www.libreoffice.org/discover/calc/>
- OnlyOffice (alt, collab): <https://www.onlyoffice.com>
- Collabora Online (alt, collab): <https://www.collaboraonline.com>
- Luckysheet (alt, JS lib): <https://github.com/dream-num/Luckysheet>
- Univer (alt, JS lib): <https://github.com/dream-num/univer>
- Handsontable (alt, JS lib, commercial): <https://handsontable.com>

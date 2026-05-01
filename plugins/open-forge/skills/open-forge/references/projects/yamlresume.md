---
name: YAMLResume
description: "Manage and version-control your resume in YAML; generate professional LaTeX-typeset PDFs. Node.js + Docker + GitHub Action. yamlresume/yamlresume. 10 languages, 8 fonts, pixel-perfect output."
---

# YAMLResume

**Write your resume in YAML, generate pixel-perfect PDFs.** YAMLResume is a LaTeX-based typesetting engine: define resume content in human-readable YAML; the tool renders it into a beautiful, professionally typeset PDF. Version-control your resume like code, swap layouts without rewriting content, and automate PDF generation via CLI, Docker, or GitHub Action.

Spun out from [PPResume](https://ppresume.com) as open source to avoid vendor lock-in. MIT license (source code).

- Upstream repo: <https://github.com/yamlresume/yamlresume>
- Docs: <https://yamlresume.dev>
- Docker Hub: <https://hub.docker.com/r/yamlresume/yamlresume>
- npm: `yamlresume`
- GitHub Action: <https://github.com/marketplace/actions/yamlresume>
- Discord: <https://discord.gg/9SyT7mVV4K>
- PPResume (hosted SaaS): <https://ppresume.com>

## Architecture in one minute

- **TypeScript / Node.js** CLI (`yamlresume` command)
- Calls **LaTeX** (pdflatex or xelatex) to generate PDFs — LaTeX must be available
- Docker image bundles Node.js + LaTeX + all dependencies (easiest for clean PDF generation)
- GitHub Action available for CI/CD PDF generation
- Output: PDF (primary); can also output LaTeX source for further customization
- Resource: **low to medium** — Node.js process + LaTeX compilation (LaTeX install is ~1–3 GB)

## Compatible install methods

| Method          | Command                                         | Notes                                                              |
| --------------- | ----------------------------------------------- | ------------------------------------------------------------------ |
| **Docker**      | `docker run yamlresume/yamlresume`              | **Easiest** — bundles LaTeX; one command to PDF                    |
| **npm**         | `npm install -g yamlresume`                     | Requires local LaTeX installation (TeX Live / MiKTeX)             |
| **GitHub Action** | see marketplace                               | Automated PDF generation in CI/CD                                  |
| **PPResume SaaS** | ppresume.com                                  | Web GUI for YAMLResume; no local install needed                    |

## Quick start with Docker

```bash
# Initialize a sample resume
docker run --rm -v $(pwd):/workdir yamlresume/yamlresume init my-resume.yaml

# Generate PDF
docker run --rm -v $(pwd):/workdir yamlresume/yamlresume compile my-resume.yaml

# Output: my-resume.pdf in current directory
```

## Quick start with npm

```bash
# Install (requires LaTeX: https://www.latex-project.org/get/)
npm install -g yamlresume

# Initialize sample resume
yamlresume init my-resume.yaml

# Generate PDF
yamlresume compile my-resume.yaml

# Preview in watch mode (re-compiles on save)
yamlresume compile --watch my-resume.yaml
```

## YAML schema (excerpt)

```yaml
# my-resume.yaml
meta:
  language: en
  layout:
    font: "NewComputerModernSans"   # choose from 8 fonts
    font_size: 11pt
    paper_size: a4paper

basics:
  name: "Jane Doe"
  email: "jane@example.com"
  phone: "+1 (555) 000-0000"
  location:
    city: "San Francisco"
    country: "USA"

education:
  - institution: "MIT"
    degree: "B.S. Computer Science"
    start_date: "2018-09"
    end_date: "2022-06"

work:
  - company: "Acme Corp"
    title: "Software Engineer"
    start_date: "2022-07"
    end_date: "present"
    highlights:
      - "Built a distributed system serving 10M requests/day"
      - "Reduced latency by 40% through caching optimizations"

skills:
  - category: "Languages"
    keywords: ["Python", "TypeScript", "Go", "Rust"]
```

Full schema reference: <https://yamlresume.dev/docs/content>

## GitHub Action (automated PDF generation)

```yaml
# .github/workflows/resume.yml
name: Generate Resume PDF
on:
  push:
    paths: ['resume.yaml']

jobs:
  compile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: yamlresume/action@v1
        with:
          input: resume.yaml
          output: resume.pdf
      - uses: actions/upload-artifact@v4
        with:
          name: resume-pdf
          path: resume.pdf
```

## Supported languages (10)

English, French, German, Spanish, Portuguese, Bahasa Indonesia, Japanese, Simplified Chinese, Traditional Chinese — and more. Locale-aware formatting (dates, phone numbers, addresses).

## Supported fonts (8)

Choose LaTeX fonts per layout: New Computer Modern, New Computer Modern Sans, Latin Modern, Latin Modern Sans, Palatino, Helvetica, Times, Computer Modern. Each renders differently — preview at yamlresume.dev.

## Gotchas

- **LaTeX is a 1–3 GB install.** If using npm directly, you need a local TeX Live (Linux/macOS) or MiKTeX (Windows) installation. The Docker image bundles it — use Docker to avoid setup friction.
- **Compilation time.** LaTeX is slow — expect 5–30 seconds per PDF compilation. Watch mode (npm CLI `--watch`) helps during editing.
- **Japanese/Chinese/Korean CJK fonts.** LaTeX CJK support requires additional font packages. The Docker image bundles `texlive-lang-cjk` for CJK support. npm install on a minimal TeX Live may need extra packages.
- **YAML → PDF, not docx or HTML.** Output is PDF (via LaTeX). There's no Word doc or HTML output — it's a typesetter, not a universal resume tool.
- **Version control your `.yaml` file.** This is the entire point — your resume is a text file. `git diff resume.yaml` shows exactly what changed. Tag releases by job application date.
- **PPResume SaaS** for those who don't want CLI. The hosted version at ppresume.com provides a web editor for the same YAML schema with live PDF preview — without installing anything. The CLI is for those who want full control.
- **No template marketplace yet.** Layout options are controlled by the built-in font/spacing/margin settings. Community templates may come via the ecosystem as the project grows.
- **GitHub Action pinning.** Pin to a specific version (`yamlresume/action@v1.2.3`) in production CI to prevent surprise breakage from upstream updates.

## Project health

Active TypeScript development, Docker Hub, npm, GitHub Action, 10 languages, CI, Discord, PPResume commercial backing, blog posts. MIT source code license.

## Resume-as-code-family comparison

- **YAMLResume** — YAML → LaTeX → PDF, Node.js/Docker/GH Action, 10 languages, 8 fonts, pixel-perfect
- **JSON Resume** — JSON schema standard; many community renderers; less opinionated output
- **Overleaf** — web LaTeX editor; not YAML-driven; manual layout
- **Reactive Resume** — full web app, drag-and-drop visual editor; self-hostable; no YAML
- **HackMyResume** — FRESH/JRS schema; CLI; unmaintained

**Choose YAMLResume if:** you want to version-control your resume as YAML and generate pixel-perfect LaTeX-typeset PDFs via CLI, Docker, or GitHub Action — with multilingual support.

## Links

- Repo: <https://github.com/yamlresume/yamlresume>
- Docs: <https://yamlresume.dev>
- Docker Hub: <https://hub.docker.com/r/yamlresume/yamlresume>
- npm: <https://www.npmjs.com/package/yamlresume>
- GitHub Action: <https://github.com/marketplace/actions/yamlresume>
- PPResume (web UI): <https://ppresume.com>

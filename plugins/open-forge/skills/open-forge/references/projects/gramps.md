---
name: Gramps
description: "Open-source desktop genealogy software. Python/GTK. Sources, citations, place + date tools, narrative web export, map integration. Decades-old project (~2001). GPL. Active; Weblate translations. Companion: Gramps Web (API + web frontend)."
---

# Gramps

Gramps (Genealogical Research and Analysis Management Programming System) is **"the gold-standard open-source genealogy program"** — used by hobbyist + professional genealogists for decades. Python + GTK desktop app. Full research features: individuals, families, events, places, sources, citations, repositories, notes, tags, media. Exports to GEDCOM + narrative website HTML + many formats. Map integration via osm-gps-map. Graphs via Graphviz. Translations via Weblate to 30+ languages. Companion project **Gramps Web** adds REST API + web frontend for collaborative use.

Built + maintained by **The Gramps Project** + decades-long community. License: **GPL** (COPYING file). Active; GitHub Actions CI + codecov + Weblate translations; gramps60 maintenance branch. First released around 2001 → one of the longest-running OSS genealogy tools.

Use cases: (a) **family tree researcher** — professional or hobbyist genealogy work (b) **family history website export** — narrative web feature produces static HTML (c) **replace Ancestry.com / MyHeritage subscription** for offline research (d) **academic genealogy research** — sources + citations + repositories all tracked (e) **GEDCOM workflow** — import/export between tools (f) **collaborative family research** via Gramps Web (g) **long-term family-archive** — data format documented + open (h) **privacy-conscious genealogy** — your ancestry data stays YOUR data.

Features (per README):

- **Individuals, families, events, places, sources, citations, repositories, notes, tags, media**
- **GEDCOM 5.5 import/export**
- **Narrative website** generator (HTML/CSS + photos + family graphs)
- **Geography category** via osm-gps-map
- **Graphs** via Graphviz
- **Reports** (PDF, HTML, custom)
- **Multi-language** (Weblate 30+ languages)
- **PyICU localized sorting**
- **SQLite backend**
- **Plugin system**

- Upstream repo: <https://github.com/gramps-project/gramps>
- Website: <https://gramps-project.org>
- Wiki: <https://gramps-project.org/wiki>
- Gramps Web: <https://github.com/gramps-project/Gramps-Web-API>
- Weblate: <https://hosted.weblate.org/engage/gramps-project>

## Architecture in one minute

- **Python 3.10+** + **GTK 3.24+** (desktop)
- **SQLite** — primary DB (BSDDB also historical)
- **Gramps Web** companion = REST API + React frontend
- **Resource**: moderate — 300-800MB RAM for Python/GTK desktop
- **Desktop-first** — web access via Gramps Web

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Desktop**: apt / dnf / brew / Windows / macOS installers | Packages available | **Primary user base**                                                                        |
| **Gramps Web**     | **Docker — API + frontend**                                     | **For web/collaborative use**                                                                        |
| Source build       | Python + GTK dependencies                                                                    | DIY                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| GEDCOM source data   | Existing genealogy files                                    | Import       | Round-trip testing recommended                                                                                    |
| DB path              | `~/.gramps/grampsdb/`                                       | Storage      |                                                                                    |
| Media dir            | Photos + scans + documents                                  | Storage      | Can be LARGE                                                                                    |
| (For Gramps Web): domain + TLS | Public access                                                                           | URL          |                                                                                    |

## Install via package manager (desktop)

```sh
# Ubuntu/Debian
sudo apt install gramps
# Fedora
sudo dnf install gramps
# macOS (Homebrew)
brew install --cask gramps
# Arch
sudo pacman -S gramps
```

## Gramps Web (for self-hosted web access)

```sh
# See https://github.com/gramps-project/Gramps-Web-API
docker compose up -d
# Access via configured domain
```

## First boot

1. Install desktop app OR deploy Gramps Web via Docker
2. Create new database
3. Import GEDCOM (if existing)
4. Add individuals, events, sources, media
5. Link citations to claims (best practice)
6. Generate first report / narrative website
7. Back up regularly (Gramps → Tools → Archive)

## Data & config layout

- `~/.gramps/grampsdb/<tree>/` — SQLite DB
- Media stored by-reference in media dir OR in DB
- `~/.gramps/plugins/` — installed plugins
- Addon downloads stored locally

## Backup

```sh
# Within Gramps: File → Archive this Family Tree
# Creates a .gramps file (XML + media)

# Or manual:
sudo tar czf gramps-$(date +%F).tgz ~/.gramps/
```

## Upgrade

1. Releases: <https://github.com/gramps-project/gramps/releases>. Active.
2. Package manager: `apt upgrade gramps` / `dnf upgrade gramps`
3. **BACKUP BEFORE MAJOR VERSION UPGRADES** — Gramps occasionally does DB migrations
4. Test upgrade path with a copy of your tree before committing

## Gotchas

- **GENEALOGY DATA = REGULATORY-SENSITIVE + EMOTIONALLY-CHARGED**:
  - Family data includes: names, dates-of-birth, places, relationships, photos, scanned legal docs
  - **LIVING INDIVIDUALS**: privacy laws (GDPR, CCPA) protect living persons' personal data
  - **Sensitive claims**: adoptions, illegitimate births, criminal records, medical histories — often documented in genealogy
  - **NEW sub-family: "genealogy-personal-history-risk"** under hub-of-credentials — 1st tool (Gramps)
  - **68th tool in hub-of-credentials family — Tier 2 with "living-person-privacy" + "sensitive-family-history" density**
- **LIVING-PERSON PRIVACY IN NARRATIVE-WEB EXPORTS**:
  - Narrative website default can include LIVING individuals' full data
  - **MUST CONFIGURE**: Living people → omit OR mask OR redact (Gramps has "Alive" filter)
  - Publishing living-person data = GDPR violation (in EU) + potential identity-theft-enablement
  - **Recipe convention: "living-person-privacy-in-exports" callout** — MANDATORY pre-publish filter
  - **NEW recipe convention** — critical for genealogy tools
- **ANCESTRY-DNA / 23ANDME DATA IMPORT**:
  - Some genealogists import DNA-match data
  - DNA data = genetic-information = regulated (GINA in US, GDPR Art.9 in EU)
  - **Don't upload DNA data to cloud-shared trees without explicit match-consent**
- **ADOPTION / ILLEGITIMATE-BIRTH / PATERNITY-UNCERTAINTY**:
  - Research often uncovers sensitive information
  - Publishing these findings without living-descendants' consent = harm potential
  - **Recipe convention: "genealogical-discovery-ethics" callout**
- **LONG-LIVED SOFTWARE (~2001)**:
  - One of oldest OSS genealogy tools
  - Mature, stable, tested
  - **Recipe convention: "two-decade-OSS-project" positive-signal** — exceptional longevity
  - **NEW positive-signal** (Gramps 1st explicitly named)
- **DESKTOP-FIRST ≠ DEFAULT-WEB**:
  - Gramps desktop is the primary UX
  - Gramps Web is separate project for web/collab
  - **Recipe convention: "desktop-primary-tool with web-companion" architecture note**
- **GEDCOM = LINGUA FRANCA**:
  - GEDCOM 5.5 is the industry-standard genealogy format
  - Gramps supports import/export
  - **Recipe convention: "open-standard-format-support" positive-signal** (OxiCloud 100 WebDAV precedent)
- **NARRATIVE WEB = STATIC SITE GENERATION**:
  - Gramps generates HTML website from family tree
  - Deploy to any static host (Cloudflare Pages, GitHub Pages, etc.)
  - Links out to LittleLink-adjacent deployment patterns (LittleLink 103)
- **MAP INTEGRATION = osm-gps-map**:
  - OpenStreetMap-based map rendering
  - Optional; if missing, Geography category inactive
  - **Recipe convention: "map-tile-provider" sub-convention** applies (AdventureLog 98 precedent)
- **GRAPHVIZ DEPENDENCY**:
  - Several reports require Graphviz
  - Without it: 3 reports unavailable
  - Modern install typically bundles
- **MULTI-LANGUAGE + WEBLATE**:
  - Weblate = open translation platform
  - Community contributes translations
  - **Recipe convention: "Weblate-community-translations" positive-signal** — infrastructure for localization
- **LARGE MEDIA DIRS**:
  - Genealogy often includes scanned documents, photos, birth certificates, census pages
  - Media can be TBs
  - Gramps stores by-reference; back up media dir separately + alongside DB
- **PLUGIN SYSTEM**:
  - Third-party plugins available
  - **Security caveat**: untrusted plugins = code execution; review before installing
  - **Recipe convention: "plugin-system-trust-boundary" callout**
  - **NEW recipe convention**
- **HOBBYIST-PROFESSIONAL SPAN**:
  - Simple-enough for hobbyist beginners
  - Feature-complete enough for professionals
  - Rare in open-source tools (often one or the other)
  - **Recipe convention: "hobbyist-and-professional-usability-span" positive-signal**
- **INSTITUTIONAL-STEWARDSHIP**: The Gramps Project org + decades-community + Weblate + codecov + CI. **54th tool — large-community-project sub-tier** (**NEW sub-tier**) — distinct from sole-maintainer-with-community because Gramps has a PROJECT-wide governance structure.
  - **NEW sub-tier: "large-community-project with project-governance"** — 1st tool named (Gramps)
- **TRANSPARENT-MAINTENANCE**: active + CI + codecov + Weblate + 2001-origin + maintenance branches + wiki + YouTube + Blog + multiple GitHub repos. **62nd tool in transparent-maintenance family.**
- **OPEN-FILE-FORMAT = DATA-PORTABILITY**:
  - Gramps XML format is documented
  - GEDCOM for cross-tool interop
  - **Recipe convention: "zero-lock-in" applies** (Flatnotes 101 + Basic Memory 102 precedents) — **3rd tool in zero-lock-in pattern**
- **GENEALOGY-CATEGORY (crowded):**
  - **Gramps** — OSS desktop + Gramps Web
  - **Family Historian** — commercial Windows
  - **Family Tree Maker** — commercial
  - **Ancestry.com** — commercial SaaS
  - **MyHeritage** — commercial SaaS
  - **WebTrees** — PHP web-based OSS
  - **RootsMagic** — commercial Windows/Mac
  - **GeneWeb** — OSS CGI
  - **TreeSoup** — newer OSS
- **ALTERNATIVES WORTH KNOWING:**
  - **WebTrees** — if you want PHP web-based (mature)
  - **Gramps Web** — for web collaboration on Gramps data
  - **Ancestry.com / MyHeritage** (commercial) — if you want DNA matching + broad source coverage
  - **Choose Gramps if:** you want desktop-first + OSS + decades-proven + open-format + optional-web.
  - **Choose WebTrees if:** you want web-first + PHP.
- **PROJECT HEALTH**: decades-active + large-community + CI + Weblate + maintenance branches + multiple projects. EXCELLENT signals — long-lived OSS tool.

## Links

- Repo: <https://github.com/gramps-project/gramps>
- Website: <https://gramps-project.org>
- Wiki: <https://gramps-project.org/wiki>
- Gramps Web: <https://github.com/gramps-project/Gramps-Web-API>
- Weblate: <https://hosted.weblate.org/engage/gramps-project>
- WebTrees (alt): <https://webtrees.net>
- GeneWeb (alt): <https://geneweb.tuxfamily.org>
- GEDCOM spec: <https://www.familysearch.org/developers/docs/guides/gedcom>
- Ancestry.com (commercial alt): <https://www.ancestry.com>
- MyHeritage (commercial alt): <https://www.myheritage.com>

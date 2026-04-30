---
name: SonarQube
description: Static code-analysis platform — detects bugs, vulnerabilities, security hotspots, code smells across 30+ languages. Quality Gates enforce "new code" standards in CI. Community Edition is free OSS; Developer/Enterprise/Data Center editions are commercial. Java + Elasticsearch + Postgres. LGPL-3.0 (CE) / commercial.
---

# SonarQube

SonarQube is the canonical static-code-analysis platform. Point it at your codebase (directly or via CI), and it reports **bugs, security vulnerabilities, security hotspots, and code smells** across 30+ programming languages. Paired with "Quality Gates," it enforces code-quality standards on every pull request — "don't merge if coverage drops / new bugs / new security findings."

Target audience: professional engineering teams that want quality standards enforced in CI/CD.

- **Community Edition** (free, LGPL-3.0, this repo) — basic analysis + Quality Gates for most mainstream languages
- **Developer Edition** (commercial) — adds PR decoration, branch analysis, more languages (C/C++/Obj-C/Swift)
- **Enterprise Edition** — portfolio management, executive dashboards, more
- **Data Center Edition** — HA clustering, largest scale

Noteworthy update: **SonarQube 10.x (2023+)** introduced "Clean Code" framing, "Quality Gates on new code," and stronger AI-generated-code assurance badges.

- Upstream repo: <https://github.com/SonarSource/sonarqube>
- Website: <https://www.sonarsource.com/products/sonarqube>
- Docs: <https://docs.sonarsource.com/sonarqube>
- Download: <https://www.sonarsource.com/products/sonarqube/downloads>
- Community: <https://community.sonarsource.com>
- Docker Hub: <https://hub.docker.com/_/sonarqube>
- Next (preview of upcoming version): <https://next.sonarqube.com/sonarqube>

## Architecture in one minute

- **SonarQube server** — Java; web app + compute engine (analyzes results); Elasticsearch embedded (or external)
- **PostgreSQL** (required for prod; SonarQube 8+ dropped MySQL/Oracle/MSSQL support for CE)
- **Scanner** — CLI tools (`sonar-scanner`, Maven/Gradle plugins, MSBuild, .NET CLI) — run in CI, send results to server
- **Ports**: `9000` web UI, `9092` (Elasticsearch, internal)

Minimum RAM: **3 GB** for the SonarQube process + Elasticsearch. 8 GB of host RAM is a practical minimum for prod.

Linux-only production (macOS + Windows supported for dev).

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                                  |
| ----------- | ------------------------------------------------ | ---------------------------------------------------------------------- |
| Single VM   | Docker (`sonarqube:<edition>-community`)           | **Most common**                                                          |
| Single VM   | Docker Compose (Sonar + Postgres)                    | Upstream-documented                                                      |
| Kubernetes  | **Official Helm chart**                                | <https://SonarSource.github.io/helm-chart-sonarqube>                       |
| Single VM   | ZIP distribution + `sonar.sh start`                    | For bare-VM / systemd deploys                                              |
| Managed     | **SonarCloud** (hosted; <https://sonarcloud.io>)         | Free for public repos; paid for private                                     |

## Inputs to collect

| Input                     | Example                               | Phase     | Notes                                                             |
| ------------------------- | ------------------------------------- | --------- | ----------------------------------------------------------------- |
| Postgres host/user/pw     | external or bundled                    | DB        | **Required** — SQLite/HSQLDB removed since SQ 7.9                   |
| Java heap                 | `-Xmx2g` for web + `-Xmx1g` CE          | Resource  | Via `SONAR_WEB_JAVAOPTS`, `SONAR_CE_JAVAOPTS`                        |
| Data volumes              | `/opt/sonarqube/data` + `logs` + `extensions` | Storage | Elasticsearch index + plugins                                      |
| Admin user                | created on first boot                   | Bootstrap | **Default `admin`/`admin`** — CHANGE ON FIRST LOGIN              |
| `SONAR_HOST_URL`          | `https://sonar.example.com`             | URL       | For scanners + OAuth redirects                                        |
| Reverse proxy             | required for TLS                         | Network   | Default listener is plain HTTP                                         |
| `vm.max_map_count`        | `524288` (kernel setting)                | Host OS   | Elasticsearch requires this; set on host                                  |
| `fs.file-max`             | `131072`                                 | Host OS   | Required by Elasticsearch                                                |

## Install via Docker Compose (CE + Postgres)

```yaml
services:
  sonarqube:
    image: sonarqube:10.x.x-community     # pin; check Docker Hub
    container_name: sonarqube
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://postgres:5432/sonarqube
      SONAR_JDBC_USERNAME: sonarqube
      SONAR_JDBC_PASSWORD: <strong>
      SONAR_WEB_JAVAOPTS: "-Xmx2g -Xms1g"
    volumes:
      - sonarqube-data:/opt/sonarqube/data
      - sonarqube-logs:/opt/sonarqube/logs
      - sonarqube-extensions:/opt/sonarqube/extensions
    ulimits:
      nofile:
        soft: 131072
        hard: 131072
      nproc:
        soft: 8192
        hard: 8192

  postgres:
    image: postgres:17
    container_name: sonarqube-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: sonarqube
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: sonarqube
    volumes:
      - sonarqube-pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sonarqube"]
      interval: 10s
      retries: 5

volumes:
  sonarqube-data:
  sonarqube-logs:
  sonarqube-extensions:
  sonarqube-pg:
```

### Host kernel prereq (CRITICAL)

On the Docker host BEFORE starting:

```sh
# Persistent
echo 'vm.max_map_count=524288' | sudo tee /etc/sysctl.d/99-sonarqube.conf
echo 'fs.file-max=131072' | sudo tee -a /etc/sysctl.d/99-sonarqube.conf
sudo sysctl --system

# Or temporary
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
```

Elasticsearch refuses to start without these; SonarQube exits.

## First boot

1. Browse `http://<host>:9000`
2. Log in with **`admin` / `admin`** — **FORCED to change password immediately**
3. Create your first project:
   - Manually → pick a name + key → get a scanner token
4. Configure scanner in your CI (Jenkins/GitLab CI/GitHub Actions/Bitbucket Pipelines — plenty of docs)
5. Run first scan → wait a few minutes → dashboard populates

### Scanner example (CLI)

```sh
# Install sonar-scanner
curl -o sonar-scanner.zip -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.x.zip
unzip sonar-scanner.zip

# From your project root
sonar-scanner \
  -Dsonar.projectKey=my-project \
  -Dsonar.sources=src \
  -Dsonar.host.url=https://sonar.example.com \
  -Dsonar.login=<token-from-server>
```

## Data & config layout

- `/opt/sonarqube/data/` — **Elasticsearch index** (very large; the bulk of data volume)
- `/opt/sonarqube/logs/` — server logs + access + web + compute-engine logs
- `/opt/sonarqube/extensions/plugins/` — optional plugins (drop JAR files; CE has few; more in commercial editions)
- **PostgreSQL DB** — project metadata, issue history, user config

## Backup

```sh
# Postgres is the source of truth
docker compose exec -T postgres pg_dump -U sonarqube sonarqube | gzip > sonarqube-db-$(date +%F).sql.gz

# Volumes (Elasticsearch is recoverable from DB; extensions should be backed up)
docker run --rm -v sonarqube-extensions:/src -v "$PWD":/backup alpine \
  tar czf /backup/sonarqube-extensions-$(date +%F).tgz -C /src .
```

**Elasticsearch index can be rebuilt from Postgres** via SQ's reindex feature; don't panic if you lose `data/` volume. DB is critical.

## Upgrade

1. Releases: <https://github.com/SonarSource/sonarqube/releases> AND <https://docs.sonarsource.com/sonarqube/latest/server-upgrade-and-maintenance/upgrade/>.
2. **Upgrade path matters** — some versions require stepping through intermediate releases. Consult [upgrade matrix](https://docs.sonarsource.com/sonarqube/latest/server-upgrade-and-maintenance/upgrade/).
3. Back up Postgres FIRST.
4. `docker compose pull` → `docker compose up -d`.
5. Browse `http://<host>:9000/setup` → SonarQube runs migrations; click "Migrate."
6. **LTS (Long-Term Support) versions** are a safer prod target than bleeding-edge.

## Gotchas

- **`vm.max_map_count=524288` and `fs.file-max=131072`** on the host — non-negotiable for Elasticsearch. Most "SonarQube won't start" issues in Docker are this.
- **Default credentials `admin`/`admin`** — server refuses to accept logins until changed. Still — change immediately, don't leave at default even briefly if internet-exposed.
- **Postgres is mandatory** since SQ 7.9. MySQL/Oracle/MSSQL were dropped. SQLite/HSQLDB also gone. You MUST run Postgres.
- **Java heap sizing**: `SONAR_WEB_JAVAOPTS=-Xmx2g` for the web process + `SONAR_CE_JAVAOPTS=-Xmx1g` for Compute Engine + ES uses ~1 GB. **Plan for 4-6 GB of RAM** for a small install. Enterprise installs with multiple projects: 8-16 GB.
- **Elasticsearch lifecycle**: SonarQube embeds its own ES; don't point at an external ES cluster (not supported).
- **Scan results can be HUGE** — a large codebase analyzed daily generates GBs in Elasticsearch. Plan storage accordingly.
- **CE language coverage** is strong for most (Java, Kotlin, JS, TS, Python, Ruby, Go, PHP, HTML, CSS, C#, VB.NET, Scala, Apex). **NOT in CE**: C, C++, Obj-C, Swift, ABAP, COBOL, T-SQL, PL/SQL — those require Developer Edition or higher.
- **Branch analysis + PR decoration** are commercial-only (Developer Edition+). CE only analyzes the "main" branch.
- **Quality Gates** in CE are limited to fixed/default gates; custom per-project gates start at Developer Edition.
- **SonarLint** (the IDE plugin) is free + pairs with SonarQube for in-editor linting using your server's rules.
- **SonarCloud** (hosted SaaS) is free for public GitHub/GitLab/Bitbucket repos — very popular for OSS projects; no self-hosting needed.
- **Plugin ecosystem** (JARs dropped in `extensions/plugins/`) adds language support + integrations (e.g., community C++ analyzer, Terraform, Ansible). Community plugins are a mixed bag of quality.
- **LGPL-3.0** for Community Edition — you can use in commercial products; modifications to SonarQube itself must be GPL-compatible.
- **Data Center Edition (HA)** is commercial-only. For CE HA, you'd need application-level load balancing, which upstream explicitly doesn't support.
- **SonarQube is heavy** compared to tools like ESLint / Ruff / Semgrep. For many teams, a targeted Semgrep + language-specific linters are faster to onboard than SonarQube's "all languages" approach.
- **CI integration** is the normal path — scanner runs in GitHub Actions / GitLab CI / Jenkins → pushes to SonarQube → Quality Gate sets PR status.
- **Alternatives worth knowing:**
  - **Semgrep** — lightweight, rule-based, open-source; strong for security patterns
  - **Qodana (JetBrains)** — commercial, integrated with IntelliJ; freemium self-host
  - **DeepSource** — SaaS; modern UX
  - **CodeQL (GitHub)** — deep semantic analysis; free for OSS; part of GitHub
  - **Snyk Code** — SaaS; good for security
  - **ReviewDog + linters** — OSS duct tape; pick linters per language
  - **Coverity** (commercial, Synopsys) — enterprise deep analysis
  - **Fortify / Veracode / Checkmarx** — enterprise AST
  - **Choose SonarQube if:** you want breadth of language support + polished dashboard + Quality Gate model + you're OK with the Java footprint.

## Links

- Repo: <https://github.com/SonarSource/sonarqube>
- Website: <https://www.sonarsource.com/products/sonarqube>
- Docs: <https://docs.sonarsource.com/sonarqube>
- Install docs: <https://docs.sonarsource.com/sonarqube/latest/setup-and-upgrade/install-the-server/>
- Docker image: <https://hub.docker.com/_/sonarqube>
- Releases: <https://github.com/SonarSource/sonarqube/releases>
- Upgrade guide: <https://docs.sonarsource.com/sonarqube/latest/server-upgrade-and-maintenance/upgrade/>
- Helm chart: <https://SonarSource.github.io/helm-chart-sonarqube>
- Editions comparison: <https://www.sonarsource.com/plans-and-pricing/sonarqube/>
- SonarCloud (hosted): <https://sonarcloud.io>
- SonarLint (IDE plugin): <https://www.sonarsource.com/products/sonarlint/>
- Community forum: <https://community.sonarsource.com>
- Next (preview): <https://next.sonarqube.com/sonarqube>

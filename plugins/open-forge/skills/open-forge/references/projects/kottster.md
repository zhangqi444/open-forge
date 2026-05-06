---
name: kottster
description: Kottster recipe for open-forge. Low-code admin panel builder that connects to your database and auto-generates pages to view and manage data. Node.js app, supports PostgreSQL/MySQL/SQLite. Deploy via npx CLI or Docker. Source: https://github.com/kottster/kottster
---

# Kottster

Low-code admin panel that connects to your database and automatically generates pages to view and manage data in your tables. Lets you compose dashboards, build custom pages with forms and charts, and manage data without writing a custom admin UI. Built on Node.js; supports PostgreSQL, MySQL, and SQLite. Deploy with a single npx command or via Docker. Upstream: https://github.com/kottster/kottster. Docs: https://kottster.app/docs/. Demo: https://demo.kottster.app.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| npx CLI (new project) | Linux / macOS / Windows | Recommended. Scaffolds a Node.js project. |
| Docker | Linux | See Docker quickstart docs |
| npm / node | Linux / macOS / Windows | Run the scaffolded project as a regular Node.js app |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| init | "Project name / directory?" | Name for the admin panel project folder |
| db | "Database type?" | PostgreSQL, MySQL, or SQLite |
| db | "Database connection string?" | e.g. postgresql://user:pass@host:5432/dbname |
| auth | "Admin account?" | Created via the web UI on first run |
| deploy | "Port?" | Default: 5480 |

## Software-layer concerns

### Method 1: Create a new project via CLI (recommended)

  # Prerequisites: Node.js v20+
  npx @kottster/cli@latest new

  # Follow the prompts to:
  # - Name your project
  # - Choose your database (PostgreSQL / MySQL / SQLite)
  # - Set the connection string

  # This scaffolds a Node.js project directory.

### Run in development mode

  cd your-project-name
  npm run dev
  # Access at: http://localhost:5480

### Run in production mode

  npm run build
  npm start
  # Or: NODE_ENV=production node dist/server.js

### Docker

  # See: https://kottster.app/docs/quickstart-docker
  # The Docker quickstart spins up a container from the kottster image
  # with your database connection passed as environment variables.

  docker run -d \
    --name kottster \
    -p 5480:5480 \
    -e DATABASE_URL="postgresql://user:pass@host:5432/dbname" \
    kottster/kottster:latest

### Environment variables

  DATABASE_URL    Database connection string (PostgreSQL/MySQL/SQLite)
  PORT            Web server port (default: 5480)
  NODE_ENV        production or development

### Key files (scaffolded project)

  kottster.config.js   # App config: DB connection, pages, nav
  src/                 # Custom pages and components (if any)
  dist/                # Built output (after npm run build)

### Ports

  5480/tcp   # Web UI (default)

### Reverse proxy (nginx)

  location / {
      proxy_pass http://127.0.0.1:5480;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
  }

## Upgrade procedure

  # Update the kottster packages in your project:
  npm update @kottster/server @kottster/cli
  npm run build
  # Restart the service

## Gotchas

- **Node.js v20+ required**: the CLI and server require Node.js v20 or later. Check with `node --version`.
- **Project is a Node.js app**: unlike tools that are just a Docker image, Kottster scaffolds a Node.js project that you own and commit to version control. Customizations go in `src/`.
- **Not a SaaS**: Kottster is fully self-hosted. Your database credentials never leave your server.
- **Account created on first run**: navigate to the web UI after starting for the first time to create your admin account.
- **Database access**: Kottster reads and writes directly to your database. Scope its database user to only the tables/schemas needed for the admin panel.
- **Custom pages**: beyond auto-generated table pages, you can build fully custom React-based pages for dashboards, charts, and forms.

## References

- Upstream GitHub: https://github.com/kottster/kottster
- Documentation: https://kottster.app/docs/
- Docker quickstart: https://kottster.app/docs/quickstart-docker
- Deploying: https://kottster.app/docs/deploying
- Demo: https://demo.kottster.app

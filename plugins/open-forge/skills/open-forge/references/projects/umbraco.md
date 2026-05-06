---
name: umbraco
description: Umbraco CMS recipe for open-forge. Friendly open-source .NET CMS. Covers dotnet CLI install (recommended), Docker, and Azure/hosting options. Upstream: https://github.com/umbraco/Umbraco-CMS
---

# Umbraco

Friendly open-source .NET CMS. Easy to use, highly extensible, with a large community. Powers everything from personal blogs to enterprise websites. Built on ASP.NET Core.

5,168 stars · MIT

Upstream: https://github.com/umbraco/Umbraco-CMS
Website: https://umbraco.com/
Docs: https://docs.umbraco.com/
Install guide: https://docs.umbraco.com/umbraco-cms/fundamentals/setup/install/

## What it is

Umbraco provides a full CMS platform on .NET:

- **Content management** — Tree-based content structure with flexible document types
- **Document types** — Custom content types with configurable property editors
- **Media library** — Image, file, and video management with folders
- **Members** — Frontend user accounts (not the same as backoffice users)
- **Multilingual** — Built-in multi-language / dictionary support
- **Backoffice UI** — Clean Angular-based admin dashboard
- **Examine search** — Built-in full-text search (Lucene-based)
- **Package ecosystem** — Community packages at https://marketplace.umbraco.com/
- **Headless** — Content Delivery API (REST) for headless/hybrid use
- **Cloud option** — Umbraco Cloud (managed hosting)

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| `dotnet new` CLI (recommended) | https://docs.umbraco.com/umbraco-cms/fundamentals/setup/install/install-umbraco-with-templates | Any .NET-capable server |
| Visual Studio template | https://docs.umbraco.com/umbraco-cms/fundamentals/setup/install/visual-studio | Windows development |
| Docker | https://docs.umbraco.com/umbraco-cms/fundamentals/setup/install/running-umbraco-on-linux-macos | Containerized deploy |

## Requirements

- .NET 9 SDK (or .NET 8 LTS for Umbraco 13 LTS)
- SQLite (bundled, dev), SQL Server, MySQL 8+, or PostgreSQL 12+
- 1 GB RAM minimum; 2 GB recommended
- .NET SDK install: https://dot.net/

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| site_name | "Project/site name?" | All |
| db | "Database: SQLite (dev), SQL Server, MySQL, or PostgreSQL?" | All |
| domain | "Domain for production?" | Production |

## dotnet CLI install (recommended)

Upstream: https://docs.umbraco.com/umbraco-cms/fundamentals/setup/install/install-umbraco-with-templates

### 1. Install .NET SDK

    # Ubuntu/Debian
    wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
    chmod +x dotnet-install.sh
    ./dotnet-install.sh --channel 9.0

    # Or via Microsoft package repo:
    apt install -y dotnet-sdk-9.0

### 2. Install Umbraco templates

    dotnet new install Umbraco.Templates

### 3. Create the project

    dotnet new umbraco -n MyWebsite
    cd MyWebsite

This creates a standard ASP.NET Core project with Umbraco configured.

### 4. Run the site

    dotnet run

Open http://localhost:5000 — you'll see the Umbraco installer.

### 5. Complete the installer

In the web browser:
1. Set admin username, email, and password
2. Choose database (SQLite for dev, configure connection string for production)
3. Wait for database initialization (~30 seconds)

Access the backoffice at http://localhost:5000/umbraco

### 6. Publish and run as a service

    dotnet publish -c Release -o /var/www/mywebsite
    cd /var/www/mywebsite
    dotnet MyWebsite.dll

Or via systemd:

    cat > /etc/systemd/system/umbraco.service << 'SVCEOF'
    [Unit]
    Description=Umbraco CMS
    After=network.target

    [Service]
    WorkingDirectory=/var/www/mywebsite
    ExecStart=/usr/bin/dotnet /var/www/mywebsite/MyWebsite.dll
    Restart=on-failure
    RestartSec=10
    Environment=ASPNETCORE_ENVIRONMENT=Production
    Environment=ASPNETCORE_URLS=http://localhost:5000

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    systemctl daemon-reload
    systemctl enable --now umbraco

### 7. Reverse proxy (Nginx)

    server {
        listen 443 ssl;
        server_name mywebsite.com;

        location / {
            proxy_pass http://localhost:5000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection keep-alive;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

## Database configuration (production)

For production, use SQL Server, MySQL, or PostgreSQL. Configure in `appsettings.json`:

    {
      "ConnectionStrings": {
        "umbracoDbDSN": "Server=localhost;Database=umbraco;User Id=umbraco;Password=yourpassword;",
        "umbracoDbDSN_ProviderName": "Microsoft.Data.SqlClient"
      }
    }

For MySQL/PostgreSQL, install the appropriate NuGet package:

    # MySQL
    dotnet add package Umbraco.Cms.Persistence.MySql

    # PostgreSQL
    dotnet add package Umbraco.Cms.Persistence.Sqlite
    # (Actually: Umbraco.Cms.Persistence.Npgsql)

Configure the provider in `Program.cs`:
    builder.CreateUmbracoBuilder()
        .AddBackOffice()
        .AddWebsite()
        .AddComposers()
        .AddMySql()   // or .AddPostgres()
        .Build();

## Docker

    FROM mcr.microsoft.com/dotnet/aspnet:9.0
    WORKDIR /app
    COPY --from=publish /app/publish .
    EXPOSE 8080
    ENTRYPOINT ["dotnet", "MyWebsite.dll"]

Full Docker guide: https://docs.umbraco.com/umbraco-cms/fundamentals/setup/install/running-umbraco-on-linux-macos

## Upgrade

    dotnet add package Umbraco.Cms --version <new-version>
    dotnet run

Umbraco applies database migrations automatically on startup. Back up your database before upgrading major versions.

## Gotchas

- **.NET required** — Umbraco is a .NET ASP.NET Core app. You need the .NET runtime on the server. This makes it heavier than PHP CMSes but brings strong type safety and performance.
- **SQLite for dev only** — SQLite works for development and tiny sites. Use SQL Server, MySQL, or PostgreSQL for production.
- **Backoffice URL is `/umbraco`** — The admin panel is always at `/umbraco`. Protect it at the network/reverse proxy level if needed.
- **LTS vs current** — Umbraco 13 is the current LTS (.NET 8). Umbraco 14+ is the latest with .NET 9. Choose LTS for production stability.
- **Media files** — By default, media files are stored in `wwwroot/media/`. Configure Azure Blob Storage or S3 for scalable/CDN-backed media storage in production.
- **MIT license** — Fully permissive; use commercially without restrictions.

## Links

- GitHub: https://github.com/umbraco/Umbraco-CMS
- Website: https://umbraco.com/
- Docs: https://docs.umbraco.com/
- Install guide: https://docs.umbraco.com/umbraco-cms/fundamentals/setup/install/
- Templates install: https://docs.umbraco.com/umbraco-cms/fundamentals/setup/install/install-umbraco-with-templates
- Package marketplace: https://marketplace.umbraco.com/
- Our.Umbraco community: https://our.umbraco.com/

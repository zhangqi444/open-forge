---
name: ZenTao
description: Open-source Agile (Scrum/Waterfall/Kanban) project management system covering product, project, QA, and documentation management. Built by EasySoft in PHP. Licensed under AGPL-3.0 / ZPL.
website: https://www.zentao.pm/
source: https://github.com/easysoft/zentaopms
license: AGPL-3.0
stars: 1594
tags:
  - project-management
  - scrum
  - agile
  - kanban
platforms:
  - PHP
  - Docker
---

# ZenTao

ZenTao is a comprehensive project management platform combining Scrum, Waterfall, and Kanban methodologies. It covers the full software development lifecycle: product management, project planning, QA/bug tracking, documentation, and DevOps integrations. Originally developed in China (2009), it's now used globally.

Official site: https://www.zentao.pm/  
Source: https://github.com/easysoft/zentaopms  
Docs: https://www.zentao.pm/book/

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker + MySQL | Recommended; official docker-compose provided |
| Any Linux VM / VPS | PHP 7.4+ / 8.x + MySQL | Native install |
| Kubernetes | Docker image | Helm chart available from EasySoft |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname for ZenTao
- MySQL root password (`MYSQL_ROOT_PASSWORD`)
- MySQL database name (default: `zentao`)
- Port to expose (default: `8080`)
- Data volume path for ZenTao data
- Data volume path for MySQL data

**Phase: First Boot**
- Admin username and password (set via web installer on first login)
- Application timezone

## Software-Layer Concerns

**Docker Compose (recommended):**
```yaml
version: '2'
networks:
  zentao-net:
    driver: bridge

services:
  zentao-mysql:
    image: mysql:5.7
    container_name: zentao-mysql
    volumes:
      - zentao_db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=CHANGE_ME
      - MYSQL_DATABASE=zentao
    networks:
      - zentao-net

  zentao:
    image: easysoft/zentao:latest
    container_name: zentao
    ports:
      - '8080:80'
    volumes:
      - zentao_data:/data
    depends_on:
      - zentao-mysql
    environment:
      - MYSQL_HOST=zentao-mysql
      - MYSQL_PORT=3306
      - MYSQL_USER=root
      - MYSQL_PASSWORD=CHANGE_ME
      - MYSQL_DB=zentao
    networks:
      - zentao-net

volumes:
  zentao_db:
  zentao_data:
```

**Config paths:**
- App data: `/data` inside container
- MySQL data: `/var/lib/mysql` inside MySQL container

**Environment variables:**
- `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`

**Ports:**
- `80` inside container → map to `8080` (or your preferred port) on host

## Upgrade Procedure

1. Pull the latest image: `docker pull easysoft/zentao:latest`
2. Stop and remove the old container: `docker-compose down`
3. Start with new image: `docker-compose up -d`
4. ZenTao applies DB migrations automatically on first start after upgrade
5. Check release notes at https://www.zentao.pm/blog/ for breaking changes

## Gotchas

- **Editions**: ZenTao Open Source (free, AGPL), ZenTao Biz, and ZenTao Max (commercial) exist — ensure you're using the open source image
- **MySQL 5.7**: Official docker-compose uses MySQL 5.7; MySQL 8.x works but may require `default-authentication-plugin=mysql_native_password`
- **PHP install**: Native install requires PHP 7.4+ with extensions: pdo_mysql, json, xml, gd, curl, mbstring, zip
- **ZPL license**: The dual AGPL-3.0/ZPL license may have implications for commercial use — review https://www.zentao.pm/dynamic/zentaopms-license-1007.html
- **Chinese-origin**: UI available in English and Chinese; documentation is primarily in Chinese but English translations exist

## Links

- Upstream README: https://github.com/easysoft/zentaopms/blob/master/README.md
- Installation guide: https://www.zentao.pm/book/zentaopms/install-78.html
- Docker image: https://hub.docker.com/r/easysoft/zentao
- Docker-compose repo: https://github.com/easysoft/docker-zentao

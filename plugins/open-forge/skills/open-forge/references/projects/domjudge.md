---
name: domjudge
description: DOMJudge recipe for open-forge. Programming contest judging system used at ICPC and IOI events, supporting automated judge submission, sandboxed execution, and a web interface for teams and jury. Source: https://github.com/DOMjudge/domjudge
---

# DOMJudge

Programming contest judging system supporting ICPC-style and IOI-style (partial scoring) contests. Features automated submission judging, sandboxed code execution, team/jury/admin web interfaces, and balloon tracking. Used at ICPC World Finals and regional contests. Upstream: https://github.com/DOMjudge/domjudge. Docs: https://www.domjudge.org/documentation.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker (domserver + judgehost) | Docker | Recommended for most deployments. Official images on Docker Hub. |
| Package install | Debian/Ubuntu | .deb packages available from domjudge.org. |
| Source build | Linux | For development or customization. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Public URL for DOMJudge?" | e.g. https://judge.example.com — needed for team registration links |
| setup | "MySQL/MariaDB credentials?" | domserver uses a database; set in .env or docker run vars |
| setup | "Number of judgehosts?" | Each judgehost runs submissions. More = higher concurrency. |
| contest | "Contest name, start time, duration?" | Configured in web admin after setup |

## Software-layer concerns

### Docker deployment (recommended)

DOMJudge consists of two components:
- **domserver**: web interface, jury, database connection, submission queue
- **judgehost**: executes and evaluates submitted code in a sandbox (cgroup-isolated)

Docker Hub images: https://hub.docker.com/r/domjudge/domserver and https://hub.docker.com/r/domjudge/judgehost

#### Start domserver

  # 1. Start a MariaDB container
  docker run -d \
    --name dj-mariadb \
    -e MYSQL_ROOT_PASSWORD=rootpw \
    -e MYSQL_USER=domjudge \
    -e MYSQL_PASSWORD=djpw \
    -e MYSQL_DATABASE=domjudge \
    mariadb --max-connections=1000 --max-allowed-packet=512M

  # 2. Start domserver
  docker run -d \
    --name domserver \
    --link dj-mariadb:mariadb \
    -p 80:80 \
    -e MYSQL_HOST=mariadb \
    -e MYSQL_USER=domjudge \
    -e MYSQL_PASSWORD=djpw \
    -e MYSQL_DATABASE=domjudge \
    -e MYSQL_ROOT_PASSWORD=rootpw \
    domjudge/domserver:latest

  # 3. Get admin password from logs:
  docker logs domserver 2>&1 | grep "admin password"

#### Start judgehost(s)

  # Judgehosts need privileged access for cgroup sandboxing
  docker run -d \
    --name judgehost-0 \
    --privileged \
    --hostname judgehost-0 \
    -e DOMSERVER_BASEURL=http://domserver/ \
    -e JUDGEDAEMON_USERNAME=judgehost \
    -e JUDGEDAEMON_PASSWORD=<judgehost-password-from-admin-ui> \
    --link domserver:domserver \
    domjudge/judgehost:latest

  # Get judgehost credentials: Admin UI > Users > judgehost account

#### cgroup requirement

Judgehosts require cgroup v1 or v2 mounted. On modern kernels:
  # cgroup v2 (most modern systems)
  # Add to kernel cmdline: systemd.unified_cgroup_hierarchy=1
  # Or for v1: cgroup_enable=memory swapaccount=1

### Key post-setup steps

1. Log in to http://<host>/jury as admin
2. Add contest, problems, teams, and accounts
3. Verify judgehosts appear in jury > judgehosts and are active
4. Upload problem packages (DOMJudge problem format or ICPC format)

## Upgrade procedure

  docker pull domjudge/domserver:latest
  docker pull domjudge/judgehost:latest
  docker stop domserver judgehost-* && docker rm domserver judgehost-*
  # Re-run with same DB credentials
  # DB migrations run automatically on startup

## Gotchas

- **Privileged judgehosts**: --privileged is required for cgroup-based sandbox isolation. Do not run judgehosts on the same machine as untrusted users.
- **cgroup setup**: if judging fails with cgroup errors, check that cgroups are properly mounted. The judgehost container's entrypoint checks and warns.
- **judgehost password**: retrieve from domserver admin UI after first boot (Users > judgehost). Required before starting judgehosts.
- **Problem package format**: uses its own format or compatible ICPC polygon packages. Verify problem statements and answer keys before contest start.
- **Balloon tracking**: built-in, but requires a dedicated balloon runner process (included in the container).
- **Production vs dev compose**: the repo's docker-compose.yml is explicitly for development (uses contributor image). Use the separate domjudge/domserver and domjudge/judgehost images for production.
- **Firewall**: only port 80/443 on domserver needs to be public. Judgehosts connect outbound to domserver; keep them on a private network.

## References

- Upstream GitHub: https://github.com/DOMjudge/domjudge
- Documentation: https://www.domjudge.org/documentation
- domserver Docker Hub: https://hub.docker.com/r/domjudge/domserver
- judgehost Docker Hub: https://hub.docker.com/r/domjudge/judgehost
- ICPC problem format: https://icpc.io/problem-package-format/

---
name: jenkins
description: Recipe for Jenkins — leading open-source automation server for CI/CD.
---

# Jenkins

The leading open-source automation server, providing 2,000+ plugins to automate virtually any build, test, and deployment workflow. Written in Java. Two release lines: Weekly (latest features) and LTS (stability-focused). Upstream: <https://github.com/jenkinsci/jenkins>. Docs: <https://www.jenkins.io/doc/>. License: MIT. ~23K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/jenkins/jenkins> | Yes | Recommended for containerized deployments |
| Docker Compose | <https://www.jenkins.io/doc/book/installing/docker/> | Yes | Compose-based with Docker-in-Docker for builds |
| Linux packages (apt/yum) | <https://www.jenkins.io/download/> | Yes | Bare-metal or VM installs (Debian/Ubuntu/RHEL/Fedora) |
| WAR file | <https://www.jenkins.io/download/> | Yes | Any platform with JRE 17+ |
| Helm chart | <https://artifacthub.io/packages/helm/jenkinsci/jenkins> | Yes | Kubernetes deployments |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for Jenkins UI? | Port number (default 8080) | All |
| infra | Host data directory for Jenkins home? | Absolute path | Docker |
| software | Number of build executor threads? | Integer (default 2; use 0 on controller in prod) | Tuning |
| software | Jenkins timezone? | TZ string | Optional |

## Software-layer concerns

### Docker (simplest)

```bash
docker run -d \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins \
  --restart unless-stopped \
  jenkins/jenkins:lts-jdk21
```

Port 8080 is the Web UI. Port 50000 is for inbound build agents (JNLP) — only needed if using remote agents.

### Linux (Debian/Ubuntu) package install

```bash
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update && sudo apt install jenkins
sudo systemctl enable --now jenkins
```

Requires Java 21: `sudo apt install fontconfig openjdk-21-jre`

### Key environment variables

| Variable | Description |
|---|---|
| JENKINS_HOME | Data directory (default /var/jenkins_home in Docker) |
| JENKINS_OPTS | Extra CLI flags (e.g. --prefix=/jenkins for subpath hosting) |
| JAVA_OPTS | JVM tuning (e.g. -Xmx2g) |
| JENKINS_SLAVE_AGENT_PORT | Port for inbound agents (default 50000) |

### First-run setup

Jenkins prints an unlock password to stdout on first run:
```bash
docker logs jenkins | grep -A 2 "initial admin password"
```

Visit http://your-host:8080, paste the password, install suggested plugins, create admin user.

## Upgrade procedure

```bash
# Docker
docker pull jenkins/jenkins:lts-jdk21
docker compose up -d

# Linux package
sudo apt update && sudo apt upgrade jenkins
sudo systemctl restart jenkins
```

Before major upgrades, back up JENKINS_HOME and review the LTS upgrade guide at https://www.jenkins.io/changelog-stable/

## Gotchas

- Run executors on agents, not controller: set controller executor count to 0 in production. Running builds on the controller is a security and stability risk.
- Java version: Jenkins LTS requires Java 17 or 21. Java 11 support was dropped in Jenkins 2.463+.
- Docker-in-Docker requires --privileged mode. Consider rootless alternatives (Kaniko, Podman) for build-time Docker needs.
- Plugin updates: plugins update independently from core. Run Manage Jenkins > Plugin Manager > Updates regularly.
- Reverse proxy: set Jenkins URL correctly in Manage Jenkins > System for webhooks and OAuth to work. Use Nginx/Caddy for HTTPS.
- Memory: allocate at least 512 MB heap; 1-2 GB for active CI. Set via JAVA_OPTS=-Xmx2g.
- No built-in backup: use ThinBackup plugin or rsync of JENKINS_HOME.

## Links

- GitHub: <https://github.com/jenkinsci/jenkins>
- Docs: <https://www.jenkins.io/doc/>
- Downloads: <https://www.jenkins.io/download/>
- Docker Hub: <https://hub.docker.com/r/jenkins/jenkins>
- Plugin index: <https://plugins.jenkins.io/>
- Installing with Docker: <https://www.jenkins.io/doc/book/installing/docker/>

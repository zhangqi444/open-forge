---
name: inginious
description: INGInious recipe for open-forge. Automated code grader for education. Runs student code securely in Docker containers. Python + MongoDB + Docker. AGPL-3.0. Source: https://github.com/INGInious/INGInious
---

# INGInious

Intelligent automated code grading platform for education. Teachers create programming exercises; students submit code through a web interface; INGInious runs and grades submissions securely inside Docker containers. Supports external LMS integration (Moodle, edX via LTI). Python backend, MongoDB, Docker-based task execution. AGPL-3.0 licensed. Developed at UCLouvain (Belgium).

Upstream: https://github.com/INGInious/INGInious | Docs: https://inginious.readthedocs.io | Demo: https://inginious.org

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Official method; recommended |
| Linux | pip + MongoDB | Manual install; see docs |
| Any | LTI integration | Works as external grader for Moodle or edX |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Superadmin password | Default credentials: superadmin / superadmin -- change immediately |
| config | Port | Default 9000 |
| config (optional) | REGISTRY | Docker image registry override (default: official ghcr.io registry) |
| config (optional) | VERSION | Container version to pull (default: latest) |
| config (optional) | LTI credentials | For Moodle/edX integration |

## Software-layer concerns

- Docker-in-Docker: INGInious runs student code inside Docker containers. The INGInious container must have access to the host Docker socket (or use a Docker-in-Docker setup).
- tasks/ directory: courses and exercises are stored here as files. Map as a volume to persist across container restarts and share with course authors.
- MongoDB: metadata, submissions, and user data stored in MongoDB. The compose file includes a MongoDB service.
- LTI support: INGInious can act as an LTI tool provider for Moodle or edX, allowing seamless grade passback.

## Install -- Docker Compose

```bash
git clone https://github.com/INGInious/INGInious.git
cd INGInious
docker compose up
# or with rebuild:
docker compose up --build
```

Access at http://localhost:9000. Default login: superadmin / superadmin.

The docker compose creates a tasks/ folder automatically if it doesn't exist.

Override registry/version if needed:

```bash
REGISTRY=myregistry.example.com VERSION=0.8.0 docker compose up
```

## Adding courses

Copy course directories into the tasks/ folder. Each course is a subdirectory with a course.yaml and task subdirectories.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Or rebuild from source:

```bash
git pull
docker compose up --build -d
```

## Gotchas

- Change superadmin credentials immediately: the default superadmin / superadmin credentials are public. Set a strong password on first login.
- Docker socket access: the INGInious container needs access to the Docker daemon to spin up grading containers. In the compose setup this is handled automatically; in manual installs you must configure Docker socket permissions.
- Course management: courses are file-based. Authors write YAML task definitions and upload them to the tasks/ volume. There is no GUI course builder -- tasks are authored as code/config files.
- Resource isolation: each student submission runs in a separate Docker container with configurable CPU, memory, and time limits. Set appropriate limits to prevent runaway submissions.

## Links

- Source: https://github.com/INGInious/INGInious
- Documentation: https://inginious.readthedocs.io
- Website: https://inginious.org

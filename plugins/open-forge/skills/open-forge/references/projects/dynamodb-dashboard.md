---
name: dynamodb-dashboard-project
description: Web GUI dashboard for local or remote DynamoDB instances. Upstream: https://github.com/kritish-dhaubanjar/dynamodb-dashboard
---

# DynamoDB Dashboard

Web GUI dashboard for local or remote [DynamoDB](https://aws.amazon.com/dynamodb/) instances. Supports browsing tables, running queries, and visualising data. Available via npm or Docker. Upstream: <https://github.com/kritish-dhaubanjar/dynamodb-dashboard>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | [GitHub README](https://github.com/kritish-dhaubanjar/dynamodb-dashboard#docker) | ✅ | Recommended self-hosted install |
| Docker run | [Docker Hub](https://hub.docker.com/r/kritishdhaubanjar/dynamodb-dashboard) | ✅ | Quick start |
| npm global install | [README](https://github.com/kritish-dhaubanjar/dynamodb-dashboard#installation) | ✅ | Direct CLI use |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Docker or npm install?" | options | All |
| config | AWS region | string | All |
| config | DynamoDB endpoint URL | URL | All |
| config | AWS access key ID | string | All |
| config | AWS secret access key | string | All |
| config | Port to expose dashboard on (default 8080) | number | Docker |

## Docker Compose install

Source: <https://github.com/kritish-dhaubanjar/dynamodb-dashboard>

```yaml
version: "3.7"
services:
  dynamodb-local:
    image: amazon/dynamodb-local:latest
    container_name: dynamodb-local
    working_dir: /home/dynamodblocal
    ports:
      - 8000:8000
    volumes:
      - ./:/home/dynamodblocal/data
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"

  dynamodb-dashboard:
    container_name: dynamodb-dashboard
    image: kritishdhaubanjar/dynamodb-dashboard:latest
    ports:
      - 8080:4567
    environment:
      AWS_REGION: us-west-2
      AWS_ENDPOINT: http://dynamodb-local:8000
      AWS_ACCESS_KEY_ID: fakeMyKeyId
      AWS_SESSION_TOKEN: fakeSessionToken
      AWS_SECRET_ACCESS_KEY: fakeSecretAccessKey
```

## npm install

```bash
npm install --global dynamodb-dashboard
dynamodb-dashboard start
```

Options:
- `-d, --debug` — show log output (default: false)
- `-p, --port <port>` — port to run app (default: 4567)
- `-h, --host <host>` — host to run app (default: 127.0.0.1)

Set AWS environment variables before launching:

```bash
export AWS_REGION=us-west-2
export AWS_ENDPOINT=http://localhost:8000
export AWS_ACCESS_KEY_ID=fakeAccessKeyId
export AWS_SECRET_ACCESS_KEY=fakeSecretAccessKey
dynamodb-dashboard start
```

## Configuration

AWS credentials are resolved via the standard AWS SDK v2 chain:
1. Explicit environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`)
2. `~/.aws/credentials`
3. AWS SSO sessions
4. EC2/ECS instance metadata

## NGINX (SSE support)

For Server-Sent Events (SSE) to work behind NGINX, disable buffering:

```nginx
proxy_buffering off;
proxy_cache off;
proxy_read_timeout 3600;
```

## Upgrade procedure

```bash
# Docker
docker compose pull && docker compose up -d

# npm
npm update --global dynamodb-dashboard
```

## Gotchas

- Default internal port is **4567** — map to a different host port if needed.
- NGINX requires `proxy_buffering off` for SSE-based log streaming to work.
- Fake credentials are fine for `dynamodb-local`; use real IAM credentials for remote DynamoDB.

## References

- GitHub: <https://github.com/kritish-dhaubanjar/dynamodb-dashboard>
- Docker Hub: <https://hub.docker.com/r/kritishdhaubanjar/dynamodb-dashboard>
- npm: <https://www.npmjs.com/package/dynamodb-dashboard>

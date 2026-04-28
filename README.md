# open-forge

Self-host open-source apps on your own cloud, guided by Claude Code.

Given a project and a cloud provider, open-forge walks you through provisioning, DNS, TLS, outbound email (SMTP), and inbound email. It captures the non-obvious gotchas that usually cost hours the first time: proxy misconfigurations, non-interactive certbot flags, mail config quirks, DNS propagation, etc.

## Supported today

Supported software:

| Software | What it is |
|---|---|
| Ghost | Self-hosted blogging platform |
| OpenClaw | Self-hosted personal AI agent (openclaw.ai) |
| Hermes-Agent | Self-improving personal AI agent from Nous Research |
| Ollama | Local-LLM inference server (foundation layer for self-hosted AI) |
| Open WebUI | Feature-rich web UI for any OpenAI-compatible LLM (pairs with Ollama) |
| Stable Diffusion WebUI (A1111) | Most-popular open-source AI image generator (text-to-image, ControlNet, LoRA) |
| ComfyUI | Node-based AI image / video generation (workflow graphs; power-user alternative to A1111) |
| Dify | Open-source LLMOps + AI app builder (visual workflows, RAG, multi-tenant) |
| LibreChat | Multi-provider chat UI for teams (multi-user, social logins, per-user balance, MCP, RAG) |

Supported **where**:

| Where | How |
|---|---|
| **AWS Lightsail** | OpenClaw blueprint (Bedrock pre-wired) · Ubuntu + Docker · Ubuntu + native · Ghost Bitnami blueprint |
| **AWS EC2** | Ubuntu / Amazon Linux + Docker · + native |
| **Azure VM** (Bastion-hardened, no public IP) | Ubuntu + Docker · + native |
| **Hetzner Cloud** | CX-line VM + Docker · + native |
| **DigitalOcean** | Droplet + Docker · + native |
| **GCP Compute Engine** | VM + Docker · + native |
| **Oracle Cloud** | Always-Free A1.Flex ARM + native (via Tailscale) |
| **Hostinger** | Managed (1-Click) or VPS (Docker Manager via hPanel) |
| **Raspberry Pi** | Pi 4 / Pi 5 (64-bit) + native |
| **macOS VM** (Lume on Apple Silicon) | Sandboxed macOS + native (for iMessage via BlueBubbles) |
| Any Linux VM you already have (other providers, bare metal) | Docker · Podman · native |
| **Any Kubernetes cluster** (EKS / GKE / AKS / DOKS / k3s / kind / Docker Desktop) | Kustomize manifests (or community Helm charts for projects that ship them) |
| **Fly.io** · **Render** · **Railway** · **Northflank** · **exe.dev** | PaaS one-click templates from the upstream repos |
| **Your own machine** (macOS / Linux / Windows / WSL2) | Docker Desktop · Podman · native (`install.sh` / `install-cli.sh` / `install.ps1`) |

Three-question flow: what to host, where to host, how to host. Claude asks only what's genuinely ambiguous — if your prompt already names a clear cloud, the first question is skipped.

## Install

In Claude Code:

```
/plugin marketplace add zhangqi444/open-forge
/plugin install open-forge@open-forge
```

## 使用 Docker 运行（macOS）

### 前置要求

- macOS 12.0+（Apple Silicon 或 Intel）
- Docker Desktop for Mac（已安装并运行）
- 至少 4GB 可用内存（推荐 8GB+）

### Docker Desktop for Mac 设置注意事项

1. **启用 Docker Compose**：Docker Desktop 默认已包含，无需单独安装
2. **分配足够资源**：
   - 打开 Docker Desktop → Settings → Resources
   - 建议分配：CPU 4 核+，内存 6GB+，磁盘空间 50GB+
3. **文件共享**：确保项目目录在 Docker Desktop 的 File Sharing 列表中（默认 `/Users` 已共享）
4. **Apple Silicon 用户**：部分镜像可能需要 Rosetta 转译，首次启动可能稍慢

### 快速启动

```bash
# 1. 克隆项目
cd /Users/zhouchengyue
# 如果还没有 open-forge，先克隆
git clone <repository-url> open-forge
cd open-forge

# 2. 创建 docker-compose.yml（如果还没有）
# 见下方的完整配置示例

# 3. 启动服务
docker-compose up -d

# 4. 查看日志
docker-compose logs -f

# 5. 停止服务
docker-compose down
```

### docker-compose.yml 配置示例

```yaml
version: '3.8'

services:
  open-forge:
    image: openclaw/open-forge:latest
    container_name: open-forge
    restart: unless-stopped
    ports:
      - "8080:8080"   # Web 界面
      - "8443:8443"   # HTTPS（可选）
    volumes:
      - ./data:/app/data              # 持久化数据
      - ./deployments:~/.open-forge/deployments  # 部署状态文件
      - /var/run/docker.sock:/var/run/docker.sock  # Docker-in-Docker（可选，用于自动部署）
    environment:
      - TZ=Asia/Shanghai
      - OPENFORGE_PORT=8080
      - OPENFORGE_ENV=production
      # 可选：配置日志级别
      # - LOG_LEVEL=info
    networks:
      - open-forge-net
    # macOS 特定优化
    platform: linux/amd64  # Intel Mac 可移除，Apple Silicon 建议保留以确保兼容性
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G

volumes:
  open-forge-data:

networks:
  open-forge-net:
    driver: bridge
```

### 端口映射说明

| 容器端口 | 主机端口 | 用途 |
|---------|---------|------|
| 8080 | 8080 | Web 界面 / API |
| 8443 | 8443 | HTTPS（可选，如需加密访问） |

如需自定义端口，修改 `ports` 部分，例如 `"3000:8080"` 将主机 3000 端口映射到容器 8080。

### 卷挂载说明

| 主机路径 | 容器路径 | 用途 |
|---------|---------|------|
| `./data` | `/app/data` | 应用数据持久化 |
| `./deployments` | `~/.open-forge/deployments` | 部署状态文件（重要！） |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker 套接字（可选，用于自动部署到云） |

**注意**：
- 确保 `./data` 和 `./deployments` 目录存在：`mkdir -p data deployments`
- Docker 套接字挂载仅在你需要 open-forge 自动执行 Docker 命令时需要
- macOS 上文件共享性能较好，但仍建议将大量 I/O 数据放在卷内

### 常见问题

**Q: 启动后无法访问 8080 端口？**
```bash
# 检查容器状态
docker-compose ps

# 查看日志
docker-compose logs open-forge

# 确认端口占用
lsof -i :8080
```

**Q: Apple Silicon 上镜像不兼容？**
```bash
# 强制使用 amd64 架构
docker-compose up -d --platform linux/amd64
```

**Q: 如何重置并重新开始？**
```bash
# 停止并删除容器、网络（保留卷）
docker-compose down

# 完全重置（包括卷，会删除所有数据！）
docker-compose down -v
```

**Q: 如何更新到最新版本？**
```bash
# 拉取最新镜像
docker-compose pull

# 重启服务
docker-compose up -d
```

## Use

Tell Claude what you want to deploy:

> "I want to self-host Ghost on AWS Lightsail."

The `open-forge` skill will take it from there — collecting inputs, running AWS CLI + SSH commands, guiding you through DNS and SMTP setup, and recording state so you can resume across sessions.

## How it works

- **Phased workflow**: preflight → provision → DNS → TLS → outbound email → inbound email → hardening. Each phase is verifiable and resumable.
- **State file**: `~/.open-forge/deployments/<name>.yaml` records inputs, outputs, and completed phases.
- **Progressive disclosure**: the skill loads only the references it needs for your chosen project + infra combo.
- **Autonomous with `--dry-run`**: runs AWS CLI / SSH directly by default; pass `--dry-run` to print commands without executing.

## Repo layout

```
open-forge/
├── .claude-plugin/marketplace.json     # marketplace manifest
└── plugins/
    └── open-forge/                     # the plugin
        ├── .claude-plugin/plugin.json
        └── skills/open-forge/
            ├── SKILL.md
            ├── references/
            │   ├── projects/           # per-project recipes (ghost.md, openclaw.md, ...)
            │   ├── infra/              # per-infra adapters (aws/, hetzner/, digitalocean/, gcp/, byo-vps.md, localhost.md)
            │   ├── runtimes/           # docker.md, podman.md, native.md, kubernetes.md
            │   └── modules/            # cross-cutting (preflight, dns, tls, smtp, inbound, tunnels)
            └── scripts/
```

## Contributing

To add a new project: drop a `references/projects/<name>.md` recipe.
To add a new infra: drop a `references/infra/<name>.md` adapter.
See existing files for the expected shape.

## License

MIT

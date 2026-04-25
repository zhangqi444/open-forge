---
name: preflight
description: Cross-cutting preflight for open-forge. Collects the three core inputs (software, where, how) from the user, then detects and offers to install the tools required for the chosen combo — AWS CLI only when infra ∈ AWS, Docker only when runtime = docker, etc. Loaded at the start of every deployment.
---

# Preflight — local environment setup

The first thing open-forge does in any deployment. Goal: get from "user wants to self-host X" to "Claude has all the tools and credentials needed to execute." Minimum questions, maximum autonomy.

## Operating principle

**Claude does the work; the user makes the choices.** Detect what's missing, propose the install, run it after confirmation. Never silently install. Never make the user copy-paste a command they could approve in chat. Announce every autonomous action in one sentence before running.

## Step 1 — the three questions

Ask these in order. Each narrows the next. If the user's prompt already names an answer, **announce the inferred choice instead of asking** ("I'll deploy OpenClaw on AWS since you said Lightsail. Say if you'd rather use something else.")

### 1a. What software?

Usually inferred from the user's prompt ("self-host Ghost" → ghost). If ambiguous, ask and load `references/projects/<name>.md`.

### 1b. Where to host?

Use `AskUserQuestion`:

> **Where should this run?**
> - AWS
> - Hetzner
> - DigitalOcean
> - GCP
> - Bring-your-own VPS (any Linux VM you already have)
> - **localhost** (your own machine)

Loads the matching infra adapter — `references/infra/<cloud>/` or `references/infra/{byo-vps,localhost}.md`. For clouds that don't yet have a dedicated adapter, fall through to `byo-vps.md` (user provides an already-provisioned VM).

### 1c. How? (service + runtime)

Generated *dynamically* from (software, where). Options come from the **Compatible combos** table in the project recipe, filtered by the where answer. Example for OpenClaw on AWS:

> **On AWS, which option?**
> - Lightsail OpenClaw blueprint — fastest, Bedrock pre-wired
> - Lightsail Ubuntu + Docker — any model provider, easy upgrades
> - Lightsail Ubuntu + native installer — any model provider, no containers
> - EC2 + Docker
> - EC2 + native installer

Skipped when the infra service bundles the runtime (EKS → Kubernetes, vendor blueprint → vendor's choice).

Loads the matching runtime module (`references/runtimes/docker.md`, etc.) when the choice isn't infra-bundled.

## Step 2 — required tools depend on the combo

Now that (software, where, how) are known, detect and install only the tools the chosen combo needs. Always required regardless of combo:

| Tool | Why |
|---|---|
| `jq` | Edit JSON config files — used in nearly every recipe |
| `curl` | Fetch installer scripts, health probes |

Infra-conditional:

| If infra ∈ | Also required |
|---|---|
| AWS | `aws` (v2) CLI |
| Hetzner (when adapter lands) | `hcloud` CLI |
| DigitalOcean (when adapter lands) | `doctl` CLI |
| GCP (when adapter lands) | `gcloud` CLI |
| BYO VPS | `ssh` (usually preinstalled) |
| localhost | none — Claude runs local Bash |

Runtime-conditional:

| If runtime = | Also required |
|---|---|
| Docker | `docker` (engine + compose v2) on the *target host* (local or remote). Not on the user's machine unless infra = localhost. |
| Native | build tools on the target host; usually installed by the project's installer script |
| Kubernetes | `kubectl` on the user's machine |

Project-conditional inputs (collected at their specific phases, not here):

- `ghost` → domain, Let's Encrypt email, SMTP provider + key (see `references/projects/ghost.md`)
- `openclaw` → model provider + API key (see `references/projects/openclaw.md`)

## Step 3 — detect tools on the user's machine

For each required tool, run detection in parallel:

```bash
command -v jq && jq --version
command -v curl && curl --version | head -1
# ...and whichever of aws / hcloud / ssh / kubectl applies
```

Missing ones go to step 4.

## Step 4 — offer to install missing tools

Detect the user's package manager (run in parallel):

```bash
command -v brew      # macOS Homebrew
command -v apt-get   # Debian/Ubuntu
command -v dnf       # Fedora/RHEL
command -v pacman    # Arch
command -v winget    # Windows
```

Pick the first that exists. For each missing tool, ask before installing:

> `AskUserQuestion`: "`<tool>` is required and not installed. Install with `<command>`?"
> Options: `Yes` / `Skip — I'll install myself` / `Cancel`

Announce in one sentence, then run. Verify after (`<tool> --version`).

### Install command matrix

| Tool | brew | apt-get | dnf | pacman | Manual fallback |
|---|---|---|---|---|---|
| `jq` | `brew install jq` | `sudo apt-get install -y jq` | `sudo dnf install -y jq` | `sudo pacman -S --noconfirm jq` | <https://jqlang.org/download/> |
| `curl` | preinstalled | `sudo apt-get install -y curl` | `sudo dnf install -y curl` | `sudo pacman -S curl` | preinstalled on macOS |
| `aws` v2 | `brew install awscli` | official installer (below) | `sudo dnf install -y awscli` | `sudo pacman -S aws-cli-v2` | <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html> |

`aws` note: `apt-get install awscli` installs v1 on older Ubuntu/Debian. Prefer the official v2 installer:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
  && unzip -q /tmp/awscliv2.zip -d /tmp \
  && sudo /tmp/aws/install \
  && aws --version
```

For **Docker** (install on the target host, not the user's machine):

- On a Linux VPS (BYO or cloud Ubuntu): `curl -fsSL https://get.docker.com | sudo sh` — runs via SSH, not locally. See `references/runtimes/docker.md`.
- On localhost: don't auto-install Docker Desktop / colima / OrbStack silently — too disruptive. Point the user at the download and wait.

## Step 5 — cloud credentials (only when applicable)

Only runs when infra ∈ AWS / Hetzner / DO / GCP.

### AWS

```bash
aws configure list-profiles
```

- **No profiles**: ask whether to run `aws configure` interactively (user types access key / secret / region — Claude doesn't see them) or to pause while the user sets one up themselves.
- **One profile**: confirm with "Using profile `<name>`. OK?"
- **Multiple profiles**: `AskUserQuestion` to pick.

Sanity-check:

```bash
aws sts get-caller-identity --profile "$AWS_PROFILE"
```

Show the user *which account* is selected — single most common preflight mistake is using the wrong AWS account. If it errors ("could not be found" / "expired"), help re-auth (`aws sso login --profile <name>` for SSO setups) before continuing.

### Hetzner / DigitalOcean / GCP

When those adapters land, each has its own credential flow (`hcloud config`, `doctl auth init`, `gcloud auth login`). Follow their standard onboarding — don't reinvent.

### BYO VPS

Ask for the SSH details specified in `references/infra/byo-vps.md` (host, user, key path, OS family). Verify SSH works before proceeding.

### localhost

Nothing to collect. Skip this step.

## Step 6 — region (only when applicable)

Only for clouds with regions. Use `AskUserQuestion` with the most common options + "Other":

> "Which region?"

Default suggestion: geographically closest to the user. If unsure, `us-east-1` (cheapest egress, most service availability).

Skipped for BYO VPS (the VM's already in a region the user picked) and localhost (irrelevant).

## Step 7 — deployment name

```
AskUserQuestion: "What should we call this deployment?"
Free-text. Validate: lowercase, hyphens, no spaces, ≤ 30 chars.
```

Used as the state file key, the instance name when provisioning, and the default for other resource names.

## Step 8 — write the state file

```yaml
# ~/.open-forge/deployments/<name>.yaml
name: <deployment-name>
project: <software>
infra: <where>        # aws-lightsail-blueprint, aws-lightsail-ubuntu, aws-ec2, hetzner-cloud-cx, byo-vps, localhost, ...
runtime: <how>        # docker, native, vendor-blueprint, kubernetes, ... or null when infra bundles it
inputs:
  aws_profile: <profile>     # only when infra ∈ AWS
  aws_region: <region>       # only when applicable
  ssh_host: <ip-or-fqdn>     # only when infra = byo-vps
  ssh_user: <user>           # only when infra = byo-vps
  ssh_key_path: <path>       # only when infra = byo-vps
phases:
  preflight: { status: done, at: "<ISO-8601>" }
  ...
```

After this, hand off to the project recipe and infra/runtime modules for their respective input collection.

## Resuming an existing deployment

If `~/.open-forge/deployments/<name>.yaml` exists, **read it and skip preflight**. Resume from the first non-`done`, non-`skipped` phase. Confirm with the user before restarting work mid-stream.

## What NOT to ask in preflight

- Domain names, SMTP keys, model providers, API keys — project recipe's input collection at the right phase.
- Bundle / blueprint / instance size — infra adapter or project recipe at the provision phase.
- IAM / role / permission specifics — project recipe.

Preflight is **software-and-combo-aware**: what it asks depends on the three top-level answers, but it doesn't dig into project internals. Everything beyond the tuple `(software, where, how)` belongs downstream.

---
name: preflight
description: Cross-cutting preflight module for open-forge — detects required CLI tools on the user's machine, offers to install missing ones via the local package manager, and validates AWS profile access. Loaded at the start of every deployment, before any project- or infra-specific work.
---

# Preflight — local environment setup

The first thing open-forge does in any deployment. The goal: get the user from "I have a cloud account" to "Claude has working tools and credentials" with the minimum number of questions.

## Operating principle

**Claude does the work; the user makes the choices.** Detect what's missing, propose the install, run it after confirmation. Never silently install. Never make the user copy-paste a command they could approve in chat.

## Step 1 — detect tools

Run all four checks in parallel (single Bash message, multiple commands or one combined script):

```bash
command -v aws  && aws --version
command -v ssh
command -v jq
command -v curl
```

Required for v0.x:

| Tool | Why |
|---|---|
| `aws` (v2) | All infra adapters use AWS CLI for provisioning |
| `ssh` | Connect to provisioned instances; ships with macOS / Linux by default |
| `jq` | Edit JSON config files on remote (Ghost config, OpenClaw config) |
| `curl` | Fetch setup scripts (e.g. AWS-published Bedrock IAM script) |

If any are missing, proceed to Step 2 for that tool.

## Step 2 — offer to install missing tools

Detect the user's package manager (run in parallel):

```bash
command -v brew     # macOS Homebrew
command -v apt-get  # Debian/Ubuntu
command -v dnf      # Fedora/RHEL
command -v yum      # Older RHEL/CentOS
```

Pick the first one that exists. If none exist or the user is on Windows, fall back to printing the official install URL and asking the user to install manually.

For each missing tool, **ask the user before installing**. Use `AskUserQuestion`:

> Question: "`jq` is required and not installed. Install it now?"
> Options: `Yes, install with brew install jq` / `Skip — I'll install manually` / `Cancel`

On confirmation, run the install command. Announce it in one sentence first.

### Install command matrix

| Tool | brew | apt-get | dnf / yum | Manual fallback |
|---|---|---|---|---|
| `aws` | `brew install awscli` | `sudo apt-get install -y awscli` (often v1; prefer official installer) | `sudo dnf install -y awscli` | `https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html` |
| `jq` | `brew install jq` | `sudo apt-get install -y jq` | `sudo dnf install -y jq` | `https://jqlang.org/download/` |
| `curl` | preinstalled | `sudo apt-get install -y curl` | `sudo dnf install -y curl` | preinstalled on macOS |

For `aws`: if `apt-get install -y awscli` is the only option, warn the user it installs v1; v2 is recommended. Offer the official installer pipe instead:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
  && unzip -q /tmp/awscliv2.zip -d /tmp \
  && sudo /tmp/aws/install \
  && aws --version
```

Always verify after install: `aws --version`, `jq --version`, etc.

## Step 3 — validate AWS profile

```bash
aws configure list-profiles
```

Branches:

- **No profiles configured.** Ask: "No AWS profiles found. Should I run `aws configure` interactively for a new profile, or do you want to set one up yourself first?" If interactive, hand off to `aws configure` (it prompts for access key, secret, region — the user types them; Claude doesn't see them in chat).
- **One profile.** Confirm: "Using profile `<name>`. OK?" with options to override.
- **Multiple profiles.** Use `AskUserQuestion` to pick one.

After picking, sanity-check it works:

```bash
aws sts get-caller-identity --profile "$AWS_PROFILE"
```

Expected: a JSON blob with `Account`, `Arn`, `UserId`. Show the user *which account* is selected — single most common preflight mistake is using the wrong AWS account.

If it errors with "could not be found" or "expired", help re-auth (likely `aws sso login --profile <name>` for SSO setups) before continuing.

## Step 4 — confirm region

Ask which region to deploy in. Use `AskUserQuestion` with the common choices + an "other" option:

> Question: "Which AWS region?"
> Options: `us-east-1` / `us-west-2` / `eu-west-1` / `ap-southeast-1` / `Other (specify)`

Default suggestion: pick the region geographically closest to the user. If unsure, `us-east-1` (most service availability, cheapest egress for typical hobbyist use).

## Step 5 — deployment name

Ask for a short hyphen-case name (e.g. `my-blog`, `agent-01`):

> Question: "What should we call this deployment? (used for the Lightsail instance name and state file)"
> Free-text answer.

Validate: lowercase, hyphens, no spaces, ≤ 30 chars. Reject and re-ask if invalid.

## Step 6 — write the state file

```yaml
# ~/.open-forge/deployments/<name>.yaml
name: <deployment-name>
project: <project>
infra: <infra>
inputs:
  aws_profile: <profile>
  aws_region: <region>
phases:
  preflight: { status: done, at: "<ISO-8601>" }
  ...
```

After this, hand off to the project recipe and infra adapter for their respective input collection.

## Resuming an existing deployment

If `~/.open-forge/deployments/<name>.yaml` already exists when the user names a deployment, **read it and skip preflight**. Resume from the first non-`done`, non-`skipped` phase. Confirm with the user before restarting work mid-stream.

## What NOT to ask in preflight

Keep preflight infra-and-project-agnostic. Don't ask about:

- Domain names, SMTP keys, model providers — those belong in the project recipe's input collection.
- Bundle/blueprint choices — those belong in the infra adapter or project recipe.
- IAM role specifics — those belong in the project recipe.

The preflight should be **identical for every project + infra combination**. Anything project- or infra-specific moves into the respective recipe.

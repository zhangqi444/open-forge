---
name: RunsOn
description: "Self-hosted GitHub Actions runners in your AWS account. CloudFormation. runs-on/runs-on. Ephemeral EC2 VMs per job, spot pricing, 7–15x cheaper than GitHub-hosted, Linux/Windows/GPU, S3 cache, static IPs. MIT CloudFormation assets."
---

# RunsOn

**Self-hosted GitHub Actions runners in your own AWS account.** Replace expensive GitHub-hosted runners with ephemeral EC2 VMs that spin up per job and terminate when done. Spot pricing with automatic on-demand fallback. 7–15x cheaper than GitHub-hosted runners; up to 30% faster CPU. All data stays in your AWS account — no third-party access to your code or secrets.

Built + maintained by **Cyril Rohr**. MIT (CloudFormation assets); commercial product with pricing tiers.

- Upstream repo: <https://github.com/runs-on/runs-on>
- Website + docs: <https://runs-on.com>
- Install guide: <https://runs-on.com/guides/install/>
- Pricing: <https://runs-on.com/pricing/>

## Architecture in one minute

- Deploys into **your AWS account** via a CloudFormation stack
- Creates a private **GitHub App** for your organization during setup
- When a job runs with a `runs-on` label, RunsOn:
  1. Provisions an **EC2 instance** (ephemeral — terminates after job)
  2. EC2 registers as a GitHub Actions self-hosted runner
  3. Job executes; runner deregisters; instance terminates
- Spot pricing: tries spot first; falls back to on-demand automatically
- **S3 cache backend**: replaces GitHub's 10 GB cache limit with unlimited S3 caching
- Supports Linux, Windows, and GPU runners
- No RunsOn servers touch your code — traffic stays in your AWS account + GitHub

## Compatible install methods

| Infra      | Runtime              | Notes                                                              |
| ---------- | -------------------- | ------------------------------------------------------------------ |
| **AWS**    | CloudFormation stack | **Only method** — deploys into your AWS account via CFn template   |

## Inputs to collect

| Input                  | Example                     | Phase    | Notes                                                            |
| ---------------------- | --------------------------- | -------- | ---------------------------------------------------------------- |
| AWS account            | existing AWS account        | Cloud    | RunsOn deploys into your account                                 |
| GitHub org             | your-org                    | GitHub   | A private GitHub App is created for the org during setup         |
| RunsOn license key     | from runs-on.com/pricing    | License  | Free tier available; paid tiers for more features                |
| AWS region             | us-east-1                   | Cloud    | Where EC2 runners will launch                                    |

## Install (10 minutes)

Follow the official guide: <https://runs-on.com/guides/install/>

High-level steps:
1. Sign up at runs-on.com → get license key
2. Deploy CloudFormation stack in your AWS account
3. Create private GitHub App for your org (guided in the install flow)
4. Configure the App with your RunsOn endpoint

## Usage in workflows

Before (GitHub-hosted):
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

After (RunsOn):
```yaml
jobs:
  build:
    runs-on: "runs-on=${{ github.run_id }}/runner=2cpu-linux-x64"
```

Or with more options:
```yaml
runs-on: "runs-on=${{ github.run_id }}/runner=8cpu-linux-x64/spot=true/image=ubuntu22-full-x64"
```

Full job label reference: <https://runs-on.com/configuration/job-labels>

## Runner sizing options

| Label | vCPU | RAM | Notes |
|-------|------|-----|-------|
| `1cpu-linux-x64` | 1 | 2 GB | Smallest |
| `2cpu-linux-x64` | 2 | 4 GB | GitHub-hosted equivalent |
| `4cpu-linux-x64` | 4 | 8 GB | |
| `8cpu-linux-x64` | 8 | 16 GB | |
| `16cpu-linux-x64` | 16 | 32 GB | |
| `gpu-linux-x64` | varies | varies | GPU runners |
| Windows variants | — | — | `windows` in label |

Exact instance type selection: <https://runs-on.com/runners/linux>

## Key features

| Feature | Details |
|---------|---------|
| Spot pricing | Auto spot→on-demand fallback; typically 80% cost saving |
| S3 cache | Replace GitHub's 10 GB cache limit; unlimited S3 storage |
| Ephemeral VMs | Fresh EC2 per job; no shared state between jobs |
| Custom images | Use public AWS AMIs or bring your own image (BYOI) |
| Static IPs | Optional Elastic IPs for firewall whitelisting |
| SSH access | Optional SSH into running jobs for debugging |
| Cost reporting | Built-in cost alerts and reports |
| Multi-AZ | Spread runners across Availability Zones |
| GPU runners | NVIDIA GPU support for ML/AI workloads |
| Magic caching | Intelligent dependency caching |

## Gotchas

- **AWS costs are yours.** RunsOn saves money vs GitHub-hosted runners, but EC2, S3, and network costs accrue to your AWS account. Monitor with Cost Explorer. Spot instances can be interrupted — RunsOn handles this with on-demand fallback.
- **RunsOn subscription + AWS costs.** RunsOn charges a license fee (see pricing page); you also pay AWS for the EC2 instances directly. The net result is typically 7–15x cheaper than GitHub-hosted.
- **AWS IAM permissions.** The CloudFormation stack needs IAM permissions to create EC2 instances, security groups, IAM roles, etc. Review the CFn template before deploying.
- **Private GitHub App.** RunsOn creates a private GitHub App installed only in your org. The App token is used to register/deregister runners. It's scoped minimally — review the permissions during setup.
- **Not open-source beyond CFn assets.** The private RunsOn server code is proprietary. The public GitHub repo contains CloudFormation templates and public-facing assets only. You're trusting the RunsOn service binary that runs in your AWS account.
- **Spot interruptions.** If a spot instance is reclaimed mid-job, the job fails and GitHub retries it. RunsOn tries on-demand fallback but can't always avoid interruptions for very short-lived spot capacity.
- **VPC/networking.** By default, runners launch in your default VPC. For private resources (internal registries, databases), configure RunsOn to launch in a specific VPC/subnet with appropriate security groups.

## Cost comparison (approximate)

| Runner | Hourly (2 vCPU) | Notes |
|--------|----------------|-------|
| GitHub-hosted | $0.008/min ≈ $0.48/hr | Standard price |
| RunsOn spot (e.g. c7i.large) | ~$0.03–0.06/hr | + RunsOn fee |
| RunsOn on-demand (c7i.large) | ~$0.09/hr | + RunsOn fee |

For teams running many hours of CI per month, savings are substantial.

## Project health

Active development, CloudFormation templates, public benchmarks, pricing tiers (including free). Maintained by Cyril Rohr. MIT for public CFn assets; commercial product license for the service.

## GitHub-Actions-runner-family comparison

- **RunsOn** — AWS CloudFormation, ephemeral EC2, spot pricing, S3 cache, 7–15x cheaper, commercial
- **Actions Runner Controller (ARC)** — Kubernetes-based, open-source, more complex ops
- **Philips Terraform module** — Terraform/AWS; similar concept; open-source
- **Buildjet** — SaaS self-hosted runners; simpler but not in your AWS account
- **Actuated** — BareMetal microVMs; different isolation model
- **GitHub-hosted** — zero ops; expensive; the baseline

**Choose RunsOn if:** you run significant GitHub Actions CI on AWS and want to cut costs 7–15x while keeping runner infrastructure in your own account without Kubernetes complexity.

## Links

- Repo: <https://github.com/runs-on/runs-on>
- Docs + pricing: <https://runs-on.com>
- Install guide: <https://runs-on.com/guides/install/>
- Job labels: <https://runs-on.com/configuration/job-labels>
- Benchmarks: <https://runs-on.com/benchmarks/github-actions-runners/>

---
name: ec2-infra
description: AWS EC2 infra adapter — how to provision an EC2 instance with security group, key pair, Elastic IP, and SSH-in for open-forge deployments. Pair with `runtimes/docker.md` or `runtimes/native.md` for the application install. Picked when the user wants more control than Lightsail offers (custom AMI, VPC, instance types beyond Lightsail's 5 sizes).
---

# AWS EC2 adapter

EC2 is AWS's general-purpose compute. Use it instead of Lightsail when you need: a non-Bitnami AMI, custom networking (VPC, subnets, peering), instance types Lightsail doesn't expose (GPU, ARM Graviton, large memory), or you already have an organization VPC the deployment must live in.

## Prerequisites

Check during preflight; stop and install/configure if missing:

- `aws` CLI v2 (`aws --version`)
- A configured AWS profile with EC2 + IAM permissions (`aws configure list-profiles`)
- A default VPC in the chosen region (most accounts have one; required for the simple flow below)

## Inputs to collect

Cross-cutting preflight collects `aws_profile`, `aws_region`, deployment name. The EC2 adapter additionally needs:

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Instance type?" | `AskUserQuestion`, options from the table below | Project-recipe-suggested |
| End of preflight | "AMI?" | `AskUserQuestion`: `Ubuntu 24.04 LTS (canonical owner)` / `Amazon Linux 2023` / `Other (specify ID)` | `Ubuntu 24.04 LTS` |
| End of preflight | "Root volume size (GB)?" | `AskUserQuestion`: `20` / `30` / `50` / `Other` | `30` |

Derived (no prompt):

| Recorded as | Derived from |
|---|---|
| `outputs.instance_name` | Deployment name |
| `outputs.security_group_name` | `<deployment-name>-sg` |
| `outputs.key_pair_name` | `<deployment-name>-key` |
| `outputs.eip_allocation_id` | `aws ec2 allocate-address` output |
| `outputs.public_ip` | `aws ec2 describe-addresses` |
| `outputs.ssh_key_path` | `~/.ssh/<deployment-name>-ec2.pem` |

### Common instance-type options

| Type | vCPU | RAM | Approx $/mo (us-east-1, on-demand) | When |
|---|---|---|---|---|
| `t3.micro` | 2 | 1 GB | $7.6 | Toy / static. Free tier eligible for first 12 mo. |
| `t3.small` | 2 | 2 GB | $15 | Light Ghost-style blog |
| `t3.medium` | 2 | 4 GB | $30 | OpenClaw, Nextcloud, anything Node/JVM |
| `t4g.medium` | 2 | 4 GB | $24 | Same as t3.medium but ARM (Graviton) — cheaper if upstream ships ARM |
| `t3.large` | 2 | 8 GB | $60 | Heavier workloads |
| `c7g.large` | 2 | 4 GB | $58 | Compute-heavy ARM |

Project recipes will suggest a default. Pick the smallest that meets the project's RAM minimum.

## Provisioning

### 1. Resolve the AMI ID for the chosen region

Always resolve dynamically — AMI IDs are region-scoped and rotate frequently.

```bash
# Ubuntu 24.04 LTS (Canonical's AWS account 099720109477)
AMI_ID=$(aws ec2 describe-images \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)
echo "$AMI_ID"

# For ARM (Graviton) — replace amd64 with arm64
# For Amazon Linux 2023 — owner 137112412989, name 'al2023-ami-2023.*-x86_64'
```

### 2. Create a key pair (or reuse one)

EC2 key pairs are region-scoped. Save the private key the first time it's created.

```bash
KEY_NAME="${INSTANCE_NAME}-key"
KEY_PATH="$HOME/.ssh/${INSTANCE_NAME}-ec2.pem"

if ! aws ec2 describe-key-pairs \
       --profile "$AWS_PROFILE" --region "$AWS_REGION" \
       --key-names "$KEY_NAME" >/dev/null 2>&1; then
  aws ec2 create-key-pair \
    --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --key-name "$KEY_NAME" --key-type ed25519 \
    --query 'KeyMaterial' --output text > "$KEY_PATH"
  chmod 600 "$KEY_PATH"
fi
```

### 3. Create the security group + open initial ports

Default-VPC flow (simplest). For non-default VPCs, add `--vpc-id <vpc-id>` and use `aws ec2 authorize-security-group-ingress` with explicit `--group-id`.

```bash
SG_NAME="${INSTANCE_NAME}-sg"
SG_ID=$(aws ec2 create-security-group \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --group-name "$SG_NAME" \
  --description "open-forge: $INSTANCE_NAME" \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --group-id "$SG_ID" \
  --ip-permissions \
    'IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0}]' \
    'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]' \
    'IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=0.0.0.0/0}]'
```

If the project recipe needs additional ports (custom WebSocket, SMTP submission), open them the same way at the relevant phase.

### 4. Launch the instance

```bash
INSTANCE_ID=$(aws ec2 run-instances \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=$ROOT_VOLUME_GB,VolumeType=gp3,DeleteOnTermination=true,Encrypted=true}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=open-forge,Value=true}]" \
  --metadata-options "HttpTokens=required,HttpEndpoint=enabled" \
  --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID"
```

`HttpTokens=required` enforces IMDSv2 — protects metadata service from SSRF. Leave it on unless the project recipe explicitly says it's incompatible (rare).

### 5. Allocate and associate an Elastic IP

EIPs persist across stop/start; the auto-assigned public IP doesn't. Always attach an EIP before DNS.

```bash
EIP_OUT=$(aws ec2 allocate-address \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --domain vpc \
  --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=$INSTANCE_NAME-ip},{Key=open-forge,Value=true}]")

EIP_ALLOC=$(echo "$EIP_OUT" | jq -r '.AllocationId')
PUBLIC_IP=$(echo "$EIP_OUT"  | jq -r '.PublicIp')

aws ec2 associate-address \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --instance-id "$INSTANCE_ID" \
  --allocation-id "$EIP_ALLOC"
```

Save `outputs.eip_allocation_id`, `outputs.public_ip`.

## SSH convention

- User: **`ubuntu`** for Ubuntu AMIs, **`ec2-user`** for Amazon Linux / RHEL, **`admin`** for Debian.
- First SSH: `-o StrictHostKeyChecking=accept-new`. Don't blow away `known_hosts` entries when a new EIP is associated.

```bash
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new "ubuntu@$PUBLIC_IP"
```

## Firewall changes after provision

Add ports later via `authorize-security-group-ingress`; remove via `revoke-security-group-ingress`. Open only what the project actually needs — default deny is your friend on EC2.

```bash
aws ec2 authorize-security-group-ingress \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --group-id "$SG_ID" \
  --ip-permissions "IpProtocol=tcp,FromPort=<N>,ToPort=<N>,IpRanges=[{CidrIp=0.0.0.0/0}]"
```

## Verification

Mark `provision` done only when all of:

- `aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name'` returns `running`
- `aws ec2 describe-addresses --allocation-ids "$EIP_ALLOC" --query 'Addresses[0].InstanceId'` returns the instance ID (associated)
- `ssh -i $KEY_PATH ubuntu@$PUBLIC_IP 'echo ok'` prints `ok`

## Teardown

For cleanup later (do **not** auto-run; confirm with the user):

```bash
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
aws ec2 release-address --allocation-id "$EIP_ALLOC"
aws ec2 delete-security-group --group-id "$SG_ID"
aws ec2 delete-key-pair --key-name "$KEY_NAME"
rm -f "$KEY_PATH"
```

EBS root volume is deleted on terminate (`DeleteOnTermination=true` set above). Snapshot it first if the user wants the data.

## Gotchas

- **EIP charged when not associated.** AWS bills idle EIPs (~$0.005/hr). Release on teardown, or leave attached even when the instance is stopped.
- **Default VPC may be missing.** Some org accounts have no default VPC. Detect with `aws ec2 describe-vpcs --filters Name=is-default,Values=true`. If empty, fall back to asking the user for an existing VPC + subnet ID, or stop and explain.
- **Spot vs on-demand.** open-forge defaults to on-demand for predictable single-node deploys. Spot can interrupt with 2-minute notice — wrong for stateful self-hosting.
- **Security group "default-vpc-default-sg" trap.** New instances launched without `--security-group-ids` join the VPC's default SG, which often allows all-internal but no external. Always pass our explicit SG.
- **IMDSv2 token requirement.** Old SDKs / instance-metadata callers that still use IMDSv1 will fail with `401 Unauthorized` against the metadata endpoint. Project recipes that hit `http://169.254.169.254/` need to support v2 (Bedrock SDK, recent AWS CLI — yes; very old curl-based scripts — no).
- **AMI rotation.** Don't hardcode AMI IDs in state files. Resolve fresh each time, or store the AMI ID alongside the deployment so rebuilds reuse the exact image.
- **Region-scoped key pair.** A new region means a new key. Don't try to import the same key everywhere — let each deployment create its own.
- **`stop-instances` keeps EBS billed.** Stopped instances pay $0 compute but full EBS storage. Long-pause deployments should be terminated with a snapshot if cost matters.

## Reference

- EC2 user guide: <https://docs.aws.amazon.com/ec2/latest/userguide/>
- Default-VPC flow: <https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html>
- Ubuntu AMI catalog: <https://cloud-images.ubuntu.com/locator/ec2/>

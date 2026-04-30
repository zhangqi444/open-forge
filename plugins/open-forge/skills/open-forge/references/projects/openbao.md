---
name: OpenBao
description: "Open-source fork of HashiCorp Vault — secrets management, dynamic credentials, PKI CA, encryption-as-a-service, transit engine. Forked from pre-BSL Vault; OSI-approved license. Community-governed under Linux Foundation / OpenSSF. Go. Mozilla Public License 2.0."
---

# OpenBao

**OpenBao** is **the open-source fork of HashiCorp Vault** — a community-driven continuation after HashiCorp relicensed Vault from MPL-2.0 to the Business Source License (BSL) in August 2023. OpenBao forked from the last MPL-2.0 version and continues development under **Linux Foundation / OpenSSF** governance with an OSI-approved license (MPL-2.0).

If you were using Vault before the BSL change, or you want Vault's feature set without the proprietary license drift, **OpenBao is the drop-in successor**. API-compatible with Vault (for now); shares the same core architecture.

Features (Vault-parity):

- **Key/Value secret storage** — encrypted at rest
- **Dynamic secrets** — on-demand DB credentials (Postgres/MySQL/Mongo/etc.), cloud creds (AWS/GCP/Azure), SSH keys, PKI certs
- **PKI secrets engine** — be your own CA; issue short-lived certs
- **Transit engine** — encryption-as-a-service (never see keys in app code)
- **Transform engine** — tokenization, masking, FPE
- **SSH** — signed SSH certs for user auth
- **TOTP** — generate OTPs
- **Identity** — entities + groups + aliases across auth methods
- **Auth methods** — Token, userpass, AppRole, LDAP, OIDC/JWT, Kubernetes, AWS/GCP/Azure IAM, Kerberos, cert, Okta, RADIUS
- **Audit devices** — file, syslog, socket; every operation logged
- **Response wrapping** — one-time-use tokens
- **Leases + renewals + revocation** — time-bound secret access
- **Policy language** — HCL policies for fine-grained ACL
- **Storage backends**: File, Raft (integrated HA), Postgres, MySQL, Consul, S3, etcd, DynamoDB
- **Seal/unseal** — root key split via Shamir (or auto-unseal via cloud KMS)

- Upstream repo: <https://github.com/openbao/openbao>
- Website: <https://openbao.org>
- Docs: <https://openbao.org/docs/>
- Discussions: <https://github.com/openbao/openbao/discussions>
- Linux Foundation OpenSSF home: <https://openssf.org>
- Chat: <https://linuxfoundation.zulipchat.com/#narrow/channel/530381-openssf-openbao-support>
- Mailing list: <https://lists.openssf.org/g/openbao>
- Security contact: <mailto:openbao-security@lists.openssf.org>

## Architecture in one minute

- **Single Go binary** — `bao` (CLI + server)
- **Storage backend**: Raft (integrated HA, most common now) or File (dev only) or Postgres / Consul / etc.
- **Secrets + audit + auth** engines pluggable
- **Unseal model**: at startup, Vault/OpenBao is **sealed** (encrypted storage, can't read/write) → must be **unsealed** with Shamir key shares or auto-unsealed via cloud KMS
- **API + UI**: HTTP(S) API on `:8200`; built-in web UI
- **HA via Raft**: 3 or 5 nodes with Raft consensus

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                             |
| ------------------ | -------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Single VM          | **Binary + systemd**                                               | **Most common production path**                                                       |
| Single VM          | Distro package (deb/rpm)                                                     | Community-built                                                                                 |
| Single VM          | **Docker (`openbao/openbao`)**                                                        | Works; use for dev/labs; stateful in prod gets tricky                                                          |
| Kubernetes         | Helm chart                                                                                       | Production path for cloud-native                                                                                             |
| HA cluster         | 3 or 5 nodes with Raft storage                                                                                  | Required for production                                                                                                                |
| Managed            | — (no vendor SaaS yet; check Linux Foundation projects for managed offerings)                                                           |                                                                                                                                                          |

## Inputs to collect

| Input                  | Example                                 | Phase       | Notes                                                                       |
| ---------------------- | --------------------------------------- | ----------- | --------------------------------------------------------------------------- |
| Cluster domain         | `bao.example.com`                            | URL         | API + UI                                                                             |
| Raft storage path      | `/opt/openbao/data`                                | Storage     | Per-node                                                                                        |
| TLS certs              | internal CA or Let's Encrypt                              | Security    | Mandatory for production                                                                                           |
| Listener addr          | `0.0.0.0:8200`                                                  | Network     | Or bind to specific interface                                                                                                             |
| Auto-unseal (opt)      | cloud KMS (AWS KMS / GCP KMS / Azure Key Vault)                           | Operations  | Highly recommended — otherwise manual unseal on every restart                                                                                                 |
| Audit log destination  | `/var/log/openbao/audit.log`                                                        | Compliance  | **Configure before first real use**                                                                                                                                                         |
| Initial root token     | generated on init                                                                                    | Bootstrap   | Revoke after creating real admin + policies                                                                                                                                                                                 |

## Install (binary + systemd)

```sh
# Download
curl -LO https://github.com/openbao/openbao/releases/download/v2.0.0/bao_2.0.0_linux_amd64.tar.gz
tar xzf bao_2.0.0_linux_amd64.tar.gz
sudo mv bao /usr/local/bin/

# User + dirs
sudo useradd --system --home /etc/openbao.d --shell /bin/false openbao
sudo mkdir -p /opt/openbao/data /etc/openbao.d
sudo chown -R openbao:openbao /opt/openbao /etc/openbao.d
```

`/etc/openbao.d/openbao.hcl`:

```hcl
storage "raft" {
  path    = "/opt/openbao/data"
  node_id = "bao-1"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/etc/openbao.d/tls.crt"
  tls_key_file  = "/etc/openbao.d/tls.key"
}

api_addr     = "https://bao.example.com:8200"
cluster_addr = "https://bao-1.internal:8201"
ui           = true
```

Systemd service + start + `bao operator init` → you get 5 unseal keys + root token.

**Save unseal keys + root token somewhere safe immediately.**

## First boot (critical sequence)

1. `bao operator init` → records **5 unseal keys** + **1 initial root token**. **DO NOT LOSE THESE.** Distribute keys to trusted parties (Shamir secret sharing).
2. `bao operator unseal` × 3 (threshold of 5) → unseal
3. `export BAO_TOKEN=<root-token>` → admin
4. Enable audit device: `bao audit enable file file_path=/var/log/openbao/audit.log` — **do this before any real secrets**
5. Enable auth method: `bao auth enable userpass` (or OIDC/LDAP)
6. Create your first real admin policy + user
7. **Revoke initial root token**: `bao token revoke <root-token>`
8. Add HA nodes: `bao operator raft join` from node 2 and 3
9. Enable secrets engines you need (kv-v2, pki, database, transit, etc.)

## Data & config layout

- `/opt/openbao/data/` — Raft storage (encrypted)
- `/etc/openbao.d/openbao.hcl` — server config
- Audit logs at configured path
- TLS material

## Backup

```sh
# Raft snapshot (atomic, consistent)
bao operator raft snapshot save backup-$(date +%F).snap
# Restore: bao operator raft snapshot restore backup.snap
```

**Back up UNSEAL KEYS + ROOT TOKEN separately, offline.** Lose unseal keys + lose a majority of HA nodes = data unrecoverable. This is the single biggest operational risk.

## Upgrade

1. Releases: <https://github.com/openbao/openbao/releases>. Active.
2. Read release notes carefully — secrets engines evolve, policy syntax may change.
3. **HA upgrade**: rolling — drain one node, upgrade binary, rejoin Raft, move to next.
4. Test on staging.
5. Back up Raft snapshot before.

## Gotchas

- **OpenBao is the MPL-2.0 fork of HashiCorp Vault.** HashiCorp's Vault is now BSL-licensed (not open-source by OSI definition). If you care about OSI-approved licensing + community governance, OpenBao. If you want HashiCorp's commercial support + enterprise features, Vault Enterprise is still the commercial option.
- **API compat with Vault**: excellent currently. Over time the projects will diverge. Plan your clients for both (most official SDKs work against both).
- **Migration from Vault → OpenBao**: straightforward currently (same storage format, same API). Document before relying.
- **Unseal key loss = data loss.** If you lose your unseal keys (and you lose a quorum of Raft nodes), your secrets are encrypted and unrecoverable. Store keys offline in multiple safe locations. This is THE most important operational discipline.
- **Auto-unseal via cloud KMS** is the production standard — otherwise every restart needs manual unseal ceremony. KMS-backed = one fewer human-in-loop.
- **Audit logs are mandatory before trusting**. Without audit, you can't answer "who accessed X secret when" — critical for compliance.
- **Policy language (HCL)**: powerful but easy to over-grant. Follow principle of least privilege. Test policies with a read-only user before granting.
- **Token TTLs**: configure short TTLs + renewable; long-lived tokens are security debt.
- **Secret engines are layered**: don't mount `kv-v2` inside another path; conflicts happen.
- **PKI CA discipline**: if using Vault/OpenBao as internal CA, set short cert TTLs (hours-days) + rotate intermediate regularly + cross-sign carefully.
- **Dynamic DB credentials**: require Vault-managed DB user with CREATE ROLE privilege. Each requester gets a fresh unique user.
- **Leases + revocation**: on compromise, revoke lease → all dynamically-created creds rescinded.
- **HA replication**: Raft storage is synchronous across nodes; writes require quorum. Performance hits on partitioned cluster.
- **Deleted secrets** in `kv-v2`: versions kept for a configurable period (default ~32). Permanent delete needs `destroy`.
- **UI is optional** — most production shops use CLI + API. UI is good for ad-hoc + exploration.
- **CLI name**: `bao` (not `vault`). Compatible flags otherwise.
- **Kubernetes integration**: Vault Agent patterns still work; Helm chart available.
- **Community governance**: OpenBao is under Linux Foundation / OpenSSF with open TSC. Governance docs on repo.
- **License**: **Mozilla Public License 2.0 (MPL-2.0)** — the pre-BSL Vault license.
- **Alternatives worth knowing:**
  - **HashiCorp Vault** (BSL) — same codebase origin; commercial + proprietary path
  - **Infisical** — modern open-source secrets platform (different architecture; separate recipe likely)
  - **Bitwarden Secrets Manager** — password-manager-adjacent; new
  - **AWS Secrets Manager** / **AWS Parameter Store** — cloud-native
  - **Azure Key Vault** — cloud-native
  - **GCP Secret Manager** — cloud-native
  - **Doppler** — SaaS secrets platform
  - **SOPS + age/PGP** — file-based; git-compatible; different paradigm
  - **CyberArk Conjur** — enterprise commercial
  - **Choose OpenBao if:** you want Vault's features + OSI-approved license + community governance.
  - **Choose Vault Enterprise if:** you need HashiCorp's commercial support + enterprise features (DR replication, etc.).
  - **Choose AWS/Azure/GCP native if:** cloud-only workload, no need for portability.
  - **Choose SOPS if:** you want git-native + simple + no running service.
  - **Choose Infisical if:** you want modern SaaS-or-self-host secrets platform with team UX.

## Links

- Repo: <https://github.com/openbao/openbao>
- Website: <https://openbao.org>
- Docs: <https://openbao.org/docs/>
- Installation: <https://openbao.org/docs/install/>
- Releases: <https://github.com/openbao/openbao/releases>
- Discussions: <https://github.com/openbao/openbao/discussions>
- Mailing list: <https://lists.openssf.org/g/openbao>
- Chat (Zulip): <https://linuxfoundation.zulipchat.com/>
- Security contact: <mailto:openbao-security@lists.openssf.org>
- HashiCorp Vault (BSL): <https://www.vaultproject.io>
- HashiCorp BSL license change context: <https://www.hashicorp.com/blog/hashicorp-adopts-business-source-license>
- Linux Foundation: <https://www.linuxfoundation.org>
- OpenSSF: <https://openssf.org>
- Infisical (alt): <https://infisical.com>
- SOPS (alt): <https://github.com/getsops/sops>

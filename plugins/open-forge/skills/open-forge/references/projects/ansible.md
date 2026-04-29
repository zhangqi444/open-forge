---
name: ansible-project
description: Ansible recipe for open-forge. GPL-3.0 IT automation (config management, app deployment, provisioning, ad-hoc execution). NOT a daemon — Ansible is an agentless CLI you install on a control host and point at managed nodes over SSH. This recipe covers upstream-blessed installs (pip, distro packages, `ansible-core` vs `ansible` community bundle), plus the two server-form products (AWX as the open-source upstream of Red Hat's Automation Platform, and Semaphore as a popular community UI). Self-host framing: if the user wants a "web UI for running playbooks," they want AWX or Semaphore, NOT `ansible` itself.
---

# Ansible

GPL-3.0 "radically simple IT automation." Upstream: <https://github.com/ansible/ansible>. Docs: <https://docs.ansible.com/ansible/latest/>.

**Important reframing.** Ansible is **not** a service you stand up and expect to hit on a port. It's an agentless CLI:

1. `pip install ansible` (or `apt install ansible`) on a **control host** (your laptop, a bastion, a CI runner).
2. Write a `playbook.yml` describing desired state.
3. Declare target hosts in an `inventory.ini` (or pull from a dynamic inventory plugin).
4. Run `ansible-playbook -i inventory.ini playbook.yml`.
5. Ansible SSHes to each target and executes Python / shell tasks idempotently. No agent; no open ports on targets beyond SSH.

That shifts the self-host framing. If the user asks to "self-host Ansible" they likely mean one of:

| Intent | What they actually want |
|---|---|
| "Install Ansible on my laptop to run playbooks" | Local install — pip or package manager. |
| "Web UI for triggering playbooks with audit log + RBAC" | **AWX** (upstream of Red Hat Ansible Automation Platform) OR **Semaphore UI** (community alternative). |
| "Host Ansible modules / collections / roles internally" | Private Automation Hub (commercial RHAAP) or a PyPI-compatible `ansible-galaxy` mirror. |
| "Run Ansible from CI" | GitHub Actions / GitLab CI pattern, not a self-host deploy. |

Ask before installing. Most of this recipe covers the CLI install; the AWX / Semaphore section at the end handles the "I want a UI" case.

## `ansible` vs `ansible-core`

Two PyPI packages from the same org:

- **`ansible-core`** — the engine + a handful of built-in plugins. ~40 MB install. Upstream-maintained.
- **`ansible`** — the "community bundle": `ansible-core` + ~100 community-curated collections (`community.general`, `community.docker`, `amazon.aws`, etc.). Larger install (hundreds of MB) but has the batteries included.

Most users want `ansible` (the community bundle). Only pick `ansible-core` if you explicitly manage which collections are installed via `ansible-galaxy collection install`.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `pip install ansible` (or `ansible-core`) | <https://pypi.org/project/ansible/> · <https://pypi.org/project/ansible-core/> | ✅ | Any OS with Python 3.10+. Upstream-preferred for latest version. |
| Distro packages (apt/dnf/pacman/brew) | See upstream install guide | ✅ | Auto-updates via OS; usually lags upstream by 1–2 minor versions. |
| `pipx install ansible` | <https://pipx.pypa.io/> | ✅ (community pattern) | Isolates Ansible from system Python. Recommended on user laptops. |
| Container image (`quay.io/ansible/ansible-runner`) | <https://github.com/ansible/ansible-runner> | ✅ | Reproducible CI / ephemeral execution environments. |
| AWX (web UI + API + DB) | <https://github.com/ansible/awx> | ✅ (upstream of commercial RHAAP) | "I want a web UI." Heavy (Kubernetes Operator-driven) deploy. |
| Semaphore UI | <https://github.com/semaphoreui/semaphore> | ⚠️ Community-maintained | Lightweight alternative to AWX. Single binary or Docker. Not in `ansible/*` org. |
| Ansible Tower / Red Hat Ansible Automation Platform | <https://www.redhat.com/en/technologies/management/ansible> | 💰 Commercial | Paid; out of scope for open-forge. |

Upstream installation guide: <https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html>.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| intent | "What's your goal — run playbooks from a CLI, or need a web UI?" | `AskUserQuestion`: `CLI install` / `Web UI (AWX / Semaphore)` / `CI-only` | Drives which section runs. Most users want the CLI path. |
| preflight | "Control host OS?" (Ansible runs on: Linux, macOS, WSL; NOT native Windows as control) | `AskUserQuestion`: `Linux` / `macOS` / `WSL` | Native Windows is NOT supported as a control host. Targets can be Windows (via WinRM / SSH), but you drive from a POSIX system. |
| preflight | "Python version on control host?" (Ansible needs 3.10+) | Auto-detect: `python3 -V` | If < 3.10, install via `pyenv` / `uv` / distro package. |
| package | `ansible` (bundle) or `ansible-core`?" | `AskUserQuestion`: `ansible (recommended)` / `ansible-core (minimal)` | Default `ansible` unless user explicitly manages collections. |
| ui | *Web UI path* "AWX or Semaphore?" | `AskUserQuestion`: `AWX (upstream / richer)` / `Semaphore (lighter)` / `Neither — stick to CLI` | AWX needs Kubernetes; Semaphore is a single binary. |

## Install — CLI (pip / pipx)

Upstream-preferred path.

### pipx (recommended on user laptops)

```bash
# Install pipx if missing
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# Install Ansible
pipx install --include-deps ansible

# Verify
ansible --version         # shows ansible-core version + config / collections paths
ansible-playbook --help
```

`--include-deps` is important: it makes CLI entry points for `ansible-playbook`, `ansible-galaxy`, `ansible-inventory`, `ansible-vault`, `ansible-config`, etc., all available in PATH.

### pip (in a venv)

```bash
python3 -m venv ~/.venvs/ansible
source ~/.venvs/ansible/bin/activate
pip install --upgrade pip
pip install ansible                   # or: pip install ansible-core
ansible --version
```

Activate the venv each session, or add `~/.venvs/ansible/bin` to PATH.

### Distro packages

| OS | Command | Notes |
|---|---|---|
| Debian/Ubuntu | `sudo apt install ansible` | Usually 1–2 versions behind upstream. PPA available: `sudo add-apt-repository ppa:ansible/ansible`. |
| Fedora/RHEL/CentOS | `sudo dnf install ansible` | EPEL required on RHEL/CentOS. |
| Arch | `sudo pacman -S ansible` | Generally current. |
| macOS | `brew install ansible` | Current. |
| Alpine | `apk add ansible` | Minimal; may not include `community.*` collections. |

### Container (ephemeral runs / CI)

```bash
docker run --rm -v "$(pwd):/work" -w /work \
  quay.io/ansible/ansible-runner:latest \
  ansible-playbook -i inventory.ini playbook.yml
```

Upstream also publishes `ansible-execution-env` images for the Automation Platform's Execution Environment model.

## Post-install: collections + roles

Ansible's actual functionality lives in **collections** (namespaced bundles of modules/plugins). The community bundle (`ansible`) ships with ~100 of them; anything else is a one-time install:

```bash
# From Ansible Galaxy (public registry)
ansible-galaxy collection install community.docker
ansible-galaxy collection install amazon.aws
ansible-galaxy collection install kubernetes.core

# From a private repo (git URL)
ansible-galaxy collection install git+https://internal.git/ansible-collections/mycol.git,main

# From a requirements file (preferred for repo-as-source-of-truth)
cat > requirements.yml <<EOF
collections:
  - name: community.docker
    version: ">=3.0.0,<4.0.0"
  - name: amazon.aws
EOF
ansible-galaxy collection install -r requirements.yml
```

Collections install under `~/.ansible/collections/` by default. Override with `ANSIBLE_COLLECTIONS_PATH`.

## Config files (the three you actually edit)

| File | Role |
|---|---|
| `ansible.cfg` | Project-local config. Overrides system defaults. `ANSIBLE_CONFIG` env points to a specific file. Precedence: `$ANSIBLE_CONFIG` > `./ansible.cfg` > `~/.ansible.cfg` > `/etc/ansible/ansible.cfg`. |
| `inventory.ini` (or `.yml`) | List of hosts + group vars. Can also be a directory of inventory plugins for dynamic (cloud) inventories. |
| `playbook.yml` | Your actual automation. Plays, tasks, handlers. |

Minimal `ansible.cfg` for a new project:

```ini
[defaults]
inventory = ./inventory.ini
host_key_checking = False       # for lab / dev only; NOT production
roles_path = ./roles
collections_paths = ./collections:~/.ansible/collections
forks = 20
stdout_callback = yaml           # human-readable output
retry_files_enabled = False
```

## Web UI — AWX

Upstream of Red Hat Ansible Automation Platform. Heavy: Kubernetes-only deploy (no longer supports docker-compose since v18). Deploy via the **AWX Operator**: <https://github.com/ansible/awx-operator>.

### When to use

- Team of >1 using Ansible, needs RBAC + audit log + scheduled runs.
- Already running Kubernetes (k3s, MicroK8s, or a full cluster).
- Comfortable with a ~30-container deploy.

### When NOT to use

- Solo user — a pipx install + git repo is simpler.
- No Kubernetes — AWX dropped docker-compose support. Semaphore fits better.
- Want a 5-minute setup — AWX is a day or two to understand.

### Install sketch

```bash
# 1. Prerequisite: a Kubernetes cluster (k3s works: https://k3s.io/)
curl -sfL https://get.k3s.io | sh -
sudo chown $USER:$USER /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 2. Install the AWX Operator
export NAMESPACE=awx
kubectl create namespace "$NAMESPACE"

# Pin to a specific AWX Operator release (check latest at
# https://github.com/ansible/awx-operator/releases)
AWX_OPERATOR_VERSION=2.19.0
kubectl apply -k "github.com/ansible/awx-operator/config/default?ref=${AWX_OPERATOR_VERSION}" \
  -n "$NAMESPACE"

# 3. Create an AWX custom resource (minimal — docs at https://ansible.readthedocs.io/projects/awx-operator/)
cat <<EOF | kubectl apply -n "$NAMESPACE" -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  service_type: nodeport
  nodeport_port: 30080
EOF

# 4. Watch it come up (takes ~5–10 min for images + DB + migrations)
kubectl get pods -n "$NAMESPACE" -w
```

Access: `http://<node-ip>:30080`. Admin password:

```bash
kubectl get secret awx-admin-password -n "$NAMESPACE" -o jsonpath="{.data.password}" | base64 -d
```

Full install guide: <https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/basic-install.html>.

## Web UI — Semaphore (lighter alternative)

Community-maintained, single Go binary or Docker container. Not in the `ansible/*` GitHub org — it's a third-party UI over Ansible. Upstream: <https://github.com/semaphoreui/semaphore>.

```bash
# Docker
docker run -d --name semaphore \
  -p 3000:3000 \
  -e SEMAPHORE_DB_DIALECT=bolt \
  -e SEMAPHORE_ADMIN_PASSWORD=changeme \
  -e SEMAPHORE_ADMIN_NAME=admin \
  -e SEMAPHORE_ADMIN_EMAIL=admin@example.com \
  -e SEMAPHORE_ADMIN=admin \
  -v semaphore_data:/etc/semaphore \
  semaphoreui/semaphore:latest
```

Then `http://localhost:3000` — admin / `changeme`. Much simpler than AWX for small teams. (A full Semaphore recipe would live at `semaphore.md` if someone adds it to the selfh.st list.)

## Upgrade

### CLI

```bash
# pipx
pipx upgrade ansible

# pip / venv
pip install --upgrade ansible

# apt
sudo apt update && sudo apt upgrade ansible

# Collections
ansible-galaxy collection install -U -r requirements.yml
```

### AWX

Upgrade the operator first, then the AWX CR reconciles to the new version. Always take a DB backup first — the operator supports a `backup` CRD:

```bash
cat <<EOF | kubectl apply -n awx -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: pre-upgrade
spec:
  deployment_name: awx
EOF
```

## Gotchas

- **Ansible is not a daemon.** No port, no container by default. `apt install ansible` does NOT start a service. If someone expects "after install, I can hit http://host:XXXX," they want AWX or Semaphore.
- **Windows is a target, not a control host.** You can manage Windows boxes with `ansible.windows.*` modules (WinRM or SSH), but you run Ansible itself from Linux / macOS / WSL.
- **Python on the TARGET matters too.** Most modules need Python 3 on the managed host. `raw` and `win_*` modules are exceptions. New minimal hosts (Alpine, stripped VMs) may need `ansible_python_interpreter: /usr/bin/python3` in host vars.
- **`ansible-core` ≠ `ansible`.** Installing `ansible-core` and wondering where `community.general.htpasswd` went? You need to install the collection: `ansible-galaxy collection install community.general`.
- **AWX Operator requires Kubernetes.** Docker-compose was dropped after v17. On a single-node LAN box, run k3s or MicroK8s. If the user refuses k8s, point them at Semaphore.
- **`host_key_checking = False` is a lab convenience, not a production setting.** In production, manage known_hosts properly — turning off host-key checks opens you to MITM on first connect.
- **Secrets in playbooks → `ansible-vault`.** Never commit plaintext passwords. `ansible-vault create secrets.yml` / `encrypt` / `view` / `edit`. Password goes in `~/.vault_pass` or env `ANSIBLE_VAULT_PASSWORD_FILE`.
- **Inventory plugins for cloud targets.** Static `inventory.ini` is fine for a handful of known hosts. For AWS / GCP / Azure / dynamic fleets, use inventory plugins (`amazon.aws.aws_ec2`, `google.cloud.gcp_compute`, `azure.azcollection.azure_rm`).
- **Running Ansible "from inside a playbook" (meta-automation).** Technically possible (`ansible.builtin.shell: ansible-playbook …`) but usually a sign you wanted an `include_tasks` / `import_playbook` / roles instead. Ask before nesting.
- **PPA on Ubuntu is usually more current** than the default Ubuntu archive. If latest features matter, `add-apt-repository ppa:ansible/ansible`.
- **`ansible.cfg` location precedence.** Editing `/etc/ansible/ansible.cfg` but running from a project dir with its own `./ansible.cfg` → your system-wide edits are shadowed. `ansible --version` shows which config file is active.
- **Don't install Ansible with sudo unless you mean it.** `sudo pip install ansible` clutters system Python. Use pipx or a venv.

## Upstream references

- Repo: <https://github.com/ansible/ansible>
- Docs: <https://docs.ansible.com/ansible/latest/>
- Installation guide: <https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html>
- Release schedule: <https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html>
- Ansible Galaxy (collections registry): <https://galaxy.ansible.com/>
- AWX repo: <https://github.com/ansible/awx>
- AWX Operator: <https://github.com/ansible/awx-operator>
- AWX Operator docs: <https://ansible.readthedocs.io/projects/awx-operator/>
- Semaphore UI: <https://github.com/semaphoreui/semaphore>
- Forum: <https://forum.ansible.com/>

## TODO — verify on first deployment

- Confirm `ansible` community bundle still ships the default collections user expects; upstream has trimmed the bundle in past releases.
- Verify AWX Operator install path against current operator version (CR schema has evolved).
- If user has an existing Ansible-Tower-era docker-compose setup, document the migration-to-operator path (upstream's docs cover this).
- Check whether Red Hat has open-sourced the Execution Environment builder toolchain further since this recipe was written.

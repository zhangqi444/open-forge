---
name: credentials
description: How the skill asks for credentials safely — five patterns prioritized from "secret never enters chat" to "last-resort paste with explicit risk acknowledgement." Loaded by SKILL.md § Asking for credentials. Applies to API keys, SSH keys, DB passwords, OAuth client secrets, cloud account creds, anything sensitive.
---

# Credentials module — five patterns, prioritized

Pasting raw credentials into Claude Code is risky:

- The secret enters the session history (visible to other tools loaded in the same session, may persist in logs).
- May be relayed via MCP servers depending on the user's setup.
- Shows up in transcripts the user might later share for support.
- Some terminals / IDEs persist input across restarts.

The skill defaults to safer patterns. Direct chat paste is **last resort** and only after explicit risk acknowledgement.

**Hard rule:** every time the skill needs a sensitive input, it offers the user the five patterns below — letting them pick — and surfaces the risk if they pick paste. Don't silently accept a paste; don't pretend Claude Code is a vault.

---

## The five patterns (priority order)

### 1. Local file path (recommended for personal use)

User stores the secret in a file under their home directory; tells the skill the path; skill reads via `cat`.

**When to suggest first:** for one-off API keys (Resend, SendGrid, Mailgun, OpenAI, Anthropic, etc.) that the user already has in a `.env`, `.secrets`, or password-manager export.

**Skill prompt:**

> *"Path to a file containing the key (e.g. `~/.secrets/resend`)? I'll read it via `cat`."*

**Skill execution:**

```bash
RESEND_KEY=$(cat ~/.secrets/resend)   # or however the user names it
# Use $RESEND_KEY in subsequent commands; never echo it back to the user
```

**Properties:**

- Secret never enters chat.
- File survives across Claude Code sessions; user can use the same path next time.
- User is responsible for the file's permissions (`chmod 600` recommended; mention if the file's mode is `644` or wider).

---

### 2. Environment variable name (recommended for shell users)

User exports the secret as an env var **before** starting Claude Code (or in their shell `rc`); tells the skill the var name.

**When to suggest first:** when the user already has secrets in a `.envrc` / `.bashrc` / `~/.config/fish/config.fish` they `source` regularly.

**Skill prompt:**

> *"Name of an env var holding the key (e.g. `RESEND_API_KEY`)? I'll read `$RESEND_API_KEY` from my shell."*

**Skill execution:**

```bash
# Verify the var exists in Claude's shell
test -n "$RESEND_API_KEY" || { echo "RESEND_API_KEY not set; export it before continuing"; exit 1; }
# Use it
curl ... -H "Authorization: Bearer $RESEND_API_KEY" ...
```

**Properties:**

- Secret never enters chat.
- Session-scoped if exported in the current shell only; persistent if in `rc` files.
- The env var **must** exist in the shell Claude Code launched from. If the user `export`s after Claude Code starts, Claude won't see it (you'll need them to restart Claude Code or pass it inline).

---

### 3. Cloud-CLI session auth (default for AWS / GCP / Azure / GitHub)

User authenticates the cloud CLI ahead of time (e.g. `aws sso login`, `gcloud auth application-default login`, `az login`, `gh auth login`); skill uses the resulting profile / session.

**When to suggest first:** any time the credential is for a cloud account that ships its own CLI auth flow. Don't ask for raw cloud access keys if SSO / browser auth is available.

| Provider | Pre-skill setup | What skill uses |
|---|---|---|
| AWS | `aws sso login --profile <name>` (or `aws configure` for static keys) | `aws --profile <name> ...` |
| GCP | `gcloud auth application-default login` + `gcloud config set project <id>` | `gcloud` / `gsutil` / Terraform default-application-credentials |
| Azure | `az login` | `az ...` (uses cached session) |
| GitHub | `gh auth login` | `gh ...` (uses stored token, scoped) |
| DigitalOcean | `doctl auth init` | `doctl ...` |
| Hetzner | `hcloud context create` | `hcloud --context <name> ...` |
| Cloudflare | `wrangler login` | `wrangler ...` |

**Skill prompt:**

> *"Have you run `aws sso login` for the profile you want to use? If yes, what's the profile name?"*

**Properties:**

- No secret material in chat or in any file the skill reads.
- Auth is browser-mediated, MFA-friendly.
- Sessions expire (good — bounded blast radius); skill handles re-auth gracefully if the session lapses mid-deploy.

---

### 4. Secrets-manager reference (advanced)

User stores secrets in 1Password / Bitwarden / Vault / AWS Secrets Manager / GCP Secret Manager; gives the skill a CLI-resolvable reference; skill calls the secret-manager CLI to fetch only when needed.

**When to suggest first:** when the user mentions they "have it in 1Password" or similar; or for users with proper secret-management practices.

| Secret manager | Reference shape | Skill execution |
|---|---|---|
| 1Password | `op://Personal/Resend/api-key` | `op read 'op://Personal/Resend/api-key'` |
| Bitwarden | item name + field | `bw get password '<item-name>'` |
| HashiCorp Vault | `secret/data/<path>#<field>` | `vault kv get -field=<field> secret/<path>` |
| AWS Secrets Manager | secret name + JSON key | `aws secretsmanager get-secret-value --secret-id <name> --query SecretString --output text \| jq -r .<key>` |
| GCP Secret Manager | resource name | `gcloud secrets versions access latest --secret=<name>` |
| `pass` (Linux) | path | `pass <path>` |

**Skill prompt:**

> *"1Password / Bitwarden / Vault reference? I'll fetch via the matching CLI when I need it."*

**Properties:**

- Secret never enters chat or any persistent file.
- Resolved just-in-time; not cached in shell vars longer than necessary.
- User must have the matching CLI installed + authenticated.

---

### 5. Direct chat paste (last resort — risk acknowledgement required)

User types the secret directly into chat. Skill **must** surface the risks before accepting.

**When this happens:** user explicitly says they want to paste, or none of patterns 1-4 work for their situation (e.g. they're trying out the skill with a one-shot key and don't want to set up file storage).

**Required risk acknowledgement (paraphrase, don't elide):**

> *"⚠️ If you paste the key here, it will live in this Claude Code session's history. It may also be visible to other tools loaded in the session and could appear in any transcripts you share later for support. After this deploy completes, I'll remind you to rotate the key in the provider's dashboard. Still want to paste? (yes / pick a safer path)"*

**If user confirms:**

- Accept the paste.
- Use the value immediately; don't echo it back.
- At the end of the deploy, surface a reminder: *"You pasted `<provider>` API key into chat earlier. Rotate it in `<provider's dashboard URL>` now that the deploy is complete."*

**Properties:**

- Convenient but contaminates session history.
- The rotation reminder is mandatory — without it, the user may forget the key is exposed.

---

## Per-credential-class recommendations

Different credential types pair best with different patterns. Surface the recommendation when the credential class is known.

| Credential class | Default suggestion | Alternative |
|---|---|---|
| **API keys** (Resend, SendGrid, OpenAI, etc.) | Pattern 1 (file path) or 2 (env var) | Pattern 4 (secrets manager) |
| **AWS / GCP / Azure / GH cloud auth** | Pattern 3 (CLI session) | Pattern 4 if user prefers explicit secret refs |
| **SSH keys** (cloud instance auth) | The path itself is what skill needs (not the contents — never the contents). Pattern 1, but specifically the file is the key file (`~/.ssh/id_ed25519`); skill uses `ssh -i <path>` | n/a — never accept SSH key contents pasted into chat |
| **DB passwords** | Pattern 1, 2, or 4 | Pattern 5 only if it's a one-shot generated password the user is about to throw away anyway |
| **OAuth client secrets** | Pattern 4 (long-lived; should be vaulted) | Pattern 1 with `chmod 600` |
| **Random secrets generated for the deploy** (`openssl rand -hex 32` etc.) | Generate inline; never echo to user; store in the state file or pass directly to the upstream tool | n/a |

---

## Skill prompt template

When the skill reaches a phase that needs a credential, use this template:

```
[Phase: <smtp / provision / etc.>] I need <credential class>.

Pick how to provide it:

  1. **File path** — paste the path to a file containing the secret (e.g. `~/.secrets/resend`)
  2. **Env var name** — paste the name of an env var I should read (e.g. `RESEND_API_KEY`)
  3. **Cloud-CLI session** — say which profile / context if you've already done `<provider> login`
  4. **Secrets-manager ref** — paste a `op://`, `vault://`, `bw://`, etc. reference
  5. **Paste directly** — least safe; key enters chat history; you'll be reminded to rotate after

Which? (default: 1 if you have a file, 2 if you exported an env var)
```

After the user picks, validate before proceeding:

- File path → `test -r <path>` first; refuse if mode is wider than 600 (offer to `chmod 600`).
- Env var → `test -n "$<NAME>"`; refuse if empty.
- Cloud-CLI session → run a smoke command (`aws sts get-caller-identity --profile <name>`); refuse if it errors.
- Secrets-manager ref → run a smoke command (`op read --no-newline <ref>` etc.); refuse if it errors or empty.
- Paste → require the risk acknowledgement before accepting.

---

## End-of-deploy: rotation reminders

If the user picked pattern 5 (direct paste) for any credential during the deploy, surface a rotation reminder during the `hardening` phase:

```
[Hardening] Rotation reminder — you pasted these keys into chat during this deploy:

  • Resend API key (used in smtp phase)  → rotate at https://resend.com/api-keys
  • <other-provider> key                 → rotate at <provider's dashboard URL>

Pasted secrets remain in this Claude Code session's history. Rotating now means
even if the session leaks later, the keys are already invalid.
```

If the user picked patterns 1-4 for everything, no rotation reminder is needed (the secrets never entered chat).

---

## Failure modes

- **User insists on pasting "to keep it simple."** Respect their consent after risk acknowledgement, but surface the rotation reminder twice (once mid-deploy, once at hardening).
- **User pastes by accident** (meant to paste a path, pasted the key itself). Detect via key-shape regex (`re_[A-Za-z0-9_]+`, `sk-ant-`, `AKIA[0-9A-Z]{16}`, etc.); if a paste looks like a key when the prompt expected a path, stop and ask: *"That looks like the key itself, not a path. Did you mean to paste the key directly? (if so, see risks above; if not, paste the path)."*
- **Env var not present in Claude's shell.** User exported it after starting Claude Code. Ask them to restart Claude Code with the var set, or fall back to a different pattern.
- **File mode is too permissive** (e.g. `0644`). Refuse to read; offer to run `chmod 600 <path>` first.
- **Secrets-manager CLI not installed.** Detect via `command -v op` etc.; if missing, fall back to a different pattern, don't try to install a secret manager mid-deploy.
- **CLI session expired mid-deploy.** Common with AWS SSO. Skill detects the expiry, says *"AWS session expired; please re-run `aws sso login --profile <name>` and tell me when ready."*, then resumes from the failed phase.

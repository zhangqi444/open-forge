---
name: feedback
description: Post-deploy feedback module — sanitization rules + draft templates + submission paths for the three GitHub-issue input channels (recipe-feedback / software-nomination / method-proposal). Loaded by SKILL.md § Post-deploy feedback.
---

# Feedback module — drafting + submitting GitHub issues

This module is loaded after a deploy completes (or is abandoned) when the user opts in to share what they learned. Implements the multi-step consent flow described in CLAUDE.md § *Sanitization principles* and SKILL.md § *Post-deploy feedback*.

**Hard rule:** never post without showing the redacted draft + getting explicit "yes" from the user. The skill is the user's submitter; consent gates everything.

---

## Sanitization checklist

Apply BEFORE drafting. Scan the deployment session — including chat transcript, any tool outputs Claude has in context, any state-file references — and replace identifiers per the table.

### Strip-list (regex patterns + replacements)

| Class | Detection | Replacement |
|---|---|---|
| **Domains** (apex, www, admin) | Anything matching the user's `${CANONICAL_HOST}` / `${APEX}` / `${ADMIN_DOMAIN}` collected during inputs, plus generic FQDNs in URL paths the user typed | `${CANONICAL_HOST}` / `${APEX}` / `${ADMIN_DOMAIN}` |
| **Public IPv4** | `\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b` (excluding RFC-1918 ranges if you want to allow them as `${PRIVATE_IP}`) | `${PUBLIC_IP}` |
| **Private IPv4** | `\b(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)[0-9.]+\b` | `${PRIVATE_IP}` (or strip if it leaks network topology) |
| **IPv6** | Standard IPv6 patterns | `${PUBLIC_IPV6}` / `${PRIVATE_IPV6}` |
| **SSH key paths** | Anything matching `~/.ssh/[^ ]+`, `/home/[^/]+/\.ssh/[^ ]+`, `*.pem`, `*.priv`, `id_(rsa|ed25519|ecdsa)` | `${KEY_PATH}` |
| **SSH key contents** | `-----BEGIN [A-Z ]+ KEY-----` blocks | `<REDACTED-SSH-KEY>` |
| **Resend API key** | `re_[A-Za-z0-9_]+` | `<REDACTED-RESEND-KEY>` |
| **SendGrid API key** | `SG\.[A-Za-z0-9._-]+` | `<REDACTED-SENDGRID-KEY>` |
| **OpenAI API key** | `sk-[A-Za-z0-9]{20,}` | `<REDACTED-OPENAI-KEY>` |
| **Anthropic API key** | `sk-ant-[A-Za-z0-9_-]{20,}` | `<REDACTED-ANTHROPIC-KEY>` |
| **Slack tokens** | `xox[bp]-[A-Za-z0-9-]+` | `<REDACTED-SLACK-TOKEN>` |
| **GitHub PAT** | `ghp_[A-Za-z0-9]{36}` / `github_pat_[A-Za-z0-9_]+` | `<REDACTED-GH-PAT>` |
| **AWS access key ID** | `AKIA[0-9A-Z]{16}` | `<REDACTED-AWS-KEY>` |
| **AWS secret key** | After `aws_secret_access_key`, 40-char base64 | `<REDACTED-AWS-SECRET>` |
| **AWS account ID** | 12 consecutive digits in AWS context (ARN, account-id field) | `${AWS_ACCOUNT}` |
| **AWS profile name** | Whatever the user collected as `aws_profile` during inputs | `${AWS_PROFILE}` |
| **GCP service-account JSON** | `"type": "service_account"` blocks | `<REDACTED-GCP-SA>` |
| **Generic Bearer token** | `Bearer [A-Za-z0-9._~+/=-]{20,}` | `<REDACTED-BEARER>` |
| **Email addresses** | RFC-822 pattern; especially the LE email + SMTP from-address + any user identity email | `${EMAIL}` |
| **State-file contents** | Anything from `~/.open-forge/deployments/<name>.yaml` raw | Reference by deployment name only, never paste contents |
| **MySQL/Postgres password** | After `password=` / `--password ` / `IDENTIFIED BY ` | `<REDACTED-DB-PASSWORD>` |
| **OAuth client secrets** | After `client_secret` / `CLIENT_SECRET` | `<REDACTED-CLIENT-SECRET>` |
| **Random bytes from `openssl rand -hex N`** that the user generated as a secret | Long hex strings used as secrets | `<REDACTED-RANDOM-SECRET>` |

### Manual review pass (after regex)

After regex-based sanitization, do a final read-through looking for:

- **Hostnames in URL paths** that contain the user's domain (sed/regex may have missed embedded URLs).
- **Username conventions** that are personally identifiable (e.g. `qi-experiment` as an AWS profile).
- **Stack-trace lines** containing absolute filesystem paths (`/home/<user>/...`).
- **Anything pasted from the user's clipboard or env vars** that wasn't covered by the strip-list.

If you can't confidently classify something as safe, **redact it** — the user's final review is a safety net, not the only line of defense.

### What you may keep

| Class | OK to keep | Why |
|---|---|---|
| Recipe filenames (`ghost.md`, `openclaw.md`) | ✅ | Public; needed for context |
| Plugin version (`0.20.0`) | ✅ | Public; needed for triage |
| Combo names (`Ghost-CLI on Ubuntu`, `DigitalOcean droplet`) | ✅ | Public; needed for context |
| Generic error messages quoted from upstream tools | ⚠️ | OK if no identifiers; redact paths and IPs from stack traces |
| `${VAR}` placeholders | ✅ | These are the redactions; they're fine |
| Public repo URLs (upstream docs you're proposing to add) | ✅ | Public |

---

## Draft templates

Each template renders into the matching `.github/ISSUE_TEMPLATE/*.yml` form. The structure mirrors the form fields so the user pastes the body and the form auto-validates the sanitization checkboxes.

### Channel 1 — recipe feedback (default at end of deploy)

```markdown
**Recipe**: <recipe-filename>
**Combo**: <infra adapter> / <runtime>
**Plugin version**: <version-from-plugin.json>
**Outcome**: <one-of: Deploy succeeded with notes / Deploy succeeded after retries / Deploy failed; recovered manually / Deploy failed; abandoned / Recipe was outdated>

## What the recipe missed

<Concrete description: what surprised you, what failed, what required manual intervention. Sanitized.>

## Suggested edit (optional — diff format preferred)

```diff
@@ <section header from the recipe> @@
- <line that was wrong / missing>
+ <line that should be there>
```

## Sanitization confirmation
- [x] All domains, IP addresses, SSH key paths, API keys, AWS account IDs, and email addresses stripped from this issue body.
- [x] I understand this issue is public and permanent. I grant a non-revocable license to use this content in the open-forge recipe.
```

### Channel 2 — software nomination (Tier 2 → Tier 1)

```markdown
**Software name**: <project>
**Upstream repo**: <github URL>
**Upstream install-method index**: <docs / repo path / wiki URL>
**Intended deploy combo**: <infra> / <runtime>

## Why Tier 1?

<What's painful about this software's install that compounds across deploys?
Per the demand-driven graduation criteria in CLAUDE.md, a Tier 1 recipe earns
its keep when the captured tribal knowledge saves the next user real pain.>

## In-scope check (per CLAUDE.md § Is this software in scope?)

This software is: <one-of: deployable service / static-site generator / AI inference server / CI runner / storage backend / not sure>

## Confirmation
- [x] I have read the *Is this software in scope?* and *Demand-driven graduation criteria* sections in CLAUDE.md.
- [x] This software has at least one upstream-documented install method or canonical install artifact in-repo.
```

### Channel 3 — method proposal

```markdown
**Recipe to extend**: <recipe-filename>
**Method name**: <e.g. "Snap package", "Helm chart">
**Upstream URL documenting this method**: <URL>
**Source type**: <First-party — published by upstream / Community-maintained>

## Canonical install command(s)

```bash
<paste verbatim from upstream>
```

## Why this method matters

<When would a user pick this method over the existing options in the recipe?>

## Confirmation
- [x] I have verified the upstream URL above shows this install method on the current upstream version.
- [x] No credentials, IPs, or other identifiers in this issue.
```

---

## Submission paths (try in order)

The skill never opens a browser silently or POSTs without explicit user confirmation. Three submission paths in priority order:

### 1. `gh` CLI (preferred when available)

```bash
# Check if gh is authenticated for the right account
gh auth status

# If yes, submit
gh issue create \
  --repo zhangqi444/open-forge \
  --title "<title from template>" \
  --body-file /tmp/feedback-draft.md \
  --label recipe-feedback,recipe:<name>
```

Strengths: works headlessly in chat; respects user's existing GitHub auth.

Caveats: user must have `gh` installed + authenticated. If `gh auth status` errors, fall through to path 2.

### 2. GitHub MCP server (if available)

If `mcp__github__issue_write` is available in the tool list, use it:

```
mcp__github__issue_write({
  method: "create",
  owner: "zhangqi444",
  repo: "open-forge",
  title: "<title>",
  body: "<full body>",
  labels: ["recipe-feedback", "recipe:<name>"]
})
```

Strengths: no `gh` install needed; uses the MCP server's auth.

Caveats: only works if the MCP server is configured with appropriate scopes.

### 3. Prefilled URL (always-available fallback)

When neither `gh` nor the GitHub MCP works, generate a URL the user opens in a browser:

```
https://github.com/zhangqi444/open-forge/issues/new?template=recipe-feedback.yml&title=<URL-encoded-title>&body=<URL-encoded-body>
```

Print the URL in chat with the instruction:

> *"I can't post for you in this environment. Open this URL in a browser, review one more time, and click Submit:*
>
> *<URL>*
>
> *The form has the same sanitization checkboxes from the template — they'll be checked based on what you've already confirmed in chat."*

URL-encode the title + body. GitHub URL length limit is ~8 KB total; if the body is longer, truncate the body and put the rest in a `<details>` block (or warn the user to paste it manually).

---

## Liability + license boilerplate (paste at end of every issue body)

Append this exact block as the final paragraph of every issue body before submission:

```markdown
---

> By submitting this issue, I grant a non-revocable license to the open-forge project to use this content in recipes and documentation. The open-forge project bears no liability for my choice to share. I have reviewed the issue body for credentials and personal information per CLAUDE.md § *Sanitization principles*.
```

This is in addition to the checkboxes in the issue-template form — it's an extra paper trail in the issue body itself.

---

## When the deploy aborted before completion

If the user wants to file feedback about a deploy that failed mid-phase (e.g. preflight passed, provisioning failed at the security-group step), the `Outcome` field should be *"Deploy failed; abandoned"* and the body should include:

- Which phase failed.
- What the error was (sanitized — strip stack traces of paths/IPs).
- What workaround the user attempted (if any).
- Whether the user wants the recipe edited to handle this case, or whether they think it was an upstream / cloud-account issue (out of recipe scope).

These are often the highest-value feedback issues — they catch recipes that succeed in the maintainer's environment but fail in others.

---

## Failure modes to watch for

- **User says "post it" too quickly.** Respect their consent, but flag any line you weren't 100% sure about: *"Posting now. One last thing — line 14 mentions a username `qi-experiment` that might be your AWS profile name. Was that intentional?"*
- **Drafts that quote upstream error messages with embedded user data.** Common with Bitnami's `bncert-tool` output, AWS CLI errors quoting account IDs in ARNs.
- **State-file leaks.** If the user asks Claude to read `~/.open-forge/deployments/<name>.yaml` while drafting, do **not** paste contents — reference by deployment name only.
- **Multiple rapid yes-clicks.** If the user says "yes, yes, yes, post" to skip the review, slow down: re-show the draft once, get confirmation, then submit. Speed is not a user safety feature.

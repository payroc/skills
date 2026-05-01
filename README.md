# Payroc Skills

AI agent skills for developers integrating with Payroc payment APIs — compatible with Claude Code, Cursor, and any Agent Skills-compatible tool.

[Documentation](https://docs.payroc.com) · [Getting Started](#prerequisites) · [Feedback](#feedback)

---

## Prerequisites

- A Payroc account with API credentials
- An AI coding assistant (Claude Code, Cursor, or any Agent Skills-compatible tool)

---

## Install

> Payroc Skills are not yet listed on the Claude Code or Cursor marketplaces. Install using the Skills CLI below.

**Claude Code**

```bash
npx skills add payroc/skills --agent claude-code
```

**Cursor**

```bash
npx skills add payroc/skills --agent cursor
```

**Any Agent**

```bash
npx skills add payroc/skills
```

---

## What happens after install

When you ask _"help me board a new merchant,"_ your assistant:

1. Loads the matching skill (e.g. `boarding`)
2. Follows Payroc API conventions to construct the correct request
3. Guides you through authentication, error handling, and response parsing

---

## Plugins

| Plugin | Description | Covers |
|--------|-------------|--------|
| **boarding** | Merchant boarding and onboarding flows | MID provisioning, merchant registration, underwriting |
| **transaction** | Payment transaction integration | Authorizations, captures, voids, refunds, tokenization |
| **funding** | Funding and settlement integration | Settlement batches, funding reports, reconciliation |
| **reporting** | Reporting and analytics integration | Transaction reports, statements, dispute management |

---

## Example prompts

- "Help me board a new merchant via the Payroc API"
- "Process a payment authorization with tokenized card data"
- "Pull a funding report for yesterday's settlements"
- "Generate a transaction report for the last 30 days"

---

## Feedback

Found a bug or have a feature request? [Open an issue](https://github.com/payroc/skills/issues) on GitHub.

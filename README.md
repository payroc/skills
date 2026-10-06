# Payroc Skills

Skills that teach AI coding tools how to integrate with the Payroc payment APIs. Once they're installed, your AI tool follows Payroc's conventions for authentication, request formats and error handling when it writes your integration code.

[Documentation](https://docs.payroc.com) · [Supported tools](#supported-tools) · [Install](#install) · [Feedback](#feedback)

---

## Supported tools

Installation depends on your tool. Find your tool here, then follow the matching section under [Install](#install).

| Tool | How to install |
|------|----------------|
| Claude Code | [Plugin marketplace](#claude-code) |
| Codex | [Plugin marketplace](#codex) |
| GitHub Copilot CLI | [Plugin marketplace](#github-copilot-cli) |
| Cursor | [Skills CLI](#cursor-github-copilot-in-vs-code-gemini-cli-and-other-tools) |
| GitHub Copilot in VS Code | [Skills CLI](#cursor-github-copilot-in-vs-code-gemini-cli-and-other-tools) |
| Gemini CLI | [Skills CLI](#cursor-github-copilot-in-vs-code-gemini-cli-and-other-tools) |
| Other tools that support Agent Skills, such as OpenCode, Windsurf, Cline, Kiro, Junie, Goose, and Amp | [Skills CLI](#cursor-github-copilot-in-vs-code-gemini-cli-and-other-tools) |

Payroc Skills are not currently listed in any tool's built-in marketplace. Every method below installs directly from this GitHub repository.

---

## Before you start

You need:

- A Payroc account with API credentials. Sign up at https://developers.payroc.com.
- One of the tools above, already installed
- For the Skills CLI method only: [Node.js](https://nodejs.org), which provides the `npx` command

### Terminal or chat?

The steps below happen in one of two places, and each step says which:

- **Your terminal.** Command Prompt or PowerShell on Windows, Terminal on macOS or Linux. You type the command and press Enter.
- **Your AI tool's chat.** The box where you type requests to your AI tool.

Every install command runs in your terminal. You only use the chat once the skills are installed.

---

## Plugins

The skills come in six plugins:

| Plugin | What it covers |
|--------|----------------|
| `boarding` | Merchant platforms, processing accounts, pricing intents, attachments, terminal orders |
| `transaction` | Card sales, pre-authorizations, 3-D Secure, refunds, ACH payments, bank account verification, saved payment methods, single-use tokens, subscriptions and payment plans, Hosted Fields, hosted payment pages, payment links, Apple Pay, Google Pay, Payroc Cloud, EBT balance checks, card lookups |
| `funding` | Funding recipients, sending funds to merchants, funding balances and activity |
| `reporting` | Settlement batches, settled transactions, authorizations, ACH deposits, disputes |
| `notifications` | Event subscriptions (webhooks) for status changes |
| `migrations` | Porting an existing IBX gateway integration to the Payroc API |

With the plugin marketplace method, you install the plugins you need one at a time. The Skills CLI method installs all of them at once.

---

## Install

### Claude Code

**In your terminal**, add the Payroc marketplace (this repository). You only do this once:

```bash
claude plugin marketplace add payroc/skills
```

**In your terminal**, install a plugin. This example installs `transaction`:

```bash
claude plugin install transaction@payroc-skills
```

Repeat that command for each plugin you want, swapping `transaction` for the plugin name. Then restart Claude Code.

If the first command fails with "blocked by enterprise policy", your company controls which marketplaces Claude Code can use. Ask your administrator to allow `payroc/skills`, or use the [Skills CLI](#cursor-github-copilot-in-vs-code-gemini-cli-and-other-tools) instead.

### Codex

**In your terminal**, add the Payroc marketplace (this repository). You only do this once:

```bash
codex plugin marketplace add payroc/skills
```

**In your terminal**, install a plugin. This example installs `transaction`:

```bash
codex plugin add transaction@payroc-skills
```

Repeat that command for each plugin you want, swapping `transaction` for the plugin name. Then start a new Codex session.

### GitHub Copilot CLI

**In your terminal**, add the Payroc marketplace (this repository). You only do this once:

```bash
copilot plugin marketplace add payroc/skills
```

**In your terminal**, install a plugin. This example installs `transaction`:

```bash
copilot plugin install transaction@payroc-skills
```

Repeat that command for each plugin you want, swapping `transaction` for the plugin name. Then start a new Copilot session.

### Cursor, GitHub Copilot in VS Code, Gemini CLI and other tools

These tools use the [Skills CLI](https://github.com/vercel-labs/skills), which copies every Payroc skill into your project.

**In your terminal**, go to your project folder:

```bash
cd path/to/your/project
```

**In your terminal**, run the command for your tool:

| Tool | Command |
|------|---------|
| Cursor | `npx skills add payroc/skills --agent cursor -y` |
| GitHub Copilot in VS Code | `npx skills add payroc/skills --agent github-copilot -y` |
| Gemini CLI | `npx skills add payroc/skills --agent gemini-cli -y` |
| Any other tool | `npx skills add payroc/skills` (it asks which tool and which skills you want) |

The skills go into a `.agents/skills` folder inside your project. To install them for every project instead, add `--global` to the end of the command. Then restart your tool, or open a new chat.

---

## Use the skills

**In your AI tool's chat**, ask for what you want in plain English. Your tool loads the matching skill by itself. For example:

- "Help me board a new merchant via the Payroc API"
- "Show me the settled transactions in a Payroc settlement batch"
- "Port our IBX integration to the Payroc API"

---

## Update

Each skill checks for a newer published version when it runs and tells you if one is available. To pick up the latest at any time, run the commands for your tool.

**Claude Code**, in your terminal:

```bash
claude plugin marketplace update payroc-skills
claude plugin update transaction@payroc-skills
```

Run the second command once for each plugin you installed, then restart Claude Code.

**Codex**, in your terminal:

```bash
codex plugin marketplace upgrade
```

**GitHub Copilot CLI**, in your terminal:

```bash
copilot plugin marketplace update payroc-skills
copilot plugin update transaction@payroc-skills
```

Run the second command once for each plugin you installed.

**Skills CLI**, in your terminal, from your project folder:

```bash
npx skills update
```

---

## Feedback

Found a bug or have a feature request? [Open an issue](https://github.com/payroc/skills/issues) on GitHub.

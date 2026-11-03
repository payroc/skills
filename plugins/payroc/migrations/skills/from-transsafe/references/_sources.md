# References — source manifest

This skill answers from the local `references/` files below. Nothing is fetched live at runtime. To
refresh a file, regenerate it from the current analysis and update the "Last synced" date here and in
the file's own header.

Last synced: **2026-10-08** for every mapping file except the ten the table dates 2026-11-03 (host and test-environment wording); `identity-call.md` was last synced 2026-11-03.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `map-protocol-auth-and-results.md` | — (see note below) | 2026-11-03 | `legacy-migration-analysis` |
| `identifier-translation.md` | — | 2026-10-08 | `legacy-migration-analysis` |
| `map-card-transactions.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-tokens-vault-and-customers.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-recurring.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-paypages.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-boarding.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-batch-and-reporting.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-gift-ebt-check-altpay.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-users-and-merchant-config.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-v1-delta.md` | — | 2026-10-08 | `legacy-migration-analysis` |
| `no-equivalent-register.md` | — | 2026-11-03 | `legacy-migration-analysis` (compiled from the files above) |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-11-03 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied or curated directly;
`legacy-migration-analysis` = Payroc's own operation-by-operation mapping between a legacy
Payroc-owned gateway and the Payroc API.

## Why these rows carry no Source URL

The other skills in this repository document a single API and cite the page that documents it. A
migration reference has no such page: it is a *comparison* of two platforms. TranSafe publishes a REST
reference, but it covers only part of what an integration can call (see "Visibility labels" below), it
says nothing about the Payroc side, and it does not always describe what the platform actually does. So
the mapping is Payroc's own analysis rather than a curated copy of anything, and there is no honest URL
to put in that column.

What replaces the URL is **per-row confidence**. Every mapping row keyed by a TranSafe call or field
carries a `C` badge (lookup tables, such as the status and frequency lists, do not), and the file-level `legacy-migration-analysis` tag certifies no individual row:

| Badge | What it means for you |
| --- | --- |
| `verified` | Confirmed against how the platform actually behaves, not only against what its documentation declares. Safe to build on. |
| `inferred` | The shapes line up and this is the best-supported reading, but the pairing is not confirmed end to end. Build on it, then test the behaviour the row names before going live. |
| `unverified` | Not established. The skill will not turn one of these into code without telling you it is unverified. |

Most rows carry a **split badge**, for example `verified (TranSafe side) / inferred (Payroc side)`. That
is deliberate and it is more informative than either half alone. Each half says how well that one claim
is known; the lowest half is the one to plan around. The text in parentheses names what the half covers
or what is still unknown.

## How far a badge goes

**Read the halves separately; they rest on different kinds of evidence.**

- **TranSafe side.** A `verified` TranSafe half is confirmed against how the platform behaves, not
  only against its published reference. Only a few have also been checked on live requests: the outcome
  signalling, error and duplicate rows in `map-protocol-auth-and-results.md`, and a handful of purchase
  rows. The administrative surfaces (`map-boarding.md`, `map-users-and-merchant-config.md`) and the
  recurring, batch and paypage files have not been checked on live requests. Where your integration
  depends on an exact TranSafe behaviour, confirm it against your own logs before you remove the code
  that handles it.
- **Payroc side.** A Payroc half is almost always `inferred`: it follows Payroc's published API
  reference and has not been run end to end, so test the behaviour the row names before going live. Absence claims ("the Payroc API has no operation for
  this") are stated against the public API reference, so you can check them there.
- **`unverified`** halves name the open point in words. Most are questions only your Payroc
  implementation contact can answer (how existing merchants, groups or tokens are moved, which build
  your TranSafe deployment runs). Ask before you build on them.

## Visibility labels

Some row keys end with a label: `published` (in TranSafe's published REST reference), `public build
only` (in a newer TranSafe reference build that was never published), or `internal-only` (in
neither: not in any public TranSafe documentation). An integration calling an `internal-only` action was built against something other than the
public documentation; expect fewer details on the TranSafe side of those rows.

Each file states its own scope and limits in its header. **Read that before treating a badge as a
guarantee.**

## Reading a row

Every mapping row has six cells: the TranSafe call, the verdict, the Payroc target, the request delta, the
behaviour change and the confidence badge (`C`).

| Verdict | Means |
| --- | --- |
| `direct` | Same behaviour on both sides; the row names what was compared |
| `absorbed` | The TranSafe call becomes a flag or field on a Payroc call; the row names it |
| `partial` | It ports, but something is lost; the behaviour change starts `LOSS:` |
| `sequence` | One TranSafe call becomes several Payroc calls in order (`SEQ:`) |
| `branch` | One TranSafe call becomes one of several Payroc calls, chosen by the condition in `IF:` |
| `config` | No longer an API call; Payroc configures it, and `CFG:` says whom to ask |
| `none` | No Payroc equivalent; the row gives an alternative or an escalation route |
| `—` (on an `OUT` row) | Not callable on TranSafe either, or outside this skill; `SCOPE:` gives the reason |

Behaviour-change tags: `SEMANTIC:` the field or call looks the same but means something different; `LOSS:`
something TranSafe did that Payroc does not; `SEQ:` the order of steps matters; `IF:` the condition that
picks a branch, or, on rows that share the same key/value pairs, the parameter that tells them apart;
`SCOPE:` why a row is out of scope or limited; `ID:` an identifier changes; `CFG:` configuration, with
whom to ask. A branch condition is sometimes a design choice (which page type to use, say): decide it
once and record why.

Separators: in the Payroc target, `A → B` means call `A`, then `B`, and a skill name after `→` is the
task skill that implements the call (`payment` → run-a-card-sale); ` | ` separates the alternatives of
a branch. In the request delta, `x → y` means TranSafe's `x` becomes Payroc's `y`, `+field` is a
Payroc-required field with no TranSafe source, and `—` means nothing changes. On a v1 row, `⇒` points
to its v2 twin.

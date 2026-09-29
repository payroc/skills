# References — source manifest

This skill answers from the local `references/` files below. Nothing is fetched live at runtime. To
refresh a file, regenerate it from the current analysis and update the "Last synced" date here and in
the file's own header.

Last synced: **per file — see the table below.** Files are refreshed individually, so a single
tree-wide date would be misleading; the earliest row is 2026-09-04.

> **What a 2026-09-14 date means on the seven files that carry one, and what it does not.** Those
> files were **targeted updates**, not regenerations: named claims were corrected or added, and the
> rest of each file still dates from the row's previous sync. **Do not read 2026-09-14
> as "every row in this file was re-derived that day."**

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `map-card-transactions.md` | — (see note below) | 2026-09-14 | `legacy-migration-analysis` |
| `map-debit-and-ebt.md` | — | 2026-09-14 | `legacy-migration-analysis` |
| `map-check-cash-and-stored-value.md` | — | 2026-09-14 | `legacy-migration-analysis` |
| `map-tokens-and-vault.md` | — | 2026-09-24 | `legacy-migration-analysis` |
| `map-token-payments.md` | — | 2026-09-04 | `legacy-migration-analysis` |
| `map-rest-transactions.md` | — | 2026-09-04 | `legacy-migration-analysis` |
| `map-batch-and-settlement.md` | — | 2026-09-14 | `legacy-migration-analysis` |
| `map-reporting-and-search.md` | — | 2026-09-09 | `legacy-migration-analysis` |
| `map-recurring-soap.md` | — | 2026-09-10 | `legacy-migration-analysis` |
| `map-recurring-rest.md` | — | 2026-09-04 | `legacy-migration-analysis` |
| `map-merchant-admin.md` | — | 2026-09-04 | `legacy-migration-analysis` |
| `map-auth-and-platform-utilities.md` | — | 2026-09-04 | `legacy-migration-analysis` |
| `map-undocumented-surfaces.md` | — | 2026-09-14 | `legacy-migration-analysis` |
| `map-extdata-tags.md` | — | 2026-09-24 | `legacy-migration-analysis` |
| `identifier-translation.md` | — | 2026-09-04 | `legacy-migration-analysis` |
| `no-equivalent-register.md` | — | 2026-09-14 | `legacy-migration-analysis` (compiled from the files above) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied or curated directly;
`legacy-migration-analysis` = Payroc's own operation-by-operation mapping between a legacy
Payroc-owned gateway and the Payroc API.

## Why these rows carry no Source URL

The other skills in this repository document a single API and cite the page that documents it. A
migration reference has no such page: it is a *comparison* of two platforms, and one of them — IBX —
has no current public specification to point at. So the mapping is Payroc's own analysis rather than a
curated copy of anything, and there is no honest URL to put in that column.

What replaces the URL is **per-row confidence**. Every row in every mapping file carries a `C` badge,
and the file-level `legacy-migration-analysis` tag certifies no individual row:

| Badge | What it means for you |
| --- | --- |
| `verified` | Confirmed against how the platform actually behaves, not only against what its documentation declares. Safe to build on. |
| `inferred` | The shapes line up and this is the best-supported reading, but the pairing is not confirmed end to end. Build on it, then test the behaviour the row names before going live. |
| `unverified` | Not established. The skill will not turn one of these into code without telling you it is unverified. |

Some rows carry a **split badge** — for example `verified (Payroc side) / inferred (the pairing)`. That
is deliberate and it is more informative than either half alone: it means the target operation's
behaviour is confirmed while the claim that your legacy call corresponds to it is not.

## How far a badge goes, and why badges are not comparable across files

**A `verified` does not mean the same thing in every file, and reading them as equivalent is the most
likely way to be misled by this skill.** What was available to check differs by surface:

- The **transaction files** are the strongest. A `verified` there is normally grounded in the
  platform's runtime behaviour.
- The **administrative surfaces** (`map-merchant-admin.md`) have no captured traffic behind them at
  all. Findings rest on Payroc's engineering records, most from around 2021, not re-confirmed
  against the running platform.
- The **supporting services** in `map-auth-and-platform-utilities.md` are mapped largely from their
  declared interfaces only. **No Payroc pairing in that file is `verified`** — its rows are
  `inferred` or `unverified`, and where one carries a split badge the `verified` half is about IBX's
  behaviour, never about the Payroc target.
- Where a **SOAP row is badged lower than the REST row beside it**, that reflects how much
  confirmation was available for that transport, not a difference in behaviour between them.
- `map-recurring-soap.md` carries less field-level detail than its REST sibling. The service's own
  definition has no per-operation documentation and no request against it has been observed, so most
  rows name a best-guess Payroc target. What **is** established, and in detail, is how the four
  `Manage*` operations behave.

Each file states its own limit in its header. **Read that before treating a badge as a guarantee.**

## Reporting an error

Payroc-side facts throughout these files are drawn from the current Payroc API documentation at
`https://docs.payroc.com/`. Where a mapping row and the Payroc documentation disagree, the
documentation is correct and the row is stale — please report it.

## Shared vocabulary

`legacy-migration-analysis` is intended to be shared by every legacy-gateway migration skill in
`plugins/payroc/migrations/`, not reinvented per platform. A reader who has migrated one Payroc legacy
gateway should not have to learn a second provenance vocabulary to migrate another.

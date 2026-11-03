# References — source manifest

This skill answers from the local `references/` files below. Nothing is fetched live at runtime. Each
file's "Last synced" date, here and in its own header, says when it was last brought up to date.

Last synced: **per file — see the table below.**

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `map-protocol-auth-and-results.md` | — (see note below) | 2026-11-03 | `legacy-migration-analysis` |
| `identifier-translation.md` | — | 2026-10-11 | `legacy-migration-analysis` |
| `map-xml-api.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-direct-cgis.md` | — | 2026-10-11 | `legacy-migration-analysis` |
| `map-browser-forms-and-pages.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-json-api.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-recurring.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-payouts.md` | — | 2026-10-11 | `legacy-migration-analysis` |
| `map-transaction-reporting.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-postbacks.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-gateway-servlet.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-sdks.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `map-plugins-and-clients.md` | — | 2026-11-03 | `legacy-migration-analysis` |
| `no-equivalent-register.md` | — | 2026-11-03 | `legacy-migration-analysis` (collects the gaps recorded in the files above) |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-11-03 | `payroc-verbatim` (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied or curated directly;
`legacy-migration-analysis` = Payroc's own operation-by-operation mapping between a legacy
Payroc-owned gateway and the Payroc API.

## Why the mapping rows carry no Source URL

The other skills in this repository document a single API and cite the page that documents it. A
migration reference has no such page: it compares two platforms, and one of them, iTransact, has no
current public specification to point at. The mapping is Payroc's own analysis, so there is no single page to
cite in that column.

What replaces the URL is **per-row confidence**. Every row in every mapping file carries a `C` badge,
and the file-level `legacy-migration-analysis` tag applies to the whole file, not to any one row:

| Badge | What it means for you |
| --- | --- |
| `verified` | Confirmed against how the platform actually behaves, not only against what its documentation declares (for iTransact, see "How far a badge goes" below). Safe to build on. |
| `inferred` | The shapes line up and this is the best-supported reading, but the pairing is not confirmed end to end. Build on it, then test the behaviour the row names before going live. |
| `unverified` | Not established. The skill will not turn one of these into code without telling you it is unverified. |

Many rows carry a **split badge**, for example `verified (iTransact side) / inferred (Payroc side)`.
That is deliberate. Each half says how well that half is known, and the claim that your iTransact call
corresponds to the Payroc operation is only as strong as the weaker half.

## How far a badge goes in these files

**Read this before treating a badge as a guarantee.**

- **On the iTransact side, `verified` means iTransact's own implementation or configuration agrees with
  the row.** It does not mean a live transaction was observed: none was sent to iTransact for this
  mapping, and none can be before the platform switches off. Test the behaviour a row names in the Payroc
  test environment. Where iTransact's implementation and its published documentation disagree, the row says both.
- **No Payroc API half is `verified`.** Each is `inferred` from Payroc's API documentation, or
  `unverified` where the documentation doesn't settle it. Test the behaviour a row names in the test environment before
  going live.
- **Absence claims about Payroc** ("the Payroc API documents no operation for this") describe Payroc's
  documentation, not a confirmed product limit. Each one comes with an alternative or an escalation
  route; ask your Payroc implementation contact before redesigning around it.
- **The gateway servlet file is provisional.** It is mapped in case your integration posts XML to the
  gateway servlet directly.
- **SDK, plugin and client rows wrap another row.** They carry only what differs from the row they
  wrap, and the wrapped row is authoritative.

## Reporting an error

Payroc-side facts throughout these files come from the current Payroc API documentation at
`https://docs.payroc.com/`. Where a mapping row and the Payroc documentation disagree, follow the
documentation and tell your Payroc implementation contact.

## Shared vocabulary

`legacy-migration-analysis` is used the same way by every Payroc legacy-gateway migration skill. A reader who has migrated one Payroc legacy gateway doesn't have to
learn a second provenance vocabulary to migrate another.

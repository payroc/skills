# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch its source, regenerate it, then update the "Last synced" date here and in the file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (boarding → merchant-platforms paths + schemas) | 2026-06-01 | payroc-verbatim (curated slice) |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-06-22 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly. The
merchant-platform schemas are entirely Payroc-owned, so this skill has no `third-party-derived` references.

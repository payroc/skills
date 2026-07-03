# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch its source URL and regenerate it, then update the "Last synced" date here and in the
file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/api/schema/tokenization/secure-tokens/create.md + retrieve + list + delete + update-account (curated slice) | 2026-06-22 | payroc-verbatim (curated slice) |
| `save-payment-details-guide.md` | https://docs.payroc.com/guides/take-payments/save-payment-details.md | 2026-06-22 | payroc-verbatim |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-06-22 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly; `third-party-derived`
= our own-words notes on third-party API surface (none in this skill).

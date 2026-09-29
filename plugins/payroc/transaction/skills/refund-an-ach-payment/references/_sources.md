# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch its source URL and regenerate it, then update the "Last synced" date here and in the
file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (bank-transfer-payments and bank-transfer-refunds schemas); https://docs.payroc.com/guides/take-payments/payments/refunds/referenced-refunds/bank.md; https://docs.payroc.com/guides/take-payments/payments/refunds/unreferenced-refunds/bank.md | 2026-09-18 | payroc-verbatim (curated slice) |
| `bank-transfer-refund-guide.md` | https://docs.payroc.com/guides/take-payments/payments/refunds/referenced-refunds/bank.md; https://docs.payroc.com/guides/take-payments/payments/refunds/unreferenced-refunds/bank.md; https://docs.payroc.com/guides/take-payments/payments/refunds/reversals/bank.md | 2026-09-24 | payroc-verbatim |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-09-16 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly; `third-party-derived`
= our own-words notes on third-party API surface (none in this skill).

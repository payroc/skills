# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch its source URL and regenerate it, then update the "Last synced" date here and in the
file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (Repeat Payments schemas) and https://docs.payroc.com/api/schema/repeat-payments/payment-plans/create.md + subscriptions/create.md | 2026-06-22 | payroc-verbatim (curated slice) |
| `repeat-payments-guide.md` | https://docs.payroc.com/guides/take-payments/repeat-payments/use-our-gateway.md and https://docs.payroc.com/knowledge/card-payments/payment-plans-and-subscriptions.md | 2026-06-22 | payroc-verbatim |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-06-22 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly; `third-party-derived`
= our own-words notes on third-party API surface (none in this skill).

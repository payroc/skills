# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch its source URL and regenerate it, then update the "Last synced" date here and in the
file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (Payment Links schemas) | 2026-06-01 | payroc-verbatim (curated slice) |
| `create-and-share-a-payment-link.md` | https://docs.payroc.com/essentials/payment-links/create-and-share-a-payment-link.md | 2026-06-01 | payroc-verbatim |
| `extend-your-integration.md` | https://docs.payroc.com/essentials/payment-links/extend-your-integration.md | 2026-06-01 | payroc-verbatim |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-06-22 | payroc-verbatim (curated slice) |
| `idempotency.md` | https://docs.payroc.com/api/idempotency | 2026-07-02 | payroc-verbatim (shared fragment, copied from `plugins/payroc/_shared/idempotency.md`) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly; `third-party-derived`
= our own-words notes on third-party API surface (none in this skill).

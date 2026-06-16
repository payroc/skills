# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch its source URL and regenerate it, then update the "Last synced" date here and in the
file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (Card Payments — Capture + `transactionResult` schemas) | 2026-06-01 | payroc-verbatim (curated slice) |
| `authenticate-your-requests.md` | https://docs.payroc.com/essentials/hosted-payment-page/run-a-sale/authenticate-your-requests.md | 2026-06-01 | payroc-verbatim |
| `load-hosted-payment-page.md` | https://docs.payroc.com/essentials/hosted-payment-page/run-a-sale/load-hosted-payment-page.md | 2026-06-01 | payroc-verbatim |
| `build-receipt-page.md` | https://docs.payroc.com/essentials/hosted-payment-page/run-a-sale/build-receipt-page.md | 2026-06-01 | payroc-verbatim |
| `implement-background-validation.md` | https://docs.payroc.com/essentials/hosted-payment-page/extend-your-integration/implement-background-validation.md | 2026-06-01 | payroc-verbatim |
| `save-payment-details/authenticate-your-requests.md` | https://docs.payroc.com/essentials/hosted-payment-page/extend-your-integration/save-a-customers-payment-details/authenticate-your-requests.md | 2026-06-04 | payroc-verbatim |
| `save-payment-details/load-hosted-payment-page.md` | https://docs.payroc.com/essentials/hosted-payment-page/extend-your-integration/save-a-customers-payment-details/load-hosted-payment-page.md | 2026-06-04 | payroc-verbatim |
| `save-payment-details/build-receipt-page.md` | https://docs.payroc.com/essentials/hosted-payment-page/extend-your-integration/save-a-customers-payment-details/build-receipt-page.md | 2026-06-04 | payroc-verbatim |
| `repeat-payments-api-schema.md` | https://docs.payroc.com/openapi.yml (Repeat Payments — Secure Tokens, Payment Plans, Subscriptions + Payments `secureToken` / `standingInstructions` schemas) | 2026-06-04 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly; `third-party-derived`
= our own-words notes on third-party API surface (none in this skill).

The `save-payment-details/*.md` files carry a small number of clearly-marked **skill annotation** notes
(labelled "not part of the source page") that flag where the save-card surface differs from the sale surface;
the surrounding text is verbatim.

`sale.md`, `pre-auth.md`, and `recurring.md` are skill-authored flow files (not source snapshots) and are
intentionally not listed here.

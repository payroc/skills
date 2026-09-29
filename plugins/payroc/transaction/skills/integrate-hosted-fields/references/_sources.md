# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch its source URL and regenerate it, then update the "Last synced" date here and in the
file's header. For the SDK JS, the four-part `libVersion` comes from `create-a-payment-form.md`; re-read it
there, re-fetch the SDK from the CDN URL, and regenerate `hosted-fields-sdk.js`.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (Hosted Fields / Payments schemas) | 2026-06-01 | payroc-verbatim (curated slice) |
| `hosted-fields-sdk.js` | https://cdn.uat.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261457.js (UAT) · https://cdn.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261471.js (prod) | 2026-06-01 | payroc-verbatim |
| `authenticate-your-session.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md | 2026-06-01 | payroc-verbatim |
| `create-a-payment-form.md` | https://docs.payroc.com/essentials/hosted-fields/create-a-payment-form.md | 2026-06-01 | payroc-verbatim |
| `run-a-sale.md` | https://docs.payroc.com/essentials/hosted-fields/run-a-sale.md | 2026-09-16 | payroc-verbatim |
| `style-your-fields.md` | https://docs.payroc.com/essentials/hosted-fields/extend-your-integration/style-your-fields.md | 2026-06-01 | payroc-verbatim |
| `add-your-own-fields.md` | https://docs.payroc.com/essentials/hosted-fields/extend-your-integration/add-your-own-fields.md | 2026-06-01 | payroc-verbatim |
| `close-a-session.md` | https://docs.payroc.com/essentials/hosted-fields/extend-your-integration/close-a-session.md | 2026-06-01 | payroc-verbatim |
| `save-a-customers-payment-details.md` | https://docs.payroc.com/essentials/hosted-fields/extend-your-integration/save-a-customers-payment-details.md | 2026-09-16 | payroc-verbatim |
| `update-a-customers-payment-details.md` | https://docs.payroc.com/essentials/hosted-fields/extend-your-integration/update-a-customers-payment-details.md | 2026-06-01 | payroc-verbatim |
| `3-d-secure.md` | https://docs.payroc.com/guides/take-payments/3-d-secure.md | 2026-06-01 | payroc-verbatim |
| `run-a-sale-with-3-d-secure.md` | https://docs.payroc.com/guides/take-payments/3-d-secure/run-a-sale-with-3-d-secure.md | 2026-06-01 | payroc-verbatim |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange; cross-skill canonical copy; HF session-token step is in `authenticate-your-session.md`) | 2026-09-16 | payroc-verbatim (curated slice) |
| `idempotency.md` | https://docs.payroc.com/api/idempotency (shared fragment; byte-identical copy of `plugins/payroc/_shared/idempotency.md`) | 2026-07-02 | payroc-verbatim |
| `pagination.md` | https://docs.payroc.com/api/pagination (shared fragment; byte-identical copy of `plugins/payroc/_shared/pagination.md`) | 2026-07-02 | payroc-verbatim |
| `run-a-card-sale-guide.md` | https://docs.payroc.com/guides/take-payments/payments/run-a-card-sale.md (reused byte-identical copy from `run-a-card-sale/references/run-a-card-sale-guide.md`) | 2026-06-22 | payroc-verbatim |
| `secure-tokens-api-schema.md` | https://docs.payroc.com/openapi.yml (secure-tokens schemas) + create/retrieve/list/delete/update-account schema pages (reused byte-identical copy from `save-a-payment-method/references/api-schema.md`) | 2026-06-22 | payroc-verbatim (curated slice) |
| `update-saved-payment-details-guide.md` | https://docs.payroc.com/guides/take-payments/update-saved-payment-details.md | 2026-07-02 | payroc-verbatim |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly; `third-party-derived`
= our own-words notes on third-party API surface (none in this skill).

**Not listed (skill-authored, no source URL):** `recurring-billing.md` is authored by this skill and reads
from the files above — it is not a snapshot and has no freshness header.

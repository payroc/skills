# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch (Payroc) or re-derive (Apple) its source, regenerate it, then update the "Last synced"
date here and in the file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (Apple Pay session + payment request schemas) | 2026-07-23 | payroc-verbatim (curated slice) |
| `set-up-apple-pay-for-a-merchant.md` | https://docs.payroc.com/guides/take-payments/apple-pay/set-up-apple-pay-for-a-merchant.md | 2026-09-24 | payroc-verbatim |
| `add-apple-pay-to-your-integration.md` | https://docs.payroc.com/guides/take-payments/apple-pay/add-apple-pay-to-your-integration.md | 2026-09-16 | payroc-verbatim |
| `third-party/apple-applepaysession.md` | https://developer.apple.com/documentation/applepayontheweb/applepaysession | 2026-06-05 | third-party-derived |
| `third-party/apple-payment-token.md` | https://developer.apple.com/documentation/applepayontheweb/applepaypaymenttoken | 2026-06-05 | third-party-derived |
| `third-party/apple-server-setup.md` | https://developer.apple.com/documentation/applepayontheweb/setting-up-your-server | 2026-06-05 | third-party-derived |
| `third-party/apple-pay-button.md` | https://developer.apple.com/documentation/applepayontheweb/displaying-apple-pay-buttons-using-javascript | 2026-06-05 | third-party-derived |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-09-16 | payroc-verbatim (curated slice) |
| `idempotency.md` | https://docs.payroc.com/api/idempotency | 2026-07-02 | payroc-verbatim (shared fragment, byte-identical copy of `plugins/payroc/_shared/idempotency.md`) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly; `third-party-derived`
= our own-words notes on third-party (Apple) API surface — factual names/structure only, no copied prose.
To re-derive or repoint a `third-party-derived` note back to its live source, follow the source URL in the
file's header and in this table.

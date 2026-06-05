# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch (Payroc) or re-derive (Google) from its source URL, then update the "Last synced" date here
and in the file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (Create Payment / `paymentRequest` schemas) | 2026-06-01 | payroc-verbatim (curated slice) |
| `google-pay.md` | https://docs.payroc.com/guides/take-payments/google-pay/google-pay.md | 2026-06-01 | payroc-verbatim |
| `third-party/google-request-objects.md` | https://developers.google.com/pay/api/web/reference/request-objects | 2026-06-01 | third-party-derived |
| `third-party/google-client.md` | https://developers.google.com/pay/api/web/reference/client | 2026-06-01 | third-party-derived |

Provenance legend: `payroc-verbatim` = Payroc-owned content (OpenAPI spec, Payroc narrative guide) copied or
curated directly; `third-party-derived` = our own-words notes on a third party's (Google's) API surface —
factual names/structure only, no verbatim third-party prose (Google docs are not redistributed verbatim).
To repoint a `third-party-derived` note back to a live fetch, swap the matching `Read: references/third-party/<file>.md`
line in SKILL.md for a fetch of the source URL in this row.

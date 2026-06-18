# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To
refresh a file, re-fetch its source (docs.payroc.com serves a markdown copy of any page when you
append `.md` to the URL, and exposes an MCP server at `docs.payroc.com/_mcp/server`), regenerate it,
then update the "Last synced" date here and in the file's header.

| Local file | Source URL(s) | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | `https://docs.payroc.com/openapi.yml` (`payrocCloud` tag) + the per-operation schema pages: `https://docs.payroc.com/api/schema/payroc-cloud/payment-instructions/{submit,retrieve,delete}.md`, `.../refund-instructions/{submit,retrieve,delete}.md`, `.../signature-instructions/{submit,retrieve,delete}.md`, `.../signatures/retrieve.md`, `.../closed-loop-reads/retrieve.md`; plus `https://docs.payroc.com/api/schema/card-payments/payments/retrieve.md` (retrieved-payment body + `transactionResult`/`supportedOperations`), `https://docs.payroc.com/api/schema/card-payments/refunds/reverse.md`, `https://docs.payroc.com/api/schema/boarding/devices/search-devices.md`, and the payments `refunds`/search schemas | 2026-06-17 | payroc-verbatim (curated slice) |
| `narrative-run-a-sale.md` | `https://docs.payroc.com/essentials/payroc-cloud/run-a-sale.md` | 2026-06-17 | payroc-verbatim |
| `narrative-extend.md` | `https://docs.payroc.com/essentials/payroc-cloud/extend-your-integration.md` (+ `/capture-a-signature.md`, `/run-an-unreferenced-refund.md`, `/run-a-referenced-refund.md`, `/reverse-a-payment.md`) | 2026-06-17 | payroc-verbatim |
| (shared) error format | `plugins/payroc/_shared/error-response-format.md` | — | payroc-verbatim |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly. The Payroc Cloud
schemas are entirely Payroc-owned, so this skill has no `third-party-derived` references.

**Unverified caveat (2026-06-17):** these references were curated from the published docs without a
Cloud-enabled UAT account or hardware to confirm against. The **Cloud error response shape** in
particular is assumed to follow the cross-skill RFC 7807 + `errors[]` standard (verified on boarding
endpoints) but is **not confirmed for Cloud**. The `api-schema.md` error section is flagged
accordingly. Acquiring a Payroc App API key via the Self-Care Portal (to drive the Payroc Cloud
Simulator at `cloud.uat.payroc.com`) is the documented path to close this gap — no hardware required.

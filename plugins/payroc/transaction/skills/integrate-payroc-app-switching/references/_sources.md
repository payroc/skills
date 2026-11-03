# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To
refresh a file, re-fetch its source (docs.payroc.com serves a markdown copy of any page when you
append `.md` to the URL), regenerate it, then update the "Last synced" date here and in the file's
header. Files noted as copies are byte-identical copies of another skill's reference: change the
source file first, then re-copy.

| Local file | Source URL(s) | Last synced | Provenance | Notes |
| --- | --- | --- | --- | --- |
| `android-same-device.md` | `https://docs.payroc.com/guides/payments/payroc-cloud/device-setup/android-same-device.md` | 2026-10-30 | payroc-verbatim (curated slice) | Diagram dropped, doc links pointed at local files, Kotlin fences relabelled. |
| `api-schema.md` | See `integrate-payroc-cloud/references/_sources.md` (`payrocCloud` tag of `https://docs.payroc.com/openapi.yml` and the per-operation schema pages) | 2026-11-03 | payroc-verbatim (curated slice) | Byte-identical copy of `integrate-payroc-cloud/references/api-schema.md`. Hosts: one REST host for test and live keys per https://docs.payroc.com/api/authentication (2026-11-03); the docs guide page still lists UAT hosts. |
| `narrative-run-a-sale.md` | `https://docs.payroc.com/essentials/payroc-cloud/run-a-sale.md` | 2026-10-30 | payroc-verbatim | Byte-identical copy of `integrate-payroc-cloud/references/narrative-run-a-sale.md`. |
| `narrative-extend.md` | `https://docs.payroc.com/essentials/payroc-cloud/extend-your-integration.md` (+ `/capture-a-signature.md`, `/run-an-unreferenced-refund.md`, `/run-a-referenced-refund.md`, `/reverse-a-payment.md`) | 2026-10-30 | payroc-verbatim | Byte-identical copy of `integrate-payroc-cloud/references/narrative-extend.md`. |
| `error-response-format.md` | Payroc's cross-skill error format (RFC 7807 envelope plus `errors[]`) | — | payroc-verbatim | Byte-identical copy of `integrate-payroc-cloud/references/error-response-format.md`. |
| `field-notes.md` | Observed on a test-environment payment terminal running the Payroc test app; answers from Payroc's integration team | 2026-11-03 | observed (test environment); Payroc integration team | Diagnostic observations and team answers, not documented behaviour. Hedges in the answers are kept. |
| `identity-call.md` | `https://docs.payroc.com/api/authentication` | 2026-11-03 | payroc-verbatim | Byte-identical copy of `integrate-payroc-cloud/references/identity-call.md`. |
| `recovery.md` | `https://docs.payroc.com/api/idempotency.md`, `https://docs.payroc.com/api/authentication.md`, plus `api-schema.md`, `narrative-extend.md`, `error-response-format.md` and `identity-call.md` here | 2026-10-30 | derived | This skill's retry and recovery rules; each names its source. |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied or curated directly. `observed (test environment)` =
seen on a test-environment terminal, not in the docs. `Payroc integration team` = answers from Payroc's
integration team to questions the docs leave open, not published. `derived` = this skill's own guidance built from the Payroc
sources it names. No reference file is third-party-derived, but SKILL.md also states third-party
platform behaviour that isn't from a Payroc source: Android package visibility, background activity
starts, `startService` returning `null`, `repeatOnLifecycle` cancelling its block
(developer.android.com); OkHttp's 10-second default read timeout (OkHttp source); and
kotlinx.serialization omitting default values unless `encodeDefaults` is set (kotlinlang.org).

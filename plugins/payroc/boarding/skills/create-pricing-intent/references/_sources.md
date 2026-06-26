# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To
refresh a file, re-fetch its source, regenerate it, then update the "Last synced" date here and in
the file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (boarding → pricing-intents paths + `pricingIntent5.2`, `baseUs`, `PricingIntent52Processor`, `gatewayUs5.2`, `servicesUs5.0` schemas) | 2026-06-16 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly. The pricing
intent schemas are entirely Payroc-owned, so this skill has no `third-party-derived` references.

**Live correction (2026-06-16):** the OpenAPI `ErrorsItems` schema documents only `message` on each
`errors[]` item, but the live API returns `parameter` + `detail` + `message` (and a top-level
`instance`). Verified by `POST`ing an empty body to both `/pricing-intents` and `/merchant-platforms`
on UAT. The error-schema section of `api-schema.md` reflects the live shape, not the spec.

**Live correction (2026-06-19):** the OpenAPI spec marks `base.addressVerification`,
`base.regulatoryAssistanceProgram`, and `base.merchantAdvantage` as nullable, but the live UAT API
**rejects `null` for all three** (*"... must not be empty"*) — verified by `POST`ing each as
`null`. Earlier guidance said to send `null` (never `0`); that was wrong against UAT. The SKILL,
`api-schema.md`, examples, and evals now send a numeric value (`0` when not charged). Also confirmed
the same run: a freshly created pricing intent is `active` immediately in UAT (no manual-approval
wait), and IDs are returned as plain integers (e.g. `5722`), not `PI-XXXX`.

Related guide pages (not yet snapshotted; fetch if narrative copy is needed):
`https://docs.payroc.com/api/schema/boarding/pricing-intents/{create,retrieve,list,update,partially-update,delete}`.

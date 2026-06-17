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

Related guide pages (not yet snapshotted; fetch if narrative copy is needed):
`https://docs.payroc.com/api/schema/boarding/pricing-intents/{create,retrieve,list,update,partially-update,delete}`.

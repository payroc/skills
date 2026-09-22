# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime. To refresh
a file, re-fetch its source URL and regenerate it, then update the "Last synced" date here and in the
file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (Funding Activity schemas: `funding_fundingActivity_*`, `merchantBalance`, `activityRecord`, `ActivityRecordType`) | 2026-06-22 | payroc-verbatim (curated slice) |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-09-16 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly; `third-party-derived`
= our own-words notes on third-party API surface (none in this skill).

## Notes

- No narrative guide page was found for funding activity at `https://docs.payroc.com/essentials/funding/` (returns 404). The API schema reference (`api-schema.md`) and the OpenAPI spec list endpoint (`https://docs.payroc.com/api/schema/funding/funding-activity/list`) are the primary sources.
- The funding activity skill covers two read-only GET endpoints: `GET /v1/funding-balance` and `GET /v1/funding-activity`. Both are documented in the OpenAPI spec under the `subpackage_funding.subpackage_funding/fundingActivity` tag.

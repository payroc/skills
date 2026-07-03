# References — Sources

All files in this `references/` directory are local snapshots. Regenerate them from their source URLs if they look stale.

---

| File | Source URL | Last synced | Used for |
| --- | --- | --- | --- |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-06-22 | Auth — identity endpoint URL, request header, and response shape. Mandatory for every skill. |
| `api-schema.md` | https://docs.payroc.com/guides/fund-merchants/send-funds-to-your-merchants.md · https://docs.payroc.com/api/schema/funding/funding-instructions/create.md · https://docs.payroc.com/api/schema/funding/funding-instructions/retrieve.md · https://docs.payroc.com/api/schema/funding/funding-instructions/list.md · https://docs.payroc.com/api/schema/funding/funding-instructions/update.md · https://docs.payroc.com/api/schema/funding/funding-instructions/delete.md · https://docs.payroc.com/api/schema/funding/funding-activity/retrieve-balance.md | 2026-06-22 | All endpoint paths, HTTP methods, request/response schemas, enum values, error codes. Primary reference for all code generation. |
| `send-funds-guide.md` | https://docs.payroc.com/guides/fund-merchants/send-funds-to-your-merchants.md | 2026-06-22 | Narrative walkthrough of the two-step flow (check balance → create instruction), lifecycle status model, and key constraints. |

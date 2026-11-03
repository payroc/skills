# Sources — create-single-use-token

All files in this `references/` directory are local snapshots of external sources. This file
records where each was fetched from and when it was last synced. If a reference looks stale,
re-fetch from the source URL and update the "Last synced" date.

---

| File | Source URL | Last synced | Notes |
| --- | --- | --- | --- |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-11-03 | Canonical identity-service reference shared across all Payroc skills |
| `api-schema.md` | https://docs.payroc.com/api/schema/tokenization/single-use-tokens/create.md | 2026-11-03 | Schema for POST /v1/processing-terminals/{processingTerminalId}/single-use-tokens — enums, required fields, request/response; hosts: one REST host for test and live keys per https://docs.payroc.com/api/authentication (2026-11-03); the docs guide page still lists UAT hosts |
| `tokenization-overview.md` | https://docs.payroc.com/knowledge/basic-concepts/tokenization.md | 2026-06-22 | Narrative overview: single-use vs secure tokens, when to use each |

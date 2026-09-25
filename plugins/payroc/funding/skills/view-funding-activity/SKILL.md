---
name: view-funding-activity
description: >
  Guides developers through querying merchant funding balances and funding activity via the
  Payroc Funding API (GET /v1/funding-balance and GET /v1/funding-activity). Use this skill
  when the user wants to view funding activity, check a merchant's current funding balance
  for reporting or reconciliation purposes, query the history of credits and debits to a
  funding balance, see what funds are available or pending, filter funding activity records
  by date range or merchant, paginate through funding records, or understand why a funding
  balance changed. Also use when the user asks about funding-balance, funding-activity,
  a merchant's available or pending funds, or how to monitor funding flows — even if they
  don't use the exact endpoint names. Do NOT use this skill for processing payment
  transactions, looking up individual payment transaction history, checking individual
  payment settlement status, creating or sending funding instructions (use
  send-funds-to-a-merchant), tracking the status of a specific funding instruction,
  setting up a funding recipient or funding account (use set-up-a-funding-recipient),
  or viewing ACH deposits (use view-ach-deposits).
metadata:
  version: "0.5.1"
  category: funding
  status: draft
---

# View Funding Activity

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/funding/skills/view-funding-activity/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

## Empty results in UAT

> If `GET /v1/funding-activity` returns no activity in UAT, it's likely because no funding
> recipient or funding instruction has been created yet in that environment — funding
> activity only appears once a KYC-approved recipient has received funds. See the
> `set-up-a-funding-recipient` skill's KYC validation note. The endpoints and schemas
> documented here are written directly from the published OpenAPI spec.

---

## Quick reference

```text
GET  https://api.uat.payroc.com/v1/funding-balance
GET  https://api.uat.payroc.com/v1/funding-activity?dateFrom=YYYY-MM-DD&dateTo=YYYY-MM-DD
Authorization: Bearer <token>
```

Both endpoints are **read-only GET requests** — no request body, no `Idempotency-Key` header required.

---

## References

All enum values and schemas live in the local `references/` files — this skill emits from them, not from live lookups or training-data memory.

| Source | Local file | Use for |
| --- | --- | --- |
| Auth (identity service) | `references/identity-call.md` | Token endpoint URL, request header, response fields |
| API schema reference | `references/api-schema.md` | All endpoint parameters, response schemas, enum values (`ActivityRecordType`), pagination fields |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots authoritative for this skill. Their source URLs and last-synced dates are recorded in [`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Inspect before asking** — scan the codebase before asking any questions; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through intake before writing implementation code; wrong assumptions waste the developer's time.
3. **Read the schema reference before emitting any enum value.** The `type` field on each `activityRecord` accepts only `credit` or `debit` — the exact documented values from `references/api-schema.md`. Read that file before you emit these values. Do not guess casing or spelling. A plausible-sounding string that isn't in the documented enum will produce incorrect filtering logic.
4. **Read the schema reference before issuing any code review verdict.** When asked to review, audit, or check correctness of code that calls the Payroc funding API, read `references/api-schema.md` BEFORE stating your verdict. Field names, required parameters, and enum values must be verified against the reference — not assumed from training-data memory or inferred from the developer's code.
5. **No Idempotency-Key on GET requests.** Both endpoints are GET-only. Do not add an `Idempotency-Key` header — it is required only on POST and PATCH requests. An extra header on a GET request is unnecessary per the API contract, though it is unlikely to cause the request to fail.
6. **dateFrom and dateTo are required for funding activity.** The `GET /v1/funding-activity` endpoint requires both `dateFrom` and `dateTo` as query parameters (format `YYYY-MM-DD`). Omitting either causes a `400` validation error.
7. **Never hardcode credentials.** API keys must come from environment variables or a secrets manager, never source code or configuration files checked into version control.
8. **Bearer token expiry.** Tokens from the identity service expire after 3,600 seconds (1 hour). For long-running services, implement token refresh logic.
9. **Amounts are in lowest denomination.** All `amount`, `funds`, `pending`, and `available` fields are integers in the currency's lowest denomination (e.g. cents for USD). `$1,000.00` is `100000`. Divide by 100 to display dollar values to users.
10. **`recipient` is conditional.** The `recipient` field on an `activityRecord` is only returned when `type` is `debit`. Do not assume it is always present.
11. **`merchant` vs `merchantId` — these are different things.** The query parameter used to filter results is `merchantId` (the processor-assigned identifier, e.g. `"123456"`). The `activityRecord` response field `merchant` is the merchant's DBA name string (e.g. `"Acme Corp"`), not an ID. `activityRecord` does not contain a `merchantId` field — there is no numeric ID on individual activity records. Do not attempt to filter with `?merchant=<name>` (wrong field name), and do not attempt to read `activityRecord.merchantId` (field does not exist).
12. **`amount` is always positive — `type` carries the direction.** All `amount` values on `activityRecord` are non-negative integers. A `debit` record does not carry a negative amount; the `type` field (`"credit"` or `"debit"`) is the sole indicator of direction. Do not negate debit amounts in your own logic — doing so will double-count the deduction.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Any existing HTTP client setup or credential configuration
- How environment variables are managed
- Whether any Payroc API calls already exist

Use what you find to pre-fill obvious answers and ask targeted questions. Then confirm:

- **Which endpoint(s) does the developer need?**
  - Funding balances only (`GET /v1/funding-balance`) — view available/pending/total funds per merchant
  - Funding activity only (`GET /v1/funding-activity`) — view credits and debits over a date range
  - Both
- **Filtering needs:**
  - For balances: filter by a specific `merchantId`?
  - For activity: what date range? Filter by `merchantId`?
- **Pagination:** does the developer need to page through all results or just the first page?
- **Output format:** are they building a dashboard display, writing to a log, or storing records?

---

## Prerequisites

These are needed to **run and test** the integration in UAT — not to write the code. If the developer already has them, proceed. If not, wire the code to read from environment variables and keep building.

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by the Payroc Integrations team along with UAT access.
2. **UAT environment** — Payroc's test environment. There is no self-serve signup; UAT access is provisioned manually by the Payroc Integrations team.
3. **Merchant ID(s)** — optional, only needed if filtering by a specific merchant. The Payroc Integrations team provides these.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it; otherwise propose `PAYROC_API_KEY`. Write the code to read credentials from those variables, then tell the developer:

> ⚠️ I've wired this to read your API key from `PAYROC_API_KEY`. You'll need a Payroc UAT API key to actually run or test this — contact the Payroc Integrations team to get it, and set the variable before testing. I can keep building in the meantime.

### Checkpoint

Either the credentials are confirmed, or the developer knows what's outstanding and which environment variables the code reads from — and has chosen to proceed.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). All subsequent API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

**Production vs UAT API keys are different.** A UAT API key cannot be used against the production identity service — it will return `401`. When switching environments, the developer must use a production API key provisioned by the Payroc Integrations team.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the UAT environment.

---

## Step 2 — Query funding balances (optional)

> **Read `references/api-schema.md` before writing this request.** The response schema, field names, and what `available`/`pending`/`funds` mean are all defined there. Do not emit field names from training-data memory.

Endpoint: `GET https://api.uat.payroc.com/v1/funding-balance`

Required headers:
```
Authorization: Bearer <token>
```

No request body. No `Idempotency-Key` header (GET request).

Optional query parameters:
- `merchantId` — filter to a specific merchant
- `limit` — results per page (default 10)
- `after` / `before` — pagination cursors (use one, not both)

Example request:
```bash
curl -G https://api.uat.payroc.com/v1/funding-balance \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode "merchantId=123456"
```

Example response (200 OK):
```json
{
  "limit": 10,
  "count": 1,
  "hasMore": false,
  "links": [],
  "data": [
    {
      "merchantId": "123456",
      "funds": 150000,
      "pending": 50000,
      "available": 100000,
      "currency": "USD"
    }
  ]
}
```

**Amounts are in cents.** `"available": 100000` means $1,000.00 available.

| Field | Meaning |
| --- | --- |
| `funds` | Total funding balance including pending amounts |
| `pending` | Amount not yet sent to funding accounts |
| `available` | Amount that can be used in a new funding instruction |
| `currency` | Currency code — currently always `"USD"`; read from the field rather than hardcoding |

### Checkpoint

Does the API return HTTP 200 with a `data` array? If the array is empty, there are no merchants linked to the account. If you get a `401`, check the Bearer token. If you get a `403`, check the API key permissions.

---

## Step 3 — Query funding activity

> **Read `references/api-schema.md` before writing this request.** The `dateFrom` and `dateTo` required parameters, the `type` enum values (`credit` / `debit`), and the conditional `recipient` field are all documented there. Do not emit field names or enum values from training-data memory.

Endpoint: `GET https://api.uat.payroc.com/v1/funding-activity`

Required headers:
```
Authorization: Bearer <token>
```

**Required** query parameters:
- `dateFrom` — start date in `YYYY-MM-DD` format
- `dateTo` — end date in `YYYY-MM-DD` format

Optional query parameters:
- `merchantId` — filter to a specific merchant's activity
- `limit` — results per page (default 10)
- `after` / `before` — pagination cursors (use one, not both)

Example request:
```bash
curl -G https://api.uat.payroc.com/v1/funding-activity \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode "dateFrom=2026-06-01" \
  --data-urlencode "dateTo=2026-06-22" \
  --data-urlencode "merchantId=123456"
```

Example response (200 OK):
```json
{
  "limit": 10,
  "count": 2,
  "hasMore": false,
  "links": [],
  "data": [
    {
      "id": 98765,
      "date": "2026-06-15T14:30:00Z",
      "merchant": "Acme Corp",
      "description": "Sales",
      "amount": 150000,
      "type": "credit",
      "currency": "USD"
    },
    {
      "id": 98766,
      "date": "2026-06-15T16:00:00Z",
      "merchant": "Acme Corp",
      "recipient": "First National Bank",
      "description": "Funding instruction payout",
      "amount": 100000,
      "type": "debit",
      "currency": "USD"
    }
  ]
}
```

**`type` enum — read from `references/api-schema.md` before emitting:**
- `credit` — funds were moved **into** the funding balance (e.g. from settled transactions)
- `debit` — funds were moved **out of** the funding balance (e.g. a payout to a funding account)

**`recipient` is conditional.** It is only present in the response when `type` is `debit`. Do not assume it exists on credit records — your code must handle both cases.

**Amounts are in cents and always positive.** `"amount": 150000` means $1,500.00. Debit records do not carry a negative amount — use the `type` field to determine direction, not the sign of `amount`.

**`date` is UTC.** The `date` field is always an ISO 8601 datetime in UTC (e.g. `"2026-06-15T14:30:00Z"`). If displaying to users in a local timezone, convert from UTC accordingly. When filtering by `dateFrom`/`dateTo`, be aware the date boundaries apply to the UTC value of each record's `date` field. The API specification does not explicitly document whether `dateTo` is inclusive or exclusive — for reconciliation-critical scenarios (where a record at the boundary could be excluded or double-counted), verify the boundary behaviour with your Payroc contact before deploying.

**`id` is an integer — watch for overflow in JavaScript/TypeScript.** The `id` field is typed as `integer`. Activity record IDs can be large enough to exceed `Number.MAX_SAFE_INTEGER` (2^53-1). In JavaScript/TypeScript, `JSON.parse` silently truncates integers above this threshold — a subsequent `BigInt(record.id)` does not fix the problem, because the value is already corrupted before you receive it. To preserve precision, use a library that supports BigInt JSON parsing (e.g. `json-bigint`) or a custom `JSON.parse` reviver that captures the raw string before numeric conversion.

### Checkpoint

Does the API return HTTP 200 with a `data` array? If you get a `400` mentioning `dateFrom` or `dateTo`, both are required — add them. If the array is empty, try widening the date range or removing the `merchantId` filter.

---

## Step 4 — Handle pagination

Both endpoints use cursor-based pagination. The response includes:

| Field | Description |
| --- | --- |
| `hasMore` | `true` if there are more results beyond this page |
| `links` | Array of HATEOAS navigation links with cursors |
| `count` | Number of records on this page |
| `limit` | Maximum records per page |

To retrieve all results, loop until `hasMore` is `false`:
1. Make the initial request without `after`/`before`.
2. If `hasMore` is `true`, find the entry in `links` where `rel` is `"next"`. You have two equivalent options:
   - **Use the full `href` directly** as the next request URL — all required parameters (`after`, `dateFrom`, `dateTo`, etc.) are already embedded in it.
   - **Extract the `after` cursor** from the `href` and reconstruct the request yourself — but you must re-include `dateFrom` and `dateTo` explicitly, because they are required on every call to `/v1/funding-activity`, not just the first.
   Both options are correct. Using the full `href` directly is simpler and avoids the risk of forgetting a required parameter.
3. Repeat until `hasMore` is `false`.

**`links` entry structure:** `{ "rel": "next", "method": "GET", "href": "<full URL including cursor and all query params>" }`. For backward pagination, look for `rel: "prev"`. When `hasMore` is `false`, `links` is empty (`[]`). See `references/api-schema.md` for a populated example.

Do **not** pass `after` and `before` in the same request.

**Important for `/v1/funding-activity` pagination:** Include `dateFrom` and `dateTo` in **every** request in the pagination loop — not just the first request. These are required query parameters on every call, not just the initial one. Omitting them from any subsequent page request will return a `400` error.

**For polling / long-running services:** When implementing a service that polls for new funding activity repeatedly (e.g. every N minutes), compute `dateFrom` and `dateTo` dynamically on each poll — do not use fixed literal date strings. A typical pattern is:
- `dateTo` = today's date (UTC, formatted `YYYY-MM-DD`)
- `dateFrom` = today minus a lookback window (e.g. 1–7 days) to catch records that may arrive slightly after their activity date

Recompute both values at the start of each poll cycle. This ensures the date range stays current and never misses records due to a stale fixed range.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `400` mentioning `dateFrom` or `dateTo` | Required date parameters missing or wrong format | Add both `dateFrom` and `dateTo` in `YYYY-MM-DD` format to the `/funding-activity` request |
| `400` mentioning `before`/`after` conflict | Both pagination cursors sent | Use only one of `after` or `before` per request, not both |
| `400` other validation error | Malformed query parameter | Check each parameter against `references/api-schema.md` — read the `errors[].parameter` field in the response to identify which parameter failed |
| `401` on any request | Token missing, expired, or invalid API key | Re-generate Bearer token; verify `x-api-key` header value is the correct UAT API key |
| `403` | Insufficient permissions | Check API key scope; contact Payroc support |
| `406` | Not acceptable | Ensure the request does not include an `Accept` header that rejects `application/json` |
| `500` | Server error | Retry with exponential backoff |
| Empty `data` array | No records match the query | Widen the date range, remove `merchantId` filter, or confirm the account has funding activity |

**Reading validation errors:** Errors follow the RFC 7807 problem-details envelope (`type`, `title`, `status`, `detail`, `instance`) extended by Payroc's `errors[]` array. Each `errors[]` item has `parameter` (the JSON path of the failing field), `detail` (a short reason), and `message` (the human-readable explanation). Use `parameter` to identify which query parameter failed.

---

## Common pitfalls

- **Missing `dateFrom`/`dateTo`:** Both are required for `GET /v1/funding-activity`. Omitting either returns a `400`. The funding balance endpoint (`/funding-balance`) does not require date parameters.
- **`recipient` assumed always present:** The `recipient` field only appears on records where `type` is `debit`. Code that unconditionally reads `record['recipient']` or `record.recipient` will fail (KeyError/undefined) on `credit` records. Always use conditional access — for example in Python: `recipient = record.get('recipient', 'N/A')` or check `if record['type'] == 'debit': ...`. When correcting developer code that has this bug, always provide a safe-access code example.
- **Amounts misread as dollars:** All amount fields (`funds`, `pending`, `available`, `amount`) are integers in cents. Divide by 100 (or your currency's decimal factor) to display to users.
- **Mixing up `after` and `before` cursors:** These are mutually exclusive. Send one or the other per request.
- **Wrong `type` enum casing:** The valid values are `credit` and `debit` (lowercase). Read from `references/api-schema.md` — do not use `Credit`, `Debit`, `CREDIT`, or `DEBIT`.
- **Filtering with the wrong field (`?merchant=` instead of `?merchantId=`):** The filter query parameter is `merchantId` (the processor-assigned ID). The `merchant` field on each `activityRecord` is the DBA name string — it is not a valid filter parameter.
- **Reading `activityRecord.merchantId` (field does not exist):** Activity records carry `merchant` (DBA name), not `merchantId`. If you need to correlate an activity record to a specific merchant by ID, match using the `merchantId` you passed in the query filter — not a field on the record itself. If you called the endpoint without a `merchantId` filter (fetching activity for all merchants), there is no ID field on individual records to correlate against; the only identifier is the `merchant` DBA name string. For multi-merchant correlation by ID, call the endpoint separately for each `merchantId`.
- **Negating debit amounts:** All `amount` values are positive integers. The `type` field (`"credit"` or `"debit"`) indicates direction. Do not negate debit amounts — this produces incorrect net balance calculations.
- **Pagination links cursor extraction:** When `hasMore` is `true`, find the `links` entry where `rel` is `"next"` and parse the `after` value from its `href`. Do not pass `links[0]` directly as the cursor.

---

## Full field reference

Read `references/api-schema.md` for:
- Complete `merchantBalance` schema (funding-balance endpoint)
- Complete `activityRecord` schema (funding-activity endpoint)
- All enum values for `ActivityRecordType` (`credit` | `debit`)
- Pagination fields (`limit`, `count`, `hasMore`, `links`)
- Error response codes and shapes

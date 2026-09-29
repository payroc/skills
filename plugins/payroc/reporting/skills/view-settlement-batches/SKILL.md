---
name: view-settlement-batches
description: >
  Guides developers through querying Payroc card settlement batch data via the Reporting API
  (GET /v1/batches and GET /v1/batches/{batchId}). Use this skill when the user wants to
  list or retrieve settlement batches, look up daily batch summaries or settlement reports,
  check how much settled on a given date, query batch-level totals (saleAmount, heldAmount,
  returnAmount) or transaction counts per batch, build a settlement batch reporting integration,
  work with the /v1/batches endpoint, or understand how Payroc groups settled card transactions
  into daily batches. Also use when the user asks about batch IDs, batch amounts, batch status,
  or iterating through batches with pagination. Do NOT use for viewing individual settled
  transactions within a batch (use view-settled-transactions), ACH deposits or ACH batches
  (use view-ach-deposits), disputes (use view-disputes), or authorizations
  (use view-authorizations).
metadata:
  version: "0.2.1"
  category: reporting
  status: draft
---

# View Settlement Batches

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/reporting/skills/view-settlement-batches/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

Settlement batches are daily groupings of card transactions submitted to the card processor for
settlement. The Payroc Reporting API exposes two endpoints for batch data:

- **List batches** (`GET /v1/batches`) — returns all batches for a given date, optionally filtered
  by merchant. Fully testable against UAT.
- **Retrieve a batch** (`GET /v1/batches/{batchId}`) — returns the details of one specific batch by
  its ID. The UAT environment periodically wipes data, so this endpoint may return 404 for batches
  that existed earlier; it is documented here but cannot always be confirmed live in UAT.

Batch amounts are integers in the currency's **lowest denomination** (e.g. `saleAmount: 100` means
$1.00, not $100.00). For the complete field reference and example responses, read
`references/api-schema.md`.

---

## Quick reference

```text
GET  https://api.uat.payroc.com/v1/batches?date=YYYY-MM-DD
GET  https://api.uat.payroc.com/v1/batches/{batchId}
Authorization: Bearer <token>
```

No request body. No `Content-Type` or `Idempotency-Key` headers required — these are GET requests. If you set a custom `Accept` header, use `application/json` (or omit it entirely); any other value will return a 406.

---

## References

All field names, response shapes, and constraints for this skill come from local `references/`
files — not from memory and not from live lookups during a session.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | Endpoint paths, query parameters, response schemas, field names, example responses |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| Identity call reference | `references/identity-call.md` | Auth endpoint URL, request header, response fields — mandatory before any auth code |

These are local snapshots; their source URLs and last-synced dates are in
[`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Read the schema reference first — before writing code, reviewing code, or diagnosing errors.**
   Open `references/api-schema.md` before emitting any field name, reviewing a struct or model,
   or identifying the cause of an API error. Field names in the Payroc Reporting API (`batchId`,
   `saleAmount`, `heldAmount`, `processingAccountId`, etc.) must come from that reference. Do not
   rely on training-data guesses for field names, types, or required parameters.
2. **`date` is required for the list endpoint.** Without it the API returns a 400. Always include it.
3. **`batchId` is an integer**, not a string. Do not quote it in path construction.
4. **Amounts are in the lowest denomination.** A `saleAmount` of `100` for USD means $1.00. When
   displaying amounts to end users, divide by the appropriate minor unit factor (e.g. 100 for USD/GBP).
5. **Pagination is cursor-based.** Use the `after`/`before` cursors from the **top-level** `response.links` array (not from the per-batch `data[n].links` array, which contains HATEOAS resource links, not cursors).
   Do not use offset pagination. Do not send both `after` and `before` in the same request.
6. **Never hardcode credentials.** API keys must come from environment variables.
7. **No idempotency key needed** — these are read-only GET requests; the Idempotency-Key header
   is only required on POST and PATCH requests.
8. **Diagnose before proceeding** — if a step fails, read `references/api-schema.md` and then work
   through the error taxonomy before concluding what went wrong.

---

## Prerequisites

These are needed to **run and test** the integration — not to write the code.

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by
   the Payroc Integrations team.
2. **UAT environment access** — Payroc's test environment. Terminals are provisioned manually by
   the Payroc Integrations team. Note: the UAT environment periodically wipes data, so some batch
   records may not persist long-term.

**If the API key is missing — warn, don't block.** Wire the code to read from `PAYROC_API_KEY` (or
the existing env var convention in the codebase) and tell the developer plainly what they need to
obtain from the Integrations team.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Exchange your API key for a Bearer token:

```bash
# Test / UAT
curl -X POST https://identity.uat.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"

# Production
curl -X POST https://identity.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"
```

The response includes `access_token`, `expires_in` (3600 seconds), and `token_type` ("Bearer").
Use `Authorization: Bearer <access_token>` on every subsequent API call.

Store the API key in an environment variable — never inline it.

### Checkpoint

Can the token exchange return a non-empty `access_token`? If not, verify the `x-api-key` header
value and confirm the API key is provisioned for the UAT environment.

---

## Step 2 — List settlement batches

### Endpoint

```text
GET https://api.uat.payroc.com/v1/batches?date=YYYY-MM-DD
Authorization: Bearer <token>
```

### Required parameters

> **Read `references/api-schema.md` before building the request.** The query parameter names and
> response field names must come from the reference — do not guess them from training data.

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| `date` | `YYYY-MM-DD` | **Yes** | The date batches were submitted. Omitting it returns a 400. |
| `merchantId` | string | No | Filter to a specific merchant by processor-assigned merchant ID |
| `limit` | integer | No | Results per page (default: 10) |
| `after` | string | No | Cursor for next page — use value from response `links` |
| `before` | string | No | Cursor for previous page — do not combine with `after` |

### Example request

```bash
curl "https://api.uat.payroc.com/v1/batches?date=2024-07-02" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### Response (200)

The response is a paginated list:

```json
{
  "limit": 10,
  "count": 1,
  "hasMore": false,
  "links": [],
  "data": [
    {
      "batchId": 65,
      "date": "2024-07-02",
      "createdDate": "2024-07-02",
      "lastModifiedDate": "2024-07-02",
      "saleAmount": 100,
      "heldAmount": 0,
      "returnAmount": 0,
      "transactionCount": 10,
      "currency": "USD",
      "merchant": {
        "merchantId": "4525644354",
        "doingBusinessAs": "Pizza Doe",
        "processingAccountId": 38765,
        "link": {
          "rel": "self",
          "method": "GET",
          "href": "https://api.payroc.com/v1/processing-accounts/38765"
        }
      },
      "links": [
        {
          "rel": "transactions",
          "method": "GET",
          "href": "https://api.payroc.com/v1/transactions?batchId=65"
        }
      ]
    }
  ]
}
```

Key fields per batch:

| Field | Notes |
| --- | --- |
| `batchId` | Integer — save this if you need to retrieve the batch later |
| `saleAmount` | Total sales in lowest denomination (e.g. cents for USD) |
| `heldAmount` | Total authorization (held) value in the lowest denomination — this represents card authorizations captured in the batch, not a risk-reserve hold. Use `saleAmount` for gross settled sales; `heldAmount` is a separate authorization figure. |
| `returnAmount` | Total returns/refunds |
| `transactionCount` | Number of transactions in the batch |
| `currency` | ISO 4217 code |
| `merchant.merchantId` | Processor-assigned merchant ID — always a **string**, even when the value looks numeric (e.g. `"4525644354"`) |
| `merchant.doingBusinessAs` | Merchant's DBA (trading) name — the full field name is `doingBusinessAs` (not `dba`, `businessName`, or `tradingName`) |
| `merchant.processingAccountId` | **Integer** — Payroc processing account ID. **Do not quote or deserialise this as a string.** Unlike `merchant.merchantId` (which is a string), this field is a numeric type — `int` in C#, `number` in TypeScript, `int64` in Go. |
| `merchant.link` | HATEOAS link (singular object, not an array) — `{ rel, method, href }` pointing to the processing account resource |
| `links` | Per-batch HATEOAS links to drill into transactions or authorizations (this is the batch-level `links`, not the top-level pagination `links`) |

### Pagination

The response has **two distinct `links` arrays** — do not confuse them:

- **Top-level `links`** (`response.links`) — pagination cursors (next/previous page). This is the one to use for `after`/`before`.
- **Per-batch `links`** (`response.data[n].links`) — HATEOAS links to related resources (transactions, authorizations). These are **not** pagination cursors.

If `hasMore` is `true`, another page exists. When there are more pages, the top-level `links`
array is populated with an entry where `rel` is `"next"`. The `href` field of that entry is the
full URL for the next page — extract the `after` query parameter value from it (or pass the full
`href` directly, depending on your HTTP client):

```json
{
  "limit": 10,
  "count": 10,
  "hasMore": true,
  "links": [
    {
      "rel": "next",
      "method": "GET",
      "href": "https://api.uat.payroc.com/v1/batches?date=2024-07-02&after=<cursor>"
    }
  ],
  "data": [ ... ]
}
```

Retrieve the next page using the `after` cursor from the top-level `response.links` entry
(not from `data[n].links`):

```bash
curl "https://api.uat.payroc.com/v1/batches?date=2024-07-02&after=<cursor-from-response.links>" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

Do not send `after` and `before` in the same request. To navigate backwards, look for a `"prev"`
entry in the top-level `links` array and use its `href` to get the `before` cursor value.

### Checkpoint

Does the response return HTTP 200 with a `data` array? An empty array (`"data": []`) means no
batches exist for that date — try a different date. If you receive a 400, check that `date` is
present and in `YYYY-MM-DD` format.

---

## Step 3 — Retrieve a specific batch

> **UAT data note:** The UAT environment periodically wipes data. `GET /v1/batches/{batchId}`
> may return 404 for a batch that existed earlier in the same UAT session. This is expected
> UAT behaviour — it does not indicate a production limitation. In production, batch records
> persist.

### Endpoint

```text
GET https://api.uat.payroc.com/v1/batches/{batchId}
Authorization: Bearer <token>
```

`batchId` is an **integer** — do not quote it.

### Example request

```bash
curl "https://api.uat.payroc.com/v1/batches/65" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### Response (200)

Returns the same batch object shape as items in the list response — see Step 2 for field
descriptions.

### Checkpoint

HTTP 200 with the expected `batchId` in the response. If you receive 404, the batch ID either
doesn't exist or has been wiped in UAT. Use the list endpoint with the batch's date to confirm
whether the batch still exists.

---

## Error taxonomy

> **Before diagnosing any API error, read `references/api-schema.md`** to confirm the correct
> parameter names, types, and required fields. Do not diagnose from memory.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 400 — missing `date` parameter | The `date` query parameter was omitted | Add `?date=YYYY-MM-DD` to the list request |
| 400 — invalid `date` format | `date` not in `YYYY-MM-DD` format | Reformat to ISO 8601 date (e.g. `2024-07-02`) |
| 400 — `before` and `after` both set | Cursor conflict in pagination | Use only one of `before` or `after` per request |
| 401 — Unauthorized | Bearer token missing, expired, or malformed | Re-authenticate via the identity service; check `x-api-key` header |
| 403 — Forbidden | API key scope does not include reporting | Contact Payroc Integrations team to confirm the API key has reporting access |
| 404 — Batch not found | `batchId` does not exist or was wiped in UAT | Use list endpoint with the date to confirm the batch still exists |
| 406 — Not acceptable | `Accept` header mismatch (not `Content-Type`) | Remove the custom `Accept` header or set it to `application/json`. Do **not** add or change `Content-Type` — that header has no effect on GET requests and will not fix a 406. |
| 500 — Server error | Transient server issue | Retry with exponential backoff |
| Amounts seem wrong (e.g. 100 for $1.00) | Amounts are in lowest denomination (cents) | Divide by minor unit factor: `saleAmount / 100` for USD/GBP |
| Empty `data` array | No batches on that date | Try a different date; UAT data may be sparse after a wipe |
| `before`/`after` cursor pagination returns wrong page | Wrong cursor value | Use the cursor from the `links` array in the response, not a manually constructed value |

---

## What this skill does not cover

- **Settled transactions within a batch** — use the `view-settled-transactions` skill
  or follow the `links` in the batch response to fetch transactions directly.
- **ACH deposits** — covered by the `view-ach-deposits` skill.
- **Disputes** — covered by the `view-disputes` skill.
- **Authorizations** — covered by the `view-authorizations` skill.
- **Writing or modifying batches** — the Payroc Reporting API is read-only for batch data.

---

## Full field reference

Read `references/api-schema.md` for:
- Complete field definitions for batch objects and the merchant summary sub-object
- All query parameter names and types
- Full example request and response JSON
- Response code descriptions

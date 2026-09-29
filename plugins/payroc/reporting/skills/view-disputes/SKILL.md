---
name: view-disputes
description: >
  Guides developers writing code to query the Payroc Disputes API (read-only) — listing disputes,
  retrieving dispute status history, or paginating through chargeback records. Use this skill when
  the user wants to implement dispute reporting, call GET /v1/disputes or GET
  /v1/disputes/{id}/statuses, list or filter chargeback records by date or merchant, check a
  dispute's current status via the API, build a chargeback reporting dashboard, sync dispute data
  into a platform, or troubleshoot HTTP errors (400, 401, 404) from the disputes endpoint. Do NOT
  use for contesting disputes, submitting chargeback responses, responding to chargebacks, or any
  write operation — the Disputes API exposes only LIST and GET endpoints. Do NOT use for general
  questions about the chargeback process, dispute notifications, or settlement batches.
metadata:
  version: "0.3.1"
  category: reporting
  status: eval-complete
---

# View Disputes

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/reporting/skills/view-disputes/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

The Payroc Disputes API is a **read-only reporting surface**. It lets you list disputes (chargebacks)
submitted against a merchant's transactions and retrieve the full status history for any individual
dispute. There are no mutation endpoints — disputes cannot be created, updated, or deleted via the API.

For the complete field reference, enum values, and schema details, read `references/api-schema.md`
(load it when you need enum values, response shapes, or pagination details).

---

## Quick reference

```text
GET  https://api.uat.payroc.com/v1/disputes?date=YYYY-MM-DD
GET  https://api.uat.payroc.com/v1/disputes/{disputeId}/statuses
Authorization: Bearer <token>
```

No request body. No `Idempotency-Key` header (GET requests only).

---

## References

All enum values and schemas live in the local `references/` files below. This skill emits from them,
not from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| Identity call reference | `references/identity-call.md` | Bearer token exchange — endpoint URL, headers, response shape |
| API schema reference | `references/api-schema.md` | All enum values (disputeType, status), response schemas, pagination, date format |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core principles

1. **Read `references/api-schema.md` before writing or reviewing any disputes code.** Both `disputeType`
   and `status` have large enum sets with values that are easy to misspell or misremember (e.g.
   `prearbitrationInProcess`, `arbitrationFiledWithCardBand`). Read `references/api-schema.md` before
   writing any disputes API code (even a simple GET URL), before emitting any enum values, and before
   reviewing or correcting anyone else's disputes code. Do not use training-data guesses. A
   plausible-sounding value that isn't in the documented enum will produce a 400 or silent mismatch.
2. **The `date` parameter is required** — list disputes will return a 400 without it.
3. **Pagination is cursor-based.** Use `after` or `before` (not both) with the cursor value from the
   previous response. Do not mix cursor pagination with numeric offsets.
4. **`disputeId` is an integer**, not a string. Pass it as a path segment: `/v1/disputes/12345/statuses`.
5. **Amounts are in the lowest currency denomination** — `disputeAmount: 5000` means $50.00 USD.
6. **Dates use YYYY-MM-DD format** throughout (filter parameter, response dates, status dates).
7. **Never hardcode credentials.** API keys must come from environment variables or a secrets manager.
8. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). All subsequent
API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. For production code, include expiry
tracking and refresh logic — tokens that expire mid-operation will produce 401s on otherwise valid requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header value and
confirm the API key is correct for the target environment.

---

## Step 2 — List disputes

Endpoint: `GET https://api.uat.payroc.com/v1/disputes`

Required headers:
```
Authorization: Bearer <token>
```

No request body, no `Idempotency-Key` (GET request).

### Required parameter

`date` (YYYY-MM-DD) — **required**. Omitting this parameter results in a 400 validation error.

```bash
# List disputes for a specific date
curl "https://api.uat.payroc.com/v1/disputes?date=2024-02-01" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### Optional parameters

| Parameter | Description | Notes |
| --- | --- | --- |
| `merchantId` | Filter by merchant ID | Processor-assigned; narrows results to a specific merchant |
| `limit` | Max results per page | Integer; defaults to 10 |
| `after` | Next-page cursor | From `links` in the previous response; mutually exclusive with `before` |
| `before` | Previous-page cursor | From `links` in the previous response; mutually exclusive with `after` |

```bash
# Filtered — specific merchant, custom page size
curl "https://api.uat.payroc.com/v1/disputes?date=2024-02-01&merchantId=M12345&limit=25" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### Response (200 OK)

The response is a paginated envelope. (You should have already read `references/api-schema.md` per Core Principle 1 — if not, do so now before continuing.) Key fields:

```json
{
  "limit": 10,
  "count": 2,
  "hasMore": true,
  "links": [
    { "rel": "next", "href": "..." }
  ],
  "data": [
    {
      "disputeId": 12345,
      "disputeType": "firstDispute",
      "currentStatus": {
        "disputeStatusId": 67890,
        "status": "representmentInProgress",
        "statusDate": "2024-02-05"
      },
      "createdDate": "2024-02-01",
      "receivedDate": "2024-01-30",
      "disputeAmount": 5000,
      "currency": "USD",
      "referenceNumber": "REF-ABC123",
      "merchant": {
        "merchantId": "M12345",
        "businessName": "Acme Widgets"
      },
      "transaction": {
        "transactionId": "TXN-789",
        "type": "sale",
        "amount": 5000
      }
    }
  ]
}
```

> **Read `references/api-schema.md` before interpreting `disputeType` or `status` values.** Do not
> assume meanings from naming — the full enum list and descriptions are in the reference.

### Paginating through results

If `hasMore` is `true`, the `links` array contains a `next` link object:

```json
"links": [
  { "rel": "next", "href": "https://api.uat.payroc.com/v1/disputes?date=2024-02-01&after=eyJsYXN0SWQiOjEyMzQ1fQ" }
]
```

The cursor is the value of the `after` query parameter **inside** the `href` URL — not the full URL itself. Extract it by parsing the `href` as a URL and reading the `after` query parameter, then pass that token as `after` in your next request:

```bash
# Subsequent page — pass the cursor token extracted from links[rel=next].href's after= param
curl "https://api.uat.payroc.com/v1/disputes?date=2024-02-01&after=eyJsYXN0SWQiOjEyMzQ1fQ" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

Do **not** pass the full `href` URL as the `after` value — the API expects only the cursor token, not the complete URL string. To find the next link: look for the entry in `links` where `rel === "next"`, then parse the `href` to extract the `after` query parameter value.

Never combine `after` and `before` in the same request.

### Checkpoint

Does the response include a `data` array (even if empty)? If you receive a 400, check that `date` is
present and in `YYYY-MM-DD` format. If you receive a 401, exchange a new token.

---

## Step 3 — Retrieve dispute status history

To see the full lifecycle of a specific dispute, fetch its status history.

Endpoint: `GET https://api.uat.payroc.com/v1/disputes/{disputeId}/statuses`

`disputeId` is an **integer** from the list response — use it as a path segment, not a query parameter.

```bash
curl "https://api.uat.payroc.com/v1/disputes/12345/statuses" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### Response (200 OK)

Returns a **plain array** (not a paginated envelope) of status objects in chronological order:

```json
[
  {
    "disputeStatusId": 100,
    "status": "new",
    "statusDate": "2024-01-30"
  },
  {
    "disputeStatusId": 101,
    "status": "representmentInProgress",
    "statusDate": "2024-02-05"
  }
]
```

> **Read the `status` enum values from `references/api-schema.md` before emitting or interpreting
> them.** There are 22 possible status values; do not guess spellings. The full enum is in the
> reference.

### Checkpoint

Does the response return an array of status objects? If you receive a 404, confirm the `disputeId` is
correct (integer, from the list response). If you receive a 401, exchange a new token.

---

## Error taxonomy

| Status | Scenario | Action |
| --- | --- | --- |
| 400 — missing `date` | The `date` query parameter was not provided on list disputes | Add `?date=YYYY-MM-DD` to the request |
| 400 — invalid `date` format | Date not in `YYYY-MM-DD` format | Reformat date; ISO 8601 only |
| 400 — both `after` and `before` sent | Mutually exclusive pagination parameters | Use only one cursor direction per request |
| 401 | Token missing, expired, or API key wrong | Re-exchange API key for a new Bearer token; verify `x-api-key` header is the correct key for this environment |
| 403 | Insufficient permissions | Check API key scope; contact Payroc support |
| 404 | Dispute not found (status history endpoint) | Verify `disputeId` is an integer from a valid list-disputes response |
| 406 | Not acceptable | Ensure `Accept` header is not set to an unsupported type (or omit it entirely) |
| 500 | Server error | Retry with exponential backoff |

**Reading validation errors** — error responses use the **RFC 7807 problem-details envelope** (`type`,
`title`, `status`, `detail`, `instance`); Payroc **extends** this with an `errors` array. Each `errors[]`
item carries `parameter` (the failing field path), `detail` (short reason), and `message` (human-readable).
Use `errors[].parameter` to identify which input caused the validation failure.

---

## Common pitfalls

- **Missing `date` parameter:** The list disputes endpoint requires `date` — it is not optional. Omitting it returns a 400.
- **Wrong date format:** Use `YYYY-MM-DD` only. Formats like `DD/MM/YYYY` or Unix timestamps are rejected.
- **Combining `after` and `before`:** These cursor parameters are mutually exclusive. Use one or the other for pagination direction.
- **Passing the full `href` as the cursor:** The `after` value is the cursor token embedded in the `href` query string, not the full `href` URL. Parse `links[rel=next].href` as a URL and extract its `after` query parameter — do not pass the entire URL string as the `after` value, as this will produce a 400.
- **`disputeId` as string:** `disputeId` is an integer; do not wrap it in quotes or format it as `DIS-12345`.
- **Amounts in major units:** `disputeAmount` and `feeAmount` are integers in the lowest currency denomination (cents, pence). Divide by 100 for display; do not submit major units.
- **Guessing status values:** The `status` enum has 22 values with precise spellings. Always read from `references/api-schema.md`. In particular, `arbitrationFiledWithCardBand` and `complianceFiledWithCardBand` are spelled with `CardBand` (not `CardBrand`) — this is the verbatim spelling the API uses; do not "correct" it to `CardBrand`.

---

## Full field reference

Read `references/api-schema.md` for:
- All `disputeType` enum values
- All `status` enum values (22 values — do not guess)
- Complete nested object schemas (card, merchant, transaction, currentStatus)
- HTTP status codes and their meanings
- Pagination mechanics

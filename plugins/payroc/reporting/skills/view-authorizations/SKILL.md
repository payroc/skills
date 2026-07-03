---
name: view-authorizations
description: >
  Guides developers through querying Payroc authorization records via the Reporting API
  (GET /v1/authorizations and GET /v1/authorizations/{authorizationId}). Use this skill
  when the user wants to view, list, or retrieve authorization records, check pre-authorization
  responses, look up card authorization history, filter authorizations by date or batch ID,
  retrieve a specific authorization by its integer ID, build a reporting integration for
  authorization data, inspect the bank's authorizationResponse codes, view open or pending
  authorizations, check which card transactions were approved or declined by the issuing bank,
  or query the /v1/authorizations endpoint. Also use for any read-only authorization reporting
  feature — even if the user does not use the word "skill" explicitly. Do NOT use for creating
  pre-authorizations or card payments (use run-a-pre-authorization or run-a-card-sale), viewing
  settlement batches or batch totals (use view-settlement-batches), viewing settled transactions
  (use view-settled-transactions), ACH deposits (use view-ach-deposits), or disputes
  (use view-disputes).
metadata:
  version: "0.1.0"
  category: reporting
  status: draft
---

# View Authorizations

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/reporting/skills/view-authorizations/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

The Payroc Reporting API exposes authorization records — the batch-level snapshot of what the
issuing bank approved, denied, or responded to for each card transaction. This skill covers two
read-only GET endpoints:

- **List authorizations** — paginated, filtered by date or batch
- **Retrieve an authorization** — single record by `authorizationId`

For all enum values, field types, and response schemas, read `references/api-schema.md`.

---

## Quick reference

```
GET  https://api.uat.payroc.com/v1/authorizations
GET  https://api.uat.payroc.com/v1/authorizations/{authorizationId}
Authorization: Bearer <token>
```

No `Idempotency-Key` or `Content-Type` headers are required — these are GET requests.

---

## References

All enum values and schemas live in the local `references/` files below — this skill emits from
them, not from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | **All** enum values, query parameters, request/response schemas, status codes, example responses |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| Identity call reference | `references/identity-call.md` | Bearer token exchange — endpoint URL, request header, response fields |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md).

---

## Core Principles

1. **Read `references/api-schema.md` before emitting any enum value.** The `authorizationResponse`
   field has 80+ possible values — never guess or infer from training data. Card type, transaction
   type, and entry method also have documented enum sets. Read the reference before emitting any
   of these. The same discipline applies when reviewing developer-supplied code. **Important:**
   common guesses like `declined`, `canceled`, `pending`, `fraud`, and `timeout` are NOT valid
   `authorizationResponse` values — the full list is in the reference and must be read before
   emitting any categorization logic.
2. **Read `references/identity-call.md` before emitting any auth code.** Do not guess the endpoint
   URL, header name, or response shape — use only what the reference documents.
3. **These endpoints are read-only.** There is no POST, PATCH, or DELETE on `/v1/authorizations`.
   Authorizations are created implicitly by payment transactions — this API is for reporting only.
4. **`date` or `batchId` is required for listing.** The list endpoint rejects requests that omit
   both filters. Confirm with the developer which filter they need before writing code.
5. **Never hardcode credentials.** API keys must come from environment variables, never source code.
6. **Paginate with cursors, not offsets.** Use `before`/`after` with `limit` — not offset-based
   pagination. Do not use `before` and `after` together in the same request.
7. **`authorizationId` is an integer.** The retrieve endpoint uses an integer path parameter —
   not a string or UUID.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework in use
- Any existing HTTP client, authentication, or token-management code
- How environment variables are managed
- Any existing reporting or data-export workflows

Use what you find to pre-fill obvious answers. Then ask:

1. **Which operation?** List authorizations (filtered by date or batch) or retrieve a specific
   authorization by ID? Or both?
2. **Filter type** (for list): date filter (`YYYY-MM-DD`) or batch ID filter (integer)?
3. **Merchant filter**: Does the developer need to filter by `merchantId`? If so, do they know it?
4. **Pagination**: Is a single page enough, or does the integration need to page through all results?

Use the answers to skip sections that don't apply.

---

## Prerequisites

These are needed to run and test the integration in UAT. If the developer already has them, skip ahead.

1. **API key** — used to generate Bearer tokens. Provisioned by the Payroc Integrations team.
2. **A date or batch ID** — required for the list endpoint. The developer must know which batch
   or date they want to query.
3. **`authorizationId`** (retrieve only) — the integer ID of a specific authorization record. This
   comes from a prior list call or from transaction metadata.
4. **UAT environment** — `api.uat.payroc.com`. No self-serve signup; provisioned by Payroc.

**If anything is missing — warn, don't block.** Write the code to read credentials from environment
variables (e.g. `PAYROC_API_KEY`), then tell the developer what they'll need to run or test it.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Exchange your API key for a Bearer token at the identity service:

- UAT: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

Response contains `access_token`, `expires_in` (3600 seconds), `token_type` ("Bearer"), and `scope`. Use the
token in `Authorization: Bearer <access_token>` on all subsequent requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

For long-running services, track the token's issue time and refresh proactively before the 1-hour
expiry — a token that expires mid-operation causes a 401 on an otherwise valid request.

### Checkpoint

Can the helper generate a Bearer token without error? If not, verify the `x-api-key` header and
confirm the API key is valid for the UAT environment.

---

## Step 2 — List Authorizations

Endpoint: `GET https://api.uat.payroc.com/v1/authorizations`

Required headers:
```
Authorization: Bearer <token>
```

**No Idempotency-Key or Content-Type headers are needed for GET requests.**

> **Read `references/api-schema.md` before writing query parameters.** Confirm the exact parameter
> names (`date`, `batchId`, `merchantId`, `before`, `after`, `limit`) from the reference — do not
> guess. The `date` and `batchId` filter constraint (one is required) is also documented there.

### Query parameter rules

| Parameter | Type | Notes |
| --- | --- | --- |
| `date` | string (YYYY-MM-DD) | Conditional — required if `batchId` not provided |
| `batchId` | integer | Conditional — required if `date` not provided |
| `merchantId` | string | Optional — filter by processor-assigned merchant ID |
| `limit` | integer | Optional — max results per page (default: 10) |
| `after` | string | Optional — cursor for next page; cannot be used with `before` |
| `before` | string | Optional — cursor for previous page; cannot be used with `after` |

**Either `date` or `batchId` must be present** — at least one is required. A request with neither will fail with a 400.

### Example request — filter by date

```bash
curl -G https://api.uat.payroc.com/v1/authorizations \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode "date=2024-07-02" \
  --data-urlencode "limit=20"
```

### Pagination loop

```
while hasMore:
    fetch page (with 'after' cursor from previous response's links)
    process data[]
    if hasMore == false: break
```

Each response includes `hasMore` (boolean) and `links` (HATEOAS navigation). When `hasMore` is
true, find the entry in `links` with `rel: "next"` and use its `href` value **directly** as the
URL for the next request — do not parse or extract a cursor token from the URL. The `href` is
a fully-formed URL with all required query parameters already embedded (including the `after`
cursor value). Simply GET that URL as-is, adding only the `Authorization` header.

Example — next-page link in a paginated response:

```json
{
  "links": [
    { "rel": "self",   "method": "get", "href": "https://api.uat.payroc.com/v1/authorizations?date=2024-07-02&limit=20" },
    { "rel": "next",   "method": "get", "href": "https://api.uat.payroc.com/v1/authorizations?date=2024-07-02&limit=20&after=<cursor>" }
  ]
}
```

To fetch the next page, GET the `href` from `rel: "next"` directly — do not reconstruct the URL.

### Checkpoint

Does the response return HTTP 200 with a `data` array and `hasMore` field? If not, work through
the error taxonomy.

---

## Step 3 — Retrieve a Specific Authorization

Endpoint: `GET https://api.uat.payroc.com/v1/authorizations/{authorizationId}`

`authorizationId` is an **integer** — not a string or UUID.

Required headers:
```
Authorization: Bearer <token>
```

### Example request

```bash
curl https://api.uat.payroc.com/v1/authorizations/65 \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

A 200 response returns a single authorization object. A 404 means the `authorizationId` does not
exist — verify the ID from a prior list response.

### Checkpoint

Does the response return HTTP 200 with an `authorizationId` field? If not, check that the ID is an
integer and matches a record returned by the list endpoint.

---

## Step 4 — Process the Response

> **Read `references/api-schema.md` before writing any code that reads or displays
> `authorizationResponse`, `card.type`, `transaction.type`, or `transaction.entryMethod`.**
> These are enum fields — use only the documented values. Do not derive or guess the set.

### Key response fields

| Field | Type | Notes |
| --- | --- | --- |
| `authorizationId` | integer | Unique identifier |
| `createdDate` | string (YYYY-MM-DD) | Date authorization was received |
| `lastModifiedDate` | string (YYYY-MM-DD) | Last modification date |
| `authorizationResponse` | enum string | Bank's response code — 80+ possible values; see schema |
| `preauthorizationRequestAmount` | integer | Amount in lowest denomination (e.g. cents) |
| `currency` | string (ISO 4217) | e.g. `"USD"`, `"GBP"` |
| `batch` | object or null | Batch summary; null if not yet batched |
| `card.cardNumber` | string | Masked card number, e.g. `"453985******7062"` |
| `card.type` | enum string | Card network — see schema for full list |
| `transaction` | object or null | Transaction summary; null if no associated transaction on this authorization |
| `transaction.transactionId` | integer or null | Associated transaction ID |
| `transaction.type` | enum string | `capture` or `return` |
| `transaction.entryMethod` | enum string | How the card was presented — see schema |
| `transaction.amount` | integer | Amount in lowest denomination |
| `merchant.merchantId` | string | Processor-assigned merchant ID |
| `merchant.doingBusinessAs` | string | Trading name |

**Amounts are in the lowest currency denomination** — e.g. `10000` means $100.00 USD. Display
by dividing by 100 (or the appropriate minor-unit factor for the currency).

**`authorizationResponse` has 80+ possible values.** The most common positive responses are
`approved`, `approveVip`, `approveWithId`, `honorWithId`, `partialApproval`,
`partialAuthorization`, and `successful`. Build any switch/match logic from the documented enum in
`references/api-schema.md`, not from a remembered subset.

**`batch` may be null** — an authorization that has not yet been batched will have `batch: null`.
Handle this case explicitly. When a developer reports a NullPointerException or null-dereference
on the batch field, always provide a corrected code example with an explicit null check (e.g.
`if (authorization.getBatch() != null)` in Java, `if authorization.batch:` in Python, or
`if (authorization.batch)` in TypeScript/Go) — not just a verbal explanation.

**HATEOAS links** — the `batch.link`, `merchant.link`, and `transaction.link` objects provide
navigable URLs to related records. Use these rather than constructing URLs manually.

---

## Error taxonomy

> Errors use the **RFC 7807 problem-details format** as the envelope (`type`, `title`, `status`,
> `detail`, `instance`). Payroc **extends** the envelope with an `errors` array (Payroc's own, not
> RFC-defined). Each `errors[]` item carries `parameter` (JSON path of the failing field), `detail`
> (short reason), and `message` (human-readable explanation). Use `parameter` to map each error back
> to the request.

| Status | Symptom | Fix |
| --- | --- | --- |
| 400 | Missing `date` and `batchId` | Add at least one of `date` (YYYY-MM-DD) or `batchId` (integer) as a query parameter |
| 400 | Malformed `date` | Use ISO 8601 format: `YYYY-MM-DD` |
| 400 | `before` and `after` used together | Use one cursor at a time — not both |
| 401 | Token missing, expired, or API key wrong | Re-generate Bearer token; verify `x-api-key` header uses the correct UAT API key |
| 403 | Insufficient permissions | Check API key scope; contact Payroc support |
| 404 | `authorizationId` not found (retrieve only) | Verify the integer ID from a prior list response |
| 406 | Not acceptable | Check `Accept` header — omit it entirely for the default JSON response |
| 500 | Server error | Retry with exponential backoff; surface `errors` array if present |

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] No `Idempotency-Key` or `Content-Type` header on GET requests (not needed)
- [ ] List endpoint: either `date` (YYYY-MM-DD) or `batchId` (integer) query parameter present
- [ ] `before` and `after` cursor parameters not used simultaneously
- [ ] `authorizationId` passed as an integer for the retrieve endpoint
- [ ] `authorizationResponse` values read from `references/api-schema.md` — not from memory
- [ ] `card.type`, `transaction.type`, and `transaction.entryMethod` enum values read from `references/api-schema.md`
- [ ] `batch` field handled for the null case (unbatched authorization)
- [ ] Amounts displayed correctly (lowest denomination ÷ 100 for USD/GBP/EUR)
- [ ] UAT endpoints used (`api.uat.payroc.com`) — not production endpoints during testing

---

## Completion

Once all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **List authorizations** (if built) — filters by [date / batchId]; pagination via cursor; processes all fields.
> - **Retrieve authorization** (if built) — fetches single record by integer `authorizationId`.
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Use production credentials.

Offer next steps:
- **View disputes** — retrieve and list dispute records linked to transactions
- **View settlement batches** — query batch summaries and settled transactions
- **Run a card sale** — create payment transactions that generate authorization records via `POST /v1/payments`; to create a pre-authorization specifically, use the run-a-pre-authorization skill

---
name: view-settled-transactions
description: >
  Guides developers through querying Payroc's Settlement Reporting API to retrieve
  settled transactions and settlement batches (GET /v1/batches, GET /v1/transactions).
  Use this skill when the user wants to view settled (batched/cleared) transactions,
  retrieve post-settlement data, reconcile payments against a settlement batch, list
  settled transactions within a specific batch, look up which transactions are in a
  given batch, build a settlement reconciliation workflow, look up a settled transaction
  by batch ID or settlement date, inspect the settled.achDate or settled.achDepositId
  fields on transaction records, or work with the /v1/batches or /v1/transactions
  reporting endpoints. Also trigger when someone asks about daily settlement reports,
  end-of-day reconciliation, batch transaction lists, settlement totals, or matching
  captured card payments to settlement batch records.
  Do NOT use for: viewing standalone ACH deposit records or ACH deposit fees
  (use view-ach-deposits), viewing authorization records (use view-authorizations),
  processing payments, creating refunds, or checking real-time authorization status.
metadata:
  version: "0.1.0"
  category: reporting
  status: draft
---

# View Settled Transactions

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/reporting/skills/view-settled-transactions/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

> **UAT data note.** The Payroc UAT environment periodically wipes settlement data, so queries against `api.uat.payroc.com` may return empty results even with a valid API key. This is expected UAT behaviour — it does not indicate a code problem or a production limitation. If UAT returns empty results for `/v1/batches` or `/v1/transactions`, advise the developer to: (1) try a recent past date (within the last 7 days); (2) contact the Payroc Integrations team for a UAT environment with seed data; or (3) treat the empty response as a successful call and proceed to production testing. The endpoints and schemas documented here match the production API spec.

---

## Quick reference

```text
# Step 1 — Find batches for a date (date = batch submission date, not original authorization date)
GET  https://api.uat.payroc.com/v1/batches?date=YYYY-MM-DD
Authorization: Bearer <token>

# Step 1b (optional) — Retrieve a single batch by ID
GET  https://api.uat.payroc.com/v1/batches/{batchId}
Authorization: Bearer <token>

# Step 2 — Get transactions in a batch (from batchId in step 1 response)
GET  https://api.uat.payroc.com/v1/transactions?batchId={batchId}
Authorization: Bearer <token>

# Alternative — Get all transactions for a date directly (date = batch submission date, not transaction date)
GET  https://api.uat.payroc.com/v1/transactions?date=YYYY-MM-DD
Authorization: Bearer <token>

# Step 3 (optional) — Retrieve a single transaction
GET  https://api.uat.payroc.com/v1/transactions/{transactionId}
Authorization: Bearer <token>
```

These are **read-only** (GET) endpoints. No `Idempotency-Key` header is required.

---

## References

All enum values, schemas, and endpoint details live in the local `references/` files. Emit from these — not from memory, not from live lookups.

| File | Use for |
| --- | --- |
| `references/identity-call.md` | Identity Service endpoint, token exchange request/response schema |
| `references/api-schema.md` | All endpoint paths, query parameters, required-field sets, enum values, response schemas |
| `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| `references/settlement-data-guide.md` | Settlement workflow narrative, reconciliation patterns, Reporting API vs. Payments API distinction |

These are local snapshots authoritative for this skill. Source URLs and last-synced dates are recorded in [`references/_sources.md`](references/_sources.md).

---

## Core Principles

1. **Inspect before asking** — scan the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through intake before writing implementation code.
3. **Read the schema reference before emitting any enum or parameter value.** Every query parameter that accepts a fixed set of values — especially `transactionType` — is documented in `references/api-schema.md`. Read it before emitting any value. Do not use training-data guesses.
4. **No `Idempotency-Key` required.** These are GET endpoints; idempotency headers are only needed for state-changing (POST/PATCH) operations. Do not add this header.
5. **Never hardcode credentials.** API keys must come from environment variables, never source code.
6. **Bearer token expiry.** Tokens expire after 3,600 seconds (1 hour). For recurring reconciliation jobs, implement token refresh.
7. **Validate before advancing** — confirm each step's checkpoint before moving to the next.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing HTTP client or API client setup
- Existing reconciliation or reporting code
- How environment variables are managed
- Whether the developer already has a `merchantId` or `batchId`

Use what you find to pre-fill obvious answers and ask targeted questions.

**What does the developer need? Ask them to select all that apply:**

- **[Always included]** List batches for a date (required starting point)
- List all settled transactions for a date (skip batch lookup)
- List transactions within a specific batch
- Filter transactions by type (Captures only, or Returns only)
- Retrieve a specific transaction by ID
- Implement pagination to handle large result sets
- Build a nightly reconciliation job

Also confirm:
- **Date scope:** Which date(s) to query? (YYYY-MM-DD format)
- **Merchant filter:** Do they need to filter by a specific `merchantId`?
- **Language:** What language/framework is the implementation in?

---

## Prerequisites

These are needed to **run and test** the integration — not to write the code. If the developer already has them, proceed. If not, wire the code to read from environment variables and keep building.

1. **API key** — exchanged for a Bearer token. Provisioned by the Payroc Integrations team.
2. **UAT environment access** — `api.uat.payroc.com` for test, `api.payroc.com` for production.
3. **A date with settlement data** — in UAT, data may be sparse or absent (see UAT status note above).

**If anything is missing — warn, don't block.** Propose env var names like `PAYROC_API_KEY`. Write code to read from those variables, then tell the developer:

> ⚠️ I've wired this to read your API key from `PAYROC_API_KEY`. You'll need a Payroc UAT API key to test this — contact the Payroc Integrations team if you don't have one. Note: UAT settlement data may be sparse; if queries return empty results, that's a data availability issue, not a code problem.

### Checkpoint

Either the credentials are confirmed, or the developer knows what's outstanding and has chosen to proceed.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Obtain a Bearer token by exchanging the API key against the Identity Service:

- UAT: `POST https://identity.uat.payroc.com/authorize` with header `x-api-key: <api-key>`
- Production: `POST https://identity.payroc.com/authorize` with header `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600 seconds), and `token_type` ("Bearer"). Use `Authorization: Bearer <access_token>` on all subsequent requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

For nightly reconciliation jobs: track token issue time and refresh proactively — a job that runs longer than an hour will encounter 401s on otherwise valid requests if the token expires mid-run.

### Checkpoint

Can the helper generate a Bearer token without error? If not, verify the `x-api-key` header and confirm the API key is correct for the target environment.

---

## Step 2 — List settlement batches for a date

> Read `references/api-schema.md` before writing any request. Confirm the required parameters and response field names from the reference — not from memory.

```
GET https://api.uat.payroc.com/v1/batches?date=YYYY-MM-DD
Authorization: Bearer <access_token>
```

The `date` parameter is **required** and must be in `YYYY-MM-DD` format (the batch submission date, not the transaction date).

Optional parameter: `merchantId` — filter to a specific merchant (useful for multi-merchant integrations). This is a **string** value (e.g. `"MERCH-001"`). Do not use `merchant.processingAccountId` (an integer present in the response object) as the filter value — it is a different field and will not produce a useful result.

**Response:** A paginated list of batch objects. Key fields per batch:

- `batchId` — integer; use this to fetch transactions for the batch
- `transactionCount` — number of settled transactions in the batch
- `saleAmount`, `returnAmount` — totals in lowest denomination (e.g. cents)
- `currency` — ISO 4217 code
- `merchant.merchantId`, `merchant.doingBusinessAs` — merchant identity
- `links[]` — HATEOAS array; find the entry with `rel == "transactions"` for the batch transactions URL

**Pagination:** The default `limit` is 10. If `hasMore` is true, fetch the next page by following the top-level `links` entry where `rel == "next"` and appending its cursor as the `after` query parameter. Do not combine `after` and `before` in the same request.

### Checkpoint

Does the request return HTTP 200 with a `data` array? If `data` is empty, check the date (try yesterday's date) and see the UAT note above. If you get 400, check the `date` format.

---

## Step 2b — Retrieve a single batch by ID (optional)

If you already have a `batchId` (e.g. received via a webhook or external notification) and want to retrieve that batch's metadata without listing all batches for a date:

```
GET https://api.uat.payroc.com/v1/batches/{batchId}
Authorization: Bearer <access_token>
```

Replace `{batchId}` with a non-null **integer** batch ID. The response shape is identical to a single batch object from the list response (same fields: `batchId`, `saleAmount`, `returnAmount`, `transactionCount`, `currency`, `merchant`, `links`, etc.).

For production, replace `api.uat.payroc.com` with `api.payroc.com`.

### Checkpoint

Does the request return HTTP 200 with the batch details? If 404, verify the `batchId` is an integer and from the correct environment (UAT/production).

---

## Step 3 — List transactions in a batch

> Read `references/api-schema.md` before writing any request or using `transactionType` values.

From the `batchId` obtained in Step 2:

```
GET https://api.uat.payroc.com/v1/transactions?batchId={batchId}
Authorization: Bearer <access_token>
```

**Alternative** — skip batch lookup and query by date directly:

```
GET https://api.uat.payroc.com/v1/transactions?date=YYYY-MM-DD
Authorization: Bearer <access_token>
```

The `date` parameter here is the **batch submission date** (the date the batch closed and was submitted for settlement) — not the original transaction date. A sale made on 2025-03-13 may not appear until querying `date=2025-03-14` if the batch closed the following day.

**Either `date` or `batchId` is required.** A request without either returns a 400. The `batchId` parameter is typed as **integer** — pass it as a numeric value, not a string (e.g. `batchId=65`, not `batchId="65"`).

**Optional filter:** `transactionType` — filter by transaction type.

> **Read `references/api-schema.md` before emitting a `transactionType` value.** The enum values are case-sensitive. Do not guess.

| Value | Meaning |
| --- | --- |
| `Capture` | Settled sale/capture transactions |
| `Return` | Settled return/refund transactions |

Note: the query parameter uses title-case (`Capture`, `Return`). The `type` field in the response object uses lowercase (`capture`, `return`). These are different representations of the same concept — do not interchange them. When comparing `type` values from the response in code, use **lowercase** (`"capture"`, `"return"`) — never title-case. Exact-match comparisons using `"Capture"` will silently miss all matching records.

**Response fields per transaction:**

- `transactionId` — integer (may be `null` for some types — handle defensively)
- `type` — `capture` or `return` (lowercase; read-only)
- `amount` — in lowest denomination (e.g. cents)
- `currency` — ISO 4217
- `date` — settlement date (YYYY-MM-DD)
- `status` — one of many values (see schema reference)
- `entryMethod` — how the card was presented (see schema reference for full enum)
- `card.type` — card brand (see schema reference for full enum; note: **not all values are lowercase** — `masterCard`, `amexOptBlue`, `jcbNonSettled`, `wrightExpress`, `discoverRetained` are camelCase; exact-match comparisons must use the casing from the schema)
- `settled.achDate` — date funds were deposited via ACH
- `settled.achDepositId` — integer linking to the ACH deposit record (for cross-referencing only; the HATEOAS `settled.link` object in the response has a placeholder `href: "string"` — do not follow it as a live endpoint)
- `authorization.authorizationId`, `authorization.code` — original authorization details
- `authorization.amount` — amount authorised (useful for reconciliation against the settled amount)
- `authorization.avsResponseCode` — AVS result code from the original authorization

> **Read enum values from `references/api-schema.md` before emitting them.** The `status`, `entryMethod`, and `card.type` fields each have long enums. Do not guess values — read the reference.

**Pagination:** Same cursor-based pattern as batches — use `after`/`before` with `hasMore`.

### Checkpoint

Does the request return HTTP 200 with a `data` array? If `transactionId` is `null` in some items, this is normal — handle it defensively (don't crash on null).

> **Pagination note:** The default `limit` is 10. If `hasMore` is true, the result is truncated — continue fetching with the `after` cursor until `hasMore` is false. A reconciliation job that makes only one call will silently miss records in batches with more than 10 transactions.

---

## Step 4 — Retrieve a single transaction (optional)

If the developer needs a specific transaction by ID:

```
GET https://api.uat.payroc.com/v1/transactions/{transactionId}
Authorization: Bearer <access_token>
```

The `transactionId` must be a **non-null integer** (from the list response). When iterating over list results, skip records where `transactionId` is `null` before calling this endpoint — constructing a path like `/v1/transactions/null` will produce a 400 or 404. The response shape is the same as a single item from the list.

### Checkpoint

Does the request return HTTP 200 with the transaction details? If 404, confirm the `transactionId` is correct and from the same environment (UAT/production).

---

## Pagination pattern

All list endpoints (`/v1/batches`, `/v1/transactions`) use cursor-based pagination:

```text
GET /v1/transactions?batchId=65&limit=50
→ response: { "hasMore": true, "links": [{ "rel": "next", "href": "...?after=<cursor>" }] }

GET /v1/transactions?batchId=65&limit=50&after=<cursor>
→ response: { "hasMore": false, ... }
```

**Rules:**
- `limit` defaults to 10. For reconciliation jobs, set a higher limit (e.g. 100) to reduce round trips.
- Use `after` for forward pagination, `before` for backward. Never combine both.
- `hasMore: false` means you have all records.
- Follow `links[rel="next"].href` if available, rather than constructing cursor URLs manually. The `rel` value `"next"` is the actual relation name for the pagination cursor link (api-schema.md uses `"rel": "string"` as a placeholder in its response example). Note: batch-level HATEOAS links (`rel: "transactions"`, `rel: "authorizations"`) appear on each batch object and are separate from the top-level pagination links.

---

## Error taxonomy

| Status | Scenario | Action |
| --- | --- | --- |
| 400 — missing date/batchId | Request to `/v1/transactions` without `date` or `batchId` | Add either `date=YYYY-MM-DD` or `batchId=<integer>` |
| 400 — validation error | Malformed parameter (e.g. date format wrong) | Check `errors[].parameter` and `errors[].message` for which field failed |
| 401 | Token missing, expired, or API key invalid | Re-authenticate; verify `x-api-key` is correct for the target environment |
| 403 | Insufficient permissions | Check API key scope; contact Payroc support |
| 404 | `transactionId` not found (path does not exist; 404 is expected behaviour but is not listed in the API schema's documented error codes) | Verify the ID is an integer and from the correct environment |
| 406 | Content negotiation failure | Ensure `Accept: application/json` is set (or omitted) |
| 500 | Server error | Retry with exponential backoff; check `errors[]` if present |

**Reading validation errors:** Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`); Payroc **extends** it with an `errors` array. Each `errors[]` item has `parameter` (JSON path of the failing field), `detail` (short reason), and `message` (human-readable explanation). Use `parameter` to identify which field caused the error.

**UAT empty results:** A 200 response with an empty `data` array is not an error. In UAT, settlement data is periodically wiped. This is a data availability issue, not a code problem — see the UAT note at the top of this skill.

---

## Common pitfalls

- **Missing `date` or `batchId`:** The transactions endpoint requires one of these; omitting both causes a 400
- **Date format:** Use `YYYY-MM-DD` — not timestamps, not slashes
- **Wrong `transactionType` casing:** The query parameter uses title-case (`Capture`, `Return`); the response field `type` uses lowercase — these are not interchangeable
- **`type` response comparison must use lowercase:** When filtering response records by `type` in code, use lowercase `"capture"` / `"return"` — using title-case `"Capture"` in an exact-match comparison will silently miss all records
- **`merchantId` filter uses the string `merchantId`, not `processingAccountId`:** The `merchantId` query parameter is a string (e.g. `"MERCH-001"`). The batch/transaction response objects also contain `merchant.processingAccountId` (an integer). These are different identifiers — do not pass `processingAccountId` as the `merchantId` filter value
- **`card.type` enum has mixed casing:** Not all `card.type` values are lowercase. `masterCard`, `amexOptBlue`, `jcbNonSettled`, `wrightExpress`, and `discoverRetained` are camelCase. Exact-match comparisons or switch/match statements must use the casing exactly as documented in `references/api-schema.md`
- **`settled.link` is a placeholder:** The `settled.link` object in the transaction response has `"href": "string"` — this is a schema placeholder, not a live URL. Use `settled.achDepositId` for cross-referencing; do not attempt to follow the HATEOAS link to an ACH deposit endpoint
- **`transactionId` can be null:** Some transaction records have a null `transactionId`; skip those records before calling `GET /v1/transactions/{transactionId}` — do not call `/v1/transactions/null`
- **Amounts in lowest denomination:** All monetary values are integers in cents (USD) or pence (GBP) — $100.00 is `10000`
- **No `Idempotency-Key` needed:** These are GET requests — adding this header is harmless but unnecessary
- **Token expiry in long jobs:** Nightly jobs that run over an hour must refresh the token before it expires
- **Non-existent nested path:** `GET /v1/batches/{batchId}/transactions` does **not** exist. If a developer calls this path they will receive a 404. The correct path for transactions in a batch is `GET /v1/transactions?batchId={batchId}` — note that `batchId` is a query parameter on `/v1/transactions`, not a sub-resource of `/v1/batches`.

---

## Full field reference

Read `references/api-schema.md` for:
- Complete enum lists for `transactionType`, `type`, `status`, `entryMethod`, `card.type`
- Full response schemas for batches and transactions
- All query parameter definitions with types and required flags
- Error response shape with example

Read `references/settlement-data-guide.md` for:
- Settlement workflow context (how batches form, how ACH dates relate to settlement dates)
- Reconciliation workflow pattern
- Reporting API vs. Payments API distinction

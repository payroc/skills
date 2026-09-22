---
name: view-ach-deposits
description: >
  Guide a developer through retrieving ACH deposit data from the Payroc Reporting API —
  listing deposits by date, retrieving a single deposit by ID, and listing the fees associated
  with a deposit. Use this skill when the user wants to view ACH deposits, retrieve ACH deposit
  details, look up ACH deposit history, check what Payroc paid out via ACH, reconcile ACH
  deposit records, query ACH deposit fees, or integrate Payroc ACH deposit reporting into their
  software. Also use when the user asks about /v1/ach-deposits, /v1/ach-deposit-fees, or ACH
  deposit data for a specific date or merchant — even if they don't say "skill" or "reporting API"
  explicitly. Do NOT use for taking or processing ACH payments, refunding ACH payments,
  verifying bank accounts, viewing settlement batches, viewing settled transactions, or viewing
  funding activity — those have dedicated skills.
metadata:
  version: "0.1.1"
  category: reporting
  status: draft
---

# View ACH Deposits

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/reporting/skills/view-ach-deposits/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

> **Known UAT behavior:** the ACH deposit endpoints may return HTTP 500 errors in the Payroc UAT
> environment. This is expected UAT instability, not an indication your request is malformed — retry
> with exponential backoff, and if it persists, contact the Payroc Integrations team. The skill content
> is derived directly from the published Payroc API specification and is spec-accurate.

---

The Payroc ACH Deposits API is a **read-only reporting** surface. It provides three `GET` endpoints:

| Operation | Endpoint |
| --- | --- |
| List ACH deposits | `GET /v1/ach-deposits` |
| Retrieve a single deposit | `GET /v1/ach-deposits/{achDepositId}` |
| List deposit fees | `GET /v1/ach-deposit-fees` |

All monetary amounts are integers in the **lowest currency denomination** (e.g. cents for USD). There is
no request body and no `Idempotency-Key` required — these are safe, idempotent `GET` requests.

For complete field names, all response schema details, and error shapes, read
`references/api-schema.md` (load it when you need any field name, date format, or pagination details).

---

## Quick reference

```text
# List ACH deposits
GET  https://api.uat.payroc.com/v1/ach-deposits?date=YYYY-MM-DD
Authorization: Bearer <token>

# Retrieve a deposit by ID
GET  https://api.uat.payroc.com/v1/ach-deposits/{achDepositId}
Authorization: Bearer <token>

# List deposit fees
GET  https://api.uat.payroc.com/v1/ach-deposit-fees?date=YYYY-MM-DD
Authorization: Bearer <token>
```

---

## References

All field names, response schemas, and error shapes are in the local `references/` files. This skill
emits from them — not from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | All field names, response schemas, required/optional parameters, pagination, error shapes |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| Identity call reference | `references/identity-call.md` | Bearer token exchange — endpoint URL, request header, response fields |

These are local snapshots, authoritative for this skill. Source URLs and last-synced dates are recorded
in [`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Inspect before asking** — scan the developer's codebase before asking anything; use what you find to skip obvious questions.
2. **Read the schema reference before emitting any field name.** Every field in the request and response — `achDepositId`, `paymentDate`, `netAmount`, `associationDate`, etc. — is documented in `references/api-schema.md`. Read it before writing code. Do not guess spelling or type from training data. A plausible-sounding name that doesn't match the spec produces silent mismatches or 400 errors.
3. **Amounts are in the lowest denomination.** `netAmount: 36500` means $365.00 (or £365.00, etc.) — not $36,500. Always clarify this to the developer when displaying amounts.
4. **No idempotency key needed.** These are `GET` requests — do not add an `Idempotency-Key` header.
5. **Never hardcode credentials.** API keys must come from environment variables or a secrets manager.
6. **Bearer token lifetime.** Tokens from the identity service expire after 3,600 seconds (1 hour). For long-running services, implement token refresh logic.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing HTTP client setup or credential configuration
- Existing reporting or settlement code
- How environment variables are managed

Use what you find to pre-fill obvious answers. Then confirm:

1. **Which operations are needed?**
   - List ACH deposits by date (always required — the entry point)
   - Retrieve a specific deposit by `achDepositId`
   - List fees for a deposit
2. **Filter scope:** Is the developer filtering by a specific merchant ID, or listing all merchants?
3. **Pagination:** Will the integration page through results (multi-page) or just take the first page?
4. **Target environment:** UAT (testing) or production?

Use the answers to implement only the relevant operations and skip sections that don't apply.

---

## Prerequisites

To run and test this integration in UAT:

1. **API key** — provisioned by the Payroc Integrations team along with UAT access.
2. **UAT environment** — `api.uat.payroc.com`. There is no self-serve signup; UAT access is provisioned by the Payroc Integrations team.
3. **A date with ACH deposit data** — the list endpoint requires a `date` parameter and the UAT environment may have limited historical data.

**If the API key is missing — warn, don't block.** Wire the code to read credentials from environment variables and keep building. Tell the developer plainly:

> ⚠️ I've wired this to read your API key from `PAYROC_API_KEY`. You'll need Payroc UAT access to actually run or test this — contact the Payroc Integrations team to get it, and set the variable before testing. I can keep building in the meantime.

### Checkpoint

Either the developer has their credentials, or they know what's outstanding and how to obtain it, and they've chosen to proceed. Don't leave missing items unstated, but don't block on them.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Exchange your API key for a Bearer token using the Payroc identity service.

> **Orientation only — always emit auth code from `references/identity-call.md`, not from the
> summary below.** The following is a quick orientation; the reference file is the authoritative source
> for the endpoint URL, header name, and response fields. If anything below conflicts with the reference,
> the reference takes precedence.

- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>` — no request body.

The response contains `access_token`, `expires_in` (3600), `scope`, and `token_type` ("Bearer"). Use `Authorization: Bearer <access_token>` on all subsequent API calls.

Store the API key in an environment variable (`PAYROC_API_KEY`). Never inline it.

For production code, include expiry tracking — a token that expires mid-session causes a `401` on an otherwise valid request.

The Payroc SDKs (TypeScript, Python, C#, PHP, Go, Java, Ruby) handle token exchange automatically.
See https://docs.payroc.com/api/payroc-sd-ks-beta.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the environment.

---

## Step 2 — List ACH deposits

> **Read `references/api-schema.md` before writing request or response code.** All field names
> (`achDepositId`, `paymentDate`, `associationDate`, `netAmount`, etc.) and their types are documented
> there. Do not guess field names from training data — use only the reference.

Endpoint: `GET https://api.uat.payroc.com/v1/ach-deposits`

Required query parameter: **`date`** (`YYYY-MM-DD`) — the date the merchant **received** the ACH deposit (`paymentDate` in the response). Note: the response also includes `achDate` (date Payroc sent the ACH) and `associationDate` (date sent to card brands for clearing) — these are different dates. The `date` filter matches `paymentDate` only.

```bash
curl -G https://api.uat.payroc.com/v1/ach-deposits \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode "date=2024-07-02"
```

Optional filters:
- `merchantId` — filter by a specific merchant
- `limit` — results per page (default: 10)
- `after` / `before` — cursor-based pagination (use one, not both)

> **`date` is mandatory.** Omitting it returns a `400` validation error. Do not emit code that calls this endpoint without a `date` parameter.

The response `data` array contains `achDeposit` objects. Read `references/api-schema.md` for the
complete field list. Key fields to surface:

| Field | Meaning |
| --- | --- |
| `achDepositId` | Use this to retrieve full details or associated fees |
| `paymentDate` | Date the merchant received the deposit |
| `netAmount` | What was actually paid (after fees, adjustments, holdback) |
| `transactions` | Count of transactions in the deposit |

**Amounts note:** All monetary fields (`sales`, `returns`, `dailyFees`, `heldSales`, `achAdjustment`, `holdback`, `reserveRelease`, `netAmount`) are integers in the **lowest currency denomination**. Divide by 100 for display in major units (e.g. `36500` → `$365.00`).

Pagination: if `hasMore` is `true`, fetch the next page using the `after` cursor. The preferred approach is to extract the `href` from the `links` array in the response (look for the pagination `next` link) and use the `after` query parameter value from it. As a fallback documented by the API, you can pass the `achDepositId` of the last item in `data` as the `after` value. The `after` parameter is typed as `string` in the schema — if your HTTP client is strongly-typed, convert the integer ID to a string explicitly before passing it (e.g. `?after=99`, not `?after="99"`).

### Checkpoint

Does the call return HTTP 200 with a `data` array? If not, work through the error taxonomy below.

---

## Step 3 — Retrieve a specific ACH deposit

*(Include if the developer selected this operation)*

Endpoint: `GET https://api.uat.payroc.com/v1/ach-deposits/{achDepositId}`

The `achDepositId` (integer) comes from the list response above.

```bash
curl https://api.uat.payroc.com/v1/ach-deposits/99 \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

Returns a single `achDeposit` object — same shape as items in the `data` array from Step 2.

Check the `links` array in the response: if a link with `rel: "achDepositFees"` is present, use
that URL to fetch the associated fees (see Step 4).

> **`rel` value casing:** The value is `"achDepositFees"` in camelCase — not `"ach-deposit-fees"` or
> `"ACH_DEPOSIT_FEES"`. Do not normalize or lowercase it before comparing; filter with an exact string
> match (`link.rel === "achDepositFees"`).

### Checkpoint

Does the call return HTTP 200 with an `achDepositId` matching your request? A 404 means the ID doesn't
exist for the authenticated context.

---

## Step 4 — List ACH deposit fees

*(Include if the developer selected this operation)*

Endpoint: `GET https://api.uat.payroc.com/v1/ach-deposit-fees`

> **Read `references/api-schema.md` before writing this request.** Pay particular attention to the
> conditional requirement: either `date` or `achDepositId` must be provided — confirm this before
> writing the call.

At least one of `date` or `achDepositId` must be provided — providing neither returns a `400` error. Providing **both** is valid and narrows results to fees for that specific deposit on that date.

```bash
# By deposit ID (preferred when you have one from a prior call)
curl -G https://api.uat.payroc.com/v1/ach-deposit-fees \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode "achDepositId=99"

# By date
curl -G https://api.uat.payroc.com/v1/ach-deposit-fees \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode "date=2024-07-02"

# By both (narrows to fees for deposit 99 on that date)
curl -G https://api.uat.payroc.com/v1/ach-deposit-fees \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode "achDepositId=99" \
  --data-urlencode "date=2024-07-02"
```

Optional filters: `merchantId`, `limit`, `after`, `before` (same pagination rules as List ACH deposits).

The `data` array contains `achDepositFee` objects. Key fields:

| Field | Meaning |
| --- | --- |
| `associationDate` | Date **this transaction** was sent to card brands for clearing — transaction-level granularity. Note: the parent `achDeposit` object also has an `associationDate`, which is the batch-level clearing date. The two fields share the same name but have different semantic scopes; do not use one where the other is expected in reconciliation logic. |
| `description` | Human-readable fee description |
| `amount` | Fee amount (lowest denomination — divide by 100 for display) |
| `adjustmentDate` | Date the adjustment was applied |
| `achDeposit.achDepositId` | ID of the parent deposit — **nested inside the `achDeposit` object** (access as `fee.achDeposit.achDepositId`, not `fee.achDepositId`) |
| `merchant.link` | HATEOAS link to the full merchant record — **singular `link` object**, not a `links` array. Access as `fee.merchant.link.href`. |

### Checkpoint

Does the call return HTTP 200 with fee records? If you get a `400`, confirm that either `date` or `achDepositId` is in the query string.

---

## Error taxonomy

> **Read `references/api-schema.md` for the error response shape** before writing error-handling code.
> Errors follow the RFC 7807 envelope with a Payroc `errors[]` extension.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 400 — missing `date` on list deposits | `date` query parameter omitted | Add `?date=YYYY-MM-DD` to the request — it is mandatory |
| 400 — missing filter on deposit fees | Neither `date` nor `achDepositId` provided | Add at least one of `?date=YYYY-MM-DD` or `?achDepositId=<id>` — providing both is also valid |
| 400 — invalid date format | Date not in `YYYY-MM-DD` format | Correct the format; ISO 8601 date strings only |
| 400 — `before` and `after` both sent | Pagination cursor conflict | Remove one — use `after` for forward pagination, `before` for backward |
| 401 — identity not verified | Token missing, expired, or API key wrong | Re-generate the Bearer token; verify the `x-api-key` value is correct for the environment |
| 403 — insufficient permissions | API key scope doesn't cover reporting | Contact Payroc to check API key permissions |
| 404 — deposit not found | `achDepositId` doesn't exist in this context, **or the request URL uses the wrong environment** | Check the base URL in the request: UAT is `api.uat.payroc.com`, production is `api.payroc.com`. A deposit ID created in UAT will 404 in production and vice versa. Verify the ID from the list response using the same environment. |
| 406 — not acceptable | `Accept` header set to a non-JSON MIME type | Remove the `Accept` header or set it to `application/json`; these endpoints return JSON only |
| 500 — server error | Transient server error (known to occur in UAT) | Retry with exponential backoff. Check `errors[]` array for detail. |

**Reading error details** — the response uses the RFC 7807 problem-details envelope (`type`, `title`,
`status`, `detail`, `instance`); Payroc extends it with an `errors` array. Each `errors[]` item has a
`parameter` (JSON path of the failing field), `detail` (short reason), and `message` (human-readable
explanation). Use `parameter` to identify exactly which query parameter or field failed.

See [`references/error-response-format.md`](references/error-response-format.md) for the cross-skill
error standard.

---

## Common pitfalls

- **Missing `date` on List ACH deposits** — the parameter is mandatory; omitting it always causes a 400
- **Missing filter on List ACH deposit fees** — at least one of `date` or `achDepositId` must be present (providing both is valid and narrows results further)
- **Using `before` and `after` together** — pick one pagination direction per request
- **Displaying raw amounts** — `netAmount`, `sales`, `returns`, etc. are in the lowest denomination; always divide by 100 (or equivalent) before displaying dollar/pound amounts
- **ID type confusion** — `achDepositId` is an integer; `merchantId` is a string — don't swap them
- **Wrong environment** — UAT (`api.uat.payroc.com`) and production (`api.payroc.com`) use different base URLs and credentials. When reviewing a developer's request that returns 404, always check the base URL in the request first — a deposit ID that exists in UAT will 404 in production and vice versa.

---

## Validation checklist

- [ ] API key sourced from an environment variable — never hardcoded
- [ ] Bearer token generated from the identity service (from `references/identity-call.md`)
- [ ] No `Idempotency-Key` header added — not required for GET requests
- [ ] `date` query parameter present and in `YYYY-MM-DD` format on every List ACH deposits call
- [ ] At least one of `date` or `achDepositId` present on every List ACH deposit fees call (providing both is valid)
- [ ] Only one of `after` or `before` used per paginated request (not both)
- [ ] Field names (`achDepositId`, `paymentDate`, `netAmount`, etc.) read from `references/api-schema.md` — not from training data
- [ ] Monetary amounts divided by 100 before display (they are integers in lowest denomination)
- [ ] UAT endpoints used during testing (`api.uat.payroc.com`, `identity.uat.payroc.com`)

---

## Completion

Once all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **List ACH deposits** — filtered by date; paginated via cursor.
> - **Retrieve deposit** (if built) — single deposit lookup by `achDepositId`.
> - **List deposit fees** (if built) — fees for a deposit, filtered by date or deposit ID.
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Point credentials to production.

Offer next steps:
- **View settlement batches** — retrieve batch-level settlement data
- **View settled transactions** — drill into individual settled transactions within a batch
- **View authorizations** — look up pre-authorization records

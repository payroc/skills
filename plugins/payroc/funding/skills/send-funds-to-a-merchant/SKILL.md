---
name: send-funds-to-a-merchant
description: >
  Guides developers through sending (disbursing) funds to a merchant via the Payroc Funding API
  — including checking available balance before disbursement and creating, tracking, updating, or
  cancelling funding instructions (/v1/funding-instructions). Use this skill when the user wants
  to disburse or send funds to a merchant, create a funding instruction, pay out a merchant,
  distribute merchant balances, implement an ACH payout to a merchant's bank account, perform
  merchant settlement disbursement, batch-fund multiple merchants in a single instruction, update
  a pending funding instruction, delete or cancel a funding instruction, or manage the
  /v1/funding-instructions endpoint (POST, GET, PUT, DELETE). Also use when the user asks about
  idempotency keys for funding instructions, tracking instruction status
  (accepted/pending/completed/funded), or checking available balance specifically as a prerequisite
  for disbursing funds. Do NOT use for setting up or registering a new funding recipient or funding
  account (use the set-up-a-funding-recipient skill), or for viewing funding activity history,
  balance reports, or funding balances without the intent to disburse (use the
  view-funding-activity skill).
metadata:
  version: "0.1.2"
  category: funding
  status: draft
---

# Send Funds to a Merchant

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/funding/skills/send-funds-to-a-merchant/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

> **Funding a merchant requires a KYC-approved recipient.** If funding instructions fail with a "recipient not found" or similar error in UAT, confirm the target funding recipient has passed KYC first — see the KYC validation note in the `set-up-a-funding-recipient` skill. All steps, schemas, and enum values here are derived from the official Payroc API documentation.

---

Payroc's Funding API lets distributors disburse funds to merchants via ACH. The process has two steps:

1. **Check available balance** — confirm sufficient funds before sending (`GET /v1/funding-balance`)
2. **Create a funding instruction** — specify which merchants and funding accounts receive which amounts (`POST /v1/funding-instructions`)

For all field details, enum values, and schemas, read `references/api-schema.md`. For the narrative flow, lifecycle model, and key constraints, read `references/send-funds-guide.md`.

> **Read `references/api-schema.md` before answering any question about or emitting any enum value** — especially `paymentMethod` and `currency`. There is one supported value for each. This applies equally to code generation and to dialog responses (e.g. "is GBP supported?", "can I use wire transfer?"). Do not guess from training data — always consult the reference first.

---

## Quick reference

```text
GET   https://api.uat.payroc.com/v1/funding-balance
POST  https://api.uat.payroc.com/v1/funding-instructions
GET   https://api.uat.payroc.com/v1/funding-instructions/{instructionId}
GET   https://api.uat.payroc.com/v1/funding-instructions?dateFrom=YYYY-MM-DD&dateTo=YYYY-MM-DD
PUT   https://api.uat.payroc.com/v1/funding-instructions/{instructionId}
DELETE https://api.uat.payroc.com/v1/funding-instructions/{instructionId}

Authorization:   Bearer <token>          (all requests)
Idempotency-Key: <uuid-v4>              (POST only)
Content-Type:    application/json        (POST and PUT)
```

---

## References

| File | Used for |
| --- | --- |
| `references/identity-call.md` | Auth — identity service endpoint URL, request header (`x-api-key`), and response shape. Mandatory. Read before writing any auth code. |
| `references/api-schema.md` | All endpoint paths, HTTP methods, request/response schemas, enum values (`paymentMethod`, `currency`, instruction status, recipient status), and error codes. Read before emitting any enum value or request body. |
| `references/send-funds-guide.md` | Narrative guide — two-step flow, lifecycle model, update/delete constraints, and key field rules. |
| `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog. |

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing payout, billing, or financial-operations code
- Any existing HTTP client setup or credential configuration
- How environment variables are managed

Use what you find to pre-fill obvious answers. Then confirm:

1. **Do you want to send funds to one merchant or multiple merchants in a single instruction?**
2. **Do you have the `merchantId` and `fundingAccountId`(s) for each recipient merchant?** (These come from the Payroc Boarding API — if not available, they must be obtained from the funding-recipients setup before proceeding.)
3. **What is the amount to send?** (In USD cents — e.g. $500.00 = `50000`)
4. **Do you need to list or retrieve existing instructions? Update or delete pending instructions?**

Use the answers to scope what sections to implement.

---

## Prerequisites

Before this skill can run end-to-end, the following must exist:

1. **API key** — used to generate Bearer tokens. Provisioned by the Payroc Integrations team.
2. **Merchant ID** — the `merchantId` of the recipient merchant, assigned by Payroc when the merchant was boarded.
3. **Funding account ID** — the `fundingAccountId` (integer) of the merchant's bank account, created when the funding recipient was set up. If this doesn't exist, the `set-up-a-funding-recipient` skill must be run first.
4. **Available balance** — confirmed via `GET /v1/funding-balance` before creating an instruction.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it; otherwise propose `PAYROC_API_KEY`. Write the code to read credentials from those variables, then tell the developer:

> ⚠️ I've wired this to read your API key from `PAYROC_API_KEY`. You'll need a Payroc UAT API key and a set-up funding recipient (with a valid `fundingAccountId`) to run or test this — contact the Payroc Integrations team if you don't have them.

### Checkpoint

Either the credentials and IDs are confirmed, or the developer knows what's outstanding and has chosen to proceed anyway.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Exchange your API key for a Bearer token before any Funding API call.

- UAT: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`
- Header: `x-api-key: <api-key>`

Response: `access_token`, `expires_in` (3600), `token_type` ("Bearer"), `scope` (space-separated service identifiers — check this field if you receive a 403 to verify funding scope is included).

Use `Authorization: Bearer <access_token>` on every subsequent request. Tokens expire after 1 hour — implement refresh logic for long-running services.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never hardcode it.

### Checkpoint

Can the token helper return an `access_token` without error? If not, verify the `x-api-key` header and confirm the API key is correct for the environment.

---

## Step 2 — Check available balance

Before creating a funding instruction, verify sufficient funds are available.

```text
GET https://api.uat.payroc.com/v1/funding-balance
Authorization: Bearer <token>
```

Optional query parameters (read from `references/api-schema.md`): `merchantId` (filter by merchant), `limit`, `after`, `before` (pagination).

The response `data` array contains one entry per merchant. For each entry:
- `funds` — total balance in cents
- `pending` — funds not yet distributed
- `available` — the usable balance that can be instructed

**Only the `available` amount can be used in funding instructions.** If `available` is less than the intended disbursement amount, do not proceed — inform the developer and stop.

### Checkpoint

Is the merchant's `available` balance at least equal to the amount you intend to send? If not, surface the actual `available` value and stop.

---

## Step 3 — Create a funding instruction

> Read `references/api-schema.md` before writing the request body or answering questions about supported payment methods and currencies. The `paymentMethod` enum and `currency` enum have exactly one valid value each — do not guess them from training data.

Endpoint: `POST https://api.uat.payroc.com/v1/funding-instructions`

Required headers:
```text
Authorization:   Bearer <token>
Idempotency-Key: <UUID v4>
Content-Type:    application/json
```

Generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* instruction (after a network failure where you don't know if the request reached the server), reuse the **same** key — the API returns the original response without creating a duplicate. On a genuinely new instruction (different payload), generate a new UUID.

Request body — single merchant, single recipient:
```json
{
  "merchants": [
    {
      "merchantId": "MERCHANT-123",
      "recipients": [
        {
          "fundingAccountId": 456,
          "paymentMethod": "ACH",
          "amount": {
            "value": 50000,
            "currency": "USD"
          }
        }
      ]
    }
  ]
}
```

Request body — batch (multiple merchants):
```json
{
  "merchants": [
    {
      "merchantId": "MERCHANT-123",
      "recipients": [
        {
          "fundingAccountId": 456,
          "paymentMethod": "ACH",
          "amount": { "value": 50000, "currency": "USD" }
        }
      ]
    },
    {
      "merchantId": "MERCHANT-456",
      "recipients": [
        {
          "fundingAccountId": 789,
          "paymentMethod": "ACH",
          "amount": { "value": 25000, "currency": "USD" }
        }
      ]
    }
  ]
}
```

> **Schema discipline — critical points:**
> - `paymentMethod` must be `"ACH"` — this is the only supported value and the field is **case-sensitive** (uppercase only; `"ach"` or `"Ach"` will be rejected). Read it from `references/api-schema.md`, do not infer it.
> - `fundingAccountId` is an **integer**, not a string. Sending a string will produce a 400 validation error.
> - Always include `"currency": "USD"` explicitly even though it is technically optional — this avoids silent default-related issues if the API behaviour ever changes.

**Response (201 Created):**
```json
{
  "instructionId": 789,
  "createdDate": "2026-06-22T10:00:00Z",
  "lastModifiedDate": "2026-06-22T10:00:00Z",
  "status": "accepted",
  "merchants": [
    {
      "merchantId": "MERCHANT-123",
      "recipients": [
        {
          "fundingAccountId": 456,
          "paymentMethod": "ACH",
          "amount": { "value": 50000, "currency": "USD" },
          "status": "accepted"
        }
      ]
    }
  ]
}
```

Capture `instructionId` (an integer) from the response for tracking. When building URL paths from this value, always interpolate it as an integer — do **not** store it as a float or `double`, which can produce malformed URLs like `/v1/funding-instructions/789.0` in languages where JSON numbers default to floating-point (e.g. Go's `interface{}`, Java `Object`, C# `dynamic`). Cast explicitly to integer/long before string interpolation.

### Checkpoint

Does the API return HTTP 201 with an `instructionId`? If not, work through the error taxonomy below.

---

## Step 4 — Track instruction status

Poll `GET https://api.uat.payroc.com/v1/funding-instructions/{instructionId}` to monitor progress. As an alternative to polling, you can subscribe to webhook events to receive push notifications when the instruction status changes — if the developer prefers event-driven tracking, refer them to the Payroc webhook documentation.

**Instruction-level status progression:**
```
accepted → pending → completed
```

The instruction level has no terminal error state — if the overall instruction fails, check the individual recipient statuses below.

**Recipient-level status progression (within each merchant/recipient):**
```
accepted → pending → released → funded
```

**Recipient-level terminal error states** (recipient dimension only — do not check these on the instruction-level object):
- `failed` — ACH payment failed
- `rejected` — instruction rejected after review
- `onHold` — instruction placed on hold

> **Casing note:** `onHold` is deliberately camelCase. Every other recipient status value is all-lowercase (`accepted`, `pending`, `released`, `funded`, `failed`, `rejected`). Do **not** normalise it to `on_hold`, `onhold`, or `ONHOLD` — a status comparison using any of those strings will silently never match, causing on-hold instructions to appear as permanently in-flight.

> Read `references/api-schema.md` for the complete enum list of both instruction-level and recipient-level statuses before writing any status-handling code. The terminal error states (`failed`, `rejected`, `onHold`) apply **only** to `merchants[].recipients[].status` — the instruction-level `status` field only ever contains `accepted`, `pending`, or `completed`.

Implement polling with appropriate backoff — ACH transfers are not instant and may take hours to days to reach `funded`.

---

## Step 5 (optional) — Extended operations

*(Implement only what the developer needs)*

### List instructions

`GET https://api.uat.payroc.com/v1/funding-instructions?dateFrom=YYYY-MM-DD&dateTo=YYYY-MM-DD`

Both `dateFrom` and `dateTo` are required. Date range is limited to the previous two years. Supports `limit`, `after`, `before` for pagination.

### Update an instruction

`PUT https://api.uat.payroc.com/v1/funding-instructions/{instructionId}`

**Constraint: only possible while status is `accepted`.** Once the instruction moves to `pending` or beyond, this returns 409 Conflict.

Required headers: `Authorization: Bearer <token>`, `Content-Type: application/json`. No `Idempotency-Key` required on PUT.

Request body: same schema as the POST create body — provide the full updated `merchants` array.

Response: 204 No Content.

### Delete an instruction

`DELETE https://api.uat.payroc.com/v1/funding-instructions/{instructionId}`

**Constraint: only possible while status is `accepted`.** Fails with 409 if already `pending` or beyond.

Required header: `Authorization: Bearer <token>`.

**Before writing delete code:** confirm with the developer that they want to cancel the instruction. Deletion is permanent — no funds will be sent.

Response: 204 No Content.

---

## Error taxonomy

> Errors use the RFC 7807 problem-details format as the envelope (`type`, `title`, `status`, `detail`, `instance`). Payroc extends the envelope with an `errors` array. Each `errors[]` item has `parameter` (JSON path of the failing field), `detail` (short reason), and `message` (human-readable explanation). Use `parameter` to map each error back to the request body.

| Status | Scenario | Action |
| --- | --- | --- |
| 400 — validation | Field issues in request body | Fix each field named in `errors[].parameter`; resubmit with a fresh idempotency key (nothing was created, but the corrected body needs a new key) |
| 400 — missing `Idempotency-Key` | Missing `Idempotency-Key` header on POST | Add `Idempotency-Key: <uuid-v4>` to the request |
| 400 — `fundingAccountId` type error | Sent as string, not integer | Change `fundingAccountId` to an integer literal |
| 401 | Token missing, expired, or API key invalid | Re-authenticate; verify `x-api-key` value and ensure the API key is correct for the environment |
| 403 | API key lacks funding scope | Contact Payroc Integrations team to enable funding permissions for this API key |
| 404 | `instructionId` not found | Verify the ID from the create response; check list endpoint |
| 406 | Not Acceptable — format issue | Verify the `Accept` header is not set to an unsupported media type; omit `Accept` to use the default |
| 409 — duplicate idempotency key | Reused an idempotency key with a **different** payload | This is a different instruction — generate a new UUID and resubmit. Do **not** confuse this with a retry: if you are retrying the *same* payload after a network failure, reuse the original key (the API is idempotent and will return the original response). A 409 on a retry means the original request was received and succeeded — retrieve the instruction to confirm. |
| 409 — wrong status for update/delete | Instruction is not `accepted` | Retrieve the instruction to check current status; modifications cannot be made beyond `accepted` |
| 500 | Server error | Retry with exponential backoff |

---

## Enum discipline — mandatory for all interactions

> **Before stating what payment methods or currencies are supported** — whether in code, a dialog answer, or a review — read `references/api-schema.md` to verify the current supported values. The enums are: `paymentMethod` → `ACH` only; `currency` → `USD` only. Do not answer from training data.

If a developer asks "can I use wire transfer?" or "is GBP supported?" or similar, read `references/api-schema.md` first, then answer from what the reference documents.

---

## Common pitfalls

- **`paymentMethod` wrong case or missing:** Only `"ACH"` is valid — the value is case-sensitive (uppercase). `"ach"` or `"Ach"` will produce a 400. Read from `references/api-schema.md`; do not guess.
- **`fundingAccountId` sent as a string:** The field type is integer. `"456"` (string) will fail; `456` (integer) is correct.
- **`currency` wrong or unsupported:** Only `"USD"` is accepted. The field is optional (defaults to `USD`), but always include it explicitly to avoid any ambiguity: `"currency": "USD"`.
- **Amount in dollars instead of cents:** All amounts are in the lowest denomination. `$500.00` must be sent as `50000`.
- **Missing `Idempotency-Key` on POST:** Required — omitting it produces a 400.
- **`merchants` array empty:** The `merchants` array must contain at least one merchant. Posting an empty array `[]` produces a 400 validation error. In batch-funding loops, guard against accidentally sending an empty array before calling the API.
- **`instructionId` stored as float:** In languages where JSON numbers default to floating-point (Go `interface{}`, Java `Object`, C# `dynamic`), `instructionId: 789` may deserialize to `789.0`. Interpolating that into a URL produces `/v1/funding-instructions/789.0`, which results in a 404. Always cast to integer/long before building URL paths.
- **`onHold` recipient status mismatched due to casing:** `onHold` is camelCase. Writing `"on_hold"`, `"onhold"`, or `"ONHOLD"` in a switch/match will never match — the instruction will silently appear to stay in-flight. Use `onHold` exactly.
- **Attempting to update/delete once past `accepted` status:** Updates and deletes are only possible while the instruction is in `accepted` status. Once it moves to `pending` or beyond, it cannot be changed — any attempt returns 409. Check status before attempting a modification.
- **Missing `dateFrom`/`dateTo` on list:** Both query parameters are required for `GET /v1/funding-instructions`. Dates are in YYYY-MM-DD format; the API interprets them as UTC day boundaries — be aware of timezone offset if your system is not UTC.
- **`merchantId` or `fundingAccountId` not yet set up:** Funding requires a prior call to create a funding recipient and account. If the IDs don't exist yet, use the `set-up-a-funding-recipient` skill first.

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values (`paymentMethod`, `currency`, instruction status, recipient status)
- Complete request and response schemas for all endpoints
- Error response structure and all documented error codes

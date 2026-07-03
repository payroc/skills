---
name: refund-a-card-payment
description: >-
  Guides developers through refunding a Payroc card (credit/debit) payment via the Payroc
  API. Use this skill when the user wants to refund a card payment or card transaction,
  issue a credit back to a cardholder's card, send money back to a credit or debit card,
  process a return for a card payment, work with the /v1/payments/{paymentId}/refund or
  /v1/refunds endpoints, create a referenced refund (using a paymentId) or an unreferenced
  refund (providing card details directly), issue a partial refund on a card payment, adjust
  or void a card refund, reverse or cancel a card refund (remove a refund from an open
  batch), look up or list card refund records, or build card refund functionality into a
  payment integration. Do NOT use for ACH or bank-transfer refunds (use
  refund-an-ach-payment instead), voiding or reversing a pre-authorization hold, or
  cancelling an unsettled card payment before capture.
metadata:
  version: "0.1.0"
  category: transaction
  status: draft
---

# Refund a Card Payment

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/refund-a-card-payment/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Card Payment Refund**
> I'll guide you through refunding a card payment using the Payroc API.
>
> **Two refund types are available:**
> 1. **Referenced refund** — you have the `paymentId` from the original payment. The refund is linked to that payment. Preferred when you have the ID.
> 2. **Unreferenced refund** — you don't have (or don't need) the original `paymentId`. You provide the customer's card details directly. Only available on certain accounts.
>
> **Important: batch state affects behaviour**
> - Payment in a **closed batch**: the API returns funds to the cardholder's account (true refund).
> - Payment in an **open batch**: the API **reverses** the payment instead. The endpoint is the same — the gateway decides which action to take.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
# Referenced refund (preferred — use when you have the paymentId)
POST  https://api.uat.payroc.com/v1/payments/{paymentId}/refund
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json

# Unreferenced refund (standalone — no paymentId required)
POST  https://api.uat.payroc.com/v1/refunds
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json

# Retrieve / list / adjust / reverse
GET   https://api.uat.payroc.com/v1/refunds
GET   https://api.uat.payroc.com/v1/refunds/{refundId}
POST  https://api.uat.payroc.com/v1/refunds/{refundId}/adjust
POST  https://api.uat.payroc.com/v1/refunds/{refundId}/reverse
```

---

## References

All enum values and schemas live in the local `references/` files below — this skill emits from them, not from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| Identity call reference | `references/identity-call.md` | Auth endpoint URL, request/response shape — read before writing any auth code |
| API schema reference | `references/api-schema.md` | **All** endpoint paths, request schemas, enum values, response schemas |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are recorded in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core Principles

1. **Inspect before asking** — read the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through intake before writing implementation code; wrong assumptions waste the developer's time.
3. **Read the schema reference before emitting any enum value or reviewing developer code against the schema.** Every field that accepts a fixed set of strings — `channel`, `refundMethod.type`, `cardDetails.entryMethod`, `adjustments[].type`, filter parameters — is documented in `references/api-schema.md`, the authoritative copy for this skill. Read it before emitting values and before reviewing any developer-submitted code for correctness. A verdict issued from memory rather than the reference will miss wrong field names and missing required fields.
4. **Idempotency-Key on every POST.** The header value must be a UUID v4. This is a required header — omitting it causes a 400. Generate a fresh UUID for each distinct operation. When **retrying the same failed request**, reuse the same key — the gateway returns the original response and does not create a duplicate.
5. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables or a secrets manager.
6. **Bearer token expiry.** Tokens expire after 3,600 seconds (1 hour). For long-running services, implement token refresh logic.
7. **Validate before advancing** — don't move to the next step until the current step's checkpoint passes in UAT.
8. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing payment or order management code that stores `paymentId`
- Any existing HTTP client setup or credential configuration
- How environment variables are managed

Use what you find to pre-fill obvious answers and ask targeted questions. Then confirm:

1. **Do you have the `paymentId` of the payment to refund?**
   - Yes → use the **referenced refund** path (Step 2a).
   - No → use the **unreferenced refund** path (Step 2b). Confirm the terminal is enabled for unreferenced refunds.

2. **Full refund or partial?**
   - Partial refunds are supported for referenced refunds — the `amount` can be less than the original payment.
   - Unreferenced refunds specify the amount directly.

3. **What operations do you need beyond basic refund?**
   - Retrieve a refund by ID
   - List / search refunds
   - Adjust a refund (update status or customer details while in an open batch)
   - Reverse a refund (cancel it while still in an open batch)

Use the answers to skip sections that don't apply.

---

## Prerequisites

These are needed to run and test the integration in UAT — not to write the code. If the developer already has them, great. If not, don't stop: wire the code to read each value from an environment variable and keep building.

1. **API key** — used to generate Bearer tokens. Provisioned by the Payroc Integrations team.
2. **Processing terminal ID** — needed for unreferenced refunds (`processingTerminalId` in the request body). The developer should know this from their UAT setup.
3. **`paymentId`** — needed for referenced refunds. Returned when the original payment was created.
4. **UAT environment** — Payroc's test environment. UAT terminals are provisioned manually by the Payroc Integrations team.
5. **Unreferenced refund capability** (if applicable) — this feature must be enabled by Payroc on the terminal. Not all terminals support it.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it; otherwise propose names like `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID`. Tell the developer plainly what's outstanding and how to obtain it.

### Checkpoint

Either the credentials are confirmed, or the developer knows what's outstanding, how to obtain it, and which environment variables the code reads it from — and has chosen to proceed.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), `scope`, and `token_type` ("Bearer"). All subsequent API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic — tokens that expire mid-operation will produce 401s on otherwise valid requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the UAT environment.

---

## Step 2a — Create a referenced refund (you have the paymentId)

Endpoint: `POST https://api.uat.payroc.com/v1/payments/{paymentId}/refund`

> **Read `references/api-schema.md` before writing the request body.** Confirm the `referencedRefund` schema — required fields are `amount` and `description`. Do not add fields not in the schema.

Required headers:
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <UUID v4>
```

Request body:
```json
{
  "amount": 5000,
  "description": "Customer requested refund — order INV-1234"
}
```

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `amount` | integer | **Yes** | Amount to refund in the currency's lowest denomination (e.g. cents). Must be ≤ original payment amount. Partial refunds are allowed. |
| `description` | string | **Yes** | Reason for the refund. |
| `operator` | string | No | Name/ID of the operator issuing the refund. |

**What the gateway does:**
- If the original payment is in a **closed batch**: gateway credits the cardholder's card — a true refund.
- If the original payment is in an **open batch**: gateway **reverses** (voids) the payment. You use the same endpoint — the gateway decides which action to take.

**Response (HTTP 200):** Returns the updated `payment` object. Capture `refunds[]` — each entry has a `refundId`, `status`, `amount`, and `responseCode`. Store the `refundId` if you need to retrieve, adjust, or reverse the refund later.

### Checkpoint

Does the API return HTTP 200 with the payment object containing a `refunds[]` entry? If not, work through the error taxonomy.

---

## Step 2b — Create an unreferenced refund (no paymentId)

> **Confirm with the developer that their terminal supports unreferenced refunds before writing this code.** This capability is not enabled on all Payroc accounts.

Endpoint: `POST https://api.uat.payroc.com/v1/refunds`

> **Read `references/api-schema.md` before writing the request body.** The `channel`, `refundMethod.type`, and `cardDetails.entryMethod` values are all enums — read their documented values from the reference. Do not emit enum values from memory.

Required headers:
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <UUID v4>
```

> **Read the `UnreferencedRefundChannel` enum from `references/api-schema.md` before writing the `channel` value.** Valid values are `pos` and `moto`. Do not guess.

> **Read the `refundMethod.type` enum from `references/api-schema.md` before writing the refundMethod.** Valid types are `card` and `secureToken`.

> **Read the `cardDetails.entryMethod` enum from `references/api-schema.md` before writing card details.** Valid entry methods are `raw`, `icc`, `keyed`, and `swiped`.

Example request body — Variant 1 (`card`, keyed entry):
```json
{
  "channel": "pos",
  "processingTerminalId": "TERMINAL_ID",
  "order": {
    "orderId": "REFUND-5678",
    "description": "Refund for order INV-1234",
    "amount": 5000,
    "currency": "USD"
  },
  "refundMethod": {
    "type": "card",
    "cardDetails": {
      "entryMethod": "keyed",
      ...
    }
  }
}
```

Example request body — Variant 2 (`secureToken`):
```json
{
  "channel": "moto",
  "processingTerminalId": "TERMINAL_ID",
  "order": {
    "orderId": "REFUND-5679",
    "description": "Refund for order INV-1235",
    "amount": 3000,
    "currency": "USD"
  },
  "refundMethod": {
    "type": "secureToken",
    "token": "tok_abc123",
    "secCode": "web"
  }
}
```

> **`secCode` is required for `secureToken` refunds.** It must be a sibling of `token` inside `refundMethod`. Omitting it causes a 400 validation error.

**`refundMethod` field tables (read `references/api-schema.md` before emitting):**

Variant 1 — `card`:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | `"card"` | **Yes** | Discriminator. |
| `cardDetails` | object | **Yes** | Polymorphic on `entryMethod` (`raw` \| `icc` \| `keyed` \| `swiped`). |
| `accountType` | enum | No | `checking` \| `savings` — for bank account refund methods only. |

Variant 2 — `secureToken`:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | `"secureToken"` | **Yes** | Discriminator. |
| `token` | string | **Yes** | Secure token identifying the stored card. |
| `secCode` | enum | **Yes** | ACH SEC code: `web` \| `tel` \| `ccd` \| `ppd`. **Omitting this field causes a 400 validation error.** |
| `accountType` | enum | No | `checking` \| `savings`. |

Required fields summary (from `references/api-schema.md`):
- `channel` (enum: `pos` | `moto`)
- `processingTerminalId` (string)
- `order.orderId`, `order.description`, `order.amount`, `order.currency`
- `refundMethod.type` + associated card or token details (for `secureToken`: `token` and `secCode` are both required)

**Response (HTTP 201):** Returns a `retrievedRefund` object containing a `refundId`. Store this `refundId` for subsequent operations (retrieve, adjust, reverse).

### Checkpoint

Does the API return HTTP 201 with a `refundId`? If not, work through the error taxonomy.

---

## Step 3 — Extended operations

*(Implement only the sub-sections the developer selected during intake)*

### Retrieve a refund

`GET https://api.uat.payroc.com/v1/refunds/{refundId}`

Headers: `Authorization: Bearer <token>`

Returns the full `retrievedRefund` object including current `transactionResult.status`. Useful for checking whether the refund was approved or declined.

---

### List refunds

`GET https://api.uat.payroc.com/v1/refunds`

Headers: `Authorization: Bearer <token>`

> **Read `references/api-schema.md` for the valid filter parameter enum values** (`tender`, `status`, `settlementState`) before writing filter logic. Do not emit these values from memory.

Supports query filters: `processingTerminalId`, `orderId`, `operator`, `cardholderName`, `first6`, `last4`, `tender` (`ebt` | `creditDebit`), `status` (array), `dateFrom`, `dateTo`, `settlementState` (`settled` | `unsettled`), `settlementDate`.

> **Read `references/api-schema.md` for the `RefundsGetParametersStatusSchemaItems` enum before writing `status` filter values.** Note: the filter enum (`RefundsGetParametersStatusSchemaItems`) does not include `returned`, even though `returned` is a valid value in the `RefundSummaryStatus` response object. Do not filter by `status=returned` — it is not a documented filter value and may result in a 400 error.

Pagination: cursor-based via `limit`, `after`, `before` query parameters. Use `before` or `after` — not both in the same request. The response `hasMore` field indicates whether additional pages exist.

---

### Adjust a refund

> Adjustments are only possible while the refund is in an **open batch**. Once settled, you cannot adjust it.

`POST https://api.uat.payroc.com/v1/refunds/{refundId}/adjust`

Required headers:
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <UUID v4>
```

> **Read `references/api-schema.md` for the `RefundAdjustmentAdjustmentsItems.type` enum values** (`status` | `customer`) and the `toStatus` enum values (`ready` | `pending`) before writing the adjustments array. Note: `toStatus` only applies to adjustments where `type` is `"status"` — it is not used for `type: "customer"` adjustments.

The request body contains an `adjustments` array of polymorphic objects:

```json
{
  "adjustments": [
    { "type": "status", "toStatus": "pending" }
  ]
}
```

Or to update customer contact details:
```json
{
  "adjustments": [
    {
      "type": "customer",
      "shippingAddress": { ... },
      "contactMethods": [ ... ]
    }
  ]
}
```

Response (HTTP 200): updated `retrievedRefund` object.

---

### Reverse a refund

> **Warn the developer before writing reversal code:** Reversing a refund removes it from the open batch permanently. No funds are returned to the cardholder. This can only be done while the refund is in an open batch.

`POST https://api.uat.payroc.com/v1/refunds/{refundId}/reverse`

Required headers: `Authorization: Bearer <token>`, `Idempotency-Key: <UUID v4>`

No request body required.

Response (HTTP 200): updated `retrievedRefund` object with `transactionResult.status` set to `reversal`.

**Before writing reversal code:** stop and ask the developer to explicitly confirm they understand the consequences before proceeding:

> Before I write the reversal code — please confirm you understand:
> - The refund will be **permanently removed** from the open batch. The customer will **NOT** receive any funds.
> - This is only possible while the refund is **still in an open batch** (before settlement). Once settled, reversal is not possible.
> - This action cannot be undone.
>
> Do you want to proceed with the reversal?

Only write the code after the developer confirms. Do not proceed without an explicit confirmation.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header is the correct UAT API key |
| 400 — `idempotencyKeyMissing` | `Idempotency-Key` header absent | Add `Idempotency-Key: <UUID v4>` to every POST; generate a fresh UUID per operation |
| 400 — validation error on `channel` | Enum value not from the reference | Read `references/api-schema.md` — valid values: `pos`, `moto` |
| 400 — validation error on `refundMethod.type` or `cardDetails.entryMethod` | Enum value not from the reference | Read `references/api-schema.md` for valid enum values; never emit from memory |
| 400 — validation error on `amount` | Amount exceeds original payment, or missing | For referenced refunds: `amount` must be ≤ original payment amount and is required |
| 400 — validation error on `description` | `description` missing | Both `amount` and `description` are required on `referencedRefund` |
| 400 — validation on `order.*` | Missing required order fields in unreferenced refund | All four fields required: `orderId`, `description`, `amount`, `currency` |
| 403 — unreferenced refund rejected | Terminal not enabled for unreferenced refunds | Contact Payroc to enable unreferenced refund capability on this terminal |
| 404 — paymentId not found | `paymentId` wrong, payment doesn't exist in this environment, or environment mismatch (e.g. production paymentId used against UAT) | Verify the ID from the original payment response; use List Payments to search. UAT and production are separate systems — a paymentId created in production will never exist in UAT |
| 404 — refundId not found | `refundId` wrong or refund doesn't exist | Verify the ID from the refund creation response; use List Refunds to search |
| 409 — duplicate `Idempotency-Key` | Same key reused for a different operation | Generate a fresh UUID for every distinct new operation; only reuse for retries of the same request |
| `transactionResult.responseCode: D` | Processor declined the refund | Check `responseMessage` for details; contact Payroc support if consistently declined |
| `transactionResult.responseCode: E` | Processor will process later | Refund is queued; poll `GET /v1/refunds/{refundId}` for status update |
| Adjust returns 400 | Refund already settled; can't adjust | Adjustments only possible in open batch; check `transactionResult.status` first |
| Reverse returns 400 | Refund already settled; can't reverse | Reversal only possible in open batch; no alternative if already settled |

**Error response format:** Errors use the **RFC 7807 problem-details format as the envelope** (`type`, `title`, `status`, `detail`, `instance`). Payroc **extends** the envelope with an `errors` array. Each `errors[]` item carries `parameter` (the JSON path of the failing field), `detail` (a short reason), and `message` (the human-readable explanation). Use `parameter` to map each error back to your request body.

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] `Idempotency-Key` header present and set to a UUID v4 on every POST
- [ ] Fresh UUID generated for each distinct operation (same key reused only for retries of the same request)
- [ ] For referenced refunds: `amount` and `description` present; `amount` ≤ original payment amount
- [ ] For unreferenced refunds: `channel`, `processingTerminalId`, `order.*`, `refundMethod.*` all present
- [ ] `channel` value read from `references/api-schema.md` — not from training data (`pos` or `moto`)
- [ ] `refundMethod.type` and `cardDetails.entryMethod` values read from `references/api-schema.md` — not from training data
- [ ] `refundId` captured from creation response (for unreferenced) or from `payment.refunds[].refundId` (for referenced) and stored for subsequent operations
- [ ] Reversal: developer explicitly confirmed intent before code was written
- [ ] UAT endpoints used (`api.uat.payroc.com`) — not production endpoints during testing

---

## Completion

Once all checklist items pass:

> **Refund integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **Refund** — [summarise: referenced or unreferenced, amount, description]
> - **Extended operations** (list what was built) — retrieve, list, adjust, reverse.
> - **Validated in UAT** — end-to-end flow confirmed.
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Point credentials to the production terminal and API key.

Offer next steps:
- **Refund status polling** — use `GET /v1/refunds/{refundId}` to check whether a queued refund (`responseCode: E`) was subsequently approved
- **Webhook notifications** — receive server-side refund events rather than polling
- **Card sales** — run new card payments with the `run-a-card-sale` skill

---
name: refund-an-ach-payment
description: >
  Guides developers through returning funds for an ACH (bank transfer) payment via the
  Payroc API. Use this skill when the user wants to refund an ACH payment, refund a bank
  transfer payment, return money to a customer's bank account via ACH or bank transfer,
  reverse or void a settled or open-batch bank transfer, issue a referenced refund (linked
  to a paymentId) or an unreferenced refund (standalone, no paymentId) for a bank
  transfer, process a PAD (Canadian pre-authorized debit) refund, work with the
  /v1/bank-transfer-payments/{id}/refund endpoint, or work with the
  /v1/bank-transfer-refunds endpoint. Also trigger when the developer asks about the
  difference between ACH reversals and refunds, choosing the right refund method for a
  bank transfer, NACHA return codes on a refund, or tracking ACH refund status. Does NOT
  cover card payment refunds (credit card, debit card, or Visa/Mastercard/Amex refunds —
  use the refund-a-card-payment skill for those), taking new ACH payments, accepting bank
  transfer payments, verifying bank accounts, retrying NSF/returned payments, or viewing
  ACH deposit reports.
metadata:
  version: "0.5.0"
  category: transaction
  status: draft
---

# Refund an ACH Payment

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/refund-an-ach-payment/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

## ACH terminal requirement

> **This requires an ACH-capable terminal.** ACH refunds need a terminal provisioned for ACH —
> this applies in both UAT and production. All guidance in this skill is derived from the
> published Payroc OpenAPI specification and narrative documentation.

---

On first invocation, announce to the developer:

> **Payroc ACH Refund Integration**
> I'll guide you through refunding an ACH (bank transfer) payment — choosing the right method (reversal, referenced refund, or unreferenced refund), building the request, and handling the asynchronous ACH response cycle.
>
> **How ACH refunds work:**
> - ACH is a batch payment system — refunds are not instant. Funds take 1–3 business days to clear.
> - The right approach depends on whether the original payment has settled and whether you have its ID.

---

## Quick reference

```text
# Referenced refund (settled payment, have paymentId)
POST https://api.uat.payroc.com/v1/bank-transfer-payments/{paymentId}/refund
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json

# Unreferenced refund (settled payment, no paymentId)
POST https://api.uat.payroc.com/v1/bank-transfer-refunds
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json

# Reversal (payment still in open batch)
POST https://api.uat.payroc.com/v1/bank-transfer-payments/{paymentId}/reverse
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json

# Reverse a refund (undo a previously issued unreferenced refund)
POST https://api.uat.payroc.com/v1/bank-transfer-refunds/{refundId}/reverse
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

---

## Scope — what this skill covers

This skill covers **ACH (bank transfer) refunds only**: US ACH and Canadian PAD (pre-authorized debit) payments processed via the Payroc bank transfer endpoints.

**If the developer is asking about refunding a card payment** (credit card, debit card, Visa, Mastercard, Amex, etc.) — that is handled by a different skill and endpoint:

> This skill does not cover card payment refunds. For refunding a card payment, use the **refund-a-card-payment** skill, which covers the `/v1/card-payments/{paymentId}/refund` endpoint. The flows, request shapes, and async behaviour differ from ACH refunds.

If the developer's question is about card refunds, tell them clearly that this skill is ACH/bank-transfer only, point them to the `refund-a-card-payment` skill, and do not attempt to answer their card refund question using this skill's guidance.

---

## References

All enum values and schemas live in the local `references/` files below — this skill emits from them,
not from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | **All** enum values, required fields, request/response schemas for both refund endpoints and the reversal endpoint |
| Narrative refund guide | `references/bank-transfer-refund-guide.md` | Step-by-step logic for choosing reversal vs referenced vs unreferenced refund; async status tracking; common issues |
| Identity call reference | `references/identity-call.md` | Bearer token exchange — endpoint URLs, headers, response fields |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core principles

1. **Read `references/api-schema.md` before emitting any enum value — in code, in dialog answers, and in code reviews.** Every field that accepts a fixed set of strings — `type`, `secCode`, `accountType`, `transactionResult.status`, `transactionResult.type` — is documented there. Read it before you emit the value, answer a question about it, or review a request body that contains it. Do not use training-data guesses. A plausible-sounding string that isn't in the documented enum will produce a 400 or silent mismatch.

   > **This read-before-emit discipline applies equally to all output modes:** dialog answers about valid values, code review verdicts on request bodies, and code generation. If a developer asks "what are the valid secCode values?" — read `references/api-schema.md` first, then answer. If a developer pastes a request body for review — read `references/api-schema.md` before issuing your verdict. Do not answer from memory even if you believe you already know the values.

2. **`Idempotency-Key` on every POST.** The header value must be a UUID v4. Omitting it causes a 400. Generate a fresh UUID for each distinct operation.
3. **ACH is asynchronous.** An initial `"ready"` or `"pending"` status is not completion — poll or use webhooks to confirm final status. Do not tell the developer the refund is "done" until `transactionResult.status` is `"complete"`.
4. **Never hardcode credentials.** API keys, terminal IDs, and account numbers must come from environment variables or a secrets manager.
5. **Choose the right method before coding.** The three paths (reversal, referenced refund, unreferenced refund) differ in eligibility, endpoint, and request shape. Determine which applies before writing any code.
6. **Read the schema reference before emitting bank account field names.** `secCode`, `accountType`, `routingNumber`, `transitNumber`, `institutionNumber` — spellings matter. Emit from `references/api-schema.md`, not from memory.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing payment or refund-related code
- Credential and environment variable conventions
- Whether `paymentId` is already stored and retrievable

Then ask the developer the following questions (pre-fill from codebase scan where possible):

1. **Do you have the original `paymentId` for the payment you want to refund?**
   - Yes → referenced refund or reversal path
   - No → unreferenced refund path (requires special merchant enablement — confirm first)

2. **Has the payment already settled?**
   - Not yet settled (still in open batch) → reversal is the right tool (not a refund)
   - Settled → referenced or unreferenced refund
   - Don't know → can look it up via `GET /v1/bank-transfer-payments/{paymentId}`

3. **Is this a full refund or partial?**
   - Note: referenced refunds apply to the full original payment amount. The referenced refund endpoint does not accept an `amount` field — do not attempt to pass one for a partial refund, as the schema does not document this field and the behaviour would be undefined. Partial refund capability should be confirmed with the Payroc Integrations team before attempting.

4. **Is the payment ACH (US) or PAD (Canadian pre-authorized debit)?**
   - Affects which bank account fields are needed for unreferenced refunds.

Use the answers to determine which path to implement below.

---

## Prerequisites

These are needed to **run and test** the integration — not to write the code. If the developer already has them, great. If not, don't block:

1. **API key** — used to obtain Bearer tokens from the Payroc Identity Service.
2. **Processing terminal ID** — required for unreferenced refunds and for listing/searching payments.
3. **`paymentId`** — required for referenced refunds and reversals. Comes from the original payment creation response.
4. **Unreferenced refund enablement** — only certain merchant accounts can send unreferenced refunds. Confirm with the Payroc Integrations team before building this path.
5. **UAT environment** — provisioned by the Payroc Integrations team.

**If anything is missing — warn, don't block.** Wire the code to read credentials from environment variables (e.g. `PAYROC_API_KEY`, `PAYROC_TERMINAL_ID`) and continue building.

### Checkpoint

Either the developer has the required credentials and IDs, or they know what's outstanding, how to obtain it, and which environment variables the code reads from — and has chosen to proceed.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Exchange your API key for a Bearer token:

```bash
# UAT / test
curl -X POST https://identity.uat.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"

# Production
curl -X POST https://identity.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"
```

Response: `access_token`, `expires_in` (3600 seconds), `token_type` ("Bearer"), `scope`. Use `Authorization: Bearer <access_token>` on all subsequent requests.

Implement a token helper in the developer's language. For production services, implement expiry tracking — tokens that expire mid-operation produce `401` errors on otherwise valid requests.

### Checkpoint

Does the token helper return a Bearer token without error? If not, verify `x-api-key` is correct and pointing at the right environment.

---

## Step 2 — Determine the correct refund path

> Read `references/bank-transfer-refund-guide.md` for the full decision logic. The table below is a summary — emit decisions from the reference, not from memory.

| Situation | Method | Endpoint |
| --- | --- | --- |
| Payment in open batch (not settled) | **Reversal** | `POST /v1/bank-transfer-payments/{paymentId}/reverse` |
| Payment settled + have `paymentId` | **Referenced refund** | `POST /v1/bank-transfer-payments/{paymentId}/refund` |
| Payment settled + no `paymentId` | **Unreferenced refund** | `POST /v1/bank-transfer-refunds` |

If the developer is unsure whether a payment has settled, help them look it up first (see Step 3a).

> **Gateway auto-conversion:** If you call the referenced refund endpoint on a payment that is still in an open batch, the Payroc gateway automatically converts it to a reversal. So if you're not sure of the settlement state, the referenced refund endpoint is safe to call — you won't create a duplicate. But confirm this behaviour with the developer so they're not surprised — when auto-converted, the response `transactionResult.status` will be `"reversal"` (not `"pending"` or `"complete"`). Note: `transactionResult.type` will remain `"refund"` regardless — the `"reversal"` value appears only in the `status` field, not in `type`.

---

## Step 3 — Referenced refund path

### Step 3a (optional) — Find the original payment

If the developer needs to look up the `paymentId`:

```bash
# By payment ID
GET https://api.uat.payroc.com/v1/bank-transfer-payments/{paymentId}
Authorization: Bearer <access_token>

# Or search by orderId / name / last4 digits
GET https://api.uat.payroc.com/v1/bank-transfer-payments?processingTerminalId=1234001&orderId=OrderRef6543
Authorization: Bearer <access_token>
```

Check the response to confirm the payment exists and its `transactionResult.status`. Note whether `refunds[]` already contains entries — a payment may already be partially or fully refunded.

### Step 3b — Issue the referenced refund

Always generate a fresh UUID v4 for `Idempotency-Key`. Do not reuse the key from the original payment.

```bash
curl -X POST https://api.uat.payroc.com/v1/bank-transfer-payments/{paymentId}/refund \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d '{}'
```

The refund amount and bank account details are taken from the original payment — you do not re-supply them.

### Step 3c — Handle the referenced refund response

**HTTP 200** — refund submitted:

```json
{
  "paymentId": "M2MJOG6O2Y",
  "processingTerminalId": "1234001",
  "order": { "amount": 4999, "currency": "USD", "orderId": "OrderRef6543", "..." : "..." },
  "bankAccount": { "type": "ach", "accountNumber": "****3159", "nameOnAccount": "Sarah Hazel Hopper", "..." : "..." },
  "transactionResult": {
    "type": "refund",
    "status": "pending",
    "authorizedAmount": -4999,
    "currency": "USD",
    "responseCode": "A",
    "responseMessage": "NoError",
    "processorResponseCode": "0"
  },
  "refunds": [ { "..." : "..." } ]
}
```

Key fields to check:
- `transactionResult.type` — will be `"refund"`. This field never returns `"reversal"` — that value is not in the `transactionResult.type` enum (`payment | refund | unreferencedRefund | accountVerification`).
- `transactionResult.status` — expect `"pending"` or `"ready"` initially; `"reversal"` if the gateway auto-converted the request (payment was still in open batch); final status arrives asynchronously
- `transactionResult.authorizedAmount` — negative value confirms it's a refund (e.g. `-4999`)

> **Do not report the refund as complete on an initial `"pending"` status.** ACH refunds take 1–3 business days. Poll `GET /v1/bank-transfer-payments/{paymentId}` and watch the `refunds[]` array for final status.

### Checkpoint

Does the API return HTTP 200 with `transactionResult.type: "refund"` and a negative `authorizedAmount`? If `transactionResult.status` is `"reversal"`, the gateway auto-converted the request (the payment was still in an open batch) — this is expected behaviour, not an error. If the response shows anything other than HTTP 200, work through the error taxonomy.

---

## Step 4 — Reversal path

Use this when the payment is still in an open batch (not settled):

```bash
curl -X POST https://api.uat.payroc.com/v1/bank-transfer-payments/{paymentId}/reverse \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json"
```

No request body is required. Returns HTTP 200 with the updated payment object (HTTP 200 is consistent with the referenced refund; the reversal endpoint's response code is not explicitly listed in `references/api-schema.md` — confirm from the live API or Payroc documentation if your code needs to differentiate).

The payment is removed from the open batch — no funds are transferred to or from the customer.

When the reversal succeeds, check `transactionResult.status` on the response — it will be `"reversal"` for an auto-converted gateway reversal or reflect the final removal state. This is the `status` field, not `type` — `transactionResult.type` does not carry a `"reversal"` value.

### Checkpoint

Does the API return HTTP 200? If not, the payment may have already settled — use the referenced refund path instead.

---

## Step 4b — Reverse a refund (undo an issued refund)

If you have already issued an unreferenced refund and need to reverse it, use the reverse-a-refund endpoint:

```bash
curl -X POST https://api.uat.payroc.com/v1/bank-transfer-refunds/{refundId}/reverse \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json"
```

No request body is required. This is a different endpoint from the payment reversal (`/bank-transfer-payments/{paymentId}/reverse`) — it applies to a refund that has already been created.

> **Note:** This endpoint is only documented for unreferenced refunds (`/v1/bank-transfer-refunds/{refundId}/reverse`). To reverse a referenced refund, consult the Payroc Integrations team.

---

## Step 5 — Track refund status (asynchronous)

ACH refunds and reversals are not instant. To track final outcome:

**Poll referenced refund:**
```bash
GET https://api.uat.payroc.com/v1/bank-transfer-payments/{paymentId}
Authorization: Bearer <access_token>
```
For referenced refunds the source of truth is the `refunds[]` array on the payment response — not the parent `transactionResult.status`. Each entry in `refunds[]` has its own `status` field. Find the refund by its ID and read `refunds[n].status` to determine completion.

**Poll unreferenced refund:**
```bash
GET https://api.uat.payroc.com/v1/bank-transfer-refunds/{refundId}
Authorization: Bearer <access_token>
```
Check `transactionResult.status` on the returned `bankTransferRefund` object.

> **Read `references/api-schema.md` for the full `transactionResult.status` enum** before writing status-handling logic. Do not assume the set of values from memory.

Terminal statuses (stop polling when you see any of these — read `references/api-schema.md` for the authoritative full enum before writing switch/if logic):
- `"complete"` — funds returned to the customer's account
- `"reversal"` — the payment or refund was processed as a reversal (open-batch removal or direct reversal); this is the expected final state for both gateway auto-conversions and direct `POST .../reverse` calls
- `"returned"` — the customer's bank rejected the ACH return (NACHA return); the refund did not succeed
- `"declined"` — the refund was declined by the processor
- `"referral"` — requires manual review; treat as terminal for polling purposes and contact Payroc support
- `"pickup"` — administrative hold (rare for ACH); treat as terminal and contact Payroc support
- `"admin"` — administrative hold; treat as terminal and contact Payroc support
- `"expired"` — the transaction expired without completion; treat as terminal
- `"accepted"` — processor acknowledged; treat as terminal

---

## Step 6 — Unreferenced refund path

> **Prerequisite:** Only certain merchant accounts can send unreferenced refunds. Confirm enablement with the Payroc Integrations team before building this path. A `403` response indicates the terminal is not enabled.

> **Read `references/api-schema.md` before emitting any field name or enum value in the request body.** The `type`, `secCode`, and `accountType` values must come from the reference — not from training-data guesses.

> **`processingTerminalId` is a string.** Even though it looks like a number (e.g. `"1234001"`), it must be sent as a quoted JSON string — not a JSON integer. Serialising it as `1234001` (no quotes) will produce a 400.

### Step 6a — ACH (US) unreferenced refund

Use `refundMethod.type: "ach"` with `routingNumber` (9-digit ABA number), `accountType`, and `secCode`:

```bash
curl -X POST https://api.uat.payroc.com/v1/bank-transfer-refunds \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d '{
    "processingTerminalId": "1234001",
    "order": {
      "orderId": "REFUND-OrderRef6543",
      "description": "Refund for order OrderRef6543",
      "amount": 4999,
      "currency": "USD"
    },
    "refundMethod": {
      "type": "ach",
      "accountNumber": "1234567890",
      "nameOnAccount": "Sarah Hazel Hopper",
      "routingNumber": "123456789",
      "accountType": "checking",
      "secCode": "web"
    },
    "customer": {
      "notificationLanguage": "en",
      "contactMethods": [{"type": "email", "value": "sarah.hopper@example.com"}]
    }
  }'
```

### Step 6b — PAD (Canadian pre-authorized debit) unreferenced refund

Use `refundMethod.type: "pad"` instead of `"ach"`. PAD uses different bank account fields: **`transitNumber`** (5-digit branch transit) and **`institutionNumber`** (3-digit bank institution code) instead of `routingNumber`. There is no `secCode` field for PAD. Read `references/api-schema.md` for the full PAD variant schema before emitting any field names.

```bash
curl -X POST https://api.uat.payroc.com/v1/bank-transfer-refunds \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d '{
    "processingTerminalId": "1234001",
    "order": {
      "orderId": "REFUND-OrderRef6543-CA",
      "description": "Refund for order OrderRef6543",
      "amount": 4999,
      "currency": "CAD"
    },
    "refundMethod": {
      "type": "pad",
      "accountNumber": "1234567890",
      "nameOnAccount": "Marie Tremblay",
      "transitNumber": "12345",
      "institutionNumber": "001"
    }
  }'
```

Key differences between ACH and PAD `refundMethod` fields:

| Field | ACH (`type: "ach"`) | PAD (`type: "pad"`) |
| --- | --- | --- |
| `routingNumber` | Required (9-digit ABA) | Not used |
| `transitNumber` | Not used | Required (5-digit branch transit) |
| `institutionNumber` | Not used | Required (3-digit bank code) |
| `accountType` | Required (`"checking"` or `"savings"`) | Required |
| `secCode` | Required (`web`/`tel`/`ccd`/`ppd`) | Not used |

**HTTP 201** — unreferenced refund submitted:

```json
{
  "refundId": "R1ABCDEFGH",
  "processingTerminalId": "1234001",
  "order": { "orderId": "REFUND-OrderRef6543", "amount": 4999, "currency": "USD", "..." : "..." },
  "transactionResult": {
    "type": "unreferencedRefund",
    "status": "pending",
    "authorizedAmount": -4999,
    "currency": "USD",
    "responseCode": "A"
  }
}
```

Save `refundId` for tracking (see Step 5).

> **Amounts are in the currency's lowest denomination.** `"amount": 4999` = $49.99 USD. `"amount": 100` = $1.00.

### Step 6c — Secure-token unreferenced refund

If the customer's bank account has been tokenized by Payroc (via the secure-token service), you can use the token as the `refundMethod` instead of raw account details. Read `references/api-schema.md` for the full `secureToken` variant schema before emitting any field names.

```bash
curl -X POST https://api.uat.payroc.com/v1/bank-transfer-refunds \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d '{
    "processingTerminalId": "1234001",
    "order": {
      "orderId": "REFUND-OrderRef6543",
      "description": "Refund for order OrderRef6543",
      "amount": 4999,
      "currency": "USD"
    },
    "refundMethod": {
      "type": "secureToken",
      "token": "296753XXXXXX",
      "accountType": "checking",
      "secCode": "web"
    }
  }'
```

Key fields for the `secureToken` variant (read `references/api-schema.md` for the authoritative schema):
- `type` — must be `"secureToken"` (or `"singleUseToken"` for a single-use token variant)
- `token` — the previously issued secure token (296753-prefixed, up to 12 digits)
- `accountType` — conditional; required if the token represents a bank account
- `secCode` — conditional; required if the token represents an ACH account; omit for PAD tokens

> **Do not apply ACH or PAD raw-account field names** (`routingNumber`, `accountNumber`, `nameOnAccount`, `transitNumber`, `institutionNumber`) to a secure-token request. The token encapsulates the account — only supply the fields in the `secureToken` variant schema.

### Checkpoint

Does the API return HTTP 201 with `transactionResult.type: "unreferencedRefund"`? If not, work through the error taxonomy. A 403 means the terminal is not enabled for unreferenced refunds.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `401` on any request | Token missing, expired, or API key wrong | Re-exchange token; verify `x-api-key` header value is the correct UAT key |
| `400` — missing or malformed `Idempotency-Key` | Header absent or not a UUID v4 | Add `Idempotency-Key: <UUID v4>` to every POST; generate a new UUID per operation |
| `400` — validation error on `refundMethod` | Wrong field name or enum value | Read `references/api-schema.md`; check `type`, `secCode`, `accountType` spellings. Note: `secCode` values are **lowercase** (`web`, `tel`, `ccd`, `ppd`) — NACHA convention is uppercase but the API expects lowercase |
| `400` — validation error on `processingTerminalId` | Sent as integer instead of string | `processingTerminalId` is always a **string** — send `"1234001"` with quotes, not `1234001` as a JSON integer |
| `400` — validation error on PAD `refundMethod` | Sent `routingNumber` instead of PAD fields | For PAD (`type: "pad"`), use `transitNumber` + `institutionNumber` — not `routingNumber` (which is ACH-specific) |
| `400` — `amount` not an integer | Sending `49.99` instead of `4999` | Convert to lowest denomination (cents); amounts must be integers |
| `400` — validation error on `order.description` | Field missing from unreferenced refund body | `order.description` is **required** for unreferenced refunds — unlike many payment APIs where description is optional |
| `403` — permission denied on unreferenced refund | Terminal not enabled for unreferenced refunds | Contact Payroc Integrations team to enable the feature for this merchant account |
| `404` — payment not found | `paymentId` wrong, or payment doesn't exist on this terminal | Verify the `paymentId` from the original payment creation response; check that terminal matches |
| `409` — idempotency key conflict | Same key reused with different payload | Generate a fresh UUID for each distinct operation |
| `409` — resource already exists / refund already issued | Payment already fully refunded | Check `payment.refunds[]` before submitting; do not re-issue if already complete |
| `transactionResult.status: "returned"` | Customer's bank rejected the ACH return (NACHA return code) | Closed/invalid account. Resolve outside ACH (check, wire, or credit). |
| Initial status `"pending"` but no update after days | ACH processing delay or NACHA return | Poll `GET /v1/bank-transfer-payments/{paymentId}` or `GET /v1/bank-transfer-refunds/{refundId}`; check for `"returned"` status |
| Reversal 400 or unexpected behaviour | Payment has already settled — can't reverse | Use the referenced refund endpoint instead |

**Error response shape (RFC 7807 + Payroc extension):**

Errors use the **RFC 7807 problem-details format as the envelope**: top-level `type`, `title`, `status`, `detail`, and `instance` are the standard RFC members. Payroc **extends** the envelope with an `errors` array (not defined by RFC 7807). Each `errors[]` item carries `parameter` (the JSON path of the failing field), `detail` (a short reason), and `message` (the human-readable explanation). Use `parameter` to map each error back to your request body.

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] `Idempotency-Key` header present and set to a UUID v4 on every POST
- [ ] Correct refund path chosen: reversal (open batch), referenced (settled + have paymentId), unreferenced (settled + no paymentId)
- [ ] `refundMethod.type`, `secCode`, `accountType`, and all other enum values read from `references/api-schema.md` — not from training data
- [ ] `secCode` enum values are lowercase (`web`, `tel`, `ccd`, `ppd`) — not uppercase
- [ ] `processingTerminalId` is sent as a JSON string (`"1234001"`), not an integer (`1234001`)
- [ ] For PAD (Canadian) unreferenced refunds: `transitNumber` + `institutionNumber` used instead of `routingNumber`; no `secCode`
- [ ] Amounts are integers in the currency's lowest denomination (e.g. cents), not decimals
- [ ] For referenced refunds: `paymentId` captured from the original payment creation response and used in the path
- [ ] For unreferenced refunds: merchant account confirmed as enabled for unreferenced refunds
- [ ] ACH async handling: code does not assume `"pending"` status means failure; polling or webhook logic implemented
- [ ] UAT endpoints used (`api.uat.payroc.com`) — not production endpoints during testing

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values (`type`, `secCode`, `accountType`, `transactionResult.status`, etc.)
- Complete request schemas for referenced refund, unreferenced refund, and reversal
- Response object schemas (`bankTransferPayment`, `bankTransferRefund`)
- List/search query parameter reference

---
name: take-an-ach-payment
description: >
  Guide a developer through accepting ACH (Automated Clearing House) or PAD (Pre-Authorized Debit)
  bank transfer payments via the Payroc API (POST /v1/bank-transfer-payments). Use this skill when
  the user wants to accept ACH payments, collect bank transfer payments, process direct debit
  payments, charge a customer's bank account (checking or savings), implement bank account billing,
  process eCheck payments, set up recurring ACH charges, or tokenize bank account details for
  future charges. As part of building the integration, also covers: reversing (voiding) a payment
  before settlement, re-presenting a returned ACH transaction (NSF / closed account retry), and
  refunding as one step of the overall payment flow. Does NOT cover: refunding or reversing an ACH
  payment as the primary goal (use refund-an-ach-payment for that), viewing ACH deposit reports,
  verifying bank accounts, card payments, or single-use card tokens. Also covers single-use bank
  account tokens (`singleUseToken` type) obtained from a Hosted Fields session.
metadata:
  version: "0.4.3"
  category: transaction
  status: draft
---

# Take an ACH / Bank Transfer Payment

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/take-an-ach-payment/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc ACH / Bank Transfer Payments**
> I'll guide you through accepting payments directly from your customers' bank accounts using the
> Payroc Bank Transfer Payments API.
>
> **What this covers:**
> - ACH payments (US bank accounts — routing number + account number)
> - PAD payments (Canadian bank accounts — transit number + institution number)
> - Tokenizing bank details for future charges
> - Reversals (void before settlement), refunds, and re-presenting returned ACH transactions
>
> **What to know upfront:**
> - ACH payments are asynchronous — `status` is initially `pending` and settles later
> - PAD representment is currently unavailable in the Payroc UAT environment
> - ACH re-presentment has limited testability in UAT — document this in production code
> - Account numbers and routing numbers are always masked in API responses (last 4 digits only)

> **eCheck note:** In the Payroc API, eCheck is implemented as ACH — there is no separate eCheck product or additional micro-deposit verification step. A developer expecting a bank-verification handshake before the first charge (common in other payment platforms) should be informed that Payroc ACH proceeds directly to the transaction.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
POST https://api.uat.payroc.com/v1/bank-transfer-payments
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

---

## References

All enum values and schemas live in the local `references/` files below — this skill emits from them,
not from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| Identity service auth | `references/identity-call.md` | Bearer token endpoint URL, header name, response shape |
| API schema reference | `references/api-schema.md` | All enum values, required fields, request/response schemas |
| Error format reference | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| Narrative guide | `references/ach-payment-guide.md` | Payment lifecycle, reversal/refund logic, re-presentment workflow, tokenization |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core principles

1. **Inspect before asking** — scan the codebase before asking anything; use what you find to skip obvious questions.
2. **Ask before coding** — gather unknowns through intake before writing implementation code.
3. **Read `references/api-schema.md` before emitting any enum value.** Fields like `paymentMethod.type`, `accountType`, `secCode`, and `transactionResult.status` are all defined there. Do not use training-data guesses. A plausible-sounding string that isn't in the documented enum produces a 400 error. Note that `paymentMethod.type` has inconsistent casing: `ach` and `pad` are all-lowercase, but `secureToken` and `singleUseToken` are camelCase — `"securetoken"`, `"secure_token"`, and `"SecureToken"` all produce 400s.
4. **Read `references/api-schema.md` before reviewing developer-submitted code.** When a developer shares existing code for review, read `references/api-schema.md` before issuing any verdict — enum casing, required fields, and schema shapes must be verified against the reference, not from memory.
5. **Idempotency-Key on every POST.** Must be a UUID v4. Required — omitting it causes a 400. Generate a fresh UUID for each distinct operation.
6. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables or a secrets manager, never source code.
7. **Bearer token expiry.** Tokens expire after 3,600 seconds (1 hour). For long-running services, implement token refresh logic.
8. **Validate before advancing** — don't move to the next step until the current step's checkpoint passes in UAT.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing payment or billing code
- Any existing HTTP client setup or credential configuration
- How environment variables are managed

Then confirm with the developer:

1. **Payment type** — US (ACH) or Canadian (PAD)?
2. **Account collection** — collect bank details directly in the request (`ach`/`pad`), use a reusable token from a prior payment (`secureToken`), or use a single-use token from a Hosted Fields session (`singleUseToken`)?
3. **SEC code** — (ACH only) what's the transaction context: `web` (internet), `tel` (phone), `ccd` (business), or `ppd` (prearranged/recurring)?
4. **Tokenization** — store bank details for future use? (sets `credentialOnFile.tokenize: true`)
5. **Post-payment operations** — retrieval only, or also refunds / reversals / re-presentment?

Use the answers to scope the implementation. If the use case is ambiguous, ask one targeted question before proceeding.

---

## Prerequisites

These are needed to test the integration in UAT — not to write the code. If the developer already has them, proceed. If not, wire the code to read each from an environment variable and keep building.

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by the Payroc Integrations team.
2. **Processing terminal ID** — included in the request body (`processingTerminalId`). ACH capability must be enabled on the terminal by Payroc.
3. **UAT environment** — test environment. No self-serve signup; terminals are provisioned by the Payroc Integrations team.

**If anything is missing — warn, don't block.** Propose env var names like `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID`. Write code to read from those variables, then tell the developer:

> ⚠️ I've wired this to read credentials from `<VAR names>`. You'll need a Payroc UAT terminal with ACH enabled to test this — contact the Payroc Integrations team if you don't have one yet. I can keep building in the meantime.

### Checkpoint

Either credentials are confirmed, or the developer knows what's outstanding, how to obtain it, and which env vars the code reads from.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). All subsequent API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic — tokens that expire mid-operation will produce 401s on otherwise valid requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the UAT environment.

---

## Step 2 — Build the payment request

> **Read `references/api-schema.md` before writing the request body.** Enum values for `paymentMethod.type`, `accountType`, `secCode`, and all other discriminated fields are defined there. Do not emit them from training data.

Endpoint: `POST https://api.uat.payroc.com/v1/bank-transfer-payments`

Required headers:
```
Authorization: Bearer <token>
Content-Type: application/json
Idempotency-Key: <UUID v4>
```

### 2a — US ACH payment (type: "ach")

> **`order.orderId` must be unique per payment.** The examples below use static strings (`ORDER-001`, etc.) for readability — replace them with a generated unique value (e.g. a UUID or incrementing reference) in production code. Reusing the same `orderId` across distinct payments can cause data integrity issues.
> **`order.currency`** must be a 3-letter uppercase ISO 4217 code (`"USD"`, `"CAD"`). `"usd"`, `"US"`, or `"ca"` will fail validation.

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "order": {
    "orderId": "ORDER-001",
    "amount": 4999,
    "currency": "USD",
    "description": "Optional description"
  },
  "paymentMethod": {
    "type": "ach",
    "nameOnAccount": "Customer Full Name",
    "accountNumber": "123456789",
    "routingNumber": "053200983",
    "accountType": "checking",
    "secCode": "web"
  }
}
```

> **`secCode` is mandatory for ACH payments** — always include it. Read `references/api-schema.md` for the valid values: `web`, `tel`, `ccd`, `ppd`. Choose based on how the customer authorised the transaction. Do not guess or omit.

> **`accountType` is optional** — include it when the customer's account type is known (reduces decline risk). Valid values: `"checking"` and `"savings"` only (read `references/api-schema.md`). Do not include it if unknown rather than guessing.

**Amount is in cents** (integer in lowest denomination): `$49.99` → `4999`.

### 2b — Canadian PAD payment (type: "pad")

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "order": {
    "orderId": "ORDER-002",
    "amount": 5000,
    "currency": "CAD"
  },
  "paymentMethod": {
    "type": "pad",
    "nameOnAccount": "Customer Full Name",
    "accountNumber": "123456789",
    "transitNumber": "12345",
    "institutionNumber": "003",
    "accountType": "checking"
  }
}
```

PAD uses a 5-digit `transitNumber` and 3-digit `institutionNumber` instead of a routing number.
`secCode` does not apply to PAD. `accountType` is optional — include when known.

### 2c — Secure token payment (type: "secureToken")

Use a token obtained from a prior ACH/PAD payment when `credentialOnFile.tokenize: true` was set:

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "order": {
    "orderId": "ORDER-003",
    "amount": 2999,
    "currency": "USD"
  },
  "paymentMethod": {
    "type": "secureToken",
    "token": "296753xxxxxxxxx",
    "secCode": "ppd"
  }
}
```

> **`secCode` is still required when the token is ACH-backed.** If the original payment was ACH (`type: "ach"`), include `secCode` in the secureToken request. For PAD-backed tokens, `secCode` does not apply.

> **Token extraction path after tokenization:** When `credentialOnFile.tokenize: true` is set, the reusable token is returned in the response at `bankAccount.secureToken.token` — not in `paymentMethod` or `credentialOnFile`. Store that value for future `secureToken` requests.

### 2d — Single-use token payment (type: "singleUseToken")

Use a single-use token obtained from a Hosted Fields session or tokenization endpoint. A `singleUseToken` can only be used once; it is consumed after the first successful charge.

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "order": {
    "orderId": "ORDER-004",
    "amount": 2999,
    "currency": "USD"
  },
  "paymentMethod": {
    "type": "singleUseToken",
    "token": "<single-use-token-from-hosted-fields>",
    "secCode": "web"
  }
}
```

> **`type` must be `"singleUseToken"` (camelCase) — not `"single_use_token"` or `"singleusetoken"`.** Read `references/api-schema.md` for the exact casing.
> **`secCode` is required** when the underlying bank account is ACH-backed. Omit for PAD-backed single-use tokens.
> **Do not reuse** a `singleUseToken` value — it is invalidated after first use. Attempting to reuse it will produce a 400.

### Optional: tokenize bank details

Add to any payment request to store bank details for future charges:

```json
"credentialOnFile": {
  "tokenize": true
}
```

After the payment succeeds, the reusable token is returned in the response at `bankAccount.secureToken.token` — not at `paymentMethod.token` or `credentialOnFile.token`. Persist this value to use in subsequent `secureToken` requests.

### Optional: customer notifications

```json
"customer": {
  "notificationLanguage": "en",
  "contactMethods": [
    { "type": "email", "value": "customer@example.com" }
  ]
}
```

### Checkpoint

Does the request body include all required fields? Cross-check against `references/api-schema.md` before sending. Do not advance until the request body validates.

---

## Step 3 — Send the request and handle the response

Generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* failed request, reuse the same key. On a genuinely new submission, generate a new UUID.

```bash
curl -X POST https://api.uat.payroc.com/v1/bank-transfer-payments \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @payment-payload.json
```

### Success response (HTTP 201)

```json
{
  "paymentId": "PAY-XXXX",
  "processingTerminalId": "1234001",
  "order": {
    "orderId": "ORDER-001",
    "amount": 4999,
    "currency": "USD"
  },
  "bankAccount": {
    "type": "ach",
    "nameOnAccount": "Customer Full Name",
    "accountNumber": "*****5929",
    "routingNumber": "*****4162"
  },
  "transactionResult": {
    "type": "payment",
    "status": "pending",
    "responseCode": "E",
    "responseMessage": "Pending",
    "authorizedAmount": 4999,
    "currency": "USD"
  }
}
```

**Persist `paymentId` immediately** — it is required for all follow-on operations (retrieval, refund, reversal, representment).

**IDs are opaque.** The `PAY-XXXX` form above is illustrative. Treat every ID as an opaque string — do not validate against a pattern.

**ACH is asynchronous.** The initial `transactionResult.status` is typically `pending` (response code `E`). Funds are not confirmed until the status transitions to a terminal state. Poll via `GET /v1/bank-transfer-payments/{paymentId}` or use webhooks to detect status changes.

**Status values — all 7 (read `references/api-schema.md` before writing any status-based branching):**

Transient states (not a final outcome — keep polling or wait for a webhook):
- `ready` — transaction queued, not yet submitted to processor
- `pending` — processing in progress; the normal initial state after creation

Terminal states (final outcome — act on these):
- `complete` — funds successfully transferred
- `declined` — processor rejected the transaction
- `returned` — bank returned the payment after settlement (e.g., NSF, closed account) — can trigger re-presentment
- `admin` — administrative hold; contact Payroc support
- `reversal` — transaction reversed (voided before settlement)

Never treat `pending` as a failure — it is the normal initial state after creation.

> **Read `references/api-schema.md` for the full `transactionResult.status` enum** before writing any status-based branching logic. Do not assume status values from training data.

### Checkpoint

HTTP 201 received with a `paymentId` in the response? If not, work through the error taxonomy.

---

## Step 4 — Post-payment operations

*(Implement only the operations the developer selected during intake)*

### Retrieve a payment

`GET https://api.uat.payroc.com/v1/bank-transfer-payments/{paymentId}`

Headers: `Authorization: Bearer <token>`

Returns the full payment object including current `transactionResult.status`. Use this to poll for settlement or to find the return `paymentId` needed for re-presentment.

---

### List payments

`GET https://api.uat.payroc.com/v1/bank-transfer-payments?processingTerminalId=<id>`

`processingTerminalId` is **required**. Optional filters include `orderId`, `nameOnAccount`, `last4`, `type` (`ach`/`pad`), `status`, `dateFrom`, `dateTo`, `settlementState` (`unsettled`/`settled`), and `settlementDate`.

> **Read `references/api-schema.md` for the exact `type` and `status` enum values** before writing filter logic.

Pagination: cursor-based via `limit`, `after`, `before` query parameters.

---

### Reverse (void) or refund a payment — choose based on settlement state

**Before writing reversal or refund code, ask the developer (or instruct them to check):** has the payment already settled?

- Retrieve the payment via `GET /v1/bank-transfer-payments/{paymentId}` and inspect `transactionResult.status` and `settlementState` to determine the correct operation.
- If the payment is **still in an open batch** (not yet settled): use **reversal** — voids the payment before funds move.
- If the payment has **already settled**: use **refund** — returns funds to the customer's bank account.

**Never prescribe reversal or refund without first determining settlement state.** The wrong operation will fail.

#### Reverse (void)

`POST https://api.uat.payroc.com/v1/bank-transfer-payments/{paymentId}/reverse`

Headers: `Authorization: Bearer <token>`, `Idempotency-Key: <UUID v4>`

No request body required. Removes the payment from the open batch — no funds are taken. Only works if the payment is still in an open batch (before settlement).

**Note:** If you issue a referenced refund on a payment still in an open batch, the gateway automatically reverses it — you don't need to call reverse explicitly in that case.

---

#### Refund a payment

`POST https://api.uat.payroc.com/v1/bank-transfer-payments/{paymentId}/refund`

Headers: `Authorization: Bearer <token>`, `Idempotency-Key: <UUID v4>`

Requires a body with `amount` and `description` — both are mandatory, and an empty body returns `400`. Send the original amount for a full refund, or a lower value for a partial one.

**You can't run a referenced refund against an ACH payment that is in a closed batch.** Our gateway returns a `400` error, `Bank transfer with status COMPLETE can not be refunded`, as soon as the batch closes, and while the batch is still open it reverses the payment rather than refunding it. To return funds for an ACH payment after its batch closes, run an unreferenced refund (`POST /v1/bank-transfer-refunds`) instead. This doesn't apply to pre-authorized debit (PAD) payments.

Refunds are a separate flow with their own decision logic — use the **refund-an-ach-payment** skill rather than building from this section.

---

### Re-present a returned ACH payment

Use this to retry an ACH payment that was returned by the bank (e.g., NSF, closed account), after
resolving the issue with the customer.

**Critical:** Use the `paymentId` from the `returns[]` array in the original payment response — **not**
the original `paymentId`. Retrieve the original payment first to get the return record.

Specifically: retrieve via `GET /v1/bank-transfer-payments/{originalPaymentId}`, then use `returns[0].paymentId` as the path parameter — each item in `returns[]` has its own `paymentId` field. Read `references/api-schema.md` for the full `returns[]` item shape.

`POST https://api.uat.payroc.com/v1/bank-transfer-payments/{returnPaymentId}/represent`

> **Path segment is `/represent` (verb) — not `/representment`, `/re-present`, or `/re-presentment`.** The narrative throughout this skill uses "re-presentment" as a noun, but the endpoint path uses the verb form `represent`. Typing `/representment` produces a 404.

Headers: `Authorization: Bearer <token>`, `Idempotency-Key: <UUID v4>`

Request body is optional. Omit to reuse the original bank details, or supply updated bank account details if the customer changed accounts:

```json
{
  "paymentMethod": {
    "type": "ach",
    "nameOnAccount": "Customer Full Name",
    "accountNumber": "987654321",
    "routingNumber": "053200983",
    "accountType": "checking",
    "secCode": "web"
  }
}
```

Payments can be re-presented a **maximum of two times**.

**UAT note:** PAD representment is currently broken in the Payroc UAT environment. ACH representment availability in UAT may be limited. Document this in comments if writing production code that relies on it.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header value is the correct UAT API key |
| 400 — validation error on `type`, `accountType`, or `secCode` | Enum value not from the reference | Read `references/api-schema.md` and use the documented value exactly — note `secureToken` and `singleUseToken` are camelCase |
| 400 — validation error on `currency` | Lowercase, 2-letter, or unknown currency code | Use a 3-letter uppercase ISO 4217 code: `"USD"`, `"CAD"` |
| 400 — `idempotencyKeyMissing` | `Idempotency-Key` header absent | Add `Idempotency-Key: <UUID v4>` to every POST request |
| 400 — missing required field | Required field absent from request body | Cross-check required fields in `references/api-schema.md` for the payment method type |
| 400 — `secCode` missing for ACH | Forgot `secCode` on an `ach`-type payment | Add `secCode` — it is mandatory for ACH transactions |
| 409 — duplicate `Idempotency-Key` | Same key reused across different operations | Generate a fresh UUID for every distinct operation |
| Payment `status: returned` | Bank returned the payment (NSF, closed account) | Investigate return reason; contact customer; use re-presentment if appropriate |
| Re-present fails or wrong `paymentId` | Using original `paymentId` instead of return's `paymentId` | Retrieve the original payment; use `returns[0].paymentId` from the `returns[]` array (each return item has its own `paymentId` field) |
| Refund returns an automatic reversal | Payment was in an open batch | The gateway voided it automatically; this is correct behaviour |
| 500 — server error | Transient gateway error | Retry with exponential backoff; if persistent, contact Payroc support |

**Error response shape** — errors follow the RFC 7807 problem-details format as the envelope (`type`,
`title`, `status`, `detail`, `instance`); Payroc extends it with an `errors` array. Each `errors[]`
item carries `parameter` (the JSON path of the failing field), `detail` (short reason), and `message`
(human-readable). Use `parameter` to map each error back to your request body.

---

## Read-then-emit discipline

The following fields **must** be read from `references/api-schema.md` before emitting — never from
training data:

| Field | Why it matters |
| --- | --- |
| `paymentMethod.type` | `ach`/`pad`/`secureToken`/`singleUseToken` — wrong value produces 400 |
| `paymentMethod.accountType` | `checking`/`savings` only — snake_case or other forms rejected |
| `paymentMethod.secCode` | `web`/`tel`/`ccd`/`ppd` — mandatory for ACH; wrong value produces 400 |
| `transactionResult.status` | 7 values — do not branch on guessed status strings |
| List filter `type` | `ach`/`pad` — enum for query parameter |
| List filter `status` | same 7 values as transactionResult.status |
| List filter `settlementState` | `unsettled`/`settled` — 2 values only |

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] `Idempotency-Key` header present and set to a UUID v4 on every POST
- [ ] `paymentMethod.type`, `accountType`, `secCode` values read from `references/api-schema.md` — not from training data
- [ ] `processingTerminalId` is provided in the request body
- [ ] `order.orderId` is unique per payment — not a static string copied from an example
- [ ] `order.currency` is a 3-letter uppercase ISO 4217 code (e.g. `"USD"`, `"CAD"`)
- [ ] `order.amount` is in the currency's lowest denomination (cents, not dollars)
- [ ] `secCode` is included for all ACH (`type: "ach"`) payments
- [ ] PAD payments use `transitNumber` + `institutionNumber` (not `routingNumber`)
- [ ] `paymentId` captured from creation response and stored for subsequent operations
- [ ] For re-presentment: the `paymentId` used is `returns[0].paymentId` from `returns[]`, not the original payment's `paymentId`
- [ ] UAT endpoints used during testing (`api.uat.payroc.com`)

---

## Completion

Once all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **ACH/PAD payment** — [summarise: payment type, SEC code, tokenization if enabled]
> - **Post-payment operations** — [list what was built: retrieve, list, reverse, refund, re-present]
> - **Validated in UAT** — end-to-end flow confirmed (note any UAT limitations encountered).
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Point credentials to the production terminal and API key.

Offer next steps:
- **Refund an ACH payment** — return funds to the customer's bank account after settlement
- **View ACH deposits** — check batch settlement details via the reporting API
- **Save a payment method** — tokenize card details for multi-payment-method recurring billing
- **Webhook notifications** — receive server-side payment events rather than polling

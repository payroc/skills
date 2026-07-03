---
name: run-a-card-sale
description: >
  Guides developers through running a card sale (immediate-capture payment) via the Payroc Payments
  API (POST /v1/payments). Use this skill when the user wants to process a card payment, charge a
  credit or debit card, run a card transaction or card sale, take a card payment, collect a card
  payment, run an immediate-capture payment, implement a direct-API card payment (server-to-server),
  accept a card payment online or in-store, process a MOTO payment, use a card token or
  single-use token to charge a customer, or work with the /v1/payments endpoint for a sale. Also
  use when the user asks about card payment channels (pos/web/moto), card entry methods, what fields
  are required for a card payment request, how to get a paymentId from a sale, or how to submit a
  card payment and handle the response — even if they don't use the word "skill" or "payments API"
  explicitly. Do NOT use for pre-authorization (autoCapture: false), refunds, reversals,
  ACH/bank-transfer payments, 3-D Secure authentication, or Hosted Fields / Hosted Payment Pages
  (embedded UI card input) — those are separate skills.
metadata:
  version: "0.1.0"
  category: transaction
  status: draft
---

# Run a Card Sale

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/run-a-card-sale/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Card Sale Integration**
> I'll guide you from authentication through a working card sale — sending a payment request and handling the response.
>
> **What "run a card sale" means:**
> A sale charges the card immediately when the payment is approved (`autoCapture: true`, the default).
> The gateway returns a `paymentId` you can use for refunds, reversals, or adjustments later.
>
> **This skill vs. related skills:**
> - **Card sale (this skill)** — immediate capture; funds taken now.
> - **Pre-authorization** — funds held, captured separately. Different skill.
> - **Refund a card payment** — return funds to the customer. Different skill.
> - **3-D Secure** — additional online authentication layer. Different skill.
> - **Save a payment method** — tokenise a card for future use. Different skill.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
POST  https://api.uat.payroc.com/v1/payments
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
| Identity call reference | `references/identity-call.md` | Bearer token exchange endpoint, request, response |
| API schema reference | `references/api-schema.md` | **All** enum values, required fields, request/response schemas |
| Error format reference | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| Narrative guide | `references/run-a-card-sale-guide.md` | Conceptual context, channel guidance, feature overview |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Inspect before asking** — read the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through intake before writing implementation code; wrong assumptions waste the developer's time.
3. **Read the schema reference before emitting or reviewing any enum value.** Every field that accepts a fixed set of strings — `channel`, `paymentMethod.type`, `cardDetails` entry method, `tip.type`, `tip.mode`, `tax.type`, `healthcareExpenses[].type` — is documented in `references/api-schema.md`, the authoritative copy for this skill. Read it before you write or assess the value. This applies both when generating code and when reviewing developer code for correctness. Do not use training-data guesses.
4. **Idempotency-Key on every POST.** The header value must be a UUID v4. This is required, not optional — omitting it causes a 400. Generate a fresh UUID for each distinct payment attempt.
5. **Never hardcode credentials.** API keys, terminal IDs, and card numbers must come from environment variables or a secrets manager.
6. **Bearer token expiry.** Tokens from the identity service expire after 3,600 seconds (1 hour). For short scripts this is fine; for long-running services, implement token refresh logic.
7. **Save `paymentId` immediately.** The `paymentId` in the response is the key for all follow-on operations. Capture it from the response before anything else.
8. **Validate before advancing** — don't move to the next step until the current step's checkpoint passes in UAT.
9. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing payment or billing code
- Any existing HTTP client setup or credential configuration
- How environment variables are managed

Use what you find to pre-fill obvious answers and ask targeted questions. Then present the following checklist — the developer's answers determine which sections you implement:

---

**What does your integration need? Ask the developer to confirm:**

- **[Always included]** Authenticate and run a card sale (required core)
- **Card input source:** raw card details (keyed/manual entry), a saved secure token, or a single-use token from Hosted Fields?
- **Channel:** `pos` (in-store terminal), `web` (online checkout), or `moto` (phone/mail order)?
- **Currency and amount:** fixed or dynamic?
- **Order reference:** what format is your merchant `orderId`?
- **Customer data:** do you need to collect billing address, shipping address, or contact details for AVS or receipts?
- **Itemised amounts:** do you need to submit tips, taxes, surcharges, or line items in a `breakdown`?
- **Tokenisation:** do you want to save the card for future charges? (Separate skill — flag if yes)
- **3-D Secure:** do you need additional authentication for online payments? (Separate skill — flag if yes)

Use the answers to scope the implementation. If the developer's use case is ambiguous (e.g. "I want to charge a card"), ask one targeted clarifying question before proceeding.

---

## Prerequisites

These are needed to **run and test** the integration in UAT — not to write the code. If the developer already has them, proceed. If not, don't block — write the code to read values from environment variables and keep building.

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by the Payroc Integrations team.
2. **Processing terminal ID** — the `processingTerminalId` sent in every payment request. The developer should have this from their UAT setup.
3. **UAT environment** — Payroc's test environment. There is no self-serve signup; UAT terminals are provisioned manually by the Payroc Integrations team.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it; otherwise propose `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID`. Write the code to read credentials from those variables, then tell the developer plainly:

> ⚠️ I've wired this to read your API key and terminal ID from `<VAR names>`. You'll need a Payroc UAT terminal and API key to actually run or test this — contact the Payroc Integrations team to get them. I can keep building in the meantime.

### Checkpoint

Either the credentials are confirmed, or the developer knows what's outstanding and has chosen to proceed. Don't leave missing items unstated, but don't block on them either.

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

Endpoint: `POST https://api.uat.payroc.com/v1/payments`

Required headers:
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <UUID v4>
```

> **Read `references/api-schema.md` before writing the request body.** The values for `channel`, `paymentMethod.type`, the `cardDetails` entry-method discriminator, and every other enum are all defined there. Do not emit any of these from training data — the reference is the contract.

### 2a. Choose the channel

> **Read `references/api-schema.md` for the `channel` enum** before writing this field. Do not guess the value.

Based on intake:
- `pos` — in-store, card physically present
- `web` — online/e-commerce
- `moto` — phone or mail order

### 2b. Build the order object

```json
{
  "orderId": "<your-unique-order-id>",
  "amount": 5000,
  "currency": "USD"
}
```

- `orderId` must be unique per merchant — use your internal order reference.
- `amount` is in the **lowest currency denomination**: `5000` = $50.00 USD / £50.00 GBP.
- `currency` is an ISO 4217 code. Read valid values from `references/api-schema.md`.

If the developer needs itemised amounts (tips, taxes, surcharge), add a `breakdown` object. Read the breakdown schema from `references/api-schema.md` before writing any `tip.type`, `tax.type`, or `healthcareExpenses[].type` enum values.

### 2c. Build the paymentMethod object

> **Read `references/api-schema.md` for `paymentMethod.type` enum values and the `cardDetails` entry-method discriminator** before writing. Do not guess these.

**Card (keyed — for web/MOTO card-not-present):**
```json
{
  "type": "card",
  "cardDetails": {
    "entryMethod": "keyed",
    "cardholderName": "Jane Smith",
    "keyedData": {
      "dataFormat": "plainText",
      "cardNumber": "4111111111111111",
      "expiryDate": "2612",
      "cvv": "123"
    }
  }
}
```

**Secure token (saved card from prior tokenised payment):**
```json
{
  "type": "secureToken",
  "token": "<secure-token-id>"
}
```

**Single-use token (from Hosted Fields):**
```json
{
  "type": "singleUseToken",
  "token": "<single-use-token>"
}
```

**Digital wallet (Apple Pay or Google Pay encrypted payload):**
```json
{
  "type": "digitalWallet",
  "serviceProvider": "apple",
  "token": "<wallet-encrypted-payload>"
}
```

> `serviceProvider` is required for `digitalWallet`. Read valid values from `references/api-schema.md` (`apple` or `google`). The token value is the encrypted payment data returned by the wallet SDK — do not modify it.

For POS card-present flows (`icc`, `swiped`, `contactlessIcc`), the entry-method sub-object contains device-specific fields — read the schema in `references/api-schema.md` for the correct structure.

### 2d. autoCapture and processAsSale

Omit `autoCapture` (or set it to `true`) for a sale — this is the default and means funds are captured immediately on approval. Setting it to `false` creates a pre-authorization — that is a different skill.

For **immediate settlement** (funds moved to the merchant account at once rather than batching at end-of-day), set `processAsSale: true` at the root level. This is an optional field and defaults to `false`. Most integrations do not need it, but it is available if the merchant's account is configured for real-time settlement.

### Minimal sale request

```json
{
  "channel": "web",
  "processingTerminalId": "{{PAYROC_TERMINAL_ID}}",
  "order": {
    "orderId": "ORD-20260622-001",
    "amount": 5000,
    "currency": "USD"
  },
  "paymentMethod": {
    "type": "card",
    "cardDetails": {
      "entryMethod": "keyed",
      "cardholderName": "Jane Smith",
      "keyedData": {
        "dataFormat": "plainText",
        "cardNumber": "4111111111111111",
        "expiryDate": "2612",
        "cvv": "123"
      }
    }
  }
}
```

---

## Step 3 — Send the request

Always generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* failed request, reuse the same key — the API returns the original response instead of creating a duplicate charge. On a genuinely new payment attempt, generate a new UUID.

```bash
curl -X POST https://api.uat.payroc.com/v1/payments \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @payment-payload.json
```

### Checkpoint

Does the API return HTTP 201 with a `paymentId`? If not, work through the error taxonomy.

---

## Step 4 — Handle the response

**201 Created** — payment accepted and sale captured:

```json
{
  "paymentId": "PAY-XXXX",
  "order": {
    "orderId": "ORD-20260622-001",
    "amount": 5000,
    "currency": "USD"
  },
  "transactionStatus": "authorized",
  "paymentMethod": {
    "type": "card",
    "cardDetails": {
      "last4": "1111",
      "cardType": "visa"
    }
  },
  "links": [ ... ]
}
```

**Save `paymentId` immediately.** It is required for refund, reversal, adjustment, and capture. Treat it as an opaque string — do not parse or validate its format. In UAT the ID may be a plain integer; in production the format may differ.

The `transactionStatus` on a successful sale is typically `authorized` (approved by the issuer). Settlement state is tracked separately — query the payment later or use webhooks to detect settlement.

**Important: HTTP 201 does not guarantee approval.** The API returns 201 even when the issuer declines the card. Always check `transactionStatus` in the response body before treating the payment as successful:

| `transactionStatus` | Meaning | Action |
| --- | --- | --- |
| `authorized` | Issuer approved; funds captured | Proceed — payment is complete |
| `declined` | Issuer declined | Show a declined message; do not retry automatically; ask the customer to try a different card |
| `pending` | Authorization pending (rare) | Poll the payment status or wait for a webhook |

Never assume a 201 response means the card was charged — always inspect `transactionStatus`.

---

## Step 5 — Handle errors

Errors follow [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) and include a `type` URL linking to Payroc docs, plus an `errors` array for validation failures.

| Status | Scenario | Action |
| --- | --- | --- |
| 400 validation | Field issues | Fix each field in `errors[].parameter`; resubmit with a fresh idempotency key (the corrected body needs a new key) |
| 400 `idempotencyKeyMissing` | Missing header | Add `Idempotency-Key: <uuid-v4>` to the request |
| 401 | Token expired or invalid | Re-authenticate and get a fresh bearer token |
| 403 | Insufficient permissions | Check API key scope; contact Payroc support |
| 409 `idempotencyKeyInUse` | Key reused with different payload | Generate a new UUID for the new payment attempt |
| 415 | Wrong Content-Type | Set `Content-Type: application/json` |
| 500 | Server error | Retry with exponential backoff; surface `errors` array if present |

**Reading validation errors** — the response uses the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`); Payroc **extends** it with an `errors` array. Each `errors[]` item has:
- `parameter` — the JSON path of the failing field (e.g. `paymentMethod.type`, `order.currency`)
- `detail` — a short reason (distinct from the top-level `detail`)
- `message` — human-readable explanation

Use `parameter` to identify which field failed and fix it before resubmitting. See [`references/error-response-format.md`](references/error-response-format.md) for the envelope shape and the canonical error `type` catalog.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header value is the correct UAT API key |
| 400 — `channel` validation error | Invalid channel value | Read `references/api-schema.md` and use `pos`, `web`, or `moto` exactly |
| 400 — `paymentMethod.type` rejected | Wrong or misspelled type value | Read `references/api-schema.md`; use `card`, `secureToken`, `singleUseToken`, or `digitalWallet` exactly |
| 400 — card entry method rejected | Wrong entry-method key in `cardDetails` | Read `references/api-schema.md` for the valid entry-method discriminator values |
| 400 — `amount` wrong | Passing major units (e.g. 50 instead of 5000) | Convert to minor units (cents/pence): $50.00 = 5000 |
| 400 — missing `orderId` | `order.orderId` not provided | Add a unique `orderId` to the `order` object |
| 400 — `idempotencyKeyMissing` | `Idempotency-Key` header absent | Add `Idempotency-Key: <UUID v4>` header to every POST |
| 409 — duplicate idempotency key | Same UUID reused for a different payment | Generate a fresh UUID for each distinct payment |
| 415 — unsupported media type | `Content-Type` header missing or wrong | Set `Content-Type: application/json` |
| Card declined (transactionStatus reflects decline) | Issuer declined | Show the customer a declined message; do not retry automatically — ask the customer to try a different card |

---

## Common pitfalls

- **Amount in major units**: `amount: 50` for a $50 charge will charge $0.50. Always use minor units (cents/pence).
- **Missing idempotency key**: All POST requests require `Idempotency-Key: <UUID v4>` or you get a 400.
- **Reusing a key for a different payment**: Each unique payment attempt needs its own UUID. Only reuse the same key when retrying the exact same failed request.
- **Wrong enum casing**: Enum values are camelCase — `pos` is correct, `POS` is not. `singleUseToken` is correct, `single_use_token` is not. Read from `references/api-schema.md`, do not guess.
- **Hardcoded card numbers**: Never include raw card numbers in source code. Use test card numbers from the Payroc UAT documentation during development; production code should accept card details through a secure input mechanism.
- **Not saving `paymentId`**: The response `paymentId` is your only reference for refunds, reversals, and adjustments. Persist it immediately.
- **Using production endpoint during testing**: Use `api.uat.payroc.com` for UAT and `identity.uat.payroc.com` for token exchange during development and testing.
- **`expiryDate` format is `YYMM`, not `MMYY`**: The Payroc API takes `YYMM` — year first, then month. December 2026 is `2612`, not `1226`. This is the reverse of the card scheme convention (`MMYY`) and is a common source of silent card rejections or test failures.

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values (`channel`, `paymentMethod.type`, card entry methods, `tip.type`, `tip.mode`, `tax.type`, `healthcareExpenses[].type`, status values)
- Complete nested object schemas (order breakdown, customer, credentials on file)
- Minimal and full request examples

---

## Completion

Once a 201 response with a `paymentId` is received and the developer can verify the transaction in UAT:

> **Integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **Card sale** — [summarise: channel, payment method type, currency/amount].
> - **Response handling** — `paymentId` captured and stored for follow-on operations.
> - **Validated in UAT** — end-to-end flow confirmed.
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Point credentials to the production terminal and API key. Remove any hardcoded test card numbers.

Offer next steps:
- **Refund a payment** — return funds to a customer using the `paymentId`
- **Save a payment method** — tokenise the card for future merchant-initiated charges using `credentialOnFile`
- **3-D Secure** — add cardholder authentication for online payments to reduce fraud
- **Pre-authorization** — hold funds without capturing; capture separately when goods are shipped

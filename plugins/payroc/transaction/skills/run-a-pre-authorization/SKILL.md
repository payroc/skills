---
name: run-a-pre-authorization
description: >
  Guides developers through running a card pre-authorization via the Payroc Payments API
  (POST /v1/payments with autoCapture: false), then capturing or reversing it. Use this skill
  when the user wants to hold funds on a card without immediately capturing, run a pre-auth,
  authorize a card payment for later capture, implement a hotel or car-rental hold pattern,
  build a deferred-capture payment flow, capture a pre-authorized payment, void or reverse a
  pre-authorization, or adjust a pre-authorization amount before capture — even if they don't
  use the word "pre-authorization" explicitly. Also trigger for questions about the difference
  between a sale and a pre-auth, or how to capture a held amount. Do NOT use for immediate
  card sales (autoCapture: true), ACH/bank-transfer payments, refunds on settled transactions,
  3-D Secure authentication, or tokenization — those are separate skills.
metadata:
  version: "0.1.1"
  category: transaction
  status: draft
---

# Run a Pre-Authorization

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/run-a-pre-authorization/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message.
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Pre-Authorization Integration**
> I'll guide you through placing a hold on a customer's card and then capturing or releasing the funds.
>
> **How pre-authorization works:**
> 1. You create a pre-authorization — the card issuer reserves the amount but funds are not settled
> 2. (Optional) You adjust the amount if the final charge differs from the hold
> 3. You capture the pre-authorization when ready to collect funds — or reverse it to release the hold
>
> **Pre-auth vs. sale:**
> - **Sale** — authorizes and captures in one step; funds settle immediately
> - **Pre-authorization** — holds funds only; capture is a separate API call; the hold expires if not captured within the issuer's window (typically 7–30 days)

---

## Quick reference

```text
Create pre-auth:  POST https://api.uat.payroc.com/v1/payments
                  Authorization:   Bearer <token>
                  Idempotency-Key: <uuid-v4>
                  Content-Type:    application/json
                  Body: autoCapture: false, processAsSale: false

Capture:          POST https://api.uat.payroc.com/v1/payments/{paymentId}/capture
                  Authorization:   Bearer <token>
                  Idempotency-Key: <fresh-uuid-v4>
                  Content-Type:    application/json

Reverse/void:     POST https://api.uat.payroc.com/v1/payments/{paymentId}/reverse
                  Authorization:   Bearer <token>
                  Idempotency-Key: <fresh-uuid-v4>
                  Content-Type:    application/json

Adjust:           POST https://api.uat.payroc.com/v1/payments/{paymentId}/adjust
                  Authorization:   Bearer <token>
                  Idempotency-Key: <fresh-uuid-v4>
                  Content-Type:    application/json
```

---

## References

All enum values and schemas live in the local `references/` files — emit from them, not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | All enum values, required fields, request/response schemas, transactionResult enums |
| Error format reference | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| Narrative guide | `references/run-a-pre-authorization-guide.md` | Step-by-step narrative, timing considerations, adjust/capture/reverse flow |
| Identity call reference | `references/identity-call.md` | Bearer token exchange — endpoint URL, header name, response shape |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Read schema before emitting enum values.** Every field that accepts a fixed set of strings — `channel`, `paymentMethod.type`, `cardDetails.entryMethod`, `keyedData.dataFormat`, `transactionResult.status`, `transactionResult.responseCode` — is documented in `references/api-schema.md`. Read it before emitting any value. A plausible-sounding string not in the documented enum will produce a 400 or silent mismatch. Apply the same discipline when reviewing developer code.
2. **Both `autoCapture: false` AND `processAsSale: false` for pre-authorization.** Omitting either flag (or setting `autoCapture: true`) causes the gateway to process the transaction as a sale. These are the only two fields that distinguish a pre-auth from a sale in the create request.
3. **Persist `paymentId` immediately.** The create response's `paymentId` is required for every subsequent operation (capture, adjust, reverse). If it is lost, the pre-authorization cannot be captured programmatically.
4. **Idempotency-Key on every POST.** UUID v4, required. A fresh UUID per distinct operation — do not reuse the create key for the capture. When retrying a failed request, reuse the same key.
5. **Branch on `transactionResult`, not HTTP status alone.** HTTP 201 (create) or 200 (capture) confirms the API accepted the request, not that the authorization or capture succeeded. Read `transactionResult.status` and `transactionResult.responseCode` against the full enums in `references/api-schema.md` before writing success/failure branches. `"approved"` is not a member of `TransactionResultStatus` — a common authorization success is `status: "ready"` with `responseCode: "A"`.
6. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables or a secrets manager.
7. **Validate before advancing.** Confirm each step's checkpoint passes in UAT before moving to the next step.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing payment or order-related code
- HTTP client setup and credential configuration
- Environment variable conventions

Use what you find to pre-fill obvious answers. Then confirm:

1. **What triggers the pre-authorization?** (check-in, order placement, reservation?)
2. **What triggers the capture?** (checkout, shipment, service completion?)
3. **How is the final amount determined?** Fixed at auth time, or does it vary before capture?
4. **Payment method type:** card present (POS device), keyed (MOTO/card-not-present), stored token, or digital wallet?
5. **Should the integration also handle reversal** (e.g. cancellation path)?

---

## Prerequisites

These are needed to run and test the integration in UAT. If the developer already has them, great. If not, wire the code to read each value from an environment variable and keep building.

1. **API key** — used to generate Bearer tokens. Provisioned by the Payroc Integrations team.
2. **Processing terminal ID** — the `processingTerminalId` used in the create request body.
3. **Pre-authorization enabled** on the terminal. If not enabled, create requests process as sales. The Payroc Integrations team enables this feature.

**If anything is missing — warn, don't block.** Match the existing env-var convention in the codebase; otherwise propose `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID`. Tell the developer plainly:

> ⚠️ I've wired this to read credentials from `<VAR names>`. Pre-authorization also requires the feature to be enabled on your terminal — confirm this with the Payroc Integrations team before testing.

### Checkpoint

Either the credentials and terminal capability are confirmed, or the developer knows what's outstanding and how to obtain it — and has chosen to proceed.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). Use `Authorization: Bearer <access_token>` on all subsequent API requests.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic — tokens that expire mid-session will produce 401s on otherwise valid requests.

Store the API key in an environment variable. Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, verify the `x-api-key` header value and confirm the API key is for the UAT environment.

---

## Step 2 — Create the pre-authorization

Endpoint: `POST https://api.uat.payroc.com/v1/payments`

> **Read `references/api-schema.md` before writing the request body.** The values for `channel`, `paymentMethod.type`, `cardDetails.entryMethod`, `keyedData.dataFormat`, and all device model enums are defined there. Do not emit any of these from training data or memory.

**The two flags that make this a pre-authorization (not a sale):**

```json
"autoCapture": false,
"processAsSale": false
```

Both must be present and set to `false`. If `autoCapture` is `true` (the default), the gateway captures immediately and settles as a sale.

**Required request body fields:**

```jsonc
{
  "channel": "<pos|web|moto>",          // read enum from references/api-schema.md
  "processingTerminalId": "<terminal-id>",
  "autoCapture": false,
  "processAsSale": false,
  "order": {
    "orderId": "<merchant-assigned order ID>",
    "amount": <integer in lowest denomination>,
    "currency": "<ISO 4217 code, e.g. USD>"
  },
  "paymentMethod": {
    "type": "<card|secureToken|singleUseToken|digitalWallet>",
    // ... card/token details — see references/api-schema.md for each variant
  }
}
```

> **Confirm all required fields from `references/api-schema.md`.** Don't rely on a remembered list — read the `paymentRequest` schema and check which fields are required and which are conditional on `paymentMethod.type` and `cardDetails.entryMethod`. Read the `channel` enum values before writing them.

**Payment method selection (based on intake answers):**

- **Card present (POS)** — `paymentMethod.type: "card"` with `cardDetails.entryMethod: "icc"` or `"swiped"`. Requires device object with model and serialNumber. Read DeviceModel enum from `references/api-schema.md` — do not guess model identifiers.
- **Keyed / card-not-present (MOTO)** — `paymentMethod.type: "card"` with `cardDetails.entryMethod: "keyed"`, `keyedData.dataFormat: "plainText"` (for plain text card data). Read the `keyedData` schema from `references/api-schema.md`.
- **Stored token** — `paymentMethod.type: "secureToken"`, `token: "<secure-token-id>"`.
- **Digital wallet** — `paymentMethod.type: "digitalWallet"`, `serviceProvider: "<apple|google>"`. Read serviceProvider enum from `references/api-schema.md`.

**Amounts are in lowest denomination.** `amount: 10000` is $100.00 USD (or £100.00 GBP, €100.00 EUR, etc.). Never pass a decimal.

**Generate a fresh UUID v4 for `Idempotency-Key`.** On retry of the same failed request, reuse the same key. On a genuinely new submission, generate a new UUID.

### Checkpoint

Does the API return HTTP 201 with a `paymentId` in the response? If not, work through the error taxonomy below.

After HTTP 201, read `transactionResult.status` and `transactionResult.responseCode` to confirm the authorization was approved:
- Read both enums from `references/api-schema.md` before writing the success branch.
- A common approval: `status: "ready"`, `responseCode: "A"`.
- `"approved"` is NOT a member of `TransactionResultStatus` — branching on it will silently fail real approvals.

**Persist `paymentId` immediately to durable storage.** Session or in-memory state may not survive the time between authorization and capture.

---

## Step 3 (optional) — Adjust the pre-authorization

*(Include this step if the final amount may differ from the authorized amount)*

Endpoint: `POST https://api.uat.payroc.com/v1/payments/{paymentId}/adjust`

Required headers: `Authorization: Bearer <token>`, `Idempotency-Key: <fresh-uuid-v4>`, `Content-Type: application/json`

Use this when the final charge amount is different from the held amount — for example, a hotel adding room-service charges before checkout.

- Amount adjustments are subject to card scheme rules and issuer limits.
- A payment cannot be adjusted after it has been captured or reversed.

### Checkpoint

Does the adjust call return HTTP 200? If not, check whether the payment has already been captured or reversed.

---

## Step 4a — Capture the pre-authorization

Endpoint: `POST https://api.uat.payroc.com/v1/payments/{paymentId}/capture`

Required headers: `Authorization: Bearer <token>`, `Idempotency-Key: <fresh-uuid-v4>`, `Content-Type: application/json`

**Full capture** — omit the request body (or send `{}`) to capture the full pre-authorized amount.

**Partial capture** — include the amount in lowest denomination:

```json
{ "paymentCapture": { "amount": 8000 } }
```

> To capture MORE than the original pre-authorized amount, call the Adjust endpoint (Step 3) first, then capture.

A successful capture returns **HTTP 200** with a `payment` object.

> **Read `transactionResult.status` and `transactionResult.responseCode` from `references/api-schema.md` before writing the capture-response handler.** HTTP 200 confirms the API accepted the request — it does NOT confirm the capture succeeded. A common capture-success state is `status: "ready"` with `responseCode: "A"`. Branch on the full enum set, not a guessed subset.

### Checkpoint

Does the capture call return HTTP 200? Does `transactionResult.responseCode` equal `"A"` (or another approval code)? If not, work through the error taxonomy.

---

## Step 4b (alternative) — Reverse the pre-authorization

*(Implement instead of Step 4a when the merchant wants to release the hold without charging)*

Endpoint: `POST https://api.uat.payroc.com/v1/payments/{paymentId}/reverse`

Required headers: `Authorization: Bearer <token>`, `Idempotency-Key: <fresh-uuid-v4>`, `Content-Type: application/json`

A reversal releases the hold on the customer's card. Once reversed, the payment cannot be captured.

**Before writing reversal code,** confirm with the developer that they understand this is permanent — a reversed pre-authorization cannot be recaptured. If the intent is to reduce the amount rather than cancel entirely, the developer should adjust and then capture instead.

### Checkpoint

Does the reverse call return HTTP 200? If not, check whether the payment was already captured.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header value is the correct UAT API key |
| 400 — `idempotencyKeyMissing` | `Idempotency-Key` header absent | Add `Idempotency-Key: <uuid-v4>` to every POST |
| 400 — validation error mentioning `channel`, `entryMethod`, or `type` | Enum value not from the reference | Read `references/api-schema.md` and use the documented value |
| 400 — validation error on `amount` | Amount passed as decimal (e.g. `100.00`) | Use integer lowest denomination (e.g. `10000` for $100.00) |
| 409 — duplicate `Idempotency-Key` | Same key reused across different operations | Generate a fresh UUID for every distinct operation |
| 404 on capture/adjust/reverse | `paymentId` wrong or not found | Verify the ID from the create response; check the payment exists |
| Pre-auth processes as a sale | `autoCapture: true` or feature not enabled on terminal | Set `autoCapture: false` and `processAsSale: false`; confirm terminal has pre-auth enabled |
| Capture greater than authorized amount | Capturing more than the hold without adjusting first | Call the Adjust endpoint to increase the authorized amount, then capture |
| Capture fails — payment already captured | Duplicate capture attempt | The payment was already captured; retrieve the payment to confirm status |
| Capture fails — payment reversed | Reverse was called before capture | Cannot capture a reversed payment; create a new pre-auth if needed |
| `transactionResult.responseCode: "D"` | Processor declined | Decline is final; create a new payment with the customer's corrected card details |
| `transactionResult.responseCode: "P"` | Partial approval | Only part of the requested amount was authorized; check `transactionResult.authorizedAmount` and handle the shortfall |
| Hold released before capture | Issuer's hold period elapsed without a capture | Card scheme hold windows are typically 7–30 days; implement capture promptly and monitor hold expiry. For long-duration holds (e.g. multi-week car rentals), consider: (a) capturing a deposit upfront and refunding the unused portion, (b) re-authorizing periodically before the hold expires, or (c) contacting the Payroc Integrations team to discuss options for your use case. The Payroc API does NOT send a notification when a pre-authorization expires — tracking hold expiry is the developer's responsibility. |

**Reading validation errors** — error responses use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`); Payroc **extends** it with an `errors` array (Payroc's own extension, not defined by RFC 7807). Each `errors[]` item has `parameter` (the JSON path of the failing field), `detail` (short reason), and `message` (human-readable explanation). Use `parameter` to map each error back to the request body field that failed.

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] `Idempotency-Key` header present and set to a UUID v4 on every POST
- [ ] `autoCapture: false` AND `processAsSale: false` set in the create request
- [ ] `channel`, `paymentMethod.type`, `entryMethod`, `dataFormat`, and DeviceModel values read from `references/api-schema.md` — not from training data
- [ ] `paymentId` persisted to durable storage immediately after create response
- [ ] `transactionResult.status` and `transactionResult.responseCode` enums read from `references/api-schema.md` before writing success/failure branches
- [ ] Capture: fresh `Idempotency-Key` (not reusing the create key)
- [ ] Amounts in integer lowest denomination (not decimals)
- [ ] UAT endpoints used (`api.uat.payroc.com`) — not production endpoints during testing
- [ ] Reversal: developer confirmed they understand the operation is irreversible

---

## Completion

Once all checklist items pass:

> **Pre-authorization integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **Create pre-authorization** — `autoCapture: false`, `processAsSale: false`; `paymentId` persisted for downstream operations.
> - **Capture** (if built) — full or partial capture from the `paymentId`.
> - **Adjust** (if built) — amount adjustment before capture.
> - **Reverse/void** (if built) — hold released without charging.
> - **Validated in UAT** — end-to-end flow confirmed.
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Point credentials to the production terminal and API key.

Offer next steps:
- **Tokenization / recurring billing** — save the customer's payment method as a secure token for future merchant-initiated charges
- **Refunds** — issue a referenced refund after a captured payment settles
- **Webhooks** — receive payment status notifications server-side instead of polling

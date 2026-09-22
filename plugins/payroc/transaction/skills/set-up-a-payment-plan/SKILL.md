---
name: set-up-a-payment-plan
description: >
  Guides developers through creating and configuring recurring / repeat payments with Payroc —
  building a payment plan template and enrolling customers by creating new subscriptions. Use
  this skill when the user wants to implement recurring billing, repeat payments, subscription
  billing, scheduled payments, installment plans, automatic recurring charges, or payment
  schedules with Payroc. Also use when the developer asks about creating payment plans,
  enrolling customers in subscriptions, the
  /v1/processing-terminals/{id}/payment-plans or /v1/processing-terminals/{id}/subscriptions
  endpoints, or how to charge a customer repeatedly on a defined schedule — even if they don't
  use the word "skill" or "repeat payments" explicitly. Do NOT use for: saving or tokenizing
  a payment method (use save-a-payment-method), managing or updating existing subscriptions
  (use manage-subscriptions), or one-time card or ACH payments.
metadata:
  version: "0.1.3"
  category: transaction
  status: draft
---

# Set Up a Payment Plan

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/set-up-a-payment-plan/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Repeat Payments Integration**
> I'll guide you through setting up recurring payment collection with Payroc — creating a payment plan template, enrolling customers via subscriptions, and configuring how the gateway collects payments.
>
> **How Repeat Payments works:**
> 1. You create a **payment plan** — a template defining frequency, currency, and (for automatic plans) amount
> 2. You obtain a **secure token** for each customer (from the Tokenization API) representing their saved payment method
> 3. You create a **subscription** — linking the customer's secure token to the payment plan with a start date
> 4. Payments are collected automatically by the gateway (automatic plans) or triggered by you (manual plans)
>
> **Two plan types:**
> - **`automatic`** — the Payroc gateway charges the customer at each billing interval; `recurringOrder` with an amount is required
> - **`manual`** — your system initiates each payment by calling the "Pay manual subscription" endpoint; the gateway does not charge automatically

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
# Payment Plans
POST   https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans
GET    https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans
GET    https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}
PATCH  https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}
DELETE https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}

# Subscriptions
POST   https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions
GET    https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions
GET    https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}
PATCH  https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}
POST   https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/deactivate
POST   https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/reactivate
POST   https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/pay

Required headers (POST / PATCH, except /deactivate and /reactivate):
  Authorization:   Bearer <token>
  Idempotency-Key: <uuid-v4>
  Content-Type:    application/json

Required header (/deactivate, /reactivate, GET, DELETE — no Idempotency-Key):
  Authorization:   Bearer <token>
```

---

## References

All enum values and schemas live in the local `references/` files — this skill emits from them, not from live lookups and not from memory.

| Source | Local file | Use for |
|--------|-----------|---------|
| API schema reference | `references/api-schema.md` | **All** enum values, required fields, request/response schemas for payment plans and subscriptions |
| Error format reference | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| Narrative guide | `references/repeat-payments-guide.md` | Conceptual overview — manual vs automatic, deactivate vs delete, surcharging, inheritance |
| Identity call reference | `references/identity-call.md` | Bearer token endpoint URL, request headers, response fields |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are recorded in [`references/_sources.md`](references/_sources.md).

---

## Core Principles

1. **Inspect before asking** — scan the codebase before asking anything; use what you find to skip obvious questions.
2. **Ask before coding** — gather unknowns through intake before writing implementation code.
3. **Read the schema reference before emitting any enum value.** Every field that accepts a fixed set of strings — `type`, `frequency`, `onUpdate`, `onDelete`, `paymentMethod.type`, `paymentMethod.accountType`, `paymentMethod.secCode`, `currentState.status` — is documented in `references/api-schema.md`. Read it before you emit the value. Do not use training-data guesses. A plausible-sounding string that is not in the documented enum produces a 400 or silent mismatch. The same rule applies when **reviewing** developer-supplied code: consult `references/api-schema.md` before issuing a verdict — never validate from memory.
4. **Idempotency-Key on every POST and PATCH except `/deactivate` and `/reactivate`.** The value must be a UUID v4. Omitting it causes a 400. Generate a fresh UUID for each distinct operation; do not reuse the same key across different requests. The subscription `/deactivate` and `/reactivate` POSTs do not take the header — sending it there is harmless, but omitting it does not cause a 400.
5. **Never hardcode credentials.** API keys, terminal IDs, and secure tokens must come from environment variables or a secrets manager.
6. **Bearer token expiry.** Tokens expire after 3,600 seconds (1 hour). For long-running services, implement token refresh logic.
7. **Validate before advancing** — don't move to the next step until the current step's checkpoint passes in UAT.
8. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing billing, subscription, or recurring-payment-related code
- Any existing HTTP client setup or credential configuration
- How environment variables are managed

Use what you find to pre-fill obvious answers, then ask:

**What does your integration need? Ask the developer to select all that apply:**

- **[Always included]** Create a payment plan template
- **[Always included]** Create subscriptions (enrol customers)
- Retrieve a specific plan or subscription
- List plans or subscriptions
- Update a plan or subscription
- Deactivate or reactivate a subscription
- Manually trigger payment collection (for `manual`-type plans)
- Delete a payment plan

Also confirm:
- **Plan type:** `automatic` (gateway collects payments on schedule) or `manual` (your system triggers each payment)?
- **Frequency:** weekly, fortnightly, monthly, quarterly, or yearly?
- **Fixed or open-ended?** Set a `length` (number of billing cycles) or leave it as `0` (indefinite)?
- **Setup fee?** Is there an initial charge in addition to the recurring amount?
- **Payment method:** card (most common) or bank account / ACH?

Use the answers to skip sections that don't apply. If the use case is ambiguous, ask one targeted clarifying question before proceeding.

---

## Prerequisites

These are needed to **run and test** the integration in UAT — not to write the code. If the developer already has them, great. If not, keep building and tell them to populate credentials before testing.

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by the Payroc Integrations team along with UAT access.
2. **Processing terminal ID** — the `processingTerminalId` used in all endpoint paths. The developer should know this from their UAT setup.
3. **Secure token** — for each subscription, you need a `secureTokenId` representing the customer's saved payment method. This is obtained by first calling the Tokenization API (the `save-a-payment-method` skill). **A subscription cannot be created without a valid secure token** — if the developer does not yet have one, point them to the save-a-payment-method skill before proceeding to subscription creation.
4. **UAT environment** — Payroc's test environment. UAT terminals are provisioned by the Payroc Integrations team; there is no self-serve signup.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it; otherwise propose `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID`. Write the code to read credentials from environment variables, then tell the developer plainly:

> ⚠️ I've wired this to read your API key and terminal ID from `<VAR names>`. You'll need a Payroc UAT terminal and API key to actually run or test this — contact the Payroc Integrations team to get them. I can keep building in the meantime.

### Checkpoint

Either the credentials are confirmed, or the developer knows what's outstanding and has chosen to proceed.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). All subsequent API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic — tokens that expire mid-operation produce 401s on otherwise valid requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the UAT environment.

---

## Step 2 — Create a payment plan

Endpoint: `POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans`

Required headers:
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <UUID v4>
```

> **Read `references/api-schema.md` before writing the request body.** The values for `type`, `frequency`, `onUpdate`, and `onDelete` are all enum fields defined there. Do not emit any of these from training data — the reference is the contract.

### Key decisions to implement

**`paymentPlanId` is merchant-assigned** — you choose this value. It must be unique per terminal. Do not assume the API generates it.

**`type`** — read the enum values from `references/api-schema.md`:
- `automatic` — gateway collects payments automatically; **`recurringOrder` with an `amount` is required**
- `manual` — your system calls the "Pay manual subscription" endpoint per billing cycle; `recurringOrder` is optional

**`frequency`** — read the valid values from `references/api-schema.md` before writing. Do not guess; a single wrong character causes a 400.

**`length`** — number of billing cycles. Set to `0` for an indefinite (open-ended) plan.

**`onUpdate` / `onDelete`** — read enum values from `references/api-schema.md`. These control how changes and deletion cascade to linked subscriptions.

**Amounts are in the currency's lowest denomination** — `amount: 4999` means $49.99 USD or £49.99 GBP (not $4,999).

Minimal example for a monthly automatic plan:
```json
{
  "paymentPlanId": "PLAN-MONTHLY-001",
  "name": "Monthly Premium",
  "currency": "USD",
  "type": "automatic",
  "frequency": "monthly",
  "onUpdate": "continue",
  "onDelete": "complete",
  "length": 0,
  "recurringOrder": {
    "amount": 4999,
    "description": "Monthly subscription fee"
  }
}
```

Capture the `paymentPlanId` from the response — it's required for creating subscriptions.

### Checkpoint

Does the API return HTTP 201 with the plan's details including `processingTerminalId`? If not, work through the error taxonomy.

---

## Step 3 — Obtain a secure token (prerequisite for subscriptions)

Before creating a subscription, you need a **secure token** representing the customer's payment details. This is a `secureTokenId` obtained from the Payroc Tokenization API.

If the developer already has a secure token workflow, ask for the `secureTokenId` value and proceed.

If not: point them to the **`save-a-payment-method`** skill, which covers the full tokenization process. They must complete that flow first — a subscription cannot be created without a valid secure token. The token must be validated (status `cardNumberValidated` or `bankAccountValidated`) before use.

> Do not skip this step. Creating a subscription without a valid `secureTokenId` will return a 400 or 422 error.

### Checkpoint

Does the developer have a `secureTokenId` from the Tokenization API? If yes, proceed to Step 4. If no, redirect to the `save-a-payment-method` skill first.

---

## Step 4 — Create a subscription

Endpoint: `POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions`

Required headers:
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <UUID v4>      ← generate a new UUID; do not reuse Step 2's key
```

> **Read `references/api-schema.md` before writing the request body.** The `paymentMethod.type` discriminator value, `paymentMethod.accountType`, and `paymentMethod.secCode` enum values are all defined there. Do not emit any of these from training data.

### Key decisions

**`subscriptionId` is merchant-assigned** — you choose this value. It must be unique per terminal.

**`paymentMethod.type`** — always `"secureToken"`. Read this value from `references/api-schema.md` and emit it verbatim.

**`paymentMethod.accountType`** — only required for bank account (ACH) tokens. Read valid values (`checking`, `savings`) from `references/api-schema.md`.

**`paymentMethod.secCode`** — only required for ACH bank accounts. Read valid values (`web`, `tel`, `ccd`, `ppd`) from `references/api-schema.md` before emitting.

**`startDate`** — `YYYY-MM-DD` format. This is when the subscription starts; the first payment (or first manual collection) is due on or after this date.

**Inherited fields** — the subscription inherits `type`, `frequency`, `currency`, and `length` from the payment plan. You can override `name`, `description`, `setupOrder`, `recurringOrder`, `endDate`, `length`, and `pauseCollectionFor` at the subscription level.

**`pauseCollectionFor`** — optional integer. Skips the first N billing cycles (e.g. a free trial), without modifying the underlying plan.

Minimal card subscription example:
```json
{
  "subscriptionId": "SUB-CUST-001",
  "paymentPlanId": "PLAN-MONTHLY-001",
  "startDate": "2026-07-01",
  "paymentMethod": {
    "type": "secureToken",
    "token": "<secureTokenId>"
  }
}
```

The response (HTTP 201) includes:
- `currentState.status` — should be `"active"` immediately
- `currentState.nextDueDate` — the date of the first payment
- `currentState.paidInvoices` — will be `0` on creation
- `paymentPlan` — summary link to the plan
- `secureToken` — summary of the tokenized payment method

### Checkpoint

Does the API return HTTP 201 with `currentState.status: "active"` and a `nextDueDate`? If not, work through the error taxonomy.

---

## Step 5 — Collect payments

### Automatic plans

For `automatic`-type plans, the gateway handles payment collection at each billing interval. No further action is needed — the gateway will charge the customer's saved payment method on each `nextDueDate`.

Monitor subscription state by polling `GET /v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}` or by setting up webhook notifications.

### Manual plans

For `manual`-type plans, your system must trigger each payment:

Endpoint: `POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/pay`

Required headers:
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <UUID v4>
```

Request body:
```json
{
  "order": {
    "amount": 4999
  }
}
```

The response (HTTP 201) includes `payment.status`, `payment.paymentId`, and the updated `currentState`.

### Checkpoint (manual plans)

Does the payment response return HTTP 201 with a `payment.paymentId`? Check `payment.status` — a non-`complete` status indicates the payment was declined or pending.

---

## Step 6 — Manage the subscription lifecycle

*(Implement only the sub-sections the developer selected during intake)*

### Retrieve a subscription

`GET https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}`

Headers: `Authorization: Bearer <token>`

Returns the full subscription object. Check `currentState.status` to see if the subscription is `active`, `completed`, `suspended`, or `cancelled`.

---

### List subscriptions

`GET https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions`

Headers: `Authorization: Bearer <token>`

Query parameters: `paymentPlanId` (filter by plan), `limit` (max results, default 10), `after`/`before` (cursor-based pagination). Pagination via `hasMore` in the response.

---

### Deactivate a subscription

`POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/deactivate`

Required headers:
```
Authorization:   Bearer <token>
```

No request body, and **no `Idempotency-Key`** — this endpoint does not take the header.

**Before writing deactivation code:** confirm the developer understands the effect. Deactivating:
- Sets the subscription's `currentState.status` to `"cancelled"`
- Stops payment collection immediately
- Is **reversible** — the subscription can be reactivated using the reactivate endpoint

If the developer only wants to pause temporarily, `pauseCollectionFor` (on subscription creation) or a PATCH to set an `endDate` may be more appropriate. Confirm intent before writing deactivation code.

---

### Reactivate a subscription

`POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/reactivate`

Required headers:
```
Authorization:   Bearer <token>
```

No request body, and **no `Idempotency-Key`** — this endpoint does not take the header.

Reactivation resumes a previously deactivated subscription. The `currentState.status` returns to `"active"` and payment collection resumes.

---

### Delete a payment plan

`DELETE https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}`

Headers: `Authorization: Bearer <token>` (no body required)

**Before writing deletion code:** confirm with the developer that they understand:
- Deletion is **permanent and irreversible** — the plan cannot be recovered
- New subscriptions cannot be added to the plan after deletion
- Behaviour for existing subscriptions depends on the plan's `onDelete` setting:
  - `"complete"` — gateway stops collecting payments for all linked subscriptions
  - `"continue"` — subscriptions keep running; they must be deactivated manually

Successful deletion returns HTTP 204 with an empty body.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| 401 on any request | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header uses the correct UAT API key |
| 400 — validation error mentioning `type`, `frequency`, `onUpdate`, `onDelete` | Enum value not from the reference | Read `references/api-schema.md` and use the documented value |
| 400 — validation error mentioning `paymentMethod.type` | Wrong discriminator value | The only valid value is `"secureToken"` — read `references/api-schema.md` |
| 400 — `idempotencyKeyMissing` | Idempotency-Key header absent on a POST or PATCH | Add `Idempotency-Key: <UUID v4>` to every POST and PATCH — except the body-less `/deactivate` and `/reactivate` POSTs, which do not take it and never raise this error |
| 400 — `recurringOrder` missing or empty | Automatic plan with no recurring amount | Send `recurringOrder.amount` when `type` is `"automatic"` |
| 400 — `paymentPlanId` not found when creating subscription | Referenced plan doesn't exist yet | Create the plan first, then create the subscription |
| 400 — secure token invalid | Token not yet validated or wrong format | Ensure the `secureTokenId` from the Tokenization API is valid (`cardNumberValidated` or `bankAccountValidated`) |
| 400 — amounts in wrong unit | Amount sent as major currency unit (e.g. 49.99) | All amounts are integers in the lowest denomination (e.g. `4999` for $49.99) |
| 409 — `paymentPlanId` or `subscriptionId` already exists | Merchant-assigned ID not unique | Choose a unique ID value per terminal |
| 409 — duplicate Idempotency-Key | Same key used across different operations | Generate a fresh UUID v4 for each distinct request |
| 404 — plan or subscription not found | Wrong ID, wrong terminal, or resource deleted | Verify the IDs and confirm `processingTerminalId` matches |
| 403 | Insufficient permissions | Check API key scope; contact Payroc Integrations |
| 500 | Server error | Retry with exponential backoff; if persistent, contact Payroc support |

**Reading validation errors** — the response uses the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`); Payroc **extends** it with an `errors` array. Each `errors[]` item has a `parameter` (the JSON path of the failing field), a `detail` (short reason), and a `message` (human-readable explanation). Use `parameter` to identify which field to fix.

---

## Common pitfalls

- **`paymentPlanId` and `subscriptionId` are merchant-assigned** — the API does not auto-generate these. You must choose unique values per terminal before calling the create endpoints.
- **No subscription without a valid secure token** — the `paymentMethod.token` must be an existing, validated `secureTokenId` from the Tokenization API. Creating subscriptions without this step will fail.
- **`recurringOrder` required for automatic plans** — if `type` is `"automatic"` and `recurringOrder` is absent or missing `amount`, the request returns 400.
- **Amounts in lowest denomination** — `amount: 100` means 100 cents ($1.00), not $100. Always multiply by 100 for USD/GBP/EUR.
- **`paymentMethod.type` must be exactly `"secureToken"`** — read this from `references/api-schema.md`. Any variation causes a 400.
- **Fresh Idempotency-Key per operation** — do not reuse the plan creation key for subscription creation or payment collection.
- **Deactivate (reversible) vs. Delete (irreversible)** — deactivating a subscription can be undone; deleting a payment plan cannot. Confirm intent before writing delete code.

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] `Idempotency-Key` header present and set to a UUID v4 on every POST and PATCH except `/deactivate` and `/reactivate`
- [ ] `type`, `frequency`, `onUpdate`, `onDelete`, and `paymentMethod.type` values read from `references/api-schema.md` — not from training data
- [ ] `paymentPlanId` is a unique, merchant-chosen string
- [ ] `subscriptionId` is a unique, merchant-chosen string
- [ ] `recurringOrder.amount` present when `type` is `"automatic"`
- [ ] Secure token obtained from Tokenization API before subscription creation
- [ ] All amounts are integers in the lowest currency denomination
- [ ] Dates use `YYYY-MM-DD` format (`startDate`, `endDate`)
- [ ] UAT endpoints used (`api.uat.payroc.com`) — not production endpoints during testing
- [ ] Deletion: developer explicitly confirmed the plan deletion is permanent before code was written

---

## Completion

Once all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **Payment plan** — [summarise: type, frequency, currency, length]
> - **Subscriptions** — [summarise: how customers are enrolled, payment method type, start date logic]
> - **Payment collection** — [automatic: gateway manages | manual: your system triggers via /pay endpoint]
> - **Lifecycle management** (list what was built) — retrieve, list, deactivate, reactivate, delete.
> - **Validated in UAT** — end-to-end flow confirmed.
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Point credentials to the production terminal and API key.

Offer next steps:
- **Webhook notifications** — receive server-side subscription events rather than polling
- **Manage subscriptions** — the `manage-subscriptions` skill covers advanced subscription lifecycle operations in depth
- **Reporting** — view payment history via the Authorizations reporting API

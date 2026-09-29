---
name: manage-subscriptions
description: >
  Guides developers through managing an existing Payroc repeat-payments subscription or payment
  plan after initial setup. Use this skill when the user wants to update or modify an existing
  subscription, cancel or deactivate a Payroc subscription, reactivate a cancelled subscription,
  manually trigger a payment on a subscription, change a subscription's amount or end date, pause
  or adjust collection cycles, list or retrieve subscriptions or payment plan details, or use the
  /v1/processing-terminals/{id}/payment-plans/{id} (PATCH/DELETE) or
  /v1/processing-terminals/{id}/subscriptions endpoints (including the deactivate, reactivate, and
  pay sub-endpoints) — even if they don't use the word "subscription" explicitly. Do NOT use for:
  creating a brand-new payment plan or enrolling a customer in a plan for the first time (use
  set-up-a-payment-plan instead), one-time card sales or refunds, saving or tokenizing a payment
  method, event webhook subscriptions, or payment links.
metadata:
  version: "0.4.3"
  category: transaction
  status: draft
---

# Manage Subscriptions (Repeat Payments)

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/manage-subscriptions/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message.
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

Payroc repeat payments let you charge customers on a recurring schedule — weekly gym fees,
monthly SaaS subscriptions, installment plans, and more. The system has two layers:

- **Payment plans** — reusable templates defining frequency, amount, and collection method.
- **Subscriptions** — link an individual customer (via a stored secure token) to a plan.

For the complete field reference and all enum values, read `references/api-schema.md`. For the
workflow narrative, read `references/repeat-payments-guide.md`.

---

## Quick reference

```text
# Payment plans
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

Standard headers (POST / PATCH):
  Authorization:   Bearer <token>
  Idempotency-Key: <uuid-v4>
  Content-Type:    application/json
```

---

## References

All enum values, required field sets, and response schemas live in the local `references/` files
below. This skill emits from those references, not from memory.

| File | Use for |
| --- | --- |
| `references/identity-call.md` | Bearer token exchange — endpoint URL, request header, response shape |
| `references/api-schema.md` | All endpoints, enum values (`type`, `frequency`, `onUpdate`, `onDelete`, `status`), request/response schemas for plans and subscriptions |
| `references/repeat-payments-guide.md` | Workflow narrative — how plans, tokens, and subscriptions fit together |
| `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots. Source URLs and last-synced dates are in
[`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Read the schema reference before emitting any enum value.** Every field that accepts a fixed
   set of strings — `type`, `frequency`, `onUpdate`, `onDelete`, `status`, `secCode`,
   `accountType`, `op` — is documented in `references/api-schema.md`. Read it before emitting.
   Do not guess from training data. A plausible-sounding enum that isn't in the spec produces a
   400 or silent mismatch. **Reviewing developer code is subject to the same rule: read
   `references/api-schema.md` before issuing any verdict on whether enum values or field names
   are correct. Do not pass or fail code without consulting the reference first.**
2. **Idempotency-Key on every POST and PATCH.** UUID v4 format. Required on create-plan, update-plan,
   create-subscription, update-subscription, pay-subscription. **Not** required on DELETE or on the
   deactivate/reactivate endpoints.
3. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables,
   never from source code or config files in version control.
4. **Amounts are in the lowest currency denomination.** $50.00 USD = `5000`; £10.00 GBP = `1000`.
5. **Merchant-assigned IDs.** Both `paymentPlanId` and `subscriptionId` are assigned by the
   merchant, not by Payroc. Choose meaningful, unique values.
6. **Validate before advancing.** Don't move to the next step until the current step's checkpoint
   passes in UAT.

---

## Intake

**First, scan the codebase** for:
- Server-side language and framework
- Existing payment or billing code
- HTTP client setup and credential management
- Environment variable conventions

Use what you find to pre-fill obvious answers, then ask:

1. **What type of repeat payment?**
   - Fixed-term installments (defined number of payments) — `length > 0`
   - Indefinite recurring (no end date) — `length: 0`
2. **Collection method?**
   - Automatic (gateway collects on schedule) — `type: automatic`
   - Manual (merchant triggers each payment) — `type: manual`
3. **Frequency?** (weekly / fortnightly / monthly / quarterly / yearly)
4. **Does a payment plan already exist?** If yes, skip the create-plan step.
5. **Is the customer's payment method already tokenized?** If yes, you have a secure token already;
   if no, direct them to the `save-a-payment-method` skill first.
6. **Lifecycle operations needed?** Update, deactivate, reactivate, or manual pay?

---

## Prerequisites

These are needed to run and test in UAT — not to write code. Wire the code to read them from
environment variables and keep building even if they aren't available yet.

| Item | Notes |
| --- | --- |
| API key | Exchanged for a Bearer token. Set as `PAYROC_API_KEY`. |
| Processing terminal ID | Required in every endpoint path. Set as `PAYROC_TERMINAL_ID`. |
| Secure token | The customer's stored payment method token. Obtain it via the Secure Tokens API first. |

If any item is missing, warn and continue:
> ⚠️ I've wired this to read your credentials from environment variables. You'll need a Payroc UAT
> terminal and API key to test — contact the Payroc Integrations team to get them.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Exchange your API key for a Bearer token using the Payroc Identity Service. Tokens expire after
3600 seconds (1 hour) — exchange once per session, not once per request.

```bash
# UAT / test
curl -X POST https://identity.uat.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"

# Production
curl -X POST https://identity.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"
```

Response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). Use
`Authorization: Bearer <access_token>` on every subsequent request.

### Checkpoint
Can the auth helper produce a Bearer token without error? If not, verify the `x-api-key` header
and confirm the API key is correct for the UAT environment.

---

## Step 2 — Create a payment plan

> **Before writing any code for this step:** Read `references/api-schema.md` in full. Enum values
> for `type`, `frequency`, `onUpdate`, and `onDelete` must come from that file — not from memory
> and not from the inline example below. The inline example uses placeholder comments; the
> reference file is authoritative. Read it first, then return here.

`POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans`

```
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

The `paymentPlanId` is **merchant-assigned** — choose a meaningful, unique string (e.g.
`"MONTHLY-GYM-BASIC"`). The API does not generate this value.

Minimal required body (fill enum values from `references/api-schema.md`):

```jsonc
{
  "paymentPlanId": "MONTHLY-GYM-BASIC",
  "name": "Basic Gym Membership",
  "currency": "USD",
  "type": "<read paymentPlan.type from references/api-schema.md>",
  "frequency": "<read paymentPlan.frequency from references/api-schema.md>",
  "onUpdate": "<read paymentPlan.onUpdate from references/api-schema.md>",
  "onDelete": "<read paymentPlan.onDelete from references/api-schema.md>"
  // recurringOrder: { amount: <integer cents> }
  //   ↑ Required in the *plan body* when type is "automatic". Omit from the
  //     plan body for type "manual" (no pre-defined amount at plan level).
  //     Note: individual subscriptions may still override the per-cycle amount
  //     via recurringOrder even under manual plans — see Step 3 overrides.
}
```

Optional: `description`, `length` (0 = indefinite), `setupOrder` (one-time setup fee),
`customFieldNames`.

**onUpdate / onDelete — decide before creating:**
- `onUpdate: "update"` — plan changes propagate to all linked subscriptions automatically.
  Use when all subscribers should always be on the same terms.
- `onUpdate: "continue"` — existing subscriptions retain original values; only new subscriptions
  use updated values. Use when you honour grandfathered pricing.
- `onDelete: "complete"` — deleting the plan transitions all linked subscriptions to `completed`
  status (their natural end state — not `cancelled`). This is irreversible for the plan deletion.
- `onDelete: "continue"` — subscriptions continue independently; stop them via deactivate.

Response (201 Created) echoes the plan with the assigned `processingTerminalId`.

### Checkpoint
Does the API return HTTP 201 with the `paymentPlanId` you assigned? If you get 409, a plan with
that ID already exists — retrieve it with GET or choose a different ID.

---

## Step 3 — Create a subscription

> **Before writing any code for this step:** Read `references/api-schema.md`. The
> `paymentMethod.type` discriminator and all other enum fields must come from that file. The
> inline example below uses a comment placeholder for `type` — read the reference, confirm the
> exact value, then fill it in.

`POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions`

```
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

The `subscriptionId` is **merchant-assigned** — choose a unique value per customer enrollment.

```jsonc
{
  "subscriptionId": "CUST-12345-GYM-2026",
  "paymentPlanId": "MONTHLY-GYM-BASIC",
  "paymentMethod": {
    "type": "<read subscription.paymentMethod.type from references/api-schema.md>",
    "token": "<secure-token>"  // from the Secure Tokens API
  },
  "startDate": "2026-07-01"  // YYYY-MM-DD; first payment collection date
}
```

`startDate`: Must be the current day or a later date. The gateway's calendar runs on Coordinated Universal Time (UTC) in winter and Irish Standard Time (IST) in summer, so near midnight "today" may differ from the caller's local date. Validate this before sending.

Optional overrides (per-subscriber customisation):
- `name` / `description` — override plan's name and description for this subscriber
- `recurringOrder.amount` — override the per-cycle amount (useful for per-customer pricing)
- `setupOrder.amount` — override the setup fee
- `length` / `endDate` — override the plan's term length or set an explicit end date
- `pauseCollectionFor` — skip the first N billing cycles
- `customFields` — `[{ "name": "...", "value": "..." }]`

For **bank account (ACH) subscriptions**, include in `paymentMethod`:
```jsonc
{
  "type": "secureToken",
  "token": "<token>",
  "accountType": "<read accountType enum from references/api-schema.md>",  // checking | savings
  "secCode": "<read secCode enum from references/api-schema.md>"  // web|tel|ccd|ppd; required for ACH
}
```

Response (201 Created) includes the full subscription object with `currentState.status: "active"`,
`currentState.nextDueDate`, and the linked `paymentPlan` and `secureToken` summaries.

### Checkpoint
Does the API return HTTP 201 with `currentState.status: "active"` and a `nextDueDate`? If not,
work through the error taxonomy below.

---

## Step 4 — Manage the subscription lifecycle

*(Implement only the operations the developer needs)*

### Update a payment plan (PATCH)

> **Before writing any PATCH body:** Read `references/api-schema.md`. You need: (1) the valid `op`
> enum values for RFC 6902 JSON Patch, and (2) any plan-level PATCH restrictions. Read both before
> writing any code.

`PATCH https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}`

```
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

**Idempotency-Key is required** on PATCH — see Core Principle #2.

The body is an **RFC 6902 JSON Patch array**. Use `op` values from `references/api-schema.md`:

```json
[
  { "op": "<read JSON Patch op from references/api-schema.md>", "path": "/name", "value": "Premium Gym Membership" },
  { "op": "<read JSON Patch op from references/api-schema.md>", "path": "/description", "value": "Updated description" }
]
```

Common patchable fields: `name`, `description`, `onUpdate`, `onDelete`, `recurringOrder/amount`,
`length`. The `type` and `frequency` fields are immutable after plan creation.

**Propagation depends on `onUpdate`:** If the plan was created with `onUpdate: "update"`, changes
propagate to existing subscriptions automatically. If `onUpdate: "continue"`, existing subscriptions
are not affected — only new subscriptions use the updated values.

Response (200 OK) returns the updated plan.

---

### Delete a payment plan

`DELETE https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}`

```
Authorization: Bearer <token>
```

No request body. No `Idempotency-Key` required on DELETE.

**Before writing deletion code:** confirm the `onDelete` value set at plan creation:
- `onDelete: "complete"` — all linked subscriptions transition to `completed` status. This cannot
  be undone for subscriptions that complete as a result of the deletion.
- `onDelete: "continue"` — subscriptions continue independently; stop them individually via the
  deactivate endpoint.

Response (200 OK or 204 No Content).

---

### Retrieve or list payment plans

**Retrieve a single plan:**
`GET https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}`

Returns the full plan object.

**List payment plans:**
`GET https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-plans`

Supports pagination: `limit` (default 10), `before`/`after` cursors; `hasMore` indicates additional
pages. Read `references/api-schema.md` for any available filter parameters.

---

### Update a subscription (PATCH)

> **Before writing any PATCH body:** Read `references/api-schema.md`. You need two things from
> it: (1) the valid `op` enum values for RFC 6902 JSON Patch, and (2) the PATCH restrictions
> table listing fields that cannot be modified or deleted. Read both before writing any code.

`PATCH https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}`

```
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

The body is an **RFC 6902 JSON Patch array** — not a PUT body. Use `op` values from
`references/api-schema.md` (e.g. `replace`, `add`, `remove` — read the enum, do not guess):

```json
[
  { "op": "<read JSON Patch op from references/api-schema.md>", "path": "/recurringOrder/amount", "value": 4500 },
  { "op": "<read JSON Patch op from references/api-schema.md>", "path": "/endDate", "value": "2027-06-30" }
]
```

**PATCH restrictions** (read from `references/api-schema.md`):
- `recurringOrder`, `description`, `name` — cannot be deleted (remove op is rejected)
- `currentState`, `type`, `frequency`, `paymentPlan` — cannot be modified by any PATCH operation

---

### Deactivate a subscription

`POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/deactivate`

```
Authorization: Bearer <token>
```

No request body. No `Idempotency-Key` required.

**Before writing deactivation code:** confirm with the developer what they want to happen. Deactivating sets `currentState.status` to `"cancelled"`. The subscription can be reactivated later (unlike payment link deactivation, this is not permanent).

**Financial impact for `type: automatic` subscriptions:** Deactivation stops future scheduled collections immediately. Any payment already in-flight at the moment of deactivation may still complete — it will not be reversed. Check `currentState.outstandingInvoices` before deactivating if the developer needs to know how many cycles remain unpaid; those invoices will not be collected after deactivation unless the subscription is reactivated.

Response (200 OK) returns the updated subscription with `currentState.status: "cancelled"`.

---

### Reactivate a subscription

`POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/reactivate`

```
Authorization: Bearer <token>
```

No request body. No `Idempotency-Key` required.

Response (200 OK) returns the updated subscription with `currentState.status: "active"` and an
updated `nextDueDate`.

---

### Subscription status values

`currentState.status` can be one of four values (read from `references/api-schema.md`):

| Status | Meaning |
| --- | --- |
| `active` | Subscription is running; payments collect on schedule (automatic) or on demand (manual) |
| `completed` | All billing cycles finished naturally, or the plan was deleted with `onDelete: "complete"` |
| `cancelled` | Subscription was deactivated; can be reactivated via the reactivate endpoint |
| `suspended` | Gateway-level hold — typically triggered by repeated payment failures on an automatic subscription. The subscription cannot collect payments while suspended. Contact Payroc support to resolve the underlying issue (e.g. expired card); then reactivate. |

---

### Manually collect a payment

*(For `type: manual` subscriptions only)*

You can collect only when a payment is due. The plan's `frequency` sets how often that is, for example weekly or monthly. If the payment for the current period has already been collected, the gateway rejects the request, so don't retry a rejected collection within the same period.

`POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/pay`

```
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

```jsonc
{
  "order": {
    "amount": 4000,         // integer, lowest denomination; required
    "orderId": "INV-9001",  // optional merchant reference
    "description": "July gym fee"  // optional
  }
}
```

Response (201 Created) includes `payment.paymentId`, `payment.status`, `payment.responseCode`,
updated `currentState.paidInvoices`, and `currentState.nextDueDate`.

---

### Retrieve or list subscriptions

**Retrieve a single subscription:**
`GET https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}`

Returns the full subscription object including `currentState`.

**List subscriptions:**
`GET https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/subscriptions`

> Read `references/api-schema.md` for list filter enum values (`frequency`, `status`) before
> writing query parameter code. Use only documented values.

Supports query filters: `customerName`, `last4`, `paymentPlan`, `frequency`, `status`,
`endDate`, `nextDueDate`. Pagination: `limit` (default 10), `before`/`after` cursors; `hasMore`
indicates additional pages.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or wrong API key | Re-generate token; verify `x-api-key` header |
| 400 — `idempotencyKeyMissing` | Missing `Idempotency-Key` header | Add `Idempotency-Key: <uuid-v4>` to every POST and PATCH — except the deactivate and reactivate endpoints and DELETE (see Core Principle #2) |
| 400 — field validation error | Required field missing or wrong format | Read `errors[].parameter` to identify the failing field; fix and resubmit with a fresh idempotency key (the corrected body needs a new key) |
| 400 — invalid enum value | Enum value not from the spec | Read `references/api-schema.md` and use the documented value exactly |
| 400 — `recurringOrder` missing | `type: automatic` plan has no `recurringOrder` | Add `recurringOrder.amount` to the plan; automatic collection requires a defined amount |
| 409 — `resourceAlreadyExists` | `paymentPlanId` or `subscriptionId` already in use | Retrieve the existing resource; or choose a different ID for a new one |
| 409 — idempotency conflict | Same key reused for a different payload | Generate a fresh UUID v4 for each distinct operation |
| 404 | Wrong `processingTerminalId`, `paymentPlanId`, or `subscriptionId` | Verify the path parameters against creation responses |
| 500 | Server error | Retry with exponential backoff; surface `errors` array if present |
| Subscription `status: cancelled`, no payments collected | Subscription was deactivated | Reactivate via the reactivate endpoint |
| `type`/`frequency` PATCH rejected | These fields cannot be modified after creation | Create a new subscription with the desired settings if the type or frequency needs to change |
| Plan update not reflected in subscriptions | `onUpdate: continue` was set at plan creation | Per-plan: the `continue` setting is immutable; update subscriptions individually via PATCH, or create a new plan |

**Error shape** — errors follow RFC 7807 (envelope) + Payroc `errors[]` extension. Read
`errors[].parameter` to identify the failing field, `errors[].detail` for the short reason, and
`errors[].message` for the explanation. See `references/error-response-format.md` for the
cross-skill standard.

---

## Common pitfalls

- **Missing `recurringOrder` for automatic plans.** If `type: automatic`, `recurringOrder.amount`
  must be present in the plan; the API rejects plans without it.
- **Trying to PATCH `type` or `frequency` on a subscription.** These are immutable after creation.
  If a customer needs a different frequency, create a new subscription.
- **Reusing `paymentPlanId` or `subscriptionId`.** Both are merchant-assigned and must be globally
  unique per terminal. If you get a 409, retrieve the existing record rather than creating a new one.
- **Amount in major units.** `amount: 50` means 50 cents, not $50. Use `5000` for $50.00.
- **Missing idempotency key on PATCH.** PATCH requires `Idempotency-Key` just like POST.
- **Assuming deactivate is permanent.** Unlike payment link deactivation, subscription deactivation
  sets status to `cancelled` but the subscription can be reactivated.
- **Wrong `secCode` for ACH.** If the payment method is a bank account, `secCode` is required.
  Read the valid values (`web`, `tel`, `ccd`, `ppd`) from `references/api-schema.md`.

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service using the URL and header from `references/identity-call.md`
- [ ] `Idempotency-Key` header present (UUID v4) on every POST and PATCH except `/deactivate`, `/reactivate` and DELETE
- [ ] All enum values (`type`, `frequency`, `onUpdate`, `onDelete`, `accountType`, `secCode`) read from `references/api-schema.md` — not from memory
- [ ] `paymentPlanId` and `subscriptionId` are merchant-assigned unique strings
- [ ] `recurringOrder.amount` present in plan when `type: automatic`
- [ ] Amounts expressed in the lowest currency denomination (cents for USD, pence for GBP)
- [ ] `startDate` in `YYYY-MM-DD` format, and the current day or later (gateway date: UTC in winter, IST in summer)
- [ ] Manual collections are triggered only when a payment is due, at most once per `frequency` period
- [ ] UAT endpoints used (`api.uat.payroc.com`) during testing — not production

---

## Completion

Once all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Payment plan** — [name, frequency, type (automatic/manual), amount]
> - **Subscription** — [subscriptionId, linked to plan, startDate]
> - **Lifecycle operations** (list what was built)
> - **Validated in UAT** — confirmed with Payroc API
>
> **Before going live:** swap `api.uat.payroc.com` → `api.payroc.com` and
> `identity.uat.payroc.com` → `identity.payroc.com`. Point credentials to production
> terminal and API key.

Offer next steps:
- **Webhook notifications** — receive server-side events when payments succeed or fail
- **Reporting** — query `view-authorizations` or `view-settlement-batches` skills for payment history
- **Updating stored payment methods** — re-tokenize a customer's card before it expires

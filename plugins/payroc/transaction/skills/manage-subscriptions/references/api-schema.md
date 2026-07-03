# Manage Subscriptions — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Repeat Payments schemas). Last synced: 2026-06-22. This is the offline source of truth this skill
> emits from — read enum values and required-field sets from here, not from memory. To refresh,
> re-fetch the source and regenerate this file (see [`_sources.md`](./_sources.md)).

Manage Subscriptions covers the full lifecycle of Payroc repeat payments: creating payment plan
templates, creating subscriptions (assigning customers to plans), and managing subscriptions
(update, deactivate, reactivate, manual pay).

---

## Overview — how the pieces fit together

```
Payment Plan  →  Secure Token  →  Subscription
(template)       (customer's       (links customer
                 payment method)    to plan; drives
                                   payment collection)
```

1. **Create a payment plan** — defines the schedule, frequency, amount, and collection method.
2. **Tokenize the customer's payment method** — creates a secure token (covered by the
   `save-a-payment-method` / `create-single-use-token` skills).
3. **Create a subscription** — links the customer's token to the payment plan and starts the
   billing cycle.
4. **Collect payments** — automatic (gateway-driven) or manual (via the Pay endpoint).

---

## Endpoints

| Operation | Method | Path |
| --- | --- | --- |
| Create a payment plan | POST | `/v1/processing-terminals/{processingTerminalId}/payment-plans` |
| List payment plans | GET | `/v1/processing-terminals/{processingTerminalId}/payment-plans` |
| Retrieve a payment plan | GET | `/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}` |
| Update a payment plan (JSON Patch) | PATCH | `/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}` |
| Delete a payment plan | DELETE | `/v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}` |
| Create a subscription | POST | `/v1/processing-terminals/{processingTerminalId}/subscriptions` |
| List subscriptions | GET | `/v1/processing-terminals/{processingTerminalId}/subscriptions` |
| Retrieve a subscription | GET | `/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}` |
| Update a subscription (JSON Patch) | PATCH | `/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}` |
| Deactivate a subscription | POST | `/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/deactivate` |
| Reactivate a subscription | POST | `/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/reactivate` |
| Pay manual subscription | POST | `/v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/pay` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

---

## Enums

### paymentPlan.type (collection method)
`automatic` | `manual`

- `automatic` — Payroc's gateway collects payments from the customer's account on schedule.
  Requires `recurringOrder` in the plan.
- `manual` — Merchant triggers each collection via the Pay Manual Subscription endpoint.

### paymentPlan.frequency
`weekly` | `fortnightly` | `monthly` | `quarterly` | `yearly`

### paymentPlan.onUpdate
`update` | `continue`

- `update` — Changes to the payment plan propagate to all existing subscriptions.
- `continue` — Existing subscriptions retain their original plan settings; only new subscriptions
  use the updated values.

### paymentPlan.onDelete
`complete` | `continue`

- `complete` — When the plan is deleted, all linked subscriptions are completed (stopped).
- `continue` — Subscriptions continue independently; use the deactivate endpoint to stop them.

### subscription.type (read-only; derived from the payment plan)
`automatic` | `manual`

### subscription.frequency (read-only; derived from the payment plan)
`weekly` | `fortnightly` | `monthly` | `quarterly` | `yearly`

### subscription.currentState.status (read-only)
`active` | `completed` | `suspended` | `cancelled`

### subscription.paymentMethod.type (discriminator — create request only)
`secureToken`

The only supported value is `secureToken`. Use the token string returned by the Secure Tokens
endpoint.

### secureToken.status (read-only, in subscription responses)
`notValidated` | `cvvValidated` | `validationFailed` | `issueNumberValidated` |
`cardNumberValidated` | `bankAccountValidated`

### subscription.paymentMethod.secCode (ACH only)
`web` | `tel` | `ccd` | `ppd`

Required when `accountType` is `checking` or `savings` (bank account subscriptions).

### JSON Patch `op` values (PATCH endpoints, RFC 6902)
`add` | `remove` | `replace` | `move` | `copy` | `test`

### List subscriptions — filter enums
- `frequency`: `weekly` | `fortnightly` | `monthly` | `quarterly` | `yearly`
- `status`: `active` | `completed` | `suspended` | `cancelled`

---

## Schemas

### paymentPlan (create request)

Required fields:

| Field | Type | Description |
| --- | --- | --- |
| `paymentPlanId` | string | Merchant-assigned unique identifier for this plan |
| `name` | string | Human-readable name of the plan |
| `currency` | string | ISO 4217 code (e.g. `"USD"`, `"GBP"`, `"EUR"`) |
| `type` | enum | `automatic` or `manual` |
| `frequency` | enum | Collection interval — see frequency enum above |
| `onUpdate` | enum | `update` or `continue` |
| `onDelete` | enum | `complete` or `continue` |

Optional fields:

| Field | Type | Description |
| --- | --- | --- |
| `description` | string | Plan description |
| `length` | integer | Number of billing cycles; `0` = indefinite (default: `0`) |
| `customFieldNames` | array[string] | Names of custom fields available on subscriptions |
| `setupOrder` | object | One-time setup fee charged at subscription start |
| `recurringOrder` | object | Per-cycle amount (required when `type` is `automatic`) |

**Order object shape** (used in both `setupOrder` and `recurringOrder`):

```jsonc
{
  "amount": 5000,        // integer, lowest denomination (e.g. cents); required
  "description": "...",  // optional
  "breakdown": {
    "subtotal": 4500,    // integer; required in breakdown
    "taxes": [
      { "name": "VAT", "rate": 0.2, "amount": 900 }  // rate is decimal (0.2 = 20%)
    ]
  }
}
```

### paymentPlan (response — 201 Created / 200 OK)

Echoes all request fields plus:

| Field | Type | Description |
| --- | --- | --- |
| `processingTerminalId` | string | Terminal the plan belongs to |

### subscription (create request)

Required fields:

| Field | Type | Description |
| --- | --- | --- |
| `subscriptionId` | string | Merchant-assigned unique identifier |
| `paymentPlanId` | string | The plan this subscription follows |
| `paymentMethod` | object | Secure token details (see below) |
| `startDate` | string | First billing date — `YYYY-MM-DD` |

Optional fields:

| Field | Type | Description |
| --- | --- | --- |
| `name` | string | Overrides the payment plan's name for this subscription |
| `description` | string | Overrides the payment plan's description |
| `setupOrder` | object | Override the plan's setup fee amount for this subscriber |
| `recurringOrder` | object | Override the plan's recurring amount for this subscriber |
| `endDate` | string | Subscription end date — `YYYY-MM-DD` |
| `length` | integer | Override the plan's billing cycle count |
| `pauseCollectionFor` | integer | Number of cycles to skip at the start |
| `customFields` | array | `[{ "name": string, "value": string }]` |

**paymentMethod object:**

```jsonc
{
  "type": "secureToken",   // required; only valid value
  "token": "<token>",      // required; the token string from the Secure Tokens API
  "accountType": "checking" | "savings",  // ACH only
  "secCode": "web" | "tel" | "ccd" | "ppd"  // required for ACH
}
```

### subscription (response — 201 Created / 200 OK)

| Field | Type | Description |
| --- | --- | --- |
| `subscriptionId` | string | Echoed from request |
| `processingTerminalId` | string | Terminal identifier |
| `paymentPlan` | object | `{ paymentPlanId, name, link }` |
| `secureToken` | object | `{ secureTokenId, customerName, token, status, link }` |
| `name` | string | Subscription name |
| `description` | string | Description |
| `currency` | string | ISO 4217 code |
| `type` | enum | `manual` or `automatic` |
| `frequency` | enum | Collection interval |
| `startDate` | string | `YYYY-MM-DD` |
| `endDate` | string | `YYYY-MM-DD` or absent if indefinite |
| `length` | integer | Total billing cycles (`0` = indefinite) |
| `pauseCollectionFor` | integer | Cycles paused at start |
| `setupOrder` | object | Setup payment details (with breakdown: subtotal, surcharge, taxes) |
| `recurringOrder` | object | Recurring payment details |
| `currentState` | object | Status snapshot (see below) |
| `customFields` | array | `[{ "name", "value" }]` |

**currentState object:**

| Field | Type | Description |
| --- | --- | --- |
| `status` | enum | `active`, `completed`, `suspended`, `cancelled` |
| `paidInvoices` | integer | Payments already collected |
| `nextDueDate` | string | Date of next payment (`YYYY-MM-DD`) |
| `outstandingInvoices` | integer | Remaining payments (present if fixed-term) |

### PATCH restrictions (subscriptions)

Fields that **cannot be deleted**:
- `recurringOrder`
- `description`
- `name`

Fields that **cannot be modified at all** (no PATCH operation allowed):
- `currentState`
- `type`
- `frequency`
- `paymentPlan`

### Pay Manual Subscription (request body)

```jsonc
{
  "order": {
    "orderId": "...",       // optional — merchant reference for this payment
    "amount": 5000,         // required — integer, lowest denomination
    "description": "...",   // optional
    "breakdown": {
      "subtotal": 4500,
      "convenienceFee": { "amount": 500 },
      "surcharge": { "bypass": false, "amount": 0, "percentage": 0.0 },
      "taxes": [{ "name": "Tax", "rate": 0.1, "amount": 500 }]
    }
  },
  "operator": "...",          // optional
  "customFields": [{ "name": "...", "value": "..." }]
}
```

Response (201): includes `subscriptionId`, `processingTerminalId`, `payment` (paymentId, dateTime,
currency, amount, status, responseCode, responseMessage), `secureToken`, `currentState`,
`customFields`.

---

## Required headers

| Header | Where | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | Every request | Token from the identity service; expires in 3600s |
| `Content-Type: application/json` | POST / PATCH | |
| `Idempotency-Key: <UUID v4>` | Every POST and PATCH — **except** the deactivate and reactivate sub-endpoints, and DELETE | Required; fresh UUID per distinct operation |

DELETE does not require `Idempotency-Key`. The deactivate (`/deactivate`) and reactivate (`/reactivate`) POST endpoints also do not require `Idempotency-Key`.

---

## List subscriptions — query filters

| Parameter | Type | Notes |
| --- | --- | --- |
| `customerName` | string | Filter by customer name |
| `last4` | string | Last 4 digits of card or account number |
| `paymentPlan` | string | Filter by plan name |
| `frequency` | enum | See frequency enum above |
| `status` | enum | `active`, `completed`, `suspended`, `cancelled` |
| `endDate` | date | `YYYY-MM-DD` — filter by end date |
| `nextDueDate` | date | `YYYY-MM-DD` — filter by next payment date |
| `before` / `after` | string | Pagination cursors |
| `limit` | integer | Max results per page (default: 10) |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes these endpoints return: `400`, `401`, `403`, `404`, `409`, `500`.

Endpoint-specific `type`s: `#idempotency-key-missing` (400 when a POST/PATCH omits `Idempotency-Key`), `#resource-already-exists` (409 when `paymentPlanId` or `subscriptionId` is already in use).

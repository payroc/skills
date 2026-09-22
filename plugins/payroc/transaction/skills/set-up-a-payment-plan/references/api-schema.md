# Payment Plans & Subscriptions — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Repeat Payments schemas). Last synced: 2026-06-22. This is the offline source of truth this skill emits
> from — read enum values and required-field sets from here, not from memory. To refresh, re-fetch the
> source and regenerate this file (see [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Create a payment plan | `POST /v1/processing-terminals/{processingTerminalId}/payment-plans` |
| List payment plans | `GET /v1/processing-terminals/{processingTerminalId}/payment-plans` |
| Retrieve a payment plan | `GET /v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}` |
| Partially update a payment plan | `PATCH /v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}` |
| Delete a payment plan | `DELETE /v1/processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}` |
| Create a subscription | `POST /v1/processing-terminals/{processingTerminalId}/subscriptions` |
| List subscriptions | `GET /v1/processing-terminals/{processingTerminalId}/subscriptions` |
| Retrieve a subscription | `GET /v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}` |
| Partially update a subscription | `PATCH /v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}` |
| Deactivate a subscription | `POST /v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/deactivate` |
| Reactivate a subscription | `POST /v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/reactivate` |
| Pay manual subscription | `POST /v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/pay` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Enums

### type (plan / subscription type)
`manual` | `automatic`

- `manual` — the merchant collects payments themselves via their POS system; the gateway does not automatically charge the customer.
- `automatic` — the gateway automatically charges the customer at each billing interval using the recurring order config; `recurringOrder` is required when `type` is `automatic`.

### frequency (billing interval)
`weekly` | `fortnightly` | `monthly` | `quarterly` | `yearly`

### onUpdate (payment plan behaviour when updated)
`update` | `continue`

- `update` — changes to the plan propagate to all linked subscriptions.
- `continue` — linked subscriptions keep their current settings; only new subscriptions pick up the updated plan.

### onDelete (payment plan behaviour when deleted)
`complete` | `continue`

- `complete` — (default) the gateway stops taking payments for all subscriptions linked to the deleted plan.
- `continue` — subscriptions continue; must be cancelled manually via the Deactivate Subscription endpoint.

### paymentMethod.type (subscription payment method discriminator)
`secureToken` — the only supported value. Always emit exactly this string.

### paymentMethod.accountType (bank accounts only, optional)
`checking` | `savings`

### paymentMethod.secCode (ACH bank accounts, required if ACH)
`web` | `tel` | `ccd` | `ppd`

- `web` — online transaction
- `tel` — telephone transaction
- `ccd` — corporate credit or debit
- `ppd` — pre-arranged payment or deposit

### currentState.status (subscription state, read-only)
`active` | `completed` | `suspended` | `cancelled`

- `active` — subscription is running and collecting payments.
- `completed` — reached the defined end date or billing cycle count.
- `suspended` — temporarily paused (e.g., payment failure).
- `cancelled` — deactivated by the merchant; use reactivate endpoint to resume.

### secureToken.status (read-only)
`notValidated` | `cvvValidated` | `validationFailed` | `issueNumberValidated` | `cardNumberValidated` | `bankAccountValidated`

---

## Schemas

### paymentPlan (create request)

```jsonc
{
  // Required
  "paymentPlanId": "PlanRef8765",         // merchant-assigned unique identifier
  "name": "Premium Club",                  // plan name
  "currency": "USD",                       // ISO 4217 code
  "type": "automatic",                     // "manual" | "automatic"
  "frequency": "monthly",                  // "weekly" | "fortnightly" | "monthly" | "quarterly" | "yearly"
  "onUpdate": "continue",                  // "update" | "continue"
  "onDelete": "complete",                  // "complete" | "continue"

  // Optional
  "description": "Monthly subscription",
  "length": 12,                            // number of billing cycles; 0 = indefinite
  "customFieldNames": ["referralCode"],    // custom field definitions (empty array allowed)

  // Optional — initial setup fee
  "setupOrder": {
    "amount": 4999,                        // lowest currency denomination (e.g. cents)
    "description": "Initial setup fee",
    "breakdown": {
      "subtotal": 4999,                    // required if breakdown sent
      "taxes": [{ "name": "VAT", "rate": 0.20 }]
    }
  },

  // Optional (required when type = "automatic")
  "recurringOrder": {
    "amount": 4999,                        // lowest denomination; required for automatic plans
    "description": "Monthly charge",
    "breakdown": {
      "subtotal": 4999,
      "taxes": [{ "name": "VAT", "rate": 0.20 }]
    }
  }
}
```

Response (201): full `paymentPlan` object plus `processingTerminalId`.

### subscription (create request)

```jsonc
{
  // Required
  "subscriptionId": "SUB-CUST-001",        // merchant-assigned unique identifier
  "paymentPlanId": "PlanRef8765",           // must match an existing payment plan
  "startDate": "2026-07-01",               // YYYY-MM-DD
  "paymentMethod": {
    "type": "secureToken",                  // only supported value — always exactly this string
    "token": "tok_abc123...",              // secure token from the Tokenization API
    // Conditional (bank accounts only):
    "accountType": "checking",             // "checking" | "savings"
    // Conditional (ACH only):
    "secCode": "web"                       // "web" | "tel" | "ccd" | "ppd"
  },

  // Optional
  "name": "Customer subscription name",    // overrides plan name for this subscription
  "description": "Custom description",
  "endDate": "2027-06-30",                // YYYY-MM-DD; omit for open-ended
  "length": 12,                           // total billing cycles; 0 = indefinite
  "pauseCollectionFor": 1,               // cycles to skip at start (free trial)
  "customFields": [{ "name": "referralCode", "value": "FRIEND2026" }],

  // Optional — override plan's setup fee for this subscriber
  "setupOrder": {
    "orderId": "SETUP-001",
    "amount": 4999,
    "description": "Setup fee",
    "breakdown": {
      "subtotal": 4999,
      "convenienceFee": { "amount": 100 },
      "taxes": [{ "rate": 0.10, "name": "Tax" }]
    }
  },

  // Optional — override plan's recurring amount for this subscriber
  // (send only if type is "automatic")
  "recurringOrder": {
    "amount": 4999,
    "description": "Monthly charge",
    "breakdown": {
      "subtotal": 4999,
      "convenienceFee": { "amount": 100 },
      "taxes": [{ "rate": 0.10, "name": "Tax" }]
    }
  }
}
```

Response (201): full `subscription` object including `currentState`, `paymentPlan` link, `secureToken` summary.

### subscription response — currentState object

```jsonc
{
  "status": "active",             // "active" | "completed" | "suspended" | "cancelled"
  "nextDueDate": "2026-08-01",   // YYYY-MM-DD — when the next payment will be collected
  "paidInvoices": 0,             // number of payments collected so far
  "outstandingInvoices": 12      // payments remaining (only returned if a fixed length is set)
}
```

### pay manual subscription (request)

```jsonc
{
  // Required
  "order": {
    "amount": 4999                // lowest denomination; required
    // Optional:
    // "orderId": "INV-001",
    // "description": "Manual payment"
  }
  // Optional:
  // "operator": "staff-user-id",
  // "customFields": [{ "name": "referralCode", "value": "FRIEND2026" }]
}
```

Response (201): `subscriptionPayment` — includes `payment.paymentId`, `payment.status`, `currentState`.

---

## Required headers

| Header | Where | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | every request | token from the identity service; expires in 3600s |
| `Content-Type: application/json` | POST / PATCH | |
| `Idempotency-Key: <UUID v4>` | every POST and PATCH — **except** the deactivate and reactivate sub-endpoints | required; fresh UUID per distinct operation |

The deactivate (`/deactivate`) and reactivate (`/reactivate`) subscription POSTs do not require
`Idempotency-Key`. Sending the header anyway is harmless; the gateway ignores it.

---

## Key constraints

- **`paymentPlanId` is merchant-assigned**: you supply the plan ID; it is not auto-generated. Must be unique per terminal.
- **`subscriptionId` is merchant-assigned**: you supply the subscription ID; it is not auto-generated.
- **Secure token required before subscription**: the `paymentMethod.token` in a subscription must be a valid secure token obtained via the Payroc Tokenization API (save-a-payment-method skill) before creating the subscription.
- **`recurringOrder` required when `type = "automatic"`**: for `manual` plans, the gateway does not collect payments automatically — omit `recurringOrder` or include it at the plan level only.
- **Amounts in lowest denomination**: all `amount` fields are integers in the smallest currency unit (e.g. cents for USD).
- **Dates are `YYYY-MM-DD`**: `startDate`, `endDate`, `nextDueDate` all use this format.
- **Delete is irreversible**: a deleted payment plan cannot be recovered; new subscriptions cannot be added to it after deletion.
- **Deactivate vs Delete**: deactivating a subscription sets its status to `cancelled` but does NOT delete it — it can be reactivated. Deleting a payment plan permanently removes the plan template.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes for these endpoints: `400`, `401`, `403`, `404`, `409`, `500`.

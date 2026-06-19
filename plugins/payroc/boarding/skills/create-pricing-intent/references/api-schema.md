# Create Pricing Intent — Full API Schema Reference

Curated slice of `https://docs.payroc.com/openapi.yml` (boarding → pricing intents). Server base
URL is `https://api.payroc.com/v1` (production) or `https://api.uat.payroc.com/v1` (test), so every
path below is relative to `/v1`.

A pricing intent is a reusable Merchant Processing Agreement (MPA) **template**. Once approved, its
`id` can be assigned to a processing account during boarding (`pricing.type = "intent"`), instead of
embedding a full pricing agreement inline.

---

## Endpoints

| Operation | Method & path | Idempotency-Key | Success |
|-----------|---------------|:---------------:|---------|
| List pricing intents | `GET /pricing-intents` | — | `200` `paginatedPricingIntent` |
| Create pricing intent | `POST /pricing-intents` | **required** | `201` `pricingIntent` |
| Retrieve pricing intent | `GET /pricing-intents/{pricingIntentId}` | — | `200` `pricingIntent` |
| Update pricing intent (full replace) | `PUT /pricing-intents/{pricingIntentId}` | — | `204` No Content |
| Partially update pricing intent | `PATCH /pricing-intents/{pricingIntentId}` | **required** | `200` `pricingIntent` |
| Delete pricing intent | `DELETE /pricing-intents/{pricingIntentId}` | — | `204` No Content |

- **`Authorization: Bearer <token>`** is required on every operation.
- **`PATCH` uses [RFC 6902](https://datatracker.ietf.org/doc/html/rfc6902) JSON Patch** — the body
  is an array of patch operations, not a partial object. It returns the updated intent (`200`).
- **`PUT` replaces the whole record** — send a complete `pricingIntent` body. It returns `204` with
  no body.
- List supports pagination query params: `before`, `after` (mutually exclusive), `limit`
  (integer, default `10`). See https://docs.payroc.com/api/pagination.

Updating or deleting a pricing intent does **not** affect merchants you have already onboarded.

---

## Enums

### status (response only)
`active` (approved) | `pendingReview` (not yet reviewed) | `rejected`

### country
`US` (only value currently supported)

### version (MPA version)
`5.2` (only value currently supported)

### processor.card.planType (discriminator)
`interchangePlus` | `interchangePlusPlus` | `tiered3` | `tiered4` | `tiered6` | `flatRate` |
`consumerChoice` | `rewardPayChoice`

### amex.type (discriminator, within card fees)
`optBlue` | `direct`

### base.annualFee.billInMonth
`june` | `december` (default `december`)

### base.platinumSecurity.billingFrequency (discriminator)
`monthly` | `annual`

### services[].name (discriminator)
`hardwareAdvantagePlan`

### rewardPayChoice debit.option
`interchangePlus` | `flatRate`

### rewardPayChoice credit.tips
`noTips` | `tipPrompt` | `tipAdjust`

---

## Shared primitives

- **`amount`** — integer in the currency's lowest denomination (cents). `2500` = $25.00.
- **`percentage`** — number, up to 2 decimal places (e.g. `0.25` = 0.25%).
- **`processorFee`** — `{ "volume": <percentage>, "transaction": <amount cents> }`. Used widely for
  per-rate buckets.

---

## Request / response body — `pricingIntent` (→ `pricingIntent5.2`)

The same `pricingIntent` schema is used for the create request body, the create/retrieve/patch
responses, and the PUT request body.

```json
{
  "key": "RETAIL-STANDARD-2026",   // string, REQUIRED — your own identifier for the template
  "country": "US",                  // enum, REQUIRED
  "version": "5.2",                 // enum, REQUIRED
  "base": { ... },                  // REQUIRED — see base object
  "processor": { ... },             // optional — see processor object
  "gateway": { ... },               // optional — see gateway object
  "services": [ ... ],              // optional — see services array
  "metadata": {                     // optional — your key/value pairs, echoed back
    "internalRef": "..."
  }
}
```

Response-only fields (returned by the gateway, not sent on create):

```json
{
  "id": "PI-XXXX",                  // assign this to a processing account's pricing.pricingIntentId
  "createdDate": "2026-06-01T12:00:00Z",
  "lastUpdatedDate": "2026-06-01T12:00:00Z",
  "status": "pendingReview"
}
```

---

## base object (`baseUs`)

Fixed and recurring fees. All monetary values in cents.

```json
{
  "addressVerification": 10,            // REQUIRED — fee per AVS request (spec-nullable, but UAT rejects null; use 0 when not charged)
  "annualFee": {                        // REQUIRED
    "amount": 9900,                     // REQUIRED — annual fee in cents
    "billInMonth": "december"           // "june" | "december" (default "december")
  },
  "regulatoryAssistanceProgram": 0,     // REQUIRED — annual program fee (spec-nullable, but UAT rejects null; use 0 when not charged)
  "merchantAdvantage": 0,               // REQUIRED — monthly Payroc Advantage fee (spec-nullable, but UAT rejects null; use 0 when not charged)
  "maintenance": 995,                   // REQUIRED — monthly maintenance fee
  "minimum": 2500,                      // REQUIRED — monthly minimum-fee shortfall charge
  "batch": 25,                          // REQUIRED — fee per batch

  "pciNonCompliance": 7495,             // optional, default 7495 — monthly fee if not PCI compliant
  "voiceAuthorization": 95,             // optional, default 95 — fee per voice authorization
  "chargeback": 2500,                   // optional, default 2500 — fee per chargeback
  "retrieval": 1500,                    // optional, default 1500 — fee per retrieval
  "earlyTermination": 57500,            // optional, default 57500 — early-termination fee
  "platinumSecurity": {                 // optional — polymorphic on billingFrequency
    "billingFrequency": "monthly",      // "monthly" (default amount 1295) | "annual" (default 15540)
    "amount": 1295
  }
}
```

---

## processor object (`PricingIntent52Processor`)

```json
{
  "card": { ... },   // optional — polymorphic on planType (see below); omit for ACH-only templates
  "ach": { ... }     // optional ACH fees — see ACH section
}
```

Both `card` and `ach` are optional. A card-accepting template carries `card` (and usually
`gateway`); an ACH-only template omits `card` and carries only `ach`.

### processor.card — discriminated on `planType`

Every variant is `{ "planType": "<value>", "fees": { ... } }`. The `fees` shape depends on
`planType`. Across the card variants, these optional sub-objects are also accepted:

- `amex` — polymorphic on `type`: `optBlue` `{ type, volume, transaction }` **or** `direct`
  `{ type, transaction }`. On the qual-based plans (`interchangePlusPlus`, `tiered3/4/6`) the
  `optBlue` amex object takes per-bucket rates that mirror the plan's `mastercardVisaDiscover`
  shape rather than a single `volume`/`transaction` — but the exact per-bucket field names for
  amex are **not enumerated in this reference. Confirm against the live OpenAPI before emitting an
  `amex` block on a tiered/qual plan; do not guess the bucket names.**
- `pinDebit` — `{ additionalDiscount %, transaction cents, monthlyAccess cents }` (all required).
- `electronicBenefitsTransfer` — `{ transaction cents }` (required).
- `specialityCards` — `{ transaction cents }` (required).

#### `interchangePlus`
```json
{
  "planType": "interchangePlus",
  "fees": {
    "mastercardVisaDiscover": { "volume": 0.25, "transaction": 10 },  // REQUIRED (processorFee)
    "amex": { "type": "optBlue", "volume": 0.30, "transaction": 10 },
    "pinDebit": { "additionalDiscount": 0.05, "transaction": 5, "monthlyAccess": 500 }
  }
}
```

#### `interchangePlusPlus`
`mastercardVisaDiscover` becomes a `qualRates` object (required `qualifiedRate`, `midQualRate`,
`nonQualRate`, each a `processorFee`):
```json
{
  "planType": "interchangePlusPlus",
  "fees": {
    "mastercardVisaDiscover": {
      "qualifiedRate":  { "volume": 0.20, "transaction": 10 },
      "midQualRate":    { "volume": 0.50, "transaction": 10 },
      "nonQualRate":    { "volume": 0.90, "transaction": 10 }
    }
  }
}
```

#### `tiered3`
Same `qualRates` shape as interchangePlusPlus (`qualifiedRate`, `midQualRate`, `nonQualRate`).

#### `tiered4`
`mastercardVisaDiscover` is `qualRatesWithPremium` — adds `premiumRate`:
```json
"mastercardVisaDiscover": {
  "qualifiedRate": { "volume": 0.20, "transaction": 10 },
  "midQualRate":   { "volume": 0.50, "transaction": 10 },
  "nonQualRate":   { "volume": 0.90, "transaction": 10 },
  "premiumRate":   { "volume": 1.20, "transaction": 10 }
}
```

#### `tiered6`
`mastercardVisaDiscover` is `qualRatesWithPremiumAndRegulated` (required `premiumRate`,
`regulatedCheckCard`, `unregulatedCheckCard`, each a `processorFee`).

#### `flatRate`
No `mastercardVisaDiscover`; uses `standardCards` (a `processorFee`, required). `amex` here only
supports the `direct` variant.
```json
{
  "planType": "flatRate",
  "fees": {
    "standardCards": { "volume": 2.90, "transaction": 30 }
  }
}
```

#### `consumerChoice`
```json
{
  "planType": "consumerChoice",
  "fees": {
    "monthlySubscription": 4995,        // REQUIRED — cents
    "volume": 3.50,                     // REQUIRED — merchant-authorized % on non-cash transactions
    "merchantChargePercentage": 0.00
  }
}
```

#### `rewardPayChoice`
```json
{
  "planType": "rewardPayChoice",
  "fees": {
    "monthlySubscription": 4995,        // REQUIRED — cents
    "debit": {                          // REQUIRED
      "option": "interchangePlus",      // "interchangePlus" | "flatRate"
      "volume": 0.20,                   // REQUIRED
      "transaction": 10                 // REQUIRED — cents
    },
    "credit": {                         // REQUIRED
      "tips": "tipPrompt",              // "noTips" | "tipPrompt" | "tipAdjust"
      "cardChargePercentage": 3,        // default 3 — % charged to the cardholder
      "merchantChargePercentage": 0.9,  // default 0.9 — % charged to the merchant
      "merchantChargePerTransaction": 0
    }
  }
}
```

### processor.ach (`ach` → `AchFees`)

```json
{
  "fees": {
    "transaction": 25,                 // REQUIRED — cents
    "batch": 25,                       // REQUIRED
    "returns": 500,                    // REQUIRED
    "unauthorizedReturn": 1000,        // REQUIRED
    "statement": 500,                  // REQUIRED
    "monthlyMinimum": 2500,            // REQUIRED — cents
    "accountVerification": 50,         // REQUIRED
    "discountRateUnder10000": 0.50,    // REQUIRED — % for transfers < $10,000
    "discountRateAbove10000": 0.25     // REQUIRED — % for transfers >= $10,000
  }
}
```

---

## gateway object (`gatewayUs5.2`)

```json
{
  "fees": {                            // REQUIRED
    "monthly": 2500,                   // REQUIRED — cents
    "setup": 0,                        // REQUIRED — cents
    "perTransaction": 10,              // REQUIRED — cents
    "perDeviceMonthly": 0,             // REQUIRED — cents
    "3dSecurePerTransaction": 5,       // optional — cents
    "tapToPayPerTransaction": 0        // optional — cents
  }
}
```

---

## services array (`servicesUs5.0`)

Array of polymorphic service objects (discriminated on `name`). Currently only one service:

```json
[
  { "name": "hardwareAdvantagePlan", "enabled": true }
]
```

---

## Complete annotated example — create request

A standard interchange-plus retail template:

```json
{
  "key": "RETAIL-STANDARD-2026",
  "country": "US",
  "version": "5.2",

  "base": {
    "addressVerification": 10,
    "annualFee": { "amount": 9900, "billInMonth": "december" },
    "regulatoryAssistanceProgram": 0,
    "merchantAdvantage": 0,
    "maintenance": 995,
    "minimum": 2500,
    "batch": 25
  },

  "processor": {
    "card": {
      "planType": "interchangePlus",
      "fees": {
        "mastercardVisaDiscover": { "volume": 0.25, "transaction": 10 },
        "amex": { "type": "optBlue", "volume": 0.30, "transaction": 10 }
      }
    }
  },

  "gateway": {
    "fees": {
      "monthly": 2500,
      "setup": 0,
      "perTransaction": 10,
      "perDeviceMonthly": 0
    }
  },

  "metadata": {
    "internalRef": "tpl-retail-std"
  }
}
```

---

## PATCH example (RFC 6902 JSON Patch)

To change the gateway monthly fee on an existing intent, send an **array of operations**:

```bash
curl -X PATCH https://api.payroc.com/v1/pricing-intents/PI-XXXX \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d '[
    { "op": "replace", "path": "/gateway/fees/monthly", "value": 1995 }
  ]'
```

The response is `200` with the full updated `pricingIntent`.

---

## Headers reference

| Header | Required on | Notes |
|--------|-------------|-------|
| `Authorization` | all | `Bearer <access_token>` |
| `Idempotency-Key` | `POST`, `PATCH` | UUID v4; reuse on retry of the same request |
| `Content-Type` | `POST`, `PUT`, `PATCH` | `application/json` |

---

## Error schema

Errors follow [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807). Real `400` response from
UAT (`POST /pricing-intents` with an empty body):

```json
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/pricing-intents",
  "errors": [
    {
      "parameter": "country",
      "detail": "Invalid format",
      "message": "The 'country' field is required"
    }
  ]
}
```

**Each `errors[]` item carries three fields:** `parameter` (the JSON path of the field that failed,
e.g. `country`, `base.annualFee.amount`), `detail` (a short reason, e.g. `"Invalid format"`,
`"Required field not populated"`), and `message` (the human-readable explanation). The top-level
envelope also includes `instance` (the request URL).

> **Spec vs. live:** the published OpenAPI `ErrorsItems` schema only lists `message`, but the live
> API returns `parameter` and `detail` too — verified against UAT on 2026-06-16 for both
> `/pricing-intents` and `/merchant-platforms`. Treat `parameter` + `detail` + `message` as the real
> shape. (The `403` schema additionally returns `resource`.)

| Status | When |
|--------|------|
| `400` | Validation error |
| `401` | Identity could not be verified (token expired/invalid) |
| `403` | No permission for this action |
| `404` | Pricing intent not found (retrieve/update/delete) |
| `406` | Not acceptable (create/update/patch) |
| `409` | Conflict (create/patch) — e.g. idempotency key reuse with a different payload |
| `500` | Server error |

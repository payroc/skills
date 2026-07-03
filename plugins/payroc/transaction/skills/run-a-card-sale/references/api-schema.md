# Run a Card Sale — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (payments schemas). Last synced: 2026-06-22. This is the offline source of truth this skill emits
> from — read enum values and required-field sets from here, not from memory. To refresh, re-fetch the
> source and regenerate this file (see [`_sources.md`](./_sources.md)).

Card payments use a pure REST/JSON API. Every enum value and schema below comes from the OpenAPI spec
and the published API reference.

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Create a payment (sale or pre-auth) | `POST /v1/payments` |
| Retrieve a payment | `GET /v1/payments/{paymentId}` |
| List payments | `GET /v1/payments` |
| Adjust a payment | `POST /v1/payments/{paymentId}/adjust` |
| Capture a pre-auth | `POST /v1/payments/{paymentId}/capture` |
| Reverse a payment | `POST /v1/payments/{paymentId}/reverse` |
| Refund a payment (referenced) | `POST /v1/payments/{paymentId}/refund` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

Identity (UAT): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Enums

### channel (payment channel)
`pos` | `web` | `moto`

- `pos` — card-present, in-store transaction processed on a physical terminal.
- `web` — online/e-commerce payment.
- `moto` — mail order or telephone order (card-not-present, not web).

### paymentMethod.type (payment method discriminator)
`card` | `secureToken` | `digitalWallet` | `singleUseToken`

- `card` — raw card data or device-read card (ICC, swipe, contactless).
- `secureToken` — a saved token from a prior tokenised payment.
- `digitalWallet` — Apple Pay or Google Pay encrypted payload.
- `singleUseToken` — a single-use token (e.g. from Hosted Fields).

### cardDetails.entryMethod (discriminator FIELD within `card` paymentMethod — not a nested key)

`icc` | `keyed` | `swiped` | `swipedFallback` | `contactlessIcc` | `contactlessMsr`

Send it as `cardDetails.entryMethod: "<value>"`, then put the entry-method data in the matching
object (`keyedData` for `keyed`, `iccData` for `icc`, etc.). Do **not** nest the fields under a
key named after the enum value (e.g. `cardDetails.keyed { … }` is rejected — `entryMethod` is required).

- `icc` — chip card inserted into a reader.
- `keyed` — card number and expiry entered manually.
- `swiped` — magnetic stripe read.
- `swipedFallback` — magnetic stripe after chip read failure.
- `contactlessIcc` — contactless chip (tap).
- `contactlessMsr` — contactless magnetic stripe (tap, legacy).

### autoCapture (boolean — not an enum, but critical)
- `true` (default) — sale: funds captured immediately when the payment is approved.
- `false` — pre-authorization: funds held on the card; capture must be called separately.

**This skill covers `autoCapture: true` (sale).** Pre-authorization is a separate skill.

### digitalWallet.serviceProvider
`apple` | `google`

### secureToken.secCode (for ACH/bank-transfer tokens only; not used in card sales)
`web` | `tel` | `ccd` | `ppd`

### tip.type
`percentage` | `fixedAmount`

### tip.mode
`prompted` | `adjusted`

### surcharge fields
- `surcharge.bypass`: boolean — set `true` to skip surcharging for this transaction.
- `surcharge.amount`: integer — surcharge in minor currency units.
- `surcharge.percentage`: number — surcharge as a percentage.

### tax.type
`amount` | `rate`

### healthcareExpenses[].type
`copay` | `clinic` | `dental` | `prescription` | `transit` | `vision`

### customer.notificationLanguage
`en` | `fr`

### status values (returned in payment response, read-only)
`pending` | `authorized` | `settled` | `declined` | `voided` | `refunded` | `partiallyRefunded`

---

## Schemas

### paymentRequest (POST /v1/payments request body)

Root-level required fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `channel` | enum | yes | `pos`, `web`, `moto` |
| `processingTerminalId` | string | yes | Terminal identifier from Payroc setup |
| `order` | object | yes | Payment order details — see `paymentOrderRequest` |
| `paymentMethod` | object | yes | Polymorphic — discriminated by `type` field |
| `operator` | string | no | Staff member who processed the transaction |
| `customer` | object | no | Customer contact and address information |
| `ipAddress` | object | no | IP address of the device initiating the request |
| `threeDSecure` | object | no | 3-D Secure authentication data (separate skill) |
| `credentialOnFile` | object | no | Tokenisation settings for saving the card |
| `offlineProcessing` | object | no | Offline transaction details |
| `autoCapture` | boolean | no | Default `true` (sale). Set `false` for pre-auth |
| `processAsSale` | boolean | no | Default `false`. Set `true` for immediate settlement |
| `customFields` | array | no | Custom key-value merchant data |

### paymentOrderRequest

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `orderId` | string | yes | Unique merchant-assigned identifier for this order |
| `amount` | integer | yes | Total in lowest currency denomination (cents/pence) |
| `currency` | string | yes | ISO 4217 code (e.g. `USD`, `GBP`, `EUR`) |
| `dateTime` | string | no | ISO 8601 processing timestamp |
| `description` | string | no | Transaction description |
| `acceptPartialAmount` | boolean | no | Allow partial authorisation if `true` |
| `dccOffer` | object | no | Dynamic currency conversion offer |
| `standingInstructions` | object | no | Recurring or instalment payment configuration |
| `breakdown` | object | no | Itemised transaction details (see breakdown schema) |

### paymentMethod — card variant

```yaml
paymentMethod:
  type: card                # required discriminator
  cardDetails:              # required
    entryMethod: keyed      # required discriminator FIELD (not a nested key):
                            #   icc | keyed | swiped | swipedFallback | contactlessIcc | contactlessMsr
    cardholderName: ...     # cardholder name — sits on cardDetails, not inside the data object
    # Entry-method-specific DATA object. For keyed entry, use keyedData:
    keyedData:
      dataFormat: plainText # required: plainText | encrypted (read api-schema for encrypted)
      cardNumber: ...       # card number (PAN) — field is `cardNumber`, not `pan`
      expiryDate: ...       # YYMM format
      cvv: ...              # card security code
    # For chip (entryMethod: icc) use iccData + a device object instead of keyedData.
```

### paymentMethod — card variant (keyed, minimal)

The `keyed` entry type is the most common for online/MOTO card-not-present sales:

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

### paymentMethod — secureToken variant

```json
{
  "type": "secureToken",
  "token": "tok_abcdef123456"
}
```

### paymentMethod — singleUseToken variant

```json
{
  "type": "singleUseToken",
  "token": "sut_abcdef123456"
}
```

### breakdown object (optional itemisation)

| Field | Type | Notes |
| --- | --- | --- |
| `subtotal` | integer | Pre-tax amount (required if `breakdown` is present) |
| `tip` | object | Tip config: `type` (`percentage`/`fixedAmount`), `mode` (`prompted`/`adjusted`), `amount`/`percentage` |
| `surcharge` | object | Surcharge: `bypass` (bool), `amount` (int), `percentage` (num) |
| `taxes` | array | Each: `type` (`amount`/`rate`), `name`, value |
| `dutyAmount` | integer | Duties/fees in minor units |
| `freightAmount` | integer | Shipping cost in minor units |
| `convenienceFee` | object | Convenience fee amount |
| `dualPricing` | object | Alternative pricing: `offered`, `choiceRate`, `alternativeTender` |
| `healthcareExpenses` | array | Each: `type` enum + `amount` |
| `items` | array | Line items: commodity code, product code, unit price, quantity, taxes |

### customer object (optional)

| Field | Type | Notes |
| --- | --- | --- |
| `firstName`, `lastName` | string | Cardholder name |
| `dateOfBirth` | string | `YYYY-MM-DD` |
| `referenceNumber` | string | Your internal customer ID |
| `billingAddress` | object | Card billing address |
| `shippingAddress` | object | Delivery address |
| `contactMethods` | array | Polymorphic: `email`, `phone`, `mobile`, `fax` |
| `notificationLanguage` | enum | `en` or `fr` |

---

## Payment response (201 Created)

| Field | Type | Notes |
| --- | --- | --- |
| `paymentId` | string | Unique gateway-assigned identifier. Save this — required for capture, refund, reverse |
| `order` | object | Echo of submitted order details with final amounts |
| `paymentMethod` | object | Processed payment method info (masked card details) |
| `customer` | object | Echoed customer data |
| `transactionStatus` | string | Status: see status enum above |
| `breakdown` | object | Final transaction breakdown |
| `dccOffer` | object | Dynamic currency conversion result (if applicable) |
| `secureTokenId` | string | Token ID if tokenisation was requested (`credentialOnFile`) |
| `links` | array | HATEOAS links for follow-on operations |

**Save `paymentId` immediately.** It is required for every follow-on operation (refund, reversal, capture, adjust).

---

## Minimal sale request example

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

`autoCapture` defaults to `true`, so omitting it runs a sale (immediate capture).

---

## Query parameters for GET /v1/payments

| Parameter | Type | Notes |
| --- | --- | --- |
| `processingTerminalId` | string | Filter by terminal |
| `orderId` | string | Filter by merchant order ID |
| `operator` | string | Filter by operator name |
| `cardholderName` | string | Filter by name |
| `first6` | string | First 6 digits of card |
| `last4` | string | Last 4 digits of card |
| `tender` | enum | Payment tender type |
| `tipMode` | enum | Tip mode |
| `type` | enum | Payment type |
| `status` | enum | Payment status |
| `dateFrom`, `dateTo` | string | ISO 8601 date range |
| `settlementState` | string | Settlement state filter |
| `settlementDate` | string | Settlement date filter |
| `paymentLinkId` | string | Filter by payment link |
| `before`, `after`, `limit` | string/int | Cursor-based pagination |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes for these endpoints: `400`, `401`, `403`, `404`, `409`, `500`.

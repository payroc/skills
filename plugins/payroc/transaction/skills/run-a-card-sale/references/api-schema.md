# Run a Card Sale — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (payments schemas). Last synced: 2026-11-03. This is the offline source of truth this skill emits
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

Host (test and live): `https://api.payroc.com`. Use a test API key for testing; the key, not the URL, decides test or live.

Identity (test and live): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

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
- `digitalWallet` — Apple Pay or Google Pay encrypted payload, hex-encoded in `encryptedData`.
- `singleUseToken` — a single-use token (e.g. from Hosted Fields).

### cardDetails.entryMethod (discriminator FIELD within `card` paymentMethod — not a nested key)

`raw` | `icc` | `keyed` | `swiped`

Send it as `cardDetails.entryMethod: "<value>"`, then put the entry-method data in the matching
object (`keyedData` for `keyed`, `iccData` for `icc`, etc.). Do **not** nest the fields under a
key named after the enum value (e.g. `cardDetails.keyed { … }` is rejected — `entryMethod` is required).

- `raw` — unencrypted payment data directly from the device.
- `icc` — chip card inserted into a reader.
- `keyed` — card number and expiry entered manually.
- `swiped` — magnetic stripe read.

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

### transactionResult.status values (returned in payment response, read-only)
`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `admin` | `expired` | `accepted`

### transactionResult.responseCode values (read-only)
`A` approved | `D` declined | `E` received, processed later | `P` partial approval | `R` declined, customer to contact their bank | `C` declined, card reported lost or stolen

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
                            #   raw | icc | keyed | swiped
    cardholderName: ...     # cardholder name — sits on cardDetails, not inside the data object
    # Entry-method-specific DATA object. For keyed entry, use keyedData:
    keyedData:
      dataFormat: plainText # required: plainText | fullyEncrypted | partiallyEncrypted
      cardNumber: ...       # card number (PAN) — field is `cardNumber`, not `pan`
      expiryDate: ...       # MMYY format
      cvv: ...              # card security code
    # For chip (entryMethod: icc) use iccData + a device object instead of keyedData.
```

### paymentMethod — card variant (keyed, minimal)

The `keyed` entry type is the usual one for online/MOTO card-not-present sales:

```json
{
  "type": "card",
  "cardDetails": {
    "entryMethod": "keyed",
    "cardholderName": "Jane Smith",
    "keyedData": {
      "dataFormat": "plainText",
      "cardNumber": "4111111111111111",
      "expiryDate": "1226",
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
  "token": "<single-use token: exactly 128 characters>"
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

#### Level 2/3/CEDP fields

Apart from `subtotal`, which is required whenever you send a `breakdown`, and `quantity` and
`unitPrice`, which every entry in `breakdown.items` needs, none of the fields below are structurally
required by the API. Spec prose (not a `required:` constraint) marks them as needed to qualify a transaction for Level 2/Level 3/CEDP enhanced-data
interchange rates — lower rates on B2B and purchasing-card transactions in exchange for richer
line-item and tax detail. Send them when the merchant wants that rate benefit; omit them for a
plain consumer sale.

| Field | Needed for |
| --- | --- |
| `subtotal`, `taxes` | Level 2, Level 3, CEDP |
| `breakdown.dutyAmount`, `breakdown.freightAmount`, `breakdown.items` (the array itself) | Level 3, CEDP |
| Each item's `commodityCode`, `productCode`, `description`, `unitPrice`, `quantity` | Level 3, CEDP |

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
| `processingTerminalId` | string | Terminal that processed the payment |
| `operator` | string | Operator who ran the payment (if sent) |
| `order` | object | Echo of submitted order details with final amounts (`orderId`, `amount`, `currency`, `breakdown`, …) |
| `customer` | object | Echoed customer data (if sent) |
| `card` | object | Masked card details: `type`, `entryMethod`, `cardNumber` (masked), `expiryDate`, `securityChecks`; `secureToken` if tokenisation was requested (`credentialOnFile`) |
| `refunds` | array | Refunds against this payment (on a retrieved payment) |
| `supportedOperations` | array | Follow-on operations this payment allows (for example `capture`, `fullyReverse`, `adjustTip`) |
| `transactionResult` | object | The outcome: `status` (see values above), `responseCode`, `responseMessage`, `approvalCode`, `authorizedAmount`, `type` |
| `customFields` | array | Echoed custom fields (if sent) |

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
        "expiryDate": "1226",
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

Status codes for these endpoints: `400`, `401`, `403`, `404` (retrieve), `406`, `409` and `415` (create),
`500`.

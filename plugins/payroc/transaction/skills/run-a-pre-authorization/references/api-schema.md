# Run a Pre-Authorization — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Card Payments — Create Payment, Capture, and `transactionResult` schemas).
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read enum
> values and required-field sets from here, not from memory. To refresh, re-fetch the source and
> regenerate this file (see [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Create a pre-authorization | `POST /v1/payments` |
| Capture a pre-authorization | `POST /v1/payments/{paymentId}/capture` |
| Retrieve a payment | `GET /v1/payments/{paymentId}` |
| Adjust a payment (before capture) | `POST /v1/payments/{paymentId}/adjust` |
| Reverse a payment (void) | `POST /v1/payments/{paymentId}/reverse` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Enums

### channel (PaymentRequestChannel)
`pos` | `web` | `moto`

- `pos` — point-of-sale (in-person, card present)
- `web` — online / e-commerce
- `moto` — mail order / telephone order

### paymentMethod.type
`card` | `secureToken` | `digitalWallet` | `singleUseToken`

### cardDetails.entryMethod
`raw` | `icc` | `keyed` | `swiped`

- `keyed` — card number, expiry, CVV entered manually (card not present)
- `swiped` — magnetic stripe data from a physical swipe
- `icc` — EMV chip card data
- `raw` — raw unencrypted device data

### keyedData.dataFormat
`plainText` | `partiallyEncrypted` | `fullyEncrypted`

### swipedData.dataFormat
`plainText` | `encrypted`

### fallbackReason (card downgrade)
`technical` | `repeatFallback` | `emptyCandidateList`

### pinDetails.dataFormat
`dukpt` | `raw`

### accountType
`checking` | `savings`

### secCode (ACH)
`web` | `tel` | `ccd` | `ppd`

### digitalWallet.serviceProvider
`apple` | `google`

### offlineProcessing.operation
`offlineDecline` | `offlineApproval` | `deferredAuthorization`

### credentialOnFile.mitAgreement
`unscheduled` | `recurring` | `installment`

### standingInstructions.sequence
`first` | `subsequent`

### standingInstructions.processingModel
`unscheduled` | `recurring` | `installment`

### tip.type
`percentage` | `fixedAmount`

### tip.mode
`prompted` | `adjusted`

### tax.type
`amount` | `rate`

### dualPricing.alternativeTender
`card` | `cash` | `bankTransfer`

### healthcareExpense.type
`copay` | `clinic` | `dental` | `prescription` | `transit` | `vision`

### device.category
`attended` | `unattended`

### DeviceModel enum
`bbposChp` | `bbposChp2x` | `bbposChp3x` | `bbposRambler` | `bbposWp` | `bbposWp2` | `bbposWp3` |
`genericCtlsMsr` | `genericMsr` | `idtechAugusta` | `idtechMinismart` | `idtechSredkey` |
`idtechVp3300` | `idtechVp5300` | `idtechVp6300` | `idtechVp6800` | `ingenicoAxiumDx4000` |
`ingenicoAxiumDx8000` | `ingenicoAxiumEx8000` | `ingenicoIct220` | `ingenicoIpp320` |
`ingenicoIpp350` | `ingenicoIuc285` | `ingenicoL3000` | `ingenicoL7000` | `ingenicoS2000` |
`ingenicoS3000` | `ingenicoS4000` | `ingenicoS5000` | `ingenicoS7000` | `paxA80` | `paxA920` |
`paxA920Pro` | `paxA920Max` | `paxE500` | `paxE700` | `paxE800` | `paxIm30` | `uic680` | `uicBezel8`

### ipAddress.type
`ipv4` | `ipv6`

### customer.notificationLanguage
`en` | `fr`

### contactMethod.type
`email` | `phone` | `mobile` | `fax`

---

## Schemas

### paymentRequest (create pre-authorization body)

To create a pre-authorization instead of a sale, set **both**:
- `autoCapture: false` — do not auto-capture after authorization
- `processAsSale: false` — do not immediately settle (this is the default; must be explicitly false)

If either flag is `true`, the gateway settles the transaction as a sale.

**Required fields:**

| Field | Type | Notes |
| --- | --- | --- |
| `channel` | enum (`PaymentRequestChannel`) | `pos`, `web`, or `moto` — read from enum above |
| `processingTerminalId` | string | Terminal identifier from Payroc provisioning |
| `order` | object (`paymentOrderRequest`) | Order details — see below |
| `paymentMethod` | object (polymorphic) | Discriminated by `type` — see below |

**Optional fields (selection):**

| Field | Type | Notes |
| --- | --- | --- |
| `autoCapture` | boolean | **Set to `false` for pre-authorization.** Default: `true` |
| `processAsSale` | boolean | **Set to `false` for pre-authorization.** Default: `false` |
| `operator` | string | Operator identifier |
| `customer` | object | Customer details (name, address, contact) |
| `ipAddress` | object | Device IP (`type`: `ipv4`/`ipv6`, `value`) |
| `credentialOnFile` | object | Tokenization / recurring payment details |
| `customFields` | array | Key-value pairs echoed back in responses |

---

### paymentOrderRequest (order object)

**Required:**

| Field | Type | Notes |
| --- | --- | --- |
| `orderId` | string | Merchant-assigned unique order identifier |
| `amount` | integer (int64) | Amount in lowest denomination (e.g. cents for USD, pence for GBP) |
| `currency` | string (ISO 4217) | e.g. `"USD"`, `"GBP"`, `"EUR"` |

**Optional:**

| Field | Type | Notes |
| --- | --- | --- |
| `dateTime` | string (ISO 8601) | Transaction timestamp |
| `description` | string | Order description |
| `acceptPartialAmount` | boolean | Default: `false` |
| `breakdown` | object | Itemized breakdown (subtotal, tip, taxes, etc.) |

---

### paymentMethod variants

#### type: `"card"`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | string | yes | `"card"` |
| `cardDetails` | object (polymorphic) | yes | Discriminated by `entryMethod` |
| `accountType` | enum | no | `checking` or `savings` |

**cardDetails — entryMethod: `"keyed"` (most common for card-not-present)**

```yaml
cardDetails:
  entryMethod: "keyed"
  keyedData:
    dataFormat: "plainText"
    device:
      model: <DeviceModel enum value>
      serialNumber: <string>
      category: "attended"    # or "unattended"
    cardNumber: "<card number string>"
    expiryDate: "<MMYY>"
    cvv: "<optional CVV string>"
```

For encrypted keyed data, `dataFormat` is `"fullyEncrypted"` or `"partiallyEncrypted"` and requires additional `device` and `encryptedData`/`encryptedPan` fields.

**cardDetails — entryMethod: `"icc"` (chip card)**

```yaml
cardDetails:
  entryMethod: "icc"
  device:
    model: <DeviceModel enum value>
    serialNumber: <string>
    dataKsn: "<hex string>"
  iccData: "<hex string>"
```

#### type: `"secureToken"`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | string | yes | `"secureToken"` |
| `token` | string | yes | Secure token from a previous tokenization |
| `accountType` | enum | no | `checking` or `savings` |

#### type: `"singleUseToken"`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | string | yes | `"singleUseToken"` |
| `token` | string | yes | Single-use token |

#### type: `"digitalWallet"`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | string | yes | `"digitalWallet"` |
| `serviceProvider` | enum | yes | `"apple"` or `"google"` |
| `encryptedData` | string | yes | Encrypted wallet token |
| `cardholderName` | string | no | Optional |

---

### paymentCapture (capture request body — all fields optional)

Omit the entire body to capture the full pre-authorized amount.

| Field | Type | Notes |
| --- | --- | --- |
| `processingTerminalId` | string | optional — terminal identifier |
| `operator` | string | optional — operator who performed the capture |
| `amount` | integer (int64) | optional — partial capture amount in lowest denomination; omit for full capture |
| `breakdown` | object | optional — itemized breakdown |

```jsonc
// Full capture — omit body entirely, OR send empty object
{}

// Partial capture
{ "paymentCapture": { "amount": 5000 } }
```

> To capture MORE than the original pre-authorized amount, call the Adjust endpoint first.

---

### payment (response schema — both create 201 and capture 200)

Required response fields:

| Field | Type | Notes |
| --- | --- | --- |
| `paymentId` | string | Unique gateway identifier — persist this for capture, adjust, reverse |
| `processingTerminalId` | string | Terminal that processed the payment |
| `order` | object | Order details including amount, currency |
| `card` | object | Masked card details |
| `transactionResult` | object | **Required — read before branching on success/failure** |

Optional response fields:

| Field | Type | Notes |
| --- | --- | --- |
| `operator` | string | |
| `customer` | object | |
| `refunds` | array | |
| `supportedOperations` | object | Operations allowed on this payment |
| `customFields` | array | |

---

### transactionResult

**Required fields:** `status`, `responseCode`

| Field | Type | Notes |
| --- | --- | --- |
| `type` | enum (`TransactionResultType`) | `sale` \| `refund` \| `preAuthorization` \| `preAuthorizationCompletion` |
| `status` | enum (`TransactionResultStatus`) | **required** — current state of the transaction |
| `responseCode` | enum (`TransactionResultResponseCode`) | **required** — processor's response |
| `responseMessage` | string | Human-readable processor response (e.g. `"APPROVAL"`) |
| `approvalCode` | string | Authorization code from the processor |
| `authorizedAmount` | integer (int64) | Amount authorized, in lowest denomination |
| `currency` | string (ISO 4217) | |
| `processorResponseCode` | string | Raw processor code |
| `cardSchemeReferenceId` | string | Card-brand identifier |

### transactionResult.status (`TransactionResultStatus`)
`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `admin` | `expired` | `accepted`

> **Approval is not signalled by a single value.** A pre-authorization queued for settlement commonly
> returns `ready` (authorized + queued) with `responseCode: "A"`. Do NOT branch on a remembered subset
> (e.g. only `"approved"` — that value is not in this enum). Read every value above and identify the
> full set that pairs with bank approval.

### transactionResult.responseCode (`TransactionResultResponseCode`)
`A` | `D` | `E` | `P` | `R` | `C`

- `A` — approved by the processor
- `D` — declined by the processor
- `E` — processor received the transaction but will process it later
- `P` — partial approval (a portion of the requested amount was authorized)
- `R` — declined; issuer indicates the customer should contact their bank
- `C` — declined; issuer indicates the merchant should retain the card (reported lost/stolen)

### transactionResult.type (`TransactionResultType`)
`sale` | `refund` | `preAuthorization` | `preAuthorizationCompletion`

---

## Required headers

| Header | Applies to | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | every request | Bearer token from identity service; expires in 3600s |
| `Content-Type: application/json` | POST requests | |
| `Idempotency-Key: <UUID v4>` | every POST | Required — omitting causes a 400. Generate a fresh UUID per distinct operation; reuse the same key when retrying a failed request |

---

## Pre-authorization prerequisites

- Pre-authorization must be enabled on the merchant's terminal/account. If not enabled, the gateway may process the request as a pending sale instead of a pre-authorization.
- Pre-authorization is not available when: merchant uses dual pricing or surcharging, merchant applies convenience fees, or customer pays by bank account.

---

## Worked example — plain-text keyed card pre-authorization

```jsonc
// POST https://api.uat.payroc.com/v1/payments
// Authorization: Bearer <token>
// Idempotency-Key: <uuid-v4>
// Content-Type: application/json
{
  "channel": "moto",
  "processingTerminalId": "1234567",
  "autoCapture": false,
  "processAsSale": false,
  "order": {
    "orderId": "ORDER-001",
    "amount": 10000,
    "currency": "USD"
  },
  "paymentMethod": {
    "type": "card",
    "cardDetails": {
      "entryMethod": "keyed",
      "keyedData": {
        "dataFormat": "plainText",
        "device": {
          "model": "idtechVp3300",
          "serialNumber": "SN12345"
        },
        "cardNumber": "4111111111111111",
        "expiryDate": "1230",
        "cvv": "123"
      }
    }
  }
}
```

Successful create response (HTTP 201) includes `paymentId` — persist it for capture.

```jsonc
// POST https://api.uat.payroc.com/v1/payments/{paymentId}/capture
// Authorization: Bearer <token>
// Idempotency-Key: <fresh-uuid-v4>
// Content-Type: application/json
// Body omitted = capture full amount
```

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes for these endpoints: `400`, `401`, `403`, `404`, `409`, `500`.

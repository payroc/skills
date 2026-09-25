# ACH / Bank Transfer Payments — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Bank Transfer Payment schemas and paths). Last synced: 2026-09-17. This is the offline source of
> truth this skill emits from — read enum values and required-field sets from here, not from memory.
> To refresh, re-fetch the source URL and regenerate this file (see [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Create ACH/bank transfer payment | `POST /v1/bank-transfer-payments` |
| List bank transfer payments | `GET /v1/bank-transfer-payments` |
| Retrieve bank transfer payment | `GET /v1/bank-transfer-payments/{paymentId}` |
| Reverse (void) a payment | `POST /v1/bank-transfer-payments/{paymentId}/reverse` |
| Refund a payment (referenced) | `POST /v1/bank-transfer-payments/{paymentId}/refund` — body requires `amount` + `description`. Not usable for a settled ACH payment; see Refunds in `ach-payment-guide.md` |
| Re-present a payment | `POST /v1/bank-transfer-payments/{paymentId}/represent` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

---

## Required headers (all POST requests)

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <access_token>` |
| `Idempotency-Key` | UUID v4 (fresh per distinct operation) |
| `Content-Type` | `application/json` |

GET requests require `Authorization` only; `Content-Type` and `Idempotency-Key` are not needed.

---

## Enums

### paymentMethod.type

`ach` | `pad` | `secureToken` | `singleUseToken`

- `ach` — ACH bank account details (US transactions). Routing number + account number.
- `pad` — Pre-Authorized Debit (Canadian transactions). Transit number + institution number.
- `secureToken` — Reusable token generated from a previous ACH or PAD payment.
- `singleUseToken` — Single-use token from a tokenization or hosted-fields session.

> **Read this file before emitting `paymentMethod.type`.** Do not guess the value from training data.

### paymentMethod.accountType

`checking` | `savings`

Applies to both ACH and PAD payment methods.

### paymentMethod.secCode (ACH only — Standard Entry Class code)

`web` | `tel` | `ccd` | `ppd`

- `web` — Internet-initiated (online transactions)
- `tel` — Telephone-initiated
- `ccd` — Corporate Credit or Debit (business-to-business)
- `ppd` — Prearranged Payment and Deposit (recurring or one-time consumer)

> **`secCode` is mandatory for ACH payments (`type: "ach"`) and ACH-backed tokens.** Do not omit it.
> For PAD payments, `secCode` is not applicable.

### transactionResult.status

`ready` | `pending` | `declined` | `complete` | `admin` | `reversal` | `returned`

- `ready` — Transaction queued, not yet submitted to processor
- `pending` — Processing in progress
- `complete` — Successfully processed
- `declined` — Processor rejected the transaction
- `admin` — Administrative hold
- `reversal` — Transaction reversed (voided before settlement)
- `returned` — Return issued by the bank (e.g., NSF, closed account)

### transactionResult.type

`payment` | `refund` | `unreferencedRefund` | `accountVerification`

### transactionResult.responseCode

`A` | `D` | `E` | `P` | `R` | `C`

- `A` — Approved
- `D` — Declined
- `E` — Pending / processor handling
- `P` — Partial authorization
- `R` — Contact issuer / bank
- `C` — Card / account reported lost or stolen

### List filter: type

Enum values for the `type` query parameter on `GET /v1/bank-transfer-payments`:
`ach` | `pad`

### List filter: status

Enum values for the `status` query parameter on `GET /v1/bank-transfer-payments`:
`ready` | `pending` | `declined` | `complete` | `admin` | `reversal` | `returned`

### List filter: settlementState

`unsettled` | `settled`

---

## Schemas

### bankTransferPaymentRequest (create payment — POST body)

#### Required

| Field | Type | Notes |
| --- | --- | --- |
| `processingTerminalId` | string | Terminal identifier assigned by Payroc |
| `order` | object | See `bankTransferPaymentRequestOrder` below |
| `paymentMethod` | object | See payment method variants below |

#### Optional

| Field | Type | Notes |
| --- | --- | --- |
| `customer` | object | Customer info including notification language and contact methods |
| `credentialOnFile` | object | `{ "tokenize": true }` to store bank details for future use |
| `customFields` | array | Merchant-defined key/value pairs |

---

### bankTransferPaymentRequestOrder

#### Required

| Field | Type | Notes |
| --- | --- | --- |
| `orderId` | string | Merchant-assigned unique identifier for this order |
| `amount` | integer | Total in the currency's lowest denomination (e.g. cents for USD) |
| `currency` | string | ISO 4217 code (e.g. `"USD"`, `"CAD"`) |

#### Optional

| Field | Type | Notes |
| --- | --- | --- |
| `dateTime` | string | ISO 8601 datetime |
| `description` | string | Human-readable description |
| `breakdown` | object | Subtotal, taxes, tip — see `bankTransferRequestBreakdown` |

---

### paymentMethod: ACH (`type: "ach"`)

| Field | Required | Type | Notes |
| --- | --- | --- | --- |
| `type` | required | `"ach"` | Must be the literal string `"ach"` |
| `nameOnAccount` | required | string | Account holder name |
| `accountNumber` | required | string | Bank account number |
| `routingNumber` | required | string | Nine-digit ABA routing number |
| `accountType` | optional | enum | `"checking"` \| `"savings"` |
| `secCode` | optional* | enum | `"web"` \| `"tel"` \| `"ccd"` \| `"ppd"` — **mandatory in practice** |

*`secCode` is listed as optional in the schema but is mandatory for ACH transactions in practice. Always include it.

---

### paymentMethod: PAD (`type: "pad"`)

| Field | Required | Type | Notes |
| --- | --- | --- | --- |
| `type` | required | `"pad"` | Must be the literal string `"pad"` |
| `nameOnAccount` | required | string | Account holder name |
| `accountNumber` | required | string | Bank account number |
| `transitNumber` | required | string | Five-digit Canadian transit number |
| `institutionNumber` | required | string | Three-digit Canadian institution number |
| `accountType` | optional | enum | `"checking"` \| `"savings"` |

---

### paymentMethod: secureToken (`type: "secureToken"`)

| Field | Required | Type | Notes |
| --- | --- | --- | --- |
| `type` | required | `"secureToken"` | |
| `token` | required | string | Gateway-assigned token from prior ACH/PAD payment |
| `accountType` | optional | enum | `"checking"` \| `"savings"` |
| `secCode` | optional | enum | Required if token is ACH-backed |

---

### paymentMethod: singleUseToken (`type: "singleUseToken"`)

| Field | Required | Type | Notes |
| --- | --- | --- | --- |
| `type` | required | `"singleUseToken"` | |
| `token` | required | string | Single-use token |
| `accountType` | optional | enum | `"checking"` \| `"savings"` |
| `secCode` | optional | enum | Required if token is ACH-backed |

---

### bankTransferPayment (response)

#### Required

| Field | Type | Notes |
| --- | --- | --- |
| `paymentId` | string | Gateway-assigned unique identifier; use for all subsequent operations |
| `processingTerminalId` | string | |
| `order` | object | `{ orderId, amount, currency, ... }` |
| `bankAccount` | object | Masked account details; ACH or PAD shape depending on payment method type |
| `transactionResult` | object | See `bankTransferResult` below |

#### Optional

| Field | Type | Notes |
| --- | --- | --- |
| `customer` | object | Customer information if provided at creation |
| `refunds` | array | Refund summaries (populated after refund operations) |
| `returns` | array | Return summaries (populated on bank returns — e.g., NSF) |
| `representment` | object | `paymentSummary` — populated if payment has been re-presented |
| `customFields` | array | |

---

### bankTransferResult (transactionResult in response)

| Field | Required | Type | Notes |
| --- | --- | --- | --- |
| `type` | required | enum | `"payment"` \| `"refund"` \| `"unreferencedRefund"` \| `"accountVerification"` |
| `status` | required | enum | `"ready"` \| `"pending"` \| `"declined"` \| `"complete"` \| `"admin"` \| `"reversal"` \| `"returned"` |
| `responseCode` | required | enum | `"A"` \| `"D"` \| `"E"` \| `"P"` \| `"R"` \| `"C"` |
| `authorizedAmount` | optional | integer | Amount authorised (in lowest denomination) |
| `currency` | optional | string | ISO 4217 |
| `responseMessage` | optional | string | Human-readable processor message |
| `processorResponseCode` | optional | string | Raw processor code |

---

### bankAccount in response (masked)

Account numbers and routing numbers are masked in all responses. Example ACH response:

```json
{
  "type": "ach",
  "nameOnAccount": "Sarah Hazel Hopper",
  "accountNumber": "*****5929",
  "routingNumber": "*****4162",
  "secureToken": {
    "token": "296753xxxxxxxxx",
    "status": "bankAccountValidated"
  }
}
```

Note: `secureToken` is populated in the response when `credentialOnFile.tokenize: true` was sent.

---

### returns[] item shape

When a payment is returned by the bank (e.g., NSF, closed account), the `returns` array is populated in the payment response. Each item has the following shape:

| Field | Type | Notes |
| --- | --- | --- |
| `paymentId` | string | The return payment ID — **use this** as the `{paymentId}` in the re-present endpoint, **not** the original payment's `paymentId` |
| `status` | string | Return status (e.g., `returned`) |
| `responseCode` | string | Processor response code |
| `responseMessage` | string | Human-readable processor message |

> **For re-presentment:** retrieve the original payment via `GET /v1/bank-transfer-payments/{originalPaymentId}`, find the item in `returns[]`, and use `returns[0].paymentId` as the path parameter in `POST /v1/bank-transfer-payments/{paymentId}/represent`.

---

### representment request body

The re-present endpoint (`POST /v1/bank-transfer-payments/{paymentId}/represent`) accepts:

```jsonc
{
  "paymentMethod": { ... }  // optional — omit to reuse original bank details
}
```

If `paymentMethod` is provided, it must be either `type: "ach"` (full bank details) or `type: "secureToken"`.

> **Important:** When re-presenting, use the `paymentId` from the `returns[]` array in the original payment response — **not** the original `paymentId`. The gateway creates a new payment record for each re-presentment attempt.

---

## Full create request example

```json
{
  "processingTerminalId": "1234001",
  "order": {
    "orderId": "OrderRef6543",
    "amount": 4999,
    "currency": "USD",
    "description": "Monthly subscription payment"
  },
  "paymentMethod": {
    "type": "ach",
    "accountNumber": "11101010",
    "nameOnAccount": "Sarah Hazel Hopper",
    "routingNumber": "053200983",
    "accountType": "checking",
    "secCode": "web"
  },
  "customer": {
    "notificationLanguage": "en",
    "contactMethods": [
      { "type": "email", "value": "customer@example.com" }
    ]
  },
  "credentialOnFile": {
    "tokenize": true
  }
}
```

---

## List query parameters (`GET /v1/bank-transfer-payments`)

| Parameter | Type | Notes |
| --- | --- | --- |
| `processingTerminalId` | string | **Required** |
| `orderId` | string | Filter by merchant order ID |
| `nameOnAccount` | string | Filter by account holder name |
| `last4` | string | Filter by last 4 digits of account number |
| `type` | array | `ach` \| `pad` |
| `status` | array | `ready` \| `pending` \| `declined` \| `complete` \| `admin` \| `reversal` \| `returned` |
| `dateFrom` | string | ISO 8601 datetime |
| `dateTo` | string | ISO 8601 datetime |
| `settlementState` | string | `unsettled` \| `settled` |
| `settlementDate` | string | `YYYY-MM-DD` |
| `before` | string | Cursor for pagination |
| `after` | string | Cursor for pagination |
| `limit` | integer | Page size (default: 10) |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes for these endpoints: `400`, `401`, `403`, `404`, `409`, `500`.

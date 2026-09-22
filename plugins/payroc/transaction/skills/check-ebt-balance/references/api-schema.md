# EBT Balance Check — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (payment-features/cards balance schema) and `https://docs.payroc.com/api/schema/payment-features/cards/view-ebt-balance.md`.
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read enum
> values and required-field sets from here, not from memory. To refresh, re-fetch the source and
> regenerate this file (see [`_sources.md`](./_sources.md)).

---

## Endpoint

| Operation | Method & path |
| --- | --- |
| Check EBT card balance | `POST /v1/cards/balance` |

UAT host: `https://api.uat.payroc.com`
Production host: `https://api.payroc.com`

Full UAT URL: `POST https://api.uat.payroc.com/v1/cards/balance`
Full production URL: `POST https://api.payroc.com/v1/cards/balance`

---

## Required headers

| Header | Where | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | every request | token from the identity service; expires in 3600s |
| `Content-Type: application/json` | POST | |
| `Idempotency-Key: <UUID v4>` | not used | see the note below |

> **Note:** `POST /v1/cards/balance` does **not** require an `Idempotency-Key` header. Unlike most
> Payroc POST endpoints this is a read-only balance inquiry — no resource is created or modified.
> Sending the header anyway is harmless; the gateway ignores it. Omitting it does not return a
> `400`.

---

## Request schema — `balanceInquiry`

### Root-level fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `processingTerminalId` | string | **required** | Terminal identifier provisioned by Payroc |
| `currency` | string | **required** | ISO 4217 currency code (e.g. `"USD"`) |
| `card` | object | **required** | Payment details — see `BalanceInquiryCard` below |
| `operator` | string | optional | Operator name/identifier |
| `customer` | object | optional | Customer contact/address information |

### `card` object — `BalanceInquiryCard` (polymorphic, discriminated by `type`)

Two variants:

#### Variant 1: `type: "card"`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | string | **required** | Must be `"card"` |
| `cardDetails` | object | **required** | Entry method and card data — see below |
| `accountType` | enum | optional | `"checking"` or `"savings"` — for bank accounts only |
| `ebtDetails` | object | optional | See `ebtDetails` below |
| `pinDetails` | object | optional | Encrypted or plaintext PIN |

#### Variant 2: `type: "singleUseToken"`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | string | **required** | Must be `"singleUseToken"` |
| `token` | string | **required** | Gateway-assigned single-use token |
| `accountType` | enum | optional | `"checking"` or `"savings"` |
| `ebtDetails` | object | optional | See `ebtDetails` below |
| `pinDetails` | object | optional | Encrypted or plaintext PIN |
| `secCode` | enum | optional | `"web"` \| `"tel"` \| `"ccd"` \| `"ppd"` |

---

## Enums

### `card.type`
`"card"` | `"singleUseToken"`

### `card.accountType`
`"checking"` | `"savings"`

### `card.cardDetails.entryMethod`
`"icc"` | `"swiped"` | `"keyed"` | `"raw"`

- `"icc"` — EMV chip card read
- `"swiped"` — Magnetic stripe read
- `"keyed"` — Manual/hand-keyed entry
- `"raw"` — Unencrypted device data

### `ebtDetails.benefitCategory`
`"cash"` | `"foodStamp"`

- `"cash"` — EBT Cash account (government cash assistance)
- `"foodStamp"` — EBT SNAP account (Supplemental Nutrition Assistance Program)

> **Do not guess this enum.** Only `"cash"` and `"foodStamp"` are valid. Do not use `"snap"`, `"food"`, `"stamp"`, `"ebtCash"`, `"ebtFoodStamp"`, or any other variant.

### `card.secCode` (singleUseToken variant only)
`"web"` | `"tel"` | `"ccd"` | `"ppd"`

---

## `ebtDetails` object

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `benefitCategory` | enum | optional | `"cash"` \| `"foodStamp"` — specifies which EBT account to query |

---

## `cardDetails` object variants

Each `entryMethod` variant includes:

### `entryMethod: "icc"` (chip card)

| Field | Notes |
| --- | --- |
| `device` | object with `model`, `serialNumber`, `category` |
| `iccData` | EMV chip data (hex string) |
| `encryptedData` / `plainData` | card data (one variant) |
| `pinDetails` | optional — encrypted (DUKPT) or plaintext PIN |

### `entryMethod: "swiped"` (magnetic stripe)

| Field | Notes |
| --- | --- |
| `device` | object with `model`, `serialNumber`, `category` |
| `track1` / `track2` | magnetic stripe data |
| `encryptedData` / `plainData` | card data |
| `pinDetails` | optional |

### `entryMethod: "keyed"` (manual entry)

| Field | Notes |
| --- | --- |
| `cardNumber` | PAN as string |
| `expiryDate` | `MMYY` format |
| `cvv` | optional |
| `pinDetails` | optional |

### `entryMethod: "raw"` (unencrypted device)

| Field | Notes |
| --- | --- |
| `device` | object with `model`, `serialNumber`, `category` |
| raw card data fields | device-specific |

---

## Response schema — `balance`

HTTP 200 on successful balance inquiry.

### Root-level response fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `processingTerminalId` | string | **required** | Echo of request terminal ID |
| `card` | object | **required** | Card details + balance data |
| `operator` | string | optional | Echo of request operator |
| `responseCode` | enum | optional | Processor response code |
| `responseMessage` | string | optional | Processor message |

### `responseCode` enum

| Value | Meaning |
| --- | --- |
| `"A"` | Approved |
| `"D"` | Declined |
| `"E"` | Pending processing |
| `"P"` | Partial authorization |
| `"R"` | Declined — contact issuer |
| `"C"` | Declined — card lost/stolen, retain card |

### `card` response object

| Field | Type | Notes |
| --- | --- | --- |
| `type` | string | Card brand |
| `entryMethod` | enum | Entry method used (echoed from request) |
| `cardNumber` | string | Masked — first 6 + last 4 digits |
| `expiryDate` | string | `MMYY` format |
| `cardholderName` | string | optional |
| `cardholderSignature` | string | optional |
| `secureToken` | object | optional — token summary |
| `securityChecks` | object | optional — CVV and AVS results |
| `emvTags` | array | EMV tag objects |
| `balances` | array | `cardBalance` objects — EBT balance per benefit category |

### `cardBalance` objects (inside `balances` array)

| Field | Type | Notes |
| --- | --- | --- |
| `benefitCategory` | enum | `"cash"` \| `"foodStamp"` |
| `amount` | integer | Balance in lowest currency denomination (e.g. cents) |
| `currency` | string | ISO 4217 code |

**Note:** The `balances` array is returned only for EBT card inquiries. A response may include one or two entries (cash and/or foodStamp accounts), depending on what the EBT card has.

---

## Example request (chip card EBT balance check)

```json
{
  "processingTerminalId": "TERM-001",
  "currency": "USD",
  "operator": "cashier1",
  "card": {
    "type": "card",
    "cardDetails": {
      "entryMethod": "icc",
      "device": {
        "model": "paxA920",
        "serialNumber": "12345678",
        "category": "attended"
      },
      "iccData": "9F1A0840..."
    },
    "ebtDetails": {
      "benefitCategory": "foodStamp"
    }
  }
}
```

## Example response

```json
{
  "processingTerminalId": "TERM-001",
  "operator": "cashier1",
  "responseCode": "A",
  "responseMessage": "Approved",
  "card": {
    "type": "VISA",
    "entryMethod": "icc",
    "cardNumber": "412345******3456",
    "expiryDate": "1228",
    "balances": [
      {
        "benefitCategory": "foodStamp",
        "amount": 12500,
        "currency": "USD"
      }
    ]
  }
}
```

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes this endpoint returns: `400`, `401`, `403`, `404`, `406`, `409`, `415`, `500`.

---

## EBT sharing-group requirement

`POST /v1/cards/balance` returns `400 Bad Request` if the terminal is not configured in an
EBT sharing group. EBT functionality requires a terminal that has been provisioned by Payroc
into a sharing group with the EBT network — this applies in both UAT and production. The API
and schema documented here are correct; a `400` here means the terminal needs EBT provisioning,
not that the request is malformed.

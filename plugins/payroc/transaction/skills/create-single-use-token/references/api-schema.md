# Single-Use Tokens — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/api/schema/tokenization/single-use-tokens/create.md`
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read enum
> values and required-field sets from here, not from memory. To refresh, re-fetch the source and
> regenerate this file (see [`_sources.md`](./_sources.md)).

---

## Endpoint

| Operation | Method & path |
| --- | --- |
| Create a single-use token | `POST /v1/processing-terminals/{processingTerminalId}/single-use-tokens` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

Full UAT URL: `POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/single-use-tokens`

---

## Required headers

| Header | Notes |
| --- | --- |
| `Authorization: Bearer <token>` | Bearer token from the identity service; expires in 3600s |
| `Idempotency-Key: <UUID v4>` | Required; fresh UUID per distinct request |
| `Content-Type: application/json` | Required on POST |

---

## Path parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `processingTerminalId` | string | yes | Unique identifier assigned by the gateway to the terminal |

---

## Request body schema

```yaml
createSingleUseTokenRequest:
  required:
    - channel
    - source
  properties:
    channel:
      type: string
      enum: [pos, web, moto]
      description: "Channel used to receive the customer's payment details"
    source:
      description: "Polymorphic payment method object, discriminated by 'type'"
      oneOf:
        - $ref: '#/components/schemas/cardSource'
        - $ref: '#/components/schemas/achSource'
        - $ref: '#/components/schemas/padSource'
    operator:
      type: string
      description: "Optional — operator who initiated the request"
```

### Enums

#### `channel`
`pos` | `web` | `moto`

- `pos` — point-of-sale (card-present transaction)
- `web` — online / e-commerce
- `moto` — mail order or telephone order

#### `source.type` (discriminator)
`card` | `ach` | `pad`

---

## Source object schemas

### Card source (`source.type: "card"`)

```yaml
cardSource:
  required:
    - type
    - cardDetails
  properties:
    type:
      type: string
      enum: [card]
    cardDetails:
      $ref: '#/components/schemas/cardDetails'
    accountType:
      type: string
      description: "Optional — card account type"
```

#### Card entry methods (`cardDetails.entryMethod`)
`raw` | `icc` | `keyed` | `swiped`

- `raw` — unencrypted device data
- `icc` — chip card (EMV) data
- `keyed` — manually entered card data
- `swiped` — magnetic stripe data

#### Keyed card data formats (`cardDetails.keyedData.dataFormat`)
`plainText` | `partiallyEncrypted` | `fullyEncrypted`

**Keyed plainText example (card):**
```json
{
  "type": "card",
  "cardDetails": {
    "entryMethod": "keyed",
    "keyedData": {
      "dataFormat": "plainText",
      "cardNumber": "4539858876047062",
      "cvv": "234",
      "expiryDate": "1230"
    },
    "cardholderName": "Sarah Hazel Hopper"
  }
}
```

Note: `expiryDate` format is `MMYY` (4 digits, e.g. `1230` = December 2030).

### ACH source (`source.type: "ach"`)

```yaml
achSource:
  required:
    - type
    - accountType
    - secCode
    - nameOnAccount
    - accountNumber
    - routingNumber
  properties:
    type:
      type: string
      enum: [ach]
    accountType:
      type: string
      enum: [checking, savings]
    secCode:
      type: string
      enum: [web, tel, ccd, ppd]
    nameOnAccount:
      type: string
    accountNumber:
      type: string
    routingNumber:
      type: string
```

**ACH example:**
```json
{
  "type": "ach",
  "accountType": "checking",
  "secCode": "web",
  "nameOnAccount": "Sarah Hazel Hopper",
  "accountNumber": "123456789",
  "routingNumber": "021000021"
}
```

### PAD source (`source.type: "pad"`)

```yaml
padSource:
  required:
    - type
    - accountType
    - nameOnAccount
    - accountNumber
    - transitNumber
    - institutionNumber
  properties:
    type:
      type: string
      enum: [pad]
    accountType:
      type: string
      enum: [checking, savings]
    nameOnAccount:
      type: string
    accountNumber:
      type: string
    transitNumber:
      type: string
    institutionNumber:
      type: string
```

---

## Response schema (HTTP 201)

```yaml
singleUseToken:
  required:
    - processingTerminalId
    - token
    - expiresAt
    - source
  properties:
    processingTerminalId:
      type: string
    operator:
      type: string
      description: "Echoed from request if provided"
    paymentMethod:
      type: object
      description: "Payment method details (optional in response)"
    token:
      type: string
      description: "The single-use token string; use in follow-on payment requests"
    expiresAt:
      type: string
      format: date-time
      description: "ISO 8601 timestamp; tokens expire 30 minutes after creation"
    source:
      description: "Echoed payment source with sensitive fields masked"
```

### Example success response (card)

```json
{
  "processingTerminalId": "1234001",
  "token": "fa2e9e51bc5265a33a5ca41449524d53...",
  "expiresAt": "2024-08-05T19:50:05.723+02:00",
  "source": {
    "type": "card",
    "cardNumber": "453985******7062",
    "cardholderName": "Sarah Hazel Hopper",
    "cardType": "Visa Credit",
    "currency": "USD",
    "debit": false,
    "expiryDate": "1230"
  }
}
```

**Important:** Card numbers are masked in the response — first 6 and last 4 digits visible, middle replaced with `******`. Account numbers (ACH/PAD) show only the last 4 digits.

---

## HTTP status codes

| Status | Scenario |
| --- | --- |
| `201 Created` | Token created successfully |
| `400 Bad Request` | Validation failure (see `errors[]`) |
| `401 Unauthorized` | Bearer token missing, expired, or invalid |
| `403 Forbidden` | API key lacks permission |
| `406 Not Acceptable` | Accept header mismatch |
| `409 Conflict` | Idempotency key conflict (see `errors[]` + HATEOAS link) |
| `415 Unsupported Media Type` | Content-Type not `application/json` |
| `500 Internal Server Error` | Server-side failure |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes this endpoint returns: `400`, `401`, `403`, `404`, `406`, `409`, `415`, `500`.

---

## Key behaviours

- **Single use only** — the token can be submitted in exactly one payment request. After use, it is invalid.
- **30-minute expiry** — tokens expire 30 minutes after creation (`expiresAt`). Expired tokens return a `400` or `401` depending on the consuming endpoint.
- **No MIT agreement required** — unlike secure tokens, single-use tokens do not require a merchant-initiated transaction agreement because they are one-time only.
- **Reusable across linked terminals** — a token created on one terminal can be used on other terminals linked to the same merchant account.
- **Not updateable or deletable** — single-use tokens cannot be modified or cancelled after creation; they simply expire.
- **Upgrade to secure token** — pass `"type": "singleUseToken"` as the `source.type` when calling `POST /v1/processing-terminals/{processingTerminalId}/secure-tokens` to convert to a reusable credential.

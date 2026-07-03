# Save a Payment Method — API Schema Reference

> **Local snapshot — authoritative for this skill.** Sources: `https://docs.payroc.com/openapi.yml` (secure-tokens schemas),
> `https://docs.payroc.com/api/schema/tokenization/secure-tokens/create.md`,
> `https://docs.payroc.com/api/schema/tokenization/secure-tokens/retrieve.md`,
> `https://docs.payroc.com/api/schema/tokenization/secure-tokens/list.md`,
> `https://docs.payroc.com/api/schema/tokenization/secure-tokens/delete.md`,
> `https://docs.payroc.com/api/schema/tokenization/secure-tokens/update-account.md`.
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read enum values
> and required-field sets from here, not from memory. To refresh, re-fetch the sources and regenerate
> this file (see [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Create a secure token | `POST /v1/processing-terminals/{processingTerminalId}/secure-tokens` |
| List secure tokens | `GET /v1/processing-terminals/{processingTerminalId}/secure-tokens` |
| Retrieve a secure token | `GET /v1/processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}` |
| Delete a secure token | `DELETE /v1/processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}` |
| Update account details | `POST /v1/processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}/update-account` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`
Identity (prod): `POST https://identity.payroc.com/authorize` with header `x-api-key`

---

## Enums

### source.type (discriminator — determines payment method shape)
`card` | `ach` | `pad` | `singleUseToken`

- `card` — Payment card (keyed, swiped, ICC, or raw entry)
- `ach` — US Automated Clearing House bank account
- `pad` — Canadian Pre-Authorized Debit bank account
- `singleUseToken` — Single-use token (e.g. from Hosted Fields) exchanged for a secure token

### mitAgreement (Merchant Initiated Transaction agreement)
`unscheduled` | `recurring` | `installment`

- `unscheduled` — Variable-amount transactions triggered by a specific event (e.g. account top-up)
- `recurring` — Fixed-amount, regular intervals, no fixed end date (e.g. monthly subscription)
- `installment` — Fixed-amount, regular intervals, with a defined fixed duration (e.g. 12-month plan)

### cardDetails.entryMethod
`keyed` | `swiped` | `icc` | `raw`

- `keyed` — Manually entered card data (most common for card-not-present tokenization)
- `swiped` — Magnetic stripe data
- `icc` — Chip-based (Integrated Circuit Card) data
- `raw` — Unencrypted device data

### keyedData.dataFormat
`plainText` | `partiallyEncrypted` | `fullyEncrypted`

- `plainText` — Unencrypted card data (use only in controlled test environments)
- `partiallyEncrypted` — Some fields encrypted
- `fullyEncrypted` — All card data encrypted

### ach.accountType / pad.accountType
`checking` | `savings`

### ach.secCode (Standard Entry Class code)
`web` | `tel` | `ccd` | `ppd`

### SecureTokenStatus (read-only, returned in response)
`notValidated` | `cvvValidated` | `validationFailed` | `issueNumberValidated` | `cardNumberValidated` | `bankAccountValidated`

### customer.contactMethod.type
`email` | `phone` | `mobile` | `fax`

### customer.notificationLanguage
`en` | `fr`

### ipAddress.type
`ipv4` | `ipv6`

---

## Schemas

### Create Secure Token — Request body

```yaml
# Required
source:                         # TokenizationRequestSource — polymorphic on source.type
  type: card | ach | pad | singleUseToken   # REQUIRED discriminator

# Optional
secureTokenId: string           # Merchant-generated ID; gateway assigns one if omitted
operator: string                # Name of operator saving the details
mitAgreement: unscheduled | recurring | installment
customer:
  firstName: string
  lastName: string
  dateOfBirth: string           # YYYY-MM-DD
  referenceNumber: string       # Merchant's internal customer reference
  billingAddress:
    address1: string            # Required if billingAddress provided
    address2: string
    address3: string
    city: string                # Required if billingAddress provided
    state: string               # Required if billingAddress provided
    country: string             # ISO-3166-1 alpha-2 (e.g. "US"). Required if billingAddress provided
    postalCode: string          # Required if billingAddress provided
  shippingAddress:
    recipientName: string
    address: { ... }            # Same structure as billingAddress
  contactMethods:
    - type: email | phone | mobile | fax
      value: string
  notificationLanguage: en | fr
ipAddress:
  type: ipv4 | ipv6
  value: string                 # IP address value
threeDSecure: { ... }           # 3-D Secure authentication info (optional)
customFields:
  - name: string
    value: string
```

### Source — card

```yaml
source:
  type: card
  cardDetails:
    entryMethod: keyed | swiped | icc | raw   # REQUIRED
    keyedData:                    # Required when entryMethod is "keyed"
      dataFormat: plainText | partiallyEncrypted | fullyEncrypted   # REQUIRED
      cardNumber: string          # REQUIRED
      expiryDate: string          # MMYY format (e.g. "1230" = December 2030)
      cvv: string
      issueNumber: string         # Optional
    cardholderName: string        # REQUIRED
    cardholderSignature: string   # Optional
    pinDetails: { ... }           # Optional
```

### Source — ach

```yaml
source:
  type: ach
  accountType: checking | savings   # REQUIRED
  secCode: web | tel | ccd | ppd    # REQUIRED
  nameOnAccount: string             # REQUIRED
  accountNumber: string             # REQUIRED
  routingNumber: string             # REQUIRED
```

### Source — pad

```yaml
source:
  type: pad
  accountType: checking | savings   # REQUIRED
  nameOnAccount: string             # REQUIRED
  accountNumber: string             # REQUIRED
  transitNumber: string             # REQUIRED (Canadian 5-digit transit number)
  institutionNumber: string         # REQUIRED (Canadian 3-digit institution number)
```

### Source — singleUseToken

```yaml
source:
  type: singleUseToken
  token: string             # REQUIRED — single-use token from Hosted Fields or similar
  accountType: checking | savings   # Optional (required for ACH bank accounts)
  secCode: web | tel | ccd | ppd    # Conditional (required for ACH)
  pinDetails: { ... }       # Optional
```

---

### Create Secure Token — Response (201 Created)

```yaml
secureTokenId: string         # Merchant-assigned or gateway-generated identifier
processingTerminalId: string  # Terminal the token belongs to
source:                       # Masked payment method (SecureTokenSource)
  type: card | ach | pad
  # For card:
  cardNumber: string          # Masked (e.g. "453985******7062")
  cardholderName: string
  expiryDate: string          # MMYY
  cardType: string            # e.g. "visa", "mastercard"
  currency: string            # ISO 4217 code
  debit: boolean
  surcharging:
    allowed: boolean
    amount: integer
    percentage: number
    disclosure: string
  # For ach/pad:
  nameOnAccount: string
  accountNumber: string       # Masked (last 4 digits)
  routingNumber: string       # ACH only
  transitNumber: string       # PAD only
  institutionNumber: string   # PAD only
token: string                 # Reusable token — starts with "296753", up to 12 digits, Luhn-valid
status: notValidated | cvvValidated | validationFailed | issueNumberValidated | cardNumberValidated | bankAccountValidated
mitAgreement: unscheduled | recurring | installment
customer: { ... }            # Echo of customer object submitted
customFields: [ ... ]        # Echo of customFields submitted
```

---

### List Secure Tokens — Query parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `secureTokenId` | string | Filter by merchant-assigned token identifier |
| `customerName` | string | Filter by customer name |
| `phone` | string | Filter by phone number |
| `email` | string | Filter by email address |
| `token` | string | Filter by reusable token value |
| `first6` | string | Filter by first 6 digits of card number |
| `last4` | string | Filter by last 4 digits of card or account number |
| `before` | string | Cursor — return previous page (mutually exclusive with `after`) |
| `after` | string | Cursor — return next page (mutually exclusive with `before`) |
| `limit` | integer | Max results per page (default: 10) |

Response: `{ limit, count, hasMore, data: [...secureTokenWithAccountType], links: [...] }`

---

### Update Account Details — Request body

```yaml
type: singleUseToken      # REQUIRED — only accepted value
token: string             # REQUIRED — single-use token representing the new payment details
```

Response: full `secureToken` object (same as create response).

---

### Delete Secure Token — Response

`204 No Content` — empty body. Deletion is **permanent and irreversible**. The `secureTokenId` cannot be recovered or reused for a new token.

---

## Required headers by operation

| Operation | Authorization | Idempotency-Key | Content-Type |
| --- | --- | --- | --- |
| POST (create) | Required (Bearer) | Required (UUID v4) | `application/json` |
| GET (retrieve/list) | Required (Bearer) | Not required | Not required |
| DELETE | Required (Bearer) | Not required | Not required |
| POST (update-account) | Required (Bearer) | Required (UUID v4) | `application/json` |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes for these endpoints: `400`, `401`, `403`, `404`, `409`, `500`.

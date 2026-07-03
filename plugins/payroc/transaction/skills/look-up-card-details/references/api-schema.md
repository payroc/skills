# Look Up Card Details — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (BIN Lookup schema at `#/components/schemas/binLookup`). Last synced: 2026-06-22. This is the
> offline source of truth this skill emits from — read enum values and required-field sets from
> here, not from memory. To refresh, re-fetch the source and regenerate this file (see
> [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Look up card details (BIN lookup) | `POST /v1/cards/bin-lookup` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

Full UAT URL: `POST https://api.uat.payroc.com/v1/cards/bin-lookup`

---

## Authentication and headers

| Header | Required | Value |
| --- | --- | --- |
| `Authorization` | Yes — every request | `Bearer <access_token>` from identity service |
| `Content-Type` | Yes — POST requests | `application/json` |

> **Note:** The BIN lookup endpoint does **not** require an `Idempotency-Key` header. Unlike most
> Payroc POST endpoints this is a read-only lookup — no resource is created or modified.

---

## Enums

### card.type (discriminator — how card data is supplied)

| Value | Use case |
| --- | --- |
| `cardBin` | Supply a BIN (first 6–8 digits of a card number) — simplest lookup, no full card required |
| `card` | Supply full card entry data (keyed, swiped, icc, or raw) |
| `secureToken` | Supply a gateway-issued token for a previously saved card |
| `digitalWallet` | Supply encrypted Apple Pay or Google Pay wallet data |

> **Read this table before emitting the `type` value.** All four values are exact — do not infer
> from training data.

### card.cardDetails.entryMethod (when card.type = "card")

| Value | Meaning |
| --- | --- |
| `keyed` | Card number manually keyed in |
| `swiped` | Magnetic stripe |
| `icc` | Chip (EMV) |
| `raw` | Unencrypted device data |

### card.serviceProvider (when card.type = "digitalWallet")

| Value | Meaning |
| --- | --- |
| `apple` | Apple Pay |
| `google` | Google Pay |

### card.accountType (when card.type = "card", "secureToken", or "digitalWallet")

| Value | Meaning |
| --- | --- |
| `checking` | Checking account (debit) |
| `savings` | Savings account (debit) |

### card.secCode (when card.type = "secureToken")

| Value | Meaning |
| --- | --- |
| `web` | Internet-initiated |
| `tel` | Telephone-initiated |
| `ccd` | Corporate credit or debit |
| `ppd` | Prearranged payment or deposit |

---

## Request schema — `binLookup`

```jsonc
{
  "processingTerminalId": "string",  // optional — terminal ID; include for surcharge info
  "amount": 5000,                    // optional integer, lowest currency denomination (e.g. cents)
                                     //   include for a surcharge calculation against this amount
  "currency": "USD",                 // optional ISO 4217 — include alongside amount
  "card": { ... }                    // REQUIRED — see variants below
}
```

### Variant A — `cardBin` (most common for BIN lookup)

```jsonc
{
  "processingTerminalId": "YOUR_TERMINAL_ID",  // optional
  "amount": 5000,                              // optional — for surcharge calc
  "currency": "USD",                           // optional — ISO 4217
  "card": {
    "type": "cardBin",
    "bin": "411111"   // REQUIRED — first 6–8 digits of the card number
  }
}
```

### Variant B — `card` (full card entry)

```jsonc
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "card": {
    "type": "card",
    "accountType": "checking",     // optional
    "cardDetails": {
      "entryMethod": "keyed",      // keyed | swiped | icc | raw
      // ... entry-method-specific fields
    }
  }
}
```

### Variant C — `secureToken`

```jsonc
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "card": {
    "type": "secureToken",
    "token": "GATEWAY_TOKEN",     // REQUIRED
    "accountType": "checking",    // optional
    "secCode": "web"              // optional — web | tel | ccd | ppd
  }
}
```

### Variant D — `digitalWallet`

```jsonc
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "card": {
    "type": "digitalWallet",
    "serviceProvider": "apple",           // REQUIRED — apple | google
    "encryptedData": "BASE64_DATA",       // REQUIRED
    "cardholderName": "Jane Smith",       // optional
    "accountType": "checking"             // optional
  }
}
```

---

## Response schema — `cardInfo` (HTTP 200)

```jsonc
{
  "type": "MASTERCARD",          // Card brand string — e.g. "VISA", "MASTERCARD", "AMEX"
  "cardNumber": "411111######1234", // Masked: first 6 + last 4 shown; middle digits masked
  "country": "US",               // ISO 3166-1 alpha-2 country of card issuer
  "currency": "USD",             // ISO 4217 currency
  "debit": false,                // boolean — true if this is a debit card
  "healthcare": false,           // boolean — true if linked to FSA/HSA
  "surcharging": {               // optional — only present if terminal is configured for surcharging
    "allowed": true,             // boolean — whether surcharging is permitted for this card
    "amount": 150,               // integer — surcharge in lowest denomination (cents etc.)
    "percentage": 3.0,           // number — configured surcharge rate as a percentage
    "disclosure": "A surcharge of 3.00% will be applied to this transaction."  // string
  }
}
```

Key notes:
- `type` is the card brand, not the `card.type` discriminator.
- `surcharging` is only present if a `processingTerminalId` was supplied and the terminal has
  surcharging configured. If `surcharging.allowed` is `false`, no surcharge applies even if the
  object is present.
- `amount` and `percentage` inside `surcharging` reflect the surcharge on the requested `amount`
  (if supplied), or the terminal's default rate if not.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes this endpoint returns: `400`, `401`, `403`, `404`, `406`, `409`, `415`, `500`.

Example error body:

```jsonc
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/cards/bin-lookup",
  "errors": [
    { "parameter": "card", "detail": "Required field not populated", "message": "'card' must not be empty." }
  ]
}
```

Endpoint-specific notes: `404` typically means the token was not found for the `secureToken` variant; `409` is unlikely on this read-only endpoint (it takes no `Idempotency-Key`).

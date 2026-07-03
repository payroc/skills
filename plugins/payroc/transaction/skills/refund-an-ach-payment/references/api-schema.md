# ACH / Bank Transfer Refunds — API Schema Reference

> **Local snapshot — authoritative for this skill.** Sources: `https://docs.payroc.com/openapi.yml`
> (bank-transfer-payments and bank-transfer-refunds schemas);
> `https://docs.payroc.com/guides/take-payments/payments/refunds/referenced-refunds/bank.md`;
> `https://docs.payroc.com/guides/take-payments/payments/refunds/unreferenced-refunds/bank.md`.
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read enum
> values and required-field sets from here, not from memory. To refresh, re-fetch the sources and
> regenerate this file (see [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Retrieve a bank transfer payment | `GET /v1/bank-transfer-payments/{paymentId}` |
| List bank transfer payments | `GET /v1/bank-transfer-payments` |
| Create referenced refund | `POST /v1/bank-transfer-payments/{paymentId}/refund` |
| Reverse a bank transfer payment | `POST /v1/bank-transfer-payments/{paymentId}/reverse` |
| Create unreferenced refund | `POST /v1/bank-transfer-refunds` |
| Retrieve a refund | `GET /v1/bank-transfer-refunds/{refundId}` |
| List refunds | `GET /v1/bank-transfer-refunds` |
| Reverse a refund | `POST /v1/bank-transfer-refunds/{refundId}/reverse` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

---

## Reversal vs Refund — Key Distinction

| Scenario | Use |
| --- | --- |
| Payment is still in an open batch (not yet settled) | **Reverse** (`POST /v1/bank-transfer-payments/{paymentId}/reverse`) — removes it before settlement; no funds transferred |
| Payment is settled AND you have the original `paymentId` | **Referenced refund** (`POST /v1/bank-transfer-payments/{paymentId}/refund`) |
| Payment is settled AND you do NOT have the original `paymentId` | **Unreferenced refund** (`POST /v1/bank-transfer-refunds`) — requires special merchant account enablement |

> **Gateway auto-reversal:** If the merchant runs a referenced refund on a bank transfer payment that is still in an open batch, the gateway automatically converts it to a reversal.

---

## Enums

### bankAccount.type / refundMethod.type (discriminator)

`ach` | `pad` | `secureToken` | `singleUseToken`

- `ach` — US ACH bank transfer. Requires `accountNumber`, `nameOnAccount`, `routingNumber`, `secCode`.
- `pad` — Canadian pre-authorized debit. Requires `accountNumber`, `nameOnAccount`, `transitNumber`, `institutionNumber`.
- `secureToken` — Use a previously tokenized bank account. Requires `token`.
- `singleUseToken` — Single-use token variant.

### secCode (ACH Standard Entry Class codes)

`web` | `tel` | `ccd` | `ppd`

- `web` — Internet-initiated entries
- `tel` — Telephone-initiated entries
- `ccd` — Corporate credit or debit (business-to-business)
- `ppd` — Prearranged payment and deposit (consumer, written authorization)

### accountType (for ACH unreferenced refunds)

`checking` | `savings`

### transactionResult.type (read-only, returned by API)

`payment` | `refund` | `unreferencedRefund` | `accountVerification`

### transactionResult.status (read-only, returned by API)

`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `returned` | `admin` | `expired` | `accepted`

### transactionResult.responseCode (read-only)

`A` (approved) | `D` (declined) | `E` (pending) | `P` (partial) | `R` (contact bank) | `C` (lost/stolen)

### refund summary status (in `payment.refunds[]`)

`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `returned` | `admin` | `expired` | `accepted`

### list filter: type

`payment` | `accountVerification`

### list filter: status

`ready` | `pending` | `declined` | `complete` | `admin` | `reversal` | `returned`

### list filter: settlementState

`settled` | `unsettled`

### customer.notificationLanguage

`en` | `fr`

### customer.contactMethods[].type

`email` | `phone` | `mobile` | `fax`

### secureToken.status (read-only)

`notValidated` | `cvvValidated` | `validationFailed` | `issueNumberValidated` | `cardNumberValidated` | `bankAccountValidated`

---

## Schemas

### Referenced Refund Request (`POST /v1/bank-transfer-payments/{paymentId}/refund`)

The `paymentId` is a path parameter — taken from the original payment's response. No request body fields are documented as required at the top level (the refund applies to the full original payment amount by default). Check with Payroc if partial refund amounts are supported for ACH.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `order.orderId` | string | Conditional | Merchant reference for the refund transaction |
| `order.description` | string | No | Human-readable reason for the refund |

> **Note:** The referenced refund endpoint derives the refund amount and bank account details from the original payment — the merchant does not re-supply bank account details.

---

### Unreferenced Refund Request (`POST /v1/bank-transfer-refunds`)

Top-level fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `processingTerminalId` | string | Yes | Terminal identifier |
| `order` | object | Yes | Transaction details (see below) |
| `refundMethod` | object | Yes | Bank account or token details (see below) |
| `customer` | object | No | Customer contact details |
| `customFields` | array | No | Merchant key/value pairs |

#### order object

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `orderId` | string | Yes | Merchant-assigned transaction identifier |
| `description` | string | Yes | Refund description |
| `amount` | integer | Yes | Amount in lowest denomination (cents for USD) |
| `currency` | string | Yes | ISO 4217 code (e.g. `USD`, `CAD`) |

#### refundMethod object — ACH variant (`type: "ach"`)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | string | Yes | `"ach"` |
| `accountNumber` | string | Yes | Bank account number |
| `nameOnAccount` | string | Yes | Account holder name |
| `routingNumber` | string | Yes | 9-digit ABA routing number |
| `accountType` | string | Yes | `"checking"` or `"savings"` |
| `secCode` | string | Yes | See secCode enum above |

#### refundMethod object — PAD variant (`type: "pad"`)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | string | Yes | `"pad"` |
| `accountNumber` | string | Yes | Bank account number |
| `nameOnAccount` | string | Yes | Account holder name |
| `transitNumber` | string | Yes | 5-digit branch transit number (Canadian banks) |
| `institutionNumber` | string | Yes | 3-digit bank institution code (Canadian banks) |
| `accountType` | string | Yes | `"checking"` or `"savings"` |

> **PAD vs ACH field differences:** PAD uses `transitNumber` + `institutionNumber` (not `routingNumber`), and has no `secCode` field. Do not send `routingNumber` for PAD — it is an ACH-specific field.

#### refundMethod object — secureToken variant (`type: "secureToken"`)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | string | Yes | `"secureToken"` |
| `token` | string | Yes | Previously issued secure token (296753-prefixed, up to 12 digits) |
| `accountType` | string | Conditional | Required if token represents a bank account |
| `secCode` | string | Conditional | Required if token represents an ACH account |

#### customer object

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `notificationLanguage` | string | No | `"en"` or `"fr"` |
| `contactMethods` | array | No | Array of `{type, value}` objects |

---

### bankTransferPayment Response Object (returned for referenced refund)

| Field | Type | Notes |
| --- | --- | --- |
| `paymentId` | string | Original payment identifier |
| `processingTerminalId` | string | Terminal identifier |
| `order` | object | Order with `dateTime` added |
| `bankAccount` | object | Masked bank account details + secure token if applicable |
| `transactionResult` | object | Processing outcome (see transactionResult schema) |
| `refunds` | array | List of refund summaries |
| `customer` | object | Customer information echoed |
| `customFields` | array | Custom fields echoed |

#### bankAccount object (in payment response)

| Field | Type | Notes |
| --- | --- | --- |
| `type` | string | `"ach"` or `"pad"` |
| `accountNumber` | string | Masked — last 4 digits only (e.g. `****3159`) |
| `nameOnAccount` | string | Account holder name |
| `routingNumber` | string | Routing number |
| `secCode` | string | ACH Standard Entry Class code used |
| `secureToken` | object | Present if account was tokenized |

#### secureToken object (in bankAccount)

| Field | Type | Notes |
| --- | --- | --- |
| `secureTokenId` | string | Token identifier |
| `customerName` | string | Customer name |
| `token` | string | 296753XXXXXX format (up to 12 digits) |
| `status` | string | See secureToken.status enum |
| `link` | object | HATEOAS self-reference |

#### transactionResult object

| Field | Type | Notes |
| --- | --- | --- |
| `type` | string | e.g. `"refund"` for referenced; `"unreferencedRefund"` for standalone |
| `status` | string | See transactionResult.status enum |
| `authorizedAmount` | integer | Negative value for refunds (e.g. `-4999`) |
| `currency` | string | ISO 4217 |
| `responseCode` | string | See responseCode enum |
| `responseMessage` | string | Human-readable processor message |
| `processorResponseCode` | string | Raw processor code |

---

### bankTransferRefund Response Object (returned for unreferenced refund — HTTP 201)

| Field | Type | Notes |
| --- | --- | --- |
| `refundId` | string | Gateway-assigned refund identifier |
| `processingTerminalId` | string | Terminal identifier |
| `order` | object | Order details with `dateTime` added |
| `bankAccount` | object | Masked bank account details |
| `transactionResult` | object | Processing outcome (type will be `"unreferencedRefund"`) |
| `customer` | object | Customer information echoed |
| `customFields` | array | Custom fields echoed |

---

### List bank transfer payments — query parameters

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| `processingTerminalId` | string | Yes | Terminal to query |
| `orderId` | string | No | Filter by order reference |
| `nameOnAccount` | string | No | Filter by account holder name |
| `last4` | string | No | Filter by last 4 digits of account number |
| `type` | array | No | Filter by type: `payment`, `accountVerification` |
| `status` | array | No | Filter by status enum values |
| `dateFrom` | datetime | No | ISO 8601 |
| `dateTo` | datetime | No | ISO 8601 |
| `settlementState` | string | No | `settled` or `unsettled` |
| `settlementDate` | date | No | `YYYY-MM-DD` |
| `paymentLinkId` | string | No | Filter by payment link |
| `before` | string | No | Cursor pagination |
| `after` | string | No | Cursor pagination |
| `limit` | integer | No | Default: 10 |

---

## Example: Referenced Refund Request

```bash
# Step 1 — retrieve the original payment
curl https://api.uat.payroc.com/v1/bank-transfer-payments/M2MJOG6O2Y \
  -H "Authorization: Bearer <access_token>"

# Step 2 — issue the referenced refund
curl -X POST https://api.uat.payroc.com/v1/bank-transfer-payments/M2MJOG6O2Y/refund \
  -H "Authorization: Bearer <access_token>" \
  -H "Idempotency-Key: f47ac10b-58cc-4372-a567-0e02b2c3d479" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected response: HTTP 200 with `bankTransferPayment` object; `transactionResult.type` = `"refund"`, `authorizedAmount` is negative.

---

## Example: Unreferenced Refund Request (ACH)

```bash
curl -X POST https://api.uat.payroc.com/v1/bank-transfer-refunds \
  -H "Authorization: Bearer <access_token>" \
  -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
  -H "Content-Type: application/json" \
  -d '{
    "processingTerminalId": "1234001",
    "order": {
      "orderId": "REFUND-OrderRef6543",
      "description": "Refund for order OrderRef6543",
      "amount": 4999,
      "currency": "USD"
    },
    "refundMethod": {
      "type": "ach",
      "accountNumber": "1234567890",
      "nameOnAccount": "Sarah Hazel Hopper",
      "routingNumber": "123456789",
      "accountType": "checking",
      "secCode": "web"
    },
    "customer": {
      "notificationLanguage": "en",
      "contactMethods": [{"type": "email", "value": "sarah.hopper@example.com"}]
    }
  }'
```

Expected response: HTTP 201 with `bankTransferRefund` object; `transactionResult.type` = `"unreferencedRefund"`.

---

## Response Status Codes

| Status | Meaning |
| --- | --- |
| 200 | Referenced refund created (returns `bankTransferPayment`); also the expected status for `POST .../reverse` (payment reversal) — note: the reversal endpoint is not listed separately in the spec status table; HTTP 200 is inferred by analogy |
| 201 | Unreferenced refund created (returns `bankTransferRefund`) |
| 400 | Validation error — check `errors[]` array |
| 401 | Authentication failed |
| 403 | Permission denied (unreferenced refunds require feature enablement) |
| 404 | Payment not found |
| 406 | Not acceptable |
| 409 | Conflict (idempotency key reused with different payload, or resource already exists) |
| 415 | Unsupported media type |
| 500 | Server error |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes these endpoints return: `400`, `401`, `403`, `404`, `406`, `409`, `415`, `500`.

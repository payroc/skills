# Verify Bank Account — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Payment Features / Bank Verification schema). Last synced: 2026-06-22. This is the offline source
> of truth this skill emits from — read enum values and required-field sets from here, not from memory.
> To refresh, re-fetch the source and regenerate this file (see [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & Path |
| --- | --- |
| Verify a bank account | `POST /v1/bank-accounts/verify` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

Full UAT endpoint: `POST https://api.uat.payroc.com/v1/bank-accounts/verify`
Full production endpoint: `POST https://api.payroc.com/v1/bank-accounts/verify`

---

## Required Request Headers

| Header | Value | Notes |
| --- | --- | --- |
| `Authorization` | `Bearer <access_token>` | Bearer token from identity service |
| `Idempotency-Key` | UUID v4 | Fresh UUID per distinct request |
| `Content-Type` | `application/json` | Required |

---

## Request Body

### Top-level fields

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `processingTerminalId` | string | Yes | Terminal identifier assigned by Payroc |
| `bankAccount` | object | Yes | Polymorphic bank account object — discriminated by `type` |

### bankAccount — `type` enum (discriminator)

| Value | Description |
| --- | --- |
| `ach` | Automated Clearing House (U.S. bank transfers) |
| `pad` | Pre-Authorized Debit (Canadian bank transfers) |

> **Read this file before emitting `type`.** Do not guess which types are supported or their casing.

### bankAccount — ACH (`type: "ach"`)

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | string | Yes | Must be exactly `"ach"` |
| `accountNumber` | string | Yes | Bank account number |
| `nameOnAccount` | string | Yes | Name on the bank account |
| `routingNumber` | string | Yes | 9-digit ABA routing number |
| `accountType` | enum | Optional | `"checking"` \| `"savings"` |
| `secCode` | enum | Optional* | `"web"` \| `"tel"` \| `"ccd"` \| `"ppd"` — mandatory for ACH payments (may be required here too — confirm against live spec) |

### bankAccount — PAD (`type: "pad"`)

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | string | Yes | Must be exactly `"pad"` |
| `accountNumber` | string | Yes | Bank account number |
| `nameOnAccount` | string | Yes | Name on the bank account |
| `transitNumber` | string | Yes | 5-digit branch/transit number |
| `institutionNumber` | string | Yes | 3-digit financial institution number |
| `accountType` | enum | Optional | `"checking"` \| `"savings"` |

---

## Enums

### bankAccount.type
`ach` | `pad`

### bankAccount.accountType
`checking` | `savings`

### bankAccount.secCode (ACH only)
`web` | `tel` | `ccd` | `ppd`

- `web` — internet-initiated
- `tel` — telephone-initiated
- `ccd` — Corporate Credit or Debit (business-to-business)
- `ppd` — Prearranged Payment and Deposit (consumer)

---

## Response Body

### HTTP 200 — Successful verification

```json
{
  "processingTerminalId": "string",
  "verified": boolean
}
```

| Field | Type | Description |
| --- | --- | --- |
| `processingTerminalId` | string | Echo of the terminal ID from the request |
| `verified` | boolean | `true` if the account details were verified; `false` if not |

> Note: `verified: false` is a **successful API call** — it means the bank account details did not pass
> verification. It is not an HTTP error. The 200 response itself indicates the verification operation
> completed; `verified` tells you the outcome.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes for these endpoints: `400`, `401`, `403`, `409`, `500`.

### Example 400 response

```json
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/bank-accounts/verify",
  "errors": [
    {
      "parameter": "bankAccount.routingNumber",
      "detail": "Invalid format",
      "message": "The 'routingNumber' field must be a 9-digit number"
    }
  ]
}
```

---

## Example Requests

### ACH verification

```json
{
  "processingTerminalId": "1234001",
  "bankAccount": {
    "type": "ach",
    "accountNumber": "11101010",
    "nameOnAccount": "Sarah Hazel Hopper",
    "routingNumber": "053200983",
    "accountType": "checking",
    "secCode": "web"
  }
}
```

### PAD verification

```json
{
  "processingTerminalId": "1234001",
  "bankAccount": {
    "type": "pad",
    "accountNumber": "11101010",
    "nameOnAccount": "Sarah Hazel Hopper",
    "transitNumber": "12345",
    "institutionNumber": "003",
    "accountType": "checking"
  }
}
```

---

## Example Response

```json
{
  "processingTerminalId": "1234001",
  "verified": true
}
```

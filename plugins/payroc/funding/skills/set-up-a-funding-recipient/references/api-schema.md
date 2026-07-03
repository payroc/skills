# Funding Recipients — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Funding Recipients schemas) and `https://docs.payroc.com/api/schema/funding/funding-recipients/`.
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read enum values
> and required-field sets from here, not from memory. To refresh, re-fetch the source and regenerate
> this file (see [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Create a funding recipient | `POST /v1/funding-recipients` |
| List funding recipients | `GET /v1/funding-recipients` |
| Retrieve a funding recipient | `GET /v1/funding-recipients/{recipientId}` |
| Update a funding recipient | `PUT /v1/funding-recipients/{recipientId}` |
| Delete a funding recipient | `DELETE /v1/funding-recipients/{recipientId}` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Enums

### recipientType

| Value | Description |
| --- | --- |
| `privateCorporation` | Private corporation |
| `publicCorporation` | Public corporation |
| `nonProfit` | Non-profit organisation |
| `government` | Government entity |
| `privateLlc` | Private LLC |
| `publicLlc` | Public LLC |
| `privatePartnership` | Private partnership |
| `publicPartnership` | Public partnership |
| `soleProprietor` | Sole proprietor |

### status (read-only — returned in response, not sent in request)

| Value | Description |
| --- | --- |
| `approved` | Verified and ready to receive funds |
| `rejected` | Did not pass verification checks (KYC failure) |
| `pending` | Awaiting review |
| `hold` | Temporarily flagged by Risk team |

### fundingAccount.type

| Value | Description |
| --- | --- |
| `checking` | Checking account |
| `savings` | Savings account |
| `generalLedger` | General ledger account |

### fundingAccount.use

| Value | Description |
| --- | --- |
| `credit` | Receive funds only — use this for funding recipients |
| `debit` | Withdraw funds only |
| `creditAndDebit` | Both credit and debit |

> **Important:** Funding recipients that accept incoming funds must use `credit` for the `use` field. Do not
> use `debit` or `creditAndDebit` for a funding recipient — those values are for different account types.

### contactMethod.type

| Value | Description |
| --- | --- |
| `email` | Email address |
| `phone` | Phone number |
| `mobile` | Mobile number |
| `fax` | Fax number |

At least one `email` contact method is required for both the recipient and each owner.

### identifier.type

| Value | Description |
| --- | --- |
| `nationalId` | National identifier — SSN (US) or SIN (Canada) |

### paymentMethod.type (inside fundingAccount)

| Value | Description |
| --- | --- |
| `ach` | ACH payment method — requires routingNumber and accountNumber |

---

## Create Funding Recipient — `POST /v1/funding-recipients`

### Required headers

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <access_token>` |
| `Idempotency-Key` | UUID v4 (fresh per distinct operation) |
| `Content-Type` | `application/json` |

### Request body schema

#### Top-level fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `recipientType` | enum | Yes | See `recipientType` enum above |
| `taxId` | string | Yes | EIN (Employer Identification Number) or SSN |
| `doingBusinessAs` | string | Yes | Legal name or trading name of the recipient entity |
| `address` | object | Yes | See address schema below |
| `contactMethods` | array | Yes | At least one `email` type required |
| `owners` | array | Yes | At least one owner required — see owner schema below |
| `fundingAccounts` | array | Yes | At least one funding account required — see schema below |
| `charityId` | string | No | Government-assigned charity identifier |
| `metadata` | object | No | Custom string key-value pairs (your internal reference data) |

#### Address object

| Field | Type | Required |
| --- | --- | --- |
| `address1` | string | Yes |
| `address2` | string | No |
| `address3` | string | No |
| `city` | string | Yes |
| `state` | string | Yes |
| `country` | string | Yes — ISO 3166-1 alpha-2 (e.g. `"US"`) |
| `postalCode` | string | Yes |

#### Owner object

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `firstName` | string | Yes | |
| `lastName` | string | Yes | |
| `middleName` | string | No | |
| `dateOfBirth` | string | Yes | Format: `YYYY-MM-DD` |
| `address` | object | Yes | Same address schema as above |
| `identifiers` | array | Yes | Must include `{type: "nationalId", value: "<SSN or SIN>"}` |
| `contactMethods` | array | Yes | At least one `email` required |
| `relationship` | object | Yes | See relationship schema below |

#### Owner relationship object

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `isControlProng` | boolean | Yes | Exactly one owner per recipient must be `true` |
| `equityPercentage` | number | No | Percentage of equity owned (0–100) |
| `title` | string | No | Job title |
| `isAuthorizedSignatory` | boolean | No | Whether this owner can sign on behalf of the entity |

#### Funding account object

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | enum | Yes | `checking`, `savings`, or `generalLedger` |
| `use` | enum | Yes | Must be `credit` for funding recipients |
| `nameOnAccount` | string | Yes | Name of the account holder |
| `paymentMethods` | array | Yes | Must include at least one ACH method (see below) |

#### ACH payment method (inside fundingAccount.paymentMethods)

```json
{
  "type": "ach",
  "value": {
    "routingNumber": "021000021",
    "accountNumber": "123456789"
  }
}
```

### Example request body

```json
{
  "recipientType": "privateCorporation",
  "taxId": "12-3456789",
  "doingBusinessAs": "Acme Supplies LLC",
  "address": {
    "address1": "100 Commerce St",
    "city": "Austin",
    "state": "TX",
    "country": "US",
    "postalCode": "78701"
  },
  "contactMethods": [
    { "type": "email", "value": "accounts@acmesupplies.com" },
    { "type": "phone", "value": "5125550100" }
  ],
  "owners": [
    {
      "firstName": "Jane",
      "lastName": "Doe",
      "dateOfBirth": "1980-04-15",
      "address": {
        "address1": "42 Oak Lane",
        "city": "Austin",
        "state": "TX",
        "country": "US",
        "postalCode": "78702"
      },
      "identifiers": [
        { "type": "nationalId", "value": "123-45-6789" }
      ],
      "contactMethods": [
        { "type": "email", "value": "jane.doe@example.com" }
      ],
      "relationship": {
        "isControlProng": true,
        "equityPercentage": 100,
        "title": "CEO",
        "isAuthorizedSignatory": true
      }
    }
  ],
  "fundingAccounts": [
    {
      "type": "checking",
      "use": "credit",
      "nameOnAccount": "Acme Supplies LLC",
      "paymentMethods": [
        {
          "type": "ach",
          "value": {
            "routingNumber": "021000021",
            "accountNumber": "987654321"
          }
        }
      ]
    }
  ]
}
```

---

## Response — 201 Created

| Field | Type | Notes |
| --- | --- | --- |
| `recipientId` | integer | System-assigned ID — save this for all subsequent operations |
| `status` | enum | `approved`, `rejected`, `pending`, or `hold` — depends on KYC outcome |
| `createdDate` | string | ISO 8601 timestamp |
| `lastModifiedDate` | string | ISO 8601 timestamp |
| `recipientType` | enum | Echo of submitted value |
| `taxId` | string | Echo of submitted value |
| `doingBusinessAs` | string | Echo of submitted value |
| `address` | object | Echo of submitted address |
| `contactMethods` | array | Echo of submitted contact methods |
| `owners` | array | Each owner entry includes `ownerId` (integer) and a HATEOAS link |
| `fundingAccounts` | array | Each account includes `fundingAccountId` (integer), `status`, and a HATEOAS link |
| `metadata` | object | Echo of submitted metadata |

> **Sensitive data masking:** Bank account numbers and routing numbers are partially masked in the response
> (shown as asterisks except for the last few digits). This is expected behaviour — do not treat this as a
> data error.

---

## Retrieve Funding Recipient — `GET /v1/funding-recipients/{recipientId}`

### Path parameters

| Parameter | Type | Required |
| --- | --- | --- |
| `recipientId` | integer | Yes |

### Required headers

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <access_token>` |

Returns a single `fundingRecipient` object (same shape as the 201 response).

---

## List Funding Recipients — `GET /v1/funding-recipients`

### Required headers

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <access_token>` |

### Query parameters (all optional)

| Parameter | Type | Notes |
| --- | --- | --- |
| `after` | string | Cursor for next page — cannot be combined with `before` |
| `before` | string | Cursor for previous page — cannot be combined with `after` |
| `limit` | integer | Results per page (default: 10) |

### Response (200)

Returns a `paginatedFundRecipients` object:

| Field | Type |
| --- | --- |
| `limit` | integer |
| `count` | integer |
| `hasMore` | boolean |
| `links` | array (pagination cursor links) |
| `data` | array of `fundingRecipient` objects |

---

## Update Funding Recipient — `PUT /v1/funding-recipients/{recipientId}`

**Method:** `PUT` (full replacement — all fields required, same schema as POST request body).

Returns **204 No Content** on success.

---

## Delete Funding Recipient — `DELETE /v1/funding-recipients/{recipientId}`

Returns **204 No Content** on success. The recipient and all associated funding accounts and owners are removed.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes these endpoints return: `400` (validation), `401` (auth/expired token), `403` (permissions — check API key scope), `404` (unknown `recipientId`), `406` (content negotiation — unsupported request format), `409` (resource already exists — a HATEOAS link to the existing recipient is returned), `500` (server — retry with backoff).

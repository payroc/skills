# Send Funds to a Merchant — API Schema Reference

> **Local snapshot — authoritative for this skill.** Sources: `https://docs.payroc.com/guides/fund-merchants/send-funds-to-your-merchants.md`, `https://docs.payroc.com/api/schema/funding/funding-instructions/create.md`, `https://docs.payroc.com/api/schema/funding/funding-instructions/retrieve.md`, `https://docs.payroc.com/api/schema/funding/funding-instructions/list.md`, `https://docs.payroc.com/api/schema/funding/funding-instructions/update.md`, `https://docs.payroc.com/api/schema/funding/funding-instructions/delete.md`, `https://docs.payroc.com/api/schema/funding/funding-activity/retrieve-balance.md`.
> Last synced: 2026-06-22. This is the offline source of truth — read enum values and schemas from here, not from memory.

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Check available balance | `GET /v1/funding-balance` |
| Create funding instruction | `POST /v1/funding-instructions` |
| Retrieve funding instruction | `GET /v1/funding-instructions/{instructionId}` |
| List funding instructions | `GET /v1/funding-instructions` |
| Update funding instruction | `PUT /v1/funding-instructions/{instructionId}` |
| Delete funding instruction | `DELETE /v1/funding-instructions/{instructionId}` |

UAT host: `https://api.uat.payroc.com`
Production host: `https://api.payroc.com`

---

## Enums

### paymentMethod (recipient payment method)

The only supported value is:

```
ACH
```

No other payment method values are documented or accepted.

### amount.currency

The only supported value is:

```
USD
```

Default is `USD`; the field is optional but must be `USD` if supplied.

### instruction status (read-only)

Returned by the API on funding instruction objects:

```
accepted   – received, not yet reviewed
pending    – under review
completed  – processing finished
```

### recipient status (read-only, per merchant/recipient)

Returned within the `merchants[].recipients[]` objects:

```
accepted   – instruction received, not yet reviewed
pending    – under review
released   – approved
funded     – ACH payment sent to the bank account
failed     – ACH payment failed
rejected   – instruction rejected after review
onHold     – instruction placed on hold
```

---

## Schemas

### GET /v1/funding-balance

**Required headers:**
- `Authorization: Bearer <token>`

**Query parameters (all optional):**

| Parameter | Type | Description |
| --- | --- | --- |
| `merchantId` | string | Filter results by processor-assigned merchant ID |
| `limit` | integer | Max results per page (default: 10) |
| `after` | string | Cursor for next page |
| `before` | string | Cursor for previous page |

Note: Do not use both `after` and `before` in the same request.

**Response (200):**

```json
{
  "limit": 10,
  "count": 1,
  "hasMore": false,
  "links": [
    { "rel": "self", "method": "GET", "href": "https://api.uat.payroc.com/v1/funding-balance" }
  ],
  "data": [
    {
      "merchantId": "MERCHANT-123",
      "funds": 100000,
      "pending": 20000,
      "available": 80000,
      "currency": "USD"
    }
  ]
}
```

Field descriptions:
- `funds` — total balance in lowest denomination (cents for USD)
- `pending` — funds not yet distributed
- `available` — usable funds available to create instructions

---

### POST /v1/funding-instructions

**Required headers:**

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <token>` |
| `Idempotency-Key` | UUID v4 (e.g. `f47ac10b-58cc-4372-a567-0e02b2c3d479`) |
| `Content-Type` | `application/json` |

**Request body schema:**

```json
{
  "merchants": [
    {
      "merchantId": "MERCHANT-123",
      "recipients": [
        {
          "fundingAccountId": 456,
          "paymentMethod": "ACH",
          "amount": {
            "value": 50000,
            "currency": "USD"
          },
          "metadata": {}
        }
      ]
    }
  ],
  "metadata": {}
}
```

Field-by-field breakdown:

| Path | Type | Required | Notes |
| --- | --- | --- | --- |
| `merchants` | array | Required | At least one merchant |
| `merchants[].merchantId` | string | Required | Processor-assigned merchant ID |
| `merchants[].recipients` | array | Required | At least one recipient |
| `merchants[].recipients[].fundingAccountId` | integer | Required | Funding account ID from the funding-recipients API |
| `merchants[].recipients[].paymentMethod` | enum | Required | Must be `ACH` — the only supported value |
| `merchants[].recipients[].amount` | object | Required | Amount to send |
| `merchants[].recipients[].amount.value` | integer | Required | Amount in lowest denomination (cents for USD) |
| `merchants[].recipients[].amount.currency` | enum | Optional | Defaults to `USD`; only `USD` is accepted |
| `merchants[].recipients[].metadata` | object | Optional | Custom key-value pairs |
| `metadata` | object | Optional | Custom key-value pairs at instruction level |

**Batch funding:** Multiple merchants and multiple recipients per merchant can be included in a single instruction (one POST).

**Response (201 Created):**

```json
{
  "instructionId": 789,
  "createdDate": "2026-06-22T10:00:00Z",
  "lastModifiedDate": "2026-06-22T10:00:00Z",
  "status": "accepted",
  "merchants": [
    {
      "merchantId": "MERCHANT-123",
      "recipients": [
        {
          "fundingAccountId": 456,
          "paymentMethod": "ACH",
          "amount": { "value": 50000, "currency": "USD" },
          "status": "accepted"
        }
      ]
    }
  ],
  "metadata": {}
}
```

Note: `instructionId` is an **integer**, not a string.

---

### GET /v1/funding-instructions/{instructionId}

**Path parameter:** `instructionId` — integer, required.

**Required headers:** `Authorization: Bearer <token>`

**Response (200):** Same schema as the POST 201 response above.

---

### GET /v1/funding-instructions

**Required headers:** `Authorization: Bearer <token>`

**Query parameters:**

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `dateFrom` | string (YYYY-MM-DD) | Required | Filter instructions on or after this date |
| `dateTo` | string (YYYY-MM-DD) | Required | Filter instructions on or before this date |
| `limit` | integer | Optional | Max results per page (default: 10) |
| `after` | string | Optional | Cursor for next page |
| `before` | string | Optional | Cursor for previous page |

Note: Cannot use both `after` and `before` in the same request. Date range is limited to the previous two years.

**Response (200):** Paginated list with `limit`, `count`, `hasMore`, `links`, and `data` (array of instruction objects).

---

### PUT /v1/funding-instructions/{instructionId}

**Constraint:** Only possible when the instruction's `status` is `accepted`. Fails with 409 if the instruction has already advanced beyond `accepted`.

**Required headers:**

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <token>` |
| `Content-Type` | `application/json` |

Note: The update endpoint does not require an `Idempotency-Key` header (it is a PUT, not a POST).

**Request body:** Same schema as the POST create body (`merchants` array required, `metadata` optional).

**Response (204 No Content):** Empty body on success.

---

### DELETE /v1/funding-instructions/{instructionId}

**Constraint:** Only possible when the instruction's `status` is `accepted`. Fails with 409 if the instruction has advanced.

**Required headers:** `Authorization: Bearer <token>`

**Response (204 No Content):** Empty body on success.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes these endpoints return: `400` (validation), `401` (auth/expired token), `403` (permissions — missing funding scope), `404` (unknown `instructionId`), `406` (content negotiation — unsupported `Accept`), `409` (duplicate idempotency key, or update/delete of a non-`accepted` instruction), `500` (server — retry with backoff).

Example validation error on `POST /v1/funding-instructions`:

```json
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/funding-instructions",
  "errors": [
    {
      "parameter": "merchants",
      "detail": "Required field not populated",
      "message": "'merchants' must not be empty."
    }
  ]
}
```

# ACH Deposits — API Schema Reference

> **Local snapshot — authoritative for this skill.** Sources: `https://docs.payroc.com/api/schema/reporting/settlement/list-ach-deposits.md`,
> `https://docs.payroc.com/api/schema/reporting/settlement/retrieve-ach-deposit.md`,
> `https://docs.payroc.com/api/schema/reporting/settlement/list-ach-deposit-fees.md`.
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read field names,
> enum values, and required-field sets from here, not from memory. To refresh, re-fetch the source URLs
> and regenerate this file (see [`_sources.md`](./_sources.md)).

ACH Deposits is a read-only reporting API — all three endpoints are `GET` requests. No request body, no
idempotency key required (GET operations are idempotent by definition).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| List ACH deposits | `GET /v1/ach-deposits` |
| Retrieve an ACH deposit | `GET /v1/ach-deposits/{achDepositId}` |
| List ACH deposit fees | `GET /v1/ach-deposit-fees` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Required headers (all three endpoints)

| Header | Required | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | Yes | Token from the Payroc identity service; expires in 3600 s |

No `Content-Type` or `Idempotency-Key` required — these are GET requests with no request body.

---

## GET /v1/ach-deposits — List ACH deposits

### Query parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `date` | string (YYYY-MM-DD) | **Yes** | Filter results by the date that the merchant received the ACH deposit. |
| `merchantId` | string | No | Filter by the unique identifier that the processor assigned to the merchant. |
| `limit` | integer | No | Maximum number of results per page. Default: 10. |
| `after` | string | No | Cursor — return the next page of results after this value. Cannot be combined with `before`. |
| `before` | string | No | Cursor — return the previous page of results before this value. Cannot be combined with `after`. |

> **`date` is mandatory.** Requests without it receive a `400` validation error.

### Response (HTTP 200)

Paginated list envelope:

| Field | Type | Description |
| --- | --- | --- |
| `limit` | integer | Maximum results per page |
| `count` | integer | Number of results on this page (not the total) |
| `hasMore` | boolean | Whether another page of results exists |
| `links` | array | HATEOAS navigation links (previous/next pages) |
| `data` | array | Array of `achDeposit` objects |

### achDeposit object

| Field | Type | Description |
| --- | --- | --- |
| `achDepositId` | integer | Unique identifier assigned to this ACH deposit |
| `associationDate` | string (YYYY-MM-DD) | Date that Payroc sent the transactions to the card brands for clearing |
| `achDate` | string (YYYY-MM-DD) | Date that Payroc sent the ACH deposit |
| `paymentDate` | string (YYYY-MM-DD) | Date that the merchant received the ACH deposit |
| `transactions` | integer | Number of transactions in the deposit |
| `sales` | integer (int64) | Total sales amount (lowest currency denomination, e.g. cents) |
| `returns` | integer (int64) | Total returns amount (lowest currency denomination) |
| `dailyFees` | integer (int64) | Fees applied to the transactions (lowest denomination) |
| `heldSales` | integer (int64) | Amount held if the merchant was in full suspense |
| `achAdjustment` | integer (int64) | Adjustments applied to the deposit |
| `holdback` | integer (int64) | Reserve funds held back from the deposit |
| `reserveRelease` | integer (int64) | Reserve funds released from holdback |
| `netAmount` | integer (int64) | Total paid to the merchant after fees and adjustments |
| `merchant` | object | Merchant summary — see below |
| `links` | array | Related resource links (e.g. link to achDepositFees for this deposit) |

### merchant summary object (inside achDeposit)

| Field | Type | Description |
| --- | --- | --- |
| `merchantId` | string | Processor-assigned merchant identifier |
| `doingBusinessAs` | string | Merchant's trading name |
| `processingAccountId` | integer | Processing account identifier |
| `link` | object | HATEOAS link to the full merchant record |

### Example response (List ACH deposits)

```json
{
  "limit": 10,
  "count": 1,
  "hasMore": false,
  "links": [],
  "data": [
    {
      "achDepositId": 99,
      "associationDate": "2024-07-02",
      "achDate": "2024-07-02",
      "paymentDate": "2024-07-02",
      "transactions": 10,
      "sales": 50000,
      "returns": 10000,
      "dailyFees": 1000,
      "heldSales": 1000,
      "achAdjustment": 1000,
      "holdback": 1000,
      "reserveRelease": 500,
      "netAmount": 36500,
      "merchant": {
        "merchantId": "4525644354",
        "doingBusinessAs": "Pizza Doe",
        "processingAccountId": 38765,
        "link": {
          "rel": "merchant",
          "href": "https://api.uat.payroc.com/v1/merchants/4525644354"
        }
      },
      "links": [
        {
          "rel": "achDepositFees",
          "href": "https://api.uat.payroc.com/v1/ach-deposit-fees?achDepositId=99"
        }
      ]
    }
  ]
}
```

---

## GET /v1/ach-deposits/{achDepositId} — Retrieve a specific ACH deposit

### Path parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `achDepositId` | integer | **Yes** | The unique identifier of the ACH deposit to retrieve |

### Response (HTTP 200)

Returns a single `achDeposit` object — same shape as items in the `data` array above.

### Error codes

| Status | Description |
| --- | --- |
| 400 | Validation error |
| 401 | Identity could not be verified |
| 403 | Insufficient permissions |
| 404 | ACH deposit not found |
| 406 | Not acceptable |
| 500 | Server error |

### Example request

```
GET https://api.uat.payroc.com/v1/ach-deposits/99
Authorization: Bearer <token>
```

### Example response

```json
{
  "achDepositId": 99,
  "associationDate": "2024-07-02",
  "achDate": "2024-07-02",
  "paymentDate": "2024-07-02",
  "transactions": 10,
  "sales": 50000,
  "returns": 10000,
  "dailyFees": 1000,
  "heldSales": 1000,
  "achAdjustment": 1000,
  "holdback": 1000,
  "reserveRelease": 500,
  "netAmount": 36500,
  "merchant": {
    "merchantId": "4525644354",
    "doingBusinessAs": "Pizza Doe",
    "processingAccountId": 38765,
    "link": {
      "rel": "merchant",
      "href": "https://api.uat.payroc.com/v1/merchants/4525644354"
    }
  },
  "links": [
    {
      "rel": "achDepositFees",
      "href": "https://api.uat.payroc.com/v1/ach-deposit-fees?achDepositId=99"
    }
  ]
}
```

---

## GET /v1/ach-deposit-fees — List ACH deposit fees

### Query parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `date` | string (YYYY-MM-DD) | Conditional | Date to retrieve fee results from. Either `date` **or** `achDepositId` must be provided. |
| `achDepositId` | integer | Conditional | Unique identifier of the ACH deposit. Either `achDepositId` **or** `date` must be provided. |
| `merchantId` | string | No | Filter by the processor-assigned merchant identifier. |
| `limit` | integer | No | Maximum results per page. Default: 10. |
| `after` | string | No | Cursor — return the next page of results after this value. Cannot be combined with `before`. |
| `before` | string | No | Cursor — return the previous page of results before this value. Cannot be combined with `after`. |

> **Either `date` or `achDepositId` must be provided.** Providing neither returns a `400` error. Providing both is valid (and narrows results to that deposit on that date). Providing `after` and `before` simultaneously is not supported — use one or the other for pagination direction.

### Response (HTTP 200)

Paginated list envelope (same structure as List ACH deposits):

| Field | Type | Description |
| --- | --- | --- |
| `limit` | integer | Maximum results per page |
| `count` | integer | Number of results on this page (not the total) |
| `hasMore` | boolean | Whether another page exists |
| `links` | array | HATEOAS navigation links |
| `data` | array | Array of `achDepositFee` objects |

### achDepositFee object

| Field | Type | Description |
| --- | --- | --- |
| `associationDate` | string (YYYY-MM-DD) | Date that the transaction was sent to card brands for clearing (transaction-level — distinct from the batch-level `associationDate` on the parent `achDeposit`) |
| `adjustmentDate` | string (YYYY-MM-DD) | Date of the adjustment |
| `description` | string | Human-readable description of the fee |
| `amount` | integer | Total value of the ACH deposit fee (lowest currency denomination) |
| `merchant` | object | Merchant summary (merchantId, doingBusinessAs, processingAccountId, link) |
| `achDeposit` | object | Contains `achDepositId` (integer) and a `link` object (HATEOAS link to the parent deposit). Access the parent ID as `fee.achDeposit.achDepositId` — it is NOT a top-level field on the fee object. |

### Example response (List ACH deposit fees)

```json
{
  "limit": 10,
  "count": 1,
  "hasMore": false,
  "links": [],
  "data": [
    {
      "associationDate": "2024-07-02",
      "adjustmentDate": "2024-07-02",
      "description": "Interchange fee",
      "amount": 150,
      "merchant": {
        "merchantId": "4525644354",
        "doingBusinessAs": "Pizza Doe",
        "processingAccountId": 38765,
        "link": {
          "rel": "merchant",
          "href": "https://api.uat.payroc.com/v1/merchants/4525644354"
        }
      },
      "achDeposit": {
        "achDepositId": 99,
        "link": {
          "rel": "achDeposit",
          "href": "https://api.uat.payroc.com/v1/ach-deposits/99"
        }
      }
    }
  ]
}
```

> **Nesting note:** `achDeposit.achDepositId` is nested inside the `achDeposit` object — not at the top level of the fee record. Access it as `fee.achDeposit.achDepositId`, not `fee.achDepositId`. Similarly, `merchant.link` is a **singular `link` object** (not a `links` array) — access it as `fee.merchant.link.href`.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

These are read/reporting (GET) endpoints, so the typical status set is `400` (invalid query params), `401` (auth), `403` (permissions), `404` (unknown `achDepositId`, retrieve endpoint only), `406` (content negotiation), and `500` (server).

```json
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/ach-deposits",
  "errors": [
    {
      "parameter": "date",
      "detail": "Required field not populated",
      "message": "The 'date' field is required"
    }
  ]
}
```

| Error status | Scenario |
| --- | --- |
| 400 | Validation error — missing required parameter, invalid date format, both `before` and `after` sent together |
| 401 | Bearer token missing, expired, or invalid |
| 403 | API key lacks permission to access this endpoint |
| 404 | `achDepositId` not found (retrieve endpoint only) |
| 406 | Not acceptable (Accept header mismatch) |
| 500 | Server error — known to occur intermittently in UAT; retry with backoff |

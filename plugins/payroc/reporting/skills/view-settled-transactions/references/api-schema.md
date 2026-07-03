# View Settled Transactions — API Schema Reference

> **Local snapshot — authoritative for this skill.** Sources: `https://docs.payroc.com/api/schema/reporting/settlement/list-batches.md`, `https://docs.payroc.com/api/schema/reporting/settlement/retrieve-batch.md`, `https://docs.payroc.com/api/schema/reporting/settlement/list-transactions.md`, `https://docs.payroc.com/api/schema/reporting/settlement/retrieve-transaction.md`
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read enum values and required-field sets from here, not from memory. To refresh, re-fetch the source URLs and regenerate this file (see [`_sources.md`](./_sources.md)).

The settled-transactions reporting surface is a read-only REST/JSON API. Every enum value and schema below comes from the official docs.

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| List settlement batches | `GET /v1/batches` |
| Retrieve a batch | `GET /v1/batches/{batchId}` |
| List transactions in a batch | `GET /v1/transactions` |
| Retrieve a single transaction | `GET /v1/transactions/{transactionId}` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

> **Note:** Transactions in the Reporting API are settled transactions. These are different from the payment objects in the Payments API (`GET /payments`). Settlement transactions represent settled ledger entries, not live payment state.

---

## Authentication

All endpoints require a Bearer token in the `Authorization` header. See `references/identity-call.md` for token exchange details.

```text
Authorization: Bearer <access_token>
```

These are GET (read-only) endpoints — no `Idempotency-Key` header is required.

---

## GET /v1/batches — List Settlement Batches

### Query Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `date` | string (YYYY-MM-DD) | **Yes** | Filter batches by the date they were submitted |
| `merchantId` | string | No | Filter by processor-assigned merchant identifier |
| `limit` | integer | No | Max results per page (default: 10) |
| `after` | string | No | Pagination cursor — next page. Cannot be combined with `before` |
| `before` | string | No | Pagination cursor — previous page. Cannot be combined with `after` |

### Response Schema (200 OK)

```json
{
  "limit": 10,
  "count": 2,
  "hasMore": false,
  "links": [
    { "rel": "string", "method": "get", "href": "string" }
  ],
  "data": [
    {
      "batchId": 65,
      "date": "2025-03-14",
      "createdDate": "2025-03-14",
      "lastModifiedDate": "2025-03-14",
      "saleAmount": 125000,
      "heldAmount": 0,
      "returnAmount": 5000,
      "transactionCount": 12,
      "currency": "USD",
      "merchant": {
        "merchantId": "string",
        "doingBusinessAs": "Acme Corp",
        "processingAccountId": 9815,
        "link": { "rel": "processingAccount", "method": "get", "href": "https://api.payroc.com/v1/processing-accounts/9815" }
      },
      "links": [
        { "rel": "transactions", "method": "get", "href": "https://api.payroc.com/v1/transactions?batchId=65" },
        { "rel": "authorizations", "method": "get", "href": "https://api.payroc.com/v1/authorizations?batchId=65" }
      ]
    }
  ]
}
```

**Key fields:**
- `batchId` — integer ID, use it to query transactions via `GET /v1/transactions?batchId={batchId}`
- `saleAmount`, `heldAmount`, `returnAmount` — amounts in lowest currency denomination (e.g. cents)
- `transactionCount` — number of settled transactions in the batch
- `links[].rel == "transactions"` — HATEOAS link to the transactions for this batch

---

## GET /v1/batches/{batchId} — Retrieve a Batch

### Path Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `batchId` | integer | **Yes** | Unique identifier assigned to the batch |

### Response Schema (200 OK)

Same shape as a single batch object from the list response (see above).

---

## GET /v1/transactions — List Settled Transactions

### Query Parameters

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| `date` | string (YYYY-MM-DD) | Conditional | Filter by batch submission date. **Either `date` or `batchId` is required.** |
| `batchId` | integer | Conditional | Filter by batch ID. **Either `date` or `batchId` is required.** |
| `merchantId` | string | No | Filter by processor-assigned merchant identifier |
| `transactionType` | string (enum) | No | See enum values below |
| `limit` | integer | No | Max results per page (default: 10) |
| `after` | string | No | Pagination cursor — next page. Cannot be combined with `before` |
| `before` | string | No | Pagination cursor — previous page. Cannot be combined with `after` |

> **Either `date` or `batchId` must be supplied.** A request without either will be rejected.

### Enum: `transactionType`

> **Read this list before emitting a `transactionType` value. Do not guess.**

| Value | Meaning |
| --- | --- |
| `Capture` | A settled sale/capture transaction |
| `Return` | A settled return/refund transaction |

Note: the values are title-case (`Capture`, `Return`) — not lowercase.

### Response Schema (200 OK)

```json
{
  "limit": 10,
  "count": 5,
  "hasMore": false,
  "links": [
    { "rel": "string", "method": "get", "href": "string" }
  ],
  "data": [
    {
      "transactionId": 12345,
      "type": "capture",
      "date": "2025-03-14",
      "amount": 10000,
      "entryMethod": "ecommerce",
      "createdDate": "2025-03-14",
      "lastModifiedDate": "2025-03-14",
      "status": "paid",
      "cashbackAmount": 0,
      "interchange": {
        "basisPoint": 150,
        "transactionFee": 10
      },
      "currency": "USD",
      "merchant": {
        "merchantId": "string",
        "doingBusinessAs": "Acme Corp",
        "processingAccountId": 9815,
        "link": { "rel": "processingAccount", "method": "get", "href": "string" }
      },
      "settled": {
        "settledBy": "string",
        "achDate": "2025-03-15",
        "achDepositId": 789,
        "link": { "rel": "achDeposit", "method": "get", "href": "string" }
      },
      "batch": {
        "batchId": 65,
        "date": "2025-03-14",
        "cycle": 1,
        "link": { "rel": "batch", "method": "get", "href": "string" }
      },
      "card": {
        "cardNumber": "411111XXXXXX1111",
        "type": "visa",
        "cvvPresenceIndicator": "string",
        "avsRequest": "string",
        "avsResponse": "string"
      },
      "authorization": {
        "authorizationId": 99001,
        "code": "ABC123",
        "amount": 10000,
        "avsResponseCode": "Y",
        "link": { "rel": "authorization", "method": "get", "href": "string" }
      }
    }
  ]
}
```

### Enum: `type` (on transaction object, read-only)

> **Read-only field returned by the API. Do not emit this value in requests.**

| Value | Meaning |
| --- | --- |
| `capture` | Settled sale/capture |
| `return` | Settled return/refund |

Note: response uses lowercase (`capture`, `return`); the query parameter `transactionType` uses title-case (`Capture`, `Return`).

### Enum: `entryMethod` (on transaction object, read-only)

> **Read-only field returned by the API.**

`barcodeRead` | `smartChipRead` | `swipedOriginUnknown` | `contactlessChip` | `ecommerce` | `manuallyEntered` | `manuallyEnteredFallback` | `swiped` | `swipedFallback` | `swipedError` | `scannedCheckReader` | `credentialOnFile` | `unknown`

### Enum: `status` (on transaction object, read-only)

> **Read-only field returned by the API.**

`fullSuspense` | `heldAudited` | `heldReleasedAudited` | `holdForSettlement30Days` | `holdForSettlementDuplicate` | `holdLongTerm` | `paid` | `paidByThirdParty` | `partialRelease` | `pull` | `release` | `new` | `held` | `unknown`

### Enum: `card.type` (on transaction object, read-only)

> **Read-only field returned by the API.**

`visa` | `masterCard` | `discover` | `debit` | `ebt` | `wrightExpress` | `voyager` | `amex` | `privateLabel` | `storedValue` | `discoverRetained` | `jcbNonSettled` | `dinersClub` | `amexOptBlue` | `fuelman` | `unknown`

---

## GET /v1/transactions/{transactionId} — Retrieve a Single Transaction

### Path Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `transactionId` | integer | **Yes** | Unique identifier assigned to the transaction |

### Response Schema (200 OK)

Same shape as a single transaction object from the list response (see above).

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

These are read/reporting (GET) endpoints, so the typical status set is `400` (invalid query params), `401` (auth), `403` (permissions), `404` (unknown `batchId` or `transactionId`, retrieve endpoints only), `406` (content negotiation), and `500` (server).

```json
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/transactions",
  "errors": [
    { "parameter": "date", "detail": "Required field not populated", "message": "Either 'date' or 'batchId' must be provided" }
  ]
}
```

---

## Notes on Data Freshness

- Settlement transactions are posted as batches close. Querying by `date` returns batches (and via HATEOAS, transactions) that settled on that calendar date.
- `transactionId` may be `null` for some transaction types — handle this defensively in code.
- The `settled` object on each transaction includes `achDate` and `achDepositId` for linking to ACH deposit records.
- Amounts are always in the lowest denomination of the currency (e.g. cents for USD, pence for GBP).

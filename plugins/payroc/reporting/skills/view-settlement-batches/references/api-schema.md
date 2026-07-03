# Settlement Batches — API Schema Reference

> **Local snapshot — authoritative for this skill.** Sources:
> `https://docs.payroc.com/api/schema/reporting/settlement/list-batches.md`
> `https://docs.payroc.com/api/schema/reporting/settlement/retrieve-batch.md`
> Last synced: 2026-06-22. This is the offline source of truth this skill emits
> from — read enum values, field names, and required-field sets from here, not from memory.
> To refresh, re-fetch the source URLs and regenerate this file (see [`_sources.md`](./_sources.md)).

Settlement batches are daily groupings of card transactions submitted to the card processor for
settlement. Each batch covers one merchant on one date. Amounts are integers in the lowest
currency denomination (e.g. cents for USD).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| List batches | `GET /v1/batches` |
| Retrieve a batch | `GET /v1/batches/{batchId}` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## GET /v1/batches — List batches

### Required headers

| Header | Notes |
| --- | --- |
| `Authorization: Bearer <token>` | Bearer token from the identity service |

### Query parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `date` | string (`YYYY-MM-DD`) | **Yes** | Filter batches by the date that they were submitted |
| `merchantId` | string | No | Filter results by the unique identifier that the processor assigned to the merchant |
| `limit` | integer | No | Maximum results per page (default: 10) |
| `after` | string | No | Return the next page of results after the value specified (cursor-based pagination) |
| `before` | string | No | Return the previous page of results before the value specified (cursor-based pagination) |

> **Note:** `before` and `after` are mutually exclusive — do not send both in the same request.

> **Note:** `date` is required. Requests without a `date` parameter will fail with a 400 validation error.

### Response schema (200)

The response is a paginated list object:

| Field | Type | Description |
| --- | --- | --- |
| `limit` | integer | Maximum results per page |
| `count` | integer | Number of results on this page (not the total) |
| `hasMore` | boolean | Whether another page of results exists |
| `links` | array | Pagination navigation links |
| `data` | array of batch objects | The batch records |

Each **batch object** in `data`:

| Field | Type | Description |
| --- | --- | --- |
| `batchId` | integer | Unique identifier Payroc assigned to the batch |
| `date` | string (`YYYY-MM-DD`) | Date the batch was submitted to the processor |
| `createdDate` | string (`YYYY-MM-DD`) | Date the batch record was created |
| `lastModifiedDate` | string (`YYYY-MM-DD`) | Date the batch record was last modified |
| `saleAmount` | integer | Total sales value in the lowest currency denomination (e.g. cents) |
| `heldAmount` | integer | Total authorization (held) value in the lowest currency denomination |
| `returnAmount` | integer | Total returns value in the lowest currency denomination |
| `transactionCount` | integer | Number of transactions in the batch |
| `currency` | string | ISO 4217 currency code (e.g. `"USD"`, `"GBP"`) |
| `merchant` | object | Merchant summary — see below |
| `links` | array | HATEOAS links to related resources (transactions, authorizations) |

**Merchant summary object** (nested inside each batch):

| Field | Type | Description |
| --- | --- | --- |
| `merchantId` | string | Unique identifier the processor assigned to the merchant |
| `doingBusinessAs` | string | The merchant's DBA (trading) name |
| `processingAccountId` | integer | Payroc processing account identifier |
| `link` | object | HATEOAS link — `{ rel, method, href }` |

### Example response — List batches (200)

```json
{
  "limit": 10,
  "count": 1,
  "hasMore": false,
  "links": [],
  "data": [
    {
      "batchId": 65,
      "date": "2024-07-02",
      "createdDate": "2024-07-02",
      "lastModifiedDate": "2024-07-02",
      "saleAmount": 100,
      "heldAmount": 0,
      "returnAmount": 0,
      "transactionCount": 10,
      "currency": "USD",
      "merchant": {
        "merchantId": "4525644354",
        "doingBusinessAs": "Pizza Doe",
        "processingAccountId": 38765,
        "link": {
          "rel": "self",
          "method": "GET",
          "href": "https://api.payroc.com/v1/processing-accounts/38765"
        }
      },
      "links": [
        {
          "rel": "transactions",
          "method": "GET",
          "href": "https://api.payroc.com/v1/transactions?batchId=65"
        }
      ]
    }
  ]
}
```

---

## GET /v1/batches/{batchId} — Retrieve a batch

### Path parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `batchId` | integer | **Yes** | Unique identifier that Payroc assigned to the batch |

### Required headers

| Header | Notes |
| --- | --- |
| `Authorization: Bearer <token>` | Bearer token from the identity service |

### Response schema (200)

Returns a single batch object with the same shape as each item in the `data` array of the list
response — see fields above.

### Example response — Retrieve batch (200)

```json
{
  "batchId": 65,
  "date": "2024-07-02",
  "createdDate": "2024-07-02",
  "lastModifiedDate": "2024-07-02",
  "saleAmount": 100,
  "heldAmount": 0,
  "returnAmount": 0,
  "transactionCount": 10,
  "currency": "USD",
  "merchant": {
    "merchantId": "4525644354",
    "doingBusinessAs": "Pizza Doe",
    "processingAccountId": 38765,
    "link": {
      "rel": "self",
      "method": "GET",
      "href": "https://api.payroc.com/v1/processing-accounts/38765"
    }
  },
  "links": [
    {
      "rel": "transactions",
      "method": "GET",
      "href": "https://api.payroc.com/v1/transactions?batchId=65"
    }
  ]
}
```

---

## Response codes

| Status | Description |
| --- | --- |
| `200` | Success |
| `400` | Validation error — check the `errors[]` array for the failing parameter |
| `401` | Authentication failed — Bearer token missing, expired, or invalid |
| `403` | Insufficient permissions — API key scope does not cover reporting |
| `404` | Batch not found (retrieve only) — `batchId` does not exist |
| `406` | Not acceptable |
| `500` | Server error — retry with exponential backoff |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

These are read/reporting (GET) endpoints, so the typical status set is `400` (invalid query params), `401` (auth), `403` (permissions), `404` (unknown `batchId`, retrieve endpoint only), `406` (content negotiation), and `500` (server).

---

## Key facts and constraints

- **`date` is required for list** — the list endpoint will not return results without a `date` query parameter.
- **`batchId` is an integer** — not a string. Do not wrap it in quotes.
- **Amounts are in lowest denomination** — `saleAmount: 100` means $1.00 (100 cents), not $100.
- **Pagination is cursor-based** — use `after`/`before` with the cursor values from the `links` array; do not use offset pagination.
- **`before` and `after` are mutually exclusive** — sending both causes a 400.
- **No `Idempotency-Key` required** — these are GET requests; idempotency keys are only required for POST/PATCH.
- **UAT data may be sparse** — periodic data wipes in the UAT environment mean batch records from earlier dates may not exist; use a recent date when testing.
- **Retrieve may 404 for recently-seen batches** — the UAT environment wipes data periodically, so `GET /v1/batches/{batchId}` may return 404 even for a batch that existed earlier in the same session. This is expected UAT behaviour, not a production limitation.

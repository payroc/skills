# Funding Activity — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Funding Activity schemas: `funding_fundingActivity_*`, `merchantBalance`, `activityRecord`, `ActivityRecordType`).
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read enum values
> and required-field sets from here, not from memory. To refresh, re-fetch the source and regenerate
> this file (see [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| List funding balances | `GET /v1/funding-balance` |
| List funding activity | `GET /v1/funding-activity` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## GET /v1/funding-balance — List Funding Balances

Returns a paginated list of funding balances available for each merchant linked to your account.
Shows total, available, and pending amounts for each merchant.

### Query parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `merchantId` | string | No | Filter by the unique identifier the processor assigned to the merchant |
| `limit` | integer | No | Maximum results per page (default: `10`) |
| `after` | string | No | Cursor for the next page — cannot be used with `before` |
| `before` | string | No | Cursor for the previous page — cannot be used with `after` |

### Required headers

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <access_token>` |

### Response — 200 OK

Schema: `funding_fundingActivity_retrieveBalance_Response_200`

```json
{
  "limit": 10,
  "count": 2,
  "hasMore": false,
  "links": [...],
  "data": [
    {
      "merchantId": "123456",
      "funds": 150000,
      "pending": 50000,
      "available": 100000,
      "currency": "USD"
    }
  ]
}
```

### merchantBalance schema

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `merchantId` | string | — | Unique identifier the processor assigned to the merchant |
| `funds` | integer | — | Total funding balance including pending amounts (lowest denomination, e.g. cents) |
| `pending` | integer | — | Amount not yet sent to funding accounts (lowest denomination) |
| `available` | integer | — | Amount available for use in funding instructions (lowest denomination) |
| `currency` | string | — | Currency of the funding balance. Returns `"USD"` |

---

## GET /v1/funding-activity — List Funding Activity

Returns a paginated list of activity associated with merchants' funding balances within a specific date range.

### Query parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `dateFrom` | string (`YYYY-MM-DD`) | **Yes** | Start date for activity filter |
| `dateTo` | string (`YYYY-MM-DD`) | **Yes** | End date for activity filter |
| `merchantId` | string | No | Filter by the unique identifier the processor assigned to the merchant |
| `limit` | integer | No | Maximum results per page (default: `10`) |
| `after` | string | No | Cursor for the next page — cannot be used with `before` |
| `before` | string | No | Cursor for the previous page — cannot be used with `after` |

> **Important:** `dateFrom` and `dateTo` are **required** query parameters for the funding activity endpoint.
> Requests without them will return a `400` validation error.

### Required headers

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <access_token>` |

### Response — 200 OK

Schema: `funding_fundingActivity_list_Response_200`

```json
{
  "limit": 10,
  "count": 3,
  "hasMore": false,
  "links": [...],
  "data": [
    {
      "id": 98765,
      "date": "2026-06-15T14:30:00Z",
      "merchant": "Acme Corp",
      "description": "Sales",
      "amount": 150000,
      "type": "credit",
      "currency": "USD"
    },
    {
      "id": 98766,
      "date": "2026-06-15T16:00:00Z",
      "merchant": "Acme Corp",
      "recipient": "First National Bank",
      "description": "Funding instruction payout",
      "amount": 100000,
      "type": "debit",
      "currency": "USD"
    }
  ]
}
```

### activityRecord schema

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `id` | integer | Yes | Unique identifier assigned to the activity |
| `date` | string (datetime) | Yes | Date/time that funds were moved (ISO 8601) |
| `merchant` | string | Yes | Doing Business As (DBA) name of the merchant that owns the funding balance |
| `description` | string | Yes | Description of the activity |
| `amount` | integer (int64) | Yes | Total amount removed or added to the merchant's funding balance (lowest denomination, e.g. cents) |
| `type` | enum (`ActivityRecordType`) | Yes | Whether funds were added (`credit`) or removed (`debit`) |
| `currency` | string | Yes | Currency of the funds. Returns `"USD"` |
| `recipient` | string | Conditional | Name of the account holder who owns the funding account that received funds. **Only returned when `type` is `debit`** |

---

## Enums

### ActivityRecordType (activityRecord.type)

`credit` | `debit`

- `credit` — funds were moved **into** the funding balance (e.g. settlement of sales).
- `debit` — funds were moved **out of** the funding balance (e.g. a funding instruction payout).

> **Read this enum from this file before emitting.** Do not guess — `credit`/`debit` are the exact documented values. Do not use `Credit`/`Debit` (capitalized), `CREDIT`/`DEBIT`, or any other variant.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes these endpoints return: `400` (validation — e.g. `dateFrom`/`dateTo` missing or malformed on `/funding-activity`), `401` (auth/expired token), `403` (permissions), `406` (content negotiation — unsupported `Accept`), `500` (server — retry with backoff).

---

## Pagination

Both endpoints use cursor-based pagination:

| Field | Description |
| --- | --- |
| `limit` | Maximum results returned per page |
| `count` | Actual number of results on this page |
| `hasMore` | `true` if more pages exist |
| `links` | HATEOAS navigation links (next/previous page cursors) |

To page forward, take the cursor from `links` and pass it as the `after` parameter.
To page backward, pass the cursor as the `before` parameter.
Do **not** pass both `after` and `before` in the same request.

### links array structure

Each entry in `links` is an object with three fields:

| Field | Type | Description |
| --- | --- | --- |
| `rel` | string | Relation — `"next"` for the next page, `"prev"` for the previous page |
| `method` | string | HTTP method — always `"GET"` for pagination links |
| `href` | string | Full URL of the next/previous page, including all query parameters |

Example response with a next-page link (when `hasMore: true`):

```json
{
  "limit": 10,
  "count": 10,
  "hasMore": true,
  "links": [
    { "rel": "next", "method": "GET", "href": "https://api.uat.payroc.com/v1/funding-activity?after=<cursor>&dateFrom=2026-06-01&dateTo=2026-06-22" }
  ],
  "data": [ ... ]
}
```

**To extract the cursor:** find the link where `rel` is `"next"`, then either:

- Use the full `href` URL directly as the next request URL (all required parameters are already included), or
- Parse the `after` query parameter from `href` and pass it explicitly.

When `hasMore` is `false`, the `links` array will be empty (`[]`).

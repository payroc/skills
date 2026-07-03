# View Disputes — API Schema Reference

> **Local snapshot — authoritative for this skill.** Sources: `https://docs.payroc.com/openapi.yml`
> (disputes schemas) and `https://docs.payroc.com/api/schema/reporting/settlement/list-disputes.md`,
> `https://docs.payroc.com/api/schema/reporting/settlement/list-disputes-statuses.md`.
> Last synced: 2026-06-22. This is the offline source of truth this skill emits from — read enum
> values and schema details from here, not from memory. To refresh, re-fetch the source URLs and
> regenerate this file (see [`_sources.md`](./_sources.md)).

Disputes is a read-only reporting surface — `GET` only, no mutation. Disputes are submitted by
cardholders via their issuing bank; Payroc's reporting API lets you list disputes and retrieve
their status history.

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| List disputes | `GET /v1/disputes` |
| List dispute statuses | `GET /v1/disputes/{disputeId}/statuses` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

Full endpoint examples:
- `GET https://api.uat.payroc.com/v1/disputes?date=2024-02-01`
- `GET https://api.uat.payroc.com/v1/disputes/{disputeId}/statuses`

---

## Authentication

All endpoints require a Bearer token in the `Authorization` header. See `references/identity-call.md`
for the token exchange endpoint and exact request/response shape.

```
Authorization: Bearer <access_token>
```

---

## GET /v1/disputes — List Disputes

### Query Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `date` | string (YYYY-MM-DD) | **Yes** | Filter by the date the dispute was submitted |
| `merchantId` | string | No | Filter by the processor-assigned merchant identifier |
| `limit` | integer | No | Maximum results per page (default: 10) |
| `after` | string | No | Cursor for the next page (use value from previous response) |
| `before` | string | No | Cursor for the previous page (use value from previous response) |

**Pagination constraint:** `after` and `before` are mutually exclusive — do not send both in the same request.

### Response (200 OK)

The response is a paginated list envelope.

| Field | Type | Description |
| --- | --- | --- |
| `limit` | integer | Maximum results per page |
| `count` | integer | Number of results on this page (not the total) |
| `hasMore` | boolean | Whether additional pages exist |
| `links` | array | Navigation link objects (next/previous cursors) |
| `data` | array | Array of dispute objects (see Dispute Object below) |

### Dispute Object

| Field | Type | Description |
| --- | --- | --- |
| `disputeId` | integer | Unique identifier assigned to the dispute |
| `disputeType` | string enum | Type of dispute — see enum values below |
| `currentStatus` | object | Current status details (see CurrentStatus Object) |
| `createdDate` | string (date) | Date Payroc received the dispute |
| `lastModifiedDate` | string (date) | Most recent modification date |
| `receivedDate` | string (date) | Date the acquiring bank received the dispute |
| `description` | string | Human-readable dispute description |
| `referenceNumber` | string | Bank reference number for the dispute |
| `disputeAmount` | integer | Disputed amount in lowest currency denomination (e.g. cents) |
| `feeAmount` | integer | Associated fee amount in lowest currency denomination |
| `firstDispute` | boolean | Whether this is the initial dispute (not a re-dispute) |
| `authorizationCode` | string | Authorization code of the original transaction |
| `currency` | string | ISO 4217 currency code (e.g. `"USD"`, `"GBP"`) |
| `card` | object | Card details (see Card Object) |
| `merchant` | object | Merchant details (see Merchant Object) |
| `transaction` | object | Original transaction details (see Transaction Object) |

### CurrentStatus Object

| Field | Type | Description |
| --- | --- | --- |
| `disputeStatusId` | integer | Unique identifier for this status record |
| `status` | string enum | Current dispute status — see status enum values below |
| `statusDate` | string (date, YYYY-MM-DD) | Date the status was last changed |
| `link` | object | HATEOAS link to the status resource |

### Card Object

| Field | Type | Description |
| --- | --- | --- |
| `number` | string | Masked card number (e.g. last four digits) |
| `type` | string | Card scheme/type (e.g. Visa, Mastercard) |
| `cvvIndicator` | string | CVV match indicator |
| `avsIndicator` | string | AVS match indicator |

### Merchant Object

| Field | Type | Description |
| --- | --- | --- |
| `merchantId` | string | Processor-assigned merchant identifier |
| `businessName` | string | Merchant's trading name |
| `processingAccountId` | string | Processing account identifier |

### Transaction Object

| Field | Type | Description |
| --- | --- | --- |
| `transactionId` | string | Identifier of the original transaction |
| `type` | string | Transaction type (e.g. sale, refund) |
| `date` | string (date) | Date of the original transaction |
| `entryMethod` | string | How the card was presented (e.g. chip, swipe, ecommerce) |
| `amount` | integer | Original transaction amount in lowest currency denomination |

---

## GET /v1/disputes/{disputeId}/statuses — List Dispute Statuses

Returns the full status history for a single dispute, ordered chronologically.

### Path Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `disputeId` | integer | **Yes** | Unique identifier of the dispute (from the list disputes response) |

### Response (200 OK)

Returns an **array** of status objects (not a paginated envelope — the full history is returned directly).

| Field | Type | Description |
| --- | --- | --- |
| `disputeStatusId` | integer | Unique identifier for this status record |
| `status` | string enum | Dispute status value — see enum values below |
| `statusDate` | string (date, YYYY-MM-DD) | Date this status was set |

---

## Enum Values

### disputeType

> **Read this enum from the reference before emitting.** Do not guess dispute type values.

| Value | Description |
| --- | --- |
| `firstDispute` | Initial chargeback filed by the cardholder's issuing bank |
| `firstDisputeWithReversal` | Initial dispute that includes an immediate reversal |
| `issuerReversal` | The issuer has reversed the dispute |
| `prearbitration` | Dispute re-filed after a representment was rejected |

### status (dispute status, in currentStatus and status history)

> **Read this enum from the reference before emitting.** Do not guess status values — there are many
> and they are easy to misspell. Emit them verbatim from this list.

| Value | Notes |
| --- | --- |
| `new` | Dispute newly received |
| `invalid` | Dispute found to be invalid |
| `rejected` | Dispute rejected |
| `stand` | Merchant accepts the dispute (no contest) |
| `issuerReversal` | Issuer reversed the dispute |
| `representmentInProgress` | Merchant's representment is being processed |
| `representmentFailed` | Representment was unsuccessful |
| `representmentPaid` | Representment was successful and funds returned |
| `representmentReceived` | Representment documents received |
| `prearbitrationInProcess` | Pre-arbitration stage in progress |
| `prearbitrationAccepted` | Pre-arbitration accepted in merchant's favour |
| `prearbitrationDeclined` | Pre-arbitration declined |
| `arbitrationFiledWithCardBand` | Arbitration filed with the card brand — **note: the API spells this `CardBand`, not `CardBrand`; use verbatim** |
| `arbitrationFundsToBeReturned` | Arbitration outcome: funds to be returned to merchant |
| `arbitrationLost` | Arbitration decided against merchant |
| `arbitrationSettledPartialAmount` | Arbitration settled at a partial amount |
| `precomplianceInProcess` | Pre-compliance stage in progress |
| `precomplianceAccepted` | Pre-compliance accepted |
| `precomplianceDeclined` | Pre-compliance declined |
| `complianceFiledWithCardBand` | Compliance filed with the card brand — **note: the API spells this `CardBand`, not `CardBrand`; use verbatim** |
| `complianceLost` | Compliance decided against merchant |
| `complianceSettledPartialAmount` | Compliance settled at a partial amount |

---

## HTTP Status Codes

| Code | Scenario |
| --- | --- |
| 200 | Success |
| 400 | Validation error — check `errors[]` array |
| 401 | Authentication failed — exchange a new Bearer token |
| 403 | Insufficient permissions — check API key scope |
| 404 | Dispute not found (status history endpoint) |
| 406 | Not acceptable |
| 500 | Server error — retry with backoff |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

These are read/reporting (GET) endpoints, so the typical status set is `400` (invalid query params), `401` (auth), `403` (permissions), `404` (unknown `disputeId`, status-history endpoint only), `406` (content negotiation), and `500` (server).

---

## Amounts and Dates

- **All amounts** are integers in the **lowest currency denomination** (e.g. cents for USD, pence for GBP). `disputeAmount: 5000` means $50.00 USD.
- **All dates** use `YYYY-MM-DD` format (ISO 8601). The `date` filter parameter requires this format.
- **`disputeId`** is an integer, not a string. Use it as a path parameter in `/v1/disputes/{disputeId}/statuses`.

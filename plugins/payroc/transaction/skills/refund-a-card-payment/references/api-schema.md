# Refund a Card Payment — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Card Payment Refund schemas). Last synced: 2026-06-22. This is the offline source of truth this
> skill emits from — read enum values and required-field sets from here, not from memory. To refresh,
> re-fetch the source and regenerate this file (see [`_sources.md`](./_sources.md)).

---

## Endpoints

| Operation | Method & Path |
| --- | --- |
| Create referenced refund (refund by payment ID) | `POST /v1/payments/{paymentId}/refund` |
| Create unreferenced refund (no payment ID needed) | `POST /v1/refunds` |
| List refunds | `GET /v1/refunds` |
| Retrieve a refund | `GET /v1/refunds/{refundId}` |
| Adjust a refund | `POST /v1/refunds/{refundId}/adjust` |
| Reverse a refund | `POST /v1/refunds/{refundId}/reverse` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Refund Types

### Referenced Refund
A refund linked to an existing payment. Use `POST /v1/payments/{paymentId}/refund`.
- Requires the `paymentId` of the original payment (returned when the payment was created).
- If the payment is in a **closed batch**: gateway returns funds to the cardholder's account.
- If the payment is in an **open batch**: gateway **reverses** the payment instead (same endpoint, different gateway behaviour — no code change required; the gateway decides based on batch state).
- Response: returns the updated `payment` object (HTTP 200), which includes a `refunds[]` array.

### Unreferenced Refund
A refund not linked to any specific payment. Use `POST /v1/refunds`.
- Does not require a `paymentId` — requires customer card/payment details in the request body.
- Available only on certain accounts — confirm with Payroc that the terminal has unreferenced refund capability.
- Response: returns a `retrievedRefund` object (HTTP 201), which includes a `refundId`.

---

## Schemas

### referencedRefund (request body for POST /v1/payments/{paymentId}/refund)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `amount` | integer (int64) | **Yes** | Amount to refund, in the currency's lowest denomination (e.g. cents). Can be a partial amount (less than the original payment). |
| `description` | string | **Yes** | Reason for the refund. |
| `operator` | string | No | Operator who requested the refund. |

**Important notes:**
- `amount` must be ≤ the original payment amount. Partial refunds are supported.
- No `currency` field — currency is inherited from the original payment.
- No `channel` or `processingTerminalId` needed — these come from the original payment.

### unreferencedRefund (request body for POST /v1/refunds)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `channel` | enum (string) | **Yes** | See `UnreferencedRefundChannel` enum below. |
| `processingTerminalId` | string | **Yes** | Unique identifier of the terminal processing the refund. |
| `order` | object | **Yes** | Refund transaction details — see `refundOrder` schema below. |
| `refundMethod` | object | **Yes** | Payment method details — polymorphic on `type`; see below. |
| `operator` | string | No | Operator who initiated the request. |
| `customer` | object | No | Customer contact and address information. |
| `ipAddress` | object | No | Device IP address (`type`: `ipv4` or `ipv6`, and `value`). |
| `customFields` | array | No | Array of `{name, value}` key-value pairs. |

### refundOrder (nested in unreferencedRefund.order)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `orderId` | string | **Yes** | Merchant-assigned identifier for this refund order. |
| `description` | string | **Yes** | Description of the refund. |
| `amount` | integer (int64) | **Yes** | Refund amount in lowest denomination (e.g. cents). |
| `currency` | string | **Yes** | ISO 4217 currency code (e.g. `USD`, `GBP`, `EUR`). |
| `dateTime` | string (ISO 8601) | No | Datetime of the transaction. |
| `dccOffer` | object | No | Dynamic currency conversion offer. |

### refundMethod (polymorphic, nested in unreferencedRefund.refundMethod)

Discriminated by the `type` field.

**Variant 1: `card`**

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | `"card"` | **Yes** | Discriminator. |
| `cardDetails` | object | **Yes** | Polymorphic on `entryMethod`. |
| `accountType` | enum | No | `checking` \| `savings` — for bank account refund methods only. |

`cardDetails.entryMethod` values: `raw` | `icc` | `keyed` | `swiped`

**Variant 2: `secureToken`**

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `type` | `"secureToken"` | **Yes** | Discriminator. |
| `token` | string | **Yes** | Secure token identifying the stored card. |
| `secCode` | enum | **Yes** | ACH SEC code: `web` \| `tel` \| `ccd` \| `ppd`. |
| `accountType` | enum | No | `checking` \| `savings`. |

---

## Enums

### UnreferencedRefundChannel
`pos` | `moto`

- `pos` — Point of sale (physical terminal).
- `moto` — Mail order / telephone order.

### refundMethod.type
`card` | `secureToken`

### cardDetails.entryMethod
`raw` | `icc` | `keyed` | `swiped`

- `raw` — Unencrypted payment data directly from the device.
- `icc` — Payment data captured from the chip (EMV).
- `keyed` — Payment data entered manually by the merchant.
- `swiped` — Payment data captured from the magnetic stripe.

### RefundAdjustmentAdjustmentsItems.type (adjust endpoint)
`status` | `customer`

- `status` — Adjust the status of the refund (`toStatus`: `ready` | `pending`).
- `customer` — Adjust customer contact details and/or shipping address.

### RefundsGetParametersTender (list filter)
`ebt` | `creditDebit`

### RefundsGetParametersSettlementState (list filter)
`settled` | `unsettled`

### RefundsGetParametersStatusSchemaItems (list filter — status values)
`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `admin` | `expired` | `accepted`

---

## Response schemas

### payment (returned by POST /v1/payments/{paymentId}/refund, HTTP 200)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `paymentId` | string | Yes | Gateway-assigned ID of the original payment. |
| `processingTerminalId` | string | Yes | Terminal that processed the payment. |
| `operator` | string | No | Operator who initiated the original payment. |
| `order` | `paymentOrder` | Yes | Original payment order details. |
| `card` | `card` | Yes | Payment card details (masked). |
| `refunds` | array of `refundSummary` | No | Array of all refunds linked to this payment. |
| `supportedOperations` | array | No | Operations still available on this payment. |
| `transactionResult` | `transactionResult` | Yes | Transaction result. |
| `customer` | object | No | Customer details. |
| `customFields` | array | No | Custom fields. |

### retrievedRefund (returned by POST /v1/refunds, GET /v1/refunds/{refundId}, POST /v1/refunds/{refundId}/adjust, POST /v1/refunds/{refundId}/reverse, HTTP 200/201)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `refundId` | string | Yes | Gateway-assigned refund identifier. |
| `processingTerminalId` | string | Yes | Terminal that processed the refund. |
| `operator` | string | No | Operator who initiated. |
| `order` | `refundOrder` | Yes | Refund order details. |
| `card` | `retrievedCard` | Yes | Card details (masked). |
| `payment` | `paymentSummary` | No | Summary of linked payment (for referenced refunds). |
| `supportedOperations` | array | No | Operations available on this refund. |
| `transactionResult` | `transactionResult` | Yes | Transaction result. |
| `customer` | object | No | Customer details. |
| `customFields` | array | No | Custom fields. |

### refundSummary (items in payment.refunds[])

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `refundId` | string | Yes | Gateway-assigned refund ID. |
| `dateTime` | string (ISO 8601) | Yes | When refund was processed. |
| `currency` | string | Yes | ISO 4217 currency code. |
| `amount` | integer (int64) | Yes | Refund amount in lowest denomination. |
| `status` | enum | Yes | Current status — see `RefundSummaryStatus` below. |
| `responseCode` | enum | Yes | Processor response code — `A` \| `D` \| `E` \| `P` \| `R` \| `C`. |
| `responseMessage` | string | Yes | Human-readable processor description. |
| `link` | object | No | HATEOAS navigation link. |

### transactionResult

| Field | Type | Notes |
| --- | --- | --- |
| `type` | enum | `sale` \| `refund` \| `preAuthorization` \| `preAuthorizationCompletion` |
| `status` | enum | `ready` \| `pending` \| `declined` \| `complete` \| `referral` \| `pickup` \| `reversal` \| `admin` \| `expired` \| `accepted` |
| `responseCode` | enum | `A` \| `D` \| `E` \| `P` \| `R` \| `C` |
| `approvalCode` | string | Authorization code from processor. |
| `authorizedAmount` | integer (int64) | Amount authorized (in lowest denomination). |
| `currency` | string | ISO 4217. |
| `responseMessage` | string | Human-readable response from the processor. |
| `ebtType` | enum | EBT subtype — only for EBT transactions. |

### Response code descriptions (transactionResult.responseCode / refundSummary.responseCode)

| Code | Meaning |
| --- | --- |
| `A` | Processor approved the transaction. |
| `D` | Processor declined the transaction. |
| `E` | Processor received the transaction but will process later. |
| `P` | Processor authorized a partial amount. |
| `R` | Issuer declined; customer should contact their bank. |
| `C` | Issuer declined; merchant should retain the card (reported lost/stolen). |

### RefundSummaryStatus / transactionResult.status

`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `returned` | `admin` | `expired` | `accepted`

---

## Required headers (all POST/PATCH/PUT requests)

| Header | Where | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | every request | Token from identity service; expires in 3600s. |
| `Content-Type: application/json` | POST requests with a body | |
| `Idempotency-Key: <UUID v4>` | every POST | Required; fresh UUID per distinct operation. Reusing the same key for the same request returns the original response (safe retry). Using the same key for a different request causes a 409. |

---

## List refunds — query parameters (GET /v1/refunds)

| Parameter | Type | Notes |
| --- | --- | --- |
| `processingTerminalId` | string | Filter by terminal. |
| `orderId` | string | Filter by merchant order ID. |
| `operator` | string | Filter by operator. |
| `cardholderName` | string | Filter by cardholder name. |
| `first6` | string | First 6 digits of card number. |
| `last4` | string | Last 4 digits of card number. |
| `tender` | enum | `ebt` \| `creditDebit` |
| `status` | array | Filter by status values (see status enum above). |
| `dateFrom` | datetime (ISO 8601) | Refunds processed after this date. |
| `dateTo` | datetime (ISO 8601) | Refunds processed before this date. |
| `settlementState` | enum | `settled` \| `unsettled` |
| `settlementDate` | date | Date of settlement. |
| `before` | string | Cursor — return previous page. Cannot be combined with `after`. |
| `after` | string | Cursor — return next page. Cannot be combined with `before`. |
| `limit` | integer | Max results per page. |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes these endpoints return: `400`, `401`, `403`, `404`, `409`, `500`.

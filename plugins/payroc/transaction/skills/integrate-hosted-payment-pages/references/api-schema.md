# Hosted Payment Pages — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Card Payments — Capture + `transactionResult` schemas). Last synced: 2026-06-01. This is the offline
> source of truth this skill emits from for the **REST-API side** — read enum values and required-field
> sets from here, not from memory. To refresh, re-fetch the source and regenerate this file (see
> [`_sources.md`](./_sources.md)).

This file covers the **Payroc REST API surface** the HPP skill touches: the Capture API used to capture a
pre-authorization, and the `transactionResult` object returned in the capture response (including its
`status` and `responseCode` enums).

**This is not the HPP form-POST/receipt surface.** The HPP form fields (`PAYMENTMETHOD`, hash field order,
`AMOUNT`/`DATETIME` formats) and the receipt-callback `RESPONSECODE` query parameter are documented in the
narrative copies (`load-hosted-payment-page.md`, `build-receipt-page.md`, `authenticate-your-requests.md`),
**not** in the OpenAPI spec. Read those values from there. The receipt-callback `RESPONSECODE` and the REST
`transactionResult.responseCode` are distinct (though overlapping) enums — do not conflate them.

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Capture a pre-authorization | `POST /payments/{paymentId}/capture` |

UAT host: `https://api.uat.payroc.com/v1`  ·  Production host: `https://api.payroc.com/v1`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.
(Note the UAT identity host carries the `.uat` segment; production does not.)

The `paymentId` path parameter is the value HPP returns as `UNIQUEREF` on the receipt callback. The capture
request body is **optional**: omit it to capture the full pre-authorized amount; send `amount` (integer, the
currency's lowest denomination) to capture a partial amount. To capture more than the original amount, call
the Adjust Payment endpoint first.

A successful capture returns **HTTP 200** with a `payment` object that contains `transactionResult`. HTTP
200 confirms the API accepted the request — branch on `transactionResult.status` / `transactionResult.responseCode`
to confirm the capture actually succeeded.

---

## Enums

### transactionResult.status (`TransactionResultStatus`)
`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `admin` | `expired` | `accepted`

- Current status of the transaction.
- **Approval is not signalled by a single value.** A captured/authorized-and-queued pre-auth commonly comes
  back as `ready` (authorized + queued for capture) with `responseCode: "A"`. Do **not** build the success
  check from a remembered subset (e.g. only `"approved"` — which is not even a member of this enum).
  Identify every value that pairs with bank approval and branch on the full set.

### transactionResult.responseCode (`TransactionResultResponseCode`)
`A` | `D` | `E` | `P` | `R` | `C`

- `A` — the processor approved the transaction.
- `D` — the processor declined the transaction.
- `E` — the processor received the transaction but will process it later.
- `P` — the processor authorized a portion of the original amount of the transaction.
- `R` — the issuer declined the transaction and indicated the customer should contact their bank.
- `C` — the issuer declined the transaction and indicated the merchant should keep the card (reported lost or stolen).

### transactionResult.type (`TransactionResultType`)
`sale` | `refund` | `preAuthorization` | `preAuthorizationCompletion`

### transactionResult.healthcareIndicator (`TransactionResultHealthcareIndicator`)
`Y` | `N` | `C` | `R`

### transactionResult.ebtType (`TransactionResultEbtType`)
`cashPurchase` | `cashPurchaseWithCashback` | `foodStampPurchase` | `foodStampVoucherPurchase` | `foodStampReturn` | `foodStampVoucherReturn` | `cashBalanceInquiry` | `foodStampBalanceInquiry` | `cashWithdrawal`

---

## Schemas

### paymentCapture (capture request body — optional)

All fields optional. Omit the whole body to capture the full pre-authorized amount.

| Field | Type | Notes |
| --- | --- | --- |
| `processingTerminalId` | string | optional — terminal identifier |
| `operator` | string | optional — operator who captured the payment |
| `amount` | integer (`int64`) | optional — amount to capture, in the currency's lowest denomination (e.g. cents). If omitted, the full transaction amount is captured. |
| `breakdown` | object (`itemizedBreakdownRequest`) | optional |

```jsonc
// partial capture
{ "paymentCapture": { "amount": 1000 } }
```

### payment (capture 200 response)

Required: `paymentId`, `processingTerminalId`, `order`, `card`, `transactionResult`.

| Field | Type | Notes |
| --- | --- | --- |
| `paymentId` | string | required — gateway identifier for the transaction |
| `processingTerminalId` | string | required |
| `operator` | string | optional |
| `order` | object (`paymentOrder`) | required |
| `customer` | object | optional |
| `card` | object (`card`) | required |
| `refunds` | array | optional |
| `supportedOperations` | object | optional |
| `transactionResult` | object (`transactionResult`) | **required** — see below |
| `customFields` | array | optional |

### transactionResult

Required: `status`, `responseCode`.

| Field | Type | Notes |
| --- | --- | --- |
| `type` | enum (`TransactionResultType`) | transaction type |
| `ebtType` | enum (`TransactionResultEbtType`) | EBT subtype |
| `status` | enum (`TransactionResultStatus`) | **required** — current status of the transaction |
| `approvalCode` | string | authorization code from the processor |
| `authorizedAmount` | integer (`int64`) | amount authorized, currency's lowest denomination |
| `currency` | enum (`currency`, ISO 4217) | |
| `responseCode` | enum (`TransactionResultResponseCode`) | **required** — processor response |
| `responseMessage` | string | processor response description (e.g. `APPROVAL`) |
| `processorResponseCode` | string | original processor response code |
| `cardSchemeReferenceId` | string | card-brand identifier for the payment instruction |
| `healthcareIndicator` | enum (`TransactionResultHealthcareIndicator`) | |

---

## Required headers (capture / REST API)

| Header | Where | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | every request | token from the identity service; expires in 3600s |
| `Content-Type: application/json` | POST | |
| `Idempotency-Key: <UUID v4>` | every POST | required; UUID v4. Retrying a failed request? Reuse the same key — the gateway returns the original result rather than processing a duplicate. |

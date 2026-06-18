# Payroc Cloud — API schema reference

Curated slice of the Payroc API for the **Payroc Cloud** instruction surface. This is the source of
truth for **field names, types, required flags, enum values, and request/response shapes** — emit
these from here, not from memory. For *how to sequence* the calls, see `narrative-run-a-sale.md` and
`narrative-extend.md`.

Last synced: 2026-06-17. Sources: `docs.payroc.com/openapi.yml` (`payrocCloud` tag) and the
per-operation schema pages under `docs.payroc.com/api/schema/...` — see `_sources.md`.

> **Cloud error shape is unverified.** We have no Cloud-enabled account, so the error envelope below
> is the cross-skill Payroc standard (verified on boarding endpoints), applied here on the
> assumption Cloud is consistent. Treat the error *fields* as expected-but-unconfirmed for Cloud.

## Contents

- [Base URLs and headers](#base-urls-and-headers)
- [Endpoint inventory](#endpoint-inventory)
- [Authentication](#authentication)
- [The instruction object (poll response)](#the-instruction-object-poll-response)
- [Submit a payment instruction — `paymentInstructionRequest`](#submit-a-payment-instruction--paymentinstructionrequest)
- [Submit a refund instruction — `refundInstructionRequest`](#submit-a-refund-instruction--refundinstructionrequest)
- [Submit a signature instruction — `signatureInstructionRequest`](#submit-a-signature-instruction--signatureinstructionrequest)
- [Retrieve a signature](#retrieve-a-signature)
- [Retrieve a closed-loop read](#retrieve-a-closed-loop-read)
- [Retrieve a payment (the completed-instruction target)](#retrieve-a-payment-the-completed-instruction-target)
- [Referenced refund (via the payments API)](#referenced-refund-via-the-payments-api)
- [Reverse a payment (via the payments API)](#reverse-a-payment-via-the-payments-api)
- [Search payments — `GET /payments`](#search-payments--get-payments)
- [Search devices — `GET /devices`](#search-devices--get-devices)
- [Error responses](#error-responses)

---

## Base URLs and headers

```text
Test/sandbox (UAT):  https://api.uat.payroc.com/v1
Production:          https://api.payroc.com/v1
Identity (UAT):      https://identity.uat.payroc.com/authorize
Identity (prod):     https://identity.payroc.com/authorize
```

| Header | Where | Notes |
|--------|-------|-------|
| `Authorization: Bearer <token>` | every request | from the identity service |
| `Content-Type: application/json` | every POST | |
| `Idempotency-Key: <UUID v4>` | every instruction `POST` and every refund/reverse `POST` | fresh UUID per new submission; reuse to retry the *same* submission |

---

## Endpoint inventory

| Method | Path | Success | Purpose |
|--------|------|:-------:|---------|
| POST | `/devices/{serialNumber}/payment-instructions` | 202 | Submit a sale / pre-auth to a device |
| GET | `/payment-instructions/{paymentInstructionId}` | 200 | Poll the payment instruction |
| DELETE | `/payment-instructions/{paymentInstructionId}` | 204 | Cancel (only while `inProgress`) |
| POST | `/devices/{serialNumber}/refund-instructions` | 202 | Submit an unreferenced refund to a device |
| GET | `/refund-instructions/{refundInstructionId}` | 200 | Poll the refund instruction |
| DELETE | `/refund-instructions/{refundInstructionId}` | 204 | Cancel (only while `inProgress`) |
| POST | `/devices/{serialNumber}/signature-instructions` | 202 | Capture a signature on a device |
| GET | `/signature-instructions/{signatureInstructionId}` | 200 | Poll the signature instruction |
| DELETE | `/signature-instructions/{signatureInstructionId}` | 204 | Cancel (only while `inProgress`) |
| GET | `/payment-instructions/{id}` → `link.href` → `/payments/{paymentId}` | 200 | Retrieve the resulting payment |
| GET | `/refund-instructions/{id}` → `link.href` → `/refunds/{refundId}` | 200 | Retrieve the resulting refund |
| GET | `/signatures/{signatureId}` | 200 | Retrieve a captured signature (Base64) |
| GET | `/closed-loop-reads/{closedLoopReadId}` | 200 | Retrieve a closed-loop card payload |
| POST | `/payments/{paymentId}/refunds` | 201 | Run a **referenced** refund (not a device instruction) |
| GET | `/payments/{paymentId}/refunds/{refundId}` | 200 | Retrieve a referenced refund |
| POST | `/payments/{paymentId}/reverse` | 200 | Reverse a payment in an open batch (not a device instruction) |
| GET | `/payments` | 200 | Search payments (find a `paymentId`) |
| GET | `/payments/{paymentId}` | 200 | Retrieve a payment |
| GET | `/devices` | 200 | Search devices (find a `serialNumber`) |

> **Device-bound vs gateway-only.** The `POST /devices/{serialNumber}/...-instructions` calls run on
> the physical device. Every `GET`/`DELETE` here is gateway-only — no device involvement.

---

## Authentication

Exchange the API key for a bearer token, then send it on every request.

```text
POST https://identity.uat.payroc.com/authorize        (prod: identity.payroc.com)
x-api-key: <your-api-key>
```

Response:

```json
{
  "access_token": "eyJhbGc....adQssw5c",
  "expires_in": 3600,
  "scope": "service_a service_b",
  "token_type": "Bearer"
}
```

`expires_in` is seconds (3600 ≈ 1 hour). Refresh before expiry.

---

## The instruction object (poll response)

All three instruction types share one shape. The id field name differs
(`paymentInstructionId` / `refundInstructionId` / `signatureInstructionId`):

| Field | Type | Required | Notes |
|-------|------|:---:|-------|
| `status` | enum | ✓ | one of `inProgress`, `completed`, `failure`, `canceled` |
| `{x}InstructionId` | string | ✓ | the gateway's id for **the instruction** (not the resulting resource) |
| `errorMessage` | string | | present **only** when `status` is `failure` |
| `link` | object | | HATEOAS link: `{ rel, method, href }` |

**`link` semantics by status:**

- `inProgress` → `link.rel: "self"`, `href` points back at the instruction (poll again).
- `completed` → `link.rel` names the resource (`"self"` then resource, or directly e.g.
  `"signature"`), `href` points at the **real resource** (`/payments/{id}`, `/refunds/{id}`,
  `/signatures/{id}`). Follow it.
- `failure` → read `errorMessage`.
- `canceled` → the instruction was cancelled before completion.

**Instruction status enum:** `inProgress`, `completed`, `failure`, `canceled`. There is no
`approved`/`declined` here — bank approval lives on the **retrieved resource**
(`transactionResult` / `responseCode`), not on the instruction.

---

## Submit a payment instruction — `paymentInstructionRequest`

`POST /devices/{serialNumber}/payment-instructions` → `202 Accepted` (an instruction object).

**Required:** `processingTerminalId`, `order`.

| Field | Type | Req | Notes |
|-------|------|:---:|-------|
| `processingTerminalId` | string | ✓ | Terminal id the gateway assigned (from signup). |
| `order` | object | ✓ | See below. |
| `operator` | string | | Person who initiated the request. |
| `customer` | object | | Contact + billing/shipping address; `notificationLanguage`: `en` \| `fr`. |
| `ipAddress` | object | | `{ type: "ipv4" \| "ipv6", value: string }`. |
| `credentialOnFile` | object | | See below. |
| `customizationOptions` | object | | See below. |
| `autoCapture` | boolean | | Default `true`. `false` = pre-authorization. |
| `processAsSale` | boolean | | Default `false`. `true` = settle immediately (ignores `autoCapture`, blocks later adjustments). |

### `order` (`paymentInstructionOrder`)

**Required:** `orderId`, `amount`, `currency`.

| Field | Type | Req | Notes |
|-------|------|:---:|-------|
| `orderId` | string | ✓ | Merchant-assigned transaction id. |
| `amount` | integer (int64) | ✓ | **Lowest denomination (cents).** `4999` = $49.99. |
| `currency` | enum | ✓ | ISO 4217 (`USD`, `EUR`, `GBP`, `CAD`, …). |
| `dateTime` | date-time | | ISO-8601. |
| `description` | string | | |
| `acceptPartialAmount` | boolean | | Default `false`. Allow partial auth if the issuer can't approve the full amount. |
| `breakdown` | object | | See below. |

### `breakdown` (within `order`)

**Required within breakdown:** `subtotal`.

| Field | Type | Notes |
|-------|------|-------|
| `subtotal` | integer (int64) | Amount before tax and fees, in cents. |
| `cashbackAmount` | integer (int64) | Cashback amount. |
| `tip` | object | `{ type: "percentage" \| "fixedAmount", mode: "prompted" \| "adjusted", amount` or `percentage }`. |
| `surcharge` | object | `{ bypass: boolean, amount` or `percentage: number }`. |
| `dualPricing` | object | `{ offered: boolean, choiceRate, alternativeTender: "card" \| "cash" \| "bankTransfer" }`. |
| `healthcareExpenses` | array | items `{ type: "copay" \| "clinic" \| "dental" \| "prescription" \| "transit" \| "vision", amount }`. |
| `taxes` | array | items `{ rate: number, name: string }`. |

### `credentialOnFile`

| Field | Type | Notes |
|-------|------|-------|
| `externalVault` | boolean | Default `false`. Merchant uses a third-party vault. |
| `tokenize` | boolean | Gateway should tokenize the customer's payment details. |
| `secureTokenId` | string | Merchant-created id for the secure token. |
| `mitAgreement` | enum | `unscheduled` \| `recurring` \| `installment` (requires standing instructions). |

### `customizationOptions`

| Field | Type | Notes |
|-------|------|-------|
| `entryMethod` | enum | Default `deviceRead`. `deviceRead` \| `manualEntry` \| `deviceReadOrManualEntry`. |
| `ebtDetails` | object | `{ benefitCategory: "cash" \| "foodStamp", withdrawal: boolean }`. |
| `closedLoopOptions` | object | Polymorphic; `type: "mifare"`. |

### Worked example

```json
POST /v1/devices/{serialNumber}/payment-instructions
Headers: Authorization: Bearer <token>; Content-Type: application/json; Idempotency-Key: <uuid-v4>
{
  "processingTerminalId": "1234001",
  "order": {
    "orderId": "OrderRef6543",
    "amount": 4999,
    "currency": "USD",
    "breakdown": {
      "subtotal": 4500,
      "tip": { "type": "fixedAmount", "mode": "prompted", "amount": 499 },
      "taxes": [ { "rate": 0.08, "name": "Sales Tax" } ]
    }
  },
  "operator": "Jane",
  "customizationOptions": { "entryMethod": "deviceRead" },
  "credentialOnFile": { "tokenize": true },
  "autoCapture": true
}
```

```json
202 Accepted
{
  "status": "inProgress",
  "paymentInstructionId": "a37439165d134678a9100ebba3b29597",
  "link": {
    "rel": "self",
    "method": "GET",
    "href": "https://api.payroc.com/v1/payment-instructions/a37439165d134678a9100ebba3b29597"
  }
}
```

### Cancel (`DELETE /payment-instructions/{paymentInstructionId}`)

- Success: `204 No Content` (empty body).
- **Only valid while `status` is `inProgress`.** Cancelling once the instruction has left
  `inProgress` returns `409 Conflict` (the body carries `errors[]` and a `link`).

---

## Submit a refund instruction — `refundInstructionRequest`

This is the **unreferenced** (standalone) refund — it runs on the device and is not tied to a prior
payment. (For a refund tied to an original payment, see *Referenced refund* below.)

`POST /devices/{serialNumber}/refund-instructions` → `202 Accepted` (an instruction object with
`refundInstructionId`).

**Required:** `processingTerminalId`, `order`.

| Field | Type | Req | Notes |
|-------|------|:---:|-------|
| `processingTerminalId` | string | ✓ | |
| `order` | object | ✓ | See below. |
| `operator` | string | | |
| `customer` | object | | Same shape as on a payment. |
| `ipAddress` | object | | `{ type, value }`. |
| `customizationOptions` | object | | `entryMethod` enum, `ebtDetails`, `closedLoopOptions`. |

### `order` (`refundInstructionOrder`)

**Required:** `orderId`, `description`, `amount`, `currency`.

| Field | Type | Req | Notes |
|-------|------|:---:|-------|
| `orderId` | string | ✓ | |
| `description` | string | ✓ | **Required on a refund order** (it is optional on a payment order). |
| `amount` | integer | ✓ | Cents. |
| `currency` | enum | ✓ | ISO 4217. |
| `dateTime` | date-time | | ISO-8601. |

```json
202 Accepted
{
  "status": "inProgress",
  "refundInstructionId": "...",
  "link": { "rel": "self", "method": "GET",
            "href": "https://api.payroc.com/v1/refund-instructions/..." }
}
```

On `completed`, `link.rel` is `refund` and `link.href` points at `/refunds/{refundId}`.

---

## Submit a signature instruction — `signatureInstructionRequest`

`POST /devices/{serialNumber}/signature-instructions` → `202 Accepted`.

**Required:** `processingTerminalId` (the entire request body).

| Field | Type | Req | Notes |
|-------|------|:---:|-------|
| `processingTerminalId` | string | ✓ | The body is just this one field. |

```json
202 Accepted
{
  "status": "inProgress",
  "signatureInstructionId": "a37439165d134678a9100ebba3b29597",
  "link": { "rel": "self", "method": "GET",
            "href": "https://api.payroc.com/v1/signature-instructions/a37439165d134678a9100ebba3b29597" }
}
```

On `completed`, `link.rel` is `signature` and `link.href` points at `/signatures/{signatureId}`.
Signature capture is **standalone** — it is not tied to a payment.

---

## Retrieve a signature

`GET /signatures/{signatureId}` → `200`.

| Field | Type | Notes |
|-------|------|-------|
| `signatureId` | string | |
| `processingTerminalId` | string | Terminal the signature is linked to. |
| `createdOn` | date (YYYY-MM-DD) | Date the device captured the signature. |
| `contentType` | string | MIME type of the image, e.g. `image/png`. |
| `signature` | string (Base64) | Base64-encoded image data. |

```json
{
  "signatureId": "JDN4ILZB0T",
  "processingTerminalId": "1024",
  "createdOn": "2024-07-02",
  "contentType": "image/png",
  "signature": "iVBORw0KGgoAAAANSUhEUgAA...<truncated Base64>"
}
```

---

## Retrieve a closed-loop read

`GET /closed-loop-reads/{closedLoopReadId}` → `200` (`ClosedLoopResponse`).

| Field | Type | Notes |
|-------|------|-------|
| `processingTerminalId` | string | |
| `closedLoopReadId` | string | |
| `readDate` | date (YYYY-MM-DD) | Date the device read the card. |
| `data` | object | **Unstructured payload from the card** — shape varies by card type. |

```json
{
  "processingTerminalId": "1024",
  "closedLoopReadId": "...",
  "readDate": "2026-06-17",
  "data": { "cardType": "MiFareClassic", "uid": "04134ee21f1d80" }
}
```

> `data` is explicitly unstructured. Don't assume a fixed schema for it.

---

## Retrieve a payment (the completed-instruction target)

`GET /payments/{paymentId}` → `200` (`retrievedPayment`). This is the resource a **completed payment
instruction** points to via `link.href` — follow the link; the `paymentId` is **not** the
`paymentInstructionId`. The bank's approve/decline outcome lives here, not on the instruction.

| Field | Type | Notes |
|-------|------|-------|
| `paymentId` | string | Gateway id for the transaction. |
| `processingTerminalId` | string | |
| `operator` | string | |
| `order` | object (`paymentOrder`) | Transaction details (amount in cents, currency, orderId, …). |
| `customer` | object | Contact + address. |
| `card` | object (`retrievedCard`) | `type` (brand), `cardNumber` (masked, first6+last4), `expiryDate` (`MMYY`), `entryMethod` (`icc` \| `keyed` \| `swiped` \| `swipedFallback` \| `contactlessIcc` \| `contactlessMsr`), `secureToken`, `securityChecks`, `emvTags`, `balances` (EBT). |
| `refunds` | array | `refundSummary` items for linked refunds. |
| `supportedOperations` | array (enum) | What's allowed now: `capture`, `refund`, `fullyReverse`, `partiallyReverse`, `incrementAuthorization`, `adjustTip`, `addSignature`, `setAsReady`, `setAsPending`. Check this before choosing refund vs reverse. |
| `transactionResult` | object | See below — read this to determine approval. |
| `customFields` | array | Name/value pairs. |

### `transactionResult` — read this to branch on approval

| Field | Type | Notes |
|-------|------|-------|
| `type` | enum | `sale` \| `refund` \| `preAuthorization` \| `preAuthorizationCompletion`. |
| `status` | enum | `ready`, `pending`, `declined`, `complete`, `referral`, `pickup`, `reversal`, `admin`, `expired`, `accepted`. **Branch on the full set of approval-bearing values, not just one** — e.g. `ready` (authorized, queued for capture) is an approval. |
| `responseCode` | enum | `A` approved, `D` declined, `E` deferred, `P` partial, `R` referral, `C` card capture. |
| `responseMessage` | string | Processor description. |
| `approvalCode` | string | Authorization code. |
| `authorizedAmount` | integer | Cents. |
| `currency` | enum | ISO 4217. |
| `processorResponseCode` | string | Original processor code. |
| `cardSchemeReferenceId` | string | Lives on `transactionResult`, not on the card. |

> **A `complete`/`approved`-only success check is a known footgun.** `status: "ready"` with
> `responseCode: "A"` is an approval (authorized + queued for capture). Branch on every approval value,
> not a single remembered one.

## Referenced refund (via the payments API)

A referenced refund is **not a device instruction** — it goes through the standard payments API and
needs the original `paymentId` first.

```text
POST /v1/payments/{paymentId}/refunds          -> 201
Headers: Authorization: Bearer <token>; Content-Type: application/json; Idempotency-Key: <uuid-v4>
```

Minimal body:

```json
{ "amount": 4999, "currency": "USD" }
```

Retrieve: `GET /v1/payments/{paymentId}/refunds/{refundId}` → `200` (`refundSummary`):

| Field | Type | Notes |
|-------|------|-------|
| `refundId` | string | |
| `dateTime` | date-time | ISO-8601. |
| `currency` | enum | ISO 4217. |
| `amount` | integer | Cents. |
| `status` | enum | see refund status enum below. |
| `responseCode` | enum | `A`=approved, `D`=declined, `E`=pending, `P`=partial, `R`=referral, `C`=fraud alert. |
| `responseMessage` | string | Processor description. |

**Refund/payment status enum:** `ready`, `pending`, `declined`, `complete`, `referral`, `pickup`,
`reversal`, `returned`, `admin`, `expired`, `accepted`.

> **Open-batch behaviour.** If you run a referenced refund on a payment that is still in an **open
> batch**, the gateway **auto-cancels (reverses)** the original payment instead of creating a
> separate refund. To deliberately cancel an open-batch payment, use *Reverse a payment*.

---

## Reverse a payment (via the payments API)

Also not a device instruction. Cancels (or partially cancels) a payment that is still in an **open
batch**; the payment is removed from the batch and no funds are taken.

```text
POST /v1/payments/{paymentId}/reverse           -> 200
Headers: Authorization: Bearer <token>; Content-Type: application/json; Idempotency-Key: <uuid-v4>
```

Body (all optional):

| Field | Type | Notes |
|-------|------|-------|
| `operator` | string | Person who initiated the reversal. |
| `amount` | integer | Cents. Omit to reverse the **full** amount; supply to partially reverse. |

Returns `200` with the updated payment object. A retrieved payment lists what's allowed in its
`supportedOperations` (e.g. `refund`, `fullyReverse`, `partiallyReverse`) — check it before choosing
reverse vs refund.

---

## Search payments — `GET /payments`

Find a `paymentId` when you don't have one (needed for referenced refunds and reversals).

Query params: `first6`, `last4`, `cardholderName`, `orderId`, `operator`, `dateFrom`, `dateTo`
(ISO-8601), `status` (payment status enum above), `type` (`sale` \| `preAuthorization` \|
`preAuthorizationCompletion`), `processingTerminalId`, plus pagination `limit` / `before` / `after`.

Response wraps results: `{ limit, count, hasMore, links, data: [ paymentSummary ... ] }`. Read
`paymentId` from the matching summary. `GET /payments/{paymentId}` retrieves one in full.

---

## Search devices — `GET /devices`

Read-only; use it to discover a device's `serialNumber`. No hardware needed.

Query params:

| Param | Type | Notes |
|-------|------|-------|
| `serialNumber` | string | Filter by serial number. |
| `ksi` | string | Key serial identifier. |
| `model` | string | Device model. |
| `active` | boolean | Filter by active status. |
| `limit` | integer | Default 10. |
| `before` / `after` | string | Pagination cursors (mutually exclusive). |

Response: `{ limit, count, hasMore, data: [ device ... ], links }`. Each `device`:

| Field | Type | Notes |
|-------|------|-------|
| `deviceId` | string | |
| `serialNumber` | string | The value you put in the instruction path. |
| `ksi` | string | |
| `tender` | string | `creditDebit` \| `ebt`. |
| `deviceType` | object | `{ model, manufacturer }`. |
| `createdDate` | date-time | |
| `deactivatedDate` | date-time | Present only if the device is inactive (there is no `status` field). |
| `lastTransaction` | object | `{ orderId, dateTime, processingTerminalId }`. |
| `links` | array | HATEOAS links. |

---

## Error responses

Errors use the [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) problem-details envelope
plus a Payroc `errors[]` extension — see `_shared/error-response-format.md` for the cross-skill
standard. Envelope (standard RFC members): `type`, `title`, `status`, `detail`, `instance`. Each
`errors[]` item (Payroc extension): `parameter` (JSON path of the failing field), `detail` (short
reason, distinct from the top-level `detail`), `message` (human-readable).

| Status | Meaning on Cloud | Action |
|--------|------------------|--------|
| 400 | Validation error | Map each `errors[].parameter` to the request field; fix and resubmit (reuse the same idempotency key for an identical retry). |
| 401 | Token expired/invalid | Re-authenticate. |
| 403 | Insufficient permissions | Check API key scope. |
| 404 | Instruction/resource not found | Verify the id; note instruction id ≠ resource id. |
| 406 / 415 | Not acceptable / unsupported media | Check `Accept` / `Content-Type` and body shape. |
| 409 | Conflict — e.g. cancelling an instruction that is no longer `inProgress`, or reusing an idempotency key with a changed body | Re-GET the instruction's current `status` before retrying. |
| 500 | Server error | Retry with backoff; surface `errors` if present. |

> **Not yet verified for Cloud.** The fields above are the standard Payroc shape, confirmed on
> boarding endpoints. The Cloud endpoints almost certainly follow it, but we could not confirm
> against a live Cloud account. Read `errorMessage` on a `failure` instruction, and `errors[]` on a
> 4xx, but don't hard-code assumptions about Cloud-specific error text.

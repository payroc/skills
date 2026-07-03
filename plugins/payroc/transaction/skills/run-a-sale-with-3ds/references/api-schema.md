# Run a Sale with 3-D Secure — API Schema Reference

> **Local snapshot — authoritative for this skill.** Sources: `https://docs.payroc.com/openapi.yml`
> (payments + threeDSecure schemas) and `https://docs.payroc.com/guides/take-payments/3-d-secure/run-a-sale-with-3-d-secure.md`
> (MPI endpoint details and response schema). Last synced: 2026-06-22. This is the offline source of
> truth this skill emits from — read enum values and required-field sets from here, not from memory.

3-D Secure is a four-step flow: (1) enrol, (2) tokenize the card, (3) send to the MPI service, (4) post
the payment with the MPI reference. Steps 3 and 4 involve two separate APIs with different base URLs.

---

## Endpoints

| Step | Operation | Method & URL |
| --- | --- | --- |
| 3 | MPI authentication request | `GET https://payments.uat.payroc.com/merchant/mpi` (test) |
| 3 | MPI authentication request | `GET https://payments.payroc.com/merchant/mpi` (production) |
| 4 | Create payment | `POST https://api.uat.payroc.com/v1/payments` (test) |
| 4 | Create payment | `POST https://api.payroc.com/v1/payments` (production) |

Note the different host for the MPI service (`payments.uat.payroc.com`) vs the Payments API
(`api.uat.payroc.com`). Do not swap these.

---

## Step 2 — Tokenization

Before calling the MPI service, the card must be tokenized into a single-use token using either:
- **Hosted Fields** — Payroc's embedded card-input widgets create the token client-side
- **API tokenization** — server-side tokenization via the Payroc tokenization endpoint

The resulting token is a `singleUseToken` used in Step 3 and Step 4.

---

## Step 3 — MPI Request

**Method:** `GET` with query parameters (no request body, no `Content-Type` header, no `Idempotency-Key`).

**Authentication:** `Authorization: Bearer <token>` header required.

### Query Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `processingTerminalId` | string | Yes | Terminal identifier |
| `singleUseToken` | string | Yes | Single-use token from Step 2 |
| `email` | string | Yes | Cardholder email address |
| `amount` | integer | Yes | Transaction amount in the currency's lowest denomination (e.g. cents) |
| `currency` | string | Yes | ISO 4217 currency code (e.g. `"USD"`, `"GBP"`) |
| `orderId` | string | Yes | Merchant-assigned order identifier |
| `cardholderChallenge` | string | No | `"REQUIRED"` or `"OPTIONAL"` — whether to force a cardholder challenge |

> **Read these parameter names from this file before emitting them.** Do not guess spelling or casing.

### MPI Response Fields

The MPI response is delivered asynchronously to the callback URL that was registered during Step 1 setup. It is a GET request to your callback URL with these fields:

| Field | Type | Values | Description |
| --- | --- | --- | --- |
| `result` | string | `"A"` or `"D"` | `"A"` = approved (proceed to payment); `"D"` = declined (do not proceed) |
| `status` | string | `"A"`, `"N"`, `"U"`, `"Y"` | Authentication outcome — `"Y"` = authenticated, `"A"` = attempted, `"N"` = not authenticated, `"U"` = unable to authenticate |
| `eci` | string | `"05"`, `"06"`, `"07"` | `"05"` = fully authenticated; `"06"` = not enrolled / attempted; `"07"` = failed |
| `mpiReference` | string | — | Reference code to include in the payment request (Step 4) |
| `orderId` | string | — | Echo of the merchant's `orderId` from Step 3 |

> **Do not proceed to Step 4 if `result` is `"D"`.** A declined MPI result means the cardholder
> failed verification. Submitting the payment anyway bypasses the security intent of 3-D Secure.

---

## Step 4 — Payment Request

**Method:** `POST`

**Required headers:**

| Header | Value |
| --- | --- |
| `Authorization` | `Bearer <access_token>` |
| `Content-Type` | `application/json` |
| `Idempotency-Key` | UUID v4, freshly generated per distinct submission |

### Top-level request fields

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `channel` | enum | Yes | `"pos"`, `"web"`, or `"moto"` — for 3DS e-commerce use `"web"` |
| `processingTerminalId` | string | Yes | Terminal identifier |
| `order` | object | Yes | Payment order details (see below) |
| `paymentMethod` | object | Yes | Card token (see below) |
| `threeDSecure` | object | Yes (for 3DS flows) | 3-D Secure authentication data — include when the MPI reference is available |
| `autoCapture` | boolean | No | `true` (default) = sale (capture immediately); `false` = pre-authorisation (hold, capture later) |
| `operator` | string | No | Operator name |
| `customer` | object | No | Customer contact details and address |
| `ipAddress` | object | No | Device IP address with `type` (`"ipv4"` or `"ipv6"`) |
| `credentialOnFile` | object | No | Tokenisation settings for saving card details |
| `customFields` | array | No | Merchant-defined key/value data |

### `order` object

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `orderId` | string | Yes | Merchant-assigned order identifier — use the same value as Step 3 |
| `amount` | integer | Yes | Amount in the currency's lowest denomination — must match Step 3 amount |
| `currency` | string | Yes | ISO 4217 currency code — must match Step 3 currency |
| `description` | string | No | Order description |
| `dateTime` | string | No | ISO 8601 datetime |
| `acceptPartialAmount` | boolean | No | Default `false` |

### `paymentMethod` object — `singleUseToken` variant

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | string | Yes | Must be `"singleUseToken"` |
| `token` | string | Yes | The single-use token from Step 2 (same token used in Step 3) |

### `threeDSecure` object — gateway variant

Use the gateway variant when the MPI reference comes from Payroc's own MPI service (Step 3).

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `serviceProvider` | string | Yes | Must be `"gateway"` |
| `mpiReference` | string | Yes | The `mpiReference` value from the Step 3 MPI response |

### `threeDSecure` object — thirdParty variant

Use the third-party variant when 3-D Secure was handled externally (not via Payroc's MPI service).

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `serviceProvider` | string | Yes | Must be `"thirdParty"` |
| `eci` | string | Yes | `"fullyAuthenticated"` or `"attemptedAuthentication"` |
| `xid` | string | No | Unique transaction identifier assigned by the merchant |
| `cavv` | string | No | Cardholder Authentication Verification Value from the card issuer |
| `dsTransactionId` | string | No | Directory Server Transaction ID from the processor |

---

## Enums

### `channel`
`"pos"` | `"web"` | `"moto"`

For 3-D Secure e-commerce payments the correct value is `"web"`. Do not use `"pos"` or `"moto"` for online 3DS flows.

### `threeDSecure.serviceProvider`
`"gateway"` | `"thirdParty"`

Use `"gateway"` when using Payroc's MPI service. Use `"thirdParty"` for external 3DS providers.

### MPI `result`
`"A"` (approved — proceed to payment) | `"D"` (declined — do not proceed)

### MPI `status`
`"Y"` (authenticated) | `"A"` (attempted authentication) | `"N"` (not authenticated) | `"U"` (unable to authenticate)

### MPI `eci`
`"05"` (fully authenticated) | `"06"` (not enrolled or attempted) | `"07"` (failed)

### `threeDSecure.eci` (thirdParty variant, payment request field — different from MPI response eci)
`"fullyAuthenticated"` | `"attemptedAuthentication"`

> **Important:** These are the values for the **payment request** `threeDSecure.eci` field when using
> `serviceProvider: "thirdParty"`. They are different from the MPI response `eci` values above
> (`"05"`, `"06"`, `"07"`). Do not cross-reference these two enums.

---

## Payment Response (HTTP 201)

A successful payment returns a `payment` object including:

| Field | Notes |
| --- | --- |
| `paymentId` | Unique transaction identifier — store for refunds, adjustments, and disputes |
| `status` | Payment status |
| `approvalCode` | Authorisation code from the issuer |
| Card details | Masked PAN and card type |
| Transaction amounts | Approved amount and currency |

---

## Required Headers Summary

| Header | POST /v1/payments | GET /merchant/mpi |
| --- | --- | --- |
| `Authorization: Bearer <token>` | Yes | Yes |
| `Content-Type: application/json` | Yes | No (GET, no body) |
| `Idempotency-Key: <uuid-v4>` | Yes | No (GET request) |

---

## Setup Prerequisite

3-D Secure must be enabled by the Payroc Integrations team before the MPI service will respond.
The developer must provide a **callback URL** where the MPI response will be delivered.
Contact `cs@payroc.com` or the Payroc Integrations team to enable 3-D Secure on the terminal.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes for these endpoints: `400`, `401`, `403`, `409`, `500`.

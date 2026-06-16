# Google Pay — Payroc API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Create Payment / `paymentRequest` schemas). Last synced: 2026-06-01. This is the offline source of truth
> this skill emits from — read enum values and required-field sets from here, not from memory. To refresh,
> re-fetch the source and regenerate this file (see [`_sources.md`](./_sources.md)).

This slice covers the fields the skill emits when POSTing a Google Pay payment to the Payroc Payments API.
Every enum value below is copied exactly from the OpenAPI spec. Google Pay is processed as a `digitalWallet`
payment method with `serviceProvider: google`.

---

## Endpoint

| Operation | Method & path |
| --- | --- |
| Create a payment (run a sale / pre-authorization) | `POST /v1/payments` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Enums

### channel (`paymentRequest.channel`)
`pos` | `web` | `moto`

- Channel that the merchant used to receive the payment details.
- For a browser/app Google Pay checkout the narrative guide's worked example uses `web`.
- **Not** `internet`, `online`, `ecommerce`, or `card-not-present` — those are not in the enum and the API
  returns HTTP 400.

### paymentMethod.type (discriminator on `PaymentRequestPaymentMethod`)
`card` | `secureToken` | `digitalWallet` | `singleUseToken`

- For Google Pay, use `digitalWallet`.

### paymentMethod.serviceProvider (digitalWallet variant)
`apple` | `google`

- For Google Pay, use `google`. (`apple` is Apple Pay.)

### transactionResult.status (read-only, returned by the API)
`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `admin` | `expired` | `accepted`

- The transaction's **lifecycle state — not, by itself, the approval signal.** For a sale the two
  *authorized* states are `ready` (auto-captured / queued for capture) and `pending` (authorized but
  awaiting capture — e.g. a pre-authorization, or `autoCapture: false`; the merchant captures later to
  take the funds). Both mean the payment was authorized. `declined` / `expired` / `reversal` etc. are
  not success. Determine success from `responseCode` (below); use `status` for lifecycle.

### transactionResult.responseCode (read-only, returned by the API)
`A` | `D` | `E` | `P` | `R` | `C`

- `A` — **approved.** This is the success signal: the processor approved the transaction. A successful
  response also carries an `approvalCode` and a `responseMessage` such as `OK...`.
- `E` — received; the processor will process it later (deferred — not yet a definitive approval).
- `P` — partial approval: only part of the requested amount was authorized (handle deliberately — it
  is neither a clean approval nor a decline).
- `D` — processor declined.
- `R` — issuer declined; customer should contact their bank.
- `C` — issuer declined; merchant should keep the card (reported lost or stolen).

**Determining success (do this — don't guess a `status` subset):** branch on `responseCode === 'A'`.
Under an `A`, both `ready` and `pending` are successful authorizations (`pending` just needs a later
capture). Handle `E` (deferred) and `P` (partial) deliberately if your flow needs them; treat `D` /
`R` / `C` as declines. Building an "approval status list" from memory is how authorized payments get
silently mis-flagged as failures — key off `responseCode` instead.

### currency (`order.currency`)
ISO 4217 alphabetic code (e.g. `USD`, `GBP`, `EUR`). Full enum is the ISO 4217 set in the spec.

---

## Schemas

### paymentRequest (request body for `POST /v1/payments`)

Required: `channel`, `processingTerminalId`, `order`, `paymentMethod`.

| Field | Type | Notes |
| --- | --- | --- |
| `channel` | enum | required — `pos` \| `web` \| `moto` |
| `processingTerminalId` | string | required — terminal ID assigned by Payroc |
| `operator` | string | optional — operator who ran the transaction |
| `order` | object | required — see `paymentOrderRequest` |
| `customer` | object | optional |
| `ipAddress` | object | optional |
| `paymentMethod` | object | required — polymorphic, discriminated by `type` |
| `threeDSecure` | object | optional |
| `credentialOnFile` | object | optional |
| `offlineProcessing` | object | optional |
| `autoCapture` | boolean | optional — default `true`; `false` = pre-authorization (capture later) |
| `processAsSale` | boolean | optional — default `false`; if `true`, gateway ignores `autoCapture` |
| `customFields` | array | optional |

### paymentMethod — digitalWallet variant

Required: `type`, `serviceProvider`, `encryptedData`.

| Field | Type | Notes |
| --- | --- | --- |
| `type` | enum | required — `digitalWallet` for Google Pay |
| `serviceProvider` | enum | required — `google` for Google Pay |
| `encryptedData` | string | required — encrypted Google Pay token, **hex-encoded** |
| `accountType` | enum | optional — `checking` \| `savings`; send only for bank-account details |
| `cardholderName` | string | optional |

`encryptedData` is the encrypted payment token taken from the Google Pay `paymentData` callback, converted
to hexadecimal format before sending (see the narrative copy `google-pay.md`).

### order (`paymentOrderRequest`, abbreviated)

| Field | Type | Notes |
| --- | --- | --- |
| `orderId` | string | required — your reference for the order. **Length 1–24 characters.** |
| `amount` | integer | required — value in the currency's lowest denomination (e.g. cents); `1099` = $10.99 |
| `currency` | string | required — 3-letter ISO 4217 code, e.g. `USD` |
| `description` | string | optional — free-text description of the order |

**Watch the `orderId` length.** The maximum is 24 characters, so a raw GUID will not fit: a
hyphenated GUID is 36 chars and a `N`-format (no-hyphen) GUID is 32 — both are rejected with HTTP 400
`"'orderId' size must be between 1 and 24"`. Use a shorter identifier (e.g. your own order number, or
a truncated/encoded GUID) that stays within 1–24 characters.

---

## Required headers

| Header | Where | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | every request | token from the identity service; expires in 3600s |
| `Content-Type: application/json` | POST | |
| `Idempotency-Key: <UUID v4>` | every POST | required; fresh UUID per distinct operation |

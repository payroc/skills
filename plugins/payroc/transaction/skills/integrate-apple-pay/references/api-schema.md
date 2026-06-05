# Apple Pay — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Apple Pay session + payment request schemas). Last synced: 2026-06-01. This is the offline source of
> truth this skill emits from — read enum values and required-field sets from here, not from memory. To
> refresh, re-fetch the source and regenerate this file (see [`_sources.md`](./_sources.md)).

Covers only the Payroc-side schemas this skill touches: starting an Apple Pay session, and the payment
request that carries the Apple Pay digital-wallet token. Apple-owned shapes (the `ApplePaySession` JS API,
the payment-token structure) are documented separately under [`third-party/`](./third-party/) — they do not
cross the wire to Payroc as named here.

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Start an Apple Pay session | `POST /v1/processing-terminals/{processingTerminalId}/apple-pay-sessions` |
| Run a payment (sale / pre-auth) | `POST /v1/payments` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Enums

### channel (payment request) — `PaymentRequestChannel`
`pos` | `web` | `moto`

- For an in-browser Apple Pay checkout, the Apple Pay flow runs in the web channel. There is **no**
  `internet` / `online` / `ecommerce` value — emit one of the three above only.

### paymentMethod.type (discriminator) — `PaymentRequestPaymentMethod`
`card` | `secureToken` | `digitalWallet` | `singleUseToken`

- Apple Pay uses **`digitalWallet`**.

### paymentMethod.serviceProvider (digitalWallet variant) — `FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletServiceProvider`
`apple` | `google`

- Apple Pay uses **`apple`**. (`google` is Google Pay.)

### transactionResult.status (read-only, in the payment response) — `TransactionResultStatus`
`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `admin` | `expired` | `accepted`

- The transaction's **lifecycle state — not, by itself, the approval signal.** For a sale the two
  *authorized* states are `ready` (auto-captured / queued for capture) and `pending` (authorized but
  awaiting capture — e.g. a pre-authorization, or `autoCapture: false`; the merchant captures later to
  take the funds). Both mean the payment was authorized. `declined` / `expired` / `reversal` etc. are
  not success. Determine success from `responseCode` (below); use `status` for lifecycle. `approved` is
  **not** a member of this enum — don't branch on it.

### transactionResult.responseCode (read-only) — `TransactionResultResponseCode`
`A` | `D` | `E` | `P` | `R` | `C`

- `A` — **approved.** This is the success signal: the processor approved the transaction. A successful
  response also carries an `approvalCode` and a `responseMessage` such as `OK...`.
- `E` — received; the processor will process it later (deferred — not yet a definitive approval).
- `P` — partial approval: only part of the requested amount was authorized (handle deliberately).
- `D` — declined. `R` — declined, customer should contact bank. `C` — declined, keep card (lost/stolen).

**Determining success (do this — don't guess a `status` subset):** branch on `responseCode === 'A'`.
Under an `A`, both `ready` and `pending` are successful authorizations (`pending` just needs a later
capture). Handle `E` (deferred) and `P` (partial) deliberately; treat `D` / `R` / `C` as declines.
Building an "approval status list" from memory is how authorized payments get silently mis-flagged as
failures — key off `responseCode` instead.

### currency — `currency`
ISO 4217 three-letter code (e.g. `GBP`, `USD`, `EUR`). Full enum is in the spec; emit a valid ISO 4217 code.

> **Note on "country".** There is no top-level `country` field on the Payroc payment request. A two-letter
> ISO 3166-1 `country` appears only inside `address` objects (e.g. `customer.billingAddress.country`,
> required there). The country/currency you pass to the **Apple Pay sheet** (`countryCode`/`currencyCode`)
> are Apple-side fields — see [`third-party/apple-applepaysession.md`](./third-party/apple-applepaysession.md).

---

## Schemas

### applePaySessions (start-session request body)

`POST /v1/processing-terminals/{processingTerminalId}/apple-pay-sessions`

| Field | Type | Notes |
| --- | --- | --- |
| `appleDomainId` | string | **required** — the unique domain ID from the Payroc Self-Care Portal (Step 1). |
| `appleValidationUrl` | string | **required** — the `validationURL` from Apple's `onvalidatemerchant` event, passed through verbatim. |

Required: `appleDomainId`, `appleValidationUrl`.
Header: `Authorization: Bearer <token>` (required). This endpoint takes **no** `Idempotency-Key` parameter.

### applePayResponseSession (start-session response, 200)

| Field | Type | Notes |
| --- | --- | --- |
| `startSessionResponse` | string | **required** — the object Apple returns to start the merchant's session. Pass it back to Apple via `completeMerchantValidation` (unwrapped). |

### paymentRequest (run-a-payment request body) — `paymentRequest`

`POST /v1/payments`

Required: `channel`, `processingTerminalId`, `order`, `paymentMethod`.

| Field | Type | Notes |
| --- | --- | --- |
| `channel` | enum | **required** — `pos` \| `web` \| `moto`. Apple Pay in-browser → `web`. |
| `processingTerminalId` | string | **required** — the UAT/prod terminal ID. |
| `order` | object | **required** — `paymentOrderRequest` (see below). |
| `paymentMethod` | object | **required** — polymorphic; use the `digitalWallet` variant for Apple Pay (see below). |
| `operator` | string | optional. |
| `customer` | object | optional — contact/address details. |
| `ipAddress` | object | optional. |
| `threeDSecure` | object | optional. |
| `credentialOnFile` | object | optional — tokenize / MIT agreement. |
| `autoCapture` | boolean | optional, default `true`. `true` = sale (auto-capture); `false` = pre-authorization (capture later). |
| `processAsSale` | boolean | optional, default `false`. `true` = settle immediately (overrides `autoCapture`). |
| `customFields` | array | optional. |

### paymentMethod — digitalWallet variant

```jsonc
"paymentMethod": {
  "type": "digitalWallet",      // required (discriminator)
  "serviceProvider": "apple",   // required — Apple Pay
  "encryptedData": "<hex>",     // required — the Apple payment token JSON, hex-encoded
  "cardholderName": "..."       // optional
  // "accountType": ...         // optional, only for bank-account details
}
```

Required for the `digitalWallet` variant: `type`, `serviceProvider`, `encryptedData`.

- `encryptedData` — the Apple Pay payment token (see
  [`third-party/apple-payment-token.md`](./third-party/apple-payment-token.md)) serialized and hex-encoded.

### paymentOrderRequest (`order`)

Required: `orderId`, `amount`, `currency`.

| Field | Type | Notes |
| --- | --- | --- |
| `orderId` | string | **required** — merchant-assigned unique identifier. **Length 1–24 characters** (a raw GUID is 32–36 chars and is rejected with HTTP 400 — use a shorter identifier). |
| `amount` | integer | **required** — value in the currency's lowest denomination (e.g. cents). |
| `currency` | enum | **required** — ISO 4217 code. |
| `description` | string | optional. |
| `dateTime` | date-time | optional (ISO 8601). |
| `standingInstructions` | object | optional — required when sending a `credentialOnFile.mitAgreement`. |
| `acceptPartialAmount` | boolean | optional, default `false`. |
| `breakdown` | object | optional — itemized breakdown. |

### transactionResult (in the payment response)

Required: `status`, `responseCode`. Also returns `type`, `approvalCode`, `authorizedAmount`, `currency`,
`responseMessage`, `processorResponseCode`, `cardSchemeReferenceId`, `healthcareIndicator`.

Determine success from `responseCode === "A"` (the approval signal, paired with an `approvalCode` /
`OK` `responseMessage`); treat both `ready` and `pending` as authorized lifecycle states. Don't gate
success on a guessed `status` subset.

---

## Required headers

| Header | Where | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | every request | token from the identity service; expires in 3600s. |
| `Content-Type: application/json` | POST | |
| `Idempotency-Key: <UUID v4>` | `POST /v1/payments` | required on payments; fresh UUID per distinct operation. The apple-pay-sessions endpoint does not take this header. |

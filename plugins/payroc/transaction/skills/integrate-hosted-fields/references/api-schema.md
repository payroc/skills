# Hosted Fields — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Hosted Fields / Payments schemas). Last synced: 2026-06-01. This is the offline source of truth this
> skill emits from — read enum values and required-field sets from here, not from memory. To refresh,
> re-fetch the source and regenerate this file (see [`_sources.md`](./_sources.md)).

Every enum value and schema below is a curated slice of the OpenAPI spec covering only the schemas this
skill touches: the Hosted Fields session-token request, the `paymentRequest` body, the `payment` response,
and the objects they reference (`transactionResult`, `card`, `secureTokenSummary`, `standingInstructions`,
`schemas-credentialOnFile`, `threeDSecure`).

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Authenticate (Bearer token) | `POST https://identity.payroc.com/authorize` with header `x-api-key` |
| Create session token | `POST /v1/hosted-fields/sessions` (see authenticate-your-session.md for exact path) |
| Run a payment | `POST /v1/payments` |
| 3-D Secure MPI check | `GET /merchant/mpi` (payments host) |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
UAT payments/MPI host: `https://payments.uat.payroc.com`  ·  Production: `https://payments.payroc.com`
Identity (both environments): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Enums

Read every enum-typed value from this list, not from memory. A plausible English-sounding value that
isn't in the enum (e.g. `channel: "internet"`, or branching success only on `"approved"`) produces a 400
or a silent logic error.

### channel (`PaymentRequestChannel`)
`pos` | `web` | `moto`

- For an in-browser Hosted Fields checkout, the value is **`web`** — **not** `internet`, `online`,
  `ecommerce`, or `card-not-present` (none of those are in the enum).

### paymentMethod.type (`PaymentRequestPaymentMethod` discriminator)
`card` | `secureToken` | `digitalWallet` | `singleUseToken`

- `singleUseToken` — the one-time token from the Hosted Fields `submissionSuccess` event (first/sale charge).
- `secureToken` — the durable saved token used for subsequent merchant-initiated charges.

### scenario (`HostedFieldsCreateSessionRequestScenario`)
`payment` | `tokenization`

- `payment` — run a sale, **or** run a sale and tokenize in the same transaction.
- `tokenization` — save the customer's payment details to charge later, or update saved details.
- Use `payment` whenever you intend to actually charge the card, even if you also save it on the same call.

### transactionResult.status (`TransactionResultStatus`)
`ready` | `pending` | `declined` | `complete` | `referral` | `pickup` | `reversal` | `admin` | `expired` | `accepted`

- A successful authorization commonly returns **`ready`** (authorized + queued for capture), not
  `"approved"` (which is **not** a member of this enum). Build the success branch from this full set, not
  from a remembered subset.

### transactionResult.responseCode (`TransactionResultResponseCode`)
`A` | `D` | `E` | `P` | `R` | `C`

- `A` — processor approved the transaction.
- `D` — processor declined the transaction.
- `E` — processor received the transaction but will process it later.
- `P` — processor authorized a portion of the original amount.
- `R` — issuer declined; customer should contact their bank.
- `C` — issuer declined; keep the card (reported lost or stolen).

### standingInstructions.sequence (`StandingInstructionsSequence`)
`first` | `subsequent`

### standingInstructions.processingModel (`StandingInstructionsProcessingModel`)
`unscheduled` | `recurring` | `installment`

- `unscheduled` — payment is not part of a regular billing cycle.
- `recurring` — regular billing cycle with no end date.
- `installment` — regular billing cycle with a defined end date.

### secCode (ACH single-use token — `...SingleUseTokenSecCode`)
`web` | `tel` | `ccd` | `ppd`

- Mandatory only when the single-use token represents ACH bank account details.

### accountType (ACH single-use token — `...SingleUseTokenAccountType`)
`checking` | `savings`

- Send only when the single-use token represents bank account details.

### threeDSecure.serviceProvider (`PaymentRequestThreeDSecure` discriminator)
`gateway` | `thirdParty`

- For the Payroc-gateway 3DS flow, use `gateway`; the variant also requires `mpiReference`.

### credentialOnFile.mitAgreement (`SchemasCredentialOnFileMitAgreement`)
`unscheduled` | `recurring` | `installment`

### currency (`currency`, ISO 4217)
Full ISO 4217 three-letter set. Common values: `USD`, `GBP`, `EUR`, `CAD`, `AUD`. `amount` is an integer
in the currency's lowest denomination (e.g. cents). The complete enum is the standard ISO 4217 list as
published in the spec — read the spec if you need an uncommon code.

---

## Schemas

### hostedFieldsCreateSessionRequest (session-token request)

Required: `libVersion`, `scenario`.

| Field | Type | Notes |
| --- | --- | --- |
| `libVersion` | string | required — four-part version (e.g. `1.7.0.261457` UAT / `1.7.0.261471` prod). Spec names `1.7.0.261471` as the current production version. Read the current value from `create-a-payment-form.md` / `hosted-fields-sdk.js`. |
| `scenario` | enum | required — `payment` \| `tokenization` |
| `secureTokenId` | string | optional — include when updating a customer's saved payment details |

Header: `Idempotency-Key: <UUID v4>`.

### paymentRequest (run a payment — request body)

Required: **`channel`**, **`processingTerminalId`**, **`order`**, **`paymentMethod`**.

| Field | Type | Notes |
| --- | --- | --- |
| `channel` | enum | required — `pos` \| `web` \| `moto` (use `web` for Hosted Fields) |
| `processingTerminalId` | string | required — flat string at top level, not nested |
| `order` | object | required — `paymentOrderRequest` (see below) |
| `paymentMethod` | object | required — `PaymentRequestPaymentMethod`, discriminated by `type` |
| `credentialOnFile` | object | optional — TOP LEVEL — `schemas-credentialOnFile` (e.g. `{ tokenize: true }`) |
| `threeDSecure` | object | optional — `{ serviceProvider: "gateway", mpiReference }` for gateway 3DS |
| `customer` | object | optional |
| `ipAddress` | object | optional |
| `autoCapture` | boolean | optional, default `true` — `false` runs a pre-authorization |
| `processAsSale` | boolean | optional, default `false` |
| `operator` | string | optional |

### paymentOrderRequest (the `order` object)

Required: **`orderId`**, **`amount`**, **`currency`**.

| Field | Type | Notes |
| --- | --- | --- |
| `orderId` | string | required — unique per charge; do not reuse across charges |
| `amount` | integer (int64) | required — lowest denomination (e.g. cents) |
| `currency` | enum | required — ISO 4217 code |
| `standingInstructions` | object | optional — INSIDE `order` — the recurring/installment signal |
| `description` | string | optional |
| `acceptPartialAmount` | boolean | optional, default `false` |

### paymentMethod variants (discriminated by `type`)

```jsonc
// single-use token (sale / first charge) — from submissionSuccess
{ "type": "singleUseToken", "token": "<token-from-submissionSuccess>" }

// secure token (subsequent merchant-initiated charge)
{ "type": "secureToken", "token": "<saved-secure-token>" }
```

For ACH single-use tokens, `secCode` (`web`|`tel`|`ccd`|`ppd`) is mandatory and `accountType`
(`checking`|`savings`) is sent when the token represents bank account details.

### schemas-credentialOnFile (top-level `credentialOnFile`)

| Field | Type | Notes |
| --- | --- | --- |
| `tokenize` | boolean | set `true` to save the card and receive a reusable `secureToken` on the response |
| `secureTokenId` | string | optional — merchant-supplied id; gateway generates one if omitted |
| `externalVault` | boolean | optional, default `false` |
| `mitAgreement` | enum | optional — `unscheduled` \| `recurring` \| `installment` |

### standingInstructions (inside `order`)

Required: **`sequence`**, **`processingModel`**.

| Field | Type | Notes |
| --- | --- | --- |
| `sequence` | enum | required — `first` \| `subsequent` |
| `processingModel` | enum | required — `unscheduled` \| `recurring` \| `installment` (must match across the series) |
| `referenceDataOfFirstTxn` | object | `firstTxnReferenceData` — `{ paymentId, cardSchemeReferenceId }`; send on `subsequent` charges |

### payment (run a payment — response body)

Required: `paymentId`, `processingTerminalId`, `order`, `card`, `transactionResult`.

- **The response has no `paymentMethod` field.** It uses **`card`** (shaped by the `card` schema). Do not
  write the response handler by analogy with the request.
- `cardSchemeReferenceId` lives on **`transactionResult`**, not on `card`.
- The durable saved token is at `card.secureToken.token` (shaped by `secureTokenSummary`).

| Field | Path | Notes |
| --- | --- | --- |
| `paymentId` | top level | identifies the transaction; reuse as `referenceDataOfFirstTxn.paymentId` |
| `card.secureToken.token` | inside `card.secureToken` | durable token for subsequent charges (only present if `credentialOnFile.tokenize: true` was sent) |
| `transactionResult.status` | inside `transactionResult` | branch on the full enum, not on a remembered subset |
| `transactionResult.responseCode` | inside `transactionResult` | `A`=approved, `D`=declined, etc. |
| `transactionResult.cardSchemeReferenceId` | inside `transactionResult` | network reference for the standing-instruction series |

### secureTokenSummary (shape of `card.secureToken`)

| Field | Type | Notes |
| --- | --- | --- |
| `token` | string | the durable token (begins `296753`, up to 12 digits, Luhn check digit) |
| `secureTokenId` | string | merchant-assigned id |
| `customerName` | string | |
| `status` | enum | |

### threeDSecure — gateway variant (top-level `threeDSecure`)

Required (gateway variant): `serviceProvider` (`gateway`), `mpiReference`.

```jsonc
{ "serviceProvider": "gateway", "mpiReference": "<from MPI webhook>" }
```

---

## Required headers

| Header | Where | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | every API request | token from the identity service; expires in 3600s |
| `Content-Type: application/json` | POST | |
| `Idempotency-Key: <UUID v4>` | session-token POST and payment POST | required; fresh UUID per distinct operation (reuse → 409) |
| `x-api-key: <api-key>` | identity `POST /authorize` only | exchanged for a Bearer token |

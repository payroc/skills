# Repeat Payments — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Repeat Payments — Secure Tokens, Payment Plans, Subscriptions + the Payments `secureToken` / `standingInstructions`
> schemas). Last synced: 2026-06-04. This is the offline source of truth this skill emits from for the
> **REST-API side of recurring billing** — read enum values and required-field sets from here, not from memory.
> To refresh, re-fetch the source and regenerate this file (see [`_sources.md`](./_sources.md)).

This file covers the **Payroc REST API surface** used to turn a saved card into repeat payments: the Secure
Tokens, Payment Plans, and Subscriptions resources (the **"use our gateway"** path), and the Payments
endpoint with a secure-token payment method plus `standingInstructions` (the **"use your own software" / MIT**
path).

**This is not the HPP form-POST/receipt surface.** The save-card HPP form fields (`ACTION`,
`STOREDCREDENTIALUSE`, hash field order) and the receipt-callback parameters (`CARDREFERENCE`,
`STOREDCREDENTIALTXTYPE`, the `A`/`E14`/`E43`/`E44` `RESPONSECODE` enum) live in the narrative copies under
`save-payment-details/`, **not** in the OpenAPI spec. Read those from there.

> **Casing trap.** The HPP form POST spells stored-credential usage **UPPERCASE** (`STOREDCREDENTIALUSE` =
> `UNSCHEDULED`/`RECURRING`/`INSTALLMENT`). Every REST field below spells it **lowercase** (`mitAgreement` /
> `processingModel` = `unscheduled`/`recurring`/`installment`). Same concept, different surface — emit the
> casing for the surface you are on.

---

## Hosts, auth, and ordering

UAT host: `https://api.uat.payroc.com/v1`  ·  Production host: `https://api.payroc.com/v1`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.
(Note the UAT identity host carries the `.uat` segment; production does not.)

All requests use **Bearer-token** auth (`Authorization: Bearer <token>`, token from the identity service,
expires in 3600s) — the same mechanism as the pre-auth Capture API, **not** the HPP HMAC hash. POSTs also
require `Content-Type: application/json` and an `Idempotency-Key: <UUID v4>`.

**Dependency order (gateway path):** Subscriptions reference a payment plan and a secure token, so the plan
and the token must exist first. With HPP save-card, the token already exists — its `token` value is the
`CARDREFERENCE` returned on the receipt callback, and its `secureTokenId` is the `MERCHANTREF` you sent. Create
the **Payment Plan**, then create the **Subscription** that links the plan to the token.

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| Create / list payment plans | `POST` / `GET /processing-terminals/{processingTerminalId}/payment-plans` |
| Retrieve / update / delete payment plan | `GET` / `PATCH` / `DELETE /processing-terminals/{processingTerminalId}/payment-plans/{paymentPlanId}` |
| Create / list subscriptions | `POST` / `GET /processing-terminals/{processingTerminalId}/subscriptions` |
| Retrieve / update subscription | `GET` / `PATCH /processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}` |
| Deactivate subscription | `POST /processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/deactivate` |
| Reactivate subscription | `POST /processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/reactivate` |
| Pay a manual subscription | `POST /processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/pay` |
| Create / list secure tokens | `POST` / `GET /processing-terminals/{processingTerminalId}/secure-tokens` |
| Retrieve / delete secure token | `GET` / `DELETE /processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}` |
| Update secure token account details | `POST /processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}/update-account` |
| Run a payment with a token (MIT) | `POST /payments` (see "Use your own software" below) |

`PATCH` endpoints take a JSON Patch document (RFC 6902), not a partial resource body.

---

## Enums

### PaymentPlanType / SubscriptionType (`type`)
`manual` | `automatic`  *(default `automatic`)*
- `manual` — the merchant manually collects payments from the customer.
- `automatic` — the terminal automatically collects payments from the customer.

### PaymentPlanFrequency / SubscriptionFrequency (`frequency`)
`weekly` | `fortnightly` | `monthly` | `quarterly` | `yearly`
- Note the spellings: **`fortnightly`** (not "biweekly") and **`yearly`** (not "annually"). Do not infer from analogy.

### PaymentPlanOnUpdate (`onUpdate`)
`update` | `continue`  *(default `continue`)*
- `update` — changes to the plan apply to existing subscriptions.
- `continue` — changes don't apply to existing subscriptions.

### PaymentPlanOnDelete (`onDelete`)
`complete` | `continue`  *(default `complete`)*
- `complete` — stops existing subscriptions.
- `continue` — continues existing subscriptions.

### SubscriptionStateStatus (subscription `currentState.status`)
`active` | `completed` | `suspended` | `cancelled`
- `active` — subscription is active.
- `completed` — subscription reached its end date or total number of billing cycles.
- `cancelled` — the merchant deactivated the subscription.
- `suspended` — subscription is suspended (e.g. the customer missed payments).

### SecureTokenMitAgreement / SchemasCredentialOnFileMitAgreement / StandingInstructionsProcessingModel (`mitAgreement` / `processingModel`)
`unscheduled` | `recurring` | `installment`
- `unscheduled` — fixed-or-variable-amount transactions run at a pre-defined event.
- `recurring` — fixed-amount transactions at regular intervals, no fixed duration, run until the customer cancels.
- `installment` — fixed-amount transactions at regular intervals with a fixed duration.

### StandingInstructionsSequence (`sequence`)
`first` | `subsequent` — position of the transaction in the payment-plan sequence.

### SecureTokenStatus (`status`, response)
`notValidated` | `cvvValidated` | `validationFailed` | `issueNumberValidated` | `cardNumberValidated` | `bankAccountValidated`

### PaymentRequestChannel (`channel`, for the MIT Payments call)
`pos` | `web` | `moto`

### PaymentRequestPaymentMethod.type
`card` | `secureToken` | `digitalWallet` | `singleUseToken` — for repeat payments with a saved card, use `secureToken`.

---

## Schemas — "use our gateway" path

### paymentPlan (create request / response)

Required: `paymentPlanId`, `name`, `currency`, `type`, `frequency`, `onUpdate`, `onDelete`.

| Field | Type | Notes |
| --- | --- | --- |
| `paymentPlanId` | string | **required** — merchant-assigned unique identifier |
| `name` | string | **required** — name of the payment plan |
| `description` | string | optional |
| `currency` | enum (`currency`, ISO 4217) | **required** |
| `length` | integer | number of payments; **`0` = run indefinitely** (default `0`) |
| `type` | enum (`PaymentPlanType`) | **required** — `manual` \| `automatic` |
| `frequency` | enum (`PaymentPlanFrequency`) | **required** — how often a payment is collected |
| `onUpdate` | enum (`PaymentPlanOnUpdate`) | **required** — `update` \| `continue` |
| `onDelete` | enum (`PaymentPlanOnDelete`) | **required** — `complete` \| `continue` |
| `customFieldNames` | array of string | optional — custom fields usable by linked subscriptions |
| `setupOrder` | object (`paymentPlanSetupOrder`) | optional — initial setup cost; `amount` (int64, lowest denomination), `description`, `breakdown` |
| `recurringOrder` | object (`paymentPlanRecurringOrder`) | cost of each payment; `amount` (int64, lowest denomination), `description`, `breakdown`. **Send only if `type` is `automatic`.** |

### subscriptionRequest (create subscription)

Required: `subscriptionId`, `paymentPlanId`, `paymentMethod`, `startDate`.

| Field | Type | Notes |
| --- | --- | --- |
| `subscriptionId` | string | **required** — merchant-assigned unique identifier |
| `paymentPlanId` | string | **required** — the plan created above |
| `paymentMethod` | object (`SubscriptionRequestPaymentMethod`) | **required** — see below |
| `name` | string | optional — replaces the name inherited from the plan |
| `description` | string | optional — replaces the description inherited from the plan |
| `setupOrder` | object (`subscriptionPaymentOrderRequest`) | optional — `orderId`, `amount` (int64), `description`, `breakdown` |
| `recurringOrder` | object (`subscriptionRecurringOrderRequest`) | optional — `amount` (int64), `description`, `breakdown`. **Send only if `type` is `automatic`.** |
| `startDate` | string (`date`, **YYYY-MM-DD**) | **required** — subscription start date |
| `endDate` | string (`date`, **YYYY-MM-DD**) | optional. **If both `length` and `endDate` are sent, the gateway uses `endDate`.** |
| `length` | integer | optional — total billing cycles; `0` = indefinite. Replaces the plan's `length`. |
| `pauseCollectionFor` | integer | optional — number of billing cycles to pause (e.g. a free-trial period) |
| `customFields` | array (`customField`) | optional |

#### SubscriptionRequestPaymentMethod (polymorphic, `type` discriminator)

For a saved card the only variant you need is `secureToken`:

| Field | Type | Notes |
| --- | --- | --- |
| `type` | string enum | **required** — `secureToken` |
| `token` | string | **required** — the secure token. **For HPP save-card this is the `CARDREFERENCE` from the receipt callback.** |
| `accountType` | enum | only if the token represents bank-account details |
| `secCode` | enum (`web`/`tel`/`ccd`/`ppd`) | mandatory only when the token represents ACH bank-account details |

The subscription **response** (`subscription`) additionally returns `processingTerminalId`, a `paymentPlan`
summary, a `secureToken` summary, `currentState` (`status` from `SubscriptionStateStatus`, `nextDueDate`,
`paidInvoices`, `outstandingInvoices`), and the resolved `type` / `frequency`.

For a **`manual`** subscription, collect each payment by calling
`POST .../subscriptions/{subscriptionId}/pay` (`subscriptionPaymentRequest`: `operator`, `order`,
`customFields`). For an **`automatic`** subscription the gateway collects on schedule.

---

## Schemas — "use your own software" path (merchant-initiated transactions)

If you don't use the Subscriptions mechanism, run each payment yourself with the Payments endpoint, passing
the saved token and a `standingInstructions` block that positions the transaction in the sequence.

### paymentRequest (run a sale with a saved token)

Required: `channel`, `processingTerminalId`, `order`, `paymentMethod`.

| Field | Type | Notes |
| --- | --- | --- |
| `channel` | enum (`PaymentRequestChannel`) | **required** — `pos` \| `web` \| `moto` |
| `processingTerminalId` | string | **required** |
| `operator` | string | optional |
| `order` | object (`paymentOrderRequest`) | **required** — includes `amount` and, for MIT, the `standingInstructions` object |
| `paymentMethod` | object (`PaymentRequestPaymentMethod`) | **required** — use the `secureToken` variant: `{ "type": "secureToken", "token": "<CARDREFERENCE>" }` |
| `credentialOnFile` | object (`schemas-credentialOnFile`) | `externalVault` (bool), `tokenize` (bool), `secureTokenId` (string), `mitAgreement` (enum). **If you send `mitAgreement`, you must also send `standingInstructions` in `order`.** |
| `autoCapture` | boolean | default `true`. `true` = sale; `false` = pre-authorization (capture later). |
| `processAsSale` | boolean | default `false`. `true` settles immediately and ignores `autoCapture`. |
| `customFields` | array (`customField`) | optional |

### standingInstructions (inside `order`)

Required: `sequence`, `processingModel`.

| Field | Type | Notes |
| --- | --- | --- |
| `sequence` | enum (`StandingInstructionsSequence`) | **required** — `first` for the initial stored-credential transaction; `subsequent` for each follow-on |
| `processingModel` | enum (`StandingInstructionsProcessingModel`) | **required** — `unscheduled` \| `recurring` \| `installment` |
| `referenceDataOfFirstTxn` | object (`firstTxnReferenceData`) | on `subsequent` transactions, link back to the first: `paymentId` (recommended) and `cardSchemeReferenceId` |

> **MIT sequencing.** The first charge against a newly saved card is `sequence: first`; every later charge is
> `sequence: subsequent` and should carry `referenceDataOfFirstTxn` linking to the first payment. This mirrors
> the HPP receipt's `STOREDCREDENTIALTXTYPE` (`FIRST_TXN` vs `SUBSEQUENT_MERCHANT_INITIATED_TXN`).

---

## Note on creating tokens directly (not via HPP)

The Secure Tokens endpoint (`POST .../secure-tokens`) can also mint a token from raw card/ACH/PAD details or a
single-use token (`source` polymorphic: `card` / `ach` / `pad`), with an optional `mitAgreement`. **In the HPP
flow you do not need this** — HPP already created the token and handed you the `CARDREFERENCE`, keeping card
data off the merchant's systems. Use this endpoint only if a path needs to create a token server-side from
details the merchant already holds.

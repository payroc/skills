# Recurring Billing Flow (save a card, then take repeat payments)

Read this file when the developer's integration needs to save a customer's payment details and charge them
again later — recurring billing, subscriptions, free trials, installment plans, or merchant-initiated
follow-on charges.

The shape is two stages:

- **Stage A — Save the card on the Hosted Payment Page.** A self-contained HPP flow that mints a secure
  token (`CARDREFERENCE`) without the merchant ever touching card data. It is a *sibling* of the sale flow,
  not the sale flow with an extra field — the endpoint, the hash recipe, the form fields, and the receipt
  `RESPONSECODE` set are all different. Read the `save-payment-details/` narrative copies; do not reuse the
  sale field names or hash function from memory.
- **Stage B — Take repeat payments with the token.** A REST-API stage (Bearer-token auth, like capture).
  Two paths: **use our gateway** (Payment Plans + Subscriptions — the gateway schedules and collects), or
  **use your own software** (you schedule and run each merchant-initiated charge with the token). Read
  `references/repeat-payments-api-schema.md` for every value here.

The HPP form-POST surface and the REST surface use **different casing for the same concept**:
`STOREDCREDENTIALUSE` is UPPERCASE on the form (`RECURRING`); `mitAgreement` / `processingModel` are lowercase
on the API (`recurring`). Emit the casing for the surface you are on.

---

## Stage A, Step 1 — Authenticate the save-card request

Read: references/save-payment-details/authenticate-your-requests.md

> **Do not reuse the sale hash function.** The save-card hash recipe is
> `[TERMINALID]:[MERCHANTREF]:[DATETIME]:[ACTION]:[SECRET]` — it has **no AMOUNT** (you are tokenizing, not
> charging), uses **MERCHANTREF** in place of ORDERID, and adds the **ACTION** field. Read the exact order,
> the SHA-512 algorithm, and the worked example from the reference, and reproduce the example hash exactly
> before continuing — the example is a contract, just as it is for sales.

### Checkpoint

Does the save-card hash function reproduce the example hash from the reference exactly? If not, diagnose
(common cause: copied the sale recipe and left AMOUNT/ORDERID in) before continuing.

---

## Stage A, Step 2 — Load the Hosted Payment Page (save card)

Read: references/save-payment-details/load-hosted-payment-page.md

The endpoint is **`/merchant/securecardpage`** — *not* `/merchant/paymentpage` (sale) or `/merchant/preauthpage`
(pre-auth). As a verification anchor, the UAT URL should be
`https://payments.uat.payroc.com/merchant/securecardpage`. If the reference shows different, use the reference
and note the discrepancy.

Emit the form fields from the reference. The save-card-specific ones are `ACTION` (`register` for a new card,
`update` to refresh an existing token's details) and `STOREDCREDENTIALUSE` (**UPPERCASE** `UNSCHEDULED` /
`RECURRING` / `INSTALLMENT`). Choose `STOREDCREDENTIALUSE` to match the agreement the customer consented to —
this is the same agreement you will mirror as `mitAgreement` / `processingModel` (lowercase) on the REST side.

**Record the transaction type yourself.** HPP doesn't echo whether this was a sale, pre-auth, or save-card —
persist that in your own model alongside `MERCHANTREF`.

### Checkpoint

Does submitting the form redirect the browser to the Payroc UAT secure-card page without an error? If not,
diagnose (common cause: posted to `paymentpage`, or hash built with the sale recipe) before continuing.

---

## Stage A, Step 3 — Receipt page (capture the token)

Read: references/save-payment-details/build-receipt-page.md

Two things differ from the sale receipt and both matter:

1. **The redirect URL is a separate Self-Care field.** The save-card receipt goes to the **Secure Token URL**
   registered in the Self-Care Portal — not the sales/pre-auth receipt URL. If the handler never fires, check
   that field first.
2. **The `RESPONSECODE` enum is different.** It is `A` (we stored the details) / `E14` / `E43` / `E44` — not
   the sale `A`/`D`/`R`/`C` set. Here `A` means "stored," and there is no separate approval set to enumerate.
   Read the full set from the reference; branch on it, not on a remembered sale set.

Verify the response hash **before** trusting any value — the save-card response hash order is
`[TERMINALID]:[RESPONSECODE]:[RESPONSETEXT]:[MERCHANTREF]:[CARDREFERENCE]:[DATETIME]:[SECRET]` (different from
the sale). Then capture and **durably store**:

- `CARDREFERENCE` — the secure token. This is the value you send as `paymentMethod.token` in Stage B. Losing
  it means you cannot charge the customer again. Store it in the database against the customer/order — never
  in session or TempData.
- `MERCHANTREF` — your identifier for the token (the REST `secureTokenId`); store it so you can look the token
  up later.
- `STOREDCREDENTIALUSE` / `STOREDCREDENTIALTXTYPE` if returned — useful for setting `sequence` and
  `processingModel` correctly in Stage B.

### Checkpoint

Receipt handler verifies the response hash, branches on the save-card `RESPONSECODE` set, and writes
`CARDREFERENCE` + `MERCHANTREF` to durable storage? If not, resolve before continuing.

---

## Stage B — Take repeat payments

Read: references/repeat-payments-api-schema.md

All of Stage B is REST API over Bearer-token auth — obtain a token from the identity service exactly as for
pre-auth capture (`POST https://identity.uat.payroc.com/authorize` in UAT, `https://identity.payroc.com/authorize`
in production — the UAT host carries the `.uat` segment, prod does not — with `x-api-key`; `access_token` valid 3600s).
Every POST needs `Authorization: Bearer <token>`, `Content-Type: application/json`, and a unique
`Idempotency-Key` (UUID v4). Read every endpoint, field name, and enum from the reference — don't emit from
memory, and watch the lowercase casing of `mitAgreement` / `processingModel`.

Ask the developer which path they want before writing code:

- **Use our gateway** — Payroc stores the schedule and collects payments. Best when the merchant wants Payroc
  to manage billing cycles, retries, and pauses/free-trials.
- **Use your own software** — the merchant's system owns the schedule and runs each charge itself. Best when
  they already have billing logic and just need to charge a stored card.

### Path 1 — Use our gateway (Payment Plans + Subscriptions)

The token already exists (it's the `CARDREFERENCE` from Stage A). Two calls, in order:

1. **Create a Payment Plan** — `POST /processing-terminals/{processingTerminalId}/payment-plans`. Required:
   `paymentPlanId`, `name`, `currency`, `type` (`manual`/`automatic`), `frequency`
   (`weekly`/`fortnightly`/`monthly`/`quarterly`/`yearly`), `onUpdate`, `onDelete`. For an `automatic` plan,
   include `recurringOrder.amount` (lowest denomination). `length: 0` runs indefinitely.
2. **Create a Subscription** — `POST /processing-terminals/{processingTerminalId}/subscriptions`. Required:
   `subscriptionId`, `paymentPlanId` (from step 1), `paymentMethod`, `startDate` (YYYY-MM-DD). Set
   `paymentMethod` to the secure-token variant:

   ```json
   { "type": "secureToken", "token": "<CARDREFERENCE>" }
   ```

   Optional: `setupOrder`, `recurringOrder`, `endDate`, `length`, `pauseCollectionFor` (e.g. a free-trial
   period). If you send both `length` and `endDate`, the gateway uses `endDate`.

For a `manual` subscription, collect each payment with
`POST .../subscriptions/{subscriptionId}/pay`. For `automatic`, the gateway collects on schedule. Manage the
lifecycle with `/deactivate` and `/reactivate`.

**Verify in UAT:** the subscription is created (HTTP 2xx) and `currentState.status` is `active`. For a
`manual` plan, also run one `/pay` call and confirm it succeeds.

#### Checkpoint

Payment plan created, subscription created with `paymentMethod.type: secureToken` + the `CARDREFERENCE` token,
and `currentState.status` is `active` in UAT (and a manual `/pay` succeeded if applicable)? Did you read the
plan/subscription enums from `references/repeat-payments-api-schema.md` first? If not, use the SKILL.md error
taxonomy.

### Path 2 — Use your own software (merchant-initiated transactions)

Run each charge yourself with `POST /payments`, passing the saved token and a `standingInstructions` block
that positions the transaction in the sequence:

- `paymentMethod`: `{ "type": "secureToken", "token": "<CARDREFERENCE>" }`
- `channel`: one of `pos` / `web` / `moto` (read the enum — don't invent `internet`/`online`/`ecommerce`)
- `order.amount`: lowest denomination
- `order.standingInstructions`: `sequence` (`first` for the initial stored-credential charge, `subsequent`
  thereafter) and `processingModel` (`unscheduled`/`recurring`/`installment`). On `subsequent` charges,
  include `referenceDataOfFirstTxn` (the first charge's `paymentId`).
- `credentialOnFile.mitAgreement` if you set it — note that sending `mitAgreement` **requires** the
  `standingInstructions` object in `order`.

The first charge is `sequence: first`; every later charge is `sequence: subsequent`. This mirrors the HPP
receipt's `STOREDCREDENTIALTXTYPE` (`FIRST_TXN` → `SUBSEQUENT_MERCHANT_INITIATED_TXN`).

**Verify in UAT:** the first MIT charge returns HTTP 200 and the `transactionResult` success branch passes —
read the `transactionResult.status` / `responseCode` enums from `references/api-schema.md` (the same
discipline as pre-auth capture; a real approval may come back as `ready` with `responseCode: "A"`, not
`"approved"`).

#### Checkpoint

First MIT charge runs with `paymentMethod.type: secureToken`, the correct `channel`, and `standingInstructions`
(`sequence: first`), returns HTTP 200, and the `transactionResult` success branch was verified against the
full enum from `references/api-schema.md`? If not, use the SKILL.md error taxonomy.

---

## Recurring limitations and notes

- **Token provenance.** With HPP save-card you never call the Secure Tokens *create* endpoint — HPP already
  minted the token and handed you `CARDREFERENCE`. Only create tokens server-side (`POST .../secure-tokens`)
  if a path needs to tokenize details the merchant already holds.
- **Agreement consistency.** The `STOREDCREDENTIALUSE` the customer consented to at save time (UPPERCASE on
  the form) should match the `mitAgreement` / `processingModel` you use when charging (lowercase on the API).
- **Bank-account tokens.** If the saved token represents ACH/bank-account details rather than a card, the
  `secureToken` payment method needs `accountType` and (for ACH) `secCode` — read the reference.

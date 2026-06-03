# Recurring Billing

Read this file when the developer's integration needs recurring billing (merchant-initiated repeat charges). It extends Step 4 of the standard Hosted Fields flow.

The most common shape: the **first** transaction is a one-shot sale that *also* tokenizes the card; **subsequent** transactions are server-to-server charges against the saved secure token. Both shapes are covered below.

---

## Schemas you will need (read from `references/api-schema.md` before writing any code here)

Recurring billing is the part of Hosted Fields where guessing field placement bites hardest, because the request body uses several objects that don't appear in the basic sale flow and the response shape is materially different from the request. Read these from the local schema reference, [`references/api-schema.md`](./api-schema.md), the authoritative copy for this skill — not from memory:

| Schema | What it tells you |
| --- | --- |
| `paymentRequest` | The top-level request shape. Required fields, and the fact that `credentialOnFile` and `standingInstructions` live in different places (read on). |
| `schemas-credentialOnFile` | The `tokenize` boolean — the bit that turns a plain sale into a sale-and-tokenize. |
| `standingInstructions` | The object that signals "this is part of a recurring series." Holds `sequence`, `processingModel`, and `referenceDataOfFirstTxn`. |
| `StandingInstructionsSequence` | Enum: `first`, `subsequent`. The only valid values. |
| `StandingInstructionsProcessingModel` | Enum: `recurring`, `installment`, `unscheduled`. The only valid values. |
| `firstTxnReferenceData` | Shape of `referenceDataOfFirstTxn` — holds `paymentId` and `cardSchemeReferenceId`. |
| `payment` (response) | The POST `/v1/payments` response. **Has no `paymentMethod` field.** Uses `card` instead. |
| `transactionResult` | Where `cardSchemeReferenceId` lives in the response — *not* on `card`. |
| `secureTokenSummary` | The shape inside `card.secureToken` — the durable `token` to persist for subsequent charges. |

Looking these up by name in `references/api-schema.md` is the fastest way to verify exact field placement. Don't infer shape from analogy with the request body — request and response diverge.

---

## What recurring billing means in the Hosted Fields context

Recurring billing uses `standingInstructions` to signal to the card network and issuer that a charge is part of a recurring or installment series. Payroc calls this "standing instructions" rather than "subscriptions" because you manage the schedule yourself — Payroc does not schedule or trigger charges.

Three processing models (from the `StandingInstructionsProcessingModel` enum):

- `recurring` — regular billing cycle with no defined end date (e.g. monthly subscription)
- `installment` — regular billing cycle with a defined end date (e.g. 12-month payment plan)
- `unscheduled` — merchant-initiated charge outside a regular cycle (e.g. usage-based top-up)

> **Note from the spec:** "If you don't use our Subscriptions mechanism, include this section to configure your standing/recurring orders."

---

## Where the pieces go in `paymentRequest`

This is the bit that's easy to get wrong. The request body has *two* objects that signal recurring intent, and they live in **different places**:

```text
paymentRequest                          ← top level
├── channel
├── processingTerminalId                ← flat string at top level — not nested
├── paymentMethod                       ← singleUseToken (first) or secureToken (subsequent)
├── credentialOnFile                    ← TOP LEVEL — for tokenize-on-first-charge
│   └── tokenize: true
└── order
    └── standingInstructions            ← INSIDE order — for the recurring signal
        ├── sequence
        ├── processingModel
        └── referenceDataOfFirstTxn (subsequent only)
```

`credentialOnFile` and `standingInstructions` are independent. You can have either, both, or neither. For a typical recurring-subscription first charge, you want **both**.

---

## Step 4 extension: the first transaction

Read: [`references/run-a-sale.md`](./run-a-sale.md) (for flow context) and [`references/api-schema.md`](./api-schema.md) (for `paymentRequest` shape).

The first transaction uses the standard Hosted Fields flow — a single-use token from `submissionSuccess` — plus two recurring-specific additions:

1. **`standingInstructions` inside `order`** to mark it as the first charge in a series.
2. **`credentialOnFile.tokenize: true` at the top level** so the gateway saves the card and returns a reusable `secureToken`. **Without this, no secure token is returned and there is no way to run a subsequent charge.** This is the most common silent failure in this flow.

The session-token request that preceded this charge must use `scenario: "payment"` (not `"tokenization"`) — the `HostedFieldsCreateSessionRequestScenario` enum description in the spec explicitly covers this case: `payment` means "run a sale **or** run a sale and tokenize in the same transaction."

```json
{
  "channel": "web",
  "processingTerminalId": "<your-terminal-id>",
  "paymentMethod": {
    "type": "singleUseToken",
    "token": "<single-use-token-from-submissionSuccess>"
  },
  "credentialOnFile": {
    "tokenize": true
  },
  "order": {
    "orderId": "<unique-order-id>",
    "amount": 1000,
    "currency": "USD",
    "standingInstructions": {
      "sequence": "first",
      "processingModel": "recurring"
    }
  }
}
```

> **Read these values from [`references/api-schema.md`](./api-schema.md).** The enums above (`payment`, `singleUseToken`, `first`, `recurring`) are the valid values recorded in the local schema reference — confirm each against that file before shipping rather than emitting from memory.

### What the first-charge response contains

The response is shaped by the `payment` schema in [`references/api-schema.md`](./api-schema.md) — **not** the `paymentRequest` schema you just sent. Three values to read and persist before doing anything else:

| Field | Path in response | What it's for |
| --- | --- | --- |
| `paymentId` | top-level | Identifies this transaction; used as `referenceDataOfFirstTxn.paymentId` in every subsequent charge. |
| `card.secureToken.token` | inside `card.secureToken` (shaped by `secureTokenSummary`) | The **durable token** you'll send as `paymentMethod.token` on subsequent charges (with `paymentMethod.type: "secureToken"`). |
| `transactionResult.cardSchemeReferenceId` | inside `transactionResult` | Card network's reference for the standing instruction series; used as `referenceDataOfFirstTxn.cardSchemeReferenceId` on subsequent charges. |

> **The response has no `paymentMethod` field.** That name appears in the *request* only. The response uses `card` (shape: `retrievedCard`). `cardSchemeReferenceId` is *not* under `card` — it's a sibling, under `transactionResult`. This is the schema mistake most likely to bite if you write the response handler by analogy with the request.
>
> **Persist all three to durable storage** (database fields on the customer or subscription record). They cannot be recovered if lost.

### Checkpoint

- HTTP 201 returned?
- `paymentId`, `card.secureToken.token`, and `transactionResult.cardSchemeReferenceId` all present in the response body and persisted to storage?
- If `card.secureToken` is missing: you almost certainly forgot `credentialOnFile.tokenize: true` in the request. Add it, regenerate the session token (single-use tokens are one-shot), and retry.

---

## Subsequent transactions

Subsequent charges do not go through the Hosted Fields form — there is nothing for the customer to interact with. Your server calls `/v1/payments` directly using the saved secure token.

Read: [`references/run-a-sale.md`](./run-a-sale.md) (same page — read the `secureToken` payment method variant and the `subsequent` sequence values), and reconfirm `paymentRequest` in [`references/api-schema.md`](./api-schema.md).

Differences from the first transaction:

- `paymentMethod.type` is `"secureToken"` (not `"singleUseToken"`)
- `paymentMethod.token` is the saved secure token (the value of `card.secureToken.token` from the first response)
- `credentialOnFile` is **omitted** — you're not tokenizing again
- `standingInstructions.sequence` is `"subsequent"`
- `standingInstructions.referenceDataOfFirstTxn` includes the persisted `paymentId` and `cardSchemeReferenceId`
- A fresh `Idempotency-Key` (UUID v4) and a fresh `orderId` per charge

```json
{
  "channel": "web",
  "processingTerminalId": "<your-terminal-id>",
  "paymentMethod": {
    "type": "secureToken",
    "token": "<saved-secure-token>"
  },
  "order": {
    "orderId": "<unique-order-id-for-this-charge>",
    "amount": 1000,
    "currency": "USD",
    "standingInstructions": {
      "sequence": "subsequent",
      "processingModel": "recurring",
      "referenceDataOfFirstTxn": {
        "paymentId": "<paymentId-from-first-transaction>",
        "cardSchemeReferenceId": "<cardSchemeReferenceId-from-first-transaction>"
      }
    }
  }
}
```

### Checkpoint

Does a subsequent charge return HTTP 201 in UAT using the saved secure token and the persisted reference data?

---

## Implementation notes

- **Each charge needs a unique `orderId`** — do not reuse the first transaction's `orderId` for subsequent charges.
- **Each charge needs a unique `Idempotency-Key`** — a fresh UUID v4 per request.
- **`processingModel` must match** across first and subsequent transactions in the same series. Read the values from `StandingInstructionsProcessingModel` in the spec, don't paraphrase them.
- **There is no Payroc-side schedule** — your application is responsible for triggering charges at the right time.
- If a subsequent charge is declined, do not automatically retry with the same `Idempotency-Key`. Generate a new key and a new `orderId` for any retry attempt.
- **If the first charge succeeds but `card.secureToken` is absent from the response:** `credentialOnFile.tokenize: true` was missing from the request. The single-use token is now consumed, so the customer must re-enter card details through a fresh Hosted Fields session.

---

## Subsequent transactions: handling declines

Subsequent charges are merchant-initiated, so a decline does not interrupt a customer in front of your checkout — but it does mean your application is now responsible for the recovery loop. The patterns below are the typical merchant-side response shapes; the authoritative `transactionResult.responseCode` enumeration lives in [`references/api-schema.md`](./api-schema.md).

### Classify by `transactionResult.responseCode`

Branch on `transactionResult.responseCode` and `transactionResult.status` to decide whether to retry, ask the customer to update payment details, or stop. The common codes split into three buckets:

| Bucket | Common codes | Action |
| --- | --- | --- |
| **Retry later** — temporary issuer state | `05` (do not honor) on first attempt, `51` (insufficient funds), `61` (exceeds withdrawal limit), `91` (issuer unavailable) | Schedule a retry on day +1 / +3 / +7. Generate a fresh `Idempotency-Key` and a fresh `orderId` per retry — never reuse them. |
| **Customer must intervene** — card no longer usable | `54` (expired card), `41`/`43` (lost / stolen), `14` (invalid account), `78` (closed account) | Email the customer to update payment details. Do not retry until they re-run the "Update a customer's saved card" extension (`scenario: "tokenization"` on a fresh session) or a fresh first-charge flow with a new card. |
| **Hard decline — do not retry** | `04` (pick up card), `07` (pick up card, special), `93` (transaction cannot be completed — violation of law) | Suspend the subscription. Email the customer. Flag for internal review. |

For the authoritative list, read the `transactionResult.responseCode` enum in [`references/api-schema.md`](./api-schema.md) — these are the most common codes, not the complete set.

### When the saved `secureToken` is no longer valid

If `paymentMethod.type: "secureToken"` is rejected outright (card reported lost / stolen / closed, or the issuer revoked the standing instruction), the durable token cannot be revived — there is no API call that "refreshes" a dead secure token. Two recovery paths:

- **Update the card via tokenization** (preferred when the customer is still active). Run the "Update a customer's saved card" extension (`scenario: "tokenization"`, non-transactional) to re-tokenize the customer's new card. The new secure token replaces the old one on your `Customer` record; the `paymentId` and `cardSchemeReferenceId` from the original first transaction *can* be reused — the standing instruction series is preserved.
- **Start a new series.** Treat the next charge as a brand-new "first" transaction: Hosted Fields session token, `submissionSuccess`, single-use token, `credentialOnFile.tokenize: true`, `standingInstructions.sequence: "first"`. Persist the *new* `secureToken` / `paymentId` / `cardSchemeReferenceId`; the previous values become orphan history.

### Sketch of a dunning loop

A minimal production-shaped retry loop:

1. **Charge fails (retry-later bucket).** Persist the failure with `responseCode` and `attemptedAt`. Increment a retry counter.
2. **Day +1, +3, +7.** Background worker re-tries `ExecuteRecurringChargeAsync` with a fresh `Idempotency-Key` and `orderId`. If the result is `approved`, clear the retry counter and resume normal cadence.
3. **After N failed retries (e.g. 4)** or any "customer must intervene" / "hard decline" response: mark the subscription `PaymentStatus = "PaymentFailed"`, send the customer an email pointing at your "update payment details" flow, and stop attempting charges.
4. **Customer updates payment details** → reset retry counter, resume cadence on the next scheduled date.
5. **Customer does nothing for M days** (e.g. 14): suspend the subscription.

This loop is intentionally minimal — production systems usually add per-decline-bucket retry policies, exponential backoff with jitter, anti-thrash guards, and merchant-configurable customer messaging. The shape above is enough to keep transient declines from causing involuntary churn.

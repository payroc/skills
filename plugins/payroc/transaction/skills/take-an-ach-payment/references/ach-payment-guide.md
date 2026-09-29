# ACH / Bank Transfer Payments — Narrative Guide

> **Local snapshot — narrative guide for this skill.** Sources: Payroc developer documentation at
> `https://docs.payroc.com/guides/take-payments/payments/run-a-sale-with-bank-account-details.md`,
> `https://docs.payroc.com/guides/take-payments/payments/re-present-an-ach-payment.md`,
> `https://docs.payroc.com/guides/take-payments/payments/refunds/referenced-refunds/bank.md`,
> `https://docs.payroc.com/guides/take-payments/payments/refunds/reversals/bank.md`.
> Last synced: 2026-09-24.

---

## What ACH / Bank Transfer Payments Are

ACH (Automated Clearing House) is a U.S. bank-to-bank network for transferring funds between accounts.
PAD (Pre-Authorized Debit) is the Canadian equivalent.

The Payroc Bank Transfer Payments API allows merchants to:
- Initiate payments directly from a customer's bank account (no card required)
- Store bank account details as a secure token for future charges
- Reverse payments still in an open batch (before settlement)
- Issue refunds to bank accounts
- Re-present (retry) returned/declined ACH payments

---

## ACH vs PAD

| Feature | ACH | PAD |
| --- | --- | --- |
| Region | United States | Canada |
| Routing identifier | 9-digit routing number | 5-digit transit number + 3-digit institution number |
| `paymentMethod.type` | `"ach"` | `"pad"` |
| SEC code required | Yes (`secCode` field) | No |
| Account types | `checking`, `savings` | `checking`, `savings` |

**Note on UAT availability:** ACH payments have limited UAT testability in the current test environment. PAD representment is known to be broken in UAT. Test ACH where possible but be aware UAT coverage may be incomplete.

---

## Creating a Payment

The `POST /v1/bank-transfer-payments` endpoint creates a bank transfer payment. The gateway returns a
`paymentId` which is used for all follow-on operations (retrieval, refund, reversal, representment).

### Order amounts

The `order.amount` field is an **integer in the currency's lowest denomination** — for USD and CAD this
is cents. `$49.99` is `4999`, not `49.99`.

### Tokenization

Setting `credentialOnFile.tokenize: true` instructs the gateway to store the bank account details and
return a `secureToken` in the response. Use this token (`type: "secureToken"`) in future payment
requests to charge the same account without re-collecting account details.

### Account masking

All responses mask account numbers and routing numbers. Only the last 4 digits of the account number
are preserved (e.g., `*****5929`). The full account number is never returned in responses.

---

## Payment Lifecycle

```
created → ready → pending → complete
                          ↘ declined
                          ↘ returned   → (representment) → pending → complete
                                                                    ↘ declined
         open batch → reversal (void before settlement)
```

### Status descriptions

- `ready` — Payment is queued, not yet sent to processor
- `pending` — Payment submitted to processor, awaiting bank confirmation
- `complete` — Funds successfully transferred
- `declined` — Processor rejected the transaction (may be retried/re-presented)
- `reversal` — Payment was voided before settlement; no funds moved
- `returned` — Bank returned the payment after settlement (NSF, closed account, etc.)
- `admin` — Administrative hold; contact Payroc support

---

## Reversal (void)

Use `POST /v1/bank-transfer-payments/{paymentId}/reverse` to void a payment **still in an open batch**.
When reversed, the payment is removed from the batch and no funds are taken from the customer.

**Important:** If a referenced refund is run on a payment still in an open batch, the gateway
automatically reverses it (rather than routing a return). No explicit reversal needed in that case.

---

## Refunds

Use `POST /v1/bank-transfer-payments/{paymentId}/refund` to issue a referenced refund against a PAD
payment. The body requires `amount` and `description`. To issue a refund not linked to an existing
payment (unreferenced), use `POST /v1/bank-transfer-refunds` instead.

**ACH payments:** You can't run a referenced refund against an ACH payment that is in a closed batch.
Our gateway returns a `400` error, `Bank transfer with status COMPLETE can not be refunded`. To return
funds for an ACH payment after its batch closes, run an unreferenced refund
(`POST /v1/bank-transfer-refunds`) instead. This doesn't apply to pre-authorized debit (PAD) payments.
Before calling the referenced refund for an ACH payment, retrieve the payment and check
`transactionResult.status`. If it is `complete`, the batch has closed, so go straight to the unreferenced refund.

**Refund timing note:** If the original payment is still in an open batch when the refund is requested,
the gateway automatically reverses it instead of processing a true refund. That response carries
`transactionResult.type: "payment"` and `status: "reversal"`, with a positive `authorizedAmount`.

---

## Re-presentment (retrying returned ACH payments)

When an ACH payment is returned by the bank (e.g., NSF, closed account), a merchant can re-present
it after resolving the issue with the customer.

**Critical workflow note:** When re-presenting:
1. First retrieve the original payment via `GET /v1/bank-transfer-payments/{paymentId}`
2. Find the `returns[]` array in the response — each returned transaction has its own `paymentId`
3. Use **that return's `paymentId`** in the re-present request — **not** the original `paymentId`
4. Optionally supply updated bank account details in the request body if the customer's account changed
5. Payments can be re-presented a maximum of **two times**

**UAT note:** PAD representment is known to be broken in the current UAT environment. ACH representment
may also have limited testability. These operations are documented here for completeness; test against
UAT where possible.

---

## Settlement

ACH payments settle on a batch cycle. The `settlementState` filter on the list endpoint supports
`unsettled` (in an open batch) and `settled` (processed and funded).

ACH deposits are viewable via the ACH Deposits reporting API (separate skill: `view-ach-deposits`).

---

## Customer notifications

Set `customer.notificationLanguage` to the ISO language code (e.g., `"en"`) and provide an email in
`customer.contactMethods` to enable Payroc's customer notification emails for the payment.

---

## Credential on file / tokenization

After a successful payment with `credentialOnFile.tokenize: true`, the response `bankAccount` object
includes a `secureToken`:

```json
{
  "secureToken": {
    "token": "296753xxxxxxxxx",
    "status": "bankAccountValidated"
  }
}
```

Store this token and use it as `paymentMethod: { "type": "secureToken", "token": "..." }` in future
payment requests. This avoids re-collecting bank account details on repeat charges.

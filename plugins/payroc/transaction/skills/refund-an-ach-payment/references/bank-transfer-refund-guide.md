# Payroc — Bank Transfer Refunds Guide

> **Local snapshot — authoritative for this skill.**
> Sources:
> - https://docs.payroc.com/guides/take-payments/payments/refunds/referenced-refunds/bank.md
> - https://docs.payroc.com/guides/take-payments/payments/refunds/unreferenced-refunds/bank.md
> - https://docs.payroc.com/guides/take-payments/payments/refunds/reversals/bank.md
>
> Last synced: 2026-09-18.

---

## Overview: Three Ways to Reverse or Refund an ACH Payment

Payroc supports three methods. Choose based on the payment method, whether the payment has settled, and whether you have the original payment ID:

| Method | When to use |
| --- | --- |
| **Reverse** | Payment is still in an open batch (not yet settled). Cancels before settlement — no funds move. |
| **Referenced refund** | PAD payment in a closed batch, where you have the original `paymentId`. **Not available for an ACH payment in a closed batch** — see below. |
| **Unreferenced refund** | Any ACH payment in a closed batch, or a closed-batch PAD payment where you do NOT have the original `paymentId`. Requires special merchant account enablement. |

> **ACH payments:** You can't run a referenced refund against an Automated Clearing House (ACH) payment that is in a closed batch. Our gateway returns a `400` error, `Bank transfer with status COMPLETE can not be refunded`. To return funds for an ACH payment after its batch closes, run an unreferenced refund (`POST /v1/bank-transfer-refunds`) instead. This restriction doesn't apply to pre-authorized debit (PAD) payments.

> **Gateway auto-conversion:** If a referenced refund runs against a bank transfer payment of either method while it is still in an open batch, our gateway cancels the payment rather than refunding it. This is a property of the endpoint, not something specific to ACH. **Check the batch state first,** so you know which of the two operations you are actually performing.

---

## Referenced Refund Flow

Applies to a PAD payment in a closed batch, or to either payment method while the batch is still open, where the gateway converts the call into a reversal. For an ACH payment in a closed batch, use the Unreferenced Refund Flow instead.

### Step 1 — Authenticate

Exchange your API key for a Bearer token (see `identity-call.md`).

### Step 2 — Find the original payment

Required for ACH, since it is how you learn whether this path is available at all. Optional for PAD when you already hold the `paymentId`.

**List payments:**
```
GET /v1/bank-transfer-payments?processingTerminalId={id}&orderId={orderId}
```

**Retrieve by ID:**
```
GET /v1/bank-transfer-payments/{paymentId}
```

Read `bankAccount.type` and `transactionResult.status`, and confirm the payment is not already reversed or refunded. `type: "ach"` with `status: "complete"` means this flow will fail — go to the Unreferenced Refund Flow.

### Step 3 — Issue the referenced refund

```
POST /v1/bank-transfer-payments/{paymentId}/refund
Authorization: Bearer <access_token>
Idempotency-Key: <UUID v4>
Content-Type: application/json

{
  "amount": 4999,
  "description": "Refund for order OrderRef6543"
}
```

`amount` and `description` are both required — an empty body returns `400` naming both. The bank account details are taken from the original payment, but the amount is not: send the full original amount for a full refund, or a lower value for a partial one.

**Expected response:** HTTP 200 with the full `bankTransferPayment` object. What it contains depends on which action the gateway took:

| | Auto-converted reversal (open batch) | Genuine refund (PAD, closed batch) |
| --- | --- | --- |
| `transactionResult.type` | `"payment"` | `"refund"` |
| `transactionResult.status` | `"reversal"` | `"ready"` or `"pending"` initially |
| `transactionResult.authorizedAmount` | positive | negative (e.g. `-4999`) |

### Key notes for referenced refunds

- ACH refunds are **not instant** — expect `"pending"` status. The funds transfer takes 1–3 business days to complete.
- Final status (e.g. `"complete"` or `"returned"`) arrives asynchronously. Poll `GET /v1/bank-transfer-payments/{paymentId}` or use webhooks.
- If the payment was in an open batch, the gateway reverses it automatically instead of issuing a refund. That response is a success, even though `type` stays `"payment"` and the amount is positive.
- Once the batch closes, you can't run a referenced refund against an ACH payment at all.

---

## Unreferenced Refund Flow

> **Prerequisite:** Only certain merchant accounts can send unreferenced refunds. Confirm enablement with the Payroc Integrations team before implementing this path.

### Step 1 — Authenticate

Exchange your API key for a Bearer token.

### Step 2 — Issue the unreferenced refund

```
POST /v1/bank-transfer-refunds
Authorization: Bearer <access_token>
Idempotency-Key: <UUID v4>
Content-Type: application/json
```

**Request body (ACH):**
```json
{
  "processingTerminalId": "1234001",
  "order": {
    "orderId": "REFUND-OrderRef6543",
    "description": "Refund for order OrderRef6543",
    "amount": 4999,
    "currency": "USD"
  },
  "refundMethod": {
    "type": "ach",
    "accountNumber": "1234567890",
    "nameOnAccount": "Sarah Hazel Hopper",
    "routingNumber": "123456789",
    "accountType": "checking",
    "secCode": "web"
  },
  "customer": {
    "notificationLanguage": "en",
    "contactMethods": [{"type": "email", "value": "sarah.hopper@example.com"}]
  }
}
```

**Expected response:** HTTP 201 with `bankTransferRefund` object. Check:
- `refundId` — save this for tracking
- `transactionResult.type` = `"unreferencedRefund"`
- `transactionResult.status` — expect `"pending"` for ACH

---

## Reversal Flow

### Reverse a bank transfer payment (open batch only)

```
POST /v1/bank-transfer-payments/{paymentId}/reverse
Authorization: Bearer <access_token>
Idempotency-Key: <UUID v4>
Content-Type: application/json
```

No request body required. Returns HTTP 200 with the updated `bankTransferPayment` object.

### Reverse a refund

```
POST /v1/bank-transfer-refunds/{refundId}/reverse
Authorization: Bearer <access_token>
Idempotency-Key: <UUID v4>
Content-Type: application/json
```

Returns HTTP 200 with the updated `bankTransferRefund` object.

---

## Tracking Refund Status

ACH transactions are batch-processed, so refunds are asynchronous. After submitting:

1. Check `transactionResult.status` in the initial response.
2. Poll `GET /v1/bank-transfer-payments/{paymentId}` (for referenced refunds) and inspect `refunds[]` array.
3. Or poll `GET /v1/bank-transfer-refunds/{refundId}` for unreferenced refunds.
4. Terminal statuses: `"complete"` (funds returned), `"returned"` (NACHA return — bank rejected), `"declined"`.

---

## Common Issues

> The error strings below are quoted so you can recognise them when debugging. They are produced by the
> gateway, not fixed by the spec, so match on the payment's state rather than on the message text.

- **`"returned"` status:** The customer's bank rejected the ACH return (NACHA return code). Common causes: closed account, invalid routing/account number. A returned refund may need to be resolved outside of ACH (e.g. a check or wire).
- **Unreferenced refund 403:** The terminal/merchant account is not enabled for unreferenced refunds. Contact Payroc Integrations.
- **Referenced refund on already-refunded payment:** The API will reject with a 400 or 409 if the payment has already been fully refunded. Check `payment.refunds[]` first.
- **`Bank transfer with status COMPLETE can not be refunded`:** A referenced refund against an ACH payment in a closed batch. Retrying will never succeed — switch to the unreferenced refund. The message quotes the gateway's internal status name in uppercase; the payment's own `transactionResult.status` reads `complete`.
- **`Bank transfer with status VOID can not be refunded`:** The same status gate on a payment that was already reversed, including one auto-converted by an earlier referenced refund call.
- **Referenced refund 400 on `amount` and `description`:** The request body was empty or partial. Both fields are required; the gateway does not infer them from the original payment.
- **Amount in cents:** All `amount` fields are in the currency's smallest denomination. $49.99 = `4999`, not `49.99`.

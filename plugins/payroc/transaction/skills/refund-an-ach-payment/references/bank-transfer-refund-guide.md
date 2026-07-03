# Payroc — Bank Transfer Refunds Guide

> **Local snapshot — authoritative for this skill.**
> Sources:
> - https://docs.payroc.com/guides/take-payments/payments/refunds/referenced-refunds/bank.md
> - https://docs.payroc.com/guides/take-payments/payments/refunds/unreferenced-refunds/bank.md
> - https://docs.payroc.com/guides/take-payments/payments/refunds/reversals/bank.md
>
> Last synced: 2026-06-22.

---

## Overview: Three Ways to Reverse or Refund an ACH Payment

Payroc supports three methods. Choose based on whether the payment has settled and whether you have the original payment ID:

| Method | When to use |
| --- | --- |
| **Reverse** | Payment is still in an open batch (not yet settled). Cancels before settlement — no funds move. |
| **Referenced refund** | Payment has settled. You have the original `paymentId`. API sends funds back via ACH. |
| **Unreferenced refund** | Payment has settled. You do NOT have the original `paymentId`. Requires special merchant account enablement. |

> **Gateway auto-conversion:** If you run a referenced refund on a payment that is still in an open batch, the gateway automatically converts it to a reversal. The net effect is the same — the payment is cancelled — but you don't need to check the batch status before calling the referenced refund endpoint.

---

## Referenced Refund Flow

### Step 1 — Authenticate

Exchange your API key for a Bearer token (see `identity-call.md`).

### Step 2 (Optional) — Find the original payment

If you already have the `paymentId`, skip to Step 3.

**List payments:**
```
GET /v1/bank-transfer-payments?processingTerminalId={id}&orderId={orderId}
```

**Retrieve by ID:**
```
GET /v1/bank-transfer-payments/{paymentId}
```

Confirm `transactionResult.status` and that the payment is not already reversed or refunded.

### Step 3 — Issue the referenced refund

```
POST /v1/bank-transfer-payments/{paymentId}/refund
Authorization: Bearer <access_token>
Idempotency-Key: <UUID v4>
Content-Type: application/json
```

The refund applies to the full original payment amount. The bank account details are taken from the original payment — you do not re-supply them.

**Expected response:** HTTP 200 with the full `bankTransferPayment` object. Check:
- `transactionResult.type` = `"refund"`
- `transactionResult.status` — initially `"ready"` or `"pending"` for ACH (ACH refunds are not instant)
- `transactionResult.authorizedAmount` — negative value (e.g. `-4999` for a $49.99 refund)

### Key notes for referenced refunds

- ACH refunds are **not instant** — expect `"pending"` status. The funds transfer takes 1–3 business days to complete.
- Final status (e.g. `"complete"` or `"returned"`) arrives asynchronously. Poll `GET /v1/bank-transfer-payments/{paymentId}` or use webhooks.
- If the payment was in an open batch, the gateway reverses it automatically instead of issuing an ACH refund.

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

- **`"returned"` status:** The customer's bank rejected the ACH return (NACHA return code). Common causes: closed account, invalid routing/account number. A returned refund may need to be resolved outside of ACH (e.g. a check or wire).
- **Unreferenced refund 403:** The terminal/merchant account is not enabled for unreferenced refunds. Contact Payroc Integrations.
- **Referenced refund on already-refunded payment:** The API will reject with a 400 or 409 if the payment has already been fully refunded. Check `payment.refunds[]` first.
- **Amount in cents:** All `amount` fields are in the currency's smallest denomination. $49.99 = `4999`, not `49.99`.

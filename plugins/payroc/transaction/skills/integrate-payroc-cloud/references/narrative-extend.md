# Narrative — extend a Payroc Cloud integration

Source of truth for **how to sequence** the follow-on flows. For field names, types, and enum values,
use `api-schema.md`. Last synced: 2026-06-17. Sources:
`docs.payroc.com/essentials/payroc-cloud/extend-your-integration*.md` (see `_sources.md`).

All of these build on the core submit → poll → follow-link → retrieve pattern in
`narrative-run-a-sale.md`. They become available once you can run a sale.

## Capture a signature (standalone)

Signature capture is **not tied to a payment** — the submit body is just `{ "processingTerminalId":
"..." }`. Use it for standalone capture or to capture after a transaction.

1. **Submit:** `POST /v1/devices/{serialNumber}/signature-instructions` (Idempotency-Key required) →
   `202` with `signatureInstructionId` and a `link`.
2. **Poll:** `GET /v1/signature-instructions/{signatureInstructionId}`. On `completed`, `link.rel` is
   `signature` and `link.href` points at `/signatures/{signatureId}`.
3. **Retrieve:** `GET /v1/signatures/{signatureId}` → `200` with `contentType` (e.g. `image/png`) and
   `signature` (Base64 image data). Decode `signature` to render/store the image.

## Run an unreferenced refund (device instruction)

A standalone refund not linked to a prior payment. It runs **on the device** and follows the
instruction pattern.

1. **Submit:** `POST /v1/devices/{serialNumber}/refund-instructions` with a `refundInstructionRequest`
   (Idempotency-Key required). Note `order.description` is **required** on a refund order. → `202`
   with `refundInstructionId`.
2. **Poll:** `GET /v1/refund-instructions/{refundInstructionId}`. On `completed`, `link.rel` is
   `refund`, `link.href` → `/refunds/{refundId}`.
3. **Retrieve:** `GET /v1/refunds/{refundId}` → `200` with the refund details.

## Run a referenced refund (payments API, needs the original payment)

A referenced refund is tied to an original payment and goes through the **standard payments API**, not
a device instruction. You need the original `paymentId` first.

1. **Find the payment.** If you have the `paymentId`, `GET /v1/payments/{paymentId}`. Otherwise search:
   `GET /v1/payments?last4=7062&cardholderName=Sarah` (also `first6`, `orderId`, `operator`,
   `dateFrom`/`dateTo`, `status`, `type`, `processingTerminalId`). Read `paymentId` from the matching
   summary.
2. **Submit the refund:** `POST /v1/payments/{paymentId}/refunds` (Idempotency-Key required), body
   `{ "amount": 4999, "currency": "USD" }` → `201`.
3. **Retrieve:** `GET /v1/payments/{paymentId}/refunds/{refundId}` → `200` (`refundSummary`: `status`,
   `responseCode`, `responseMessage`, etc.).

> **Open-batch gotcha.** If the original payment is still in an **open batch**, running a referenced
> refund makes the gateway **auto-cancel (reverse)** the payment rather than create a separate refund.
> If your intent is specifically to cancel an open-batch payment, reverse it (below) instead of
> refunding.

## Reverse a card sale or pre-authorization (payments API)

Reversal cancels (or partially cancels) a payment that is still in an **open batch**. The payment is
removed from the merchant's open batch and no funds are taken from the cardholder — distinct from a
refund, which returns funds on a settled payment.

1. **Find the payment** (optional if you already hold the `paymentId`): `GET /v1/payments` filtered by
   `processingTerminalId`, `orderId`, `type=sale`/`preAuthorization`, `status=ready`/`accepted`.
   Inspect the retrieved payment's `supportedOperations` — it lists what's allowed (`refund`,
   `fullyReverse`, `partiallyReverse`).
2. **Reverse:** `POST /v1/payments/{paymentId}/reverse` (Idempotency-Key required). Body is optional:
   omit `amount` to reverse the full payment, or supply `amount` (cents) to partially reverse;
   `operator` is optional. → `200` with the updated payment.

**Reverse vs refund, in one line:** open batch, no funds moved yet → **reverse**; already settled →
**refund**. A referenced refund on an open-batch payment auto-reverses, so be deliberate about which
you intend.

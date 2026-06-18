# Narrative — run a sale through Payroc Cloud

Source of truth for **how to sequence the calls**. For field names, enum values, and request/response
shapes, use `api-schema.md`. Last synced: 2026-06-17. Source:
`docs.payroc.com/essentials/payroc-cloud/run-a-sale.md` (see `_sources.md`).

## The premise

The skill picks up at *"you have a paired device's `serialNumber`"*. Configuring/pairing the physical
device is out of scope. If you don't have a serial number, `GET /devices` finds one (see
`api-schema.md`). The Payroc Cloud Simulator (`cloud.uat.payroc.com`) also hands out a mock serial
number per browser tab for testing without hardware.

## The one pattern: submit → poll → follow link → retrieve

Every Cloud operation (sale, refund, signature) is the same asynchronous shape. Learn it once.

### Step 1 — Submit the instruction

```text
POST /v1/devices/{serialNumber}/payment-instructions
Authorization: Bearer <token>
Content-Type: application/json
Idempotency-Key: <UUID v4>
```

Body: a `paymentInstructionRequest` (see `api-schema.md`). Returns **`202 Accepted`** with the
instruction object:

```json
{
  "status": "inProgress",
  "paymentInstructionId": "a37439165d134678a9100ebba3b29597",
  "link": {
    "rel": "self", "method": "GET",
    "href": "https://api.payroc.com/v1/payment-instructions/a37439165d134678a9100ebba3b29597"
  }
}
```

The `202` means *the gateway accepted the instruction and is relaying it to the device* — not that the
sale succeeded. Persist `paymentInstructionId`.

### Step 2 — Poll the instruction (the gateway long-holds for you)

```text
GET /v1/payment-instructions/{paymentInstructionId}
Authorization: Bearer <token>
```

**The gateway waits up to ~60 seconds for the status to change before responding.** So you do *not*
need a tight polling loop or your own sleep — issue the GET, wait for it to return, and only re-issue
if the status is still `inProgress` (e.g. the cardholder is still interacting with the device).

Status values: `inProgress`, `completed`, `failure`, `canceled`.

- `inProgress` → poll again.
- `completed` → the `link` now points at the **resulting payment**:
  ```json
  {
    "status": "completed",
    "paymentInstructionId": "a37439165d134678a9100ebba3b29597",
    "link": { "rel": "self", "method": "GET",
              "href": "https://api.payroc.com/v1/payments/{paymentId}" }
  }
  ```
- `failure` → read `errorMessage`.
- `canceled` → the instruction was cancelled before completing.

### Step 3 — Follow the link and retrieve the payment

Do **not** construct the payment URL yourself from the instruction id — the instruction id and the
payment id are different values. Follow `link.href`:

```text
GET /v1/payments/{paymentId}
Authorization: Bearer <token>
```

The retrieved payment carries the real outcome — `transactionResult` / `responseCode` etc. (bank
approval lives here, not on the instruction).

### Cancelling

While the instruction is still `inProgress` you can cancel it:

```text
DELETE /v1/payment-instructions/{paymentInstructionId}   -> 204 No Content
```

Once it has left `inProgress` (completed/failure/canceled), cancelling returns `409 Conflict`. If
you're unsure of the current state, GET the instruction first and read `status`.

## Sale vs pre-authorization vs immediate settle

- **Sale (default):** `autoCapture: true` (the default). Authorizes and captures.
- **Pre-authorization:** `autoCapture: false`. Authorizes only; capture later.
- **Immediate settle:** `processAsSale: true`. Settles immediately, ignores `autoCapture`, and blocks
  later adjustments. Default is `false`.

## Idempotency

Generate a fresh UUID v4 `Idempotency-Key` for each new submission. To retry a submission that may or
may not have gone through (network blip), resend the **identical** body with the **same** key — the
gateway returns the original result instead of submitting a second instruction to the device. Changing
the body but keeping the key is a `409`.

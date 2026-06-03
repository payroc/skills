# Pre-Authorization Flow

Read this file when the developer's integration includes pre-authorizations. It covers everything that differs from the standard sale flow: the correct endpoint, the capture API, and the test path.

---

## Step 2 (pre-auth): Load the Hosted Payment Page

Read: references/load-hosted-payment-page.md

The pre-auth endpoint differs from the sale endpoint only in the path segment (`preauthpage` instead of `paymentpage`). The form-POST field set, enum values, and hash recipe are identical to the sale flow — read them from the local reference; don't emit any field name or enum value from memory.

As a verification anchor: the UAT pre-auth endpoint should be `https://payments.uat.payroc.com/merchant/preauthpage` and production `https://payments.payroc.com/merchant/preauthpage`. If the reference shows different values, use what the reference says and note the discrepancy.

All request parameters are identical to the sale flow (TERMINALID, ORDERID, CURRENCY, AMOUNT, DATETIME, HASH). The hash format is also unchanged.

### Checkpoint

Does submitting the form redirect the browser to the Payroc UAT pre-auth payment page without an error? If not, diagnose before continuing.

---

## Step 3 (pre-auth): Receipt page

Read: references/build-receipt-page.md

The receipt page response parameters and hash verification format are the same as for a sale. The critical difference is how `UNIQUEREF` must be handled:

- `UNIQUEREF` from a pre-auth receipt is the identifier you will pass to the capture API as the `:paymentId` path parameter.
- It must be persisted to durable storage — a database field on the order record — before you do anything else. Session, TempData, or in-memory state will not survive the time between authorization and capture.

Confirm from the docs which fields are included in the response hash and their exact order before implementing verification.

### Checkpoint

Receipt handler verifies the response hash, branches on `RESPONSECODE`, and writes `UNIQUEREF` to durable storage? If not, resolve before continuing.

---

## Step 4: Capture the pre-authorization

Read: references/api-schema.md

The capture is a REST API call — entirely separate from the HPP form flow. It uses Bearer token authentication, not the HMAC hash used for the HPP form. The capture endpoint, request/response shapes, and the `transactionResult` enums are documented in `references/api-schema.md` — read them from there.

### Prerequisites for capture

Before writing the capture handler, confirm:

1. **API key for the identity service** — you need an `x-api-key` to obtain a Bearer token from `POST https://identity.payroc.com/authorize`. This may or may not be the same credential as the terminal secret; ask the developer which API key they have for the REST API. If they don't have one, direct them to the Payroc Integrations team.
2. **UNIQUEREF stored** — the capture call needs the `UNIQUEREF` value written to durable storage in Step 3.

### Obtaining a Bearer token

```
POST https://identity.payroc.com/authorize
x-api-key: <api_key>
```

The response contains an `access_token` valid for 3600 seconds. Store it appropriately for the lifetime of a request — don't regenerate it on every call if you can reuse it within the expiry window.

### Capture call

```
POST https://api.uat.payroc.com/v1/payments/{UNIQUEREF}/capture
Authorization: Bearer <access_token>
Content-Type: application/json
Idempotency-Key: <uuid-v4>
```

The request body is optional. Omit it entirely to capture the full pre-authorized amount. To capture a partial amount, include:

```json
{
  "paymentCapture": {
    "amount": 1000
  }
}
```

Amount is in the lowest denomination of the currency (e.g. cents). If you need to capture more than the original pre-auth amount, the Adjust Payment endpoint must be called first.

For production, replace `api.uat.payroc.com` with `api.payroc.com`.

### Idempotency

Every capture request must include a unique `Idempotency-Key` (UUID v4). If you need to retry a failed request, reuse the same key — the gateway will return the original result rather than processing a duplicate.

### Response

A successful capture returns HTTP 200 with a `payment` object containing `transactionResult`. Check `transactionResult.responseCode` *and* `transactionResult.status` in the response — HTTP 200 confirms the API accepted the request, not necessarily that the capture succeeded.

> **`transactionResult.status` and `transactionResult.responseCode` are both enums on the Payroc REST API.** Read the `transactionResult` schema from `references/api-schema.md` before you write the capture-response handler. Do not branch on a remembered subset of either enum. **Known past failure (from sibling integrations):** branching on `transactionResult.status == "approved"` only and silently treating real approvals as failures because the actual value was `"ready"` (authorized + queued for settlement) with `responseCode: "A"` / `responseMessage: "APPROVAL"`. Read the full enum from the reference, identify every value that pairs with bank approval, and branch on that set.

### Checkpoint

Does the capture call return HTTP 200 with `transactionResult` in the response body? Did you read the `transactionResult.status` / `responseCode` enums from `references/api-schema.md` before writing the success branch? If not, use the error taxonomy in SKILL.md before continuing.

---

## Pre-auth limitations

Pre-auth is not available in the following scenarios — if the merchant's account has any of these, the pre-auth attempt will process as a sale instead:

- Merchant uses dual pricing or a surcharging program
- Merchant applies convenience fees
- Customer pays by bank account

If a pre-auth appears to go through but the response looks like a sale, check with the Payroc Integrations team whether the account has these features enabled.

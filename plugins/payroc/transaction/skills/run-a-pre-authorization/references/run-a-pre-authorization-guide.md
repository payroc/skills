# Run a Pre-Authorization — Narrative Guide

> **Local snapshot — authoritative for this skill.**
> Source: `https://docs.payroc.com/guides/take-payments/payments/run-a-pre-authorization.md`
> Last synced: 2026-06-22.

---

## Overview

A pre-authorization allows a merchant to hold (reserve) an amount on a customer's card without immediately capturing funds. The held amount is later captured when the goods or services are fulfilled — or released (reversed) if the transaction is cancelled.

**Typical use cases:**
- Hotels: hold an amount at check-in; capture the actual charges at checkout
- Car rentals: hold a deposit at pickup; capture the final amount on return
- Restaurants: hold the estimated bill; capture with tip added
- Any scenario where the final amount isn't known at authorization time

**How it differs from a sale:**
- A sale authorizes and captures in one step. Funds settle immediately.
- A pre-authorization only holds funds. Capture is a separate API call.
- Pre-authorizations that are never captured may be released by the card issuer after a hold period (typically 7–30 days depending on the card scheme and issuer).

---

## Prerequisites

1. **Pre-authorization enabled on the terminal.** This feature must be enabled by the Payroc Integrations team on the merchant's account/terminal. If not enabled, the gateway processes the request as a pending sale instead.
2. **API key** — to obtain a Bearer token from the Payroc identity service.
3. **Processing terminal ID** — the `processingTerminalId` used in the request body.

**Pre-authorization is NOT available when:**
- The merchant uses dual pricing or a surcharging program
- The merchant applies convenience fees
- The customer pays by bank account (ACH)

If a pre-auth appears to succeed but processes like a sale, check with the Payroc Integrations team whether any of the above apply to the terminal.

---

## Step 1 — Create the pre-authorization

**Endpoint:** `POST https://api.uat.payroc.com/v1/payments` (UAT) / `https://api.payroc.com/v1/payments` (production)

**Critical fields for pre-authorization (not a sale):**

| Field | Value | Effect |
| --- | --- | --- |
| `autoCapture` | `false` | Do not auto-capture after authorization |
| `processAsSale` | `false` | Do not immediately settle (this is the default) |

If `autoCapture` is `true`, the gateway captures immediately and processes as a sale. Both flags must be explicitly set to `false` (or `autoCapture` must be `false`; `processAsSale` defaults to `false`).

The response (HTTP 201) includes a `paymentId`. **Persist this immediately** — it is required for the capture call and for any adjust or reverse operations.

Check `transactionResult.status` and `transactionResult.responseCode` in the response to confirm the authorization was approved. Read the full status enum from `references/api-schema.md` before branching — `"approved"` is not a member of the `TransactionResultStatus` enum; a common authorization status is `"ready"` with `responseCode: "A"`.

---

## Step 2 (optional) — Adjust the pre-authorization

**Endpoint:** `POST https://api.uat.payroc.com/v1/payments/{paymentId}/adjust`

Call this endpoint if the final amount differs from the originally authorized amount — for example, a hotel adding charges for room service.

- You can increase or decrease the authorized amount.
- Adjustment is subject to card scheme rules and issuer limits.
- You cannot adjust a payment that has already been captured or reversed.

---

## Step 3 — Capture the pre-authorization

**Endpoint:** `POST https://api.uat.payroc.com/v1/payments/{paymentId}/capture`

**Full capture:** Omit the request body (or send `{}`) to capture the full pre-authorized amount.

**Partial capture:** Include the amount (in lowest denomination) to capture less than the full pre-authorized amount:

```json
{ "paymentCapture": { "amount": 8000 } }
```

A successful capture returns **HTTP 200** with a `payment` object containing `transactionResult`.

> HTTP 200 confirms the API accepted the request — it does NOT confirm the capture succeeded. Branch on
> `transactionResult.status` and `transactionResult.responseCode` to confirm success. Read both enums
> from `references/api-schema.md` before writing the success branch.

---

## Step 4 (alternative to capture) — Reverse/void the pre-authorization

**Endpoint:** `POST https://api.uat.payroc.com/v1/payments/{paymentId}/reverse`

Call reverse instead of capture when the merchant wants to release the held funds without collecting payment (e.g. booking cancelled).

A reversal releases the hold on the customer's card. Once reversed, the payment cannot be captured.

---

## Idempotency across steps

Each step (create, capture, adjust, reverse) requires its own `Idempotency-Key` header (a fresh UUID v4).

- The create key covers the initial authorization.
- The capture key covers the capture.
- Reuse the same key only if retrying the exact same failed request — the gateway returns the original result and does not create a duplicate.
- Never share a key across different operations (e.g. do not reuse the create key for the capture).

---

## Important timing notes

- Pre-authorizations have a hold period set by the card issuer (typically 7–30 days). If not captured within that window, the issuer may release the hold automatically.
- The Payroc API does not send a notification when a pre-authorization expires — the merchant is responsible for tracking and capturing within the hold window.
- To capture a larger amount than originally authorized, call the Adjust endpoint first, then capture.

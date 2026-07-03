# Save Payment Details — Integration Guide

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/guides/take-payments/save-payment-details.md`
> Last synced: 2026-06-22. To refresh, re-fetch the source and regenerate this file.

## Overview

The Payroc Secure Tokens API lets merchants store customer payment details in Payroc's vault. A stored token
replaces raw card or bank account data in all future transactions, reducing PCI compliance scope.

## Two tokenization paths

**Path 1 — Tokenize without a sale** (this skill's primary path)

Send a `POST` request directly to the secure-tokens endpoint. The gateway stores the payment details and
returns a `secureTokenId` and reusable `token`. No charge is made to the customer.

**Path 2 — Tokenize during a sale**

Include a `credentialOnFile` object with `"tokenize": true` in a payment creation request. The gateway
processes the sale and simultaneously vaults the payment details, returning a `secureTokenId` alongside
the payment response.

This skill covers **Path 1** — the standalone tokenize-without-sale flow. For Path 2, see the
`run-a-card-sale` skill.

---

## Token format and persistence

- The `token` field in the response starts with `296753` and is up to 12 digits, with a Luhn check digit.
- The `secureTokenId` is the merchant-friendly handle for subsequent operations (retrieve, delete, update).
- Sensitive data is never stored — the response masks card numbers (showing last 4 digits only) and never
  returns raw CVV or full card numbers.
- Tokens do not expire on their own — they persist until explicitly deleted.
- Deletion is permanent: once deleted, the `secureTokenId` cannot be recovered or reused.

---

## Validation status

After tokenization, the response includes a `status` field indicating what security checks were performed:

| Status | Meaning |
| --- | --- |
| `notValidated` | Token created; no card/account validation performed |
| `cvvValidated` | CVV was verified against the card network |
| `cardNumberValidated` | Card number was validated |
| `issueNumberValidated` | Issue number validated (UK debit cards) |
| `bankAccountValidated` | Bank account details were confirmed |
| `validationFailed` | Validation was attempted but failed |

For most card-not-present tokenization flows (plain keyed card data), the initial status is `notValidated`.

---

## MitAgreement — merchant-initiated transactions

If the stored token will be used for merchant-initiated future charges (subscriptions, installments, or
event-driven billing), set `mitAgreement` at tokenization time. This associates the customer's authorization
agreement with the token. Values:

- `unscheduled` — variable amount, event-triggered (e.g. wallet top-up when balance is low)
- `recurring` — fixed amount, regular schedule, no defined end (e.g. monthly SaaS subscription)
- `installment` — fixed amount, regular schedule, defined number of payments (e.g. 12-month payment plan)

If you are only saving for customer-initiated transactions (customer returns to checkout and pays again),
`mitAgreement` can be omitted.

---

## Update account details

To replace the payment method on an existing token (e.g. the customer's card expired and they entered a new one
via Hosted Fields), use the `update-account` sub-endpoint. This operation accepts a single-use token representing
the new payment details and replaces the stored payment method on the existing `secureTokenId`.

Only the payment source changes — customer metadata, `mitAgreement`, and `customFields` are preserved.

---

## Using a saved token in payments

Once tokenized, use the `token` value (the `296753...` string) as the payment source in subsequent API calls.
The payment request uses `source.type: "secureToken"` with the token value rather than raw card data.

---

## Key implementation notes

1. **One token per unique payment method** — tokenizing the same card twice creates two separate tokens.
2. **secureTokenId is merchant-controlled** — you can supply your own identifier (e.g. your internal customer ID)
   or let the gateway generate one. If you generate your own, it must be unique within the terminal.
3. **Always use env vars for credentials** — never hardcode API keys, terminal IDs, or tokens in source code.
4. **Idempotency-Key is required on POSTs** — use a fresh UUID v4 for each distinct create or update-account
   request. On retry of a failed request, reuse the same key to prevent duplicate tokens.

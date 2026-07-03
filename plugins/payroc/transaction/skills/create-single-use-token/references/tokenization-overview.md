# Payroc Tokenization — Overview

> **Narrative guide — use for conceptual context.** Source: `https://docs.payroc.com/knowledge/basic-concepts/tokenization.md`
> Last synced: 2026-06-22. For field-level schema details and enum values, use `api-schema.md`.

---

## What is tokenization?

A **token** is a string that represents a customer's payment details. The merchant submits payment
information to the Payroc gateway; the gateway stores it securely and returns a token — a
non-sensitive identifier — that the merchant can store locally and use in future transactions.

Tokens contain no payment information themselves, and **only the merchant that saved the payment
details can use the token**. Storing tokens does not increase PCI compliance scope beyond what the
merchant already has for transmitting payment data.

---

## Two token types

### Single-use tokens

- **Lifespan:** expire after 30 minutes; can be used **only once**.
- **No MIT agreement required** — because they are one-time, there is no need for a
  merchant-initiated transaction agreement.
- **Cannot be updated or deleted** — they simply expire.
- **Use case:** capture card details client-side (e.g. from a payment form) and pass the token
  server-side to complete a payment, without transmitting raw card data server-side.

### Secure tokens (not covered by this skill)

- **Lifespan:** persistent until deleted by the merchant.
- **Reusable** across multiple transactions.
- **MIT agreement required** — the merchant must specify `recurring`, `installment`, or
  `unscheduled` depending on the intended use.
- **Use case:** save a customer's payment method for subscriptions, instalment plans, or
  ad-hoc merchant-initiated charges.

---

## Relationship between token types

A single-use token can be **upgraded** to a secure token by passing
`"type": "singleUseToken"` as the `source` when calling
`POST /v1/processing-terminals/{processingTerminalId}/secure-tokens`.

---

## When to recommend single-use tokens

Use a single-use token when:

- A customer is at the checkout and enters card details once (web or POS).
- The payment must complete within the session (within 30 minutes).
- The merchant does not need to save the payment method for future use.

For repeat billing, subscriptions, or card-on-file flows, use secure tokens instead.

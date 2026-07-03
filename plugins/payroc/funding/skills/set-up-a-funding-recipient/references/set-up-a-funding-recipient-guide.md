# Set Up a Funding Recipient — Narrative Guide

> **Local snapshot — authoritative narrative for this skill.**
> Source: https://docs.payroc.com/guides/fund-merchants/set-up-a-funding-recipient.md
> Last synced: 2026-06-22. Use this for process guidance and context; use `api-schema.md` for
> all field names, enum values, and request/response schemas.

---

## Overview

A **funding recipient** is a third-party entity that can receive funds via Payroc's Dynamic Funding
model. Funding recipients cannot directly process card sales — they are purely fund-receiving entities.
A funding recipient is configured independently of a merchant platform and requires:

1. A funding recipient record (this guide)
2. At least one associated funding account (bank account for receiving)
3. Owner information for KYC compliance

Once a recipient is created and passes KYC review, you can target them in **funding instructions** to
split and route merchant settlement proceeds to them.

---

## How Dynamic Funding Works

The Dynamic Funding model allows you to distribute settlement funds across multiple bank accounts based
on business logic (marketplace splits, multi-location merchants, fee separation, etc.):

1. Merchant processes a sale through Payroc
2. At settlement, funding instructions define how to allocate the proceeds
3. Payroc routes funds to each designated recipient's funding account
4. Recipients appear in funding activity reports

A recipient must have `status: approved` before they can receive funds. KYC checks run automatically
when you create the recipient — the result appears in the `status` field of the response.

---

## Funding Recipient Types

A funding recipient's `recipientType` describes its legal structure. All values are camelCase:

| Enum value | Legal form |
| --- | --- |
| `privateCorporation` | Private corporation |
| `publicCorporation` | Public corporation |
| `nonProfit` | Non-profit organisation |
| `government` | Government entity |
| `privateLlc` | Private LLC |
| `publicLlc` | Public LLC |
| `privatePartnership` | Private partnership |
| `publicPartnership` | Public partnership |
| `soleProprietor` | Sole proprietor / individual |

Read the value from `api-schema.md` before emitting — do not guess from the legal name.

---

## KYC and Status

Payroc's Risk team runs Know Your Customer (KYC) checks on all funding recipients. The `status` field
reflects the outcome:

| Status | Meaning | Action required |
| --- | --- | --- |
| `pending` | Awaiting review | No action — monitor via GET or webhook |
| `approved` | Cleared to receive funds | Proceed to funding instructions |
| `rejected` | Failed KYC | Contact Payroc support — do not retry blindly |
| `hold` | Flagged by Risk team | Contact Payroc support |

In UAT, KYC checks are simulated and may fail or stay pending — this is expected test behaviour and
does not reflect a production data problem.

---

## Owner Requirements

Every funding recipient must have at least one owner record. The owner provides the KYC identity data:

- **Exactly one** owner must have `relationship.isControlProng: true` — this identifies the controlling
  party for compliance purposes
- `dateOfBirth` must be in `YYYY-MM-DD` format
- `identifiers` must include a `nationalId` type (SSN for US individuals, SIN for Canadian)
- At least one email in `contactMethods` per owner

Multiple owners are supported — document all beneficial owners with significant equity.

---

## Funding Account Requirements

Every funding recipient must have at least one funding account (the bank account for receiving funds):

- `type`: `checking`, `savings`, or `generalLedger`
- `use`: Must be **`credit`** for fund-receiving accounts
- `paymentMethods`: Must include an `ach` method with `routingNumber` and `accountNumber`
- `nameOnAccount`: The name on the bank account

Do not use `debit` or `creditAndDebit` for a funding recipient — those are for accounts that initiate
outbound transfers.

---

## After Creating the Recipient

Once the recipient is created:

1. **Save the `recipientId`** from the response — you will need it for all follow-on operations
2. **Check the `status`** — `approved` means ready to receive funds; `pending` means waiting for KYC
3. **Save each `fundingAccountId`** from the `fundingAccounts` array — needed when creating funding
   instructions
4. **Configure funding instructions** using the `send-funds-to-a-merchant` skill to begin routing funds

---

## Test Environment Notes

In UAT (`https://api.uat.payroc.com/v1`):
- KYC checks may return `pending` or `rejected` regardless of input data — this is simulated behaviour
- `recipientId` values are plain integers (not prefixed strings like in some other Payroc resources)
- Bank account numbers in responses are masked (asterisks) — this is expected
- Contact Payroc's Integrations team if UAT credentials do not work for funding endpoints

# Send Funds to Your Merchants — Narrative Guide

> **Local snapshot.** Source: `https://docs.payroc.com/guides/fund-merchants/send-funds-to-your-merchants.md`
> Last synced: 2026-06-22.

## Overview

Payroc's Funding API enables distributors to send funds to merchants through a two-step process:

1. **Check available balance** — verify there are sufficient funds before sending
2. **Create a funding instruction** — specify which merchants and funding accounts receive which amounts

Funds are disbursed via ACH (Automated Clearing House) transfers to the merchant's linked bank account.

---

## Prerequisites

Before sending funds, the merchant must already have a funding recipient set up with at least one funding account. The funding account provides the `fundingAccountId` you need to create instructions. Use the `set-up-a-funding-recipient` skill to create recipients and accounts if they aren't set up yet.

Key identifiers needed:
- `merchantId` — processor-assigned identifier for the merchant
- `fundingAccountId` — integer ID of the bank account to credit (obtained from the funding-recipients API)

---

## Step 1: Check Available Balance

Before creating a funding instruction, check that sufficient funds are available.

**Endpoint:** `GET /v1/funding-balance`

The response returns a `data` array with one entry per merchant, each containing:
- `funds` — total balance in cents
- `pending` — funds not yet distributed
- `available` — the usable balance you can instruct against

Only the `available` amount can be used in funding instructions. If `available` is zero or insufficient, the instruction will fail.

---

## Step 2: Create a Funding Instruction

Once you've confirmed sufficient balance, create a funding instruction.

**Endpoint:** `POST /v1/funding-instructions`

A single instruction can fund:
- A single merchant with a single recipient
- A single merchant with multiple recipients (split across bank accounts)
- Multiple merchants in a single batch

All funding is via `ACH` — the only supported `paymentMethod`.

Amounts are expressed in the lowest denomination: cents for USD (e.g. `50000` = $500.00).

---

## Lifecycle and Status Tracking

After creation, the instruction enters the `accepted` status and transitions through the lifecycle:

**Instruction-level status:**
- `accepted` → `pending` → `completed`

**Recipient-level status (within `merchants[].recipients[]`):**
- `accepted` → `pending` → `released` → `funded`
- Or: `rejected` / `failed` / `onHold` on error paths

Poll `GET /v1/funding-instructions/{instructionId}` or use webhook events to track progress.

---

## Updating and Deleting Instructions

Instructions can only be updated or deleted while still in `accepted` status. Once processing begins (status moves to `pending` or beyond), modifications are rejected with a 409 Conflict.

- **Update (PUT):** Replace the entire instruction body with a new set of merchants and amounts.
- **Delete (DELETE):** Cancel the instruction entirely — no funds are sent.

Always retrieve the instruction first to confirm its status before attempting either operation.

---

## Key Constraints

- Only `ACH` is supported as a `paymentMethod` — no other values are accepted
- Only `USD` is supported as a `currency`
- Amounts must be positive integers in cents (lowest denomination)
- `fundingAccountId` must be an integer (not a string)
- `instructionId` in responses is an integer (not a string)
- The `Idempotency-Key` header is required on POST (create); not required on PUT
- To list instructions, both `dateFrom` and `dateTo` are required (YYYY-MM-DD); data is available for up to two years back

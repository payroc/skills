# Settlement Data — Narrative Guide

> **Narrative reference for the view-settled-transactions skill.**
> Source: `https://docs.payroc.com/solutions/full-stack/view-reports/settlement-data.md`
> Last synced: 2026-06-22.

## Overview

Settlement is the process by which transaction funds are transferred from a card network or ACH processor into a merchant's bank account. Payroc groups settled transactions into **batches** — one or more batches per day per merchant, each representing a settlement cycle.

The Payroc Reporting API exposes settlement data as a two-level hierarchy:

```
Batches  (one per settlement cycle per merchant per day)
  └── Transactions  (one per individual settled payment or return)
```

## Two approaches to settlement reporting

**Via the Reporting API** — Recommended for partners, ISVs, and developers building integrated reporting into their software. Use the `GET /v1/batches` and `GET /v1/transactions` endpoints to:
- Pull daily settlement data on a schedule
- Automate reconciliation against internal order management systems
- Build dashboards that show merchant payouts

**Via Payroc Insights** — A self-service web portal for merchants who want access without API integration. Not covered by this skill.

## The settlement workflow

1. **During the business day** — payments are authorised and held
2. **At batch close** — the processor packages the day's authorisations into a settlement batch and submits them to the card network
3. **Settlement date** — typically T+1 or T+2; the batch appears in the API with a `date` matching the submission date
4. **Funding** — once settled, funds are deposited to the merchant's bank via ACH. The `settled.achDate` on each transaction reflects the ACH transfer date; `settled.achDepositId` links to the ACH deposit record.

## Querying by date

The primary entry point for daily settlement reconciliation is:

```
GET /v1/batches?date=YYYY-MM-DD
```

This returns all batches submitted on that date. Each batch includes a HATEOAS link to its transactions:

```
GET /v1/transactions?batchId={batchId}
```

Alternatively, skip the batch lookup and query transactions directly by date:

```
GET /v1/transactions?date=YYYY-MM-DD
```

Either `date` or `batchId` must be provided to the transactions endpoint.

## Reconciliation use case

A typical nightly reconciliation job:

1. Authenticate — obtain a Bearer token from the Identity Service
2. Query batches for the previous day: `GET /v1/batches?date=<yesterday>`
3. For each batch, query its transactions: `GET /v1/transactions?batchId=<batchId>`
4. Paginate through results using `hasMore` and cursor parameters (`after`/`before`)
5. Match `transactionId`, `amount`, and `date` against the internal order system
6. Flag discrepancies for manual review

## Settlement vs. Payments API

The Reporting API (`/v1/transactions`) is distinct from the Payments API (`GET /payments`):

| Dimension | Reporting API (`/v1/transactions`) | Payments API (`GET /payments`) |
| --- | --- | --- |
| Data type | Settled ledger entries | Live payment state |
| Use case | Reconciliation, payouts | Real-time transaction status |
| Filter by settlement | Native (the data IS settled) | Via `settlementState` query param |
| `transactionId` | Integer (may be null) | Not present (use `paymentId`) |

For reporting on what has been paid out, use the Reporting API. For checking whether a specific payment is authorised or has been voided, use the Payments API.

## Important constraints

- **`date` or `batchId` required** — the transactions endpoint rejects requests without either parameter. This is by design; querying all transactions without a date or batch scope would be unbounded.
- **Read-only** — these are GET-only endpoints; there are no write operations in the Reporting API.
- **No `Idempotency-Key` required** — idempotency headers are only required for state-changing (POST/PATCH) operations.
- **UAT data availability** — UAT settlement data is periodically wiped. If queries return empty results in UAT, this is likely the cause (see UAT status note in SKILL.md).

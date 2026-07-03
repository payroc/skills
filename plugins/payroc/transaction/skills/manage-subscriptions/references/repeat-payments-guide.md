# Repeat Payments — Narrative Guide

> **Local snapshot.** Source: `https://docs.payroc.com/guides/take-payments/repeat-payments/use-our-gateway.md`
> and `https://docs.payroc.com/guides/take-payments/repeat-payments.md`.
> Last synced: 2026-06-22.

## What are repeat payments?

Repeat payments are payments taken from a customer on a regular schedule.

- **Recurring payments** — no defined end date. Examples: gym membership ($40/month until
  cancelled), magazine subscription ($5/week until cancelled).
- **Installment payments** — a single amount split into fixed periodic payments. Examples: $1,200
  TV paid at $100/month for 12 months; $2,000 holiday paid at $250/month over 8 months.

## The gateway approach (this skill)

Payroc's gateway handles both plan management and payment collection. The workflow has four steps:

### Step 1 — Create a payment plan

A payment plan is a template that defines the schedule. Create one per product or pricing tier;
many customers (subscriptions) can then be assigned to the same plan.

- Use `POST /v1/processing-terminals/{processingTerminalId}/payment-plans`
- The `paymentPlanId` is **merchant-assigned** — you pick the value. Make it something meaningful
  (e.g. `"MONTHLY-GYM-BASIC"`).
- `type: automatic` — Payroc collects from the customer's account automatically on schedule.
- `type: manual` — Merchant triggers each collection via the Pay Manual Subscription endpoint.
- `onUpdate` and `onDelete` control what happens to linked subscriptions when the plan is changed
  or deleted — always set these explicitly.

### Step 2 — Tokenize the customer's payment method

Before creating a subscription, the customer's payment details must be stored as a **secure
token**. This is handled by the Secure Tokens API (see the `save-a-payment-method` skill).

The token is what you pass into the subscription as `paymentMethod.token`.

### Step 3 — Create a subscription

A subscription links a customer (via their secure token) to a payment plan.

- Use `POST /v1/processing-terminals/{processingTerminalId}/subscriptions`
- The `subscriptionId` is **merchant-assigned** — you pick the value. Make it unique per customer
  enrollment (e.g. `"CUST-12345-GYM-2026"`).
- Optional overrides: you can override the plan's `name`, `description`, `setupOrder`,
  `recurringOrder`, `length`, or `endDate` on a per-subscription basis.
- `startDate` determines when the first payment is collected.

### Step 4 — Collect payments

**Automatic subscriptions:** Payroc's gateway collects payments on the schedule defined in the
payment plan. No action needed per cycle.

**Manual subscriptions:** Trigger each payment using:
`POST /v1/processing-terminals/{processingTerminalId}/subscriptions/{subscriptionId}/pay`

Include the `order` object with the amount to collect in that cycle.

## Lifecycle management

| Action | Endpoint |
| --- | --- |
| Pause / update a subscription | PATCH subscription (JSON Patch) |
| Stop recurring payments | POST .../deactivate |
| Resume after deactivation | POST .../reactivate |
| Manually collect a payment | POST .../pay |
| Remove a plan and all its subscriptions | DELETE payment plan (with onDelete: complete) |

## Key constraints

- `type`, `frequency`, and `paymentPlan` on a subscription cannot be changed after creation
  (PATCH will reject these paths).
- Deactivating a subscription sets `status` to `cancelled`. Reactivating sets it back to `active`.
- The `onUpdate` and `onDelete` plan settings are set at plan creation time — plan them carefully
  before assigning customers.
- Amounts are in the **lowest currency denomination** (e.g. cents for USD, pence for GBP).

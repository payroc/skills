# Payroc Repeat Payments — Narrative Guide

> **Local snapshot — authoritative for this skill.** Sources: https://docs.payroc.com/guides/take-payments/repeat-payments/use-our-gateway.md and https://docs.payroc.com/knowledge/card-payments/payment-plans-and-subscriptions.md
> Last synced: 2026-06-22.

---

## Overview

Payroc's repeat payments feature lets you collect recurring charges from customers using a two-layer model:

1. **Payment plan** — a template that defines the payment structure: how often charges occur, how many, and (for automatic plans) how much each charge is.
2. **Subscription** — enrolls a specific customer into a payment plan using a secure token representing their payment details.

One plan can have many subscribers. Each subscription belongs to exactly one customer.

---

## Manual vs. Automatic plans

| Dimension | `manual` | `automatic` |
|-----------|----------|-------------|
| Who collects payments | Your POS / own system | Payroc gateway |
| `recurringOrder` required | No | Yes |
| How to charge | Call the "Pay manual subscription" endpoint per billing cycle | Gateway charges automatically at each billing interval |
| Use case | Merchants who manage billing in their own software | Full gateway-managed recurring billing |

---

## Four-step setup (gateway-managed / automatic)

1. **Create a payment plan** — define the template (frequency, amount, length, currency).
2. **Create a secure token** — tokenize the customer's payment method via the Tokenization API (`save-a-payment-method` skill). The resulting `secureTokenId` is what you pass into the subscription.
3. **Create a subscription** — link the customer (via their secure token) to the payment plan, with a start date.
4. **Collect payments** — for `automatic` plans the gateway handles this. For `manual` plans, call the "Pay manual subscription" endpoint each time you want to charge.

---

## Key concepts

### Payment plan ID
`paymentPlanId` is **merchant-assigned** — you choose the value when creating the plan. It must be unique per processing terminal. The API does not auto-generate it.

### Subscription ID
`subscriptionId` is also **merchant-assigned**. Choose a meaningful, unique value per terminal.

### onUpdate and onDelete
These settings determine how changes to a plan propagate to existing subscriptions:

- `onUpdate: "update"` — plan changes ripple to all current subscriptions.
- `onUpdate: "continue"` — existing subscriptions keep their original settings; only new subscriptions get the new plan terms.
- `onDelete: "complete"` — deleting the plan stops payments for all linked subscriptions.
- `onDelete: "continue"` — deleting the plan leaves subscriptions running; cancel them manually.

### pauseCollectionFor
Set this integer on a subscription to skip the first N billing cycles — useful for a free trial period, without modifying the underlying plan.

### Subscription inheritance
Subscriptions inherit `name`, `description`, `currency`, `length`, `type`, and `frequency` from the payment plan. You can override `name`, `description`, `setupOrder`, `recurringOrder`, `endDate`, `length`, and `pauseCollectionFor` at the subscription level without touching the plan.

---

## Deactivate vs. delete

| Action | Target | Reversible | Effect |
|--------|--------|------------|--------|
| Deactivate subscription | Subscription | Yes — use Reactivate | Sets status to `cancelled`; stops payments for that subscriber |
| Delete payment plan | Plan | No | Plan is permanently removed; no new subscriptions can be added |

---

## Surcharging

For automatic subscriptions, if the terminal is configured for surcharging, the gateway may add a surcharge to the recurring amount. The response will include the updated total and a breakdown showing the surcharge percentage and amount. The `recurringOrder.amount` in the response may differ from the requested amount for this reason.

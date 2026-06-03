# Sale Flow

Read this file when the developer's integration uses standard sale transactions (authorize and capture immediately). It covers Steps 2, 3, and 4 for the sale path in full.

---

## Step 2 (sale): Load the Hosted Payment Page

Read: references/load-hosted-payment-page.md

> **Do not use any endpoint URL from your training knowledge. Read the UAT and production endpoint URLs from the local reference above and use exactly what you find there. As a verification anchor — the UAT endpoint should be `https://payments.uat.payroc.com/merchant/paymentpage` and production `https://payments.payroc.com/merchant/paymentpage`. If the reference shows different values, use what the reference says and note the discrepancy.**

Read the reference before writing anything. Confirm from it:

- The UAT endpoint URL (and how it differs from production)
- All required POST fields and their exact names
- **For every enum-typed POST field — `CHANNEL`, `PAYMENTMETHOD`, country, language, currency, and any other field that accepts a specific set of strings — read the accepted values from the page.** Do not use any enum value from training knowledge. Known past failure (from sibling integrations): emitting `channel: "internet"` because it sounds reasonable for in-browser checkout — the gateway rejects it with the enum list in the error. Plausible-sounding cousins (`internet`, `online`, `ecommerce`, `card-not-present`) are the most common form this failure takes.
- The DATETIME format — must match exactly what you used in Step 1
- Any optional fields relevant to the developer's integration

Implement the checkout handler: generate the hash, assemble the required POST fields, and submit the form to the UAT endpoint. Ask the developer about anything you can't infer from the codebase — for example, the CURRENCY (confirm the ISO 4217 code for their market) and the ORDERID strategy (how order identifiers are generated in their system).

### Checkpoint

Does submitting the form redirect the browser to the Payroc UAT payment page without an error? If not, diagnose before continuing.

---

## Step 3 (sale): Build the receipt page

Read: references/build-receipt-page.md

> **Do not use any field names, response hash ordering, or parameter names from your training knowledge. Read them from the local reference above.**

Read the reference before writing anything. Confirm from it:

- Which response fields are included in the response hash and their exact order
- The full list of response parameters Payroc appends as query parameters when redirecting to the receipt URL
- What `UNIQUEREF` is and why it matters — capture and store it; it is required for refunds and follow-on transactions
- **The full `RESPONSECODE` enum — every value and what it means.** Do not assume `A` is the only success code or that `A/D/R/C` is exhaustive; the reference surfaces additional approval codes (e.g. `E`). Read the canonical list from the reference.

> **Build the `RESPONSECODE` branch from the full enum in the local reference — not from this skill, training data, or this skill's error taxonomy examples.** Identify every value that pairs with bank approval (`A` is one example; there are others) and treat the full set as success; everything else is failure or a specific case the reference describes. **Known past failure:** branching on `RESPONSECODE == 'A'` only and silently misclassifying real approvals when the actual value was `E`. The fix isn't to add `E` to a hardcoded list — the meta-mistake is reasoning about the enum from memory instead of the reference.
>
> **localhost is fine for this step.** The redirect is triggered by the customer's browser — Payroc's servers never call the receipt URL directly. If the developer also wants to implement Background Validation, that webhook does need a public URL; see the Local testing strategy section in SKILL.md.

Implement the receipt handler: parse the GET query parameters, verify the response hash before trusting any data, capture `UNIQUEREF`, and branch on `RESPONSECODE` per the reference's full enum.

### Checkpoint

Does the receipt handler receive the Payroc redirect, verify the response hash without error, and correctly parse `RESPONSECODE` and `UNIQUEREF`? If not, diagnose before continuing.

---

## Step 4 (sale): Test transaction

Before running a test, confirm the developer has a UAT test card number. Ask whether they have one from the Integrations team; if not, advise them to request test cards from the Payroc Integrations team.

Run a full end-to-end test in UAT:

1. Submit the checkout form
2. Complete payment on the Payroc-hosted page using a test card
3. Confirm the receipt page receives the redirect with `RESPONSECODE=A`
4. Confirm the response hash verification passes
5. Confirm `UNIQUEREF` is captured and stored

### Checkpoint

`RESPONSECODE=A` confirmed with a test card, and response hash verification passes? If not, use the error taxonomy in SKILL.md before continuing.

---
name: integrate-hosted-payment-pages
description: >-
  Guide an ISV developer or merchant through integrating Payroc's Hosted
  Payment Pages (HPP) from credential setup to first successful UAT test
  transaction. Use this skill whenever someone asks about integrating Payroc
  Hosted Pages, implementing HPP, setting up a Payroc payment form, generating
  a Payroc auth hash, handling a Payroc receipt callback, getting Payroc
  payments working in their application, running a pre-authorization, capturing
  a pre-auth, holding funds on a card, or authorize and capture flows — even if
  they don't explicitly mention "integration" or ask for step-by-step guidance.
metadata:
  version: "0.4.0"
  category: integration
  status: draft
---

# Payroc Hosted Pages Integration

**Phase 1 scope: CNP (card-not-present) Hosted Pages — one-time sale transactions and pre-authorizations. No recurring billing.**

On first invocation, announce to the developer:

> **Payroc Hosted Pages Integration**
> I'll guide you from credential setup through a successful UAT test transaction.
> This covers card-not-present payments via Payroc's Hosted Payment Page — both sale transactions and pre-authorizations (hold now, capture later).
>
> **How HPP works (three parts):**
> 1. Your checkout submits a POST to Payroc's HPP endpoint — this loads the payment page
> 2. The customer completes payment on Payroc's hosted page
> 3. Payroc redirects the customer's browser back to your receipt URL, appending transaction details as query parameters
>
> Note: there is also an optional **Background Validation webhook** — a server-side POST from Payroc's servers to a separate URL you configure. That's an extension step, not part of the main flow above.
>
> **HPP vs Hosted Fields:** If you need card input widgets embedded in your own form with no page redirect, that's Hosted Fields — a different product not covered by this skill. Mention it if the developer seems to be asking about embedded card forms.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
# Identity service (Bearer token — used for capture API only)
POST https://identity.uat.payroc.com/authorize
x-api-key: <api-key>

# Hosted Payment Page (form POST — loads the payment page)
POST https://payments.uat.payroc.com/merchant/paymentpage
Content-Type: application/x-www-form-urlencoded

# Capture API (pre-auth only)
POST https://api.uat.payroc.com/v1/payments/{uniqueRef}/capture
Authorization:  Bearer <token>
Content-Type:   application/json
```

---

## References

All values and shapes live in the local `references/` files below — this skill emits from them, not from
live lookups and not from memory. Three complementary surfaces, each owning a different kind of question —
using the wrong source for a question is a known failure mode:

- **API schema reference** (`references/api-schema.md`) — **source of truth for values and shapes on Payroc's JSON APIs**: the capture API for pre-auth, the `transactionResult` schema (including `responseCode` and `status` enums), any other Payroc REST API the integration touches. Read this for enum and schema questions on the REST-API side.
- **HPP narrative guides** (`references/authenticate-your-requests.md`, `references/load-hosted-payment-page.md`, `references/build-receipt-page.md`) — **source of truth for the HPP form-POST surface**: the HMAC field order and algorithm, the AMOUNT and DATETIME formats, the POST field names and accepted enum values (PAYMENTMETHOD, country, language, etc.), and the receipt-callback query-parameter shape including `RESPONSECODE`. The HPP form POST is *not* in the OpenAPI spec; these narrative copies are authoritative for it.
- **Background validation guide** (`references/implement-background-validation.md`) — **source of truth for the server-to-server webhook**: posted-field names, signature verification.

If your question is "what does the capture API request body look like, and what `transactionResult` values come back?" — that's `references/api-schema.md`. If your question is "what fields go in the HPP form POST and what's the hash recipe?" — that's the HPP narrative copies. If your question is "what `RESPONSECODE` values can the receipt callback carry?" — that's `references/build-receipt-page.md` (NOT a memorised list, even if this skill cites examples).

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | Capture API, `transactionResult` schema, any Payroc REST API field/enum |
| Authenticate (HMAC field order, AMOUNT/DATETIME formats) | `references/authenticate-your-requests.md` | Hash recipe — authoritative |
| Load the Hosted Payment Page (POST fields + enums) | `references/load-hosted-payment-page.md` | HPP form-POST field names and accepted enum values — authoritative |
| Build the receipt page (RESPONSECODE enum + receipt callback fields) | `references/build-receipt-page.md` | Receipt-callback query parameters — authoritative for RESPONSECODE values and other receipt fields |
| Sale flow (Steps 2–4) | `references/sale.md` | Sale flow (reads the narrative copies above for field/enum verification) |
| Pre-auth flow (Steps 2–4) | `references/pre-auth.md` | Pre-auth flow (reads the narrative copies + `api-schema.md` for capture) |
| Background validation | `references/implement-background-validation.md` | Webhook validation flow |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core Principles

1. **Inspect before asking** — read the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through questions before writing implementation code; wrong assumptions waste the developer's time.
3. **Validate before advancing** — don't move to the next step until the developer confirms the current step's checkpoint passes in UAT.
4. **Read the references, don't guess — and pick the right reference for the question.** HPP has *three* source surfaces, not two — using the wrong one for a question is how memorised-but-wrong values leak through. The Step 1 hash recipe already gets this discipline applied rigorously; extend it to every other step.
   - **HPP form POST and receipt callback (PAYMENTMETHOD, RESPONSECODE, AMOUNT/DATETIME formats, hash field order) → the HPP narrative copies.** These live on the form-POST surface and are NOT in `references/api-schema.md`. The narrative copies — `references/authenticate-your-requests.md`, `references/load-hosted-payment-page.md`, `references/build-receipt-page.md` — are authoritative for them. Read the relevant narrative copy before emitting form POST fields or branching on receipt-callback values.
   - **Capture API and any other Payroc REST API surface → `references/api-schema.md`.** The capture endpoint for pre-auth, the `transactionResult` schema (including the full `responseCode` and `status` enums), any other JSON API the integration touches. Field names, enum values, required fields, request/response shapes.
   - **Sequencing, validation patterns → the narrative copies.** When to call the validation endpoint, what order to validate webhook signatures, how the receipt redirect composes with background validation. The narrative copies cover *flow*; `api-schema.md` covers *values* on the JSON-API side; the HPP narrative copies cover *values* on the form-POST side.
   - **Request and response schemas diverge** — when you need a response shape (e.g. capture response), read it separately from the request schema. Don't infer the response shape from the request body.
   - **Don't infer enum values by analogy.** A plausible-sounding string that isn't in the documented enum will cause API errors. The Step 1 "do not use any algorithm name from your training knowledge" discipline applies to *every* value — `PAYMENTMETHOD`, `RESPONSECODE` branches, `transactionResult.status`, capture-response codes — not just the hash recipe.
5. **Read-then-emit, per value.** Before emitting any POST field enum value (`PAYMENTMETHOD`, country, language), any `RESPONSECODE` branch, any capture-API enum (`transactionResult.status`, `transactionResult.responseCode`), or any hash-input field name, read the relevant local reference (the HPP narrative copy for form-POST values; `references/api-schema.md` for capture and `transactionResult`). Don't treat this skill's examples (e.g. `RESPONSECODE=A` for approval, `RESPONSECODE=D` for decline) as exhaustive — they are illustrative, not canonical. The references document the full set; if you don't read them, you don't know the full set.
6. **Never hardcode credentials** — terminal IDs, secrets, and API keys must come from environment variables or a secrets manager, never source code.
7. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:

- Server-side language and framework
- Existing checkout, order, or payment-related routes and handlers
- Any partial HPP implementation (hash functions, form posts to payment URLs, receipt endpoints)
- How environment variables or configuration is managed
- How orders or transactions are identified (to understand the ORDERID strategy)

Use what you find to avoid asking for things you can infer, and to frame follow-up questions in the developer's own terms. Then ask for what you still need — don't assume.

At minimum, you need answers to these three routing questions before proceeding:

**Question 1 — Integration type:**

| | Hosted Pages (HPP) | Hosted Fields |
|---|---|---|
| Customer experience | Leaves your site briefly to pay on Payroc's hosted page, then returns | Never leaves your site — Payroc card input widgets are embedded in your own form |
| Your receipt page | Receives a browser GET redirect with query parameters | Different flow entirely |
| This skill | ✓ Covered here | Phase 2 — not yet covered |

- **Hosted Pages** → continue with this skill
- **Hosted Fields** → not yet covered; explain the difference and offer to continue with Hosted Pages instead, or stop

**Question 2 — Recurring billing:** Does this integration need recurring billing or saved payment details?

- **No** → continue with this skill (one-time CNP payments)
- **Yes** → recurring is out of Phase 1 scope; offer to continue with one-time payments or stop

**Question 3 — Transaction type:** Does this integration need pre-authorizations (hold funds now, capture later), standard sales (authorize and capture immediately), or both?

- **Sales only** → continue with the standard flow below
- **Pre-auth** or **both** → note that an extra Capture step is required after the receipt handler, and confirm pre-auth is available on the merchant account (not available with dual pricing, surcharging programs, or convenience fees). When you reach Step 2, read `references/pre-auth.md` in addition to the standard steps.

Once all three are in scope, continue to Prerequisites.

---

## Prerequisites

Before writing any code, confirm the developer has all three:

1. **Terminal ID** — a UAT terminal ID assigned by the Payroc Integrations team. UAT is Payroc's test environment; credentials are provisioned manually by the team (there is no self-serve signup).
2. **Terminal secret** — created in the [Self-Care Portal](https://selfcare.payroc.com) for that specific UAT terminal.
3. **Receipt URL** — a URL on their application that Payroc's HPP redirects the customer's browser to after payment, appending transaction details as query parameters. Because it's a browser redirect (not a call from Payroc's servers), **localhost works fine** for testing this step. The URL must be registered in the Self-Care Portal for the UAT terminal.

If anything is missing:
- Terminal ID / UAT access → contact the Payroc Integrations team
- Terminal secret → walk through the Self-Care Portal once they have UAT access
- Receipt URL → work through the tunneling options in the local testing section

Ask for anything else you need at this point — for example, whether UAT credentials are already stored somewhere, or whether there's an existing checkout handler to modify rather than write from scratch.

**If the developer has already confirmed credentials** (e.g. terminal ID and secret are visible in env vars or config), name the receipt URL explicitly as the one remaining prerequisite blocking implementation — don't present it as one of three equal questions.

### Checkpoint

Terminal ID, terminal secret, and receipt URL all confirmed? If not, stay here and help resolve what's missing.

---

## Step 1 — Authenticate your requests

Read: references/authenticate-your-requests.md

> **Do not use any algorithm name, format string, or field name from your training knowledge for this step. Read every value — hash algorithm, AMOUNT format, DATETIME format, and field order — from the local reference above.**

Read the reference fully before writing anything. From it, confirm and use:

- The hash algorithm
- The exact fields in the hash input string and their order
- The AMOUNT format — read this carefully; it is not obvious and getting it wrong means every request fails with a cryptic error
- The DATETIME format and its timezone requirement
- The example hash provided for validation — you must reproduce this exactly before advancing

Implement a hash function in the developer's language and framework. Test it immediately against the example from the reference using the documented input values. The example hash is a precise contract — if your function doesn't match it, there is a bug.

### Checkpoint

Does the hash function reproduce the example hash from the reference exactly? If not, diagnose with the error taxonomy before continuing.

---

## Step 2 — Load the Hosted Payment Page

Read the reference for your transaction type:
- **Sale:** `references/sale.md` — Step 2
- **Pre-auth:** `references/pre-auth.md` — Step 2

> **Apply the Step 1 discipline to every POST field enum value.** Just as you read the authenticate reference before writing the hash function, read the narrative copy that documents the HPP form POST fields (`references/load-hosted-payment-page.md`; `references/sale.md` points you at it) before emitting any enum-typed value — `PAYMENTMETHOD`, country, language, and any other field that accepts a specific set of strings. Do not use any enum value from your training knowledge. **Known past failure (from sibling integrations):** a model emitted `channel: "internet"` because the value sounds reasonable for in-browser checkout — the gateway rejected it with the enum list in the error detail. Plausible-sounding cousins (`internet`, `online`, `ecommerce`, `card-not-present`) are the most common form this failure takes; read the reference that documents the accepted set before emitting.

**Note:** HPP does not include the transaction type in its response. If your integration handles both sales and pre-auths, record the transaction type in your own order model before submitting the HPP form.

### Checkpoint

Does submitting the form redirect the browser to the Payroc UAT payment page without an error? If not, diagnose before continuing.

---

## Step 3 — Build the receipt page

Read the reference for your transaction type:
- **Sale:** `references/sale.md` — Step 3
- **Pre-auth:** `references/pre-auth.md` — Step 3 (receipt response is the same as sale; durable storage requirement for `UNIQUEREF` applies)

> **Apply the Step 1 discipline to RESPONSECODE branching and any other receipt-callback enum.** Read `references/build-receipt-page.md` before writing the receipt handler. Do not branch on a remembered subset of `RESPONSECODE` values — this skill's error taxonomy lists `A` / `D` / `R` / `C` as examples, not as the canonical set. The reference surfaces approval codes beyond `A` (e.g. `E`); the reference is the source of truth. **Known past failure pattern:** treating `RESPONSECODE == 'A'` as the only success and silently misclassifying real approvals because the canonical set was larger than the memorised one. Read the reference; identify every value that pairs with bank approval; branch on that full set.

### Checkpoint

Does the receipt handler receive the Payroc redirect, verify the response hash without error, and correctly parse `RESPONSECODE` and `UNIQUEREF`? If not, diagnose before continuing.

---

## Step 4 — Test transaction

- **Sale:** `references/sale.md` — Step 4
- **Pre-auth:** same sale test path (steps 1–5 in `references/sale.md`), then also:
  6. Trigger the capture call using the stored `UNIQUEREF`
  7. Confirm HTTP 200 with `transactionResult` in the response body

> **For pre-auth capture: read the `transactionResult` schema from `references/api-schema.md` before writing the success branch.** `transactionResult.status` and `transactionResult.responseCode` are both enums. **Known past failure (from sibling integrations):** a model branched only on `status == "approved"` and silently treated real approvals as failures because the actual value was `"ready"` (authorized + queued for capture) with `responseCode: "A"` / `responseMessage: "APPROVAL"`. Read the full `transactionResult.status` enum, identify every value that pairs with bank approval, and branch on the full set — do not build the success check from a remembered subset.

### Checkpoint

`RESPONSECODE=A` confirmed with a test card, and response hash verification passes? (Pre-auth: capture also returns HTTP 200 *and* the `transactionResult` success branch was verified against the full enum?) If not, use the error taxonomy. Don't mark complete until all conditions are met.

---

## Local testing strategy

**Steps 1–3** (hash generation, HPP redirect, and receipt page) can all be tested with `localhost`. The receipt redirect is triggered by the customer's browser — Payroc's servers never call the receipt URL directly, so there is no reachability requirement.

**Background Validation onward** requires a public URL. Payroc's servers POST to the validation webhook endpoint, which means `localhost` won't work. Options from simplest to most robust:

- **webhook.site** — register a webhook.site URL as a temporary validation URL in Self-Care Portal; it captures the raw POST so you can inspect the exact response fields before writing the handler. Good first step even if you plan to use a tunnel later.
- **VS Dev Tunnels** (built into Visual Studio and VS Code) — natural choice for .NET apps; creates a persistent public HTTPS URL tunneled to your local port with minimal setup.
- **ngrok** — language-agnostic, quick setup, free tier works for development.
- **Cloudflare Tunnel** — more robust for longer-lived environments.
- **Deploy to a staging host** — if tunneling is not available, deploy to any UAT-accessible host and test there.

Register whichever public URL you use in the Self-Care Portal as the Background Validation URL for the UAT terminal (this is a separate field from the receipt URL).

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Error from HPP immediately on redirect | Hash invalid | Re-read `references/authenticate-your-requests.md`; check AMOUNT format, DATETIME format and timezone, and field order; re-run against the example hash in the reference |
| `RESPONSECODE=D` | Transaction declined | Expected in UAT — use a Payroc test card |
| `RESPONSECODE=R` | Referral — customer should contact bank | Treat as decline for Phase 1 testing |
| `RESPONSECODE=C` | Card reported lost/stolen | Use a different test card |
| App logged a failure but a real approval occurred — `RESPONSECODE` carried a value other than `A` (past surfacings: `E`) | Receipt-page branch treated `RESPONSECODE == 'A'` as the only success and silently misclassified other approvals | Read `references/build-receipt-page.md` for the full `RESPONSECODE` enum. Identify every value that pairs with bank approval and branch on that full set — `A` is an example, not the canonical set. |
| Pre-auth: capture API returns HTTP 200 but app logged a failure — response shows `responseCode: "A"` / `responseMessage: "APPROVAL"` | Server-side success check branched on a remembered subset of `transactionResult.status` (past failure: only `"approved"` accepted; `"ready"` — authorized + queued for capture — silently treated as a failure) | Read the `transactionResult.status` enum from `references/api-schema.md` and branch on the full set of values that pair with bank approval. |
| No redirect to receipt page after payment | Receipt URL not registered in Self-Care Portal, or registered with a typo | The receipt result is delivered as a **browser GET redirect** (query parameters) — not a server-side POST. Localhost is valid. Most likely cause: URL not registered or typo in Self-Care Portal. Confirm the URL exactly matches what's registered for the UAT terminal. |
| Response hash verification fails | Wrong fields or wrong order in verification hash | Re-read `references/build-receipt-page.md`; confirm exactly which response fields are hashed and their order |
| Hash mismatch despite correct fields | Character encoding or whitespace | All hash inputs must be plain ASCII; check for Unicode characters, trailing spaces, or line endings in any field value |
| 404 on capture API call | UNIQUEREF invalid or pre-auth expired | Verify UNIQUEREF matches the value from the receipt response; note pre-auths have an issuer-defined hold period after which they expire |
| 409 on capture API call | Pre-auth already captured | Check order state before attempting capture; don't retry a completed capture |
| 401 on capture API call | Bearer token expired or wrong API key | Re-generate the Bearer token; confirm the `x-api-key` value used with the identity service |

---

## Validation checklist

- [ ] Terminal ID and secret sourced from environment variables — not in source code
- [ ] Receipt URL registered in Self-Care Portal and publicly accessible
- [ ] Hash function validated against the example hash in `references/authenticate-your-requests.md`
- [ ] All required POST fields present when loading HPP
- [ ] Response hash verified before trusting any response data
- [ ] `RESPONSECODE=A` confirmed in UAT with a test card
- [ ] `UNIQUEREF` captured and stored
- [ ] (Pre-auth only) Transaction type recorded in order model — HPP response does not include it
- [ ] (Pre-auth only) `UNIQUEREF` persisted to durable storage (database/order record), not session or TempData
- [ ] (Pre-auth only) Capture API tested in UAT — HTTP 200 with `transactionResult` confirmed
- [ ] Every POST field enum value (`PAYMENTMETHOD`, country, language, etc.) was read from `references/load-hosted-payment-page.md`, not from training data or this skill's examples
- [ ] `RESPONSECODE` branching covers every approval value listed in `references/build-receipt-page.md` — not a remembered subset like just `A`
- [ ] (Pre-auth only) Capture-response success branch on `transactionResult.status` covers every approval value in the `references/api-schema.md` enum (e.g. `"ready"`)

---

## Anti-patterns

**Hardcoding terminal ID or secret** — credentials in source code end up in version history and get leaked.

**Skipping example hash validation** — if the hash function has any subtle error (wrong field order, wrong AMOUNT format, wrong timezone), every transaction will fail. The example hash in `references/authenticate-your-requests.md` is a contract; validate against it before touching anything else.

**Trusting RESPONSECODE without verifying the response hash** — your receipt page can be spoofed with a forged POST containing `RESPONSECODE=A` if you don't verify the hash first.

**Not storing UNIQUEREF** — you cannot refund or perform follow-on transactions without it.

**Assuming AMOUNT format** — the correct format is documented; it is not obvious. Read it. Getting this wrong produces an invalid hash on every request.

**Storing UNIQUEREF in session or TempData** — for pre-auth integrations, UNIQUEREF must survive beyond the current request; ephemeral storage means you lose the ability to capture if the user navigates away or the session expires.

**Treating the Step 1 "do not use any value from training knowledge" discipline as Step-1-specific.** That guardrail wasn't only about hash recipes — it's the standard for *every* documented value the integration emits or branches on. POST field enums (`PAYMENTMETHOD`), `RESPONSECODE` branches, capture-API `transactionResult.status` values: each one is documented in a specific local reference (the HPP narrative copies for form/receipt, `references/api-schema.md` for capture). Read the relevant reference before emitting or branching on the value. The hash recipe just happened to be the most visible failure mode in early iterations.

**Building a success check from a partial mental model of an enum.** This is the meta-mistake behind both the `RESPONSECODE` and `transactionResult.status` failures: reasoning about the enum from memory or from this skill's examples rather than reading the local reference. Every approval check must enumerate the *full* set of values that pair with bank approval, not just `A` or a single status.

---

## Completion

Once `RESPONSECODE=A` is confirmed and all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Authentication hash** — signs every payment request with your terminal secret; prevents tampering.
> - **Checkout handler** — assembles and POSTs the payment form to Payroc's Hosted Payment Page.
> - **Receipt handler** — receives Payroc's browser redirect (GET with query parameters), verifies the response hash, branches on the full RESPONSECODE approval set, and captures UNIQUEREF.
> - **Validated in UAT** — end-to-end transaction confirmed with a test card.
> - **Pre-authorization + Capture** (if applicable) — holds funds at checkout; captured via REST API when ready to settle; UNIQUEREF links the two calls; capture-response branch covers the full `transactionResult.status` approval set.
>
> **Before going live:** swap the UAT endpoint URLs for production URLs — this applies to both the HPP endpoint and the capture API endpoint (confirm both in the references). Point credentials to the production terminal, confirm the receipt URL is registered in the production Self-Care Portal, and remove any test card numbers.

Offer next steps:

- **Background validation webhook** — a server-to-server POST on every transaction, independent of the receipt redirect; useful for reconciliation and as a fallback if the redirect fails
- **Hosted Fields** (Phase 2) — Payroc-hosted card input widgets embedded in your own form; no page redirect
- **Recurring billing** (Phase 2) — saved payment details and subscription charges

---
name: integrate-hosted-payment-pages
description: >-
  Guide an ISV developer or merchant through integrating Payroc's Hosted
  Payment Pages (HPP) from credential setup to first successful UAT test
  transaction. Use this skill whenever someone asks about integrating Payroc
  Hosted Pages, implementing HPP, setting up a Payroc payment form, generating
  a Payroc auth hash, handling a Payroc receipt callback, getting Payroc
  payments working in their application, running a pre-authorization, capturing
  a pre-auth, holding funds on a card, authorize and capture flows, saving or
  tokenizing a customer's card on the Payroc Hosted Page, getting a Payroc
  secure token or CARDREFERENCE, or setting up recurring billing, subscriptions,
  repeat payments, payment plans, free trials, installments, or
  merchant-initiated transactions on Payroc — even if they don't explicitly
  mention "integration" or ask for step-by-step guidance.
metadata:
  version: "0.6.0"
  category: integration
  status: draft
---

# Payroc Hosted Pages Integration

**Scope: CNP (card-not-present) Hosted Pages — one-time sale transactions, pre-authorizations, and recurring billing (save a customer's card on the Hosted Page, then take repeat payments via Payroc's gateway subscriptions or your own merchant-initiated charges).**

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/integrate-hosted-payment-pages/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Hosted Pages Integration**
> I'll guide you from credential setup through a successful UAT test transaction.
> This covers card-not-present payments via Payroc's Hosted Payment Page — sale transactions, pre-authorizations (hold now, capture later), and recurring billing (save a card for later, then charge it on a schedule or on demand).
>
> **How HPP works (three parts):**
> 1. Your checkout submits a POST to Payroc's HPP endpoint — this loads the payment page
> 2. The customer completes payment (or saves their card) on Payroc's hosted page
> 3. Payroc redirects the customer's browser back to your receipt URL, appending transaction details as query parameters
>
> Note: there is also an optional **Background Validation webhook** — a server-side POST from Payroc's servers to a separate URL you configure. That's an extension step, not part of the main flow above.
>
> **HPP vs Hosted Fields:** If you need card input widgets embedded in your own form with no page redirect, that's Hosted Fields — a different product not covered by this skill. Mention it if the developer seems to be asking about embedded card forms.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
# Identity service (Bearer token — used for REST APIs: capture, repeat payments)
# UAT/test: identity.uat.payroc.com · Production: identity.payroc.com (note: UAT has the .uat segment, prod does not)
POST https://identity.uat.payroc.com/authorize
x-api-key: <api-key>

# Hosted Payment Page — sale (form POST, loads the payment page)
POST https://payments.uat.payroc.com/merchant/paymentpage
Content-Type: application/x-www-form-urlencoded

# Hosted Payment Page — pre-auth (form POST)
POST https://payments.uat.payroc.com/merchant/preauthpage

# Hosted Payment Page — save a card / tokenize (form POST; ACTION=register|update)
POST https://payments.uat.payroc.com/merchant/securecardpage

# Capture API (pre-auth only)
POST https://api.uat.payroc.com/v1/payments/{uniqueRef}/capture
Authorization:  Bearer <token>
Content-Type:   application/json

# Repeat payments — gateway path (Bearer token)
POST https://api.uat.payroc.com/v1/processing-terminals/{terminalId}/payment-plans
POST https://api.uat.payroc.com/v1/processing-terminals/{terminalId}/subscriptions

# Repeat payments — your-own-software / MIT path (Bearer token; paymentMethod.type=secureToken)
POST https://api.uat.payroc.com/v1/payments
```

---

## References

All values and shapes live in the local `references/` files below — this skill emits from them, not from
live lookups and not from memory. Three complementary surfaces, each owning a different kind of question —
using the wrong source for a question is a known failure mode:

- **API schema references** (`references/api-schema.md`, `references/repeat-payments-api-schema.md`) — **source of truth for values and shapes on Payroc's JSON APIs**: `api-schema.md` covers the capture API for pre-auth and the `transactionResult` schema (including `responseCode` and `status` enums); `repeat-payments-api-schema.md` covers the Secure Tokens, Payment Plans, and Subscriptions resources plus the Payments `secureToken` / `standingInstructions` shapes for merchant-initiated charges. Read these for enum and schema questions on the REST-API side.
- **HPP narrative guides** (`references/authenticate-your-requests.md`, `references/load-hosted-payment-page.md`, `references/build-receipt-page.md`, and the save-card variants under `references/save-payment-details/`) — **source of truth for the HPP form-POST surface**: the HMAC field order and algorithm, the AMOUNT and DATETIME formats, the POST field names and accepted enum values (PAYMENTMETHOD, ACTION, STOREDCREDENTIALUSE, country, language, etc.), and the receipt-callback query-parameter shape including `RESPONSECODE` and `CARDREFERENCE`. The HPP form POST is *not* in the OpenAPI spec; these narrative copies are authoritative for it. **The save-card flow has its own copies** because its endpoint, hash recipe, form fields, and receipt `RESPONSECODE` enum all differ from the sale flow.
- **Background validation guide** (`references/implement-background-validation.md`) — **source of truth for the server-to-server webhook**: posted-field names, signature verification.

If your question is "what does the capture API request body look like, and what `transactionResult` values come back?" — that's `references/api-schema.md`. If your question is "what endpoints/fields/enums set up a subscription or run a merchant-initiated charge with a saved token?" — that's `references/repeat-payments-api-schema.md`. If your question is "what fields go in the HPP form POST and what's the hash recipe?" — that's the HPP narrative copies (the `save-payment-details/` copies for the save-card flow). If your question is "what `RESPONSECODE` values can the receipt callback carry?" — that's `references/build-receipt-page.md` for sale/pre-auth, or `references/save-payment-details/build-receipt-page.md` for save-card (NOT a memorised list, even if this skill cites examples).

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | Capture API, `transactionResult` schema, any Payroc REST API field/enum |
| Repeat-payments API schema | `references/repeat-payments-api-schema.md` | Secure Tokens, Payment Plans, Subscriptions endpoints/enums; Payments `secureToken` + `standingInstructions` (MIT) |
| Authenticate (HMAC field order, AMOUNT/DATETIME formats) | `references/authenticate-your-requests.md` | Sale/pre-auth hash recipe — authoritative |
| Load the Hosted Payment Page (POST fields + enums) | `references/load-hosted-payment-page.md` | Sale/pre-auth HPP form-POST field names and accepted enum values — authoritative |
| Build the receipt page (RESPONSECODE enum + receipt callback fields) | `references/build-receipt-page.md` | Sale/pre-auth receipt-callback query parameters — authoritative for RESPONSECODE values and other receipt fields |
| Save a card — authenticate | `references/save-payment-details/authenticate-your-requests.md` | Save-card (register/update) hash recipe — authoritative (no AMOUNT; MERCHANTREF + ACTION) |
| Save a card — load page | `references/save-payment-details/load-hosted-payment-page.md` | Save-card form POST — `securecardpage` endpoint, `ACTION`, `STOREDCREDENTIALUSE` (uppercase) — authoritative |
| Save a card — receipt | `references/save-payment-details/build-receipt-page.md` | Save-card receipt callback — `CARDREFERENCE`, `STOREDCREDENTIALTXTYPE`, the `A`/`E14`/`E43`/`E44` RESPONSECODE enum — authoritative |
| Sale flow (Steps 2–4) | `references/sale.md` | Sale flow (reads the narrative copies above for field/enum verification) |
| Pre-auth flow (Steps 2–4) | `references/pre-auth.md` | Pre-auth flow (reads the narrative copies + `api-schema.md` for capture) |
| Recurring flow (save card + repeat payments) | `references/recurring.md` | Recurring flow (reads the `save-payment-details/` copies + `repeat-payments-api-schema.md`) |
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
   - **Capture API and any other Payroc REST API surface → `references/api-schema.md`; repeat-payments REST surface → `references/repeat-payments-api-schema.md`.** The capture endpoint for pre-auth, the `transactionResult` schema (including the full `responseCode` and `status` enums) live in `api-schema.md`. The Secure Tokens / Payment Plans / Subscriptions endpoints and the Payments `secureToken` + `standingInstructions` shapes live in `repeat-payments-api-schema.md`. Field names, enum values, required fields, request/response shapes.
   - **Save-card flow is a sibling of the sale flow, not the sale flow + a field.** Its endpoint (`/merchant/securecardpage`), hash recipe (`TERMINALID:MERCHANTREF:DATETIME:ACTION:SECRET` — **no AMOUNT**, uses MERCHANTREF + ACTION), form fields (`ACTION`, `STOREDCREDENTIALUSE`), receipt fields (`CARDREFERENCE`, `STOREDCREDENTIALTXTYPE`), and receipt `RESPONSECODE` enum (`A`/`E14`/`E43`/`E44`) all differ. Read them from `references/save-payment-details/` — never carry the sale recipe over unchanged.
   - **Casing differs by surface for stored-credential usage.** The HPP form POST uses **UPPERCASE** `STOREDCREDENTIALUSE` (`RECURRING`); the REST API uses **lowercase** `mitAgreement` / `processingModel` (`recurring`). Emit the casing for the surface you're on.
   - **Subscriptions depend on a payment plan and a secure token existing first.** On the gateway path, create the Payment Plan, then the Subscription that links the plan to the token (the token is the HPP `CARDREFERENCE`). Don't POST a subscription before its plan exists.
   - **Sequencing, validation patterns → the flow files.** When to call the validation endpoint, what order to validate webhook signatures, how the receipt redirect composes with background validation, the save-card→repeat-payments order. The flow files (`sale.md`, `pre-auth.md`, `recurring.md`) cover *flow*; `api-schema.md` / `repeat-payments-api-schema.md` cover *values* on the JSON-API side; the HPP narrative copies cover *values* on the form-POST side.
   - **Request and response schemas diverge** — when you need a response shape (e.g. capture response, subscription response), read it separately from the request schema. Don't infer the response shape from the request body.
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

**Question 2 — Recurring billing / saved cards:** Does this integration need to save a customer's card for later, or take recurring/subscription/installment payments?

- **No** → continue with the one-time CNP flow (sale and/or pre-auth) below.
- **Yes** → this is the recurring flow. It has two stages: **save the card on the Hosted Page** (tokenize → get a `CARDREFERENCE`), then **take repeat payments**. Ask which repeat-payment approach they want:
  - **Use Payroc's gateway** — Payroc stores the schedule and collects payments (Payment Plans + Subscriptions). Best when they want Payroc to manage billing cycles.
  - **Use their own software** — their system schedules and runs each merchant-initiated charge with the saved token (`POST /payments` with `paymentMethod.type: secureToken`). Best when they already have billing logic.

  When recurring is in scope, Steps 1–3 below become the **save-card** variant and you add **Step 5 — Set up repeat payments**. Read `references/recurring.md` when you reach Step 1.

**Question 3 — Transaction type:** Does this integration need pre-authorizations (hold funds now, capture later), standard sales (authorize and capture immediately), or both?

- **Sales only** → continue with the standard flow below
- **Pre-auth** or **both** → note that an extra Capture step is required after the receipt handler, and confirm pre-auth is available on the merchant account (not available with dual pricing, surcharging programs, or convenience fees). When you reach Step 2, read `references/pre-auth.md` in addition to the standard steps.

Once all three are in scope, continue to Prerequisites.

---

## Prerequisites

These are needed to **run and test** the integration in UAT — not to write the code. If the developer already has them, great. If not, don't stop: wire the code to read each value from an environment variable (and the receipt URL from config), and keep building. The developer can populate everything before they test.

1. **Terminal ID** — a UAT terminal ID assigned by the Payroc Integrations team. UAT is Payroc's test environment; credentials are provisioned manually by the team (there is no self-serve signup).
2. **Terminal secret** — created in the [Self-Care Portal](https://selfcare.payroc.com) for that specific UAT terminal.
3. **Receipt URL** — a URL on their application that Payroc's HPP redirects the customer's browser to after payment, appending transaction details as query parameters. Because it's a browser redirect (not a call from Payroc's servers), **localhost works fine** for testing this step. The URL must be registered in the Self-Care Portal for the UAT terminal before a live test will redirect successfully — but you can build the receipt-handler route now and read the URL from config.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it; otherwise propose names like `PAYROC_TERMINAL_ID`, `PAYROC_TERMINAL_SECRET`, and a `PAYROC_RECEIPT_URL` setting. Write the code to read those values from the environment/config, then tell the developer what's outstanding and how to get it:
- Terminal ID / UAT access → contact the Payroc Integrations team.
- Terminal secret → create it in the Self-Care Portal once they have UAT access.
- Receipt URL → decide the route now and build the handler; register the URL in the Self-Care Portal (and work through the tunneling options in the local testing section) before testing a live redirect.

Ask for anything else you need at this point — for example, whether UAT credentials are already stored somewhere, or whether there's an existing checkout handler to modify rather than write from scratch.

**If the developer has already confirmed the terminal credentials** (e.g. terminal ID and secret are visible in env vars or config), name the receipt URL as the main outstanding item to register before live testing — but still build the receipt handler against a configured URL rather than waiting on it.

### Checkpoint

Either the terminal ID, terminal secret, and receipt URL are confirmed, or the developer knows what's outstanding, how to obtain/register it, and which environment variables and config the code reads them from — and has chosen to proceed. Don't leave missing items unstated, but don't block on them either.

---

## Step 1 — Authenticate your requests

Read the reference for your flow:
- **Sale / pre-auth:** `references/authenticate-your-requests.md`
- **Save a card (recurring):** `references/save-payment-details/authenticate-your-requests.md` — start by reading `references/recurring.md`, which sequences the whole save-card → repeat-payments flow.

> **Do not use any algorithm name, format string, or field name from your training knowledge for this step. Read every value — hash algorithm, AMOUNT format, DATETIME format, and field order — from the local reference for your flow.**

> **Recurring: the save-card hash recipe is different.** It is `TERMINALID:MERCHANTREF:DATETIME:ACTION:SECRET` — **no AMOUNT**, MERCHANTREF in place of ORDERID, plus ACTION. Reproduce *that* reference's example hash, not the sale one. A sale hash function copied across unchanged will fail every save-card request.

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
- **Save a card (recurring):** `references/recurring.md` — Stage A, Step 2 (form POST to **`/merchant/securecardpage`** with `ACTION` and `STOREDCREDENTIALUSE`)

> **Apply the Step 1 discipline to every POST field enum value.** Just as you read the authenticate reference before writing the hash function, read the narrative copy that documents the HPP form POST fields (sale/pre-auth: `references/load-hosted-payment-page.md`; save-card: `references/save-payment-details/load-hosted-payment-page.md`) before emitting any enum-typed value — `PAYMENTMETHOD`, `ACTION`, `STOREDCREDENTIALUSE`, country, language, and any other field that accepts a specific set of strings. Do not use any enum value from your training knowledge. **Known past failure (from sibling integrations):** a model emitted `channel: "internet"` because the value sounds reasonable for in-browser checkout — the gateway rejected it with the enum list in the error detail. Plausible-sounding cousins (`internet`, `online`, `ecommerce`, `card-not-present`) are the most common form this failure takes; read the reference that documents the accepted set before emitting. **Save-card note:** `STOREDCREDENTIALUSE` is UPPERCASE here; the endpoint is `securecardpage`, not `paymentpage`.

**Note:** HPP does not include the transaction type in its response. If your integration handles sales, pre-auths, and/or save-card, record which one this is in your own order model before submitting the HPP form.

### Checkpoint

Does submitting the form redirect the browser to the Payroc UAT page (payment page for sale/pre-auth, secure-card page for save-card) without an error? If not, diagnose before continuing.

---

## Step 3 — Build the receipt page

Read the reference for your transaction type:
- **Sale:** `references/sale.md` — Step 3
- **Pre-auth:** `references/pre-auth.md` — Step 3 (receipt response is the same as sale; durable storage requirement for `UNIQUEREF` applies)
- **Save a card (recurring):** `references/recurring.md` — Stage A, Step 3 (different receipt: `CARDREFERENCE` to store; `A`/`E14`/`E43`/`E44` RESPONSECODE enum; separate Secure Token URL; different response-hash order)

> **Apply the Step 1 discipline to RESPONSECODE branching and any other receipt-callback enum.** Read the receipt narrative copy before writing the handler — `references/build-receipt-page.md` for sale/pre-auth, `references/save-payment-details/build-receipt-page.md` for save-card. Do not branch on a remembered subset of `RESPONSECODE` values — this skill's error taxonomy lists `A` / `D` / `R` / `C` as sale examples, not as a canonical set, and the **save-card enum is entirely different** (`A`/`E14`/`E43`/`E44`, where `A` means "stored"). The sale reference surfaces approval codes beyond `A` (e.g. `E`); the reference is the source of truth. **Known past failure pattern:** treating `RESPONSECODE == 'A'` as the only success and silently misclassifying real approvals because the canonical set was larger than the memorised one. Read the reference; branch on the set it documents.

> **Recurring: store `CARDREFERENCE` durably.** It is the secure token you reuse to charge the customer — persist it (and `MERCHANTREF`) to the database, never to session/TempData. Verify the response hash (save-card order: `TERMINALID:RESPONSECODE:RESPONSETEXT:MERCHANTREF:CARDREFERENCE:DATETIME:SECRET`) before trusting it.

### Checkpoint

Does the receipt handler receive the Payroc redirect, verify the response hash without error, and correctly parse the receipt fields (`RESPONSECODE` + `UNIQUEREF` for sale/pre-auth; `RESPONSECODE` + `CARDREFERENCE` for save-card, persisted durably)? If not, diagnose before continuing.

---

## Step 4 — Test transaction

- **Sale:** `references/sale.md` — Step 4
- **Pre-auth:** same sale test path (steps 1–5 in `references/sale.md`), then also:
  6. Trigger the capture call using the stored `UNIQUEREF`
  7. Confirm HTTP 200 with `transactionResult` in the response body

> **For pre-auth capture: read the `transactionResult` schema from `references/api-schema.md` before writing the success branch.** `transactionResult.status` and `transactionResult.responseCode` are both enums. **Known past failure (from sibling integrations):** a model branched only on `status == "approved"` and silently treated real approvals as failures because the actual value was `"ready"` (authorized + queued for capture) with `responseCode: "A"` / `responseMessage: "APPROVAL"`. Read the full `transactionResult.status` enum, identify every value that pairs with bank approval, and branch on the full set — do not build the success check from a remembered subset.

For **save-card (recurring)**, the Step 4 milestone is "the card saved successfully" — `RESPONSECODE=A` on the save-card receipt with `CARDREFERENCE` captured and stored. Then continue to **Step 5** to set up the actual repeat payment.

### Checkpoint

`RESPONSECODE=A` confirmed with a test card, and response hash verification passes? (Pre-auth: capture also returns HTTP 200 *and* the `transactionResult` success branch was verified against the full enum? Save-card: `CARDREFERENCE` captured and persisted durably?) If not, use the error taxonomy. Don't mark complete until all conditions are met.

---

## Step 5 — Set up repeat payments (recurring only)

Skip this step unless the integration needs recurring billing. Read: `references/recurring.md` — Stage B, and `references/repeat-payments-api-schema.md` for every endpoint, field, and enum.

This stage is REST API over **Bearer-token auth** (obtain a token from the identity service exactly as for pre-auth capture) — not the HPP HMAC hash. Pick the path the developer chose in intake:

- **Use Payroc's gateway** — create a **Payment Plan** (`POST .../payment-plans`), then a **Subscription** (`POST .../subscriptions`) whose `paymentMethod` is `{ "type": "secureToken", "token": "<CARDREFERENCE>" }`. The gateway collects on schedule (`automatic`) or you collect with `.../pay` (`manual`).
- **Use their own software (MIT)** — run each charge with `POST /payments`, `paymentMethod.type: secureToken` + the token, plus an `order.standingInstructions` block (`sequence`: `first` then `subsequent`; `processingModel`: `unscheduled`/`recurring`/`installment`).

> **Read the right reference for the right value.** Plan/subscription enums (`type`, `frequency` — note `fortnightly`/`yearly`, `onUpdate`, `onDelete`) and the MIT `standingInstructions` / `channel` enums are in `references/repeat-payments-api-schema.md`. Don't infer them by analogy. And remember the casing flip: the agreement was UPPERCASE `STOREDCREDENTIALUSE` on the form; here it's lowercase `mitAgreement` / `processingModel`.

> **Subscriptions need their payment plan (and a token) to exist first.** Create the plan before the subscription. The token already exists — it's the HPP `CARDREFERENCE`.

### Checkpoint

Gateway path: subscription created and `currentState.status` is `active` in UAT (and a `manual` `/pay` succeeded if applicable)? MIT path: first charge returns HTTP 200 with the `transactionResult` success branch verified against the full enum in `references/api-schema.md` (a real approval may be `status: "ready"` with `responseCode: "A"`)? Did you read the repeat-payments schema before emitting endpoints/enums? If not, use the error taxonomy.

---

## Local testing strategy

**Steps 1–3** (hash generation, HPP redirect, and receipt page — for sale, pre-auth, and save-card) can all be tested with `localhost`. The receipt redirect is triggered by the customer's browser — Payroc's servers never call the receipt URL directly, so there is no reachability requirement. (Save-card uses a *separate* Self-Care field, the **Secure Token URL**, for its redirect — localhost is still fine.)

**Step 4 capture (pre-auth) and Step 5 repeat payments (recurring)** are server-to-server REST calls your app makes outbound to Payroc, so they work from localhost too — they just need a **Bearer token** from the identity service (`x-api-key` → `access_token`), not the HMAC hash. No public URL or tunnel is required for these.

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
| 401 on capture/repeat-payments API call | Bearer token expired or wrong API key | Re-generate the Bearer token; confirm the `x-api-key` value used with the identity service |
| Save-card: error from HPP immediately on redirect, or hash mismatch | Sale hash recipe reused for save-card (left AMOUNT in, used ORDERID, or omitted ACTION), or posted to `paymentpage` instead of `securecardpage` | Re-read `references/save-payment-details/authenticate-your-requests.md`; the recipe is `TERMINALID:MERCHANTREF:DATETIME:ACTION:SECRET` (no AMOUNT). Confirm the endpoint is `/merchant/securecardpage`. |
| Save-card: gateway rejects `STOREDCREDENTIALUSE` (or REST rejects `mitAgreement`/`processingModel`) | Wrong casing for the surface | HPP form POST uses UPPERCASE (`RECURRING`); REST APIs use lowercase (`recurring`). Read the reference for the surface you're emitting. |
| Save-card: receipt handler never fires | Save-card redirect registered in the wrong Self-Care field | The save-card receipt uses the **Secure Token URL** field, separate from the sales/pre-auth receipt URL. Confirm it's registered there. |
| Save-card: app logged failure but card was stored | Branched on the sale `RESPONSECODE` set instead of the save-card set | Read `references/save-payment-details/build-receipt-page.md`: the save-card enum is `A`/`E14`/`E43`/`E44`; `A` = stored. |
| 4xx creating a subscription | Payment plan or secure token doesn't exist yet, or `paymentPlanId`/`token` wrong | Create the Payment Plan first; set `paymentMethod` to `{ "type": "secureToken", "token": "<CARDREFERENCE>" }`. Read `references/repeat-payments-api-schema.md`. |
| MIT charge with token rejected / mis-sequenced | `standingInstructions` missing, or `sequence`/`processingModel` wrong | First charge is `sequence: first`, later charges `sequence: subsequent` with `referenceDataOfFirstTxn`. If you send `credentialOnFile.mitAgreement`, you must send `standingInstructions` in `order`. |
| Repeat-payments REST call rejects `channel` | Invalid `channel` value (e.g. `internet`/`online`/`ecommerce`) | `PaymentRequestChannel` is `pos`/`web`/`moto` — read `references/repeat-payments-api-schema.md`, don't infer by analogy. |

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
- [ ] (Save-card only) Hash function validated against the example hash in `references/save-payment-details/authenticate-your-requests.md` — recipe has no AMOUNT and includes ACTION
- [ ] (Save-card only) Form POSTs to `/merchant/securecardpage`; `STOREDCREDENTIALUSE` is UPPERCASE
- [ ] (Save-card only) Receipt branch uses the save-card `RESPONSECODE` set (`A`/`E14`/`E43`/`E44`) and `CARDREFERENCE` is persisted to durable storage (not session/TempData)
- [ ] (Save-card only) Save-card redirect registered in the Self-Care **Secure Token URL** field
- [ ] (Recurring only) Stored-credential usage casing matches the surface — UPPERCASE on the form, lowercase `mitAgreement`/`processingModel` on the REST API
- [ ] (Recurring, gateway) Payment plan created before subscription; subscription `paymentMethod` is `{ type: secureToken, token: <CARDREFERENCE> }`; `currentState.status` is `active` in UAT
- [ ] (Recurring, MIT) First charge sent with `standingInstructions` (`sequence: first`); follow-ons use `sequence: subsequent` with `referenceDataOfFirstTxn`; `channel` is a valid enum value
- [ ] (Recurring only) Repeat-payments endpoints, fields, and enums were read from `references/repeat-payments-api-schema.md`, not from memory

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

**Reusing the sale hash function for save-card.** The save-card recipe is `TERMINALID:MERCHANTREF:DATETIME:ACTION:SECRET` — no AMOUNT, MERCHANTREF instead of ORDERID, plus ACTION. A sale hash copied across unchanged fails every save-card request with a cryptic hash error. (Same family of mistake as assuming the AMOUNT format.)

**Charging an AMOUNT during a save/tokenize.** Saving a card is a $0 tokenization, not a sale — there is no AMOUNT field on the `securecardpage` form. If you find yourself building an amount into the save-card request, you've conflated it with the sale flow.

**Storing `CARDREFERENCE` in session or TempData.** The secure token must survive far beyond the current request — it's how you charge the customer next month. Persist it to durable storage, exactly like `UNIQUEREF` for pre-auth.

**Calling Subscriptions before the payment plan (and token) exist.** The subscription links a plan to a token; both must exist first. With HPP save-card the token already exists (`CARDREFERENCE`), so create the plan, then the subscription.

**Mixing up stored-credential casing across surfaces.** UPPERCASE `STOREDCREDENTIALUSE` on the HPP form; lowercase `mitAgreement` / `processingModel` on the REST API. They describe the same agreement but the gateway rejects the wrong casing for the surface.

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
> - **Recurring billing** (if applicable) — card saved on the Hosted Page via `securecardpage` (its own hash recipe and receipt), `CARDREFERENCE` stored durably, and repeat payments set up either through Payroc's gateway (Payment Plan + Subscription) or your own merchant-initiated charges (`secureToken` + `standingInstructions`), verified in UAT.
>
> **Before going live:** swap the UAT endpoint URLs for production URLs — this applies to the HPP endpoints (`paymentpage` / `preauthpage` / `securecardpage`) and every REST endpoint (capture, payment-plans, subscriptions, payments) — confirm them in the references. Point credentials to the production terminal, confirm the receipt URL(s) — including the **Secure Token URL** if you save cards — are registered in the production Self-Care Portal, and remove any test card numbers.

Offer next steps:

- **Background validation webhook** — a server-to-server POST on every transaction, independent of the receipt redirect; useful for reconciliation and as a fallback if the redirect fails
- **Manage the recurring lifecycle** (if recurring) — update/deactivate/reactivate subscriptions, update saved cards (`ACTION=update` or the secure-token update endpoint), and handle dunning for missed payments
- **Hosted Fields** (Phase 2) — Payroc-hosted card input widgets embedded in your own form; no page redirect

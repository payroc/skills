---
name: integrate-hosted-fields
description: >-
  Guide an ISV developer or merchant through integrating Payroc's Hosted Fields
  from credential setup to first successful UAT test transaction. Use this skill
  whenever someone asks about integrating Payroc Hosted Fields, embedding card
  input fields or a payment form in their own checkout page, using the Payroc JS
  payment library, generating a Payroc session token, tokenizing payment details
  with Payroc, or getting Payroc embedded payments working in their application
  — even if they don't explicitly mention "integration" or ask for step-by-step
  guidance. Also use it when a developer has HPP working and asks about the
  embedded alternative.
metadata:
  version: "0.1.0"
  category: integration
  status: draft
---

# Payroc Hosted Fields Integration

**Scope: CNP (card-not-present) Hosted Fields — one-time sale transactions, tokenization (save payment details), and recurring billing.**

On first invocation, announce to the developer:

> **Payroc Hosted Fields Integration**
> I'll guide you from credential setup through a successful UAT test transaction.
> This covers card-not-present payments via Payroc's Hosted Fields — where Payroc-hosted card input widgets are embedded directly in your own checkout page.
>
> **How Hosted Fields works (three parts):**
> 1. Your server generates a session token by calling Payroc's API — this authorises the JS library to render secure card fields
> 2. Payroc's JS library injects iFrame card input fields into your page; your customer never leaves your site
> 3. On submit, the library tokenizes the card details and gives you a single-use token; your server uses that token to call the Payroc payments API and process the charge
>
> **Hosted Fields vs Hosted Payment Pages:** If you need a redirect-based flow where the customer briefly leaves your site to pay on a Payroc-hosted page, that's Hosted Payment Pages — a different product not covered by this skill.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
# Identity service (Bearer token)
POST https://identity.uat.payroc.com/authorize
x-api-key: <api-key>

# Session token
POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/hosted-fields-sessions
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json

# Payments API
POST https://api.uat.payroc.com/v1/payments
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

---

## References

All sources live in the local `references/` files below — this skill emits from them, not from live lookups and not from memory. These are local snapshots, authoritative for this skill; their source URLs and last-synced dates are recorded in [`references/_sources.md`](references/_sources.md). Three complementary kinds of source, each owning a different kind of question — using the wrong source for a question is a known failure mode:

- **API schema reference (`references/api-schema.md`) — source of truth for values and shapes that cross the wire to the Payroc API.** Field names, enum values, required fields, request and response schemas. Whenever you need to know *what a Payroc API field is called* or *what values it accepts*, read it. It's a curated slice of the OpenAPI spec.
- **Narrative guides (`references/<page>.md`) — source of truth for approach.** How to sequence the calls, what the flow looks like end-to-end, how the JS library fits in. Use them to learn *how to compose* the integration. They occasionally hedge on exact SDK shape — when they do, drop to the third source.
- **SDK JS file (`references/hosted-fields-sdk.js`) — source of truth for SDK config shape, accepted child keys, and the public API method surface.** This local snapshot is the same JS you put in the `<script>` tag. The SDK iterates a fixed list of keys inside `fields.card` (et al.) and silently ignores anything else; it exposes a fixed list of methods on the `hostedFields` instance. The narrative guides can be ambiguous on exact placement and naming (a known docs-portal issue corroborated by feedback from prior runs) — the SDK source is not. Read it as text whenever you need to verify a property name, an accepted child key, or a method name.

If your question is "how do I structure the request body?" — that's the schema reference. If your question is "what order do I make these calls in?" — that's the guides. If your question is "what does `new Payroc.hostedFields({...})` actually accept?" or "does `cardForm.<method>` exist?" — that's the SDK source.

| Source | Local file |
| --- | --- |
| API schema reference (enums, required fields, request/response schemas) | `references/api-schema.md` |
| Step 1 — Authenticate session | `references/authenticate-your-session.md` |
| Step 2 — Create payment form | `references/create-a-payment-form.md` |
| Step 3 — Run a sale | `references/run-a-sale.md` |
| Extension — Style fields | `references/style-your-fields.md` |
| Extension — Custom fields | `references/add-your-own-fields.md` |
| Extension — Close session | `references/close-a-session.md` |
| Extension — Save payment details | `references/save-a-customers-payment-details.md` |
| Extension — Update payment details | `references/update-a-customers-payment-details.md` |
| Extension — Recurring billing | `references/recurring-billing.md` |
| 3-D Secure — overview | `references/3-d-secure.md` |
| 3-D Secure — run a sale with 3DS (implementation flow) | `references/run-a-sale-with-3-d-secure.md` |
| **SDK JS file** (authoritative for SDK config shape + public API method names — read as text) | `references/hosted-fields-sdk.js` — the same JS you load in `<script>` |

The local snapshots' source URLs and last-synced dates are in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core Principles

1. **Inspect before asking** — read the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — ask the intake questions and wait for the developer's answers before writing any implementation code. Posing a question while simultaneously providing code "assuming" the answer defeats the gate; the intake is a decision point, not a preamble.
3. **Validate before advancing** — don't move to the next step until the developer confirms the current step's checkpoint passes in UAT.
4. **Read the local references, don't guess — and pick the right one for the question.** There are *three* kinds of source, not two. Using the wrong one for a question is how memorised-but-wrong values leak through.
   - **Schemas, field names, enums, required fields → `references/api-schema.md`.** Anything that crosses the wire to the API. Names you'll meet most often: `paymentRequest`, `payment` (response), `transactionResult`, `card`, `secureTokenSummary`, `schemas-credentialOnFile`, `standingInstructions`, `firstTxnReferenceData`, `hostedFieldsCreateSessionRequest`, `HostedFieldsCreateSessionRequestScenario`, `StandingInstructionsSequence`, `StandingInstructionsProcessingModel`. Looking these up by name in the schema reference is faster than scanning narrative docs for shape.
   - **Approach, sequencing, library wiring → the narrative guides** (`references/<page>.md`). "Which call comes first?" and "how do I attach the JS library?" are guide questions, not schema questions.
   - **SDK config shape, accepted child keys, public API method names → the SDK JS file itself** (`references/hosted-fields-sdk.js`). This local snapshot is the same JS you load in `<script>`. The SDK validates `fields.card[key]` against a fixed iteration list and silently ignores keys it doesn't recognise; it exposes a fixed set of methods on the `hostedFields` instance. Narrative docs have been documented as ambiguous on exact placement and method naming — the SDK source is not. Read the JS as text whenever you need to confirm a property name, an accepted child key inside `fields.card`, or a method on `cardForm`.
   - **Request and response schemas diverge — read both.** Don't assume the response mirrors the request. For Hosted Fields the response uses `card` (not `paymentMethod`); `cardSchemeReferenceId` lives on `transactionResult`, not on the card. Inferring the response from the request name is a known footgun.
   - **The JS library CDN URL, SRI hash, and `libVersion` are four-part version strings.** Don't emit the version from memory — read it from `references/create-a-payment-form.md` (and the snapshot in `references/hosted-fields-sdk.js`) and use the full four-part string (e.g. `1.7.0.261457` in UAT, `1.7.0.261471` in production). UAT and production may publish different versions.
5. **Read-then-emit, per value.** Before emitting any enum value (e.g. `channel`, `scenario`, `paymentMethod.type`, `transactionResult.status`, `standingInstructions.sequence`, `processingModel`, `secCode`, `accountType`), any SDK config property or accepted child key, or any method call on `cardForm`, read the relevant local reference. Don't treat this skill's failure-pattern callouts (see Step 3, Step 4, error taxonomy, anti-patterns) as authoritative — they exist so you recognise mistakes by symptom, not so you can skip reading the reference. Read enums from `references/api-schema.md`, not from memory. A plausible English-sounding enum value (e.g. `"internet"` for `channel`, `"approved"` as the only success status) is the most common form this failure takes.
6. **Never hardcode credentials** — API keys and terminal IDs must come from environment variables or a secrets manager, never source code.
7. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.
8. **Session tokens are per-session** — generate a fresh session token for each checkout session. The 10-minute expiry is intentional; never cache them across users or requests.

---

## Intake

**First, scan the codebase.** Look for:

- Server-side language and framework
- Existing checkout, order, or payment-related routes and handlers
- Any existing HTTP client infrastructure (HttpClient, fetch, axios, RestClient, etc.)
- Any partial Hosted Fields implementation (session token calls, Payroc JS library references)
- How environment variables or configuration is managed
- Whether a `PaymentService` or similar exists that could be extended

Use what you find to frame your questions in the developer's own terms and avoid asking for things you can already infer.

Then ask for what you still need. At minimum, confirm:

**Question 1 — Integration type:**

| | Hosted Fields | Hosted Payment Pages |
|---|---|---|
| Customer experience | Stays on your page — Payroc card widgets embedded in your form | Leaves your site briefly to pay on Payroc's hosted page |
| Payment execution | Your server calls the Payroc payments API with a single-use token | Automatic on form POST; Payroc redirects the customer back |
| This skill | ✓ Covered here | Separate skill — not covered here |

- **Hosted Fields** → continue
- **Hosted Payment Pages** → explain the difference and offer to stop or redirect

**Question 2 — Transaction type:**

- **Sale (capture immediately)** → continue with the standard flow
- **Save payment details (tokenization)** → note this requires the `tokenization` scenario; confirm the developer wants to vault card details for later use
- **Both** → implement sale first, then add tokenization as an extension
- **Recurring billing** → note this requires tokenization as a prerequisite (the card must be saved on the first charge and reused for subsequent charges); confirm the developer wants to implement standing instructions. When you reach Step 4, also read `references/recurring-billing.md`.

**Question 3 — Payment method:**

Hosted Fields supports Card, ACH, and PAD — but only one type per page. Confirm which the developer needs. If unclear, default to Card.

**Question 4 — 3-D Secure / SCA:**

Only ask this for **card** flows. ACH and PAD are out of scope for 3DS.

- **No 3DS needed** → continue with the standard card flow
- **Yes — UK / EU customers, PSD2 SCA, or merchant wants liability shift** → flag the additional prerequisites below (terminal must be enabled for 3DS by Payroc support, and a webhook URL must be registered); the integration grows an extra MPI call between `submissionSuccess` and the payment, and a `threeDSecure` block on the payment request body. Read `references/run-a-sale-with-3-d-secure.md` before writing any 3DS code.
- **Unsure** → if customers are in the UK or EEA, default to "yes". Acquirers will soft-decline non-authenticated transactions under PSD2 SCA.

**Wait for the developer's answers before continuing.** Do not write implementation code, provide examples, or advance to Prerequisites until you have explicit confirmation for all four questions. The answers determine scope entirely — a developer targeting HPP takes a different path, ACH requires different form configuration than Card, and 3DS adds a prerequisite that must be kicked off with Payroc support before code can be tested end-to-end.

---

## Prerequisites

Before writing any code, confirm the developer has all three:

1. **API key** — used to obtain a Bearer token from Payroc's identity service. This is different from the HPP terminal secret; it is a longer-lived API credential provisioned by the Payroc Integrations team.
2. **Processing terminal ID** — a UAT terminal ID provisioned by the Payroc Integrations team. UAT is Payroc's test environment; there is no self-serve signup.
3. **UAT access confirmed** — Hosted Fields does not require Self-Care Portal configuration for the core sale flow (no receipt URL to register, unlike HPP).

If anything is missing:
- API key / UAT access → contact the Payroc Integrations team
- If the developer has HPP credentials (`TERMINAL_ID_NO_AVS` and `PAYROC_API_KEY_PAYMENTS`) — note that `PAYROC_API_KEY_PAYMENTS` is the API key used for Bearer token auth in Hosted Fields too. The same terminal ID applies. Flag this explicitly so the developer knows their existing credentials are the right ones.

**If the developer answered "yes" to Question 4 (3DS / SCA):** add two more prerequisites that must be in motion before 3DS can be tested end-to-end:

4. **Terminal enabled for 3DS** — Payroc support enables 3DS on the processing terminal. The MPI endpoint (`/merchant/mpi`) will not respond until this is done.
5. **Webhook URL registered with Payroc support** — Payroc posts the MPI result (`mpiReference`, `result`, `status`, `eci`) to a URL the merchant provides. The URL must be reachable from Payroc's network and registered with support before any 3DS sale will complete.

Tell the developer to email **cs@payroc.com** now to kick both items off, since they require a human turnaround. Building the code does not depend on them — it can proceed in parallel — but you cannot complete an end-to-end UAT 3DS transaction until both are in place.

### Checkpoint

API key and processing terminal ID confirmed? (If 3DS: cs@payroc.com email sent for terminal enablement and webhook registration?) If not, stay here and help resolve what's missing.

---

## Step 1 — Authenticate: get a Bearer token

Read: `references/authenticate-your-session.md`

Read the page before writing anything. From the local reference, confirm and use:

- The identity service endpoint (test vs production)
- The required header and its format
- The response field containing the access token
- The token expiry and what to do when it expires

Implement a server-side function that POSTs to the identity service with the API key and returns the access token. This must run server-side — the API key must never be sent to the browser.

### Checkpoint

Does the call return a 200 with an `access_token`? If not, verify the API key value and the endpoint URL before continuing.

---

## Step 2 — Create a session token

Read: `references/authenticate-your-session.md` (same page covers both auth calls)

A session token authorises the JS library to render fields for a specific checkout session. Read the reference to confirm:

- The session token endpoint (test vs production)
- The required request body fields: `libVersion`, `scenario`, and the `Idempotency-Key` header
- The `libVersion` value — **do not hardcode this from memory; read it from `references/create-a-payment-form.md` in Step 3 first, then come back and use the current value**
- The `libVersion` is a **four-part** string (e.g. `1.7.0.261457` in UAT, `1.7.0.261471` in production). The same four-part version appears in the CDN URL the create-a-payment-form page emits — they must match. Do not truncate it to three parts or substitute a different version from memory. The `hostedFieldsCreateSessionRequest.libVersion` description in `references/api-schema.md` also names the current production version.
- **`libVersion` is environment-specific.** UAT and production may publish different four-part versions. "Use the same value everywhere" is true *within* an environment but not *across* environments — when cutting over to production, re-read `libVersion`, the CDN URL, and the SRI hash from the production `create-a-payment-form.md` together. Never carry the UAT version across.
- The valid `scenario` values come from the `HostedFieldsCreateSessionRequestScenario` enum in `references/api-schema.md` (`payment` for sale or sale-and-tokenize, `tokenization` for save-only). Use `payment` whenever you intend to actually charge the card — even if you *also* want to save it on the same call.
- The session expiry (10 minutes from creation)
- The response field containing the session token

Implement a server-side endpoint that generates a session token on demand and returns it to the front-end. The endpoint should:
- Generate a fresh Bearer token (or reuse one that isn't close to expiry)
- POST to the session token endpoint with `libVersion`, `scenario: "payment"`, and a unique `Idempotency-Key`
- Return the `token` value to the client

**Important:** Generate a new session token for each checkout page load. Do not cache or reuse session tokens across users or across page navigations — the 10-minute window is tight and a stale token will silently fail to initialize the form.

### Checkpoint

Does the call return a 200 with a `token` field? If not, check the Bearer token is valid and the terminal ID in the path is correct.

---

## Step 3 — Load the JS library and initialise the form

Read: `references/create-a-payment-form.md`

Read the page before writing anything. From the local reference, confirm and use:

- The CDN URL for the JS library — **read it from the reference; don't hardcode a version from memory**
- The SRI hash (`integrity` attribute) for the current version
- The `libVersion` value you need in Step 2's request body
- The field configuration options and their `target` selectors
- The `initialize()` call and what it returns
- The `submissionSuccess` event payload — specifically the `token` field and its expiry

Implement the front-end integration:

1. Add a `<script>` tag in the page `<head>` (or a `@section Scripts` block) pointing to the CDN URL with the SRI hash

   > **Script ordering:** The Payroc SDK must be loaded before the init code runs. If you are using a templating engine or framework that separates body content from a deferred script section (footer, script bundle, layout partial, etc.), ensure both the SDK `<script>` tag and the init block are placed in the same deferred section, with the SDK tag first. Placing the init code in the body while the SDK tag is deferred will silently fail — `Payroc` will be undefined and no error will be raised.

2. Add container elements to the payment form — `<div>` elements with CSS class or ID selectors for each field (`cardholderName`, `cardNumber`, `expiryDate`, `cvv`) plus a submit target
3. Initialise the hosted fields object with the session token, the `mode: "payment"` option, and field configuration pointing to your container selectors
4. Call `.initialize()`
5. Listen for `submissionSuccess` — this fires when the library has validated and tokenized the card; the event payload contains the single-use token your server needs
6. Listen for `error` — log or display errors from `type: "config"`, `"init"`, `"field"`, and `"submission"` categories

### Before emitting the `new Payroc.hostedFields(...)` config — read the SDK source

The narrative `create-a-payment-form.md` is the right starting point, but the docs portal has been documented as ambiguous on at least one SDK-shape question (a prior run hedged between `cardForm.submitFields()` and `cardForm.submit()` — neither of which exists). **The SDK JS you put in `<script>` is also a readable JS file, snapshotted locally.** Read `references/hosted-fields-sdk.js` and grep it before emitting the config:

1. **What to read.** The local snapshot `references/hosted-fields-sdk.js` — the same JS you'll load in `<script>` (its header records the UAT/prod CDN URLs and the four-part `libVersion`). Don't paraphrase the SDK from training data; read the bytes.
2. **What to verify.**
   - The list of keys the SDK iterates inside `fields.card` (and equivalent containers for `fields.ach` / `fields.pad`). Anything outside that list is silently ignored. Search for the iteration over `fields.card` and read off the accepted keys.
   - The set of methods exposed on the `hostedFields` instance — i.e. what `cardForm.*` calls are legal. Search for the constructor and the prototype / `Object.assign` / class body.
3. **Only then emit.** Place every container target inside the accepted-keys list. Wire each method call only against the exposed surface. If a method you assumed exists isn't on the list, do not invent a different name and try again — the SDK is owning that responsibility internally.

### Known SDK-shape failure patterns

These are mistakes prior models have made on this skill. They're listed so you can recognise the symptom — the fix is always **read the SDK source and emit what it currently accepts**, not "use the value below."

- **Symptom:** SDK fires `error` with `"A submit button is required for payment forms"` even though the config has a submit-target property at the top level (e.g. `submitButton: { target: '#pay' }`). **Past wrong:** the submit target placed at the top level of the config object; the SDK only reads it from inside `fields.card`. **Verify:** grep `references/hosted-fields-sdk.js` for the iteration over `fields.card[...]` and identify where it actually looks up the submit key.
- **Symptom:** Runtime `TypeError: cardForm.submitFields is not a function` (also seen as `.submit()`, `.validate()`) on a manual click handler. **Past wrong:** assuming the SDK exposes a programmatic submit-trigger and wiring `payButton.addEventListener('click', () => cardForm.submitFields())`. **Verify:** grep `references/hosted-fields-sdk.js` for the method surface on the instance; if your method isn't there, the SDK is rendering the submit element itself (as an iframe) and owning the click — delete the manual handler.
- **Symptom:** Field containers render with styled borders/backgrounds (page-level CSS) but stay non-interactable; no iframes inject; no `error` event fires. Already covered in the error taxonomy as the script-load-order issue — cross-referenced here so you have the full shape-related symptom set in one place.

When in doubt: the SDK JS is text. Read `references/hosted-fields-sdk.js`.

### Checkpoint

Do the card input fields render in the page? Does `submissionSuccess` fire (with a token in the payload) when you submit test card details? If not, check the browser console for `error` events.

---

## Step 3b — 3-D Secure (only if Question 4 answered "yes")

Read: `references/run-a-sale-with-3-d-secure.md`

Read the page before writing anything. The 3DS path inserts one extra server call and adds one block to the payment request:

1. After `submissionSuccess` fires (Step 3), your server calls `GET /merchant/mpi` (test: `payments.uat.payroc.com`, prod: `payments.payroc.com`) with the single-use token, amount, currency, orderId, email, processingTerminalId, and optionally `cardholderChallenge` (`REQUIRED` to force a challenge, `OPTIONAL` to let the issuer decide).
2. Payroc performs the 3DS challenge and posts the result to **the webhook URL you registered with cs@payroc.com**. The payload includes `mpiReference`, `result`, `status`, `eci`.
3. Your webhook persists the `mpiReference` keyed by `orderId` (or similar) so Step 4 can look it up.
4. In Step 4's payment request, add a `threeDSecure` block: `{ "serviceProvider": "gateway", "mpiReference": "<from webhook>" }`. This is what carries the authentication through to the acquirer for liability shift.

**PSD2 / UK SCA exemptions (TRA, low-value, MIT):** the public docs do not spell these out in detail. If the developer needs explicit exemption handling, escalate to the Payroc Integrations team rather than guessing.

### Checkpoint

Does the MPI GET return a 200? Does your webhook receive a result with an `mpiReference`? If neither happens, the terminal is likely not yet enabled for 3DS — confirm with Payroc support before proceeding.

---

## Step 4 — Execute the payment

Read: `references/run-a-sale.md`

Read the page before writing anything. From the local reference, confirm:

- The payments API endpoint (test vs production)
- The required headers: `Content-Type`, `Authorization: Bearer <token>`, `Idempotency-Key`
- The minimum request body: `channel`, `processingTerminalId`, `order` (orderId, amount in lowest denomination, currency), and `paymentMethod`
- The `paymentMethod` structure for a single-use token: `type: "singleUseToken"`, `token: <value from submissionSuccess>`
- The success HTTP status and how to confirm the payment processed

> **Read every enum value from `references/api-schema.md` — don't infer from English plausibility.** Every enum-typed string in the request body (`channel`, `paymentMethod.type`, `standingInstructions.sequence`, `processingModel`, `secCode`, `accountType`, currency, country) must come from the local schema reference. **Known past failure:** a model emitted `channel: "internet"` because the value sounds reasonable for an in-browser checkout — Payroc returned HTTP 400 with the enum list in the error detail. The correction isn't to memorise the right value here; it's to read `paymentRequest.channel` (or whichever field you're about to set) from `references/api-schema.md` as you construct the body. Plausible-sounding cousins (`internet`, `online`, `ecommerce`, `card-not-present`) are the most common form this failure takes.

From the `submissionSuccess` handler, send the single-use token to your server. Your server then:
1. Generates (or reuses) a valid Bearer token
2. Constructs the payment request body with the single-use token
3. **If 3DS was used (Step 3b ran):** add `threeDSecure: { serviceProvider: "gateway", mpiReference: "<value from your MPI webhook>" }` to the payment request body
4. POSTs to the payments API with a fresh `Idempotency-Key`
5. Reads the HTTP status — 201 means the **request was processed** by Payroc, not that the issuer approved. The approval / decline outcome lives in the response body (`transactionResult.status` and `transactionResult.responseCode`). Branch on the response body, not the HTTP code.

> **Build the success branch from the full enum — not from a remembered subset.** Read `references/api-schema.md`'s `transactionResult.status` enum as you write the success check. Identify *every* value that pairs with bank approval, and branch on that set. **Known past failure:** a model branched on `status == "approved"` only and silently logged real approvals as failures because the API returned `"ready"` (authorized + queued for capture) with `responseCode: "A"` / `responseMessage: "APPROVAL"`. The fix isn't "also accept `ready`" — the meta-mistake is building the check from a partial mental model of the enum. Read the enum.

> **Framework note — antiforgery / CSRF on the AJAX handler.** The endpoint that receives the single-use token from `submissionSuccess` is a `fetch` / XHR POST, not a traditional HTML form submit. Most server frameworks enforce CSRF/antiforgery on `POST` by default. Two options, in order of preference: **(1) thread the token through** — read the framework's CSRF token from the rendered page and send it as a request header from the `submissionSuccess` callback; **(2) disable it on this one handler** — acceptable for demos and internal-only tools, not for production.
>
> Framework specifics:
>
> - **ASP.NET Core / Razor Pages.** `[IgnoreAntiforgeryToken]` must be applied **at class level** on the `PageModel` — applying it to a single handler method triggers `MVC1001` at build time. To keep antiforgery on, render `@Html.AntiForgeryToken()` in the form and send the resulting `__RequestVerificationToken` value as the `RequestVerificationToken` header.
> - **Django.** Either send the `csrftoken` cookie value as the `X-CSRFToken` request header, or decorate the view with `@csrf_exempt`.
> - **Rails.** Send the `csrf-token` meta-tag value as the `X-CSRF-Token` header, or `skip_before_action :verify_authenticity_token` on the controller action.
> - **Express + `csurf`.** Send the token as the `csrf-token` (or `X-CSRF-Token`) header per your `csurf` configuration.
> - **Laravel.** Send the `XSRF-TOKEN` cookie value as the `X-XSRF-TOKEN` header (default Laravel behaviour), or add the route to `VerifyCsrfToken::$except`.

**Single-use tokens are one-time only.** If the payment API call fails for any reason other than a genuine decline, the developer must generate a new session token and re-initialise the form before the customer can retry — the single-use token cannot be resubmitted.

### Checkpoint

Does the payments API return HTTP 201 in UAT with a test card? If not, use the error taxonomy below.

---

## Local testing strategy

All steps (session token generation, form rendering, payment API call) work with `localhost` because there is no browser redirect and no server-side webhook from Payroc. The entire flow runs within the developer's browser session.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Form fields don't render; no `submissionSuccess` ever fires | Session token expired (>10 min since generation), or `initialize()` not called | Regenerate session token on page load; check `error` events for `type: "init"` or `type: "config"` |
| `error` event with `type: "config"` | Session token missing or invalid in constructor | Confirm session token is passed to `new Payroc.hostedFields({sessionToken: ...})` correctly |
| Payment API 401 | Bearer token expired or wrong API key | Re-fetch Bearer token; verify the `x-api-key` value used with the identity service |
| Payment API 409 | Idempotency key reused | Generate a fresh UUID v4 per payment request — never reuse idempotency keys |
| Payment API 400/422 | Single-use token already consumed or expired (30-min window or already used) | Token is one-time; the customer must re-enter card details — generate new session token and re-initialise form |
| CDN script fails to load | Stale or incorrect CDN URL | Read the current URL and SRI hash from `references/create-a-payment-form.md` |
| `libVersion` mismatch error | `libVersion` in session token request doesn't match the loaded JS library version | Read both from `references/create-a-payment-form.md` to ensure they match |
| Field containers are visible (styled borders/backgrounds rendered by CSS) but non-interactable — no iframes injected, no console error | Init code executed before the Payroc SDK script loaded. `new Payroc.hostedFields(...)` throws `ReferenceError: Payroc is not defined`; because `cardForm` is never created, the `.on('error', ...)` handler is never wired, so the error is silently swallowed | Ensure the SDK `<script>` tag is rendered and executed before the init code runs. In any layout that defers scripts, keep both the SDK tag and the init block in the same deferred section, SDK tag first |
| SDK begins initialising (iframes start loading) then immediately fires: `"CVV wrapper is required for card forms. If you do not have a wrapper, please provide false."` | The `cvv` field config is missing the `wrapperTarget` property, or the wrong key name was used (`wrapper` instead of `wrapperTarget`) | Add `wrapperTarget: false` to the `cvv` field config. If a wrapper element exists, pass its CSS selector string instead of `false`. Note: `wrapper: false` (wrong key) is silently ignored — the property name must be `wrapperTarget` |
| Payment declined (non-201 status or decline flag in response) | Test card not valid for UAT | Use a Payroc UAT test card; check `transactionResult.status` and `transactionResult.responseCode` in the response body |
| HTTP 201 returned but customer says card was declined | Confusing HTTP 201 with approval | 201 means Payroc accepted and processed the request, not that the issuer approved. The approval/decline outcome is in `transactionResult.status` (enum includes `declined`) and `transactionResult.responseCode` (e.g. `A`=approved, `D`=declined, `R`=referral, `C`=CVV failure). Branch on the body, not on 201. |
| CSP blocks the Payroc CDN host — script never loads, no `error` event fires | Content Security Policy missing the Payroc CDN host | Add the Payroc CDN host (the host of the `<script>` src — see the snapshot header in `references/hosted-fields-sdk.js` for the exact UAT and prod hosts) to `script-src` (for the JS file) AND to `frame-src` / `child-src` (for the iFrames the library injects). Also add `connect-src` for the tokenization XHRs. Remember to swap the UAT host for the prod host when going live. |
| MPI endpoint returns 404 or auth error | Terminal not enabled for 3DS, or webhook URL not registered | Email cs@payroc.com to enable 3DS on the terminal and register the webhook URL; no MPI / 3DS call will succeed until both are done. |
| Payments API returns HTTP 400 naming `"channel"` (or any other enum-typed field) in the error detail, with a list of accepted values | A non-enum value was emitted (past failures: `channel: "internet"`, `"online"`, `"ecommerce"`); the skill produced a plausible-sounding cousin instead of reading the schema reference | Read `paymentRequest.channel` (or the relevant field) from `references/api-schema.md` and emit one of the listed values. Do not infer enum values from English plausibility. |
| SDK fires `error` with `"A submit button is required for payment forms"` even though a submit-target property is present at the top level of the config | The property is at the top level and the SDK only reads submit-related keys from inside `fields.card`; anything outside the iteration list is silently ignored | Read `references/hosted-fields-sdk.js` and grep for the iteration over `fields.card[...]`. Place the submit target where the SDK actually reads it. Top-level submit-shaped keys are not in the schema. |
| Runtime `TypeError: cardForm.<method> is not a function` on a manual click handler (past failures: `submitFields`, `submit`, `validate`) | The method doesn't exist on the SDK's public surface — once the submit target is configured inside `fields.card`, the SDK renders it as an iframe and owns the click | Read `references/hosted-fields-sdk.js` and confirm which methods are exposed on the `hostedFields` instance. If your method isn't on the list, the SDK is handling submit internally — remove the manual handler rather than guessing a different name. |
| App logged a payment failure but the bank actually approved — response shows `responseCode: "A"` / `responseMessage: "APPROVAL"` | Server-side success check branched on a remembered subset of `transactionResult.status` (past failure: only `"approved"` accepted; `"ready"` — authorized + queued for capture — silently treated as a failure) | Read the `transactionResult.status` enum from `references/api-schema.md`. Branch on the full set of values that pair with bank approval. Do not build a success check from a partial mental model of the enum. |

---

## Validation checklist

- [ ] API key and terminal ID sourced from environment variables — not in source code
- [ ] Bearer token generated server-side — not exposed to the browser
- [ ] Session token generated per checkout page load — not cached across sessions
- [ ] JS library CDN URL and SRI hash read from `references/create-a-payment-form.md` — not hardcoded from memory
- [ ] `libVersion` in session token request matches the version in the CDN URL
- [ ] `submissionSuccess` confirmed to fire with a token before the payment API is called
- [ ] Idempotency key is a fresh UUID v4 per payment request
- [ ] HTTP 201 confirmed in UAT with a test card
- [ ] Single-use token not logged or stored beyond the immediate API call
- [ ] Every enum value in the request body (`channel`, `paymentMethod.type`, `standingInstructions.*`, etc.) was read from `references/api-schema.md`, not from memory
- [ ] SDK config keys and any `cardForm.*` method calls were verified against `references/hosted-fields-sdk.js` (read as text)
- [ ] Server-side success branch on `transactionResult.status` covers every approval value in the `references/api-schema.md` enum (e.g. `"ready"`) — not just a single remembered value

---

## Anti-patterns

**Hardcoding the JS library version or CDN URL** — the version changes with every release; hardcoded URLs will silently break when the version increments.

**Caching session tokens across page loads** — the 10-minute expiry means a cached token will expire during a slow checkout. Generate fresh on every checkout page load.

**Reusing idempotency keys** — sending the same key twice for different payment requests causes a 409; generate a fresh UUID v4 per request.

**Calling the payment API before `submissionSuccess`** — the single-use token only exists after the library fires `submissionSuccess`; polling for it or constructing a synthetic token will fail.

**Exposing the Bearer token to the client** — the Bearer token grants API access; keep it server-side only. The session token (returned to the client) is scoped and short-lived by design.

**Retrying with the same single-use token** — it can only be used once. On any retry scenario, the user must start the form flow again from a fresh session token.

**Placing the init code where the SDK script has not yet loaded** — many server-side templating engines and front-end frameworks separate page body content from deferred script blocks, rendering them in that order. If the init code lands in the body and the SDK `<script>` tag is placed in a deferred section, the init executes while `Payroc` is still undefined. The error is silent because `cardForm` is never created and the `.on('error', ...)` handler is never wired. Keep the SDK `<script>` tag and the init block together in the same deferred/bottom-of-body location, SDK tag first.

**Using `wrapper: false` instead of `wrapperTarget: false` on the CVV config** — the correct property name is `wrapperTarget`. Using `wrapper` (the wrong name) is silently ignored by the SDK, so the config validation error persists and the SDK's own error message gives no indication of the key name mismatch. Always use `wrapperTarget` — not `wrapper`. When no wrapper element exists, the value is the boolean `false`; when a wrapper element exists, the value is its CSS selector string.

```javascript
// Correct
cvv: { target: '.card-cvv', wrapperTarget: false },

// Wrong — silently ignored, config error persists
cvv: { target: '.card-cvv', wrapper: false },
```

**Emitting an enum value without reading the schema reference.** `channel`, `paymentMethod.type`, `standingInstructions.sequence`, `processingModel`, `secCode`, `accountType`, and `transactionResult.status` are all enums. Past failures: `channel: "internet"` (the value sounded reasonable for in-browser checkout but isn't in the enum); branching success-only on `"approved"` and missing `"ready"`. The skill cannot list the canonical values for you — they live in `references/api-schema.md`. Read the schema reference before each request body and each response branch.

**Trusting narrative SDK docs for property and method names.** The narrative `create-a-payment-form.md` has been documented as ambiguous on at least one SDK shape question (the `submitFields()` vs `submit()` hedge from a prior run). `references/hosted-fields-sdk.js` is the only unambiguous source for what `new Payroc.hostedFields({...})` accepts and what methods exist on `cardForm`. Read it as text before emitting any config or `cardForm.*` call.

**Adding a manual click handler that calls a method on `cardForm`.** Past failures invented `cardForm.submitFields()`, `cardForm.submit()`, `cardForm.validate()` — none of which the SDK exposes. Once a submit target is configured inside `fields.card`, the SDK renders it as an iframe and owns its click. The visible signal that you've taken a wrong turn is a `TypeError: cardForm.<method> is not a function`. Read `references/hosted-fields-sdk.js` to see which methods actually exist; if your intended method isn't one of them, delete the manual handler rather than guessing a different method name.

**Building a success check from a partial mental model of the enum.** A real run produced `status: "ready"` with `responseCode: "A"` / `responseMessage: "APPROVAL"` — bank approved, app logged a failure because the check was `status == "approved"`. The fix isn't to add `"ready"` to a hardcoded list — the underlying meta-mistake is reasoning about the enum from memory instead of the schema reference. Read `transactionResult.status` from `references/api-schema.md`, identify every value paired with bank approval, and branch on the full set.

---

## Completion

Once HTTP 201 is confirmed and all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Bearer token** — obtained server-side from Payroc's identity service using your API key; authorises all Payroc API calls.
> - **Session token** — scoped, short-lived token generated per checkout session; authorises the JS library to render card fields.
> - **Hosted Fields form** — Payroc's JS library renders iFrame card input fields in your page; card data never touches your server.
> - **Single-use token** — generated client-side by the library on form submit; passed to your server to execute the charge.
> - **Payment API call** — your server POSTs the single-use token to Payroc's payments API; HTTP 201 confirms the charge.
> - **Validated in UAT** — end-to-end transaction confirmed with a test card.
>
> **Before going live:** swap the UAT endpoint URLs for production URLs (identity, session token, payments API) and point credentials to the production terminal. Re-read `libVersion`, the CDN URL, and the SRI hash from the **production** `create-a-payment-form.md` page — these values are environment-specific and a UAT version will not work in production.

Offer next steps (based on what wasn't already implemented):

- **Tokenization** — save a customer's card details as a secure token for future charges; uses `scenario: "tokenization"` in the session token request and the secure-tokens API
- **Recurring billing** — configure standing instructions on the first charge and reuse the saved token for subsequent merchant-initiated transactions; read `references/recurring-billing.md`
- **Update a customer's saved card** — when a customer's card expires or changes, the saved secureToken's underlying card details can be updated without creating a new token. The flow uses `scenario: "tokenization"` (not `payment`) and is **non-transactional** — no charge or zero-auth is required. Read `references/update-a-customers-payment-details.md` before implementing.
- **3-D Secure** — if the developer skipped 3DS at intake but now needs it (e.g. acquirer is soft-declining UK transactions), see Step 3b above
- **Styling** — customise the hosted field appearance with CSS via the `styles` configuration option
- **Custom fields** — collect additional data alongside the card fields using `onPreSubmit` validation
- **Close session cleanup** — when the customer cancels or navigates away mid-checkout, call `destroy()` on the hosted fields instance to tear down the iFrames. This is separate from the 10-minute session-token auto-expiry and frees client-side resources. Read `references/close-a-session.md` for the exact API.
- **Hosted Payment Pages** — if the developer later needs a redirect-based flow (e.g. for ACH on a different page), that's the HPP skill

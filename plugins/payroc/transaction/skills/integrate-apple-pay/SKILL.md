---
name: integrate-apple-pay
description: >-
  Guide an ISV developer or merchant through integrating Apple Pay with Payroc's
  payments API from merchant setup through a first successful UAT test transaction.
  Use this skill whenever someone asks about adding Apple Pay to their Payroc
  integration, implementing Apple Pay on their checkout page, handling Apple Pay
  sessions with Payroc, processing digital wallet payments via Apple Pay, or
  getting Apple Pay working with the Payroc gateway — even if they don't
  explicitly mention "integration" or ask for step-by-step guidance.
metadata:
  version: "0.4.0"
  category: integration
  status: draft
---

# Payroc Apple Pay Integration

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/integrate-apple-pay/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Apple Pay Integration**
> I'll guide you from merchant setup through a successful UAT test transaction.
> This covers Apple Pay as a payment method on your checkout page — using the Apple Pay JS API to present the payment sheet and the Payroc Payments API to process the encrypted payment data.
>
> **How Apple Pay works with Payroc (four parts):**
> 1. Your domain is verified with Apple via the Self-Care Portal, giving you a domain ID
> 2. When a customer taps the Apple Pay button, the Apple Pay JS API fires an `onvalidatemerchant` event — your server calls the Payroc API to start a session and returns the response to Apple
> 3. Apple presents the payment sheet; the customer authorises with Face ID / Touch ID
> 4. The `onpaymentauthorized` event fires with encrypted payment data — your server converts it to hex and POSTs to the Payroc payments endpoint
>
> **Important:** Apple Pay only works on Apple devices (iPhone, iPad, Mac) and requires Safari or a WebKit-based browser. Always render the Apple Pay button conditionally using `ApplePaySession.canMakePayments()`.
>
> **Apple Pay vs Hosted Fields / HPP:** Apple Pay is a separate payment flow — it does not use the Hosted Fields JS library or the HPP form. It is a complement to those integrations, not a replacement.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
# Identity service (Bearer token — server-side only)
POST https://identity.uat.payroc.com/authorize
x-api-key: <api-key>

# Apple Pay JS API — provided by Safari / WebKit; there is no script tag to load

# Apple Pay session start (server-side — validate the merchant session with Apple)
POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/apple-pay-sessions
Authorization:  Bearer <token>
Content-Type:   application/json

# Payments API (server-side — process the hex-encoded Apple Pay token)
POST https://api.uat.payroc.com/v1/payments
Authorization:  Bearer <token>
Content-Type:   application/json

# Production base URLs (swap when going live — see Completion)
#   identity.payroc.com/authorize   |   api.payroc.com/v1/...
```

The exact values, enum sets, and request/response shapes are *not* in this block — read them from the
`references/` files as each step directs. This is an at-a-glance map of the endpoints, not a substitute for
the references.

---

## References

All enum values, schemas, and the Apple Pay JS API surface live in the local `references/` files below —
this skill emits from them, not from live lookups and not from memory. Each owns a different kind of
question; using the wrong source for a question is a known failure mode:

- **`references/api-schema.md` — source of truth for values and shapes that cross the wire to the Payroc API.** Field names, enum values, required fields, request and response schemas (the start-session and payments requests). Whenever you need to know *what a Payroc API field is called* or *what values it accepts*, read this file. It is the authoritative copy for this skill.
- **Payroc narrative guides (local copies) — source of truth for approach.** How to sequence the calls, how the Apple Pay flow composes with the Payroc session-start and payments endpoints, what the end-to-end shape looks like. Use them to learn *how to compose* the integration.
- **Apple derived notes (local, under `references/third-party/`) — source of truth for the Apple Pay JS API.** The `ApplePaySession` constructor, event names (`onvalidatemerchant`, `onpaymentauthorized`, `oncancel`), methods (`canMakePayments`, `completeMerchantValidation`, `completePayment`), status constants, and the Apple Pay payment-token format are all owned by Apple — not Payroc. These notes capture the factual API surface in our own words. The Payroc narrative guides describe how these *interact* with Payroc's endpoints but are not authoritative on Apple's shape itself.

If your question is "how do I structure the Payroc session-start or payments request?" — that's `references/api-schema.md`. If your question is "what order do I call things in?" — that's the Payroc narrative copy. If your question is "what is the constructor signature of `ApplePaySession`?" or "what event fires when the customer authorises?" — that's the Apple derived notes. Payroc owns its decryption endpoint and the wrapper around Apple's payment token; Apple owns everything in the browser-side payment sheet.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | **All** Payroc enum values, required fields, request/response schemas (start-session + payments) |
| Set up Apple Pay for a merchant (Payroc narrative) | `references/set-up-apple-pay-for-a-merchant.md` | Domain verification / Self-Care Portal setup, obtaining the domain ID |
| Add Apple Pay to your integration (Payroc narrative) | `references/add-apple-pay-to-your-integration.md` | Bearer token, session-start call, run-a-sale composition |
| Apple — `ApplePaySession` (derived notes) | `references/third-party/apple-applepaysession.md` | JS API constructor, event/method names, status constants |
| Apple — Apple Pay button (derived notes) | `references/third-party/apple-pay-button.md` | How to render the button (CSS vs web-component + SDK script) and gate it correctly |
| Apple — payment-token format (derived notes) | `references/third-party/apple-payment-token.md` | Token JSON field names you hex-encode for Payroc |
| Apple — server / merchant-validation setup (derived notes) | `references/third-party/apple-server-setup.md` | Merchant-validation flow facts, domain-association file |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core Principles

1. **Inspect before asking** — read the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through questions before writing implementation code.
3. **Validate before advancing** — don't move to the next step until the developer confirms the current step's checkpoint passes in UAT.
4. **Read the references, don't guess — and pick the right reference for the question.** There are *three* sources for this integration, not two. Using the wrong one for a question is how memorised-but-wrong values leak through.
   - **Payroc API schemas, field names, enums, required fields → `references/api-schema.md`.** Anything that crosses the wire to *Payroc's* API. Field values that accept specific strings (`channel`, `paymentMethod.type`, `paymentMethod.serviceProvider`, currency, and any other enum-style parameter) come from the schema reference, not from training data. Even a plausible-sounding string that isn't in the reference will cause API errors.
   - **Approach, sequencing, how Apple Pay composes with Payroc → the Payroc narrative copies.** "Which call comes first?" and "what does Payroc expect in the session-start body?" are guide questions.
   - **Apple Pay JS API shape, event names, method names → the Apple derived notes under `references/third-party/`.** `ApplePaySession`, its constructor signature, the event handlers (`onvalidatemerchant`, `onpaymentauthorized`, `oncancel`), the methods (`canMakePayments`, `completeMerchantValidation`, `completePayment`), and the status constants are all owned by Apple. The Payroc narrative guides reference these but are not authoritative on their shape — read the Apple derived notes if you need to confirm anything about the JS API surface.
   - **Request and response schemas diverge — check both.** Don't assume the Payroc response mirrors the Payroc request; look each up separately in `references/api-schema.md`.
   - **Don't cross-contaminate.** `channel` lives on the Payroc payment request, not on the Apple Pay session object. Apple's payment-network constants (e.g. `"visa"`, `"masterCard"`) come from the Apple derived notes and live on the `ApplePaySession` request, not on the Payroc payments request. Read the right reference for each value.
5. **Read-then-emit, per value.** Before emitting any enum value (Payroc: `channel`, `paymentMethod.type`, `paymentMethod.serviceProvider`, currency; Apple: payment networks, merchant capabilities, status constants), any `ApplePaySession` constructor option, or any event/method name on the Apple Pay JS API, read it from the relevant local reference. Don't emit these from memory. Don't treat this skill's failure-pattern callouts (see Step 3, Step 5, error taxonomy) as authoritative — they exist so you recognise mistakes by symptom, not so you can skip reading the reference. A plausible-sounding English value is the most common form this failure takes.
6. **Never hardcode credentials** — API keys and terminal IDs must come from environment variables or a secrets manager, never source code.
7. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:

- Server-side language and framework
- Existing checkout or payment-related routes and handlers
- Any existing Payroc integration (HF or HPP) — the API key and terminal ID may already be present
- How environment variables or configuration is managed
- Whether the domain is already set up for Apple Pay (`.well-known` directory, existing Apple Pay JS code)

Use what you find to avoid asking for things you can already infer.

Then ask for what you still need. At minimum, confirm:

**Question 1 — Is Apple Pay the right product, and is this an addition or a standalone build?**

| | Apple Pay (this skill) | Hosted Fields | Hosted Pages (HPP) |
|---|---|---|---|
| Customer experience | Taps the Apple Pay button; authorises with Face ID / Touch ID — no card entry | Types card details into Payroc widgets embedded in your own form | Redirected to a Payroc-hosted page to pay, then returned to your site |
| Where the card data lives | Apple's wallet; your server receives an encrypted token | Payroc widgets inside your page | Payroc's hosted page |
| Availability | Apple devices on Safari / WebKit only — always gate on `canMakePayments()` | Any modern browser | Any modern browser |
| This skill | ✓ Covered here | Separate skill | Separate skill |

Apple Pay is a **complement** to a card-entry method, not a replacement — because it only works on Apple devices, most integrations offer it alongside Hosted Fields or HPP for everyone else. Once that's clear, confirm whether this is an addition or a standalone build:

- **Adding Apple Pay to an existing Payroc integration (HF or HPP)** → the API key and terminal ID are likely already configured; focus on the Apple Pay-specific steps
- **New integration, Apple Pay only** → start from the beginning including credential setup

**Question 2 — Domain setup status:**

Apple Pay requires the merchant's domain to be verified with Apple via the Payroc Self-Care Portal. Ask whether this has been done and whether the developer has a domain ID.

- **Domain already verified, domain ID available** → skip the merchant setup step
- **Not yet done** → start with Step 1 (merchant setup)

**Wait for the developer's answers before continuing.**

---

## Prerequisites

Before writing any code, confirm the developer has:

1. **API key** — used to obtain a Bearer token from Payroc's identity service. Same credential used for Hosted Fields; the Payroc Integrations team provisions it.
2. **Processing terminal ID** — a UAT terminal ID provisioned by the Payroc Integrations team.
3. **A publicly accessible HTTPS domain** — Apple Pay domain verification requires a URL that Apple's servers can reach. `localhost` is not sufficient for this step; a staging or production domain is required.

If anything is missing:
- API key / terminal ID / UAT access → contact the Payroc Integrations team

### Checkpoint

API key, terminal ID, and a publicly accessible domain confirmed? If not, stay here and help resolve what's missing before continuing.

---

## Step 1 — Set up Apple Pay for the merchant

Read: references/set-up-apple-pay-for-a-merchant.md

Read the page before doing anything. Confirm the exact steps from the reference — but at the time of writing they are:

1. Log in to the [Self-Care Portal](https://selfcare.payroc.com) for the UAT terminal
2. Navigate to Settings → Apple Pay Domains
3. Download the Apple Pay domain verification file
4. Place the file at `/.well-known/apple-developer-merchantid-domain-association` on the merchant's domain (must be publicly accessible over HTTPS)
5. In the portal, add the domain and save
6. Note the **domain ID** displayed — store it securely; it is needed in every Apple Pay session request

> **The domain verification file must be accessible before adding the domain in the portal.** Apple verifies it during the domain registration step.

### Checkpoint

Is the domain ID shown in the Self-Care Portal after saving? Can the verification file be fetched at the `/.well-known/` path over HTTPS?

---

## Step 2 — Authenticate: get a Bearer token

Read: references/add-apple-pay-to-your-integration.md

Read the authentication section before writing anything. From the reference, confirm:

- The identity service endpoint
- The required header and its format
- The response field containing the access token

Implement a server-side function that POSTs to the identity service with the API key and returns the access token. This must run server-side — the API key must never be sent to the browser.

### Checkpoint

Does the call return a 200 with an `access_token`?

---

## Step 3 — Implement the Apple Pay button and payment sheet

Read *two* references before writing anything:

- **Payroc narrative (composition):** `references/add-apple-pay-to-your-integration.md` — the client-side section. This is where you'll learn what Payroc expects between the JS events and your server.
- **Apple's JS API surface (shape):** `references/third-party/apple-applepaysession.md` — the derived notes for the `ApplePaySession` constructor, every event name, every method name, every status constant. The Payroc narrative references these by name but is not authoritative on their exact spelling, signature, or set.
- **Apple Pay button rendering (shape):** `references/third-party/apple-pay-button.md` — how to actually *draw* the button. There are two approaches and they are not interchangeable: the CSS `-webkit-appearance: -apple-pay-button` approach (no script) and the `<apple-pay-button>` web component (which **requires** loading Apple's `apple-pay-sdk.js` script, or it renders nothing). This note also covers the gating pitfall below. `apple-applepaysession.md` does **not** cover button rendering — read this file for it.

### Before emitting `new ApplePaySession(...)` or any `session.*` call — confirm against the Apple derived notes

1. **What to read.** The Apple `ApplePaySession` derived notes (`references/third-party/apple-applepaysession.md`). Also confirm the constructor's required `paymentRequest` shape from there, not from training data.
2. **What to verify.**
   - The constructor signature (`new ApplePaySession(version, paymentRequest)`) and what `version` value is currently appropriate.
   - Event handlers actually fired by the session (`onvalidatemerchant`, `onpaymentauthorized`, `oncancel`, etc.) — and the exact payload shape of each event.
   - Methods exposed on the session (`completeMerchantValidation`, `completePayment`, `abort`, etc.).
   - Status constants (`STATUS_SUCCESS`, `STATUS_FAILURE`, and any others you'll branch on).
3. **Only then emit.** Wire each event handler against the exact name the Apple derived notes document. Call each method only against the documented surface. If a method you assumed exists isn't in the derived notes, do not invent a different name and try again — Apple may have moved that responsibility elsewhere (e.g. into a payment request property).

Implement the client-side integration:

1. **Check availability and render the button** — wrap everything in `ApplePaySession.canMakePayments()`. Render the Apple Pay button only when this returns `true`; otherwise show an alternative payment method. **Read `references/third-party/apple-pay-button.md` for how to render the button** — pick one approach and emit it completely: either the CSS `-webkit-appearance: -apple-pay-button` button (nothing to load) **or** the `<apple-pay-button>` web component **with** its required `apple-pay-sdk.js` script tag (without the script the web component renders nothing). **Gate so the hide actually takes effect:** the HTML `hidden` attribute is silently overridden if your own CSS sets `display` on the button (author CSS beats the user-agent `[hidden]` rule), so toggle visibility in JS via `style.display`/a class — or keep `display` out of the button's base CSS — and verify the button is genuinely hidden when `ApplePaySession` is absent. Don't assume `hidden` wins over your stylesheet.
2. **Create an `ApplePaySession`** with the required `paymentRequest` object (merchant name, supported networks, merchant capabilities, country code, currency code, total) — **read the exact property names from the Apple derived notes, including the supported-network constant spelling** (e.g. `"visa"` vs `"Visa"` — the derived notes are authoritative for this skill).
3. **Handle the merchant-validation event** — this fires when the payment sheet opens. Your client must call your server (e.g. `POST /checkout/apple-pay/session`), passing the validation URL from the event. Your server calls the Payroc API to start the session (Step 4) and returns the session response. Your client passes the response to Apple's documented completion method (read its exact name and signature from the Apple derived notes).
4. **Handle the payment-authorisation event** — fires when the customer authorises with Face ID / Touch ID. The event contains the encrypted payment data. Your client sends this to your server (Step 5) for processing, then calls the documented payment-completion method with the documented success/failure status constant.
5. **Call the session's start method** to present the payment sheet (read its exact name from the Apple derived notes).

### Known Apple Pay JS shape failure patterns

Listed so you can recognise the symptom — the fix is always **read the Apple derived notes (`references/third-party/apple-applepaysession.md`) and emit what they document**, not "use the value below."

- **Symptom:** the assumed handler name never fires; the payment sheet opens but the merchant-validation step is silently skipped. **Past wrong:** inventing a method-style call like `session.validateMerchant()` when the actual API is event-based (an `on*` handler set on the session). **Verify:** the derived notes enumerate the events; set handlers as properties on the session per the documented event names.
- **Symptom:** `completePayment` accepts the call but the sheet doesn't dismiss correctly, or the status constant is rejected. **Past wrong:** invented status constants (e.g. `STATUS_OK`) or wrong argument shape. **Verify:** the derived notes list the status constants exported on the `ApplePaySession` class — use those exact names.
- **Symptom:** browser-side `TypeError` on the session constructor or button rendering. **Past wrong:** wrong constructor argument count, or calling a method that doesn't exist on the class. **Verify:** the derived notes document the constructor signature and the full method surface.
- **Symptom:** the Apple Pay button never appears (zero height / no glyph) even in Safari with a card available. **Past wrong:** emitting the `<apple-pay-button>` web component without loading Apple's `apple-pay-sdk.js` script, so the custom element never registers. **Verify:** `references/third-party/apple-pay-button.md` — either load the SDK script for the web component, or use the CSS `-webkit-appearance: -apple-pay-button` approach instead.
- **Symptom:** the Apple Pay button shows on non-Apple browsers (where it should be hidden), even though the gate sets the `hidden` attribute. **Past wrong:** an author CSS rule setting `display` on the button overrides the user-agent `[hidden] { display: none }` rule, defeating the gate. **Verify:** `references/third-party/apple-pay-button.md` — gate by toggling `style.display`/a class in JS rather than relying on the `hidden` attribute alone, and confirm the button is actually hidden when `ApplePaySession` is absent.

### Checkpoint

Does the Apple Pay payment sheet appear when the button is tapped on an Apple device or simulator? Does the merchant-validation event fire?

---

## Step 4 — Start the Apple Pay session

Read: references/add-apple-pay-to-your-integration.md (same page — the session-start API call) and `references/api-schema.md` (the `applePaySessions` request/response schemas)

> **Do not use any endpoint URL, field name, or response shape from your training knowledge. Read the session-start endpoint, required body fields, and response structure from `references/api-schema.md` and the narrative copy above.**

When `onvalidatemerchant` fires, your server must call the Payroc API to validate the session with Apple. From the references, confirm:

- The session-start endpoint URL (test vs production)
- The required request body fields: `appleDomainId` (the domain ID from Step 1) and `appleValidationUrl` (the `validationURL` from the event)
- The response object to pass back to `completeMerchantValidation`

Implement a server-side endpoint that:
1. Receives the `validationURL` from the client
2. Generates (or reuses) a valid Bearer token
3. POSTs to the Payroc session-start endpoint with `appleDomainId` and `appleValidationUrl`
4. Returns the response body to the client

### Checkpoint

Does `completeMerchantValidation` succeed (no error thrown)? Does the payment sheet remain open and progress to showing the payment card?

---

## Step 5 — Process the payment

This step crosses **two sources** — Apple owns the format of the encrypted token coming out of the event; Payroc owns the wrapping shape and enum values you'll POST to `/v1/payments`. Read both references:

- **Apple Pay payment-token format (Apple derived notes):** `references/third-party/apple-payment-token.md` — what the `payment.token.paymentData` payload looks like coming out of the authorisation event. These notes capture the JSON structure of the token; you'll be encoding that JSON to hex before sending to Payroc.
- **Payroc narrative + schema:** `references/add-apple-pay-to-your-integration.md` for the composition, and `references/api-schema.md` (`paymentRequest`, `paymentMethod` digitalWallet variant) for the exact field names and enum values.

> **Do not use any field names, endpoint URLs, or encrypted data format from your training knowledge.** Two separate transforms, two separate sources: Apple's token format is in `references/third-party/apple-payment-token.md`, and the Payroc payment-request shape is in `references/api-schema.md`. Read both before emitting code.

When the payment-authorisation event fires, the event contains the encrypted payment data from Apple. Your server must:

1. Extract the encrypted payment data from the event (the shape comes from the Apple payment-token derived notes, not from training data).
2. Convert it to hexadecimal format (as required by the Payroc API — read the exact requirement from the Payroc narrative copy; if it's not explicit, check `references/api-schema.md` for the `encryptedData` field's documented constraints).
3. POST to the Payroc payments endpoint. The structure to send (read from `references/api-schema.md`) is typically along the lines of:
   - `paymentMethod.type` — read the current enum value for a digital wallet from `references/api-schema.md` (`paymentMethod.type` enum); do not assume `"digitalWallet"` from memory.
   - `paymentMethod.serviceProvider` — read the current enum value for Apple Pay from `references/api-schema.md`; do not assume `"apple"` from memory.
   - `paymentMethod.encryptedData` — the hex-encoded token from step 2.
   - Plus the standard `channel`, `processingTerminalId`, `order` fields (all read-then-emitted; see the enum callout below).
   - `order.orderId` — a unique identifier you generate per payment, **constrained to 1–24 characters** (read the constraint from `references/api-schema.md`). See the orderId callout below.
4. On HTTP 201 — call the documented payment-completion method with the documented success status constant on the client (read from the Apple derived notes).
5. On any error — call the same method with the documented failure status constant so the payment sheet dismisses cleanly.

> **Read the Payroc `channel` enum from `references/api-schema.md`.** `channel` is on the Payroc payment request, not on the Apple Pay session. **Known past failure (from sibling integrations):** a model emitted `channel: "internet"` because the value sounds reasonable for an in-browser checkout — Payroc returned HTTP 400 with the enum list in the error detail. The fix isn't to memorise the right value here; it's to read `channel` from the schema reference as you construct the body. Plausible-sounding cousins (`internet`, `online`, `ecommerce`, `card-not-present`) are the most common form this failure takes.

> **Determine payment success from `responseCode`, not from a guessed `transactionResult.status` subset.** Read `references/api-schema.md`. The approval signal is **`responseCode === 'A'`** (a successful response also carries an `approvalCode` and an `OK` `responseMessage`). `transactionResult.status` is the *lifecycle* state: under an `A`, both `ready` (queued/captured) and `pending` (authorized, awaiting capture — e.g. a pre-auth or `autoCapture: false`) are successful authorizations; `declined` / `expired` etc. are not, and `approved` is **not** a member of the enum. **Known past failure (from sibling integrations and benchmarking):** a model built an approval-`status` list (or branched only on `"approved"`) and silently treated real authorizations as failures. Don't enumerate a status set from memory — key the success branch on `responseCode === 'A'` and use `status` for lifecycle. Handle `E` (deferred) and `P` (partial approval) deliberately; treat `D` / `R` / `C` as declines.

> **Keep `order.orderId` within 1–24 characters.** Read the constraint from `references/api-schema.md` (`order.orderId` length 1–24). **Known past failure:** a model generated `order-${uuidv4()}` (42 chars) or a raw `crypto.randomUUID()` (36 chars), and Payroc rejected every payment with HTTP 400 `"orderId size must be between 1 and 24"` — the success branch was then never reachable. A raw UUID/GUID does **not** fit. Use a scheme that always fits: a short hex id (e.g. `crypto.randomBytes(8).toString('hex')` → 16 chars), a base36 timestamp plus a few random chars, or the merchant's own short order number. This is easy to get wrong in a full integration where `orderId` is just one field among many — emit a compliant scheme deliberately.

### Checkpoint

Does the payments API return HTTP 201 in UAT? Does the Apple Pay payment sheet show a success confirmation?

---

## Local testing strategy

Apple Pay has two reachability constraints that `localhost` does not satisfy — both already covered above,
collected here so they're easy to find:

- **A real Apple device or simulator** with a card in Wallet, on Safari / WebKit, is required to render the
  button and present the sheet (`canMakePayments()` returns false otherwise — see the error taxonomy).
- **A publicly accessible HTTPS domain** is required for domain verification (Prerequisites and Step 1):
  Apple's servers fetch the `/.well-known/apple-developer-merchantid-domain-association` file directly, so
  `localhost` cannot be verified. Use a staging domain, or a tunnel (ngrok, VS Dev Tunnels, Cloudflare
  Tunnel) that serves the verification file over HTTPS, and register that domain in the Self-Care Portal.

There is no inbound webhook in this flow — the only public-reachability need is the domain-association file.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Apple Pay button never renders | `canMakePayments()` returns false | Test on an Apple device or simulator with a card added to Wallet; Safari on macOS also works if a paired iPhone has Apple Pay enabled |
| Apple Pay button renders as nothing (zero height / no glyph) even on Apple device with a card | `<apple-pay-button>` web component used without loading Apple's `apple-pay-sdk.js` script, so the custom element never registers | Read `references/third-party/apple-pay-button.md`; either add the `apple-pay-sdk.js` script tag, or switch to the CSS `-webkit-appearance: -apple-pay-button` approach |
| Apple Pay button is visible on a non-Apple browser (where it should be hidden) | An author CSS rule sets `display` on the button, overriding the user-agent `[hidden] { display: none }` rule, so the `hidden` gate is defeated | Read `references/third-party/apple-pay-button.md`; gate by toggling `style.display`/a class in JS, or keep `display` out of the button's base CSS; confirm it's actually hidden when `ApplePaySession` is absent |
| Payments API 400 `"orderId size must be between 1 and 24"` | `order.orderId` exceeds 24 characters — typically a raw `uuidv4()`/`crypto.randomUUID()` (36 chars) or a prefixed UUID | Read the `order.orderId` 1–24 constraint from `references/api-schema.md`; use a scheme that always fits (short hex, base36 timestamp + short random, or a short merchant order number) |
| `onvalidatemerchant` fires but `completeMerchantValidation` throws | Session-start API call failed or response is not the raw Apple session object | Log the full Payroc response; confirm the response body (not a wrapped object) is passed directly to `completeMerchantValidation` |
| Session-start returns 404 | Wrong endpoint URL or incorrect `processingTerminalId` in path | Re-read the endpoint URL from `references/api-schema.md`; confirm the terminal ID is the UAT terminal |
| Session-start returns 400 | `appleDomainId` or `appleValidationUrl` missing or invalid | Confirm the domain ID from the Self-Care Portal; confirm `validationURL` is passed through from the event verbatim without modification |
| Domain verification fails in Self-Care Portal | Verification file not accessible over HTTPS | Confirm the file is at exactly `/.well-known/apple-developer-merchantid-domain-association` with no extension; test with `curl` before adding the domain |
| Payment API 401 | Bearer token expired or wrong API key | Re-fetch Bearer token; verify the `x-api-key` value |
| Payment API 400 | `encryptedData` not in hex format, or missing required fields | Re-read the encryptedData format requirement; check that the conversion from Apple's payment data to hex is correct |
| Payment sheet shows failure after `STATUS_SUCCESS` | Payment API returned non-201 but was incorrectly treated as success | Branch strictly on HTTP 201 for success; treat all other statuses as failure |
| Payments API returns HTTP 400 naming `"channel"` (or another enum-typed field) in the error detail, with a list of accepted values | A non-enum value was emitted (past failures from sibling integrations: `channel: "internet"`, `"online"`, `"ecommerce"`); a plausible-sounding cousin substituted for the documented value | Read `channel` (or the relevant field) from `references/api-schema.md` and emit one of the listed values. Do not infer enum values from English plausibility. |
| `paymentMethod.type` or `paymentMethod.serviceProvider` rejected by the Payroc API | The skill emitted a `digitalWallet` / `apple` value remembered from training data rather than read from `references/api-schema.md` | Read the current `paymentMethod.type` and `paymentMethod.serviceProvider` enums from `references/api-schema.md` and emit the values listed there. Even if the remembered values *happen* to be right, the discipline failure (not reading the reference) is itself the bug. |
| Apple Pay session constructor throws `TypeError`, or an `on<event>` handler is never invoked | Constructor signature or event name was taken from training data rather than the Apple derived notes; an assumed name doesn't match the documented surface | Read the Apple `ApplePaySession` derived notes (`references/third-party/apple-applepaysession.md`). Confirm the constructor signature, every event name you'll wire, and every method you'll call. Do not invent or rename — if your assumed name isn't in the derived notes, Apple has moved that responsibility elsewhere. |
| App logged a payment failure but the bank actually approved — Payroc response shows `responseCode: "A"` with an `approvalCode` / `OK` message | Success check branched on a guessed `transactionResult.status` subset (past failures: only `"approved"` accepted — not even a member of the enum; or an approval list that omitted an authorized state such as `pending`) | Key the success branch on `responseCode === 'A'` per `references/api-schema.md`; treat `ready` and `pending` as authorized and `status` as lifecycle only. Don't enumerate an approval-status set from memory. |

---

## Validation checklist

- [ ] API key and terminal ID sourced from environment variables — not in source code
- [ ] Bearer token generated server-side — not exposed to the browser
- [ ] Apple Pay button only rendered when `ApplePaySession.canMakePayments()` returns `true` — and verified actually hidden when Apple Pay is unavailable (gate not defeated by author CSS overriding the `hidden` attribute)
- [ ] Apple Pay button drawn via a documented approach: CSS `-webkit-appearance: -apple-pay-button`, **or** `<apple-pay-button>` **with** its `apple-pay-sdk.js` script tag loaded
- [ ] `order.orderId` generated within 1–24 characters — not a raw UUID/GUID
- [ ] Domain verification file accessible at `/.well-known/apple-developer-merchantid-domain-association` over HTTPS
- [ ] Domain ID stored securely (env var or config) — not hardcoded
- [ ] `onvalidatemerchant`: `validationURL` passed verbatim from event to server; server response passed verbatim to `completeMerchantValidation`
- [ ] `onpaymentauthorized`: encrypted data converted to hex format before sending to Payroc API
- [ ] Payment API returns HTTP 201 in UAT with a test Apple Pay transaction
- [ ] `session.completePayment()` called with the correct status after payment API response

---

## Anti-patterns

**Rendering the Apple Pay button unconditionally** — it will silently fail on non-Apple devices or non-Safari browsers. Always gate on `canMakePayments()`.

**Gating with the `hidden` attribute while your CSS forces `display` on the button** — author CSS (e.g. `.apple-pay-button { display: block }`) overrides the user-agent `[hidden] { display: none }` rule, so the button shows even when the gate set `hidden`. Toggle `style.display`/a class in JS instead, and verify the button is actually hidden when `ApplePaySession` is absent. See `references/third-party/apple-pay-button.md`.

**Emitting the `<apple-pay-button>` web component without its SDK script** — the custom element only registers when `https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js` is loaded; without it the button renders nothing. Either load the script or use the CSS `-webkit-appearance: -apple-pay-button` approach. See `references/third-party/apple-pay-button.md`.

**Using a raw UUID for `order.orderId`** — `uuidv4()`/`crypto.randomUUID()` (36 chars) and prefixed variants exceed the 1–24 character limit and Payroc rejects the payment with HTTP 400. Use a scheme that always fits.

**Modifying the `validationURL`** — pass it through from the Apple event verbatim. Any modification (encoding, trimming) will cause merchant validation to fail.

**Wrapping the session-start response** — Apple's `completeMerchantValidation` expects the raw session object returned by the Payroc API. Do not wrap it in another object or JSON-encode it again.

**Calling `completePayment(STATUS_SUCCESS)` before the payment API responds** — always wait for the Payroc API response before calling `completePayment`. Calling it early leaves the session in an undefined state.

**Hardcoding the domain ID** — domain IDs differ between UAT and production portals; source them from environment variables.

---

## Completion

Once HTTP 201 is confirmed and all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Domain verification** — your domain is registered with Apple via the Self-Care Portal; the domain ID authorises session requests.
> - **Merchant validation** — when the Apple Pay sheet opens, your server calls Payroc to validate the session with Apple; the customer sees a trusted payment experience.
> - **Payment processing** — the customer authorises with Face ID / Touch ID; your server converts the encrypted payment data to hex and posts it to the Payroc payments endpoint.
> - **Validated in UAT** — end-to-end Apple Pay transaction confirmed.
>
> **Before going live:** swap UAT endpoint URLs for production URLs in both the session-start call and the payments API call. Register the production domain in the production Self-Care Portal and obtain its domain ID.

Offer next steps:

- **Google Pay** — add Google Pay as a parallel digital wallet option; similar flow but uses the Google Pay JS API and a different `serviceProvider` value
- **Hosted Fields** — if the developer also needs a card entry form fallback for non-Apple users, that's the Hosted Fields skill

---
name: integrate-google-pay
description: >-
  Guide an ISV developer or merchant through integrating Google Pay with Payroc's
  payments API from merchant setup through a first successful UAT test transaction.
  Use this skill whenever someone asks about adding Google Pay to their Payroc
  integration, implementing Google Pay on their checkout page, processing digital
  wallet payments via Google Pay, or getting Google Pay working with the Payroc
  gateway — even if they don't explicitly mention "integration" or ask for
  step-by-step guidance.
metadata:
  version: "0.3.0"
  category: integration
  status: draft
---

# Payroc Google Pay Integration

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/integrate-google-pay/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Google Pay Integration**
> I'll guide you from merchant setup through a successful UAT test transaction.
> This covers Google Pay as a payment method on your checkout page — using the Google Pay JS API to present the payment sheet and the Payroc Payments API to process the encrypted payment data.
>
> **How Google Pay works with Payroc (four parts):**
> 1. You configure the Google Pay JS API with Payroc's gateway details (gateway name and gateway merchant ID)
> 2. When a customer taps the Google Pay button, Google presents the payment sheet
> 3. The customer selects a card and confirms; Google returns encrypted payment data
> 4. Your server converts the encrypted data to hex and POSTs to the Payroc payments endpoint
>
> **Important gateway detail (read from the local narrative copy before emitting):** Payroc processes Google Pay through the Worldnet gateway (which Payroc acquired). The narrative copy at `references/google-pay.md` documents the specific values for the Google Pay `tokenizationSpecification.parameters` — `gateway` (a fixed constant) and `gatewayMerchantId` (derived from your processing terminal ID). Read `references/google-pay.md` before emitting either, and use exactly what it documents — don't emit these from memory.
>
> **Google Pay vs Hosted Fields / HPP:** Google Pay is a separate payment flow — it does not use the Hosted Fields JS library or the HPP form. It is a complement to those integrations, not a replacement.
>
> **Registration required for production:** Google Pay requires you to register your integration with Google before going live. UAT testing works without registration.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
# Identity service (Bearer token — server-side only)
POST https://identity.uat.payroc.com/authorize
x-api-key: <api-key>

# Google Pay JS library (client-side — load in the browser)
https://pay.google.com/gp/p/js/pay.js

# Payments API (server-side — process the hex-encoded Google Pay token)
POST https://api.uat.payroc.com/v1/payments
Authorization:  Bearer <token>
Content-Type:   application/json

# Production base URLs (swap when going live — see Step 4 and Completion)
#   identity.payroc.com/authorize   |   api.payroc.com/v1/payments
```

The exact values, enum sets, and Payroc-specific gateway constants are *not* in this block — read them
from the `references/` files as each step directs. This is an at-a-glance map of the endpoints, not a
substitute for the references.

---

## References

All enum values, schemas, and Payroc-specific values live in the local `references/` files below — this skill emits from them, not from live lookups and not from memory. Three complementary sources, each owning a different kind of question — using the wrong source for a question is a known failure mode:

- **Payroc API schema** (`references/api-schema.md`) — **source of truth for everything that crosses the wire to the Payroc API**: field names, enum values (`channel`, `paymentMethod.type`, `paymentMethod.serviceProvider`, `transactionResult.status`, etc.), required fields, request/response shapes. Curated slice of the Payroc OpenAPI spec.
- **Payroc narrative copy** (`references/google-pay.md`) — **source of truth for composition and Payroc-specific gateway values**: how to wire the Google Pay JS to Payroc, what to put in `tokenizationSpecification.parameters` (the `gateway` constant and the `gatewayMerchantId` derivation), the hex-encoding requirement.
- **Google API surface notes** (`references/third-party/google-request-objects.md` and `references/third-party/google-client.md`) — **source of truth for the Google Pay JS API shape**: `PaymentDataRequest`, `tokenizationSpecification`, supported networks/auth methods, `PaymentsClient` methods (`isReadyToPay`, `loadPaymentData`, `createButton`), `paymentData` callback shape. These are our own-words derived notes on Google's documented API surface — read them whenever you need to confirm a property name, an accepted child key, or a method name on `PaymentsClient`.

If your question is "what does the Payroc payment request body look like?" — that's `references/api-schema.md`. If your question is "what should `gateway` be, and how do I derive `gatewayMerchantId`?" — that's `references/google-pay.md`. If your question is "what is the exact shape of `PaymentDataRequest` and where does `tokenizationSpecification` go inside it?" — that's the Google notes under `references/third-party/`. Payroc owns the values *inside* `tokenizationSpecification.parameters`; Google owns the surrounding container.

| Source | Local file | Use for |
| --- | --- | --- |
| Payroc API schema | `references/api-schema.md` | Payroc API field names, enum values, request/response shapes |
| Add Google Pay to your integration (Payroc narrative) | `references/google-pay.md` | Composition with Payroc + canonical `gateway` value + `gatewayMerchantId` derivation |
| Google — request objects | `references/third-party/google-request-objects.md` | `PaymentDataRequest`, `tokenizationSpecification`, supported networks, JS object shape |
| Google — client | `references/third-party/google-client.md` | `PaymentsClient` constructor, `isReadyToPay`, `loadPaymentData`, `createButton`, callback shapes |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core Principles

1. **Inspect before asking** — read the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through questions before writing implementation code.
3. **Validate before advancing** — don't move to the next step until the developer confirms the current step's checkpoint passes in UAT.
4. **Read the references, don't guess — and pick the right reference for the question.** There are *three* sources for this integration, not two. Using the wrong one for a question is how memorised-but-wrong values leak through.
   - **Payroc API schemas, field names, enums, required fields → `references/api-schema.md`.** Anything that crosses the wire to *Payroc's* API. Field values that accept specific strings (`channel`, `paymentMethod.type`, `paymentMethod.serviceProvider`, currency, country, and any other enum-style parameter) come from the schema reference, not from training data. Even a plausible-sounding string that isn't in the reference will cause API errors.
   - **Composition, Payroc-specific gateway values (`gateway`, `gatewayMerchantId` derivation), hex-encoding requirement → `references/google-pay.md`.** "What `gateway` constant does Payroc want?" and "how do I derive `gatewayMerchantId`?" are narrative-copy questions, not schema or Google questions.
   - **Google Pay JS API shape, `PaymentDataRequest`, `tokenizationSpecification`, supported networks, `PaymentsClient` methods → the Google notes under `references/third-party/`.** The Payroc narrative references these by name but is not authoritative on Google's exact property paths, child-key spelling, or method signatures. Read the Google notes if you need to verify anything about the JS API surface.
   - **Don't cross-contaminate sources.** `channel` lives on the Payroc payment request (its enum is in `references/api-schema.md`), not on the Google Pay request. Google's supported-network constants (e.g. `"VISA"`, `"MASTERCARD"`) come from the Google notes and live on `PaymentDataRequest`, not on the Payroc payments request. Read the right reference for each value.
5. **Read-then-emit, per value.** Before emitting any enum value (Payroc: `channel`, `paymentMethod.type`, `paymentMethod.serviceProvider`, currency, country, `transactionResult.status`; Google: payment networks, auth methods, environment), any `PaymentDataRequest` property path, any `PaymentsClient.*` method call, or the Payroc `gateway` constant and `gatewayMerchantId` derivation, read the relevant local reference. The Payroc narrative copy (`references/google-pay.md`) holds the `gateway` constant and `gatewayMerchantId` derivation; `references/api-schema.md` holds the Payroc REST enums; the Google notes hold the JS API surface. Don't emit any of these from memory — read them from the reference that owns them.
6. **Never hardcode credentials** — API keys and terminal IDs must come from environment variables or a secrets manager, never source code.
7. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:

- Server-side language and framework
- Existing checkout or payment-related routes and handlers
- Any existing Payroc integration (HF or HPP) — the API key and terminal ID may already be present
- How environment variables or configuration is managed
- Whether any Google Pay JS or Google Pay merchant ID is already configured

Use what you find to avoid asking for things you can already infer.

Then ask for what you still need. At minimum, confirm:

**Question 1 — Is Google Pay the right product, and is this an addition or a standalone build?**

| | Google Pay (this skill) | Hosted Fields | Hosted Pages (HPP) |
|---|---|---|---|
| Customer experience | Taps the Google Pay button; pays with a saved Google wallet card — no card entry | Types card details into Payroc widgets embedded in your own form | Redirected to a Payroc-hosted page to pay, then returned to your site |
| Where the card data lives | Google's wallet; your server receives an encrypted token | Payroc widgets inside your page | Payroc's hosted page |
| Compatibility | Any modern browser — Chrome, Edge, Firefox, and Chrome on iOS; **not** Safari (Safari uses Apple Pay instead) | All modern browsers | All modern browsers |
| This skill | ✓ Covered here | Separate skill | Separate skill |

Google Pay is a **complement** to a card-entry method, not a replacement — most integrations offer it alongside Hosted Fields or HPP. It is **not limited to Android**: iOS users on Chrome can use Google Pay just like Android users. The browser, not the device, is what matters — Safari (on any device) does not support Google Pay. Once that's clear, confirm whether this is an addition or a standalone build:

- **Adding Google Pay to an existing Payroc integration (HF or HPP)** → the API key and terminal ID are likely already configured; focus on the Google Pay-specific steps
- **New integration, Google Pay only** → start from the beginning including credential setup

**Question 2 — Google Merchant ID:**

Google Pay for production requires a Google Merchant ID (assigned by Google when you register your integration). For UAT testing you can use a test merchant ID.

- **Google Merchant ID available** → note it; it's used in the Google Pay JS configuration
- **Not yet registered with Google** → UAT testing can proceed with a test ID; registration is required before going live

**Wait for the developer's answers before continuing.**

---

## Prerequisites

Before writing any code, confirm the developer has:

1. **API key** — used to obtain a Bearer token from Payroc's identity service. Same credential used for Hosted Fields; the Payroc Integrations team provisions it.
2. **Processing terminal ID** — a UAT terminal ID provisioned by the Payroc Integrations team. Also used to derive the `gatewayMerchantId` (terminal ID minus the last three characters).
3. **Google Merchant ID** — for UAT, a test value can be used. For production, obtained by registering with Google.

If anything is missing:
- API key / terminal ID / UAT access → contact the Payroc Integrations team
- Google Merchant ID for production → register your integration at the Google Pay Business Console

### Checkpoint

API key and terminal ID confirmed? If not, stay here and help resolve what's missing before continuing.

---

## Step 1 — Authenticate: get a Bearer token

Read: references/google-pay.md

Read the authentication section before writing anything. From the narrative copy, confirm:

- The identity service endpoint
- The required header and its format
- The response field containing the access token

Implement a server-side function that POSTs to the identity service with the API key and returns the access token. This must run server-side — the API key must never be sent to the browser.

### Checkpoint

Does the call return a 200 with an `access_token`?

---

## Step 2 — Configure and load the Google Pay JS

This step crosses **two sources** — Google owns the `PaymentDataRequest` shape and the `PaymentsClient` API; Payroc owns the values that go inside `tokenizationSpecification.parameters`. Read both before writing anything:

- **Read: references/third-party/google-request-objects.md** — for the exact property paths (`allowedPaymentMethods`, `tokenizationSpecification`, `merchantInfo`, `transactionInfo`), the supported-network constant spelling, and the auth-method constants.
- **Read: references/third-party/google-client.md** — for `PaymentsClient`, `isReadyToPay`, `loadPaymentData`, `createButton` and their argument/return shapes.
- **Read: references/google-pay.md** — for the `gateway` constant, the `gatewayMerchantId` derivation, and any other Payroc-specific values that go inside `tokenizationSpecification.parameters`.

### Before emitting any `PaymentDataRequest` or `PaymentsClient.*` call — check the Google notes

1. **What to read.** Both Google notes above (request-objects + client). Don't paraphrase the API from training data.
2. **What to confirm.**
   - The exact property hierarchy of `PaymentDataRequest` and where `tokenizationSpecification` sits inside it.
   - The supported-network constants (Google uses `"VISA"` / `"MASTERCARD"` — confirm the casing).
   - `PaymentsClient` constructor argument shape, `isReadyToPay` argument shape, `loadPaymentData` return shape.
3. **Only then emit.** Place every property in `PaymentDataRequest` at the path the Google notes document. Wire each `PaymentsClient.*` call against the documented surface. If a method or property you assumed exists isn't in the Google notes, do not invent a different name and try again — re-derive from the source (see `references/_sources.md`) rather than guessing.

### Before emitting `gateway` and `gatewayMerchantId` — check the Payroc narrative copy

These are *Payroc-specific* values, not Google values — they live inside `tokenizationSpecification.parameters`. `references/google-pay.md` is the authoritative source.

1. **What to read.** `references/google-pay.md` — the section that documents `tokenizationSpecification` configuration (Step 1 of the narrative, "Integrate with the Google Pay API").
2. **What to confirm.**
   - The exact `gateway` constant the narrative documents.
   - The exact `gatewayMerchantId` derivation rule. If the copy doesn't spell out the derivation explicitly, escalate rather than guess.
3. **Only then emit.** Use exactly what the narrative copy documents — don't substitute a remembered value.

Implement the client-side integration (only after reading the references above):

1. Load the Google Pay JS library: `https://pay.google.com/gp/p/js/pay.js`
2. Create a `PaymentsClient` with the appropriate environment (`TEST` for UAT, `PRODUCTION` for live) — confirm the environment constant against the Google client notes.
3. Call the readiness-check method (`isReadyToPay` per the Google client notes) with the supported payment methods before rendering the button.
4. Render the Google Pay button using `createButton` (per the Google client notes) — only when the readiness check returns `true`.
5. On button click, call `loadPaymentData` with the full `PaymentDataRequest`.
6. On success, send the `paymentData` to your server (Step 3).

### Known Google Pay JS shape failure patterns

Listed so you can recognise the symptom — the fix is always **read the relevant local reference and emit what it documents**, not "use the value below."

- **Symptom:** `loadPaymentData` rejects with `OR_BIBED_*` or a similar Google-side error citing tokenization spec problems. **Past wrong:** `gateway` / `gatewayMerchantId` placed outside `tokenizationSpecification.parameters`, or path inferred from training data rather than the Google notes. **Check:** `references/third-party/google-request-objects.md` for the exact nesting of `tokenizationSpecification`.
- **Symptom:** the Payroc payments call rejects the gateway-tokenised data. **Past wrong:** `gateway` constant or `gatewayMerchantId` derivation taken from training data rather than the Payroc narrative copy. **Check:** `references/google-pay.md` as the source of truth for these two values.
- **Symptom:** `PaymentsClient` method `TypeError` or unexpected return shape. **Past wrong:** assumed argument or return shape. **Check:** `references/third-party/google-client.md`.

### Checkpoint

Does the Google Pay button render on the page? Does clicking it present the payment sheet?

---

## Step 3 — Process the payment

This step crosses **two sources** — Google owns the format of the encrypted token coming out of `paymentData`; Payroc owns the wrapping shape and enum values you'll POST to `/v1/payments`. Read both:

- **Google — `paymentData` callback shape:** confirm where the encrypted token lives inside `paymentData` (e.g. `paymentData.paymentMethodData.tokenizationData.token`) — read from `references/third-party/google-request-objects.md`, not training data.
- **Payroc narrative + schema:** `references/google-pay.md` for the composition, and `references/api-schema.md` (`paymentRequest`, `paymentMethod` digitalWallet variant) for exact field names and enum values.

> **Do not use any field names, endpoint URLs, or encrypted data format from your training knowledge.** Two separate sources: Google owns `paymentData`'s structure (`references/third-party/`); Payroc owns the request body shape in `references/api-schema.md`. Read both before emitting code.

When `loadPaymentData` resolves, the `paymentData` object contains encrypted payment information. Your server must:

1. Extract the encrypted payment token from `paymentData` (the exact path — confirm against the Google request-objects notes).
2. Convert it to hexadecimal format (read the exact requirement from `references/google-pay.md`; if not explicit there, check `references/api-schema.md` for the `encryptedData` field's documented format constraints).
3. POST to the Payroc payments endpoint. The structure (read from `references/api-schema.md`) is typically along the lines of:
   - `paymentMethod.type` — read the current enum value for a digital wallet from `references/api-schema.md` (`paymentMethod.type` enum); do not assume `"digitalWallet"` from memory.
   - `paymentMethod.serviceProvider` — read the current enum value for Google Pay from `references/api-schema.md`; do not assume `"google"` from memory.
   - `paymentMethod.encryptedData` — the hex-encoded token from step 2.
   - Plus the standard `channel`, `processingTerminalId`, `order` fields (all read-then-emitted; see the enum callout below).
4. On HTTP 201 — return success to the client and show a confirmation, after checking the response body (see the success-branch callout below).
5. On any error — surface the error to the client.

> **Read the Payroc `channel` enum from `references/api-schema.md`.** `channel` is on the Payroc payment request, not on the Google Pay request. **Known past failure (from sibling integrations):** a model emitted `channel: "internet"` because the value sounds reasonable for an in-browser checkout — Payroc returned HTTP 400 with the enum list in the error detail. The fix isn't to memorise the right value here; it's to read `paymentRequest.channel` from the schema reference as you construct the body. Plausible-sounding cousins (`internet`, `online`, `ecommerce`, `card-not-present`) are the most common form this failure takes.

> **Determine payment success from `responseCode`, not from a guessed `transactionResult.status` subset.** Read `references/api-schema.md`. The approval signal is **`responseCode === 'A'`** (a successful response also carries an `approvalCode` and an `OK` `responseMessage`). `transactionResult.status` is the *lifecycle* state: under an `A`, both `ready` (queued/captured) and `pending` (authorized, awaiting capture — e.g. a pre-auth or `autoCapture: false`) are successful authorizations; `declined` / `expired` etc. are not. **Known past failure (from sibling integrations and our benchmarking):** a model built an `APPROVAL_STATUSES` list and omitted members (e.g. `pending`), silently treating real authorizations as failures. Don't enumerate a status set from memory — key the success branch on `responseCode === 'A'` and use `status` for lifecycle. Handle `E` (deferred) and `P` (partial approval) deliberately; treat `D` / `R` / `C` as declines.

### Checkpoint

Does the payments API return HTTP 201 in UAT? Does the checkout page show a payment confirmation?

---

## Step 4 — Register with Google (production only)

Before going live, your integration must be registered with Google:

1. Register at the [Google Pay Business Console](https://pay.google.com/business/console)
2. Google will assign a production `merchantId`
3. Switch the `PaymentsClient` environment from `TEST` to `PRODUCTION`
4. Contact the Payroc Integrations team (`integrationsupport@payroc.com`) to confirm that live Google Pay processing is enabled for the terminal

This step is not required for UAT testing.

---

## Local testing strategy

Google Pay is fully client-plus-server — there is **no inbound webhook**, so unlike HPP there is no
public-URL reachability requirement and you don't need a tunnel (ngrok, Dev Tunnels, etc.).

- The Google Pay button requires a **secure context**. Browsers treat `http://localhost` as secure, so
  local development works without HTTPS; any other host must be served over HTTPS for the button to render.
- Use the `TEST` environment on the `PaymentsClient` for UAT — Google returns test payment data that Payroc's
  UAT terminal accepts. No Google Business Console registration is needed to test in `TEST`.
- Production requires Business Console registration (Step 4) plus the production base URLs and the
  `PRODUCTION` environment — but **not** per-domain verification files (that is an Apple Pay concern, not
  Google Pay).

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Google Pay button never renders | `isReadyToPay` returned false | Check that supported networks and auth methods match what the test environment allows; in `TEST` environment any device should work |
| `loadPaymentData` throws or rejects | `PaymentDataRequest` misconfigured | Check browser console for Google Pay error details; verify `gateway`, `gatewayMerchantId`, and `merchantId` fields match what the docs require |
| Payment sheet shows but fails on confirmation | `gatewayMerchantId` incorrect | Confirm derivation: terminal ID minus last 3 characters — read `references/google-pay.md` to verify the formula |
| Payment API 401 | Bearer token expired or wrong API key | Re-fetch Bearer token; verify the `x-api-key` value |
| Payment API 400 | `encryptedData` not in hex format, or missing required fields | Re-read the `encryptedData` format requirement from `references/google-pay.md` / `references/api-schema.md`; confirm the hex conversion logic |
| Payment API processes but result is unexpected | Wrong `serviceProvider` value | Must be `"google"` (lowercase); check for case errors |
| Production button works in TEST but not PRODUCTION | Not registered with Google or live processing not enabled | Complete Google Pay Business Console registration; contact Payroc Integrations team |
| Payments API returns HTTP 400 naming `"channel"` (or another enum-typed field) in the error detail, with a list of accepted values | A non-enum value was emitted (past failures from sibling integrations: `channel: "internet"`, `"online"`, `"ecommerce"`); a plausible-sounding cousin substituted for the schema value | Read `paymentRequest.channel` (or the relevant field) from `references/api-schema.md` and emit one of the listed values. Do not infer enum values from English plausibility. |
| `paymentMethod.type` or `paymentMethod.serviceProvider` rejected by the Payroc API | The skill emitted a `digitalWallet` / `google` value remembered from training data rather than read from `references/api-schema.md` | Read the current `paymentMethod.type` and `paymentMethod.serviceProvider` enums from `references/api-schema.md` and emit the values listed there. Even if the remembered values *happen* to be right, the discipline failure (not reading the reference) is itself the bug. |
| `PaymentDataRequest` rejected with a Google-side error (`OR_BIBED_*` or similar) citing `tokenizationSpecification` issues | The `gateway` / `gatewayMerchantId` placement or value was taken from training data; or `tokenizationSpecification` is nested at the wrong path in the request | Read `references/third-party/google-request-objects.md` for the exact nesting; read `references/google-pay.md` for the `gateway` constant and the `gatewayMerchantId` derivation. The two sources must both be consulted; either alone is insufficient. |
| `PaymentsClient` method `TypeError` or returns an unexpected shape | Constructor argument shape, method name, or callback shape taken from training data rather than the Google client notes | Read `references/third-party/google-client.md`. Confirm the constructor and every method you'll call. Do not invent or rename — if your assumed name isn't in the Google notes, re-derive from the source (see `references/_sources.md`). |
| App logged a payment failure but the bank actually approved — Payroc response shows `responseCode: "A"` with an `approvalCode` / `OK` message | Success check branched on a guessed `transactionResult.status` subset (past failure: an `APPROVAL_STATUSES` list that omitted an authorized state such as `pending`, silently failing real authorizations) | Key the success branch on `responseCode === 'A'` per `references/api-schema.md`; treat `ready` and `pending` as authorized and `status` as lifecycle only. Don't enumerate an approval-status set from memory. |

---

## Validation checklist

- [ ] API key and terminal ID sourced from environment variables — not in source code
- [ ] Bearer token generated server-side — not exposed to the browser
- [ ] `gateway` constant and `gatewayMerchantId` derivation were read from `references/google-pay.md` (not from memory); values match the narrative copy
- [ ] `PaymentDataRequest` shape and `PaymentsClient.*` calls were checked against the Google notes under `references/third-party/`
- [ ] Every Payroc API enum value (`channel`, `paymentMethod.type`, `paymentMethod.serviceProvider`, etc.) was read from `references/api-schema.md`
- [ ] Server-side success branch keys on `responseCode === 'A'` (per `references/api-schema.md`), treats `ready` and `pending` as authorized and `D`/`R`/`C` as declines — not a guessed `transactionResult.status` subset
- [ ] Google Pay button only rendered when `isReadyToPay` returns `true`
- [ ] Encrypted payment data converted to hex format before sending to Payroc API
- [ ] Payment API returns HTTP 201 in UAT with a test Google Pay transaction
- [ ] (Production) Google Pay Business Console registration complete and `merchantId` updated
- [ ] (Production) Payroc Integrations team confirmed live processing enabled

---

## Anti-patterns

**Emitting the `gateway` constant or `gatewayMerchantId` derivation from memory instead of the narrative copy.** The values live in `references/google-pay.md`. Read it before emitting either value — don't emit from memory. Past failure modes include wrong casing on the gateway constant and incorrect derivation (e.g. removing the wrong character count), both of which produce authentication or routing failures.

**Treating memory as the source of truth for `tokenizationSpecification.parameters`.** The values inside `tokenizationSpecification.parameters` are Payroc-specific and live in `references/google-pay.md`. The shape *around* `tokenizationSpecification` (where it sits inside `PaymentDataRequest`) is Google's and lives in `references/third-party/google-request-objects.md`. Both need to be read; neither alone is enough.

**Rendering the Google Pay button unconditionally** — always gate on `isReadyToPay`. Rendering an unavailable button leads to errors when clicked.

**Hex-encoding the full `paymentData` object** — only the encrypted payment token within `paymentData` should be hex-encoded; confirm exactly which field from `references/third-party/google-request-objects.md`.

**Skipping Google registration before going live** — the `TEST` environment works without registration, but production will not process without completing the Business Console registration and contacting Payroc.

---

## Completion

Once HTTP 201 is confirmed and all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Google Pay button** — rendered conditionally; presents the Google Pay payment sheet when clicked.
> - **Gateway configuration** — the gateway constant and `gatewayMerchantId` value were read from the Payroc Google Pay narrative copy; routes requests through Payroc.
> - **Payment processing** — encrypted payment data hex-encoded and posted to the Payroc payments endpoint.
> - **Validated in UAT** — end-to-end Google Pay transaction confirmed.
>
> **Before going live:** complete Google Pay Business Console registration, update `merchantId` with the production value, switch `PaymentsClient` to `PRODUCTION` environment, swap UAT payment API URL for production, and confirm live processing is enabled with the Payroc Integrations team.

Offer next steps:

- **Apple Pay** — add Apple Pay for customers on Safari (iOS or macOS); it covers the Safari audience that Google Pay cannot reach. Apple Pay uses the Apple Pay JS API and requires domain verification — a separate skill covers this.
- **Hosted Fields** — if the developer also needs a card entry form fallback, that's the Hosted Fields skill

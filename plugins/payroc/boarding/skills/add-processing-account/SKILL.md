---
name: add-processing-account
description: >
  Guides developers through adding a processing account (a new MID) to an EXISTING merchant
  platform via the Payroc Boarding API (POST /merchant-platforms/{merchantPlatformId}/processing-accounts),
  and through retrieving, listing, and sending signing reminders for processing accounts. Use
  this skill whenever the user wants to add another processing account, provision a new MID for
  an already-boarded merchant, add a store / location / outlet / DBA to an existing merchant
  platform, onboard a second business line under the same merchant, build the request body for
  POST .../processing-accounts, retrieve or list a merchant platform's processing accounts
  (GET /processing-accounts/{id} or GET /merchant-platforms/{id}/processing-accounts), look up a
  processing account's owners, contacts, funding accounts, or pricing agreement, or prompt a
  merchant to sign their pricing agreement (reminders) — even if they don't say "skill",
  "processing account", or "boarding API" explicitly. This is distinct from create-merchant-platform
  (initial boarding of a brand-new merchant) — reach for this skill when the merchant platform
  already exists and you have its merchantPlatformId.
metadata:
  version: "0.1.3"
  category: boarding
  status: draft
---

# Add Processing Account

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/boarding/skills/add-processing-account/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

## What this skill covers

A merchant platform can hold more than one processing account — each provisions a separate MID,
typically for an additional location, brand, or line of business under the same legal entity.
This skill adds an account to a platform that **already exists**, then reads it back.

```
POST  /v1/merchant-platforms/{merchantPlatformId}/processing-accounts   → add an account
GET   /v1/merchant-platforms/{merchantPlatformId}/processing-accounts   → list a platform's accounts
GET   /v1/processing-accounts/{processingAccountId}                     → retrieve one account
GET   /v1/processing-accounts/{processingAccountId}/{pricing|owners|contacts|funding-accounts}
POST  /v1/processing-accounts/{processingAccountId}/reminders           → prompt the merchant to sign
```

**Related skills** — mention these when relevant:
- **create-merchant-platform** — board a brand-new merchant (creates the platform and its first
  account). Use that first if no `merchantPlatformId` exists yet.
- **create-pricing-intent** — create a reusable pricing template and get the `pricingIntentId`
  you reference in this account's `pricing` block.

For every field, enum, and nested object, read `references/api-schema.md`. Emit values from
that file, not from memory — boarding payloads are deep and the enums are easy to misremember.

---

## Quick reference

```
POST  https://api.payroc.com/v1/merchant-platforms/{merchantPlatformId}/processing-accounts
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

Test/UAT base URL: `https://api.uat.payroc.com`. Identity: `https://identity.uat.payroc.com`
(test) / `https://identity.payroc.com` (production).

---

## How to work (core principles)

- **Read before you emit.** The request body is one `createProcessingAccount` object with ~13
  required fields and several nested objects. Open `references/api-schema.md` and copy field
  names, enum values, and the funding `paymentMethods` shape from there. Don't reconstruct them
  from memory.
- **Gather before you build.** Boarding needs real data (owners, SSNs, bank details, volumes).
  Run the intake below first so you don't produce a half-populated payload the developer then
  has to chase.
- **Confirm at each checkpoint.** After intake, after the payload, and after the response —
  pause and confirm before moving on, so mistakes surface early rather than at submission.
- **Request and response differ.** What you send (`createProcessingAccount`) is not what comes
  back (`processingAccount` — owners/funding/pricing return as summaries with HATEOAS links).
  Read them as two separate schemas.

---

## Intake — gather these before building

1. **`merchantPlatformId`** of the existing platform. If the developer doesn't have it, point
   them to List Merchant Platforms, or to **create-merchant-platform** if the merchant isn't
   boarded yet.
2. **Pricing** — do they have a `pricingIntentId` (preferred), or do they need inline agreement
   pricing? If they want a reusable template and don't have one, send them to
   **create-pricing-intent** first.
3. **Business details** for the new account — DBA, business type, MCC, what they sell, start
   date, timezone, physical address, an email contact.
4. **Owners** — exactly one control prong (only one allowed) and at least one authorized
   signatory. An owner can be one or the other but **not both**, so you need at least two owners.
   For each: name, DOB, address, national ID (SSN), and an email.
5. **Processing** — average/highest transaction and monthly amounts (in cents), and the
   card-present / MOTO / e-commerce split (must sum to 100).
6. **Funding** — bank account name, routing number, account number, account type, and use.
7. **Signature** — email signing (`requestedViaEmail`, most common) or direct link.

---

## Prerequisites

- A bearer token (see Step 1).
- A valid `merchantPlatformId` for an existing platform.
- A pricing path: an `active` `pricingIntentId`, or the data for an inline agreement.
- The environment-specific base URLs (test vs production).

---

## Step 1 — Get a bearer token

Tokens expire in ~1 hour. Exchange your API key before each session (or refresh proactively).

```bash
# Test / sandbox
curl -X POST https://identity.uat.payroc.com/authorize -H "x-api-key: YOUR_API_KEY"

# Production
curl -X POST https://identity.payroc.com/authorize -H "x-api-key: YOUR_API_KEY"
```

Response contains `access_token`; use `Authorization: Bearer <access_token>` on every request.
The Payroc SDKs (TypeScript, Python, C#, PHP, Go, Java, Ruby) handle token exchange
automatically — see https://docs.payroc.com/api/payroc-sd-ks-beta.

**Checkpoint:** you have a token and the target `merchantPlatformId`.

---

## Step 2 — Build the processing-account body

The request body **is** a single processing-account object — no `business` wrapper and no
`processingAccounts` array. (That wrapper belongs to `POST /merchant-platforms` during initial
boarding; here you POST one account object to the platform's sub-resource.)

Required fields: `doingBusinessAs`, `businessType`, `categoryCode`, `merchandiseOrServiceSold`,
`businessStartDate`, `timezone`, `address`, `contactMethods`, `owners`, `processing`,
`funding`, `pricing`, `signature`. Optional: `website`, `contacts`, `metadata`.

Read `references/api-schema.md` for the full field list and the annotated example. The points
worth stating up front, because they're the common mistakes:

- **Ownership** — exactly one owner with `relationship.isControlProng: true` (only one control
  prong is allowed) and at least one *other* owner with `relationship.isAuthorizedSignatory: true`.
  A single owner **cannot** be both at once — the API rejects it ("it must be one or the other or
  neither") — so you need at least two owners.
- **Volume breakdown** — `processing.volumeBreakdown.cardPresent + mailOrTelephone + ecommerce`
  must equal exactly **100**. If `ecommerce > 0`, the account's top-level `website` is **required**
  (the API rejects the account without it).
- **Amounts in cents** — `transactionAmounts` and `monthlyAmounts` are integers in cents
  (`6500` = $65.00).
- **Funding payment methods are nested** — each is
  `{ "type": "ach", "value": { "routingNumber": "...", "accountNumber": "..." } }`. The bank
  numbers live under `value`, not flat on the payment method.
- **Pricing** — prefer `{ "type": "intent", "pricingIntentId": "<id>" }` (reuses a template).
  Use `{ "type": "agreement", ... }` only for one-off inline pricing; that full structure lives
  in the **create-pricing-intent** reference.
- **Signature** — `{ "type": "requestedViaEmail" }` is the usual choice and is the only one that
  lets you send signing **reminders** later.
- **Dates** — `businessStartDate` and each owner's `dateOfBirth` are `YYYY-MM-DD`.

**Checkpoint:** show the developer the assembled payload and confirm the data is right before
submitting.

---

## Step 3 — Send the request

Generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* submission, reuse the
same key — the API returns the original result instead of creating a duplicate. A `400`
validation error creates nothing, so when you fix the payload and resubmit, **keep the same key**
— it's still the same account attempt. Generate a new UUID only for a genuinely separate account.

```bash
curl -X POST https://api.payroc.com/v1/merchant-platforms/MP-XXXX/processing-accounts \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @processing-account.json
```

---

## Step 4 — Handle the response

**201 Created** — the account was accepted (approval is asynchronous):

```json
{
  "processingAccountId": "PA-XXXX",
  "status": "entered",   // may also be "pending" depending on timing
  "doingBusinessAs": "Acme Widgets - Lakeview",
  "pricing": { "link": { "rel": "pricing", "method": "GET", "href": "https://.../processing-accounts/PA-XXXX/pricing" } },
  "links": [ { "rel": "self", "method": "GET", "href": "https://.../processing-accounts/PA-XXXX" } ]
}
```

Persist `processingAccountId` — you need it to retrieve the account, read its owners/funding/
pricing, order a terminal, and send reminders. The account may start in `"entered"` or
`"pending"` depending on timing; poll or subscribe to `processingAccount.status.changed` to
detect approval rather than relying on the create-response value.

**Checkpoint:** the `processingAccountId` is saved.

---

## Step 5 — Read it back (retrieve, list, related reads)

- **Retrieve one:** `GET /v1/processing-accounts/{processingAccountId}` → full `processingAccount`.
- **List a platform's accounts:** `GET /v1/merchant-platforms/{merchantPlatformId}/processing-accounts`.
  Query params: `limit` (default 10), `after`/`before` (cursors — not both), `includeClosed`
  (default `false`; set `true` to include `terminated`/`cancelled`/`rejected`). Paginate by
  following the `next`/`prev` links and checking `hasMore`.
- **Related reads by id:** `/pricing` (full agreement), `/owners`, `/contacts`,
  `/funding-accounts`. The account response returns these as summaries-with-links, so use these
  endpoints when you need the full objects.

> Owners of a processing account are **immutable** — `PUT`/`DELETE /owners/{ownerId}` reject
> them (they work only for funding-recipient owners). Get the owners right in Step 2.

---

## Step 6 — Send a signing reminder (optional)

If the account was created with `signature.type: "requestedViaEmail"` and the merchant hasn't
signed, re-send the signing email:

```bash
curl -X POST https://api.payroc.com/v1/processing-accounts/PA-XXXX/reminders \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d '{ "type": "pricingAgreement" }'
```

A `201` returns `{ "type": "pricingAgreement", "reminderId": "RMD-XXXX" }`. A `409` usually
means the agreement is already signed; a `400`/`403` usually means the account wasn't set up for
email signing.

---

## Errors

Errors use the **RFC 7807 problem-details format as the envelope** (`type`, `title`, `status`,
`detail`, `instance`), **extended** with a Payroc `errors[]` array (the array is Payroc's own,
not defined by RFC 7807). Each `errors[]` item carries `parameter` (the JSON path of the failing
field — the most useful one), `detail` (a short reason, **distinct** from the top-level RFC
`detail`), and `message` (the human-readable explanation). Use `parameter` to map each issue back
to your request body, fix it, then resubmit with the same idempotency key (a `400` created
nothing). See [`_shared/error-response-format.md`](../../../_shared/error-response-format.md) and
the error table in `references/api-schema.md`.

| Status | Scenario | Action |
|--------|----------|--------|
| 400 validation | Field issues | Fix each `errors[].parameter`; resubmit with same idempotency key |
| 400 `idempotencyKeyMissing` | Missing header | Add `Idempotency-Key: <uuid-v4>` |
| 401 | Token expired/invalid | Re-authenticate for a fresh bearer token |
| 403 | Permissions, or account not email-signing (reminders) | Check API key scope; confirm `requestedViaEmail` |
| 404 | Unknown `merchantPlatformId` / `processingAccountId` | Verify the id via the list endpoints |
| 409 | Conflict (duplicate, or reminder when already signed) | Inspect existing state before retrying |
| 500 | Server error | Retry with exponential backoff |

---

## Common pitfalls

- **Wrapping the body** like Create Merchant Platform (`{ "business": ..., "processingAccounts": [...] }`).
  Here the body is a single account object posted to the platform's sub-resource.
- **Two control prongs** — only one is allowed; flag the rest as authorized signatories instead.
- **One owner set as both control prong and authorized signatory** — the API rejects it; use two
  owners (one control prong, a different one as authorized signatory).
- **Volume breakdown ≠ 100** — `cardPresent + mailOrTelephone + ecommerce` must be exactly 100.
- **Flat funding bank numbers** — `paymentMethods[]` nests them under `value`.
- **Amounts not in cents** — every monetary value is an integer in cents.
- **Reusing an idempotency key for a different account** — generate a fresh UUID per submission.
- **Expecting to edit owners later** — they're immutable; get them right on submission.

---

## Validation checklist (before submitting)

- [ ] `merchantPlatformId` is correct and the platform exists
- [ ] Body is a single account object (no `business` / `processingAccounts` wrapper)
- [ ] Exactly one control prong and at least one *different* authorized signatory (no owner is both)
- [ ] `volumeBreakdown` sums to 100 (and `website` is set if `ecommerce > 0`)
- [ ] All amounts are integers in cents
- [ ] Funding `paymentMethods` use the `{ type, value: { routingNumber, accountNumber } }` shape
- [ ] `pricing` is a valid `intent` (active `pricingIntentId`) or `agreement`
- [ ] Dates are `YYYY-MM-DD`
- [ ] `Authorization` and `Idempotency-Key` headers set

---

## Full field reference

Read `references/api-schema.md` for all endpoints, enum values, nested object schemas
(`owner`, `processing`, `createFunding`, `pricing`, `signature`), pagination, reminders, the
error shape, and a complete annotated example request.

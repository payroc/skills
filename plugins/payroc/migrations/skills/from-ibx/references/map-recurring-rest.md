# IBX → Payroc: recurring billing (REST) — `/customers`, `/contracts`, `/recurringtransactions`

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> the IBX REST recurring-billing surface — customers, stored recurring payment methods, contracts and
> on-demand recurring charges — to the Payroc API. Per-row confidence is carried in the `C` column; the
> legend is in [`_sources.md`](./_sources.md). Last synced: 2026-09-04. Read mappings from this file,
> not from memory — a plausible-sounding mapping that isn't here will look correct in review and fail
> in production.

```text
IN:  REST /customers, /customers/{ck}/recurringpaymentmethods/{cards|checks},
     /customers/{ck}/contracts/{cards|checks}, /contracts/{cards|checks} (merchant-wide),
     /recurringtransactions/{cards|checks}.
OUT: SOAP recurring.asmx -- map-recurring-soap.md, which covers the same general capability
     on a thinner evidence base; this file is the well-documented sibling. cardsafe token
     vaulting is a DIFFERENT vault with different request shapes --
     map-tokens-and-vault.md.
ADJACENT: identifier-translation.md holds cross-cutting identifier, amount, expiry and
     currency facts, cited from the rows below rather than restated per row. If your call is
     not in the table below, it is not absent from IBX -- check map-recurring-soap.md, then
     SKILL.md's routing table, then ask for a request sample.
```

**Where to implement what you find here:** `set-up-a-payment-plan` and `manage-subscriptions` for
contracts, `save-a-payment-method` for customers and stored recurring payment methods,
`run-a-card-sale` / `take-an-ach-payment` for the on-demand `/recurringtransactions` charge. This file
owns the delta; those skills own the request schema.

## Cross-cutting facts

Stated once here; see `identifier-translation.md` for the full detail on identifiers, amounts, expiry
and currency.

- **IBX's `/customers` is a genuine, independently addressable, PII-bearing entity** with its own
  name, address, phone and email fields, joined to the merchant, contact and address records.
- **Payroc customer data is persistent, independently addressable and full-CRUD — but the shape is
  different, and the shape is where the loss is.** A `customer` object is embedded in the
  `secure-tokens` resource, which has `createSecureToken`, `getSecureToken`, `updateSecureToken` and
  `deleteSecureToken`. So customer data is stored, readable, updatable and deletable. **What does not
  exist is a customer identity.** Identity is keyed by *payment instrument*: one secure token holds
  one customer's one payment method with their details copied into it. There is **no customer id
  property anywhere**. Consequently one person with three stored payment methods becomes three
  unlinked records, each holding its own copy of their details; there is no parent record to hang
  several payment methods, several subscriptions or a transaction history from; and "fetch customer X"
  resolves only through fuzzy `customerName`/`phone`/`email` filtering, which may return zero matches
  or many. **Do not state this as "no customer equivalent", and do not state it as "Payroc has
  customers".**
- **Subscriptions do not embed customer data — but it is one id-based hop away, not absent.** The
  subscription request references the secure token through a token payload whose properties are only
  type, account type, token and SEC code — no `customer` object. The subscription response embeds a
  secure-token summary carrying a bare `customerName` string (max 50 characters) plus the token id and
  status. **Customer data is reachable from any subscription via a second call —
  `getSecureToken(secureTokenId)`, using the id the subscription already returns.** State it as: the
  subscription payload carries no customer data, so retrieving it costs an extra call per token. Do
  not state it as "there is no customer schema to point to".
- **There is no customer-only create on Payroc.** The tokenization request declares `source` — the
  payment method to tokenize — as required, while `customer` is optional. That is the schema-level
  reason identity is keyed by payment instrument, and it names a migration cohort with no target at
  all: **a legacy customer with no stored payment method has no Payroc record to become. Escalate
  those rather than assuming a target.**
- **One underlying store backs both card- and check-funded contracts; `/contracts/cards` versus
  `/contracts/checks` is a thin, unfiltered view over it, not two separate resources.** Three
  independent runtime defects show this, rather than it being inferred from the schema: (1) fetching a
  check contract's key through the card path throws a `NullReferenceException` — the least firmly
  established of the three;
  (2) a customer-scoped card-contract list silently includes check contracts, because the query
  applies no type filter; (3) a merchant-wide card list returns a 500 if the merchant has any check
  contracts at all, casting a check to a card object. **A mapping that assumes `/contracts/cards`
  returns only card contracts is asserting something the runtime does not guarantee** for any customer
  who has ever had both.
- **`/recurringtransactions/{cards|checks}` is a manual, on-demand charge trigger against a stored
  payment method, decoupled from any contract at the API-parameter level** — not a query over a
  contract's scheduled charges, and not gated on a contract existing at all. Neither the validator nor
  the database calls it makes reference the contract record; only the payment method's own key is
  looked up. **A stored card with no contract can be charged this way** — closer to a plain one-off
  `payment` against a `secureToken` (see `map-card-transactions.md`, `map-tokens-and-vault.md` and
  `map-token-payments.md`) than to `paySubscription`, which requires an existing `subscriptionId`.
  Which target is honest depends on whether the integration's own workflow created a contract — see the
  rows below.
- **Payroc's data model splits template from enrollment; IBX's does not — a structural mismatch, not a
  rename.** Payroc's `paymentPlan` (a reusable schedule template) and `subscription` (one customer's
  enrollment, referencing `paymentPlanId`) are two objects; every IBX contract is self-contained, with
  its own billing period, interval and amount tied directly to one customer and one payment method,
  with no plan layer at all. Porting requires either a throwaway 1:1 `paymentPlan` per legacy
  contract, or a real redesign that groups contracts sharing a schedule — **put this choice to the
  developer; don't default to one.**
- **Payroc's `frequency` enum (`weekly`, `fortnightly`, `monthly`, `quarterly`, `yearly`) cannot
  represent IBX's `billingPeriod` × `billingInterval` combinations** (`DAY`+`14`, `MONTH`+`2`, and so
  on). A real `LOSS:`, not a formatting difference.
- **No Payroc field represents IBX's `maxFailures` (retry count) or `maxAmount` (cumulative cap).**
  Checked in the subscription and payment-plan schemas and in Payroc's own recurring-billing guide,
  not just the schema. Genuine absences. Payroc's nearest analogue is a read-only `suspended`
  status, described as applying when a customer misses payments — **it carries no threshold and no
  documented decline path, so do not present it as retry handling.** (Payroc *does* document a
  five-attempt retry policy, but that is **webhook delivery**, not billing. Different mechanism.)
- **`maxFailures` is IBX's head-of-line block, and its two surfaces disagree about the default in
  opposite directions. This bites on migration.**
  - On IBX's **REST** route `POST /customers/{customerKey}/contracts/cards`, `maxFailures` must be
    **greater than zero** — the rule is unconditional, so the documented default of `0` ("will not
    reprocess") **cannot be sent**. Every card contract created that way has retry-blocking on.
  - On IBX's **SOAP** route, omitting it gives you **zero**.
  - So an existing SOAP integration that relies on the zero default has no like-for-like REST
    equivalent, and you must decide a real retry count before migrating. Neither value carries over
    to Payroc, which has no field for it at all.
  - The rule applies to **card contracts only** — the check-contract and both update routes have no
    such constraint. **The documented 0–10 range is not enforced anywhere**, on either surface, so
    do not rely on an upper bound being rejected.
  - `failureInterval` is **silently clamped** into 1–28 rather than rejected: send 60 and you get
    28, with no error.
- **`updateSubscription` cannot PATCH `currentState`, `type`, `frequency` or `paymentPlan`** — four
  immutable fields — so any IBX operation that changes an existing contract's billing cadence has no
  Payroc PATCH target, regardless of what IBX's SOAP `ManageContract` supports. A firm
  gap on the Payroc side, not contingent on `ManageContract`.
- **IBX's 31st-of-month rollover rule, documented on every contract page, has no stated Payroc
  equivalent** — neither the Payroc API specification nor the published guide states one. **Confirm the rollover behaviour with your implementation contact rather than assuming
  either "same" or "gap".**
- **This whole family has no `ExtData` or free-text mechanism at all** — no request or response schema
  in scope declares the field. Anything an integration carries in `ExtData` elsewhere has no
  counterpart here to migrate from.
- **A reseller-model caveat.** IBX silently reassigns contracts to the original owning merchant when
  tokens are shared across merchants under a reseller. This is confirmed IBX-side behaviour; **whether
  it has any Payroc-side bearing has not been established** — raise it with your implementation
  contact if you operate under a reseller model, rather than assuming it either ports or disappears.

## `/customers`

**These five rows are `partial`, and `partial` here does not mean "ports cleanly".** Each carries a
distinct, real loss, and `POST /customers` for a customer with no stored payment method has no target
at all.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST POST /customers` | partial | `createSecureToken` (`POST /processing-terminals/{id}/secure-tokens`) — the customer's details are written as the `customer` object on the tokenization request | The customer's fields move onto `tokenizationRequest.customer`. **`+source` (required)** — a payment instrument the IBX call does not supply. | `LOSS:` **there is no customer-only create on Payroc.** The tokenization request declares `source` — the payment method to tokenize (`ach`/`pad`/`card`/`singleUseToken`) — as required, while `customer` is optional. IBX creates a customer first and attaches payment methods afterwards through a separate `/customers/{ck}/recurringpaymentmethods` call; on Payroc the customer record cannot exist before a payment instrument does. **A migration replaying IBX customers who have no stored payment method has nowhere to put them — escalate those specifically.** `SCOPE:` on the IBX side `customerName`, `firstName`, `lastName`, `street1`, `city`, `state`, `zip` and `email` are all validator-optional but **effectively required** — testing against the running platform returns a real `400`, `"customerName is required"`, for a field the specification marks optional. | verified (IBX side; and the Payroc side's required/optional split) / inferred (whether a token-create is an acceptable substitute for a customer-create is a judgement, not a verified equivalence) |
| `REST GET /customers` | partial | `listSecureTokens` (`GET /processing-terminals/{id}/secure-tokens`) | No customer-scoped list parameter exists; filter with `customerName`/`phone`/`email`. | `LOSS:` **`listSecureTokens` enumerates stored payment methods, not customers.** A customer with three stored payment methods appears three times, once per token, each carrying its own copy of their details; a customer with none does not appear at all. There is no customer id to de-duplicate on, so reconstructing IBX's customer list means string-grouping on `customerName` and accepting both the false-positive and the false-negative risk. On the IBX side this is a thin, unfiltered list — no pagination, no query parameters, and it returns every active and inactive customer for the calling merchant. | verified (IBX side) / inferred (the Payroc pairing) |
| `REST GET /customers/{customerKey}` | partial | `getSecureToken` (`GET /secure-tokens/{secureTokenId}`) where a token id is known; otherwise `listSecureTokens` filtered by `customerName`/`phone`/`email` | Read by `secureTokenId`, not by a customer key. `customerKey` has no Payroc counterpart — see `identifier-translation.md`'s `CustomerKey` row. | `LOSS:` **no id-based customer lookup exists.** You can read *a* customer's details from a known token — the response embeds a retrieved-customer object carrying the same property set as the write-side `customer` with only its address sub-fields relaxed, so there is no read-path field loss — but you cannot fetch a customer by identity, nor get one record covering a customer with several stored payment methods. `SEMANTIC:` on the IBX side, `status` has an **undocumented third runtime value** (`3` = closed/deleted). IBX's own field description lists only `1` and `2`, and it appears on the **create and update request** schemas — the response schema has no `status` property at all. A deleted customer returns a `404` `RecordNotFoundException` rather than a closed-status record. | verified (IBX side — a declared-versus-observed contradiction; and the Payroc read-path property set) / inferred (the Payroc pairing) |
| `REST PUT /customers/{customerKey}` | partial | `updateSecureToken` (a PATCH-style update of the token's `customer` object) | Addressed by `secureTokenId`, not `customerKey`. | `LOSS:` **one IBX update becomes N Payroc calls**, one per stored payment method, because each token holds its own unlinked copy of the customer's details. The caller must locate those tokens itself, and no id-based query returns them — only the fuzzy `customerName`/`phone`/`email` filters. `SEMANTIC:` on the IBX side **this is not a partial update** — any field omitted from the request body that was previously populated is silently overwritten with an empty string. Omitting `customerName` specifically throws an unhandled `500 SqlException` rather than a clean validation error. **An existing IBX integration may already depend on this blank-on-omit behaviour, which `updateSecureToken` does not replicate.** | verified (IBX side) / inferred (the Payroc pairing) |
| `REST DELETE /customers/{customerKey}` | partial | `deleteSecureToken` | Addressed by `secureTokenId`, not `customerKey`. | `LOSS:` the same fan-out as `PUT` — deleting "the customer" means deleting each of their tokens individually, with no id-based way to enumerate them first, and no single operation that removes the person. `SEMANTIC:` on the IBX side this is a soft delete to `status=3`, and it is **not idempotent** — re-deleting an already-deleted customer returns a `404`, unlike contract deletion below, which is idempotent and returns `204` on re-delete. | verified (IBX side) / inferred (the Payroc pairing) |

## `/contracts` and `/customers/{customerKey}/contracts/{cards\|checks}`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST GET /contracts/cards` (merchant-wide list) | partial | `listSubscriptions` (best-supported placeholder — no customer-grouping concept exists on either side to filter by merchant the same way; see cross-cutting facts) | — | `SEMANTIC:` **returns a `500 NullReferenceException`, casting a check to a card object, if the calling merchant has any check-funded contracts at all** — the one-underlying-store defect from the cross-cutting facts. This is an IBX-side runtime bug worth raising with the developer if their integration relies on this call today, independent of the migration. | verified (the defect) / inferred (the Payroc pairing) |
| `REST GET /contracts/checks` (merchant-wide list) | partial | `listSubscriptions` | — | The same one-underlying-store caveat applies in the other direction; a symmetric defect is not confirmed either way. | inferred |
| `REST GET /customers/{ck}/contracts/cards` (customer-scoped list) | partial | `listSubscriptions` filtered client-side (Payroc subscriptions have no customer-grouping field — see cross-cutting facts; a real structural gap, not just a missing filter parameter) | — | `SEMANTIC:` **silently includes check contracts in a "cards" list** — no type filter exists in the underlying query. **Do not assume this endpoint's name describes its actual output.** | verified |
| `REST GET /customers/{ck}/contracts/checks` (customer-scoped list) | partial | `listSubscriptions` filtered client-side | — | The same caveat as the card-list row, by the same underlying cause — not confirmed for checks specifically. | inferred |
| `REST POST /customers/{ck}/contracts/cards` | sequence (best-supported reading — see the plan-versus-enrollment mismatch in cross-cutting facts) | `createPaymentPlan` (if an equivalent schedule doesn't already exist) → `createSubscription` | `contractName` and `nextBillDate` are validator-optional but confirmed effectively required — the same pattern as `/customers` | `LOSS:` `maxFailures` and `maxAmount` have no Payroc target (cross-cutting facts); `billingPeriod` × `billingInterval` combinations outside Payroc's fixed five-value `frequency` enum have no target either. | verified (the effectively-required-field pattern) / inferred (the Payroc-side sequence) |
| `REST POST /customers/{ck}/contracts/checks` | sequence — the same structural mismatch as the card row above | `createPaymentPlan` → `createSubscription` | The check contract's validator is markedly looser than its card twin — no amount or date-ordering rules at all beyond `nextBillDate` | `SCOPE:` *"you can create a Card Contract for a deleted/inactive customer, where you cannot for a Check"* — a real, testing-observed asymmetry between the two payment types on the IBX side. | verified (the validator comparison) / inferred (the asymmetry claim, which rests on a single testing note) |
| `REST GET /customers/{ck}/contracts/cards/{contractKey}` | direct | `getSubscription` | — | `SEMANTIC:` returns a `500 NullReferenceException` if the key belongs to a check contract — the one-underlying-store defect again. **A caller must know a priori which payment type a `contractKey` belongs to.** | verified (the defect) / inferred (the Payroc pairing) |
| `REST GET /customers/{ck}/contracts/checks/{contractKey}` | direct | `getSubscription` | — | A symmetric defect is not confirmed either way. | inferred |
| `REST PUT /customers/{ck}/contracts/cards/{contractKey}` | partial | `updateSubscription` (PATCH, RFC 6902) | — | `LOSS:` `currentState`, `frequency` and `paymentPlan` are all PATCH-immutable on the Payroc side (cross-cutting facts) — **any IBX update that changes billing cadence has no Payroc target regardless.** | inferred |
| `REST PUT /customers/{ck}/contracts/checks/{contractKey}` | partial — the same caveat as the card row above | `updateSubscription` | — | Same. | inferred |
| `REST DELETE /customers/{ck}/contracts/cards/{contractKey}` | absorbed | `deactivateSubscription` (best guess — it cancels the enrollment; it does not delete the underlying plan template) | — | `SEMANTIC:` a delete of a **nonexistent** contract key and a delete of **someone else's real contract** both return the identical `500 ApplicationException: "Access to contract denied"` — your code cannot tell "not found" from "not yours" by the response. Idempotent: re-deleting an already-inactive contract returns `204`. | verified (the identical error text, observed on three separate occasions) / inferred (the Payroc target) |
| `REST DELETE /customers/{ck}/contracts/checks/{contractKey}` | absorbed — the same as the card row above | `deactivateSubscription` | — | The same idempotency and indistinguishable-error behaviour. | verified (IBX side) / inferred (the Payroc target) |

## `/customers/{customerKey}/recurringpaymentmethods/{cards\|checks}`

The stored-payment-method vault this whole family's contract and recurring-transaction records point
into — **not the same vault, and not the same request shapes, as `cardsafe`** (see
`map-tokens-and-vault.md`).

**A published-schema trap on this endpoint family, and it is a same-operation contradiction.**
`/contracts` and `/recurringtransactions` do not reference a card-data object at all — both take a
bare `cardInfoKey` vault reference with no embedded card fields, confirmed against their validators
and IBX's published specification. The shared card-data schema (`street`/`zipCode`) is referenced both
by `/transactions` (see `map-card-transactions.md` and `map-rest-transactions.md`) **and by these
`recurringpaymentmethods` POST and PUT operations** — but this operation's own runtime validator
requires `address`, `city`, `state` and `zip` instead, fields the *declared* schema does not have.
**The declared body shape for this operation contradicts its own runtime validator — trust the
validator.** The cause of the contradiction is not established. **Do not carry `street`/`zipCode`
into a request for this specific endpoint family regardless of the cause.**

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST GET /customers/{ck}/recurringpaymentmethods` (list) | absorbed | `listSecureTokens` filtered client-side (no customer-grouping field on Payroc's side — the same gap as the contract-list rows) | — | — | inferred |
| `REST POST /customers/{ck}/recurringpaymentmethods/cards` | absorbed | `createSecureToken` | `+address` / `+city` / `+state` / `+zip` — this endpoint's own card-data shape, **not `street`/`zipCode`**; see above | — | inferred |
| `REST GET /customers/{ck}/recurringpaymentmethods/cards/{cardInfoKey}` | direct | the token read described in `map-tokens-and-vault.md` (`listSecureTokens` filtered to one) | — | `SEMANTIC:` **a confirmed response-field bug** — `CardInfoKey` and `CustomerKey` in the response body are always `0`, even though both were supplied in the request; the response object's defaults were never wired up. Point the developer to this if they report the response looking wrong — it is a known IBX defect, not a client-side parsing error. | verified |
| `REST PUT /customers/{ck}/recurringpaymentmethods/cards/{cardInfoKey}` | absorbed | `updateSecureToken` | The same card-data shape caveat as `POST` above | — | inferred |
| `REST DELETE /customers/{ck}/recurringpaymentmethods/cards/{cardInfoKey}` | absorbed | the token delete described in `map-tokens-and-vault.md` | — | — | inferred |
| `REST POST /customers/{ck}/recurringpaymentmethods/checks` | absorbed | `createSecureToken` (bank-transfer source) | The same card-data-shape trap likely applies to the check request too — not confirmed | — | unverified |
| `REST GET /customers/{ck}/recurringpaymentmethods/checks/{checkInfoKey}` | direct | the token read described in `map-tokens-and-vault.md` | — | The response-field-zeroing bug found on the card `GET` above was not independently confirmed for checks — plausible by symmetry, not verified. | unverified |
| `REST PUT /customers/{ck}/recurringpaymentmethods/checks/{checkInfoKey}` | absorbed | `updateSecureToken` | — | `SEMANTIC:` **this is the route `map-recurring-soap.md` sends you to when a stored check's MICR line is wrong, and whether it writes a MICR is not established.** On SOAP `ManageCheckInfo`, `UPDATE` will not take `MICR` and `RawMICR` from your request. IBX declares *this* update's body with a `micr` field — but that is a declared-schema claim, on **the one endpoint family where the declared body shape is known to contradict the runtime validator**, and the instruction above is to trust the validator. **This operation's validator never mentions `micr`**: it requires the two keys, a check-data object, a check number and an account number, and nothing else. **Validator silence is not permission** — the same trap this file names on `/recurringtransactions`. Nothing else settles it: IBX's engineering notes cover the card update and the check *create*, but not this operation, and no test exercises it, while the card equivalents of both exist. **A `200` here would not tell you the MICR was stored.** The declared success response hands the stored check data straight back, so it can echo the value you just sent — and on the *card* operations of this same family a `200` is documented alongside keys the caller supplied coming back as `0`, which is plausible by symmetry here and not independently confirmed for checks. **Do not read a success as a write. Equally, do not treat rebuilding the payment method as the safe alternative** — a rebuild means an `ADD`, and `ADD` sends both MICR fields to storage while what storage does with them is not established either. **Neither route is established; take both to your Payroc implementation contact rather than choosing between them.** | inferred |
| `REST DELETE /customers/{ck}/recurringpaymentmethods/checks/{checkInfoKey}` | absorbed | the token delete described in `map-tokens-and-vault.md` | — | — | inferred |

## `/recurringtransactions/{cards\|checks}`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST POST /recurringtransactions/cards` | branch | `paySubscription` (if the integration's own workflow created a contract) \| a plain `payment` against the stored `secureToken` (if no contract exists — IBX itself does not require one; see cross-cutting facts) | `paymentType` is declared with an empty, invalid type and is never validated at runtime — the real two-value set (`Card`/`Check`) is established from documentation prose and IBX's own test code, never from a captured request body. `invoiceData` is optional to both the specification and the validator but is confirmed mandatory in practice — omitting it produces an observed `500 NullReferenceException`. **Validator silence is not permission.** | `SEMANTIC:` the success response is a near-empty stub — an echoed `pnRef` and a permanently-default, always-wrong `authDate` (`0001-01-01T00:00:00`), with no approval code, result code or result text of any kind. Contrast `paySubscription`'s response, which returns a payment summary with paymentId, dateTime, currency, amount, status and responseCode all required: **this is a case where the migration is a genuine, additive quality improvement rather than a gap**, because there is nothing rich to lose on the IBX side. `ID:` **the `forceDuplicate` → `Idempotency-Key` control does not just invert — the opt-out disappears.** IBX blocks apparent duplicates by default and `forceDuplicate` is how you opt *in* to permitting one. Payroc's `Idempotency-Key` header is **required on every request**, so deduplication is mandatory and there is no per-request flag that permits a duplicate. The equivalent of `forceDuplicate: true` is therefore **to generate a fresh idempotency key**, not to set a field — a genuinely repeated charge is a new request with a new key, and re-sending the same key returns a `409` rather than a second payment. | verified (the IBX response shape, and the Payroc response schema) / unverified (which branch target applies to a given integration, which cannot be known without knowing its own contract usage) |
| `REST POST /recurringtransactions/checks` | branch — the same as the card row above | The same as the card row above | The same `paymentType` and `invoiceData` caveats | `SEMANTIC:` **this specific operation is documented as broken** — `500`, `"Unable to cast object of type 'Check_Info_TRow' to type 'CC_Info_TRow'"`, root-caused to the same card-versus-check confusion seen throughout this file. The finding dates from 2021 and has never been revised, but "not revised" only tells you nobody documented a fix, not that the code was never fixed; it has not been confirmed live either way. **If it is still true, the honest answer to the developer is not a mapping at all: escalate, because the source platform's own equivalent operation may not function, and a migration cannot preserve behaviour that does not exist.** | verified (the defect is documented and dated) / unverified (its current status) |

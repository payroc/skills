# IBX → Payroc: merchant, user, register and interchange-optimization administration

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> IBX's administrative surfaces — REST `/merchants`, `/users`, `/registers`, `/optimizations`, and the
> SOAP `customfields` and `resellerbuilder` services — to the Payroc API. Per-row confidence is carried
> in the `C` column; the legend is in [`_sources.md`](./_sources.md). Last synced: 2026-09-04. Read
> mappings from this file, not from memory — a plausible-sounding mapping that isn't here will look
> correct in review and fail in production.
>
> **How far a badge in this file goes.** These administrative surfaces have no captured request or
> response traffic behind them. Every finding here rests on Payroc's engineering records for the IBX
> platform, and most of those records date from around 2021 and have not been re-confirmed against
> the running platform. **A `verified` in this file is weaker than a `verified` in the transaction
> files, which are backed by runtime behaviour.** Confirm anything load-bearing with your Payroc
> implementation contact before you build against it.

```text
IN:  REST /merchants, /merchants/customField, /users, /registers, /optimizations. SOAP
     customfields.asmx and resellerbuilder.asmx (/vt/ws).
OUT: Everything transaction-shaped -- every other map-*.md file in this skill. The
     per-transaction `customFields[]` key/value array sent WITH a transaction --
     map-card-transactions.md and map-rest-transactions.md. That is a DIFFERENT concept from
     this file's per-merchant custom-FIELD-DEFINITION schema; do not conflate the two.
ADJACENT: identifier-translation.md holds cross-cutting identifier, amount, expiry and
     currency facts. If your call is not in the table below, it is not absent from IBX --
     check the sibling files above, then SKILL.md's routing table, then ask for a request
     sample.
```

**Where to implement what you find here:** `create-merchant-platform` and `add-processing-account` for
boarding a merchant, `order-a-terminal` for provisioning a register's replacement, `create-pricing-intent`
for pricing. This file owns the delta; those skills own the request schema.

**Read the `V` column carefully in this file, because two of its verdicts mean opposite things to
you.** `none` means the capability is gone and you have to redesign around it. `config` means you keep
the capability — it stops being an API call you make and becomes something Payroc configures for you,
so the action is a conversation with your implementation contact, not a rewrite. Most of this file is
`config`, not `none`.

## Cross-cutting facts

Stated once here; see `identifier-translation.md` for the full detail.

- **The entire IBX `/merchants` write surface is deprecated and returns HTTP 500 — not just `POST`.**
  `PUT /merchants/{merchantKey}` and `DELETE /merchants/{merchantKey}` both return the identical
  `"This method has been deprecated"` 500 that `POST` does. **Only the two `GET` operations are
  functional.** Real merchant creation, update and deletion happen through the Virtual Terminal, not
  through any REST call — and never did. So merchant create, update and delete are all `config` rows:
  **this is not a capability the migration removes from you, because you never had it over the API.**
- **Payroc is not target-less for merchant creation — a real, documented boarding API exists.**
  `createMerchant` (`POST /merchant-platforms`) is part of Payroc's boarding solution. It is
  application- and review-gated: a `201` returns an `entered` status, and approval arrives later as a
  `processingAccount.status.changed` event. It is not a synchronous create. **The honest framing is not
  "no equivalent, we configure it" — it is "IBX never had a working self-service create either, and
  Payroc's replacement genuinely is an API, just an asynchronous application rather than a synchronous
  call."** Whether Payroc operationally routes an IBX-reseller re-boarding through this API is a
  product and process question this file cannot settle — **ask your implementation contact; do not
  assume either way.**
- **"Custom fields" in this file means a per-merchant field-*definition* schema.** It is not the same
  concept as the per-transaction `customFields[]` key/value array documented in
  `map-card-transactions.md` and `map-rest-transactions.md`. A merchant defines a field once — name,
  type, validation rule, display flags — and a transaction later supplies a value against that schema.
  The two are structurally different shapes, not two names for one thing.
- **IBX scopes access on this surface more loosely than Payroc does, and that difference is a
  migration risk in its own right.** Across `/merchants`, `/users` and `/registers`, what an IBX
  caller can reach is not always limited to the records under its own account. Payroc scopes these
  reads to the merchants and terminals linked to your account. **So an integration that today reads
  records outside its own account will not behave the same way after the port** — and it may be doing
  so without anyone having intended it. Before you map this surface, establish which records your
  integration actually reads, and raise anything outside your own account with your Payroc
  implementation contact rather than designing around it.
- **Several write operations have no validation layer at all** — `DELETE` and `GET` custom-field, for
  two examples. Where a required field is simply missing, the runtime throws an unhandled `500` rather
  than a clean `400`. Treat every "declared optional, actually crashes if absent" finding below as the
  same family as the declared-optional-but-actually-required pattern that `map-tokens-and-vault.md`
  documents, **one step worse: a crash, not a clean rejection.**
- **Every IBX-side defect in this file is documented rather than currently re-confirmed.** They were
  observed and recorded during engineering testing and have not been re-confirmed against a live system
  recently. Treat them as *documented*, not as *currently true*, and re-check any one you
  intend to build on.

## `/merchants`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST GET /merchants` (list) | absorbed | `listMerchantPlatforms` (best guess — not field-mapped) | — | — | unverified |
| `REST GET /merchants/{merchantKey}` | absorbed | `getMerchantPlatform` (best guess) | — | `SCOPE:` IBX does not confine this read to the merchants under the calling account; Payroc does. Check which merchants your integration reads here before you map it — see cross-cutting facts. | verified (the IBX behaviour) / unverified (the Payroc pairing) |
| `REST POST /merchants` | config | `createMerchant` (`POST /merchant-platforms`) — an asynchronous application, not a synchronous create; see cross-cutting facts | `+business`, `+processingAccounts[]` (owners, pricing, `merchandiseOrServiceSold`) — a materially different and much richer intake shape | `SEMANTIC:` **the IBX call itself returns `500 "This method has been deprecated"` unconditionally.** It never worked as a synchronous create in the first place, so nothing is being taken away here. | verified (the IBX deprecation) / inferred (the Payroc target — a real operation, but review-gated) |
| `REST PUT /merchants/{merchantKey}` | config | `—` — no update path within the boarding API is mapped here; **escalate to your implementation contact** | n/a | `SEMANTIC:` also returns `500 "This method has been deprecated"`, the identical message `POST` returns. The write surface is deprecated in whole, not in part. | verified |
| `REST DELETE /merchants/{merchantKey}` | config | `—` — **escalate to your implementation contact** | n/a | The same deprecation defect again, the third of the three write verbs to return the identical message. | verified |

## `/merchants/customField` and `customfields.asmx`

**This is not a `{merchantKey}` path segment.** The real REST path is the literal
`/merchants/customField` for all four verbs; `MerchantKey` travels as a query, form-data or body
parameter, **never in the URL**. If you search your codebase for `/merchants/{id}/customField` you
will not find these calls.

Both surfaces define per-merchant custom-field schemas (see cross-cutting facts). Every SOAP row below
is reasoned through its REST twin rather than confirmed independently — the SOAP handler's behaviour
has not been established.

**The values held in a custom field are not passed to the processor.** An IBX custom field is a
gateway-side annotation: what a transaction stores against one is held by the gateway, surfaced in
its transaction reporting, and — where the field's own display flags say so — rendered on receipts
and hosted pages. It is not forwarded to the processor. **If any part of your integration relies on
a custom field to carry information downstream to the processor, it was not doing that** — establish
what actually depends on these values before you plan a Payroc equivalent for them.

**The REST create and update refuse numeric definitions that IBX's own parameter list appears to
allow.** On `POST` and `PUT /merchants/customField`, a negative `MinValue` or `MaxValue` is refused,
a `MaxLength` of zero or less is refused, and `DecimalPlaces` may not be negative. **Each bound binds
only a value you actually send**, and all four are documented optional. That parameter list gives
them as optional numeric values and states none of these bounds, so a field definition that reads as
legal against the documentation can still be refused. **Do not carry this onto the
`customfields.asmx` rows** — as noted at the top of this section, nothing about that surface's
behaviour has been established.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST POST /merchants/customField {MerchantKey}` | config (positive framing — see the `CFG:` note) | `—` | n/a | `CFG:` **this is a simplification, not a gap.** Payroc's per-transaction `customFields[]` (see `map-card-transactions.md` and `map-rest-transactions.md`) accepts arbitrary key/value pairs with **no pre-registration schema of any kind**, so you keep the underlying capability without needing this administrative step at all. On the IBX side, `500 "A field with this name already exists"`, `"Merchant must belong to reseller"` and `"FieldName must be alphanumeric"` are all real, tested 500s for what should be 400s. | verified |
| `REST PUT /merchants/customField {MerchantKey}` | config — the same simplification as `POST` above | `—` | n/a | **Update's error shapes are the opposite of Create's, so do not carry `POST`'s messages across.** The update validator has no uniqueness rule and no alphanumeric rule at all. Its real 500s are `"A field with this name is not found."` — returned both for a nonexistent field and for one belonging to another merchant — and `"Merchant must belong to reseller."` | verified |
| `REST DELETE /merchants/customField {MerchantKey}` | config — same | `—` | n/a | `SEMANTIC:` **no validator exists for this operation at all.** Omitting the required `MerchantKey` produces `500 "Merchant not found"`, not a clean validation error. | verified |
| `REST GET /merchants/customField {MerchantKey}` (list) | config — same | `—` | n/a | `SEMANTIC:` no validator exists here either, and a merchant with **zero** custom fields returns `500 "Merchant must belong to reseller"` — a wrong error message for an empty result, rather than an empty list or a 204. | verified |
| `SOAP customfields.AddCustomField` | config — same target family as REST `POST` above | `—` | n/a | The SOAP twin of the REST create, paired on matching field shapes (`FieldName`, `IsNumeric`, `DecimalPlaces`, `MaxLength`, `RegEx`, `IsRequired`, `MinValue`/`MaxValue`, display flags). Behavioural parity with the REST verb is not confirmed. | unverified (a field-shape match only) |
| `SOAP customfields.UpdateCustomField` | config — same | `—` | n/a | Same caveat as `AddCustomField`. | unverified |
| `SOAP customfields.DeleteCustomField` | config — same | `—` | n/a | Same caveat. | unverified |
| `SOAP customfields.GetCustomFields` | config — same | `—` | n/a | Same caveat. | unverified |

## `/users`

**No Payroc target of any kind is known for API-user or credential management, and every row
below is `none` / escalate. This is not a confirmed absence** — a Payroc facility for this concept
may exist. **Escalate it to your implementation contact rather than telling the developer the
capability is lost.**

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST POST /users` | none (target undetermined — escalate) | `—` | n/a | `SEMANTIC:` `userSecurityLevel`'s validation pattern is `^[1..4]$` — a **character class**, not a range — so `2` and `3` are **rejected** while a literal `.` is **accepted**. A real defect in the running platform, not a documentation gap. If you are migrating user records, your existing security levels may not be the ones you think. | verified |
| `REST GET /users/{userKey}` | none (same status — escalate) | `—` | n/a | `SCOPE:` IBX does not confine this read to users under the calling merchant — the same scoping difference as `/merchants` and `/registers`, see cross-cutting facts. | verified |
| `REST PUT /users/{userKey}` | none (same status — escalate) | `—` | n/a | `SEMANTIC:` `status`'s validator message says the value "must be between 1 and 3", but the rule actually applied is an inclusive 0-to-3 range, so `0` passes despite the message forbidding it. Separately, `contactState` and `contactCountryCode` values absent from IBX's own reference tables throw an unhandled `500` (a raw database exception) rather than a 400 — neither field has any validator rule. | verified |
| `REST DELETE /users/{userKey}` | none (same status — escalate) | `—` | n/a | This is a soft delete (`status` → `INACTIVE`), with the same scoping difference as `GET` above. A deleted user then returns 404 on `GET` rather than returning a closed record, so you cannot read back what you deactivated. | verified |

## `/registers`

**Payroc has no self-service register CRUD at all.** Its nearest concept, the processing terminal,
exposes only `getProcessingTerminal`, `getProcessingTerminalHostConfiguration` and `closeBatch` (see
`map-batch-and-settlement.md`) — **no create, update or delete of any kind.** A terminal is
provisioned only through `createTerminalOrder`, part of the boarding flow that orders physical
hardware, never through a post-boarding runtime call. **This is a structural loss, not a cardinality
guess** — you can check it yourself against the public documentation for the processing-terminal
resource.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST POST /registers` | none | `—` — the nearest route is boarding-time `createTerminalOrder`; **escalate to your implementation contact if you create registers at runtime today** | n/a | `LOSS:` IBX's register creation is self-service and callable by any `Merchant`-role API user at any time. Payroc's nearest concept is boarding-time hardware ordering, not a runtime API call. **A real structural loss, not a missing field.** `SEMANTIC:` IBX documents `registerNum` as auto-generated if not supplied, but the runtime validator requires it to be non-empty — a documentation-versus-runtime conflict that is not settled either way, so do not rely on the auto-generation. `ebtTerminalNumber` is also required non-empty, so there is no way to create a register without one. | verified (both the IBX validator behaviour and the Payroc-side absence) |
| `REST GET /registers/{registerKey}` | absorbed | `getProcessingTerminal` (best guess) | — | `SEMANTIC:` sending any body on this `GET` makes the IBX call fail with a server error rather than a clean rejection — worth knowing if your HTTP client attaches an empty JSON body to `GET` requests by default, because the same client will behave differently against Payroc. `SCOPE:` IBX does not confine this read to registers under the calling merchant; see cross-cutting facts. | verified (the IBX behaviour) / unverified (the Payroc pairing) |
| `REST PUT /registers/{registerKey}` | none | `—` — **terminal settings are not editable through the API.** You can read a terminal with `getProcessingTerminal` and `getProcessingTerminalHostConfiguration`, but there is no update operation. Ask your Payroc implementation contact how to change a terminal's configuration after boarding and how long a change takes. **If your application edits register settings at runtime today, that becomes a request to Payroc rather than a call your code makes** — a design constraint on your product, not a slower API | n/a | No update operation exists on Payroc's processing-terminal family at all. | verified (the absence) |
| `REST DELETE /registers/{registerKey}` | none | `—` — **there is no self-service delete for a terminal.** Ask your Payroc implementation contact how to retire a terminal you no longer use, and what happens to its transaction history. **Raise any registers you have already deleted on IBX in the same conversation:** its delete was one-way, leaving the register permanently unreachable through the API, so those will need handling out of band | n/a | This is a soft delete (`status` 1 → 2), and **once a register is inactive both `GET` and `PUT` on it return `500 "Unexpected error, please contact customer support"`** rather than a 404 or 409 — an unrecoverable-via-API soft delete on IBX's own side. No Payroc equivalent exists regardless, since terminals are not self-service-deletable there either. | verified |

## `/optimizations` (Interchange Optimization)

IBX's `/optimizations` is a **per-merchant stored default** for the Level-2 and Level-3 commercial-card
qualification line-item data — not a per-transaction submission. **Payroc has no stored-default concept
anywhere.** The closest schema shape is `order.itemizedBreakdownRequest` / `lineItemRequest`, which is
sent fresh on **every** transaction.

> **Confirm the field names above before you build on them.** `order.itemizedBreakdownRequest` /
> `lineItemRequest` are Payroc **payment-request** shapes, and this file does not own their schema.
> The payment task skill's request reference does.

**Do not conflate this with two other things that share the word "interchange."** Payroc's pricing
plans include "interchange…" plan types — that is a merchant fee schedule. Payroc's transaction
responses carry `interchange.basisPoint` and `transactionFee` — those are fees actually charged.
Neither is the qualification line-item data this section is about.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST POST /optimizations` | partial | `order.itemizedBreakdownRequest` / `lineItemRequest`, resent per transaction (confirm the field names — see the section note above) | — | `LOSS:` the capability moves from "configure once, applies automatically" to "must be resent on every transaction" — **a structural mismatch, not a rename.** Budget for it in the integration, not in a field map. `SEMANTIC:` **all four validators on this IBX resource are empty and validate nothing.** A genuine `500 SQLException` is documented on this operation — a `NULL` inserted into a `Prefix` column that the request body does not mention, the code never assigns and the database has no default for — **but a `200 OK` success is documented for the same operation, and the two are not reconciled anywhere.** State it as: a real defect is documented; whether it is universal or conditional is unverified. | verified (the empty validators, and that the 500 is documented) / unverified (whether the 500 is universal or conditional) |
| `REST PUT /optimizations` | partial — the same target and the same caveats as `POST` above | `order.itemizedBreakdownRequest` / `lineItemRequest` (confirm the field names — see the section note above) | — | The same `LOSS:` as `POST`. The same unreconciled 200-versus-500 tension, documented independently for the update verb. | verified (the empty validator, and that the 500 is documented) / unverified (whether it is universal) |
| `REST GET /optimizations` | none | `—` — **there is no server-side copy to read back.** Level-2 and Level-3 line-item data is sent on each payment rather than stored against your merchant record, so your application holds the values it sends — read them from your own configuration. Ask your Payroc implementation contact to confirm which line-item fields your card brands and processor require for Level-2 and Level-3 qualification, so you can check your stored values against that list before you migrate. **This does not make the fields optional** — only unstored | n/a | No Payroc query exists for a stored default Payroc does not hold. On the IBX side the call is documented as working: a 200, or a 404 record-not-found when nothing is configured. | verified (the IBX-side behaviour) |
| `REST DELETE /optimizations` | none | `—` — **there is nothing to delete.** Because the line-item values travel on each payment rather than being stored against your merchant record, you turn interchange optimization off by no longer sending those fields and on by sending them again. If you need to know what your IBX merchant record currently holds before you cut over, ask your Payroc implementation contact. **The fields do not become optional in a compliance sense** — the on/off switch just moves into your own request-building code | n/a | Same reasoning as `GET`. On the IBX side the call is documented as working, returning 204. | verified (the IBX-side behaviour) |

## `resellerbuilder.asmx` — reseller and ISV provisioning

**Everything about this operation's actual behaviour is unverified.** Only its declared schema is
known: a reseller name, tax IDs, address fields, white-label branding fields and a reseller user name,
returning a bare `string`. No runtime behaviour has been established for it at all — treat the field
list below as a declaration, not as a description of what the service does.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP resellerbuilder.CreateReseller` | none (target undetermined — escalate) | `—` | n/a | Payroc's boarding model has an implicit ISV and partner tier — merchant platforms are described as linked to your ISV account — but **the Payroc API exposes no operation to create or manage that tier itself.** It is presumably provisioned by Payroc directly, out of band. **Escalate for a product answer rather than asserting either absorption or absence with confidence.** | unverified (the entire operation — the field list is declared schema only, never confirmed against real behaviour) |

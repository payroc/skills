# IBX → Payroc: native REST transactions — `/transactions`, `/authholds`, `/current-requests`

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> IBX's **native REST** transaction API — `POST /transactions`, `/authholds` and `/current-requests` —
> to the Payroc API. Per-row confidence is carried in the `C` column; the legend is in
> [`_sources.md`](./_sources.md). Last synced: 2026-09-04. Read mappings from this file, not from
> memory — a plausible-sounding mapping that isn't here will look correct in review and fail in
> production.

```text
IN:  IBX's native REST transaction API, taking RAW card and check data: POST /transactions
     (every operation is a transactionType value on one flat POST), /authholds
     (GET/POST/DELETE) and /current-requests (GET/PUT/POST/DELETE).
OUT: THE PROTOCOL DISTINCTION IS THE POINT OF THIS FILE. A "card sale" exists on three
     different IBX surfaces and they are three different mappings. SOAP card sale --
     transact.asmx / transact2.asmx ProcessCreditCard -- is map-card-transactions.md, NOT
     this file, even though the tokens (Sale, Auth, Return, Void, Force, CaptureAll ...)
     have the same names here. REST card sale against a VAULTED TOKEN --
     /cardsafe/processcreditcard, /cardsafe/processcheck -- is map-token-payments.md, not
     this file; this file is the raw-data REST path only. Check the transport and the
     credential shape of the call in front of you before using any row below. Also out:
     SOAP debit/EBT -- map-debit-and-ebt.md. REST /batch/* -- map-batch-and-settlement.md.
     REST /reporting/* -- map-reporting-and-search.md.
ADJACENT: identifier-translation.md holds cross-cutting identifier, amount, expiry,
     currency and result-semantics facts, cited from the rows below rather than restated
     per row. If your call is not in the table below, it is not absent from IBX -- check
     map-card-transactions.md and map-token-payments.md first, then SKILL.md's routing
     table, then ask for a request sample.
```

**Where to implement what you find here:** `run-a-card-sale` for `Sale`, `run-a-pre-authorization` for
`Authorization`/`Capture`/`Increment`/`Adjustment`, `refund-a-card-payment` for `Return`/`Void`/`Reversal`,
and `take-an-ach-payment` / `refund-an-ach-payment` / `verify-bank-account` for the check-flavoured
rows. This file owns the delta; those skills own the request schema.

## Cross-cutting facts

Stated once here; see `identifier-translation.md` for the full detail.

- **Card expiry is `MMYY` on both platforms; `order.currency` cannot come from any IBX request on any
  surface; `PNRef` bridges to Payroc through `order.orderId` on write and `listPayments?orderId=` on
  read** — exactly as on the SOAP surfaces.
- **Convert amounts to minor units by ×100 only for two-decimal currencies.** Payroc's `order.amount`
  is in the currency's lowest denomination and its currency enum includes zero-decimal (`JPY`, `KRW`)
  and three-decimal (`BHD`, `KWD`) entries. Because currency resolves from configuration rather than
  from the request, confirm the terminal's currency first — otherwise the error is 100×.
- **HTTP 200/201 is not "approved" on this surface either.** The transaction response carries its own
  `resultCode`/`resultText`; branch on those, never on the HTTP status. This is the same hazard as the
  SOAP surface's `Result=0`, unchanged.
- **`/transactions` compares `transactionType` ordinally, so a wrong-case token is accepted, not
  rejected.** The comparison is an exact match against the underlying constant. A token with the wrong
  casing matches no constant, falls out of **every** validator guard, and the request is **accepted
  with its `originalTransaction`/`pnRef` check skipped**. There is no 400 to tell you about it: the
  call fails later, downstream, not at the API boundary. **Emit the exact documented casing**, and
  audit any existing integration that does not.
- **Real IBX request samples mix casings on these tokens** — `adjustment` and `return` appear
  lower-case on card requests while the comparable check `Return` request is capitalised. If the real
  token constants are PascalCase, which is consistent with every other observed token, those samples
  are already exercising the ordinal-comparison behaviour above rather than merely illustrating a risk
  a customer could stumble into. **Unverified** — flagged so you check your own traffic's casing, not
  confirmed.
- **A shared-method bug gives card `Return` and check `Return` opposite `originalTransaction`
  requirements.** One private validation method serves both branches, gated on the transaction type
  not being `"Return"`. The card branch calls it with the literal string `"Return"`, so the guard is
  always false and **a card `Return` never requires `originalTransaction` on this endpoint** — by
  accident of that call site, not by design. The check-payment branch calls the same method with an
  empty string, so **a check `Return` does require it.** Same method, one bug, two opposite real-world
  requirements. Do not assume the asymmetry is deliberate API design; it is a defect with a real
  behavioural consequence either way.
- **`Force`'s own validation-failure message is unusable — never quote this endpoint's error text as
  a source for anything.** An operator-precedence bug in the message expression makes its condition
  always false, so the message is always the headless *"is required for a Force transaction"*
  regardless of what was actually missing.
- **No free-text `ExtData`-equivalent catch-all exists on this endpoint at all** — a real structural
  difference from the `transact` and `cardsafe` surfaces. The only "extra data" mechanism is the
  typed, bounded `customFields[]` array; there is no arbitrary-tag passthrough of the kind
  `map-card-transactions.md` covers. A customer relying on an undocumented `ExtData` tag elsewhere in
  IBX has no equivalent smuggling path here — which is not a loss, since this endpoint never offered
  the mechanism to begin with.
- **`Level3Data`/`Level2Data` are real, well-formed, and belong exclusively to this endpoint** — no
  other IBX operation anywhere references either schema. `Level3Data` is declared but is **not
  exercised in any observed request**; `Level2Data` is genuinely exercised
  (`taxAmount`, `taxExempt`, `poNumber` are all wire-confirmed).
- **`entryMode` here is not the same finding as `map-token-payments.md`'s `cardsafe` one — do not
  conflate them.** Every observed `/transactions` request body uses `entryMode:"Manual"`; `"COF"`,
  `"swipe"`, `"ICC"` and `"Proximity"` do not occur anywhere in this endpoint's request evidence. The
  undocumented `COF` value belongs to `cardsafe`'s own REST validator and does not reproduce here. The
  validator's `swipe` branch (requiring `cardNumber`/`expirationDate`/`trackData`) is real code with
  **zero wire evidence**, so treat it as `inferred`, not `verified`.

## `POST /transactions`

The only verb on this path — every operation is a `transactionType` value on one flat POST, not a
separate sub-resource. Eleven tokens have a named validator branch; two more (`PostAuth`, `Increment`)
are wire-confirmed but absent from all eleven — the same open question `map-card-transactions.md` flags
for the SOAP surface, and equally unresolved on this one.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST POST /transactions {transactionType=Sale}` | absorbed | `payment` + `autoCapture:true` | — | — | verified (a named dispatch branch exists) / inferred (the Payroc pairing — shape match only) |
| `REST POST /transactions {transactionType=Authorization}` | absorbed | `payment` + `autoCapture:false` | — | — | verified (dispatch) / inferred (the Payroc pairing) |
| `REST POST /transactions {transactionType=Return}` | branch (card) — see cross-cutting facts for why this branch never actually requires a reference | `refundPayment` (referenced) \| `unreferencedRefund` (unreferenced, `+refundMethod`/`+description` per the schema shapes in `map-token-payments.md`) | — | `SEMANTIC:` per cross-cutting facts, a shared-method bug means **card `Return` never requires `originalTransaction` on this endpoint at all** — not a design choice. Treat this as effectively always the unreferenced path unless the caller supplies a reference voluntarily. | verified (the validator bug and its consequence) / inferred (the Payroc pairing) |
| `REST POST /transactions {transactionType=Void}` | direct — cancels a payment before settlement; no funds taken | `reversePayment` | — | — | verified (dispatch) / inferred (the Payroc pairing) |
| `REST POST /transactions {transactionType=Reversal}` | **inferred pairing, not a direct equivalent** — an IBX `Reversal` may arrive after the batch has settled, and `reversePayment` covers only a payment in an open batch | By that payment's `supportedOperations`, first match wins: (1) a partial amount and `partiallyReverse` listed → `reversePayment` with `amount` \| (2) the full amount and `fullyReverse` listed → `reversePayment` \| (3) neither reverse token listed and `refund` listed → `refundPayment` with `amount` \| (4) anything else → escalate | On the `refundPayment` route, `+amount` and `+description` (both required) | `IF:` **route by the Payroc payment's state, not by the IBX token.** Read that payment's current `supportedOperations` (see `identifier-translation.md`) and take the first branch in the target cell that matches. `reversePayment` cancels all or part of a payment in an open batch; it is scoped to an open batch, and Payroc documents no specific error for calling it on a settled payment, so do not call it for this token without that read, and do not rely on a wrong route being rejected. Payroc also documents that a refund against a payment still in an open batch reverses the payment, but not what a **partial** refund does there, so if branch (3) ever carries a partial amount, confirm the result in UAT before relying on it. | verified (dispatch) / inferred (the routing onto `refundPayment` or `reversePayment`) |
| `REST POST /transactions {transactionType=Force}` | absorbed | `payment` + `offlineProcessing.operation` (unresolved carry-over, same as the SOAP and `cardsafe` surfaces) | `+offlineProcessing.operation` | See cross-cutting facts — never quote this endpoint's own `Force` error message. | inferred |
| `REST POST /transactions {transactionType=RepeatSale}` | absorbed | `payment` + `order.standingInstructions` | Same unresolved sub-field question as `map-card-transactions.md`'s `RepeatSale` row | — | inferred |
| `REST POST /transactions {transactionType=Adjustment}` | absorbed | `adjustPayment` (sub-type unresolved — the same guess as `map-card-transactions.md`'s raw-card `Adjustment`, on **weaker** evidence than `map-token-payments.md`'s tip-specific finding, because this endpoint's validator does not name a required `invoiceData.tipAmount` the way `cardsafe`'s does) | — | `IF:` requires `originalTransaction` (standard validator branch — the `Return` bug above does not apply here). See the casing hazard in cross-cutting facts: this is one of the two tokens real request samples send lower-case. | verified (the requirement) / inferred (the sub-type) |
| `REST POST /transactions {transactionType=Capture}` | direct — captures a pre-authorization; funds are taken | `capturePayment` | — | — | verified (dispatch) |
| `REST POST /transactions {transactionType=CaptureAll}` | absorbed (best-supported placeholder — the mechanism is `unverified` and is **not** established for this endpoint) | `closeBatch` (`POST /processing-terminals/{id}/close-batch`) | — | Whether this endpoint's `CaptureAll` shares the fabricated-queued-response hazard documented on the SOAP surface in `map-card-transactions.md`, the plain synchronous shape in `map-debit-and-ebt.md`, or something else entirely is **unverified** — nothing beyond the validator naming the token is established for this dispatch path. **Do not resolve this row from `map-batch-and-settlement.md`'s `ProcessBatch` single-call finding** — that operation dispatches through different code and its conclusion does not transfer here. Treat the Payroc target as an unconfirmed best guess, not a corrected fact. **`LOSS:` separately, even if `closeBatch` is the eventual target:** its documented scope is settling the transactions **captured** since the last close, not a capture-everything step. A customer with pending uncaptured `Auth`/`Authorization` transactions may not get them captured by `closeBatch` alone, whichever dispatch path this endpoint turns out to use. **Default: call `capturePayment` on each pending authorization, then `closeBatch`** — safe whichever dispatch path applies; see `map-batch-and-settlement.md`. Do not assume `closeBatch` alone reproduces this token's legacy behaviour. | **unverified** (both the IBX-side behaviour and the Payroc-side target) |
| `REST POST /transactions {transactionType=Inquire}` | none (target undetermined, **not** confirmed absent — escalate) | `—` | n/a | Same undetermined status as `map-card-transactions.md`'s raw-card `Inquire` — do not guess a target. | unverified |
| `REST POST /transactions {transactionType=PostAuth}` | absorbed | `payment` + `offlineProcessing.operation:deferredAuthorization` (a lexical guess, the same one as `map-card-transactions.md`) | `+offlineProcessing.operation` | Wire-confirmed but **absent from the validator's eleven named branches** — it falls through to whatever the default/unnamed path does, which is not established. | unverified (dispatch — no named branch found) / inferred (the Payroc target, carried from `map-card-transactions.md`) |
| `REST POST /transactions {transactionType=Increment}` | absorbed | `adjustPayment` with `adjustments[].type:order` (unconfirmed sub-type, the same guess as `map-card-transactions.md`) | `+type:order` | Same status as `PostAuth` above — wire-confirmed, no named validator branch. | unverified (dispatch) / inferred (the target) |

### Level 3 / Level 2 / EMV request-delta detail (applies to the `Sale`/`Authorization`/`Capture` rows above)

| Field | Payroc target | Note |
|---|---|---|
| `level2Data.{poNumber,taxAmount,taxExempt}` | `order.itemizedBreakdownRequest` (top-level fields) | inferred (shape match; wire-confirmed on the IBX side) |
| `level3Data.lineItems[].{productCode,commodityCode,description,unitOfMeasure,unitPrice,quantity}` | `order.itemizedBreakdownRequest.items[]` (`lineItemRequest`) | inferred (the Payroc schema is confirmed; the IBX side is declared but not exercised in any observed request) |
| `level3Data.lineItems[].{dutyAmount,freightAmount}` | `order.itemizedBreakdownRequest.{dutyAmount,freightAmount}` — **but Payroc puts these at the order header and IBX puts them per line item** | `LOSS:` a multi-line-item IBX transaction with per-line duty/freight has no lossless Payroc target for that granularity — escalate, don't silently sum or drop |
| `level3Data.{shipFromZip,destinationZip}` | `—` | `LOSS:` no Payroc target found anywhere in the transaction schema family — a genuine loss candidate, not a rename |
| `level3Data.{invoiceNumber,orderNumber}` | contends with `order.orderId` (the identifier-bridge field, ≤24 characters — see `identifier-translation.md`) | `SCOPE:` IBX carries three logically distinct identifiers here (the migration bridge key plus IBX's own two) against Payroc's single slot — unresolved; do not assert a collapse without checking with your implementation contact |
| `cardData.emvData` (opaque string) | `paymentMethod.iccCardDetails.iccData` (the closer wire-shape match — a single hex TLV string) **or** `card.emvTags[]` (pre-parsed tag/value pairs) | inferred, likely `iccCardDetails.iccData` on shape grounds only — escalate rather than asserting either as confirmed |

### Check-payment (`checkData`) request-delta detail (applies to the check-flavoured `Sale`/`Return`/`Void` rows above)

`checkData.{transitNumber,routingNumber,accountNumber}` map to `bankTransferPayment`'s bank-account
schema — ACH-style `accountNumber`+`routingNumber`, or check/PAD-style
`accountNumber`+`transitNumber`; both forms exist. `checkData.nameOnCheck` has a defensible rename,
`nameOnAccount`, in the same schema — **not** a loss.

`LOSS:` **six fields have no Payroc target found: `micr`, `ssn`, `driversLicenseState`,
`driversLicenseNumber`, `checkType` and `checkNumber`** (the physical check's own serial number).
Together these read as a genuine paper-check-verification capability — MICR line, driver's licence,
SSN, check serial number — that Payroc's ACH-oriented surface has no equivalent for. **Flag these six
specifically, not the whole `checkData` object** — the core account-number and name fields do have a
home. This absence was established against Payroc's transaction schemas and not against its published
prose documentation, so **confirm it at `https://docs.payroc.com/` before treating any of the six as a
final loss.**

## `/authholds` — a fraud-review queue, not a generic authorization-hold API

**Do not map this as `absorbed` into `payment` + `autoCapture:false`** — that would be exactly the
"shape match is not a behaviour match" trap. This is a **manual fraud-review action queue**: `GET`
lists holds pending review (`userName`, `password`, `rpNum`), `POST` resubmits a batch by `pnRefs`,
`DELETE` declines a batch by `pnRefs`. Credentials travel **in the request body itself on all three
methods**, not in the `Bearer` header every other operation uses.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST GET/POST/DELETE /authholds` (list/resubmit/decline a fraud-review queue) | none (target undetermined, **not** confirmed absent — escalate) | `—` | n/a | `SEMANTIC:` this is a fraud-ops review workflow (list → resubmit or decline), not a hold-management CRUD surface. The Payroc side was searched broadly and turned up **adjacent-but-non-equivalent** material rather than nothing: fraud-prevention marketing copy, an AVS/KYC glossary entry, and an issuer decline reason (`suspectFraud`) — none of which describes a manual review/resubmit/decline queue. Payroc's payment-status enum (ready, pending, declined, complete, referral, pickup, reversal, returned, admin, expired, accepted) carries no explicit hold or review value; `referral` is the nearest conceptual neighbour without being a queue state. **This was not exhaustively searched across every webhook event** — a missing endpoint is not a missing capability. **The IBX side's own liveness is also unconfirmed:** no request to this surface has been observed, and IBX's one dedicated integration-test file for it is entirely commented out, with every body unimplemented. | unverified (both the Payroc-side gap and whether this IBX surface is live at all) |

## `/current-requests/{Tag}/cancel` — likely framework infrastructure, not an IBX business capability

Four methods, all operating on one generic `CancelRequest{Tag:string, Meta:Dictionary<string,string>}`
shape. **No security scheme is declared on any of the four** (71 of 84 other operations declare
`Bearer`; these four don't), there are **zero references to `CancelRequest`/`CurrentRequest` anywhere
beyond the bare schema**, and there are no request samples. The shape carries no domain field at all —
no `PNRef`, and none of the batch or queue vocabulary of the `CaptureAll` fabricated-queue mechanism
described in `map-card-transactions.md`, so nothing on this path supports reading it as part of that
mechanism.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST GET/PUT/POST/DELETE /current-requests/{Tag}/cancel` | none — likely not an IBX business capability at all | `—` | n/a | `SEMANTIC:` the generic `Tag`+`Meta` shape, the absent security scheme (13 of 84 operations lack one; these 4 are among them), and the total absence of business-domain references together suggest this is ServiceStack's stock cancellable-long-running-request infrastructure rather than a purpose-built IBX feature. **That verdict rests on the schema's own genericness and on the absence of domain references — not on a second independent source.** If your integration genuinely calls this path, escalate rather than trusting this row's conclusion. | unverified |

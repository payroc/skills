# IBX → Payroc: batch and settlement — `ProcessBatch`, `batchinfo`, `settlementinfo`, REST `/batch/*`

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> IBX's batch and settlement surfaces — `transact`'s `ProcessBatch`, the `batchinfo` and
> `settlementinfo` SOAP services, and the REST `/batch/*` endpoints — to the Payroc API. Per-row
> confidence is carried in the `C` column; the legend is in [`_sources.md`](./_sources.md). Last
> synced: 2026-09-09. Read mappings from this file, not from memory — a plausible-sounding mapping
> that isn't here will look correct in review and fail in production.

```text
IN:  SOAP transact.asmx ProcessBatch (and its transact2 twin); batchinfo.asmx;
     settlementinfo.asmx; REST /batch/*.
OUT: transactiondetail.asmx, trxdetail.asmx, imageretrieval.asmx and REST /reporting/* --
     map-reporting-and-search.md. /reporting/AccountUpdater -- map-tokens-and-vault.md.
     Every payment type's OWN Capture/CaptureAll row -- map-card-transactions.md,
     map-debit-and-ebt.md, map-check-cash-and-stored-value.md, map-token-payments.md,
     map-rest-transactions.md. Those rows do NOT inherit this file's ProcessBatch finding.
ADJACENT: map-reporting-and-search.md holds the querying-and-retrieving half of this
     scope, including /reporting/SettlementDetail and /reporting/SettlementList, which are
     settlement-semantic but route there by path segment. map-card-transactions.md holds a
     DIFFERENT CaptureAll hazard from this file's ProcessBatch row -- the two are not the
     same defect and must not be conflated. identifier-translation.md holds cross-cutting
     identifier, amount, expiry and currency facts. If your call is not in the table below,
     it is not absent from IBX -- check the sibling files above, then SKILL.md's routing
     table, then ask for a request sample.
```

**Where to implement what you find here:** `view-settlement-batches` and `view-settled-transactions`
for batch and settlement reads, `view-authorizations` for pending pre-authorizations,
`view-ach-deposits` for funding, `view-disputes` for chargebacks. This file owns the delta; those
skills own the request schema.

## Cross-cutting facts

### `CaptureAll` → `closeBatch` — read this before mapping any batch-close volume

**`ProcessBatch`'s own `CaptureAll` dispatch is a single opaque call.** There is no enumeration, no
loop and no per-transaction `PNRef` list anywhere in it: it sets a transaction type and an `ExtData`
blob and makes one call into the processor bridge, which in turn builds one request body and makes
one call onward. Whatever "settle everything open" means happens downstream of that call, inside the
bridge, and is not established.

**Payroc's `closeBatch` is also a single call** — `POST /processing-terminals/{id}/close-batch`,
terminal-scoped, with no request body, returning `202` and a cut-off-time schedule rather than a
settlement result. Payroc's own published batch-close procedure is exactly that one POST, with the
batch identified only by the terminal so there is no `batchId` input, and with no `listPayments` or
`capturePayment` step in it. So at the dispatch layer **the two shapes simply match** — `absorbed`,
one call to one call, not a multi-step sequence. **This is a structural reading of both sides'
dispatch, not a comparison of a captured request pair** — the strongest available reading, not a
settled fact.

**That match is established for `ProcessBatch` only.** `ProcessCreditCard {TransType=CaptureAll}`,
`ProcessDebitCard {TransType=CaptureAll}` and REST `/transactions {transactionType=CaptureAll}`
dispatch through entirely different code, which this finding says nothing about, and their mechanism
is `unverified`. **Do not resolve those rows from this one** — they carry their own, different
hazard in `map-card-transactions.md`, `map-debit-and-ebt.md` and `map-rest-transactions.md`. This
file's own REST `/batch/batchsettle {TransactionType=CaptureAll}` row is in the same position: a
separate code path that does not inherit the finding either.

**A shape match is not a behaviour match, and here the difference is money.** `closeBatch`'s own
documented scope is settling the transactions **captured** since the last close — it does not itself
capture anything. IBX's `CaptureAll`, by contrast, puts a capture-everything sentinel on the wire (a
`Capture` element with `PNRef` set to `0`), baking a sweep-capture step into the same call that
closes the batch. **A merchant with pending, never-explicitly-captured `Auth` (`autoCapture:false`)
transactions who calls `closeBatch` alone, expecting `CaptureAll` parity, will not have those
transactions captured** — the amounts are silently never swept unless `capturePayment` is called per
pending payment first. This is a real gap, not merely an unconfirmed one, and it applies even on the
one row where the structural claim is solid. **How common an `Auth`-then-`CaptureAll` usage pattern
is among real IBX merchants cannot be settled here** — establish whether your own integration relies
on it before you port it, and confirm the plan with your Payroc implementation contact.

**The default for every `CaptureAll` row: capture each pending authorization, then close.** Find
the terminal's pending payments with `listPayments` (it carries a `status=pending` filter and a
separate, probably better-fitting `settlementState` filter, `unsettled`/`settled`), call
`capturePayment` on each one the merchant means to take, then call `closeBatch`. This is not a
description of how IBX's `CaptureAll` works internally, and Payroc's own batch-close procedure is a
single call with no capture step. It is the order that loses no money whichever way IBX's
behaviour turns out to be read, which is why the `CaptureAll` rows in this file and its siblings
point here. **Authorizations taken on IBX before cutover are the exception**: they have no Payroc
`paymentId`, so they have to be captured on IBX, one `PNRef` at a time, before IBX is switched off.
See `SKILL.md` Step 6.

**IBX's own data model appears to draw the same line.** IBX classifies a transaction as
settlement-eligible by transaction type, and an authorization awaiting capture is **not** in that
set; it is checked by a separate rule of its own. Whether IBX's batch close actually applies that
classification is not established, so do not read it as proof of what an IBX close did to your
pre-authorizations. Either way, a migration that assumes `closeBatch` sweeps them up is relying on
something Payroc does not document. **Plan the capture of outstanding pre-authorizations as its own
step on both sides.**

## `transact` — `ProcessBatch`

`ProcessBatch` forwards straight through to a single handler whose top-level dispatch supports
**exactly two transaction types**, `Capture` and `Inquire`; everything else is rejected with
`"Error - Unsupported Transaction Type"`.

**`PaymentType` is matched by substring against a 12-member internal enum — `Cash`, `Check`,
`CreditCard`, `DebitCard`, `EBTCard`, `Coupon`, `ACH`, `GiftCard`, `Batch`, `GetInfo`, `SetInfo`,
`Signature` — first match wins, and the comparison is case-sensitive on your input.** Only the enum
member name is upper-cased before the comparison; the value you send is used as-is against it, and
the match is ordinal. **A caller sending lower-case `"card"` matches nothing at all** — `"CREDITCARD"`
does not contain `"card"` — and falls through to `"Invalid PaymentType"`. That is a real trap for
exactly the kind of input a migrating SOAP integration might plausibly send. Upper-case `"CARD"` does
resolve, to `CreditCard` (the first member containing `CARD`) and never to `DebitCard`, `EBTCard` or
`GiftCard` — but only because it happened to be upper-case already. Empty or `"ALL"` defaults to
`CreditCard`.

**Only 6 of those 12 payment types can build a request body at all**: `CreditCard`, `DebitCard`,
`EBTCard`, `Check`, `GetInfo` and `Signature`. `Cash`, `GiftCard`, `Coupon`, `ACH`, `Batch` and
`SetInfo` have no builder branch, and there is no fallback branch either — an opening `<Transaction>`
tag is written before the branch is selected, so for these six the request goes out with an
unclosed, empty `<Transaction>` tag immediately followed by the envelope's closing `</Transactions>`.
It cannot be a valid request. Two consequences for the surfaces in
`map-check-cash-and-stored-value.md`: **`ProcessBatch {PaymentType=CHECK}` is a genuine working
alternate settlement route** for `ProcessCheck`'s unresolved `Auth`/`Capture`/`CaptureAll` rows,
because `Check` has a real branch; and **`ProcessCash`, `ProcessGiftCard` and `ProcessLoyaltyCard`'s
`none`/escalate verdicts stand even via this route**, because `Cash` and `GiftCard` do not. **This is
proven for the SOAP `ProcessBatch` call chain only — do not transfer it onto REST
`/batch/batchsettle`'s `PaymentType=EGC`**, which is a separate code path and unverified either way.

**IBX's two descriptions of `ProcessBatch`'s `PaymentType` disagree, and here it is the guide that
is wider.** The WSDLs list four values — `ALL`, `CREDIT`, `DEBIT`, `EBT`. The integration guide
lists five, adding `CHECK`. **On this value the runtime settles it in the guide's favour**: `CHECK`
reaches a real request builder, so the WSDLs' omission is a documentation gap rather than a missing
capability, and it is the same fact as the working alternate settlement route above. **That is a
result about `CHECK`, not about the two lists** — as the substring mechanism above shows, the
runtime accepts values in neither of them.

> **Do not adopt a rule that one of IBX's descriptions is authoritative for `PaymentType`.** The
> direction of the disagreement is not consistent: on `ProcessBatch` the guide is wider, on
> `GetCheckTrx` it is narrower, on `GetCardTrx` neither contains the other, and for the batch query
> operations the WSDL describes nothing at all. See `map-reporting-and-search.md` for the query
> side. **Confirm the specific values your integration sends, operation by operation.**

**For the batch query operations it is the WSDL that describes nothing** — the guide lists six
values (`ACH`, `ECHECK`, `GUARANTEE`, `PAYRECEIPT`, `SETTLE`, `VERIFY`) for three of the four, and
the service description says nothing at all. **That is undescribed, not contradicted**; there is no
second source to weigh it against. Note that IBX's own examples for those operations pass
`"Credit"` — a value in none of those six lists, and in the wrong case for `ProcessBatch`. Whether
those operations case-fold your input is **not established**; `ProcessBatch` does not, and that
behaviour must not be assumed to carry across. If you filter batch queries by payment type today,
verify each value returns what you expect before you rely on the results for reconciliation.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact.ProcessBatch {TransType=Capture, PNRef=<digits>}` | direct — settles one pre-authorized transaction; funds are taken | `capturePayment` | — | `SCOPE:` this route has **no `Amount` parameter at all** — unlike `ProcessCreditCard {TransType=Capture}` (see `map-card-transactions.md`), which does carry `Amount` and supports partial capture. `ProcessBatch`'s capture route can only ever be a full capture. That is a real behavioural difference between IBX's two routes to "capture", not a missing field to add. | verified |
| `SOAP transact.ProcessBatch {TransType=Capture, PNRef=<non-numeric or blank>}` (silently rewritten to `CaptureAll`) | absorbed (dispatch-shape match verified; the behaviour match has a known gap — see the cross-cutting note above) | `closeBatch` (`POST /processing-terminals/{id}/close-batch`) | — | `SEMANTIC:` **the promotion is unconditional.** The only gate is a single check that `PNRef` is all digits — no merchant flag, no configuration read, no database lookup — so `ProcessBatch {TransType=Capture, PNRef=""}` settles the whole open batch, for every merchant, always. `BatchID` **is** forwarded, folded into `ExtData` when non-blank; it is `BatchStatus` that is accepted, normalized and then never referenced again outside a log string — that one is the confirmed dead parameter. `SEMANTIC:` **`closeBatch` does not itself capture anything** — its documented scope is settling the transactions *captured* since the last close, while IBX's `CaptureAll` puts a capture-everything sentinel (`Capture` with `PNRef` `0`) on the wire. **A merchant with pending, never-explicitly-captured `Auth` transactions who calls `closeBatch` alone will not have them captured** — the funds are silently left uncaptured unless `capturePayment` is called per pending payment first. This is a real gap, not merely an unconfirmed one. How common that usage pattern is among real merchants is not settled here. | verified (the promotion mechanism, and the single-call dispatch-shape match at both layers) / unverified (the behaviour match — the capture-before-close gap above is not, and cannot be, ruled out from this material) |
| `SOAP transact.ProcessBatch {TransType=Inquire}` (silently rewritten to `BATCHINQUIRY`) | absorbed | `getbatches`/`getbatch` (`GET /batches`, `GET /batches/{batchId}`) | `ExtData` carries the tags `BatchSequenceNum`, `CardType`, `TID` and `ProcessingModifier` | — | verified (the dispatch) / inferred (the Payroc pairing) |

### `transact2` delta

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact2.ProcessBatch {TransType=Capture,Inquire}` | direct — the *same objects running the same code* | Same target as the corresponding `ProcessBatch` row above, for every token listed | Endpoint only: `/ws/transact2.asmx`. | — | inferred (`ProcessBatch` is one of the operations `transact2` exposes; that its forward is byte-for-byte the same has not been confirmed for this operation specifically) |

## `batchinfo`

This service's WSDL carries **no operation documentation at all** — a true absence, so there is no
declared contract to read behaviour from on the SOAP side.

**The "required even though it does not look required" pattern is confirmed on the REST batch
endpoints and is only a hypothesis here.** On the REST side, parameters the specification leaves
unmarked are in fact required, and omitting one returns `Result=1001`. **Nothing on the SOAP side
declares these parameters optional**, so do not read the SOAP rows below as saying you may omit
them: this service's WSDL says nothing about requiredness either way, and the integration guide's
own input-field tables open *"unless noted otherwise, the parameter is required"* and mark none of
these parameters optional. The one genuine ambiguity is `PaymentType`, whose guide entry also notes
a default of `ALL` when no value is set; the guide defines no notation legend, so that reading
cannot be closed either way. The SOAP operation names correspond
one-to-one with the REST ones (`GetBatchStatus`/`batchstatus`, `GetBatchDetail`/`batchdetail`,
`GetBatchNumbers`/`batchnumbers`), which makes the same pattern plausible here — **but the REST batch
service calls the settlement library and the database directly and never goes through SOAP, so the
two are architecturally separate paths and nothing on the SOAP side confirms it.** Treat it as a
carried-over hypothesis rather than a fact: send the fields, and expect a validation failure to be
your first real evidence either way.

The response payload itself travels inside the generic `ExtData`/`Response` envelope as ad-hoc XML —
for example `<BatchStatus><Message>Settled</Message><Response>GB47</Response></BatchStatus>` — rather
than in a typed schema. That too is directly confirmed only for the REST side.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP batchinfo.GetBatchStatus` | absorbed | `getbatch` (`GET /batches/{batchId}`) | `+batchNumber`/`+settleDate`/`+paymentType` — **send all three; do not treat any of them as optional.** Requiredness is confirmed on the REST twin and is a hypothesis here (see above) | `LOSS:` response fields arrive in an ad-hoc `ExtData` XML blob, not a typed schema, so there is no field-for-field contract to compare against `batch`'s typed response. | inferred (the Payroc pairing, a shape match only) |
| `SOAP batchinfo.GetBatchSummary` | absorbed | `getbatches` (`GET /batches`) | same requiredness position as the `GetBatchStatus` row above — and weaker still, because this operation does not appear in the integration guide at all | same `ExtData` caveat | inferred |
| `SOAP batchinfo.GetBatchDetail` | absorbed | `getbatch` | same requiredness position as the `GetBatchStatus` row above | same | inferred |
| `SOAP batchinfo.GetBatchNumbers` | absorbed | `getbatches` | `+startDate`/`+endDate`/`+paymentType` — **send all three**, same requiredness position as above. The guide lists `StartDate` in this operation's signature but omits it from the input-field table, so it carries no requiredness statement either way | same | inferred |

## `settlementinfo`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP settlementinfo.GetSettlementSummary` | partial | `getbatches` | — | `LOSS:` this response carries chargebacks alongside the batch summaries, and Payroc's does not — the same association loss described in full on the `GetSettlementDetail` row below. Read that row before you plan any per-batch chargeback reporting. | inferred |
| `SOAP settlementinfo.GetSettlementDetail` | partial | `getdisputes` (`GET /disputes`) → `gettransaction`, joined in your own code; `getbatch` for the batch half | `ID:` the batch identifier is a string here and an integer on Payroc's `getbatch` | `LOSS:` **you lose the link between a batch and its chargebacks, and Payroc cannot express it.** IBX returns batch data and its chargebacks together in one response, keyed on the batch you asked for. Payroc has no batch-to-disputes direction: `getdisputes` filters on date, merchant and pagination and **accepts no batch identifier**, a dispute carries no batch reference, and a batch links only to its transactions and authorizations. The **reverse** direction does exist — a dispute carries its transaction, and a transaction carries its batch — so per-batch chargeback reporting has to be rebuilt as: sweep `getdisputes`, follow each dispute's transaction, and read that transaction's batch. **Two things make that a redesign rather than a re-shape.** `getdisputes` requires a date, and that date is when the dispute was *submitted*, not the batch date, so you cannot bound the sweep by the batch you hold. And where Payroc cannot match a dispute to a transaction it omits the transaction id entirely, so those disputes cannot be attributed to any batch at all. **If per-batch chargeback reporting is a reconciliation requirement for you, raise it with your Payroc implementation contact before you design around it.** `SCOPE:` the disputes surface has exactly two operations — `getdisputes` and `getdisputesStatuses` (a status-history sub-resource with no amount, card, merchant or transaction fields). **There is no single-dispute-detail-by-id operation**, which you can check against the public documentation, so build the detail view from the list response. | inferred (the pairing is a structural read, not wire-confirmed) |

## REST `/batch/*`

**REST `/batch/batchsettle` is implemented by a different code path from SOAP `ProcessBatch`** — it
calls the settlement library directly rather than routing through the SOAP service. **Do not
transfer the SOAP `PaymentType`-reachability gap (`Cash`/`GiftCard` building no transaction body)
onto this endpoint; it is unverified here, not confirmed either way.**

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST GET /batch/batchsettle {TransactionType=Capture, PNRef=<digits>}` | direct | `capturePayment` | — | `SCOPE:` the validator forces `TransactionType=Capture` whenever `PNRef` is greater than zero. | verified |
| `REST GET /batch/batchsettle {TransactionType=CaptureAll}` | absorbed (best-supported placeholder — the dispatch mechanism is `unverified`; see the cross-cutting note above) | `closeBatch` | — | `SEMANTIC:` **a real, well-evidenced SOAP/REST divergence.** SOAP silently promotes `Capture`→`CaptureAll` on a blank or non-numeric `PNRef` (see the `ProcessBatch` row above). REST's validator **never auto-promotes** — with `PNRef` absent the caller must send `CaptureAll` explicitly or take a validation error. **An integration porting SOAP behaviour to REST that relied on the silent promotion will get a 400 instead.** `SEMANTIC:` **this row does not inherit `ProcessBatch`'s single-call finding.** This endpoint runs a separate settlement-library path, not the SOAP dispatch that finding covers, and how it handles `CaptureAll` is not established. A `CaptureAll` call against an empty batch is observed to return `200 OK — No Records To Process`, which is consistent with either a single opaque call that found nothing pending **or** an enumerate-and-settle model that enumerated zero records — it does not discriminate between them. The capture-before-close gap flagged on the `ProcessBatch` row applies here too, unverified either way. **Default: call `capturePayment` on each pending authorization, then `closeBatch`**, as the cross-cutting note above sets out. | verified (the absence of promotion logic in the validator) / unverified (the dispatch mechanism, and the capture-before-close gap — neither settled for this specific endpoint) |
| `REST GET /batch/batchstatus` | absorbed | `getbatch` (the same pairing as the SOAP `GetBatchStatus` row above) | the required-though-unmarked pattern is confirmed for this endpoint | same `LOSS:` ad-hoc-envelope caveat as the SOAP `batchinfo` rows | unverified (the request path itself — no validator available) / inferred (the Payroc pairing) |
| `REST GET /batch/batchdetail` | absorbed | `getbatch` | the required-though-unmarked pattern is confirmed for this endpoint | same `LOSS:` caveat | unverified (no validator available) / inferred |
| `REST GET /batch/batchsummary` | absorbed | `getbatches` | the required-though-unmarked pattern is **assumed here by grouping with `batchdetail`/`batchstatus`, not confirmed for this operation on its own** | same `LOSS:` caveat | unverified (no validator available, and the required-field pattern not independently confirmed for this operation) / inferred |
| `REST GET /batch/batchnumbers` | absorbed | `getbatches` | the required-though-unmarked pattern is confirmed for this endpoint, for `startDate`/`endDate`/`paymentType` | same `LOSS:` caveat | unverified (no validator available) / inferred |
| `REST POST /batch/batchupload` | none (target undetermined — escalate) | `—` | An **undeclared multipart file** is required alongside the documented `processTimeSchedule` and `failOnBadRecord` body fields — a real specification gap, not a field-name mismatch, so a request built from the published schema alone will fail. | No Payroc bulk-upload equivalent is known — **escalate to your Payroc implementation contact rather than treating this as a confirmed absence.** | unverified |

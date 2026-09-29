# IBX → Payroc: reporting and search — `transactiondetail`, `trxdetail`, `imageretrieval`, REST `/reporting/*`

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> IBX's query and retrieval surfaces to the Payroc API: the two transaction-detail SOAP services, image
> retrieval, and the REST `/reporting/*` endpoints. Per-row confidence is carried in the `C` column; the
> legend is in [`_sources.md`](./_sources.md). Last synced: 2026-09-09. Read mappings from this file,
> not from memory — a plausible-sounding mapping that isn't here will look correct in review and fail in
> production.

```text
IN:  SOAP transactiondetail.asmx; trxdetail.asmx; imageretrieval.asmx. REST /reporting/*,
     except /reporting/AccountUpdater.
OUT: transact.asmx ProcessBatch, batchinfo.asmx, settlementinfo.asmx and REST /batch/* --
     map-batch-and-settlement.md. /reporting/AccountUpdater -- map-tokens-and-vault.md.
     Receipt and signature CAPTURE, as opposed to retrieval -- ProcessSignature,
     map-card-transactions.md.
ADJACENT: SETTLEMENT IS SPLIT ACROSS TWO FILES BY PROTOCOL, NOT BY SUBJECT. The REST
     operations /reporting/SettlementDetail and /reporting/SettlementList are HERE, routed
     by their /reporting/ path segment, even though their subject matter is settlement.
     Their SOAP counterparts on settlementinfo.asmx are in map-batch-and-settlement.md,
     along with everything that SETTLES or CLOSES a batch rather than querying one. So a
     reader looking for settlement can legitimately arrive at either file: if you came here
     for a SOAP call, or for closing a batch, go to map-batch-and-settlement.md; if you came
     there for a /reporting/ path, come here. map-batch-and-settlement.md also holds the
     chargeback-versus-disputes-resource finding that this file's SettlementDetail row
     depends on. identifier-translation.md holds cross-cutting identifier, amount, expiry
     and currency facts. If your call is not in the table below, it is not absent from IBX
     -- check the sibling files above, then SKILL.md's routing table, then ask for a request
     sample.
```

**Where to implement what you find here:** `view-settled-transactions` and `view-authorizations` for the
transaction-detail queries, `view-settlement-batches` for the settlement queries,
`view-ach-deposits` for the check-flavoured ones, and `view-disputes` for the chargeback data that
IBX returns inline with a settlement batch. This file owns the delta; those skills own the request
schema.

## `imageretrieval.asmx`

Retrieves receipt images and cheque images only. There is no signature-specific retrieval verb —
that concept lives in `ProcessSignature`'s own response, a different mechanism, covered in
`map-card-transactions.md`. This surface carries no documentation of any kind.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP imageretrieval.GetReceiptImage` | none | `—` — **if you display or archive receipt images today, you will need to generate and store them yourself from transaction data.** Separately and with a deadline: ask your Payroc implementation contact whether the receipt images already held on your IBX account can be exported in bulk **before** your integration is switched over — once it is, that history is not reachable through the API | n/a | **No Payroc capability retrieves a stored receipt image.** You can check that absence yourself: a sweep of every operation and every published guide for "image", "receipt image" and "check image" returns only two things, and neither is a retrieval — Payroc Cloud's device-side signature-capture flow (a different concept; see `map-card-transactions.md`) and KYC/boarding document upload, which its own description rules out. This is a real gap, not an unsearched one. Escalate. | verified |
| `SOAP imageretrieval.GetCheckImage` | none | `—` — **no operation retrieves a stored cheque image.** Ask your Payroc implementation contact whether the cheque images already held on your IBX account can be exported before your integration is switched over, and confirm that your own retention obligations for them can be met outside Payroc — cheque images are often held under a rule you are bound by | n/a | Same sweep, same result. `ImageType` is the only image-format discriminator on this surface, and it is irrelevant once no target exists. | verified |

## `transactiondetail.asmx`

`TransType` vocabulary: `Authorization`, `Capture`, `Credit`, `ForceCapture`, `GetStatus`, `Purged`,
`Receipt`, `RepeatSale`, `Sale`, `Void`.

Four behaviours on this service are confirmed and all four are migration-relevant:

- **Date windows widen asymmetrically.** `BeginDt` widens to `00:00:00` but `EndDt` widens to
  `12:59:59` — just past noon, **not** end of day. A date-range query ported unchanged will silently
  drop most of its last day.
- **`PNRef` is exclusive with the date range** — supply one or the other.
- **`ExcludeVoid` defaults to `TRUE`**, so voided transactions are absent from a legacy result set
  unless the caller opted in.
- **`TransformType=XSL` fetches and applies a caller-supplied, server-side XSL transform.** There is
  no Payroc equivalent of any kind.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transactiondetail.GetOpenBatchSummary` | absorbed | `getbatches` (best-supported placeholder — treat it as a lead. Only this operation's schema description supports the pairing, and nothing confirms it is used as part of a settlement workflow) | — | — | unverified |
| `SOAP transactiondetail.GetCardHistoryTrx` | absorbed | `getTransactions` (`GET /transactions`) | `Count`-based cursor pagination — the only pagination mechanism on this whole surface. Payroc's `listPayments`/`getTransactions` pagination shape is not independently confirmed to match, so **confirm the cursor semantics before porting a paged extract.** | — | inferred |
| `SOAP transactiondetail.GetCardTrx` | absorbed | `getTransactions` / `gettransaction` | — | `LOSS:` `TransformType=XSL`, the server-side caller-supplied transform, has no Payroc equivalent — escalate rather than guess. `IF:` the asymmetric date-window widening above is a real behaviour an existing date-range query must account for; Payroc's own date filtering is not confirmed against this asymmetry, so **confirm the boundary behaviour before porting a date range.** | inferred |
| `SOAP transactiondetail.GetCardTrx2` | absorbed — same 29-field shape as `GetCardTrx` | `getTransactions` / `gettransaction` | — | Same as the `GetCardTrx` row above. | inferred |
| `SOAP transactiondetail.GetCardTrxSummary` | absorbed | `getTransactions` (summary view) | Uses `BeginSettleDt` + `EndSettleDt`, two fields — contrast with `trxdetail`'s single `SettleDt` below. | — | inferred |
| `SOAP transactiondetail.GetCheckTrx` | absorbed | `getTransactions` | 29-field shape, check-specific. | The same `checkData`-family loss candidates documented in `map-rest-transactions.md` — `micr`, `ssn`, the driver's-licence fields, `checkNumber` — **likely recur here, but are not confirmed for this operation.** Check them against your own payloads rather than assuming either way. | inferred |

## `trxdetail.asmx`

The same operation family as `transactiondetail`, minus `GetCardHistoryTrx` — four of the five
operations. One confirmed field-level difference: `GetCardTrxSummary` and `GetCheckTrx` here use a
single `SettleDt` where `transactiondetail`'s equivalents use `BeginSettleDt` + `EndSettleDt`.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP trxdetail.GetOpenBatchSummary` | absorbed | `getbatches` | Same caveat as `transactiondetail`'s row. | — | unverified |
| `SOAP trxdetail.GetCardTrx` | absorbed | `getTransactions` / `gettransaction` | Same as `transactiondetail`'s row. | Same `TransformType=XSL` loss. | inferred |
| `SOAP trxdetail.GetCardTrx2` | absorbed — same shape as `GetCardTrx` | `getTransactions` / `gettransaction` | Same as `transactiondetail`'s row. | Same `TransformType=XSL` loss. | inferred |
| `SOAP trxdetail.GetCardTrxSummary` | absorbed | `getTransactions` | **Single `SettleDt`, not `BeginSettleDt`/`EndSettleDt`** — a real per-service field-name difference, not an error if a mapping table cites the wrong one for the wrong service. | — | inferred |
| `SOAP trxdetail.GetCheckTrx` | absorbed | `getTransactions` | Same as `transactiondetail`'s row. | Same `checkData`-family loss candidates, carrying the same caveat. | inferred |

## The `PaymentType` filter: IBX's two descriptions of it disagree, in both directions

Both reporting services' WSDLs describe **one** `PaymentType` set and attach it to **both**
`GetCardTrx` and `GetCheckTrx`: `ACH`, `DEBIT`, `EBT`, `ECHECK`, `GUARANTEE`, `PAYRECEIPT`,
`SETTLE`, `VERIFY`. IBX's integration guide describes something different on each operation, and
**not in the same direction**:

| Operation | The guide | The WSDLs | Relation |
|---|---|---|---|
| `GetCheckTrx` | Six values — `ACH`, `ECHECK`, `GUARANTEE`, `PAYRECEIPT`, `SETTLE`, `VERIFY` | The eight above | The guide is a strict subset — it omits `DEBIT` and `EBT` |
| `GetCardTrx` | Thirteen values — nine card and gift-card types, plus `DEBIT`, `EBT`, `PAYRECEIPT` and `SETTLE` | The eight above | **Neither contains the other.** Only four values are common |

**What to do with that.** Neither source is reliably the wider one, so **do not port a
`PaymentType` filter on the strength of either document alone.** Take the set of values your own
integration actually sends, and confirm each one against IBX before you assume it is still
meaningful — a value that one of IBX's own descriptions omits may still be accepted, and a value
both describe may still return nothing.

**The two guide lists are mostly asking different questions.** `GetCardTrx`'s is dominated by card
and gift-card types; `GetCheckTrx`'s and the batch queries' are cheque-clearing categories. They
overlap in only four values, so **a value carried across from one operation to the other is likely
to return nothing rather than to error.** Whether an unrecognised value is rejected or simply
matches no rows is **not established** — either way you get no data back, and a silent empty result
is the one to plan for.

**`SETTLE` means two different things in IBX's own guide** — on `GetCardTrx` it retrieves *requests
to settle*, on `GetCheckTrx` and the batch queries it retrieves *transactions already finalised
with the host*. If you filter on `SETTLE`, establish which one you are getting.

## Settlement state: the filter is three-valued and the stored field is not

**This is the trap on this surface, and it is silent.** IBX **documents** exactly three values for
its `SettleFlag` query parameter — blank, `'1'` and `'0'` — on `GetCardTrx`, `GetCardTrxSummary`
and `GetCheckTrx` alike. **That is what its documentation lists, not a rule it is known to
enforce**; nothing in IBX's service descriptions restricts the field, and it is declared simply as
a string. The settlement state it filters on, meanwhile, is **not** a boolean.

**IBX's code declares eight settlement states** — open, settled, indeterminate, submitted,
exception, in-settlement, suspended-open and in-retry — of which its integration guide glosses only
four. Remediation scripts write a ninth value that is not in that set at all. **Three of the eight
appear in no IBX documentation of any kind**, so treat them as states IBX's software can write
rather than as states you should expect to see. Separately, IBX has a fraud path that puts a
transaction on hold; **what that path writes to this field, and whether it is what the live gateway
runs, are both unestablished** — do not plan around it, and do not count it as a further state.

> **`SettleFlag='1'` and `SettleFlag='0'` do not partition your transactions.** On the card and
> cheque detail queries IBX turns each into an **exact match** on the stored state, so everything
> that is neither plainly settled nor plainly unsettled falls outside **both** filters, while a
> blank `SettleFlag` applies no filter at all and returns the lot. **A reconciliation routine that
> loops the two values silently drops those rows** — they are retrievable, but not filterable by
> any value IBX documents.

**Do not assume the three operations behave alike here.** The card and cheque detail queries build
the filter one way; `GetCardTrxSummary` reaches the database by a different route, and that route
binds the value as a **single character**, so anything longer is cut short. **Treat the summary
operation as unestablished** rather than as a third instance of the same behaviour.

**One cheap probe would settle most of this, and it is worth running before you design around it.**
Send `SettleFlag` with an undocumented value — `'2'` is the useful one — against a low-volume
merchant on your own account. If rows come back, the states that fall outside `'1'` and `'0'` are
directly queryable after all and your reconciliation gap closes without a redesign. If it errors,
you know the blank-filter-and-classify approach above is the only route. **Its result is not established**,
so do not assume either outcome.

**If you are reconciling against IBX before or during a migration, query with `SettleFlag` blank
and classify in your own code.** Running the same query again with `'1'` and `'0'`, every other
parameter identical, gives you a useful diagnostic: the shortfall between the blank count and the
two filtered counts is transactions your existing reconciliation has been passing over. **Read it
as indicative, not as an exact total.** Three separate queries are not a snapshot — settlement
states change under you, and IBX runs a settlement sweep every few minutes that moves them — and
`ExcludeVoid` defaults to
`TRUE`, so voided transactions are missing from all three counts alike. A non-zero shortfall is
worth investigating before you cut over; a zero does not prove there is nothing there.

**IBX's REST reporting cannot express the distinction at all.** There is no `SettleFlag` on that
surface. The filter is a boolean `IsSettled`, and the response carries a settlement block whose
`IsSettled` is likewise a boolean. **Which stored state renders as which boolean is not
established** — do not assume it, and do not treat a REST `IsSettled` of `false` as meaning
"unsettled and settleable". One boolean cannot distinguish eight states.

**IBX's own documentation describes this field both ways.** Its response-field dictionary appears
twice in the guide; one copy lists a multi-value state code and the other calls the same field a
boolean. The likeliest reading is that one dictionary was emitted twice and drifted, rather than
that the field behaves two ways.

> **But do not settle that in your own head. Among the things IBX publishes, the boolean reading
> has support the multi-value reading does not** — the multi-value reading rests on IBX's internal
> code and internal notes, which you do not have and cannot check. IBX's service descriptions gloss this field as *whether the transaction was
> settled*, with no value set at all, and its REST surface exposes it as a plain boolean. **A
> two-state view of settlement may be how IBX genuinely intends this field to be read**, with the
> other values internal. What is certain is only that the stored column holds more than two values
> and the documented filter reaches two of them. **So build nothing that depends on the full value
> set.** When you need to know whether a transaction settled (confirming pre-cutover captures, for
> example), check it individually on the card or cheque detail query and count it as settled only
> when its stored flag is `1`. Treat every other value as not yet settled and follow it up. Do not
> use REST `IsSettled` for this check, since which stored states it reports as `true` is not
> established.

## REST `/reporting/*`

Excluding `/reporting/AccountUpdater`, which is `map-tokens-and-vault.md`'s territory.

**A pattern that runs through three of these four rows:** IBX's REST specification declares required
fields that its runtime does not enforce. Do not size a migration on the declared contract — legacy
callers may have been sending anything at all.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST GET /reporting/` | absorbed | `getTransactions` | — | `SCOPE:` **IBX applies no runtime check of any kind to this query**, and its specification declares no required fields either — a genuinely wide-open query surface on the legacy side. | verified (the IBX side) / inferred (the Payroc pairing) |
| `REST GET /reporting/{Pnref}` | direct | `gettransaction` | — | IBX enforces `pnRef > 0` at runtime, matching its own declared required field — the one row on this surface where the declared contract and the enforced one agree. | verified |
| `REST GET /reporting/SettlementDetail {BatchId}` | partial | `getdisputes` → `gettransaction`, joined in your own code; `getbatch` for the batch half | — | `LOSS:` **you lose the link between a batch and its chargebacks.** IBX returns them together keyed on the batch; Payroc has no batch-to-disputes direction and the association has to be rebuilt by sweeping disputes and joining through each one's transaction. **The full reasoning, and the two reasons it is a redesign rather than a re-shape, are on the `settlementinfo.GetSettlementDetail` row in `map-batch-and-settlement.md` — read it before you plan this.** `SCOPE:` the specification declares `BatchId` required; **IBX enforces nothing at runtime**, despite that claim. | verified (the IBX side, where the runtime contradicts the specification) / inferred (the Payroc pairing) |
| `REST GET /reporting/SettlementList {StartDate,EndDate}` | partial | `getbatches` | — | `LOSS:` this response carries chargebacks alongside the batch list, and Payroc's does not — the same association loss as `SettlementDetail` above, and the same reference for the full reasoning. `SCOPE:` the same pattern as `SettlementDetail` above — declared required fields, no runtime enforcement. | verified (the IBX side) / inferred (the Payroc pairing) |

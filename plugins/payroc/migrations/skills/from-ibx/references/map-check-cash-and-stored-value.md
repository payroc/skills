# IBX → Payroc: check, cash, bitcoin, gift and loyalty — `transact` / `transact2`

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> the IBX `transact` and `transact2` SOAP services to the Payroc API, covering `ProcessCheck`,
> `ProcessCash`, `ProcessBitcoin`, `ProcessGiftCard` and `ProcessLoyaltyCard`. Per-row confidence is
> carried in the `C` column; the legend is in [`_sources.md`](./_sources.md). Last synced: 2026-09-14.
> Read mappings from this file, not from memory — a plausible-sounding mapping that isn't here will
> look correct in review and fail in production.

```text
IN:  SOAP /ws/transact.asmx and /ws/transact2.asmx (where present) -- ProcessCheck,
     ProcessCash, ProcessBitcoin, ProcessGiftCard, ProcessLoyaltyCard only.
OUT: ProcessCreditCard / ProcessSignature / EmailReceipt -- map-card-transactions.md.
     ProcessDebitCard / ProcessEBTCard -- map-debit-and-ebt.md.
     cardsafe.ProcessCheck (REST/SOAP, token-based) -- map-token-payments.md; do NOT
     conflate it with this file's raw-data ProcessCheck, which is a different validator
     and a different request shape. ProcessBatch's own settlement path for
     Cash/Check/GiftCard -- map-batch-and-settlement.md, which is possibly the real
     target for the CaptureAll-shaped rows this file could not resolve.
ADJACENT: map-extdata-tags.md covers the ten ExtData tags IBX accepts and documents
     nowhere. The check path shares its recognised set with debit, so Presentation,
     CVMResult, QPS, ChipConditionCode and AppInfo reach it -- read that file if your
     ExtData carries a tag not described below.
     identifier-translation.md holds cross-cutting identifier, amount, expiry and
     currency facts, cited from the rows below rather than restated per row.
     no-equivalent-register.md indexes "no equivalent" verdicts by IBX service, and most
     of this file's rows are one. If your call is not in the table below, it is not
     absent from IBX -- check the sibling files above, then SKILL.md's routing table,
     then ask for a request sample.
```

**Where to implement what you find here:** `ProcessCheck` is the only operation in this file with a
Payroc target — `take-an-ach-payment` for `Sale`, `refund-an-ach-payment` for `Return`, and
`verify-bank-account` where you need the account checked first. This file owns the delta; those
skills own the request schema. Every other operation below is a gap, not a handoff.

## Cross-cutting facts

Stated once here; see `identifier-translation.md` for the full detail.

- **Currency cannot come from your IBX request.** IBX has no currency field on any API surface, and
  Payroc's `order.currency` is required. It resolves from processor or terminal configuration, or from
  an intake question. There is no field to read it from on the legacy side, ever.
- **The `DDDDD.CC` amount format is not what the SOAP validator enforces — but do not read that as
  permission to send more.** The validator checks only two decimal places, digits before the point,
  and a total length of no more than twelve characters. So **for intake, assume legacy rows above
  `99999.99` may exist** and do not build validation that rejects them. **For what you send,
  `99999.99` is the recommended ceiling:** IBX's REST surface declares its card amount as a
  single-precision float, which turns `999999.99` into `1000000.00`, so `99999.99` is the last value
  that round-trips cleanly. Above it the REST failure mode is **silent rounding, not an error.**
  Note the check surface declares a wider type than the card surface, so **the limit is not uniform
  across payment methods** — ask your Payroc implementation contact rather than assuming. See
  `identifier-translation.md`.
- **The two-decimal rule *is* enforced, so conversion to minor units is exact** — no rounding
  ambiguity. But convert by ×100 **only for two-decimal currencies.** Payroc's `order.amount` is in
  the currency's lowest denomination and its currency enum includes zero-decimal (`JPY`, `KRW`) and
  three-decimal (`BHD`, `KWD`) entries. Confirm the terminal's currency before applying ×100 —
  otherwise the error is 100×.
- **One documented exception to the amount format, and it does not cover both stored-value
  operations.** `ProcessLoyaltyCard` specifically documents its amount as *"in decimal format"*
  rather than `DDDDD.CC`. `ProcessGiftCard` does **not** share the exception — it explicitly documents
  the standard format. Do not broaden the carve-out beyond loyalty.
- **`PNRef` lives in your database, never IBX's.** The bridge is `order.orderId` on the way in and
  `listPayments?orderId=` on the way back out — handle both zero matches and more than one. That
  bridge applies only where a Payroc target exists at all; most rows below have none.
- **A success result is not "money moved" for every row below.** Check the rows tagged `SEMANTIC:`.
- **Card expiry (`MMYY` on both platforms) applies to `ProcessGiftCard` and `ProcessLoyaltyCard`
  only.** `ProcessCheck`, `ProcessCash` and `ProcessBitcoin` carry no card at all.
- **All five operations dispatch through a different internal path from the credit-card one** — the
  same architecture debit and EBT use, with scalar arguments rather than the credit-card request
  builder. **Every `verified` badge below is verified at the dispatch layer only** — that IBX calls a
  specific method with specific arguments — **never at the processor layer inside that call.**
- **The queued, fabricated-success `CaptureAll` hazard that credit and debit carry does not extend to
  any operation in this file.** The queueing mechanism appears exactly four times across the whole
  transaction service, all of them on the credit and debit paths. Where `CaptureAll` is live here
  (`Check`, `GiftCard`/`LoyaltyCard`) it settles synchronously, matching EBT's shape. Where it is not
  live (`Cash`), see that row's own trap.
- **`ProcessGiftCard` and `ProcessLoyaltyCard` are two SOAP operations sharing one private
  implementation**, discriminated only by a payment-type argument. The rows below combine both
  operations per token rather than doubling every row for two operations that run identical code.
- **Both gift and loyalty WSDLs under-declare their own dispatch by four tokens.** The published
  descriptions document only `Activate | Deactivate | Refund | Redeem | Inquire | Reload` — six. The
  live dispatch also handles `Force`, `Void`, `Capture` and `CaptureAll`: ten tokens, all reachable,
  four of them declared nowhere.
- **Gift and loyalty card entry recognises a near-complete EMV and device `ExtData` set** — 20 tags,
  including `EntryMode`, `Authentication`, `CVPresence` and the full device-capability set, nearly
  matching credit card's own 37. This is a real, working closed-loop EMV card-present capability
  invisible in every published document — worth telling the developer about as a genuine feature,
  not only as a gap.
- **The Payroc API has no cash, bitcoin, gift-card, loyalty-card or stored-value payment method
  anywhere** — no payment-method schema and no operation, in either the API specification or the
  published product prose. The one adjacent API concept, `getClosedLoop` (`GET
  /closed-loop-reads/{id}`, part of the Payroc Cloud device-instruction product), is a **read-only**
  passthrough that retrieves an unstructured payload a payment device captured from a closed-loop
  card. It has no activate, redeem, reload, deactivate or balance-inquiry verb of any kind and is not
  run against a Payroc-held ledger. **Do not present it as an equivalent** for any row below.
- **But that absence claim is narrower than "Payroc cannot handle cash or gift cards."** Payroc's own
  product documentation describes "Roc Terminal+" as facilitating *"cards, bank transfers, cash, and
  gift cards"* from one terminal — a real Payroc product. Whether that is a no-code merchant app
  (immaterial to an API migration) or exposes any customer-callable surface is **unresolved**, not
  settled. The `ProcessCash` rows flag this explicitly rather than recommending self-built tracking
  outright.
- **Do not conflate Payroc's `isPrepaid` with a closed-loop gift card.** `isPrepaid` is an open-loop
  Visa/Mastercard BIN attribute (see `map-auth-and-platform-utilities.md`); same marketing word,
  different product category.
- **The `bank-transfer-payments` family — `ProcessCheck`'s target — has no auth-then-capture pair and
  no batch-settle endpoint.** It exposes only a single-step create (`bankTransferPayment`), a
  referenced reversal and refund pair, an unreferenced refund, a re-presentment operation and a close
  operation. That is structurally narrower than IBX Check's two-step `Auth`→`Capture`/`CaptureAll`
  shape, which is why the `Auth`, `Capture` and `CaptureAll` rows below are escalated rather than
  force-fit onto the single-step operation.

## `ProcessCheck`

The one operation in this file whose WSDL documentation is complete: all seven dispatched tokens are
declared, byte-identical on `transact` and `transact2`.

**A real, non-obvious oddity: `PNRef` is not a top-level SOAP parameter on this operation at all.**
Every other operation in this file and in `map-card-transactions.md` carries `PNRef` as a direct
argument; here it exists only inside `ExtData`, parsed into a value that defaults to `-1` if absent or
unparseable. A client or skill that assumes `PNRef` is always a top-level field will silently drop it
for this operation's `Void` and `Capture` calls.

**`secCode` has no source anywhere on the IBX side** — not in `ProcessCheck`'s parameters, not in its
documented `ExtData` tags. Payroc requires it. This is an intake gap, not a rename:
plan to ask for it, and do not expect to derive it from legacy data. See the `Sale` row.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact.ProcessCheck {TransType=Auth}` | none (target undetermined — escalate) | `—` | n/a | No structural Payroc equivalent. `bankTransferPayment` (the `Sale` row below) settles immediately on creation, and nothing in the bank-transfer payment or refund family exposes a hold-without-settling step. A check `Auth`-then-`Capture` flow therefore has no confirmed decomposition — **ask your Payroc implementation contact rather than defaulting to `Sale`'s single-step call.** | unverified (the Payroc-side absence was checked across the bank-transfer schema family, not exhaustively across the whole API) |
| `SOAP transact.ProcessCheck {TransType=Sale}` | absorbed | `bankTransferPayment` (`POST /bank-transfer-payments`) | **`+secCode`** — required for `web`/`tel`/`ccd`/`ppd` per the schema's own description, **with no IBX-side source found anywhere**, in parameters or documented `ExtData` tags | `LOSS:` the ACH payload's own description names `secCode` mandatory for ACH payments and unreferenced refunds. This is an added required field with no legacy origin — the single largest cause of a 400 on this path, not a rename. | verified (the IBX dispatch) / inferred (the Payroc target and the gap, from schema shape only) |
| `SOAP transact.ProcessCheck {TransType=Return}` | branch | `bankTransferUnreferencedRefund` (unreferenced) \| `refundBankTransferPayment` (referenced, open batch only) | Unreferenced path: the identifier bridge in `identifier-translation.md`, adapted to the bank-transfer refund shape. Referenced path: body requires `amount` and `description` | `IF:` **whether an unreferenced check return is actually reachable on IBX's side is unresolved.** The branch is asserted from the Payroc side's own vocabulary, not confirmed against IBX behaviour. **Take the unreferenced path by default for ACH:** `refundBankTransferPayment` returns 400 once the batch closes, and reverses rather than refunds while it is open, so it never settles an ACH return. PAD is unaffected. | unverified |
| `SOAP transact.ProcessCheck {TransType=Force}` | none (target undetermined — escalate) | `—` | n/a | No bank-transfer analog to card's `offlineProcessing` was found, **but this search was narrower than the `Auth` row's and is the weakest of this operation's four gap claims** — treat it as an open question, not a confirmed absence, and say so if asked. | unverified |
| `SOAP transact.ProcessCheck {TransType=Void}` | direct — cancels a payment before settlement; no funds taken, matching `reverseBankTransferPayment`'s own description ("also known as voiding a payment") | `reverseBankTransferPayment` | `PNRef` moves from `ExtData` on the IBX side (see the note above) to the Payroc identifier bridge in `identifier-translation.md` | — | verified |
| `SOAP transact.ProcessCheck {TransType=Capture}` | none (target undetermined — escalate) | `—` | n/a | Same structural gap as `Auth` — nothing settles a previously-created bank-transfer payment as a second step. `ADJACENT:` **batch-wide check settlement is a genuine alternate route** — `ProcessBatch {PaymentType=CHECK}` has a real working path (see `map-batch-and-settlement.md`). What is **not** established is whether IBX integrations settle checks that way in practice. Check there before answering the developer. | unverified |
| `SOAP transact.ProcessCheck {TransType=CaptureAll}` | none (target undetermined — escalate) | `—` | n/a | `SEMANTIC:` a direct, synchronous call — no queue, no fabricated success result, unlike credit's and debit's `CaptureAll`. Same `ADJACENT:` note as `Capture` above: `ProcessBatch {PaymentType=CHECK}` in `map-batch-and-settlement.md` is a genuine alternate settlement route, and whether integrations use it in practice is unsettled. | verified (the dispatch shape) / unverified (the Payroc target) |

## `ProcessCash`

Only two tokens are live — `Sale` and `Return` — despite `CaptureAll` being partially recognised; see
its own row. **No `transact2` equivalent exists**, confirmed two independent ways: `transact2` exposes
exactly nine operations and `ProcessCash` is not one of them, and the `transact2` WSDL contains zero
occurrences of the name.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact.ProcessCash {TransType=Sale}` | none (target undetermined at the API layer — see caveat) | `—` — **before you build your own cash tracking, ask your Payroc implementation contact whether Roc Terminal+ covers your case and whether it exposes anything your application can call.** That is a question, not a recommendation: it may turn out to be a merchant-facing app with no integration surface, and building cash tracking is expensive to do and expensive to undo | n/a | No Payroc cash-payment *API* concept exists: no operation, no schema, and no cash payment method in the published product prose. **But that is not the whole answer.** Payroc's own product documentation states that "Roc Terminal+" facilitates *"cards, bank transfers, cash, and gift cards"* from one terminal — a real capability statement. Whether that terminal-side handling is reachable by any API an IBX SOAP integration could call, or is a no-code merchant app with nothing to migrate to, is **unresolved**. | verified (the IBX dispatch) / unverified (the Payroc-side capability, not merely the schema, is still open) |
| `SOAP transact.ProcessCash {TransType=Return}` | none (target undetermined at the API layer — see the `Sale` caveat) | `—` — ask the same question as `Sale` above, **covering sales and refunds together**: a product that records cash taken may not record cash returned, so a bare "yes, cash is supported" does not settle this direction | n/a | Same as `Sale` above. | verified (the IBX dispatch) / unverified (see `Sale`) |
| `SOAP transact.ProcessCash {TransType=CaptureAll}` | none | `—` — **nothing to port: this call does not settle anything today and never has.** Check your logs for it before you migrate, because a scheduled job that has been failing silently against this token is worth finding now. If cash settlement genuinely matters to your business, ask about Roc Terminal+ as for the cash `Sale` and `Return` rows above | n/a | `SEMANTIC:` **a genuine "recognised, then rejected" trap, not merely an undeclared token.** IBX unconditionally logs the request as a settlement attempt *before* the dispatch is reached — but the dispatch itself has no `CaptureAll` case, so it falls through to `Result=3, "Invalid Transaction type"`. **A caller sending this token is logged as if settling, then rejected.** Same shape as credit's `SendImage` in `map-card-transactions.md` — recognised in one place, absent from the place that matters. | verified |

## `ProcessBitcoin`

**No `transact2` equivalent**, confirmed the same two ways as `ProcessCash`. Undocumented at every
layer: the operation descriptions contain no occurrence of `Bitcoin`, `BTC` or `Crypto`, and the WSDL
operation element carries no documentation at all.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact.ProcessBitcoin {TransType=Sale}` | none | `—` — **almost certainly no work: check your logs before planning any.** IBX's own bitcoin checkout was withdrawn in 2015, so this is unlikely to be carrying live traffic for you. If you do find recent successful transactions, tell your Payroc implementation contact — that would contradict what IBX's own behaviour shows and is worth resolving before you migrate | n/a | `SEMANTIC:` **the Payroc API has no cryptocurrency payment method** — none in the specification, none in the published product prose. And this is not merely an unused IBX feature: IBX's own hosted checkout page carried a Bitcoin path — a radio button wired straight to this operation and on to a third-party checkout flow — and **it was explicitly withdrawn in 2015.** IBX itself abandoned the feature, so this is doubly dead rather than a migration gap. `Return` exists only as a withdrawn branch and was never live, so it is not a callable unit and gets no row. | verified (the dispatch; the Payroc-side absence and the 2015 deprecation were both exhaustively checked) |

## `ProcessGiftCard` / `ProcessLoyaltyCard`

Both public operations exist on `transact2` as pure forwards. All ten rows below apply identically to
both operations *per `TransType` dispatch and target* — see the cross-cutting facts for why they are
combined.

**One real request-shape asymmetry between the two, which that combination does not collapse:**
`ProcessGiftCard` has a `Zip` parameter that `ProcessLoyaltyCard` does not — loyalty passes nothing in
that position. Every target below is `none` regardless, so this does not change a verdict, but a
client mapping both operations from one row must not assume identical request shapes.

Every target in this section is `none`: Payroc has no closed-loop stored-value ledger of its own (see
the cross-cutting facts). `getClosedLoop` is named once, there, as the closest non-equivalent rather
than repeated per row.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact.ProcessGiftCard {TransType=Activate}` / `SOAP transact.ProcessLoyaltyCard {TransType=Activate}` | none | `—` — **ask your Payroc implementation contact whether closed-loop gift and loyalty card processing is available on your account, through which Payroc product, and whether that product exposes an interface your application can call.** Then ask what the migration path is for balances already loaded on cards you have issued. **Settle issuance first:** until a card can be activated there is nothing for the other gift and loyalty operations to act on | n/a | No Payroc activate concept for a closed-loop card. See the `getClosedLoop` caveat in the cross-cutting facts — not equivalent, do not conflate. | verified |
| `SOAP transact.ProcessGiftCard {TransType=Deactivate}` / `SOAP transact.ProcessLoyaltyCard {TransType=Deactivate}` | none | `—` — ask the same question as `Activate` above, and specifically **how a card already in circulation is taken out of service.** A lost, stolen or expired card is a support obligation, not an optional feature | n/a | Same as `Activate`. | verified |
| `SOAP transact.ProcessGiftCard {TransType=Redeem}` / `SOAP transact.ProcessLoyaltyCard {TransType=Redeem}` | none | `—` — ask the same question as `Activate` above, and **settle it before you migrate anything else**: redemption is the operation your customers touch at the till, so it sets the timetable for the rest. Note that an open-loop answer does not cover it — `isPrepaid` is a card-brand BIN attribute, a different product that shares a marketing word | n/a | Same as `Activate`. | verified |
| `SOAP transact.ProcessGiftCard {TransType=Refund}` / `SOAP transact.ProcessLoyaltyCard {TransType=Refund}` | none | `—` — ask the same question as `Activate` above, and **describe your refund flow when you ask.** This token accepts fresh card data *and* a `PNRef`, so it covers both referenced and unreferenced refunds; an answer that handles only one of those will not cover your integration | n/a | `SCOPE:` this token takes both fresh card data **and** a `PNRef` argument — a referenced-or-unreferenced hybrid, unlike any card row in `map-card-transactions.md` or `map-debit-and-ebt.md`. Still no Payroc target of any kind exists to receive either shape. | verified |
| `SOAP transact.ProcessGiftCard {TransType=Reload}` / `SOAP transact.ProcessLoyaltyCard {TransType=Reload}` | none | `—` — ask the same question as `Activate` above, and **whether adding value to a card already in a customer's hands is supported.** Reloading is a separate capability from issuing and may be answered differently, so "gift cards are supported" does not settle it | n/a | Same as `Activate`. | verified |
| `SOAP transact.ProcessGiftCard {TransType=Inquire}` / `SOAP transact.ProcessLoyaltyCard {TransType=Inquire}` | none | `—` | n/a | `SCOPE:` Payroc's `balanceCard` (the EBT `Inquire` row in `map-debit-and-ebt.md`) is scoped to EBT by its own description alone — nothing states it also serves closed-loop gift or loyalty cards. **Do not reuse it here without confirming with your Payroc implementation contact**; same caution as the debit `Inquire` row. | verified |
| `SOAP transact.ProcessGiftCard {TransType=Force}` / `SOAP transact.ProcessLoyaltyCard {TransType=Force}` | none | `—` — ask the same question as `Activate` above, and **whether forced or offline authorisation is available on whatever product carries closed-loop cards.** Do not assume the answer matches the card side: the card rows' offline-processing mapping is a card answer, not a closed-loop one | n/a | `SCOPE:` shares the same low-level force-authorization call as debit's and EBT's `Force` (see `map-debit-and-ebt.md`) — but, unlike debit and credit, is **not** gated by the `CanDoForceAuth` merchant-permission check. That gate is applied per-operation at the SOAP layer and only credit and debit apply it; `ProcessEBTCard`'s `Force` and `ProcessCheck`'s `Force` are ungated by it too. No `Force`-specific permission or eligibility check exists inside the shared gift/loyalty implementation at all — what is there is generic to every gift/loyalty token (API-user validation, a `PNRef="0"` rejection, user and account status checks) plus a transaction-type whitelist that simply accepts `Force`. Two details cut against assuming some other layer catches it: the "amount required" guard covers only `Activate`/`Deactivate`/`Redeem`/`Refund`/`Reload`, so `Force` is not even amount-checked; and the `Force` branch calls the *generic* force-authorization method — the same one credit and EBT call — dropping the payment-type argument entirely. **Still NOT established, and load-bearing — do not sharpen this: "gift/loyalty `Force` is entitlement-free end to end" does not follow.** What happens two layers below this one is not established: what `CanDoForceAuth` actually inspects is unknown, and the low-level force-authorization call could gate internally. **That is a question for your Payroc implementation contact, not one this file can answer.** No Payroc target regardless. | verified (the dispatch, and the absence of the `CanDoForceAuth` gate) |
| `SOAP transact.ProcessGiftCard {TransType=Void}` / `SOAP transact.ProcessLoyaltyCard {TransType=Void}` | none | `—` — ask the same question as `Activate` above, and **whether a gift or loyalty transaction can be cancelled before it settles.** Say that you use this today even though it appears in neither IBX service description — it is undocumented but live, so an answer given from the documentation alone will tell you that you never had it | n/a | Not declared in either WSDL — found only in the dispatch. No Payroc target. | verified |
| `SOAP transact.ProcessGiftCard {TransType=Capture}` / `SOAP transact.ProcessLoyaltyCard {TransType=Capture}` | none | `—` — ask the same question as `Activate` above, and **how a single gift or loyalty transaction is settled.** Say that you use this today even though it appears in neither IBX service description. Do not let this be answered with a card-batch operation: gift and loyalty settle through a separate call against a closed-loop ledger | n/a | Not declared in either WSDL. No Payroc target. | verified |
| `SOAP transact.ProcessGiftCard {TransType=CaptureAll}` / `SOAP transact.ProcessLoyaltyCard {TransType=CaptureAll}` | none | `—` — ask the same question as `Activate` above, and **how gift and loyalty transactions are settled in bulk.** Say that you use this today even though it appears in neither IBX service description, and that it settles synchronously here — your code can rely on the response, which is **not** true of the credit and debit `CaptureAll` | n/a | `SEMANTIC:` a direct, synchronous call — no queue, no fabricated success result (see the cross-cutting facts). Not declared in either WSDL. No Payroc target. | verified |

## `transact2`

`ProcessCash` and `ProcessBitcoin` have **no `transact2` equivalent at all** — confirmed in each
operation's own section above — so only three of this file's five operations get a delta row.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact2.ProcessCheck {TransType=Auth,Sale,Return,Force,Void,Capture,CaptureAll}` | direct — the *same objects running the same code*, a pure positional-parameter forward | Same target as the corresponding `ProcessCheck` row above, for every token listed | Endpoint only: `/ws/transact2.asmx`. | — | verified. **Treat each row's confidence here as capped by the corresponding `transact` row, never higher** |
| `SOAP transact2.ProcessGiftCard {TransType=Activate,Deactivate,Redeem,Refund,Reload,Inquire,Force,Void,Capture,CaptureAll}` | direct — same objects, same code, a pure positional-parameter forward | Same target as the corresponding `ProcessGiftCard` row above, for every token listed | Endpoint only. | — | verified. **Capped by the corresponding `transact` row, never higher** |
| `SOAP transact2.ProcessLoyaltyCard {TransType=Activate,Deactivate,Redeem,Refund,Reload,Inquire,Force,Void,Capture,CaptureAll}` | direct — same objects, same code, a pure positional-parameter forward | Same target as the corresponding `ProcessLoyaltyCard` row above, for every token listed | Endpoint only. | — | verified. **Capped by the corresponding `transact` row, never higher** |

## What this file does not map

**Most rows above have no Payroc target.** That is a real property of this surface, not a gap in
the mapping: `ProcessGiftCard` and `ProcessLoyaltyCard` alone contribute ten `none` rows because Payroc
has no closed-loop stored-value *API* at all, and the one adjacent capability (`getClosedLoop`) is
named and explicitly ruled non-equivalent rather than left silently absent.

Two of those verdicts are weaker than the rest and must not be quoted as settled gaps:

- **The two `ProcessCash` rows** are an open "no *API*, product-level capability unresolved" question,
  not a closed "no capability" gap — because of the Roc Terminal+ product statement above.
- **`ProcessCheck {TransType=Force}`** rests on a narrower search than the other three `ProcessCheck`
  gaps.

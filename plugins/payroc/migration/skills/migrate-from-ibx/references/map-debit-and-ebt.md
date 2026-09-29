# IBX → Payroc: debit and EBT transactions — `transact` / `transact2`

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> the IBX `transact` and `transact2` SOAP services to the Payroc API, covering `ProcessDebitCard` and
> `ProcessEBTCard`. Per-row confidence is carried in the `C` column; the legend is in
> [`_sources.md`](./_sources.md). Last synced: 2026-09-14. Read mappings from this file, not from
> memory — a plausible-sounding mapping that isn't here will look correct in review and fail in
> production.
>
> **How far a badge in this file goes, and it is a uniform limit.** A `verified` here normally means
> it is confirmed *which* processor-bridge call IBX makes and with which arguments — **not** what
> that call then does downstream. The downstream layer is the same for every operation in this file,
> so the limit is structural rather than row-by-row. Where a row's outcome depends on downstream
> behaviour, treat the badge as covering the dispatch only.

```text
IN:  SOAP /ws/transact.asmx and /ws/transact2.asmx -- ProcessDebitCard, ProcessEBTCard only.
OUT: ProcessCreditCard / ProcessSignature / EmailReceipt on these same two services --
     map-card-transactions.md. ProcessCheck / ProcessCash / ProcessBitcoin /
     ProcessGiftCard / ProcessLoyaltyCard -- map-check-cash-and-stored-value.md.
     ProcessBatch -- map-batch-and-settlement.md. IBX's REST surface has no debit- or
     EBT-*transaction* endpoint, so there is no map-rest-transactions.md or
     map-token-payments.md sibling for these two payment types -- SOAP is the only route.
     (IBX's REST contract does carry non-transaction debitTerminalNumber / ebtTerminalNumber
     configuration fields, and a batch filter listing Debit and EBT as settlement types.
     Neither is a transaction call, so do not read either as a REST debit or EBT surface.)
ADJACENT: map-extdata-tags.md covers the ten ExtData tags IBX accepts and documents
     nowhere. Five of them reach the debit and EBT paths -- Presentation, CVMResult, QPS,
     ChipConditionCode, AppInfo -- so read it if your ExtData carries any tag not
     described below.
     identifier-translation.md holds cross-cutting identifier, amount, expiry and
     currency facts, cited from every row below rather than restated per row.
     no-equivalent-register.md indexes the "no equivalent" verdicts, including this file's
     eWIC and ReEnter tokens. If your call is not in the table below, it is not absent from
     IBX -- check map-card-transactions.md first (several rows below share dispatch shape
     with credit's), then SKILL.md's routing table, then ask for a request sample.
```

**Where to implement what you find here:** `run-a-card-sale` for debit sales,
`run-a-pre-authorization` for `Auth`/`Capture`, `refund-a-card-payment` for
`Return`/`Void`/`Reversal`, `check-ebt-balance` for the EBT balance inquiry,
`view-settlement-batches` for the batch-close targets. This file owns the delta; those skills own the
request schema.

## Cross-cutting facts

Stated once here; see `identifier-translation.md` for the full detail.

- **Currency cannot come from your IBX request.** IBX has no currency field on any API surface, and
  Payroc's `order.currency` is required. It resolves from processor or terminal configuration, or from
  an intake question.
- **IBX documents `Amount` as `DDDDD.CC`, and the SOAP validator does not enforce it — but the
  documented figure is still the right ceiling to design to.** The validator checks only two decimal
  places, digits before the point, and a length of no more than twelve characters. So **legacy rows
  above `99999.99` may exist and your intake must tolerate them.** For what you send, IBX's REST
  surface declares its card amount as a single-precision float that turns `999999.99` into
  `1000000.00`, so `99999.99` is the last value that round-trips cleanly and the failure mode above
  it is **silent rounding, not an error.** Ask your Payroc implementation contact before relying on
  anything larger. See `identifier-translation.md`.
- **The two-decimal guarantee does hold, so conversion to minor units is exact** — but convert by ×100
  **only for two-decimal currencies.** Payroc's currency enum includes zero-decimal and three-decimal
  entries.
- **Card expiry is `MMYY` on both platforms** — no digit-pair conversion in either direction. Payroc's
  four-digit pattern does not range-check the month, so **the skill must range-check it itself.**
- **`PNRef` lives in your own database, never IBX's.** The bridge is `order.orderId` on the way in and
  `listPayments?orderId=` on the way back out — handle both zero matches and more than one.
- **A success result is not "money moved" for every row below.** Check the rows tagged `SEMANTIC:`.
- **Where a row below is badged `verified`, read what the badge covers.** For these two operations it
  is normally confirmed which processor-bridge call IBX makes for a given `TransType`, and with which
  arguments — not what that call then does downstream. Where a row needs a claim about what happens
  after the call, it says so and is badged accordingly.
- **Debit and EBT do not share credit's request-building path.** `ProcessCreditCard` builds its
  request through a shared builder that switches on `TransType`; `ProcessDebitCard` and
  `ProcessEBTCard` bypass that builder entirely and call the processor bridge directly with scalar
  arguments. **Concretely: credit's zero-amount `Sale`→`Auth` AVS rewrite cannot fire on
  `ProcessDebitCard`, because the code that performs it is never reached from here** — a verified
  absence, not a searched-and-not-found one. There is also a debit/EBT branch inside that shared
  builder, and an equivalent branch inside its demo-response generator; **neither is reachable from
  these two operations by any call path, so do not read either as behaviour.** More generally, treat
  nothing in `map-card-transactions.md` as transferring to these two operations unless a row below
  says it does.
- **Debit is a BIN classification on the Payroc side, not a distinct operation or field — hedged
  deliberately.** A `debit: boolean` appears on the `card` and `cardSource` objects, and the modern
  `POST /payments` (`operationId: payment`) states in its own description that it covers *"Credit,
  debit, and EBT"* through one schema. **Whether `card`/`cardSource` are reference-only from response
  bodies is not settled and is not asserted here.** What *is* confirmed: no transaction-request schema
  has a debit-specific write field, PIN-block variant or transaction-level cashback flag. (A boarded
  terminal does carry a `pinDebitCashback` flag, but that is terminal-boarding configuration, not a
  payment-transaction field, so it does not bear on the row mappings below.) Every debit row below
  targets the same `payment` operation as `map-card-transactions.md`'s credit-card rows; nothing in
  the transaction *request* distinguishes the two.
- **The surcharge parameter name diverges three ways, checked directly at each layer:**

  | Layer | `ProcessDebitCard` | `ProcessEBTCard` |
  |---|---|---|
  | `transact` WSDL schema element | `SurechargeAmt` | `SurchargeAmt` |
  | WSDL documentation prose (identical on both services) | `SureChargeAmt` | `SureChargeAmt` |
  | `transact2` WSDL schema element | `SureChargeAmt` | `SureChargeAmt` |
  | the parameter name `transact` actually accepts | `SurechargeAmt` | `SurchargeAmt` |

  Three distinct spellings across five sites for what is conceptually one field. **A client that
  copies the documentation's spelling verbatim (`SureChargeAmt`) will miss `transact`'s actual
  parameter name on both operations.**

- **On `ProcessEBTCard`, the surcharge value is parsed and then never forwarded anywhere.** IBX itself
  annotates the assignment as unused and unsupported by the payload format it builds. Contrast
  `ProcessDebitCard`'s surcharge, which is passed straight into the debit authorization and sale calls
  as a live argument with no such disclaimer. **This is IBX-side evidence about IBX's own processor
  bridge only — it is not evidence that Payroc drops EBT surcharge, and must not be read that way.**
  Escalate rather than assuming either way.
- **The `CaptureAll` fabricated-queue-response hazard applies to debit and does not apply to EBT —
  established for both, not assumed for either.** See the two `CaptureAll` rows below.
- **`Force`'s merchant-permission gate covers credit and debit but not EBT — a verified absence.** The
  check is applied on credit and on debit, and is not applied anywhere in `ProcessEBTCard`. The gate's
  own internal logic is not established.

## `ProcessDebitCard`

WSDL-declared `TransType` set: `Auth | Sale | Return | Force | Capture | CaptureAll` — no `Void`, no
`Inquire`. The live dispatch actually handles ten tokens, four of them undeclared (`Void`, `Reversal`,
`Inquire`, `ReEnter`); everything else falls through to `Result=3, "Invalid Transaction type"`.
`PostAuth` (row below) is a documented eleventh candidate that is **not** among the ten dispatched.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact.ProcessDebitCard {TransType=Auth}` | absorbed | `payment` + `autoCapture:false` | The debit authorization path takes four fewer parameters than the debit sale path — no tip amount, no Level 3 amount, no server ID and no `ExtData` reach the call on this token | `SCOPE:` an integration relying on tip, Level 3 or `ExtData` with `TransType=Auth` on debit **has never had them honoured** — unlike `Sale` below, and unlike credit's `Auth`, which does carry `ExtData`. | verified (which call IBX makes on this token and with which arguments; what that call then does downstream is not confirmed) |
| `SOAP transact.ProcessDebitCard {TransType=Sale}` | absorbed | `payment` + `autoCapture:true` | — | `SCOPE:` `ProcessDebitCard` never runs credit's shared request builder (see cross-cutting facts), so credit's AVS-only zero-amount `Sale`→`Auth` rewrite lives inside a function that categorically cannot fire here. Whether the debit sale path performs an equivalent rewrite internally is unverified — **do not assume debit either inherits or lacks one.** | inferred (the target follows Payroc's general "sale = auto-capture" convention; the debit sale path's own internals are not established) |
| `SOAP transact.ProcessDebitCard {TransType=Return}` | branch | `refundPayment` (`PNRef` present) \| `unreferencedRefund` (`PNRef` absent) | Unreferenced path: `+description`. Referenced path: resolve `paymentId` via `order.orderId` per `identifier-translation.md`. | `IF:` when `PNRef` is blank the internal reference defaults to a sentinel, and **nothing at the dispatch layer requires a match for `Return`** — unlike `ReEnter` below. Whether the debit refund path itself then enforces a match is unverified. | unverified (the dispatch permits an unreferenced call; downstream enforcement is not established) |
| `SOAP transact.ProcessDebitCard {TransType=Force}` | absorbed | `payment` + `offlineProcessing.operation` | `+offlineProcessing.operation` — the same unresolved carry-over question as `map-card-transactions.md`'s `Force` row | `CFG:` gated on a merchant permission. When the merchant does not hold it, the call returns `Result=1001, "Force Authorizations are not allowed."` **This is a merchant-permission gate with no named Payroc-side equivalent**; the gate's own logic is not established. | inferred (the target is carried from `map-card-transactions.md`'s `Force` row, not independently confirmed for debit) |
| `SOAP transact.ProcessDebitCard {TransType=Capture}` | direct — captures a pre-authorization; funds are taken | `capturePayment` | — | `SCOPE:` settles a **single** `PNRef`, not a batch. Contrast `CaptureAll` below. | verified |
| `SOAP transact.ProcessDebitCard {TransType=CaptureAll}` | absorbed (best-supported placeholder — the mechanism is `unverified`) | `closeBatch` (`POST /processing-terminals/{id}/close-batch`) | — | `SEMANTIC:` same fabricated-response shape as credit's `CaptureAll`. The branch checks whether a debit settlement is already queued (`Result=12` if so), otherwise queues the request and returns a **fabricated** `Result=0` with `RespMSG="CaptureAll Submitted. Use GetBatchStatus to confirm processor submission."` — a byte-identical message to credit's. **`Result=0` here does not mean the batch settled.** The downstream mechanism — what the queued background settlement actually does — is genuinely unverified. **Do not resolve this row from `map-batch-and-settlement.md`'s `ProcessBatch` finding**: this branch returns before ever reaching the code that operation dispatches through, so that conclusion does not transfer here, for the identical reason it does not transfer to `map-card-transactions.md`'s credit row. **`LOSS:` separately, even granting `closeBatch` as the eventual target, its documented scope is settling the transactions *captured* since the last close** — it performs no capture step of its own, so a merchant with pending uncaptured debit `Auth` transactions may not get them captured by `closeBatch` alone. **Default: call `capturePayment` on each pending authorization, then `closeBatch`** — see `map-batch-and-settlement.md`. Debit authorizations taken on IBX before cutover have no `paymentId` and must be captured on IBX by `PNRef` (the `Capture` row above), never drained with this token. | verified (the fabricated queued response) / **unverified** (both the downstream settlement mechanism and the Payroc-side target) |
| `SOAP transact.ProcessDebitCard {TransType=Void}` | branch — by the Payroc payment's state. IBX runs `Void` and `Reversal` through one branch, so the token says nothing about whether the batch has settled | By that payment's `supportedOperations`, first match wins: (1) a partial amount and `partiallyReverse` listed → `reversePayment` with `amount` \| (2) the full amount and `fullyReverse` listed → `reversePayment` \| (3) neither reverse token listed and `refund` listed → `refundPayment` with `amount` \| (4) anything else → escalate | On the `refundPayment` route, `+amount` and `+description` | `SCOPE:` `Void` and `Reversal` (below) are the **literal same dispatch branch** — one call, identical arguments. Not merely two tokens sharing a target, as credit's do: **IBX itself never distinguishes them here.** Undeclared in the WSDL. `IF:` **this token cannot tell you whether the batch has settled, so route by the Payroc payment's state.** Read that payment's current `supportedOperations` (see `identifier-translation.md`) and take the first branch in the target cell that matches. `reversePayment` cancels all or part of a payment in an open batch; it is scoped to an open batch, and Payroc documents no specific error for calling it on a settled payment, so do not call it for this token without that read, and do not rely on a wrong route being rejected. Payroc also documents that a refund against a payment still in an open batch reverses the payment, but not what a **partial** refund does there, so if branch (3) ever carries a partial amount, confirm the result in UAT before relying on it. | verified (the shared dispatch branch) / inferred (the routing by payment state) |
| `SOAP transact.ProcessDebitCard {TransType=Reversal}` | branch — the same call as `Void` above, routed the same way | By that payment's `supportedOperations`, first match wins: (1) a partial amount and `partiallyReverse` listed → `reversePayment` with `amount` \| (2) the full amount and `fullyReverse` listed → `reversePayment` \| (3) neither reverse token listed and `refund` listed → `refundPayment` with `amount` \| (4) anything else → escalate | On the `refundPayment` route, `+amount` and `+description` | See the `Void` row — identical dispatch branch, not merely an identical target. Undeclared in the WSDL. `IF:` **this token cannot tell you whether the batch has settled, so route by the Payroc payment's state.** Read that payment's current `supportedOperations` (see `identifier-translation.md`) and take the first branch in the target cell that matches. `reversePayment` cancels all or part of a payment in an open batch; it is scoped to an open batch, and Payroc documents no specific error for calling it on a settled payment, so do not call it for this token without that read, and do not rely on a wrong route being rejected. Payroc also documents that a refund against a payment still in an open batch reverses the payment, but not what a **partial** refund does there, so if branch (3) ever carries a partial amount, confirm the result in UAT before relying on it. | verified (the shared dispatch branch) / inferred (the routing by payment state) |
| `SOAP transact.ProcessDebitCard {TransType=Inquire}` | none (target undetermined, **not** confirmed absent — escalate) | `—` | n/a | Unlike credit's `Inquire`, this is a real, WSDL-adjacent **debit balance inquiry**, with the amount defaulting to `0` for this token. Payroc's `balanceCard` (`POST /cards/balance`) is EBT-scoped by its own description (*"View EBT balance"*), and no debit-balance equivalent was found anywhere in the Payroc API. **Do not assume `balanceCard` silently also serves debit; confirm with your Payroc implementation contact before relying on it.** | unverified (a real IBX capability, confirmed; no Payroc target found) |
| `SOAP transact.ProcessDebitCard {TransType=ReEnter}` | none (target undetermined — escalate) | `—` | n/a | **No credit-card analog** — absent from every declared `ProcessCreditCard` `TransType` set. Requires a resolved `PNRef` (`Result=26` otherwise), then forwards the reference and `ExtData` onward; that onward call's behaviour is not established. IBX's own documented `ExtData` tag list glosses the concept as *"processor specific settlement data"* — **a reading of adjacent documentation, not a confirmed target.** No matching Payroc concept was found in the EBT type enums, the published workflows or the documentation. | unverified |
| `SOAP transact.ProcessDebitCard {TransType=PostAuth}` | none | `—` — **IBX is already rejecting this call today, so there is nothing to port.** Check your logs for it before you migrate: if you are sending it, that code path has never worked and the fix belongs in your integration, not in the migration. **`PostAuth` on credit cards is a different matter and is mapped separately** — do not conclude it is gone everywhere | n/a | `SEMANTIC:` `PostAuth` is a real, dispatched token on `ProcessCreditCard`, and a debit branch for it does exist inside the unreachable part of the shared builder described in the cross-cutting facts — **so it can look supported.** The live `ProcessDebitCard` dispatch has **no branch for it at all**: it falls through to `Result=3, "Invalid Transaction type"`. **That is an outright rejection, not a decline or a degraded behaviour**, so a reader who treats it as a decline will look for the fix in the wrong place. | verified |

## `ProcessEBTCard`

WSDL-declared `TransType` set: `FoodStampSale | FoodStampReturn | CashBenefitSale | Capture |
CaptureAll`. The live dispatch actually covers **seventeen wire-distinct tokens across sixteen
branches** — one branch handles `Reversal` and `Void` together. Several tokens share one underlying
call; see the `SCOPE:` notes below. Everything else falls through to `Result=3`.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact.ProcessEBTCard {TransType=FoodStampSale}` | absorbed | `payment` + `card.cardDetails.ebtDetails{benefitCategory:foodStamp}` | `+ebtDetails.benefitCategory` — no IBX-side discriminator field; implicit from `TransType` | Response side reports `transactionResult.ebtType:foodStampPurchase`. | inferred (declared schema shape on both sides; no captured wire body confirms the pairing) |
| `SOAP transact.ProcessEBTCard {TransType=FoodStampVoucher}` | absorbed | `payment` + `ebtDetailsWithVoucher{benefitCategory:foodStamp, voucher:{approvalCode, serialNumber}}` | `+ebtDetailsWithVoucher.voucher` | `SCOPE:` on IBX this is **not** a separate operation from `FoodStampSale`: it is the literal same call, distinguished only by `<EBTPurchaseType>FoodStamp</EBTPurchaseType><EbtVoucher>T</EbtVoucher>` appended to `ExtData` beforehand. Undeclared in the WSDL — it exists only in the live dispatch. Response: `ebtType:foodStampVoucherPurchase`. | verified (the IBX half) / inferred (the Payroc pairing) |
| `SOAP transact.ProcessEBTCard {TransType=FoodStampReturn}` | absorbed | `refundPayment` (referenced — `identifier-translation.md`'s identifier bridge applies) + `ebtDetails{benefitCategory:foodStamp}` | `+ebtDetails.benefitCategory` | Response: `ebtType:foodStampReturn`. **Whether an unreferenced EBT return is possible** — credit's `unreferencedRefund` pattern — **is not established**; the EBT refund path's blank-`PNRef` handling has not been confirmed. | unverified (refund-branch behaviour not established; the Payroc pairing is inferred from schema shape only) |
| `SOAP transact.ProcessEBTCard {TransType=CashBenefitSale}` | absorbed | `payment` + `ebtDetails{benefitCategory:cash}` (+ `order.breakdown.cashbackAmount` if cashback taken) | `+ebtDetails.benefitCategory`; `+order.breakdown.cashbackAmount` when cashback is requested | Response distinguishes `cashPurchase` from `cashPurchaseWithCashback` by cashback presence. | inferred |
| `SOAP transact.ProcessEBTCard {TransType=CashBenefitWithdrawal}` | absorbed | `payment` + `ebtDetails{benefitCategory:cash, withdrawal:true}` | `+ebtDetails.withdrawal` | `SCOPE:` the same relationship as `FoodStampVoucher` above — the literal same call as `CashBenefitSale`, distinguished only by `<EbtWithdrawal>T</EbtWithdrawal>` appended to `ExtData`. Undeclared in the WSDL. Response: `ebtType:cashWithdrawal`. | verified (the dispatch) / inferred (the Payroc pairing) |
| `SOAP transact.ProcessEBTCard {TransType=Force}` | absorbed | `payment` + `offlineProcessing.operation` | `+offlineProcessing.operation` — the same unresolved carry-over question as `map-card-transactions.md`'s `Force` row and this file's debit `Force` row | `SCOPE:` **no merchant-permission gate at all** on this token — a verified absence. **A genuine three-way asymmetry: credit and debit gate `Force` on merchant permission, EBT does not.** Undeclared in the WSDL. | verified (the absence of the gate) / inferred (the Payroc target, carried from `map-card-transactions.md`) |
| `SOAP transact.ProcessEBTCard {TransType=EwicVoucherClear}` | none (target undetermined — escalate) | `—` | n/a | Undeclared in the WSDL and absent from IBX's own documented `ExtData` tag lists — it exists only in the live dispatch. Nothing in the Payroc API names it: the EBT benefit-category and `ebtType` enums carry no eWIC member and the published documentation has no eWIC concept. **Treat as a hard gap candidate, not a guessed absorption** — see `no-equivalent-register.md`. | unverified |
| `SOAP transact.ProcessEBTCard {TransType=SnapVoucherClear}` | none (same status as `EwicVoucherClear` — escalate) | `—` | n/a | `SCOPE:` the literal same call as `EwicVoucherClear` above. **Two wire tokens, one IBX implementation, no Payroc target found for either.** | unverified |
| `SOAP transact.ProcessEBTCard {TransType=EwicAuthorization}` | none (target undetermined — escalate) | `—` | n/a | Undeclared in the WSDL; it exists only in the live dispatch. No matching Payroc concept found. See `EwicSale` below for a related naming trap. | unverified |
| `SOAP transact.ProcessEBTCard {TransType=EwicSale}` | absorbed (best-supported reading — see caveat) | Same target as the `FoodStampSale` row above | Same as `FoodStampSale` | `SEMANTIC:` **despite the "eWIC" name suggesting a relationship to `EwicAuthorization`, the live dispatch runs the same function as `FoodStampSale`**, with a call to the eWIC authorization path commented out immediately above it. **The token's name does not describe its current behaviour; do not map this row from the name.** The mapping is provisional on that current behaviour continuing, not on the token's stated intent. | verified (the dispatch) / inferred (the Payroc pairing) |
| `SOAP transact.ProcessEBTCard {TransType=EwicCompletion}` | absorbed (best-supported reading — see caveat) | Same target as the `Capture` row below | — | `SEMANTIC:` runs the same generic EBT settlement function as plain `Capture` below; a separate eWIC-completion call is commented out, retired in 2019 on the grounds that the processor handler did not support it and it could be processed the same way as EBT. **A dedicated eWIC settlement concept was deliberately collapsed into generic EBT settlement.** No Payroc concept named for eWIC completion exists; the current IBX behaviour already treats this token as a plain capture, which is the best-supported target — and, as with `EwicSale`, the mapping is provisional on that behaviour continuing rather than on the token's name. | verified (the dispatch and the retiring comment) / inferred (the Payroc pairing) |
| `SOAP transact.ProcessEBTCard {TransType=Inquire}` | direct — queries a stored benefit balance; no funds move | `balanceCard` (`POST /cards/balance`) | — | IBX runs a genuine EBT balance inquiry here, supported since 2004. `balanceCard`'s own description names EBT explicitly (*"View EBT balance"*) and it appears in Payroc's published EBT-balance workflow. **The one row in this file confirmed on both sides.** | verified |
| `SOAP transact.ProcessEBTCard {TransType=ReEnter}` | none (target undetermined — escalate) | `—` | n/a | The same shape as debit's `ReEnter` row above — requires a resolved `PNRef` (`Result=26` otherwise), then forwards onward to a path whose behaviour is not established. No Payroc concept found; the same escalation, **not independently resolved for EBT.** | unverified |
| `SOAP transact.ProcessEBTCard {TransType=Void}` | branch — by the Payroc payment's state. IBX runs `Void` and `Reversal` through one branch, so the token says nothing about whether the batch has settled | By that payment's `supportedOperations`, first match wins: (1) a partial amount and `partiallyReverse` listed → `reversePayment` with `amount` \| (2) the full amount and `fullyReverse` listed → `reversePayment` \| (3) neither reverse token listed and `refund` listed → `refundPayment` with `amount` \| (4) anything else → escalate | On the `refundPayment` route, `+amount` and `+description` | `SCOPE:` the same merged-branch pattern as debit — one branch covers `Reversal` and `Void`, making one call. A commented-out separate `Void` implementation confirms one once existed and was retired in favour of the merge. `IF:` **this token cannot tell you whether the batch has settled, so route by the Payroc payment's state.** Read that payment's current `supportedOperations` (see `identifier-translation.md`) and take the first branch in the target cell that matches. `reversePayment` cancels all or part of a payment in an open batch; it is scoped to an open batch, and Payroc documents no specific error for calling it on a settled payment, so do not call it for this token without that read, and do not rely on a wrong route being rejected. Payroc also documents that a refund against a payment still in an open batch reverses the payment, but not what a **partial** refund does there, so if branch (3) ever carries a partial amount, confirm the result in UAT before relying on it. | verified (the shared dispatch branch) / inferred (the routing by payment state) |
| `SOAP transact.ProcessEBTCard {TransType=Reversal}` | branch — the same call as `Void` above, routed the same way | By that payment's `supportedOperations`, first match wins: (1) a partial amount and `partiallyReverse` listed → `reversePayment` with `amount` \| (2) the full amount and `fullyReverse` listed → `reversePayment` \| (3) neither reverse token listed and `refund` listed → `refundPayment` with `amount` \| (4) anything else → escalate | On the `refundPayment` route, `+amount` and `+description` | See the `Void` row. `IF:` **this token cannot tell you whether the batch has settled, so route by the Payroc payment's state.** Read that payment's current `supportedOperations` (see `identifier-translation.md`) and take the first branch in the target cell that matches. `reversePayment` cancels all or part of a payment in an open batch; it is scoped to an open batch, and Payroc documents no specific error for calling it on a settled payment, so do not call it for this token without that read, and do not rely on a wrong route being rejected. Payroc also documents that a refund against a payment still in an open batch reverses the payment, but not what a **partial** refund does there, so if branch (3) ever carries a partial amount, confirm the result in UAT before relying on it. | verified (the shared dispatch branch) / inferred (the routing by payment state) |
| `SOAP transact.ProcessEBTCard {TransType=Capture}` | direct — captures a pre-authorization; funds are taken | `capturePayment` | — | EBT capture has been supported since 2004 and settles against a single `PNRef`. | verified |
| `SOAP transact.ProcessEBTCard {TransType=CaptureAll}` | absorbed (best-supported reading — see caveat) | `closeBatch` (`POST /processing-terminals/{id}/close-batch`) — **carried by analogy only, not independently confirmed for EBT** | — | `SEMANTIC:` **EBT's `CaptureAll` does not share credit's and debit's fabricated-queue-response hazard.** Pre-dispatch handling is a log call only; the dispatch settles directly and synchronously — no already-queued check, no queue insert, no synthesized `Result=0`. That rules out the specific fabricated-response pattern documented for credit and debit. **But what a no-`PNRef` EBT settle does internally is not established** (settle one open batch? every pending EBT transaction? something else?) — and unlike credit and debit, this row's target is not corroborated by a matching IBX-side single-call shape confirmed for *this* operation. **Treat the target as carried by analogy, not separately established for EBT.** Separately, the `closeBatch`-scope caveat recorded on the debit row — it settles only already-captured transactions — would apply here too if the analogy holds; unverified either way for EBT specifically. **Default, if you take this target: call `capturePayment` on each pending authorization, then `closeBatch`** — it costs nothing if the caveat turns out not to apply. See `map-batch-and-settlement.md`. | verified (the absence of the fabricated-queue pattern) / unverified (the Payroc-side target, carried by analogy) |

## `transact2`

One delta row per operation `transact2` shares with `transact` in this file.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact2.ProcessDebitCard {TransType=Auth,Sale,Return,Force,Capture,CaptureAll,Void,Reversal,Inquire,ReEnter,PostAuth}` | direct — the *same objects running the same code*, with no transformation in between | Same target as the corresponding `ProcessDebitCard` row above, for every token listed | Endpoint only: `/ws/transact2.asmx`. | — | verified. **Treat each row's confidence here as capped by the corresponding row above, never higher** |
| `SOAP transact2.ProcessEBTCard {TransType=FoodStampSale,FoodStampVoucher,FoodStampReturn,CashBenefitSale,CashBenefitWithdrawal,Force,EwicVoucherClear,SnapVoucherClear,EwicAuthorization,EwicSale,EwicCompletion,Inquire,ReEnter,Void,Reversal,Capture,CaptureAll}` | direct — the *same objects running the same code*, with no transformation in between | Same target as the corresponding `ProcessEBTCard` row above, for every token listed | Endpoint only: `/ws/transact2.asmx`. Field-name note: `transact2`'s schema and documentation spelling for the surcharge parameter is `SureChargeAmt` on **both** operations (see cross-cutting facts), matching neither of `transact`'s own two spellings. **A client switching services and mis-mapping this one field is the only behavioural risk here** — it is not a dispatch difference. | — | verified. **Treat each row's confidence here as capped by the corresponding row above, never higher** |

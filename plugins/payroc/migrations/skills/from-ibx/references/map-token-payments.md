# IBX → Payroc: charging a vaulted token — `cardsafe`

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> the IBX `cardsafe` service's two money-movement operations — `ProcessCreditCard` and `ProcessCheck`,
> over both SOAP and REST — to the Payroc API. Per-row confidence is carried in the `C` column; the
> legend is in [`_sources.md`](./_sources.md). Last synced: 2026-09-04. Read mappings from this file,
> not from memory — a plausible-sounding mapping that isn't here will look correct in review and fail
> in production.
>
> **Why the SOAP rows are badged lower than their REST twins.** The two transports reach the same
> money movement, but the REST surface is the better-evidenced of the pair. Where a SOAP row carries
> a lower badge than the REST row beside it, that reflects **how much confirmation was available for
> that transport, not a difference in behaviour between them.** If you are on SOAP and a row reads
> weakly, the REST twin is usually the better description of what actually happens.

```text
IN:  SOAP /ws/cardsafe.asmx -- ProcessCreditCard, ProcessCheck only, i.e. taking money with
     an already-vaulted token. REST /cardsafe/processcreditcard, /cardsafe/processcheck.
OUT: cardsafe.StoreCard / StoreCardFromPNRef / UpdateCardInfo / UpdateCardNumber /
     GetCardExpiration -- map-tokens-and-vault.md -- managing a token, not charging one.
     transact.asmx's OWN ProcessCreditCard (raw card-present/not-present) --
     map-card-transactions.md -- a DIFFERENT operation, different service, different
     parameters, different target. Do not conflate the two; every row below keys on
     cardsafe.ProcessCreditCard, never bare ProcessCreditCard. REST /transactions --
     map-rest-transactions.md.
ADJACENT: identifier-translation.md holds cross-cutting identifier, amount, expiry and
     currency facts, cited from the rows below rather than restated per row. If your call is
     not in the table below, it is not absent from IBX -- check the sibling files above, then
     SKILL.md's routing table, then ask for a request sample.
```

**Where to implement what you find here:** `save-a-payment-method` owns the token itself;
`run-a-card-sale`, `run-a-pre-authorization` and `refund-a-card-payment` own the card money-movement
schemas; `take-an-ach-payment` and `refund-an-ach-payment` own the bank-transfer ones;
`integrate-google-pay` covers `TokenMode=googlepay`. This file owns the delta.

## Cross-cutting facts

Stated once here; see `identifier-translation.md` for the full detail.

- **Currency, amount and expiry behave exactly as they do on the raw-card surfaces.**
  `order.currency` is required by Payroc and has no source in any IBX request on any surface. Card
  expiry is `MMYY` on both platforms — no digit-pair conversion in either direction — but Payroc's
  four-digit pattern does not range-check the month, so range-check it yourself. On amounts, the SOAP
  validator accepts up to twelve characters and does **not** enforce the documented `DDDDD.CC`, so
  your intake must tolerate legacy rows above `99999.99` — but **`99999.99` remains the recommended
  ceiling for what you send**, because IBX's REST card amount is a single-precision float that turns
  `999999.99` into `1000000.00`, and the failure mode is silent rounding rather than an error. See
  `identifier-translation.md`. The two-decimal rule *is* enforced, so the
  conversion to minor units is exact — but apply ×100 **only for two-decimal currencies**, since
  Payroc's currency enum includes zero-decimal (`JPY`, `KRW`) and three-decimal (`BHD`, `KWD`)
  entries and the currency resolves from configuration rather than from your request.
- **Every SOAP row below is capped at `inferred`/`unverified`, and the cap is about the evidence, not
  about a weak claim.** The `cardsafe` SOAP handler's own behaviour could not be established. The REST
  validators are the best available evidence for how IBX accepts these calls, one layer of indirection
  removed — the REST CardSafe surface calls the SOAP service *and* touches the database directly.
- **Two of the three transaction endpoints accept an unrecognised transaction type rather than
  rejecting it, and the three behave differently in three different ways.** Keep them apart:
  - `/cardsafe/processcreditcard` has **no whitelist at all** — its validator requires only that
    `TransType` be non-empty. An unrecognised token is silently accepted into a default branch, not
    rejected.
  - `/transactions` compares **ordinally**, so a wrong-case token matches no constant, **falls out of
    every conditional guard, and is accepted with its `originalTransaction`/`pnRef` check skipped.**
  - `/cardsafe/processcheck` is the only one of the three that **rejects with a message**.

  So: **emit the exact documented token.** A wrong one usually fails *later*, not at the API.
- **The two `cardsafe` operations genuinely disagree on case sensitivity, by two different
  mechanisms.** Do not unify them. `ProcessCheck`'s whitelist is exactly seven exact-case strings
  compared ordinally against a mixed-case list — so `"Sale"` passes and `"SALE"` and `"sale"` are both
  rejected. `ProcessCreditCard` has no whitelist to be sensitive about; its comparison is
  case-insensitive, and it selects *which conditional rules apply* rather than deciding validity.
  Emit the exact documented casing for `ProcessCheck`; `ProcessCreditCard` is more forgiving, but a
  wrong token there fails later, silently, inside the default branch rather than at the API boundary.
- **`ProcessCreditCard`'s validator proves referenced-only for four of its five named branches**, which
  is a stronger claim than `map-card-transactions.md` can make for raw-card transactions. `void`,
  `adjustment`, `reversal` and `increment` all require `originalTransaction` to be non-null —
  **`return` is the sole, explicit exception.** `Force`, `RepeatSale` and `PostAuth` are outside this
  five-item set entirely and carry no such requirement.
- **`ProcessCheck` has no `PNRef`/`originalTransaction` field anywhere in its schema at all** — a real
  asymmetry from the credit-card operation above. The only evidence of how a referenced `Return`/`Void`
  works on this operation is two request bodies from IBX's own test fixtures embedding
  `<PNRef>...</PNRef>` **inside the free-text `ExtData` blob** — an undocumented convention, not a validator or handler rule, and
  `unverified` rather than a confirmed contract.
- **`TokenMode` accepts the same four runtime values as `map-tokens-and-vault.md`** — `default`,
  `googlepay`, `cardformat`, `jstoken`, case-insensitive — on both operations. **Always emit
  `googlepay`, never `google`.** There is a real validator asymmetry between the two operations: on
  `ProcessCreditCard` the `TokenMode` check fires only when `TransType` is *outside* the five-item
  `void, adjustment, return, reversal, increment` set, so for those five tokens `TokenMode` is
  **unvalidated** on that operation; `ProcessCheck`'s equivalent check is unconditional. **Whether a
  token vaulted under one mode can be redeemed under a different mode here is `unverified`** — but on
  the Payroc side this question has **no counterpart to carry across**: `secureTokenPayload` and
  `singleUseTokenPayload` carry no mode concept at all, so however IBX answers it, nothing changes on
  the target side.
- **`ExtData` handling for `cardsafe` is untraced.**
  Neither `cardsafe`'s nor `recurring`'s `ExtData` parsing has ever been traced to a handler. Every
  `ExtData` tag named in the rows below — `SurchargeAmt`, `TaxExempt`, `CVNum`, `PNRef` on
  `ProcessCheck`, arbitrary `CustomFields` — is a wire-observed convention, never a validator or
  handler rule. Treat all of them as `unverified` conventions, not as a documented contract.
- **`Capture`/`CaptureAll` are not declared, not validated, and have zero wire evidence on
  `cardsafe.ProcessCreditCard`** — absent from the documented six-value set, absent from the
  validator's named branches, and absent from all 113 captured requests to this operation across every
  transport. **Do not assume either token works on this operation; ask for a request sample rather
  than guessing whether it shares `map-card-transactions.md`'s fabricated-queue hazard or any other
  behaviour.** (Both tokens *are* validator-whitelisted on `ProcessCheck` — see that operation's own
  rows.)
- **A real, unresolved surcharge-field ambiguity, specific to `ProcessCreditCard`.** The schema
  declares a typed `invoiceData.surchargeAmount` field, but all four captured samples that exercise
  surcharge — one SOAP, three REST — send it as `ExtData.<SurchargeAmt>` instead, never touching the
  typed field. Which one, or both, IBX honours is unconfirmed. Do not assert either is "the" carrier.
- **A likely capability gap, not yet resolved.** IBX's token-charge CVV re-verification
  travels as `ExtData.<CVNum>`, wire-confirmed on four samples (two SOAP, two REST). Payroc's
  `secureTokenPayload` has no CVV field of any kind, checked directly against the full schema.
  **Confirm with your Payroc implementation contact before treating this as a hard loss.**
- **`cardData.entryMode: COF` is two occurrences via two different mechanisms, not one.** SOAP sends
  `ExtData:"<EntryMode>COF</EntryMode>"`; REST sends a structured `cardData:{"entryMode":"COF"}`. The
  REST form is the more concerning of the two: `cardData` **is not a declared property of this
  operation's request at all** — that schema carries `TransType`, `CardToken`, `TokenMode`, `Amount`,
  `invoiceData`, `InvNum`, `originalTransaction` and `ExtData` only, and `cardData` belongs to the
  `/transactions` surface (`map-rest-transactions.md`'s territory). The REST sample may simply be
  sending a field this endpoint silently drops — a **stronger** reason to escalate rather than map, not
  a weaker one. Payroc's `credentialOnFile`/`mitAgreement` is the closest structural analogue to
  whatever "COF" is meant to signal; nothing licenses asserting they correspond. **Escalate, do not
  map.**
- **EMV and Level 3 fields are structurally absent from both operations, and this is a property of the
  operations, not a gap in what is known**: neither operation ever receives raw card-present or terminal
  data — only a token — and `Level3Data`/`emvData` in the wider specification are referenced only by
  the `/transactions` surface, confirmed by checking every schema that refers to them.

## `cardsafe.ProcessCreditCard`

Ten tokens carry real evidence: six from the REST schema's own documented set — `Sale`, `Auth`,
`Return`, `Void`, `Force`, `RepeatSale` — plus four branch labels the runtime validator recognises but
that documented set omits — `Adjustment`, `Reversal`, `Increment`, `PostAuth`. All ten are
wire-confirmed except as noted per row.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP cardsafe.ProcessCreditCard {TransType=Sale}` | absorbed | `payment` + `paymentMethod.type:secureToken` + `autoCapture:true` | `CardToken`→`paymentMethod.secureToken.token` | — | inferred (SOAP-side behaviour not established — see cross-cutting facts) |
| `REST POST /cardsafe/processcreditcard {TransType=Sale}` | absorbed | same as SOAP row above | same as SOAP row | — | inferred (IBX's own acceptance rule is confirmed — the validator requires only a non-empty `TransType`; the Payroc pairing is a shape match only) |
| `SOAP cardsafe.ProcessCreditCard {TransType=Auth}` | absorbed | `payment` + `paymentMethod.type:secureToken` + `autoCapture:false` | same as `Sale` | — | inferred |
| `REST POST /cardsafe/processcreditcard {TransType=Auth}` | absorbed | same as SOAP row above | same | — | inferred |
| `SOAP cardsafe.ProcessCreditCard {TransType=Return}` | branch | `refundPayment` (referenced) \| `unreferencedRefund` (unreferenced, `+refundMethod.type:secureToken`) | **The two targets are not schema-symmetric.** `refundPayment`'s referenced body is `operator`, `amount`, `description` only — it has **no `paymentMethod`/`refundMethod` field at all**; only `unreferencedRefund` requires one, with `card`/`secureToken` variants. **Both bodies require `+description`** — a field with no IBX source on **either** path, not just the unreferenced one. | `IF:` `Return` is the sole named branch this operation's validator exempts from requiring `originalTransaction` (see cross-cutting facts) — a stronger, validator-proven branch than `map-card-transactions.md` can establish for raw-card `Return`. `CFG:` `unreferencedRefund`'s own description states it is "available only on certain accounts" — a gating caveat to raise with the developer, not just a field note. | verified (the referenced/unreferenced split itself, from the runtime validator; the Payroc-side schema shapes independently confirmed) |
| `REST POST /cardsafe/processcreditcard {TransType=Return}` | branch — same split as SOAP row above | same as SOAP row above | same asymmetry as SOAP row above | see SOAP row | verified (validator; Payroc-side schema shapes) |
| `SOAP cardsafe.ProcessCreditCard {TransType=Void}` | direct — cancels an open payment; no funds taken | `reversePayment` | resolve `paymentId` via `order.orderId` per `identifier-translation.md` | `IF:` requires `originalTransaction` unconditionally (see cross-cutting facts). Whether IBX itself treats `Void` and `Reversal` (below) as the same call — a question `map-card-transactions.md` and `map-debit-and-ebt.md` settle for other surfaces — is **unverified here**. | verified (the requirement itself) / unverified (the same-call-as-`Reversal` question) |
| `REST POST /cardsafe/processcreditcard {TransType=Void}` | direct — same behaviour as SOAP row above | same as SOAP row above | same | see SOAP row | verified (validator) / unverified (same as SOAP row) |
| `SOAP cardsafe.ProcessCreditCard {TransType=Reversal}` | **inferred pairing, not a direct equivalent** — an IBX `Reversal` may arrive after the batch has settled, and `reversePayment` covers only a payment in an open batch | By that payment's `supportedOperations`, first match wins: (1) a partial amount and `partiallyReverse` listed → `reversePayment` with `amount` \| (2) the full amount and `fullyReverse` listed → `reversePayment` \| (3) neither reverse token listed and `refund` listed → `refundPayment` with `amount` \| (4) anything else → escalate | same as `Void`; on the `refundPayment` route, also `+amount` and `+description` (both required) | `IF:` **route by the Payroc payment's state, not by the IBX token.** Read that payment's current `supportedOperations` (see `identifier-translation.md`) and take the first branch in the target cell that matches. `reversePayment` cancels all or part of a payment in an open batch; it is scoped to an open batch, and Payroc documents no specific error for calling it on a settled payment, so do not call it for this token without that read, and do not rely on a wrong route being rejected. Payroc also documents that a refund against a payment still in an open batch reverses the payment, but not what a **partial** refund does there, so if branch (3) ever carries a partial amount, confirm the result in UAT before relying on it. `IF:` requires `originalTransaction` unconditionally. Every captured sample for this token is referenced — carrying `originalTransaction.pnRef`, some with a reduced `amount` for a partial reversal — so the unreferenced-reversal ambiguity `map-card-transactions.md` flags for raw-card `Reversal` may not even arise on this token surface, since the validator requires a reference unconditionally. Its IBX-side evidence is stronger than that file's own `Reversal` row; the Payroc routing is the same. | verified (validator requirement plus captured samples) / inferred (the routing onto `refundPayment` or `reversePayment`) |
| `REST POST /cardsafe/processcreditcard {TransType=Reversal}` | inferred pairing — same as SOAP row above | same as SOAP row above | same | see SOAP row | verified (same basis) / inferred (the routing, same as SOAP row above) |
| `SOAP cardsafe.ProcessCreditCard {TransType=Force}` | absorbed | `payment` + `offlineProcessing.operation` | `+offlineProcessing.operation` — same unresolved carry-over as `map-card-transactions.md`, `map-debit-and-ebt.md` and `map-check-cash-and-stored-value.md` | Not among the five tokens requiring `originalTransaction` — no reference needed, unlike `Void`/`Reversal`/`Adjustment`/`Increment` above. | inferred (target carried from `map-card-transactions.md`'s evidence, not independently confirmed for this token surface) |
| `REST POST /cardsafe/processcreditcard {TransType=Force}` | absorbed | same as SOAP row above | same | same | inferred |
| `SOAP cardsafe.ProcessCreditCard {TransType=RepeatSale}` | absorbed | `payment` + `order.standingInstructions` | same unresolved sub-field question as `map-card-transactions.md`'s `RepeatSale` row | Also outside the `originalTransaction`-required set. | inferred (carried from `map-card-transactions.md`) |
| `REST POST /cardsafe/processcreditcard {TransType=RepeatSale}` | absorbed | same as SOAP row above | same | same | inferred |
| `SOAP cardsafe.ProcessCreditCard {TransType=Adjustment}` | absorbed | `adjustPayment` with `adjustments[].type:tip` | `+type:tip` — **more specific than `map-card-transactions.md`'s raw-card `Adjustment` guess**, because this operation's validator requires `invoiceData.tipAmount` specifically whenever `TransType=ADJUSTMENT`, confirmed by three captured samples across all three `TokenMode` variants | `IF:` requires `originalTransaction` unconditionally (same set as `Void`/`Reversal`/`Increment`). | verified (the tip-specific validator requirement, plus matching captured samples) |
| `REST POST /cardsafe/processcreditcard {TransType=Adjustment}` | absorbed — same tip-specific target as SOAP row above | same as SOAP row above | **Not "same as SOAP row above."** SOAP samples carry the tip as `ExtData:"<TipAmt>12.27</TipAmt>"`; REST samples carry it as the **typed** `invoiceData.tipAmount` field the validator itself checks. Two different carriers for the same value on the two transports of the same operation — a real transport-specific delta, not a restatement. | same requirement as SOAP row | verified (both carriers confirmed directly against captured samples) |
| `SOAP cardsafe.ProcessCreditCard {TransType=Increment}` | absorbed | `adjustPayment` with `adjustments[].type:order` (unconfirmed sub-type, same as `map-card-transactions.md`) | `+type:order` | `IF:` requires `originalTransaction` unconditionally — a stronger basis than `map-card-transactions.md` had for its own `Increment` row, which rested on an enum-only `supportedOperations` member. | verified (the requirement itself) / inferred (the sub-type, carried from `map-card-transactions.md`) |
| `REST POST /cardsafe/processcreditcard {TransType=Increment}` | absorbed — same as SOAP row above | same as SOAP row above | same | same | verified (requirement) / inferred (sub-type) |
| `SOAP cardsafe.ProcessCreditCard {TransType=PostAuth}` | absorbed | `payment` + `offlineProcessing.operation:deferredAuthorization` (a lexical match on the operation name only, same as `map-card-transactions.md`) | `+offlineProcessing.operation` | `SCOPE:` **both `TransType` comparison mechanisms on this operation are case-insensitive**, so `"VOID"`, `"void"` and `"Void"` all match. **But the comparison is not whitespace-tolerant on your value**: read the two operands separately — the whitelist entry is trimmed *and* upper-cased, your value is only upper-cased. So `" void"` with any leading or trailing space matches **nothing** and falls out of every conditional guard, exactly as a wrong-case token does on `/transactions` (see cross-cutting facts). **A migrating client that pads a value from a UI field or a CSV column hits this silently.** An empty or null value short-circuits to no match before the comparison runs. Not in the `originalTransaction`-required set, unlike `map-card-transactions.md`'s `PostAuth`, which shared `Force`'s "validate fresh card data" branch — that branch does not exist on a token-only surface at all. | verified (both comparisons' case-insensitivity) / inferred (the Payroc target, carried from `map-card-transactions.md`) |
| `REST POST /cardsafe/processcreditcard {TransType=PostAuth}` | absorbed — same as SOAP row above | same as SOAP row above | same | same | verified (case-insensitivity) / inferred (target) |

## `cardsafe.ProcessCheck`

Seven tokens, all validator-whitelisted, only four wire-confirmed: `Sale`, `Return`, `Auth`, `Void`.
**`Force`/`Capture`/`CaptureAll` are accepted in principle but have zero wire evidence anywhere** —
each row says so; do not assume they work.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP cardsafe.ProcessCheck {TransType=Sale}` | absorbed | `bankTransferPayment` + `paymentMethod.type:secureToken` | `CheckToken`→`paymentMethod.secureToken.token` | `bankTransferPayment`'s own description explicitly names secure and single-use tokens created from ACH or PAD details as valid sources — a real, citable operation-level split mirroring IBX's own credit/check separation, not a collapse. | inferred (SOAP-side behaviour not established) |
| `REST POST /cardsafe/processcheck {TransType=Sale}` | absorbed | same as SOAP row above | same | same | verified (this token is in the case-sensitive whitelist) / inferred (the Payroc pairing) |
| `SOAP cardsafe.ProcessCheck {TransType=Auth}` | none (target undetermined — escalate) | `—` | n/a | Carries forward `map-check-cash-and-stored-value.md`'s finding for raw-check `Auth`: the `bank-transfer-payments` schema family has no structural auth-then-capture step. Nothing here changes that — zero captured samples exercise this token on this operation either. **Do not assume this token silently works via `bankTransferPayment`'s single-step call.** | unverified (no wire evidence; the Payroc-side gap is carried from `map-check-cash-and-stored-value.md`, not separately established for this row) |
| `REST POST /cardsafe/processcheck {TransType=Auth}` | none (same status as SOAP row above) | `—` | n/a | same | verified (whitelisted) / unverified (Payroc target, per SOAP row) |
| `SOAP cardsafe.ProcessCheck {TransType=Return}` | branch | `refundBankTransferPayment` (referenced) \| `bankTransferUnreferencedRefund` (unreferenced, `+refundMethod.type:secureToken`) | **The same asymmetry as the credit-card `Return` rows above:** `refundBankTransferPayment`'s referenced body is `amount`, `description` only — no payment-method field at all; only the unreferenced target requires one. Both bodies require `+description`, a field with no IBX source on either path. | `LOSS:`/`SCOPE:` this operation has **no `PNRef`/`originalTransaction` field anywhere in its schema.** The only evidence that a referenced `Return` is even possible is one test-fixture request body embedding `<PNRef>...</PNRef>` inside the free-text `ExtData` blob — an undocumented convention, not a validator or handler rule. **Treat the referenced path as `unverified`, not as confirmed-supported.** | unverified (the referenced-path mechanism rests on a single fixture body) / verified (the Payroc-side schema shapes) |
| `REST POST /cardsafe/processcheck {TransType=Return}` | branch — same as SOAP row above, same caveat | same as SOAP row above | same asymmetry as SOAP row above | same | unverified (single-sample evidence) / verified (the Payroc-side schema shapes) |
| `SOAP cardsafe.ProcessCheck {TransType=Void}` | direct — cancels a payment before settlement; no funds taken | `reverseBankTransferPayment` | same undocumented `ExtData.<PNRef>` convention as `Return` above — one test-fixture body, never a validator rule | `LOSS:` same referencing caveat as `Return`. **One part is settled**: `reverseBankTransferPayment`'s request has **no body at all** — only a path `paymentId` and an idempotency header — so "does it accept a `secureToken`-sourced payment" is not the right question; there is no payment-method field on this call for *any* source type, referenced or not. Once `paymentId` is resolved (via the `ExtData.<PNRef>` convention above), the reversal itself needs nothing token-specific. | unverified (the referencing mechanism) / verified (Payroc side: no request body of any kind) |
| `REST POST /cardsafe/processcheck {TransType=Void}` | direct — same as SOAP row above | same as SOAP row above | same | same | unverified (same caveats) |
| `SOAP cardsafe.ProcessCheck {TransType=Force}` | none (target undetermined — escalate) | `—` | n/a | Carries forward `map-check-cash-and-stored-value.md`'s finding: no bank-transfer `offlineProcessing` analogue was found, on that file's own hedge that the search was not exhaustive. Zero wire evidence here. | unverified |
| `REST POST /cardsafe/processcheck {TransType=Force}` | none (same status as the SOAP row above) | `—` — same as the SOAP row above; escalate it once, not twice | n/a | Validator-whitelisted but zero wire evidence anywhere. | verified (whitelisted) / unverified (target, and functional usage) |
| `SOAP cardsafe.ProcessCheck {TransType=Capture}` | none (target undetermined — escalate) | `—` | n/a | Carries forward `map-check-cash-and-stored-value.md`'s structural gap — no capture-after-auth concept was found for bank transfers. Zero wire evidence for this token on this operation. `ADJACENT:` batch-wide check settlement may be `map-batch-and-settlement.md`'s territory, the same note `map-check-cash-and-stored-value.md`'s raw-check rows carry. | unverified |
| `REST POST /cardsafe/processcheck {TransType=Capture}` | none (same status as the SOAP row above) | `—` — same as the SOAP row above; escalate it once, not twice | n/a | Validator-whitelisted but zero wire evidence. | verified (whitelisted) / unverified (target, and functional usage) |
| `SOAP cardsafe.ProcessCheck {TransType=CaptureAll}` | none (target undetermined — escalate) | `—` | n/a | Same structural gap and the same zero wire evidence as `Capture` above. | unverified |
| `REST POST /cardsafe/processcheck {TransType=CaptureAll}` | none (same status as the SOAP row above) | `—` — same as the SOAP row above; escalate it once, not twice | n/a | Validator-whitelisted but zero wire evidence. | verified (whitelisted) / unverified (target, and functional usage) |

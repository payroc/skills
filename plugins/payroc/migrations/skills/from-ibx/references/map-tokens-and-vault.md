# IBX → Payroc: card vaulting and account updater — `cardsafe` / `accountupdaterinfo` / `/admin/jstoken`

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> IBX's card-vaulting surfaces to the Payroc API, covering `StoreCard`, `StoreCardFromPNRef`,
> `UpdateCardInfo`, `UpdateCardNumber`, `GetCardExpiration`, `GetAccountUpdaterReport` and browser
> tokenization. Per-row confidence is carried in the `C` column; the legend is in
> [`_sources.md`](./_sources.md). Last synced: 2026-09-24. Read mappings from this file, not from
> memory — a plausible-sounding mapping that isn't here will look correct in review and fail in
> production.

```text
IN:  SOAP /ws/cardsafe.asmx -- StoreCard, StoreCardFromPNRef, UpdateCardInfo, UpdateCardNumber,
     GetCardExpiration. SOAP /ws/accountupdaterinfo.asmx -- GetAccountUpdaterReport. REST
     /cardsafe/storecard, /storecardfrompnref, /updatecardinfo, /updatecardnumber,
     /admin/jstoken, /reporting/AccountUpdater. This file is about MANAGING a stored payment
     method.
OUT: cardsafe.ProcessCreditCard / cardsafe.ProcessCheck, SOAP and REST -- map-token-payments.md.
     That is taking money with a token, not managing one.
ADJACENT: map-token-payments.md for actually charging a vaulted token.
     identifier-translation.md holds cross-cutting identifier, amount, expiry and currency facts,
     cited from the rows below rather than restated per row -- including the distinction between
     CardToken (this file's vault) and CardInfoKey (the recurring family's separate vault), which
     is a genuine trap. If your call is not in the table below, it is not absent from IBX --
     check map-token-payments.md, then SKILL.md's routing table, then ask for a request sample.
```

**Where to implement what you find here:** `save-a-payment-method` for storing and updating a vaulted
card, `integrate-hosted-fields` and `create-single-use-token` for the browser-tokenization flows,
`integrate-google-pay` for `TokenMode=googlepay`. This file owns the delta; those skills own the
request schema.

## Cross-cutting facts

Stated once here; see `identifier-translation.md` for the full detail.

- **Stored tokens do not have to be re-vaulted.** Payroc publishes a supported token-migration
  process, run as an intake with the Gateway Team, with a lead time of roughly **30 business
  days**. It is an established route for IBX, so plan around it rather than treating it as
  unproven. Re-vaulting cardholders is the marked fallback, not the default plan.
- **Two things about the export file decide whether the import is viable, and both are cheap to
  check early.**
  - **Confirm your export contains full card numbers.** The IBX export's first three columns are
    the token, the card number and the expiry, which covers the three fields Payroc's import
    requires a value for (`merchantref`, `cardNumber`, `cardExpiry`). **But
    if your export masks the card number, the import cannot be fed from it and you are back to
    re-vaulting.** Ask the Gateway Team for one real, unredacted row before you plan around the
    import; it is a five-minute check that decides weeks of work. **This skill cannot tell you
    which way it goes for your export** — the samples available to it are masked, and that may
    be redaction for sending rather than the tool's behaviour.
  - **Convert the expiry; do not copy it.** The IBX export writes it with a separator (`08/29`).
    Payroc's import accepts `MMYY`, `YYMM`, `MMYYYY` or `YYYYMM`, **all without a separator**,
    and every record in one file must use the same format. A straight column copy fails.
- **Payroc's import file has its own shape, and a reformat is needed whatever IBX exports.**
  Separate values with semicolons or commas. Column order doesn't matter, but every column in
  Payroc's table must be present except `cof` and `transactionReference`, which you can leave out.
  An optional column that has no data stays in the file with the field empty. Send at most
  **100,000 records per file**. Above that, split across files and tell the Gateway Team how many
  to expect. `cof` (`Y`/`N`) records whether the cardholder agreed to have the card stored, and a
  missing or empty value is read as `N`.
- **Choose each `merchantref` before the first file, because it is permanent.** It is the stored
  card's identifier after import and can't be changed afterwards. It must be unique within the
  file and for the terminal. The same card sent under two references becomes two stored cards.
  To resend a corrected file, reuse the original references and contact the Gateway Team first.
- **Bank accounts can't be migrated.** IBX exports check and ACH tokens in the same file format,
  with bank-account columns in place of the card ones, but Payroc's token import accepts **card
  data only**. Plan to collect bank account details from customers again on Payroc. Don't wait
  for an ACH import path.
- **The published process describes only the import direction.** An **export** direction is
  offered on the intake form, but its mechanism is undocumented. Do not assume either
  that migration is import-only or that export works the same way in reverse — ask your
  implementation contact what the export path actually is before committing to it.
- **Card expiry is `MMYY` on both platforms** — no digit-pair conversion in either direction,
  including on IBX's REST vaulting surface, whose runtime accepts month `01`–`12` and year `19`–`39`
  only. So a card expiring in 2040 or later cannot be represented in IBX at all. Payroc's four-digit
  pattern does not range-check the month, so **range-check it yourself before sending.**
- **`TokenMode` takes exactly four runtime values, case-insensitive: `default`, `googlepay`,
  `cardformat`, `jstoken`.** IBX's published specification lists `google`, `match` and `apple`; those
  are wrong and must never be emitted. **Always `googlepay`.** (Payroc's own wallet enum is a separate
  vocabulary — see the `googlepay` row below.)
- **IBX's REST vaulting layer both calls the SOAP service and reads the payment-server database
  directly.** It is therefore not a thin transport over SOAP, and "REST validates the same way SOAP
  does" is a reasonable working assumption rather than a guarantee. Where a REST row and its SOAP
  sibling below differ, they differ for real.
- **Every SOAP-side row below is capped at `inferred` or `unverified`.** That cap is about the
  strength of the evidence behind the pairing, not a signal that the underlying behaviour is doubtful.
  Where a row has both a SOAP and a REST form, treat the REST row as the better-evidenced statement of
  IBX's own rule, and ask for a request sample before relying on a SOAP-only detail.
- **`GetCardExpiration` and `GetAccountUpdaterReport` sound alike and are not alike — do not conflate
  them.** `GetCardExpiration` filters IBX's own **already-stored** `ExpDate` values by a begin/end
  month-year range; it is a vault query. `GetAccountUpdaterReport` is a change log of updates a **card
  network's** automatic account-updater program has already applied to vaulted cards
  (`OldExpDate`→`NewExpDate`, `UpdateDateTime`); it does not query current state and does not trigger
  anything. The two rows below are hedged separately, and neither is evidence for the other.

## `cardsafe` vaulting operations

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP cardsafe.StoreCard {TokenMode=default,cardformat}` | absorbed | `createSecureToken` (`POST /processing-terminals/{id}/secure-tokens`, `source.type:card`) | `CustomerKey` has no required Payroc counterpart — `secureTokenId` is caller-optional and Payroc generates one if you omit it | — | inferred (shape match only; no captured request/response pair) |
| `REST POST /cardsafe/storecard {tokenMode=default,cardformat}` | absorbed | same as SOAP row above | `customerKey` is **required unless `tokenMode=jstoken`** — stricter than Payroc, which never requires a caller-supplied token id | — | inferred (IBX's own acceptance rule is confirmed; the Payroc pairing is a shape match) |
| `SOAP cardsafe.StoreCard {TokenMode=googlepay}` | none (hard gap — escalate) | `—` | n/a | `SCOPE:` **Payroc's wallet vocabulary is not this field under another name.** Payroc's `serviceProvider` (`apple`/`google`) belongs to one-shot `payment` calls and to card *verification* (`verifyCard`, `/cards/verify`) — note that this is Payroc's enum, unrelated to IBX's `TokenMode`, which is always `googlepay`. The vaulting request's `source` has **no** wallet variant, and `verifyCard` returns only a validity result, never a persistent token. This is a different naming scheme for a different capability. **A customer vaulting a Google Pay token through IBX has no confirmed Payroc vaulting target** — escalate. The Payroc-side gap was checked across the token-issuing and card-verification surfaces; it is not an exhaustive sweep of every Payroc API. | unverified |
| `REST POST /cardsafe/storecard {tokenMode=googlepay}` | none (same status as SOAP row above) | `—` | n/a | Same gap as the SOAP row above. | verified (IBX itself accepts the mode) / unverified (the Payroc target, same as the SOAP row) |
| `SOAP cardsafe.StoreCard {TokenMode=jstoken}` | sequence | `createSession` (`POST /processing-terminals/{id}/hosted-fields-sessions`, `scenario:tokenization`) → browser-side Hosted Fields interaction → `createSecureToken` (`source.type:singleUseToken`) | The `CustomerKey` requirement is waived on this token mode, matching Payroc's own lack of a required caller-supplied id | `SEQ:` see the `/admin/jstoken` row below for the browser-tokenization mechanism this token mode consumes. `ExtData.TokenExpirationDate` is required by IBX's REST layer **for this mode only**, and IBX's own examples of it use three different date formats (`1/1/2029`, `01-01-29`, `01-01-2030`) — it is an internal jstoken artefact with no Payroc-side target, not a field to carry across. | inferred (structural analog only — nothing connects IBX's flow to `createSession` specifically) |
| `REST POST /cardsafe/storecard {tokenMode=jstoken}` | sequence — same decomposition as SOAP row above | same as SOAP row above | same as SOAP row above | see the SOAP row above and the `/admin/jstoken` row below | inferred (same basis as the SOAP row; IBX's own acceptance rule is confirmed, the pairing is not) |
| `SOAP cardsafe.StoreCardFromPNRef` | none (target undetermined — escalate) | `—` | n/a | Tokenizes an *existing transaction's* card data by `PNRef` reference, with no fresh card data supplied. Payroc's closest structural concept, `source.type:singleUseToken`, requires a single-use token already in hand, not a bare historical identifier — and Payroc's card-detail responses are masked to the last four digits, per PCI norms, so reconstructing a full token from a `paymentId` alone may not be achievable through any documented Payroc path. **Escalate rather than asserting a target.** | unverified (the Payroc-side absence was checked across the token-issuing surfaces only) |
| `REST POST /cardsafe/storecardfrompnref` | none (same status as SOAP row above) | `—` | n/a | `originalTransaction.pnRef` is validated non-null and non-zero at runtime **even though IBX's own published schema marks it optional** — the runtime rule wins. There is no `TokenExpirationDate` rule on this operation, a confirmed absence rather than an untested one, unlike plain `StoreCard`'s jstoken mode. | verified (the IBX-side rule) / unverified (the Payroc target, same as the SOAP row) |
| `SOAP cardsafe.UpdateCardInfo` | direct — updates cardholder name, expiry and billing address on an existing stored payment method and does not change the underlying card number, which matches `updateSecureToken`'s own exclusion list | `updateSecureToken` (`PATCH /processing-terminals/{id}/secure-tokens/{secureTokenId}`) | `Street`/`Zip` land under Payroc's `customer.billingAddress`, not a top-level field | — | inferred (see the REST row below for the evidence this pairing rests on) |
| `REST POST /cardsafe/updatecardinfo` | direct — same behaviour as SOAP row above | same as SOAP row above | `cardToken` required; **`expirationDate` is required by IBX's REST layer even though the SOAP schema's `ExpDate` is optional** — REST is stricter than SOAP on this field | Payroc's published guidance for updating saved payment details states the operation's scope — cardholder name and expiry date, plus the customer's address details — as an exact match to this operation's field list. | verified |
| `SOAP cardsafe.UpdateCardNumber` | sequence | `createSingleUseToken` (`POST /processing-terminals/{id}/single-use-tokens`, with the new card data) → `accountUpdate` (`POST /processing-terminals/{id}/secure-tokens/{secureTokenId}/update-account`, `type:singleUseToken`) | **Two Payroc calls replace one IBX call** | `SEQ:` `updateSecureToken`'s own exclusion list explicitly forbids patching `cardNumber`. The documented route for changing the underlying card number is `accountUpdate`, which accepts only a single-use token, never a raw card number. Payroc's schema and its published guidance independently confirm the two-endpoint split. | inferred (the IBX-side behaviour) / verified (the Payroc-side split) |
| `REST POST /cardsafe/updatecardnumber` | sequence — same decomposition as SOAP row above | same as SOAP row above | `cardToken` and `cardNumber` both required | see the SOAP row above | verified (the IBX-side rule; the Payroc-side split as above) |
| `SOAP cardsafe.GetCardExpiration` | partial | `listSecureTokens` (`GET /processing-terminals/{id}/secure-tokens`), then filter `source.expiryDate` client-side per result | No Payroc equivalent for the server-side begin/end month-year range filter | `LOSS:` you can check this absence yourself against the public documentation — `listSecureTokens` accepts `secureTokenId`, `customerName`, `phone`, `email`, `token`, `first6` and `last4`, and no expiry-range parameter. The underlying data (`expiryDate` per token) *is* in the list response, so this is a capability loss you can work around by paginating and filtering, not a hard gap. **The exact SOAP response wire format is unknown** — do not write a parser for it from this row. There is no REST sibling for this operation: the REST surface exposes six `/cardsafe/*` paths against the SOAP service's seven operations, and this is the one with no REST form. | unverified (the response shape) / inferred (the capability gap, from Payroc's parameter list) |

## `accountupdaterinfo` / `/reporting/AccountUpdater`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP accountupdaterinfo.GetAccountUpdaterReport` | config | `—` (see `CFG:`) | n/a | `CFG:` this is a pull report over a date range of network-driven card refreshes **already applied** to vaulted tokens (`CardUpdateInfo{OldLastFour,NewLastFour,OldExpDate,NewExpDate,UpdateDateTime}`) — it reports, it does not trigger. **Payroc's only account-updater surface is `accountUpdater`, a boarding-time `additionalServices` opt-in with a fee schedule on a pricing intent — not a callable operation.** There is no alternative delivery mechanism either: no webhook or subscribable event type carries these updates, and no published guidance describes one. **Escalate to your onboarding or gateway contact to enable the service. There is no API to enroll a specific token or to pull a change log, and whether an enrolled merchant receives any signal at all when a card refreshes is unresolved** — settle that with your implementation contact before you plan around it, because the answer changes whether you need to build a reconciliation process or not. | verified (the IBX schema and response shape) / unverified (whether any customer-visible signal exists once enrolled) |
| `REST GET /reporting/AccountUpdater` | config — the same underlying report as the SOAP row above, over a second transport | same as SOAP row above | Query parameters are `MerchantID`, `StartDate`, `EndDate` only — **no `ExtData` on this transport** | see the SOAP row above | inferred (schema shape only; nothing confirms either transport's runtime rules) |

## `/admin/jstoken` — browser tokenization, REST-only

No SOAP sibling.

**Your code may call this under a second path, and that is the one it probably uses.** IBX's REST
layer exposes each operation again under `/api/v1/json/reply/<OperationName>`, so
**`POST /api/v1/json/reply/AdminGetToken` and `POST /api/v1/admin/jstoken` are the same
capability.** Everything in this section applies to both. Grep your codebase for `json/reply` as
well as for `admin/jstoken`. The alias form is the more common of the two in practice, so a
migration inventory built only on `/admin/jstoken` can miss most of your calls to this capability.

**A standing cap on this section:** every claim below about what a *script* sends is reported
behaviour, not confirmed against the JTL browser scripts themselves.
Confirm against the version of the script your own integration loads. The descriptions of the two JTL
versions may also lag the current implementation.

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST POST /admin/jstoken` | partial | `createSession` (`POST /processing-terminals/{id}/hosted-fields-sessions`, `scenario:tokenization`) + the browser-side Hosted Fields widget | IBX exchanges a boarding-issued **merchant token** for a card or check token in one synchronous call. Payroc exchanges `processingTerminalId` plus bearer auth for a short-lived **session** token that only *configures* a JS widget; the widget itself, once loaded, is what produces the usable token via a client-side callback. **That is an extra hop IBX's flow does not have** — plan for it in your page lifecycle, not just in your server code. | `LOSS:` the browser script (`jtlv2.js`) calls this endpoint for a token, then presents that token to `cardsafe.StoreCard` / `ProcessCreditCard {TokenMode=jstoken}`. **JTL v2 is documented as multi-use-only, with no amount sent or allowed at token generation**, so v1's amount-locking behaviour does not apply to this flow. IBX's own documentation hedges itself here — "only built for multi-use tokens **so far**", "JTLv2 is only for multi-use **currently**" — so do not harden "v2 never sends an amount". **Do not read v2's lack of a creation-time amount as agreement with Payroc's `createSingleUseToken`:** v2 is multi-use, whereas a Payroc single-use token expires in 30 minutes and is usable once. They are different kinds of token, so a shared absence proves nothing. The right Payroc counterpart to a v2 multi-use token is `createSecureToken` (or Hosted Fields for the browser-script role); creation-time amount handling does match on *that* pairing, but that is a different claim. **Two real divergences:** (1) IBX v1's single-use amount-locking has **no Payroc equivalent at all** — nothing in Payroc pins an amount to a token or enforces an amount match at redemption; (2) IBX v1 *multi-use* **forbids** sending an amount at transaction time, whereas a Payroc payment **requires** `order.amount`. **Two nuances on the v1 behaviour, and both are load-bearing:** the amount match is reached only when `SingleUse` is **true** *and* a per-vendor enforcement flag (`IsJsTokenEnforceTokenAmounts`) is on — with that flag off, a supplied amount is used as-is and the token's amount is only a fallback, so **"v1 locks the amount" is conditional, not absolute.** Separately, `/admin/jstoken` itself accepts `amount` and `singleUse` optionally **regardless of version**; the divergence lives in what the *script* sends, not in what the endpoint accepts. **Ask your gateway contact which JTL version and which vendor flag your account runs on before sizing this.** | inferred (structural analog only — nothing connects the two flows end to end, and the version behaviours described may not reflect the current implementation) |

---
name: from-ibx
description: >
  Guides developers through porting an existing IBX gateway integration to the Payroc API. Use this
  skill when the user wants to: migrate, port, or re-platform an integration off IBX; find the Payroc
  equivalent of an IBX SOAP operation or REST endpoint; understand what a TransType value maps to;
  work out what changes in a request when moving from transact.asmx, cardsafe.asmx, recurring.asmx or
  the IBX /api/v1 REST surface to Payroc; translate IBX identifiers such as PNRef, CustomerKey,
  ContractKey or CardToken into their Payroc counterparts; find out whether a capability they rely on
  today still exists on Payroc; or plan the cutover for stored tokens and historical transaction
  references. Do NOT use this skill when the user is building a new Payroc integration with no legacy
  IBX code (use the relevant task skill such as run-a-card-sale, save-a-payment-method, or
  take-an-ach-payment), when they are migrating from a different provider, or when they already know
  the Payroc operation they need and only want to implement it (go straight to that skill).
metadata:
  version: "0.1.1"
  category: migration
  status: draft
---

# Migrate from IBX to the Payroc API

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/migrations/skills/from-ibx/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Migrate from IBX to the Payroc API**
> I'll work through your existing IBX integration call by call, tell you what each one becomes on the Payroc API, and flag the places where the shapes match but the behaviour doesn't — those are what break a migration.
>
> **How this works:** I look up each IBX call you actually make in a mapping reference, rather than reasoning about it from the endpoint name. Where a call has a clean Payroc equivalent I'll hand you off to the task skill that implements it. Where it doesn't, I'll say so plainly rather than inventing something.
>
> If you can share the IBX request bodies you send — or the code that builds them — the mapping gets a lot more precise.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
IBX SOAP        →  /ws/transact.asmx, /ws/cardsafe.asmx, /vt/ws/recurring.asmx, and 13 more
IBX REST        →  /api/v1/{transactions|cardsafe|customers|contracts|batch|reporting|...}
Payroc API      →  https://api.uat.payroc.com/v1/...   (UAT)
                   https://api.payroc.com/v1/...       (production)
```

The dominant shape of this migration is **not** one-to-one. An IBX operation-type discriminator
usually becomes a *field* on a broader Payroc operation — `TransType=Auth` becomes a payment with
`autoCapture:false`, `TransType=Force` becomes a payment with `offlineProcessing`. Expect to rewrite
request bodies, not just swap endpoint URLs.

---

## References

Every mapping lives in the local `references/` files below. This skill answers from them, not from
live lookups and not from memory. **There is no general rule for converting an IBX call to a Payroc
call** — if a call is not in a reference file, the answer is that you don't know it yet.

| Source | Local file | Use for |
| --- | --- | --- |
| Card transactions | `references/map-card-transactions.md` | `transact`/`transact2`: `ProcessCreditCard`, `ProcessSignature`, `EmailReceipt` |
| Debit and EBT | `references/map-debit-and-ebt.md` | `transact`/`transact2`: `ProcessDebitCard`, `ProcessEBTCard` |
| Check, cash and stored value | `references/map-check-cash-and-stored-value.md` | `ProcessCheck`, `ProcessCash`, `ProcessBitcoin`, `ProcessGiftCard`, `ProcessLoyaltyCard` |
| Vaulting | `references/map-tokens-and-vault.md` | `cardsafe` store/update, account updater, `/admin/jstoken`, browser tokenization |
| Payments with a stored token | `references/map-token-payments.md` | `cardsafe.ProcessCreditCard`/`ProcessCheck`, SOAP and REST |
| IBX's native REST transactions | `references/map-rest-transactions.md` | `/transactions`, `/authholds`, `/current-requests` |
| Batch and settlement | `references/map-batch-and-settlement.md` | `ProcessBatch`, `batchinfo`, `settlementinfo`, REST `/batch/*` |
| Reporting and search | `references/map-reporting-and-search.md` | `transactiondetail`, `trxdetail`, `imageretrieval`, REST `/reporting/*` |
| Recurring (SOAP) | `references/map-recurring-soap.md` | `recurring.asmx`, all 13 operations |
| Recurring (REST) | `references/map-recurring-rest.md` | `/customers`, `/contracts`, `/recurringtransactions` |
| Merchant and account admin | `references/map-merchant-admin.md` | `/merchants`, `/users`, `/registers`, `/optimizations`, `customfields`, `resellerbuilder` |
| Auth and platform utilities | `references/map-auth-and-platform-utilities.md` | `validate`, `bininfo`, `health`, `transact.GetInfo`, REST `/auth`, `/bininfo` |
| Undocumented surfaces | `references/map-undocumented-surfaces.md` | `hostedpagesvc`, `/ws/hosted2`, `Epic.aspx`, `PayWS`/`CryptoWS`, `USAePay.asmx`, `TestForms` |
| Undocumented `ExtData` tags | `references/map-extdata-tags.md` | The ten tags IBX's runtime accepts that **no IBX document describes** — `Presentation`, `QPS`, `CVMResult`, `QuasiCash`, `EstimatedAmount`, `ChipConditionCode`, `Healthcare_Amount`, `AppInfo`, `CashAdvance`, `SkipVoidBackup`. Four of them change how a transaction is authorised |
| Identifiers and formats | `references/identifier-translation.md` | `PNRef` and every `*Key`, amounts, expiry, currency, result semantics — cited by every other file |
| What no longer exists | `references/no-equivalent-register.md` | Every "no equivalent" and "configured, not called" verdict, indexed by IBX service |

These are local snapshots, authoritative for this skill. Their provenance and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md), which also explains what each
confidence badge means and how far it goes.

---

## Core Principles

1. **Route from the call the developer's code actually contains, never from the operation name alone.**
   `ProcessCreditCard` exists three times in IBX — on `transact.asmx`, on `recurring.asmx`, and at
   `POST /api/v1/cardsafe/processcreditcard` — with different parameters and different Payroc targets.
   A bare operation name produces confidently wrong answers. Always resolve the service or path prefix
   first, using the routing table below.

2. **Never infer a mapping that is not in a reference file.** If the call isn't in the routed file,
   check `references/no-equivalent-register.md`, and if it isn't there either, **say you don't know and
   ask for a request sample.** A plausible-sounding mapping is the most damaging thing this skill can
   produce, because it will look right in review.

3. **A shape match is not a behaviour match.** Two operations that both take a card and an amount and
   return an approval are not equivalent if one auto-captures and the other doesn't. The failure mode
   here is not an error — it's a request that succeeds and does the wrong thing. Every row tagged
   `SEMANTIC:` is a case where the port compiles, passes review, and behaves differently in production.
   Surface those to the developer explicitly; don't bury them in a table you summarise.

4. **Read the separators literally.** In every mapping table, ` → ` means **sequence** (do all of
   these, in this order) and ` | ` means **branch** (pick one at runtime, per the row's `IF:`
   predicate). Reading ` | ` as "and" is the classic failure — it issues a reversal *and* a refund.
   A branch row always carries an `IF:` predicate; if you can't find one, don't guess the condition.

5. **Honour the confidence badge, and say it out loud.** `verified` is safe to build on. `inferred`
   means test the specific behaviour the row names before going live. **`unverified` must never be
   turned into code without telling the developer it's unverified** — offer to escalate or ask for a
   request sample instead.

6. **"You can no longer do this" is an answer, and it's the highest-stakes one.** Deliver it plainly,
   with the alternative or the escalation route from the row. Never soften it into a vague equivalent,
   and never pad it with a Payroc operation that doesn't actually do the same job.

7. **Hand off for the *how*.** This skill owns the delta — what changes, and what breaks. Once a call
   is mapped, send the developer to the task skill that documents the target operation properly
   (`run-a-card-sale`, `save-a-payment-method`, and so on). Don't restate a Payroc request schema here;
   those skills keep theirs current and this one would drift.

8. **Never hardcode credentials.** IBX credentials and Payroc API keys both come from environment
   variables or a secrets manager.

---

## Intake

**First, scan the codebase.** This is usually faster and more accurate than asking, because the answer
is in the source:

- The IBX endpoint hosts and paths being called — grep for `.asmx`, `/api/v1/`, and the service names
  in the routing table
- Which `TransType` / `transactionType` values are actually constructed, and where they come from
  (a constant, a config value, or user input — the last means the full set is in play)
- Whether stored `PNRef`, `CustomerKey`, `ContractKey`, `CardToken` or `CheckToken` values are
  persisted in the developer's own database, and what reads them
- Whether the integration is SOAP, REST, browser-side tokenisation, or a mix
- Any scheduled or batch jobs that call IBX, which are easy to miss and often carry the settlement logic

Then ask the developer, skipping anything the scan already answered:

1. **Which IBX surfaces do you call?** Share the endpoint paths, or point me at the client code.
2. **Do you store IBX identifiers?** Especially `PNRef` — historical referenced refunds depend on it,
   and it doesn't survive the migration as-is.
3. **Do you have stored cards or bank accounts in the IBX vault?** Stored cards have a supported
   migration path, but it's a process with a lead time, not an API call. Stored bank accounts can't
   be migrated. Customers will need to provide those details again on Payroc.
4. **What has to keep working on day one** versus what can be re-implemented later?
5. **Do you have a Payroc implementation contact?** Several answers in this migration depend on how
   the merchant's account and terminals are configured, not on the API.

---

## The routing table

**Always consult this before opening a reference file.** SOAP routes on the `.asmx` path, because the
base path is not derivable from the service name. REST routes on the first path segment.

### SOAP

| IBX service path | Operation → reference file |
| --- | --- |
| `/ws/transact.asmx`, `/ws/transact2.asmx` | `ProcessCreditCard`, `ProcessSignature`, `EmailReceipt` → `map-card-transactions.md` · `ProcessDebitCard`, `ProcessEBTCard` → `map-debit-and-ebt.md` · `ProcessCheck`, `ProcessCash`, `ProcessBitcoin`, `ProcessGiftCard`, `ProcessLoyaltyCard` → `map-check-cash-and-stored-value.md` · `ProcessBatch` → `map-batch-and-settlement.md` · `GetInfo` → `map-auth-and-platform-utilities.md` |
| `/ws/cardsafe.asmx` | `StoreCard`, `StoreCardFromPNRef`, `UpdateCardInfo`, `UpdateCardNumber`, `GetCardExpiration` → `map-tokens-and-vault.md` · `ProcessCreditCard`, `ProcessCheck` → `map-token-payments.md` |
| `/vt/ws/recurring.asmx` | `map-recurring-soap.md` |
| `/ws/batchinfo.asmx`, `/ws/settlementinfo.asmx` | `map-batch-and-settlement.md` |
| `/vt/ws/transactiondetail.asmx`, `/vt/ws/trxdetail.asmx`, `/ws/imageretrieval.asmx` | `map-reporting-and-search.md` |
| `/ws/accountupdaterinfo.asmx` | `map-tokens-and-vault.md` |
| `/ws/customfields.asmx`, `/vt/ws/resellerbuilder.asmx` | `map-merchant-admin.md` |
| `/ws/validate.asmx`, `/ws/bininfo.asmx`, `/vt/ws/health.asmx` | `map-auth-and-platform-utilities.md` |
| `/ws/hostedpagesvc.asmx` | `map-undocumented-surfaces.md` |

### REST

| IBX path prefix | Reference file |
| --- | --- |
| `/transactions`, `/authholds`, `/current-requests` | `map-rest-transactions.md` |
| `/cardsafe` | `storecard`, `storecardfrompnref`, `updatecardinfo`, `updatecardnumber` → `map-tokens-and-vault.md` · `processcreditcard`, `processcheck` → `map-token-payments.md` |
| `/admin` | `map-tokens-and-vault.md` |
| `/json/reply/{Operation}` | **An alias, not a separate API.** IBX's REST layer exposes every operation a second time under `/api/v1/json/reply/<OperationName>`, so the same capability has two callable paths and your code may use either. **Route on the operation name, not on the path.** `AdminGetToken` → `map-tokens-and-vault.md` (it is the same capability as `/admin/jstoken`); `Authenticate` → `map-auth-and-platform-utilities.md` (same as `/auth`). For any other operation name, strip the `/json/reply/` prefix, match the remaining name against the operations in this table, and route there. **If you cannot match it, say you don't know** — do not guess from the name |
| `/customers`, `/contracts`, `/recurringtransactions` | `map-recurring-rest.md` |
| `/merchants`, `/users`, `/registers`, `/optimizations` | `map-merchant-admin.md` |
| `/batch` | `map-batch-and-settlement.md` |
| `/reporting` | `map-reporting-and-search.md` — **except** `/reporting/AccountUpdater` → `map-tokens-and-vault.md`. Note that `/reporting/SettlementDetail` and `/reporting/SettlementList` route here by path segment even though their subject is settlement; their SOAP counterparts route to `map-batch-and-settlement.md` |
| `/auth`, `/bininfo` | `map-auth-and-platform-utilities.md` |

### Everything else

| What the developer has | Reference file |
| --- | --- |
| `/ws/hosted2`, `/vt/ws/Epic.aspx`, `/vt/ws/admin.asmx`, `/ws/TestForms/*` | `map-undocumented-surfaces.md` |
| `PayWS.asmx`, `CryptoWS.asmx`, `PayXml.aspx`, `PayNV.aspx`, `WebLink.aspx`, ADCRelay-style form posts, `USAePay.asmx` | `map-undocumented-surfaces.md` |
| Browser-side JTL v1/v2 tokenisation script | `map-tokens-and-vault.md` |
| Virtual Terminal UI, processor or reseller configuration | `map-merchant-admin.md` (as `config` rows) |
| "Can I still do X?" / "What have we lost?" | `no-equivalent-register.md` |
| Any tag inside an `ExtData` blob | The tag's own operation file first, then `map-extdata-tags.md` for the ten IBX documents nowhere. **`ExtData` is where the undocumented behaviour lives** — read `map-extdata-tags.md` before telling a developer an `ExtData` tag is harmless |
| Response fields, identifiers, amounts, expiry, currency, result codes | `identifier-translation.md` |
| **Anything not matched above** | **Say you don't know, and ask for a request sample. Never infer a mapping that isn't in a reference file.** |

---

## Step 1 — Inventory the legacy integration

Produce a list of distinct IBX calls the codebase actually makes, keyed the way the mapping tables are
keyed: `<PROTO> <SERVICE>.<OP> {<discriminator>=<value>}`. For example
`SOAP transact.ProcessCreditCard {TransType=Sale}`.

Two things to get right, because both cause silent under-scoping:

- **Enumerate discriminator values, don't assume one.** If `TransType` comes from a variable, find
  every value that can reach it. A migration scoped on the two types someone remembers will miss the
  `Void` path that only runs on same-day cancellations.
- **Include the read and reconciliation paths**, not just the payment path. Batch queries, settlement
  reports and transaction searches are where migrations typically discover an unmapped dependency late.

### Checkpoint

You have a de-duplicated list of keyed IBX calls, and the developer agrees it's complete.

---

## Step 2 — Route and look up each call

For each call in the inventory, resolve its reference file from the routing table, then read that file.

> **Before answering any question about what an IBX call becomes — including in a walkthrough, a
> summary, or a code comment — read the routed `references/*.md` file now.** Do not answer from the
> routing table, from this file's examples, or from memory. The routing table tells you which file to
> open; it does not contain a single mapping itself. Reading the reference file is mandatory, not
> optional.

Report each mapping with all four of: the verdict, the Payroc target, the request delta, and the
behaviour change. **A verdict without its behaviour change is an incomplete answer** — the behaviour
change is where the migration risk lives.

Group the results so the developer can act on them:

- **Ports cleanly** — same operation, same behaviour, only the request shape changes.
- **Ports with a behaviour change** — everything tagged `SEMANTIC:`, `SEQ:` or `LOSS:`. These need a
  decision, not just code.
- **Needs a runtime branch** — rows tagged `IF:`, where one IBX call becomes two Payroc paths.
- **No equivalent** — send these to Step 4.
- **Unverified** — say so, and offer to escalate rather than generating code.

### Checkpoint

Every call in the inventory has a verdict, and every non-`direct` verdict carries its required cell.
Nothing is answered "probably".

---

## Step 3 — Resolve identifiers, amounts and formats

> **Before writing any code that carries an identifier, an amount, a card expiry or a currency across
> from IBX, read `references/identifier-translation.md` now.** This is where the conversions that look
> obvious and aren't are documented — the amount ceiling, the expiry range check the Payroc schema
> does not perform, and the fact that fourteen distinct IBX key types do not all map the same way.
> Do not infer any of these from field naming.

The two that reliably bite:

- **`PNRef` has no Payroc counterpart.** It lives in the developer's own database, never IBX's. That
  makes historical referenced refunds impossible after cutover — a pre-migration transaction has no
  Payroc `paymentId` to refund against. The bridge is documented in the reference file; plan it before
  writing code, not after.
- **Similarly-named keys are different concepts.** `CardInfoKey` and `CardToken` are two vaults.
  `MerchantKey` and `MerchantToken` are unrelated. `BatchNumber` and `BatchID` are not the same thing.
  Look each one up rather than pattern-matching the name.

### Checkpoint

Every identifier the integration persists has either a named Payroc counterpart or an explicit
migration plan. No amount or expiry conversion is being done from assumption.

---

## Step 4 — Handle the capabilities that don't survive

> **Before telling a developer that a capability is gone, read `references/no-equivalent-register.md`
> now** — it holds every `none` and `config` verdict in one place, indexed by IBX service. Do not
> assert an absence from a domain file alone, and do not assert one from this skill file at all.

Two verdicts that look alike and mean opposite things:

- **`none`** — there is no Payroc equivalent. The feature has to be redesigned or dropped. Say so.
- **`config`** — it isn't an API call any more, but the capability remains; Payroc configures it.
  The developer keeps the feature and raises a request. **Collapsing `config` into `none` tells the
  developer they've lost something they haven't**, which is the more damaging of the two errors.

For anything in either bucket, give the developer the alternative or the escalation route the row
names. "No equivalent, no next step" is not a finished answer.

### Checkpoint

Every `none` and `config` row has been delivered with its alternative or escalation route, and the
developer knows which of their features need a design decision.

---

## Step 5 — Implement, via the task skills

This skill stops at the delta. For each mapped call, hand off to the skill that documents the target
operation, and let it own the request schema, the enums and the error handling:

| Target area | Skill |
| --- | --- |
| Card sales | `run-a-card-sale` |
| Pre-authorization, capture, incremental auth | `run-a-pre-authorization` |
| Refunds and reversals | `refund-a-card-payment`, `refund-an-ach-payment` |
| ACH / bank transfers | `take-an-ach-payment`, `verify-bank-account` |
| Stored payment methods | `save-a-payment-method`, `create-single-use-token` |
| Browser-side capture | `integrate-hosted-fields`, `integrate-hosted-payment-pages`, `integrate-payment-links` |
| Wallets | `integrate-apple-pay`, `integrate-google-pay` |
| 3-D Secure | `run-a-sale-with-3ds` |
| Recurring billing | `set-up-a-payment-plan`, `manage-subscriptions` |
| EBT balance | `check-ebt-balance` |
| Card lookups | `look-up-card-details` |
| Reporting and settlement | `view-settled-transactions`, `view-settlement-batches`, `view-authorizations`, `view-ach-deposits`, `view-disputes` |
| Boarding, terminals, pricing | `create-merchant-platform`, `add-processing-account`, `order-a-terminal`, `create-pricing-intent` |
| POS and devices | `integrate-payroc-cloud` |
| Webhooks and events | `set-up-event-subscriptions` |

**Carry the behaviour changes across the handoff.** A `SEMANTIC:` hazard found in Step 2 is not the
target skill's job to re-derive — state it as a requirement when you hand off.

### Checkpoint

Each mapped call is being implemented against a current task skill, with its behaviour changes
recorded as explicit requirements.

---

## Step 6 — Plan the cutover

Migration-specific work that no task skill covers:

- **Stored payment methods.** Payroc publishes a supported token migration process — the Gateway Team
  takes an encrypted file over SFTP, with a lead time measured in weeks, not an API call. Start it
  early; it is usually the critical path. Re-vaulting with cardholders is the fallback, and it is far
  more expensive. **This route is well-trodden for IBX specifically**, so plan around it rather
  than treating it as untested. Two things to get right, because both are easy to miss:
  - **Confirm your export contains full card numbers before you commit to the import.** The IBX
    export carries the token, the card number and the expiry as its first three columns, matching
    what Payroc's import requires — but **if your export masks the card number, the import cannot
    be fed from it and you are back to re-vaulting.** Ask for one real, unredacted row early; it is
    a five-minute check that decides weeks of work.
  - **The expiry needs converting, not copying.** The IBX export writes it with a separator
    (`08/29`); Payroc's import takes `MMYY`, `YYMM`, `MMYYYY` or `YYYYMM` with no separator, and
    every record in the file must use the same one. A straight column copy fails.
- **Historical transaction references.** See Step 3 — decide how referenced refunds against
  pre-cutover payments will work before the cutover, not after.
- **Authorizations still open on IBX at cutover.** An authorization taken on IBX has no Payroc
  `paymentId`, so only IBX can capture it. Before switching off IBX, capture each outstanding
  authorization individually by its `PNRef` (`TransType=Capture` on the payment type's own
  operation, as mapped in `references/map-card-transactions.md` and `references/map-debit-and-ebt.md`).
  Then confirm each one settled from IBX's transaction detail reporting, and count a transaction as
  settled only when its stored settle flag is `1`. **Do not drain them with `CaptureAll`, and never
  treat its response as confirmation.** On credit and debit it returns success before the
  processor is contacted, the queued work waits for a background job that does not run between
  midnight and 01:00, and an authorization left uncaptured can lapse. Read
  `references/map-batch-and-settlement.md` before planning this.
- **Terminal and account configuration.** Several behaviours in the mapping depend on how the
  merchant's terminals are configured rather than on the request — currency, whether
  pre-authorization is enabled, receipt handling. These need the implementation contact.
- **Running both in parallel.** If the developer plans a phased cutover, settlement and reporting
  reconciliation spans two platforms for the overlap. Flag it as work.

### Checkpoint

The developer has a cutover plan covering stored tokens, historical references, open IBX
authorizations and how their settlement is confirmed, configuration dependencies, and the
reconciliation overlap.

---

## Common failure modes

These are migration-specific. For Payroc API errors, use the error taxonomy in the target task skill.

| What happens | Why | Fix |
| --- | --- | --- |
| The port works in test and takes money unexpectedly in production | An IBX `Auth` mapped to a Payroc payment without the flag that suppresses capture, or with a second flag that overrides it | Re-read the row's `SEMANTIC:` note; confirm pre-authorization is enabled on the account |
| A refund that used to work now returns 400 | The Payroc referenced-refund body requires fields IBX did not | Check the row's request delta — both refund paths have different required sets and different length limits |
| A reversal and a refund are both issued | A ` \| ` branch row was read as a sequence | Re-read Principle 4; find the row's `IF:` predicate and implement the branch |
| Amounts are out by 100× | Converted to minor units without confirming the terminal's currency | Zero-decimal and three-decimal currencies exist; see `references/identifier-translation.md` |
| A large amount is accepted and settles for the wrong value | An amount above `99999.99` was sent because IBX's validator permits it. IBX's REST card amount is a single-precision float, so `999999.99` becomes `1000000.00` — **it does not error** | Treat `99999.99` as the recommended ceiling for what you send, tolerate larger values on intake, and confirm the real limit with the implementation contact. See `references/identifier-translation.md` |
| A card that stored fine in IBX is rejected | Expiry month not range-checked | The Payroc pattern accepts any four digits; the skill must range-check the month itself |
| A capability is reported as lost that isn't | A `config` row read as a `none` row | See Step 4 |
| A mapping was generated for a call not in any reference file | Principle 2 was skipped | Retract it, and ask for a request sample |

---

## Validation checklist

- [ ] Every IBX call in the inventory was routed via the routing table, not answered from the operation name
- [ ] Every mapping came from a reference file that was actually read — none inferred, none from memory
- [ ] Every `unverified` row was reported as unverified to the developer before any code was written from it
- [ ] Every `SEMANTIC:`, `LOSS:` and `SEQ:` note was surfaced explicitly, not summarised away
- [ ] Every ` | ` branch row was implemented as a runtime branch with its `IF:` predicate
- [ ] Every `none` and `config` row was delivered with its alternative or escalation route
- [ ] `config` rows were not reported as lost capabilities
- [ ] Identifier, amount, expiry and currency conversions read from `references/identifier-translation.md`
- [ ] Card expiry month range-checked client-side before any request is sent
- [ ] Amounts above `99999.99` identified in the legacy data, and a decision taken on them — intake tolerates them, outbound does not assume they are safe
- [ ] Stored-token migration started, or consciously deferred with the fallback understood
- [ ] Historical referenced-refund strategy decided before cutover
- [ ] Credentials for both platforms sourced from environment variables — never hardcoded
- [ ] UAT endpoints used (`api.uat.payroc.com`) during testing — not production endpoints

---

## Completion

Once the checklist passes:

> **Migration mapping complete.** Here's where you stand:
>
> - **Ports cleanly** — [list]
> - **Ports with a behaviour change** — [list, each with its change]
> - **No Payroc equivalent** — [list, each with its alternative or escalation]
> - **Configured rather than called** — [list]
> - **Unresolved** — [list, with what's needed to close each]
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com`, point credentials at the
> production terminal and API key, and confirm the stored-token migration has completed.

Offer next steps:

- **Implement the mapped calls** — hand off to the task skills listed in Step 5
- **Close the unresolved items** — most need the merchant's terminal configuration, which the Payroc
  implementation contact can confirm
- **Set up webhooks** — see the `set-up-event-subscriptions` skill; IBX has no equivalent mechanism,
  so this is usually new work rather than a port

---
name: from-transsafe
description: >
  Guides developers through porting an existing TranSafe gateway integration to the Payroc API. Use
  this skill when the user wants to: migrate or port an integration off TranSafe; find the Payroc
  equivalent of a TranSafe REST call (/api/v2 or /api/v1) or a key/value request such as
  action_trans=sale sent through libMonetra or another KV transport; replace PaymentFrame,
  TicketRequest, cardshieldticket, hosted paypages or invoice pages; translate TranSafe identifiers
  such as ttid, token or profile_id; check whether a TranSafe capability (gift cards, PayPal,
  customers, orders, velocity rules, user admin) still exists; or plan the cutover for tokens,
  schedules, open authorizations and history. Do NOT use it for a new Payroc integration with no
  TranSafe code (use the task skill, such as run-a-card-sale or save-a-payment-method), for a
  migration from IBX or another provider, or when the user already knows the Payroc operation and
  only wants to implement it.
metadata:
  version: "0.1.1"
  category: migration
  status: draft
---

# Migrate from TranSafe to the Payroc API

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/migrations/skills/from-transsafe/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Migrate from TranSafe to the Payroc API**
> I'll work through your existing TranSafe integration call by call, tell you what each one becomes on the Payroc API, and flag the places where the shapes match but the behaviour doesn't — those are what break a migration.
>
> **How this works:** I look up each TranSafe call you actually make in a mapping reference, rather than reasoning about it from the endpoint or action name. Where a call has a Payroc equivalent I'll hand you off to the task skill that implements it. Where it doesn't, I'll say so plainly rather than inventing something.
>
> If you can share the TranSafe requests you send — the REST paths and bodies, or the key/value pairs — or the code that builds them, the mapping gets a lot more precise.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
TranSafe REST v2  →  https://{test|live}.transafe.com/api/v2/...   (200 approved, 402 declined)
TranSafe REST v1  →  https://{test|live}.transafe.com/api/v1/...   (200 for every transaction; read `code`)
TranSafe KV       →  libMonetra, <MonetraTrans> XML/JSON envelope, IP/SSL; POST/HMAC (ticket and
                     alt-payment requests only)
                     (action_trans=…, action_admin=…, action_sys=…, action_su=…; v8: action=…)
Payroc API        →  https://api.payroc.com/v1/...       (test and production; a test API key selects test)
                     HTTPS + JSON + Bearer token; `payment` returns 201 on approval AND on decline
```

The dominant shape of this migration is **not** one-to-one. There is no Payroc key/value transport,
so every KV integration becomes a REST integration. Where a TranSafe action has a Payroc equivalent,
it is usually a field or a variant of a broader Payroc operation rather than a call of its own; several
TranSafe actions merge into one Payroc call (void and reversal both become `reversePayment`); and a
large administrative surface (users, the group hierarchy, route management, velocity, card lists,
inventory, orders) has no Payroc API at all. Expect to rewrite requests and response handling, not
just swap URLs.

---

## References

Every mapping lives in the local `references/` files below. This skill answers from them, not from
live lookups and not from memory. **There is no general rule for converting a TranSafe call to a
Payroc call** — if a call is not in a reference file, say it is not covered here and ask for a request sample.

| Source | Local file | Use for |
| --- | --- | --- |
| Transport, auth and results | `references/map-protocol-auth-and-results.md` | **Read first.** KV transports → REST; Basic / API-key / HMAC auth → Bearer; outcome signalling; HTTP 500s; `duplcheck` vs `Idempotency-Key`; amounts and currency |
| Identifiers and formats | `references/identifier-translation.md` | `ttid`, `draft_locator_id`, `token`, `customer_id`, `cardshieldticket`, `ordernum`, `profile_id`, `group_id`, amount, currency, `expdate`, timestamps — cited by every other file |
| Card transactions | `references/map-card-transactions.md` | `/transaction/*` purchase, preauth, complete, capture, reversal, void, incremental, adjust, refunds, verify, card type, balance; transaction details, receipts, Level 3, images |
| Vault and customers | `references/map-tokens-vault-and-customers.md` | `/vault/account*`, `/vault/export*`, `/customer*`, `/system/database` |
| Scheduled payments | `references/map-recurring.md` | `/vault/payment/*` installment and recurring schedules, schedule history, existing schedules at cutover |
| Payment pages | `references/map-paypages.md` | PaymentFrame, TicketRequest, `/paypage/hosted*`, the customer-facing hosted page, invoice pages |
| Boarding | `references/map-boarding.md` | `/boarding/*` groups, profiles, routes, processors, push notifications |
| Batch and reporting | `references/map-batch-and-reporting.md` | `/batch/*`, `/report*`, chart data, device and usage reports, `/system/schedule` automated settlement |
| Gift, EBT, check and PayPal | `references/map-gift-ebt-check-altpay.md` | Gift actions, `/transaction/ebt/*`, `/transaction/check/*`, `/transaction/altpayment/*` |
| Users and merchant controls | `references/map-users-and-merchant-config.md` | `/apikey*`, `/user*` (incl. MFA and self-reset), `/velocity`, `/cardlist/*`, `/e2ee/*`, `/p2pe/*` |
| REST v1 / KVS v8 | `references/map-v1-delta.md` | Every `/api/v1/*` path and every `action=<verb>` / `action=admin admin=<verb>` request: what differs from its v2 twin |
| What no longer exists | `references/no-equivalent-register.md` | Every `none` and `config` verdict, an index of "can I still …?" questions, and the inventory, order, Big Batch and system groups |
| Identity call | `references/identity-call.md` | Payroc Bearer token exchange: endpoint, request, response |

These are local snapshots, authoritative for this skill. Their provenance and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md), which also explains what each
confidence badge means, how far it goes, and what the visibility labels on row keys mean.

---

## Core Principles

1. **Route from the call the developer's code actually contains, never from the action name alone.**
   The same capability reaches TranSafe as a REST v2 path, a REST v1 path, a KVS v9 key/value set and
   a KVS v8 key/value set, and several KV identifiers are shared by more than one REST action
   (the row's `IF:` names the discriminating parameter). Resolve the transport, version and exact
   path or key/value pairs first, using the routing table below.

2. **Never infer a mapping that is not in a reference file.** If the call isn't in the routed file,
   check `references/no-equivalent-register.md`, and if it isn't there either, **say you don't know and
   ask for a request sample.** A plausible-sounding mapping is the most damaging thing this skill can
   produce, because it will look right in review.

3. **A shape match is not a behaviour match.** Two operations that both take a card and an amount are
   not equivalent if one treats `amount` as the amount to keep and the other as the amount to give
   back. The failure mode here is not an error — it's a request that succeeds and does the wrong
   thing. Rows tagged `SEMANTIC:` mark these behaviour differences; the dangerous ones are where the
   port compiles, passes review, and behaves differently in production. Surface every one to the
   developer explicitly; don't bury them in a table you summarise.

4. **Read the separators literally.** In every mapping table, ` → ` means **sequence** (do all of
   these, in this order) and ` | ` means **branch** (pick one at runtime, per the row's `IF:`
   predicate). Reading ` | ` as "and" is the classic failure. A branch row always carries an `IF:`
   predicate; if you can't find one, don't guess the condition.

5. **Honour the confidence badge, and say it out loud.** Most rows carry a split badge, one half per
   side; plan around the lowest half. `verified` is safe to build on. `inferred` means test the
   specific behaviour the row names before going live. **`unverified` must never be turned into code
   without telling the developer it's unverified** — offer to escalate or ask for a request sample
   instead.

6. **"You can no longer do this" is an answer, and it's the highest-stakes one.** Deliver it plainly,
   with the alternative or the escalation route from the row. Never soften it into a vague equivalent,
   and never pad it with a Payroc operation that doesn't actually do the same job.

7. **Hand off for the *how*.** This skill owns the delta — what changes, and what breaks. Once a call
   is mapped, send the developer to the task skill that documents the target operation properly
   (`run-a-card-sale`, `save-a-payment-method`, and so on). Don't restate a Payroc request schema here;
   those skills keep theirs current and this one would drift.

8. **Never hardcode credentials.** TranSafe credentials (username and password, API key id and secret)
   and Payroc API keys both come from environment variables or a secrets manager. Never copy a
   credential, test account or key value out of the developer's TranSafe code into new code.

---

## Intake

**First, scan the codebase.** This is usually faster and more accurate than asking, because the answer
is in the source:

- The transport: grep for `transafe.com`, `/api/v2/`, `/api/v1/`, `libmonetra` / `M_` calls,
  `<MonetraTrans>`, `PaymentFrame`, `TicketRequest`, `hmac-`
- Every `action_trans=`, `action_admin=`, `action_sys=`, `action_su=` and v8 `action=` value the code
  can send, and where each comes from (a constant, a config value, or user input — the last means the
  full set is in play)
- Every REST path called, with its method
- Whether TranSafe identifiers are persisted in the developer's own database — `ttid`, `token`,
  `customer_id`, `ordernum`, `cardshieldticket` — and what reads them
- How results are read: HTTP status, `code`, `msoft_code`, `phard_code`, `verbiage`; and whether
  anything retries on a 5xx
- Scheduled jobs that call TranSafe (settlement, reports, exports), which are easy to miss
- Endpoints that **receive** TranSafe push notifications or hosted-page redirects. TranSafe calls
  these, so a search for outbound calls misses them, and Payroc has no transaction webhooks
- Gift-card or PayPal tender sent through the ordinary actions (`account=PAYPAL|…`, gift BIN ranges,
  a `sale`, `refund` or `balanceinq` on a gift card), which routes differently from a card sale
- Calls to TranSafe's UniTerm device API. No reference file maps it: if the code uses it, ask for a
  request sample

Then ask the developer, skipping anything the scan already answered:

1. **Which TranSafe surfaces do you call?** REST v2, REST v1, a KV transport, PaymentFrame, hosted or
   invoice pages. Share the paths or key/value pairs, or point me at the client code.
2. **Do you store TranSafe identifiers?** Especially `ttid` — referenced refunds and captures
   against TranSafe transactions do not carry over to Payroc.
3. **Do you have stored cards, bank accounts, customers or recurring schedules on TranSafe?** Each one
   moves differently, and some do not move at all.
4. **Do your merchants take gift cards, depend on TranSafe customer records, rely on TranSafe push
   notifications, use PaymentFrame, keep a product catalogue on TranSafe, or settle through Big
   Batch?** None ports directly (PaymentFrame's replacement is Hosted Fields). Some stop a merchant
   migrating yet, and the rest need a design decision (Step 4).
5. **Do you run card-present devices on TranSafe P2PE or E2EE keys?** Devices injected under a
   TranSafe key need Payroc's device migration before they can process on Payroc.
6. **What has to keep working on day one** versus what can be re-implemented later?
7. **Do you have a Payroc implementation contact?** Several answers in this migration depend on how
   the merchant's account and terminals are configured, or on how Payroc moves existing merchants,
   not on the API. Every Payroc call needs a `processingTerminalId`, and nothing derives it from a
   TranSafe `profile_id`: for existing merchants it comes from that contact.

---

## The routing table

> **Read `references/map-protocol-auth-and-results.md` before routing any call.** Transport,
> authentication and outcome signalling change for **every** TranSafe call, and that file states them
> once for all of them (the token exchange itself is in `references/identity-call.md`); the per-action
> files assume you have read it.

**Always consult this before opening a reference file.** REST v2 routes on the path. KV requests route
on the key/value pairs, because every row key carries both forms. REST v1 and KVS v8 route to
`map-v1-delta.md` first, except v1 Inventory, Order and Order Reports (see the v1 table).

### REST v2 (`/api/v2/…`) and KVS v9

| TranSafe path (v2) | Reference file |
| --- | --- |
| `/transaction/activate`, `/transaction/issue`, `/transaction/cashout`, `/transaction/refund/merchandise`, `/transaction/{ttid}/return/merchandise`, `/transaction/ebt/*`, `/transaction/check/*`, `/transaction/altpayment/*` | `map-gift-ebt-check-altpay.md` |
| Every other `/transaction/*` path, `/level3/*`, `/image*` | `map-card-transactions.md` |
| `/vault/payment/*` (including `/vault/payment/history`) | `map-recurring.md` |
| `/vault/account*`, `/vault/export*`, `/customer*`, `/system/database` | `map-tokens-vault-and-customers.md` |
| `/paypage/hosted*` | `map-paypages.md` |
| `/boarding/*` | `map-boarding.md` — **except** `/boarding/route/usage/processors` → `map-batch-and-reporting.md` |
| `/batch/*`, `/report*` (including `/report/chartdata/*`), `/device/report/*`, `/device/journal`; the automated-settlement scheduler: `POST /system/schedule/settlement`, `PATCH /system/schedule/settlement/{id}`, `GET /system/schedule/`, `DELETE /system/schedule/{id}`, `POST /system/schedule/{id}/run` | `map-batch-and-reporting.md` |
| `/apikey*`, `/user*`, `/velocity`, `/cardlist/*`, `/e2ee/*`, `/p2pe/*` | `map-users-and-merchant-config.md` |
| `/inventory*`, `/order*`, `/bigbatch*`, any other `/system/*` path (including every other `/system/schedule/*` task: purges, Big Batch settlement, account updater) | `no-equivalent-register.md` |

**Tender matters as well as path.** A `sale`, `refund` or `balanceinq` on a gift card, or a purchase
with `account=PAYPAL|…`, goes to `map-gift-ebt-check-altpay.md` (its cross-cutting fact on gift, PayPal
and EBT tender on the generic actions), not to the `payment` or `unreferencedRefund` rows in
`map-card-transactions.md`.

**KV requests (KVS v9):** search the reference files for the exact `key=value` pairs the code sends
(for example `action_trans=sale`, or `action_admin=token_schedule token_schedule=add`). Every row key
is written `REST2 <METHOD> <path> · KV9 {<k=v …>}`, so the pairs locate the same row as the path. Where
one set of pairs appears on more than one row, the row's `IF:` names the parameter that tells them
apart — read it, don't pick the first match.

### REST v1 (`/api/v1/…`) and KVS v8 (`action=…`)

| What the developer has | Reference file |
| --- | --- |
| Any other `/api/v1/*` path, any `action=<verb>` or `action=admin admin=<verb>` request | `map-v1-delta.md` first. Its rows say what differs from the v2 twin and point to the twin row (`⇒ REST2 …`), whose file holds the Payroc target and the behaviour change. Read both |
| v1 Inventory, Order and Order Reports | `no-equivalent-register.md` (not `map-v1-delta.md`) |

### Everything else

| What the developer has | Reference file |
| --- | --- |
| libMonetra, `<MonetraTrans>` envelope, POST/HMAC, raw IP/SSL; HTTP Basic, `X-API-KEY-ID`/`X-API-KEY`, `X-MFA-CODE`, `X-DUAL-Authorization`; reading `code`, `msoft_code`, `phard_code`; `duplcheck`; amounts and currency | `map-protocol-auth-and-results.md` |
| PaymentFrame (`/PaymentFrame`, `PaymentFrame.js`, its `postMessage` API), a bare TicketRequest POST, the customer-facing hosted page, the invoice page | `map-paypages.md` |
| A `cardshieldticket` (what it becomes) | `identifier-translation.md`; the actions that accept one are in `map-card-transactions.md` |
| Response fields and identifiers, amounts, `expdate`, currency, timestamps | `identifier-translation.md` |
| Data that already exists at cutover (schedules, automated-settlement tasks, hosted pages, open invoices, PaymentFrame integrations, history) | The `DATA` rows in the domain file, all indexed in `no-equivalent-register.md` |
| Stored tokens and customer records at cutover | The export rows in `map-tokens-vault-and-customers.md`; the token and customer entries in the index of `no-equivalent-register.md` |
| "Can I still do X?" / "What have we lost?" | `no-equivalent-register.md` (start from its index) |
| **Anything not matched above** | **Say you don't know, and ask for a request sample. Never infer a mapping that isn't in a reference file.** |

---

## Step 1 — Inventory the legacy integration

Produce a list of distinct TranSafe calls the codebase actually makes, keyed the way the mapping
tables are keyed: `REST2 <METHOD> <path> · KV9 {<k=v …>}` for v2 and KVS v9, or
`REST1 <METHOD> <path> · KV8 {<k=v …>}` for v1 and KVS v8. For example
`REST2 POST /transaction/purchase · KV9 {action_trans=sale}`. A KV-only integration has no path in
its code; key it by the pairs and let the reference row supply the path.

Three things to get right, because each causes silent under-scoping:

- **Enumerate discriminator values, don't assume one.** If `action_trans` or `action_admin` comes from
  a variable, find every value that can reach it. The same goes for sub-keys such as
  `token_schedule=` or `carddenylist=`.
- **Record the parameters that pick the row, not just the action.** One action can map to different
  Payroc calls depending on which parameters are present: `ttid` (a new sale versus a charge against a
  stored transaction; a linked versus an unlinked refund), `capture`, `apprcode`, `token` or
  `customer_id`, a schedule `id`, `order_id` and `payment_id`. The routed row's `IF:` names the one
  that matters. Write one inventory line per combination the code can send.
- **Include the read and reconciliation paths**, not just the payment path. Batch, report and export
  calls are where migrations typically discover an unmapped dependency late.
- **Include the browser surfaces.** PaymentFrame and hosted pages often live in front-end code that a
  server-side search misses.
- **Include the inbound surfaces.** A receiver for TranSafe push notifications or hosted-page redirects
  is part of the integration even though TranSafe calls it.

### Checkpoint

You have a de-duplicated list of keyed TranSafe calls, with their discriminating parameters and inbound
receivers, and the developer agrees it's complete.

---

## Step 2 — Route and look up each call

For each call in the inventory, resolve its reference file from the routing table, then read that file.

> **Before answering any question about what a TranSafe call becomes — including in a walkthrough, a
> summary, or a code comment — read the routed `references/*.md` file now.** Do not answer from the
> routing table, from this file's examples, or from memory. The routing table tells you which file to
> open; it does not contain a single mapping itself. Reading the reference file is mandatory, not
> optional.

> **For any `/api/v1/*` path or KVS v8 `action=` request, read `references/map-v1-delta.md` and then
> the twin row it points to.** A v1 row carries only what differs; the Payroc target and the behaviour
> change live on the twin.

`map-v1-delta.md` and `no-equivalent-register.md` are too large to read in one pass. For those two,
search for the exact row key (the path or the KV pairs), read that row in full together with the file's
cross-cutting facts, and read in pages where you need more.

Report each mapping with all five of: the verdict, the Payroc target, the request delta, the
behaviour change, and the confidence badge (the verdicts, tags and separators are defined in
`references/_sources.md`, "Reading a row"). **A verdict without its behaviour change is an incomplete answer** — the behaviour
change is where the migration risk lives. If the row key carries an `internal-only` or
`public build only` label, say so: the developer's code was built against something other than the
published TranSafe reference.

Group the results so the developer can act on them:

- **Ports cleanly** — same behaviour, only the request shape changes.
- **Ports with a behaviour change** — everything tagged `SEMANTIC:`, `SEQ:` or `LOSS:`. These need a
  decision, not just code.
- **Needs a runtime branch** — rows tagged `IF:`, where one TranSafe call becomes two Payroc paths.
- **No equivalent or configured** — send these to Step 4.
- **Unverified** — say so, and offer to escalate rather than generating code.

### Checkpoint

Every call in the inventory has a verdict, and every verdict other than a direct port has its
alternative, escalation route or condition stated.
Nothing is answered "probably".

---

## Step 3 — Transport, auth, identifiers and amounts

> **Read `references/identity-call.md` before emitting any auth code.** Do not guess the endpoint URL,
> header name, or response shape — use only what the reference documents.

> **Before writing any code that carries an identifier, an amount, a currency, a card expiry or a
> timestamp across from TranSafe, read `references/identifier-translation.md` now.** Do not infer any
> of these from field naming.

The ones that reliably bite (each is stated in full, with its conditions, in the files above):

- **Every TranSafe value is a string; Payroc amounts are integers in minor units.** TranSafe's amount
  pattern accepts `19`, `19.9` and `.5`, so deleting the decimal point is not a conversion: parse the
  decimal and multiply by 10 to the power of the currency's exponent (100 for `USD`).
- **Payroc requires a currency** on money-moving requests, as an alphabetic code (`USD`, not
  TranSafe's numeric `840`); TranSafe usually omits it.
- **Every Payroc payment, refund and token call needs a `processingTerminalId`**, and Payroc has no default terminal. Nothing on
  Payroc derives it from a TranSafe `profile_id`; for existing merchants, get the profile → terminal
  map from the implementation contact, and do not assume a format: how that map is delivered is
  **unverified**.
- **No Payroc endpoint resolves a TranSafe identifier.** A `ttid` stored before cutover cannot be
  refunded, captured or reversed on Payroc.
- **A `cardshieldticket` is not a single-use token.** A ticket lives 300 seconds and can be reused; a
  Payroc single-use token lives 30 minutes and works once. Where one ticket fed several calls, tokenise
  once (`credentialOnFile.tokenize: true`) and send the secure token afterwards.
- **Read the outcome, not the HTTP status.** Payroc's `payment` returns `201` for an approval and for
  a decline; read `transactionResult.status`. There are three groups, not two: approved (`ready`,
  `pending`), declined (`declined`, `referral`, `pickup`), and **not approved yet** (`accepted`,
  `admin`, or `responseCode` `E`): do not fulfil. Payroc documents no follow-up for that third group;
  fetching the payment again with `getPayment` (a refund with `getRefund`) is **inferred**, and
  `admin` may be terminal, so ask Payroc Integrations whether it can resolve. A payment read back later can also show `reversal`: it was reversed,
  for example by a full refund while its batch was open, so treat it as given back, not approved.
- **Drop TranSafe's retry logic; write Payroc's.** TranSafe REST v2 returns `500` for parse failures,
  duplicates and genuine system failures — retry-on-5xx logic must not be ported. On Payroc, mint one `Idempotency-Key` per
  logical payment before the first attempt and keep it; resend a timeout or `5xx` with the **same**
  key, which replays the original result, including a decline; fix a `4xx` rather than resending it;
  retrying a declined card on purpose needs a **new** key. "Allow a duplicate" is a fresh key, never
  an omitted header (that is a `400`). Payroc documents no content-based duplicate check **[inferred]**, so protection
  against a double submit, which `duplcheck` gave you, is now your code's job. A duplicate may still be
  declined by the issuer (`duplicateTransmissionDetected`), held at funding
  (`holdForSettlementDuplicate`) or declined on ACH ("Duplicate check number") after the fact: do not
  rely on those. Test it in the test environment, and never store the `ttid` of a TranSafe duplicate rejection.

### Checkpoint

The integration authenticates through the identity call, every call carries a `processingTerminalId`
from a confirmed source, every persisted identifier has either a named Payroc counterpart or an
explicit plan, and no amount, currency or result conversion is being done from assumption.

---

## Step 4 — Handle the capabilities that don't survive

> **Before telling a developer that a capability is gone, read `references/no-equivalent-register.md`
> now** — it holds every `none` and `config` verdict in one place, with an index by question. Do not
> assert an absence from a domain file alone, and do not assert one from this skill file at all.
> Start from its index or search it for the exact row key, as Step 2 describes.

Three verdicts that look alike and mean different things:

- **`none`** — there is no Payroc equivalent. The feature has to be redesigned or dropped, unless the
  register makes it a do-not-migrate-yet condition (below). Say so, and check the row's badge first: some `none`
  rows are checked absences, others rest on a point not yet confirmed. Say which.
- **`config`** — it isn't an API call any more, but the capability remains; Payroc configures it.
  The developer keeps the feature and raises a request. **Collapsing `config` into `none` tells the
  developer they've lost something they haven't**, which is the more damaging of the two errors.
- **`OUT`** — an action the integration cannot call on TranSafe either (server administration), or one
  this skill does not cover. It is not a lost capability. If the code calls an out-of-scope path (the
  SkyLink licensing calls, for example), say it is out of scope here: Payroc has no licence API either.

**Some gaps stop a merchant migrating, not just a feature.** The register's index marks these as
do-not-migrate-yet conditions. Name each one and the developer's options, with a Payroc contact as
one option:

- **Gift cards**: Payroc has no gift-card API. A merchant that uses them can leave gift cards off Payroc
  and keep them on TranSafe, move them to a third-party gift provider, or not migrate yet. What happens to
  balances on cards already issued, and to cash-out requests after cutover, has to be settled before
  cutover; ask your implementation contact.
- **A customer database** (customer records apart from tokens): a merchant that depends on one is not
  ready to migrate yet.
- **Transaction webhooks** (TranSafe push notifications): Payroc offers none today, so a merchant whose
  integration depends on them is not ready to migrate yet; ask your implementation contact about availability.
- **PaymentFrame**: Payroc's current position, which is not yet final, is that it will not migrate a
  merchant that uses PaymentFrame until its integration has moved to Hosted Fields and passed testing in the test environment.
  Confirm the position with the implementation contact before planning that merchant's cutover.

**Not blockers, but design decisions.** A product catalogue has no API: keep it in your own system or a
third-party POS (Payroc's product answer is Roc Terminal+), and line items can still travel on
`order.breakdown.items[]`. For Big Batch, each terminal settles its own batch (automatic `batchClosure`
or `closeBatch`); build any aggregate view over `getbatches`. Escalating either to Payroc is one option.

For anything in these buckets, give the developer the alternative or the escalation route the row
names. "No equivalent, no next step" is not a finished answer.

### Checkpoint

Every `none` and `config` row has been delivered with its alternative or escalation route, every
blocker has been named as one, and the developer knows which of their features need a design decision.

---

## Step 5 — Implement, via the task skills

This skill stops at the delta. For each mapped call, hand off to the skill the row names, and let it own
the request schema, the enums and the error handling:

| Target area | Skill |
| --- | --- |
| Card sales | `run-a-card-sale` |
| Pre-authorization, completion, incremental and adjust; reversal and void of a payment | `run-a-pre-authorization` |
| Refunds; void or reversal of a refund (`reverseRefund`, full only) | `refund-a-card-payment` |
| ACH / bank transfers | `take-an-ach-payment`, `refund-an-ach-payment`, `verify-bank-account` |
| Check conversion: no direct equivalent. An ACH debit needs an SEC code (`web`, `tel`, `ccd` or `ppd`), none of which names check conversion; which one is a compliance decision, so do not default to `ppd` | the ACH skills above, after that decision |
| Stored payment methods | `save-a-payment-method`, `create-single-use-token` |
| PaymentFrame replacement | `integrate-hosted-fields` |
| Hosted and invoice pages | `integrate-payment-links`, `integrate-hosted-payment-pages` |
| Wallets | `integrate-apple-pay`, `integrate-google-pay` |
| 3-D Secure | `run-a-sale-with-3ds` |
| Recurring and installment billing | `set-up-a-payment-plan`, `manage-subscriptions` |
| EBT balance | `check-ebt-balance` |
| Card lookups | `look-up-card-details` |
| Reporting and settlement | `view-settled-transactions`, `view-settlement-batches`, `view-authorizations` |
| Boarding and terminals | `create-merchant-platform`, `add-processing-account`, `order-a-terminal` |
| POS and devices | `integrate-payroc-cloud` |
| Boarding events (Payroc has no transaction events) | `set-up-event-subscriptions` |

The row's `Payroc target` cell is authoritative: where it names a skill, use that one, even if this
table suggests another.

**Where no task skill covers the target**, or the row names a field the task skill lacks, say so and
point to the operation the row names in the Payroc API reference; never fill the gap from memory. The
references name, among others, `verifyCard`, `updateSecureToken` (PATCH), `updateContact`, the
merchant-platform reads (`getMerchantAccounts`, `listMerchantPlatforms`), and EBT's `ebtDetails` and
`pinDetails`, which `run-a-card-sale` does not cover: an EBT payment sent without `ebtDetails` is a
valid PIN-debit sale on Payroc.

**Carry the behaviour changes across the handoff.** A `SEMANTIC:` hazard found in Step 2 is not the
target skill's job to re-derive — state it as a requirement when you hand off.

### Checkpoint

Each mapped call is being implemented against a current task skill, with its behaviour changes
recorded as explicit requirements.

---

## Step 6 — Plan the cutover

Migration-specific work that no task skill covers. Payroc moves existing merchants' data, arranged
through the implementation contact; the developer's work is in code. Read the `DATA` rows in the routed files and the
"what you can no longer do" index in `references/no-equivalent-register.md` before planning this.

- **Cut over per merchant, not on one date.** Merchants move to Payroc one at a time, on their own
  migration dates. The code needs a per-merchant switch between the two gateways that covers
  transactions, schedules, pages and reporting.
- **Open authorizations and unsettled sales.** No Payroc call can capture, reverse or adjust an
  authorization TranSafe holds. Complete, reverse or void each one on TranSafe and settle the last
  TranSafe batch there **before** cutover. See `references/identifier-translation.md`.
- **Refunds of pre-cutover sales.** Refund on TranSafe while it still runs; after that the only Payroc
  path is an unreferenced refund, which is account-gated and loses TranSafe's refund checks: it needs
  the card or a migrated secure token, takes only `pos` or `moto` channels, and your code must enforce
  the cumulative refund cap. Ask your implementation contact to enable it before cutover. Do not plan
  around a TranSafe switch-off date; ask your implementation contact whether one has been set for your
  merchants. After migration,
  TranSafe access is described both as read-only for 13 months and as refunds-only for a period that
  is not stated, so confirm which applies before counting on TranSafe refunds, and keep the
  TranSafe users and API keys that perform them working through cutover.
- **No destructive clean-up on TranSafe.** Do not delete TranSafe users, API keys, groups or
  profiles, or deactivate BDKs or devices, until Payroc confirms the data move. *Remove a Profile*
  also deletes its schedules, automated-settlement tasks and hosted pages and purges its transaction
  data; *Remove a Group* deletes its users and all API keys under it; *Delete User* deletes that user's API keys; BDK and device deactivation are permanent. See
  `references/map-boarding.md` and `references/map-users-and-merchant-config.md`.
- **Stored cards.** Payroc moves these; the developer's code does not. The code changes how it looks a
  migrated token up: Payroc puts the old token id in the imported record's `merchantref`
  (**inferred**), but which Payroc field and lookup expose it is unconfirmed, so confirm it with your
  implementation contact before building that lookup. Payroc states that its automated import does not carry ACH tokens (this is not in Payroc's published
  documentation, and the published import covers card data only): assume none carries over and ask your
  implementation contact whether yours were moved; if not, re-collect bank details and create new secure tokens
  before the first debit, and do not assume an old ACH token resolves. Gift-card and
  PayPal tokens come out in TranSafe's card ("cc") export with the cards (the effect on import is
  **inferred**): filter them out before import
  and plan for those stored payment methods ending at cutover. See
  `references/map-tokens-vault-and-customers.md` and `references/map-gift-ebt-check-altpay.md`.
- **Customers.** Payroc has no customer resource. The customer-to-card link has to live in the
  developer's own records (or in the `customer` object embedded on each token: one person with three
  cards becomes three unlinked secure tokens), and a merchant that depends on a customer database is not ready to migrate
  yet (Step 4).
- **Recurring and installment schedules.** There is no schedule export or import. Ask your implementation
  contact whether existing schedules are carried over, and tell the merchant neither "retained" nor
  "recreate" until answered; if you must plan now, treat recreation as the contingency. Recreate only
  the **remaining** installments: never copy `installment_total` into `length`, which charges the
  cycles already paid a second time (Payroc cannot set `paidInvoices`). The per-payment amount and final
  charge need care; see `references/map-recurring.md`. ACH-funded schedules depend on ACH token
  migration, and deboarding the TranSafe profile also switches its schedules off. Whoever recreates a
  schedule on Payroc must disable the TranSafe schedule
  (`status=disabled`) **before** the Payroc `startDate`, or both gateways charge the same cycle. If you
  might re-enable a TranSafe schedule later (a rollback), set its SKIPMISSED flag first: reactivating
  it otherwise charges the failed cycle and every missed cycle back to back. `flags=SKIPMISSED`
  replaces the schedule's whole flag set, and `skipmissed=yes` works only on an edit that sends no
  `flags`. Payroc does not document missed-cycle behaviour: do not port catch-up billing as an
  assumption. See `references/map-recurring.md`.
- **Automated settlement** moves from a TranSafe scheduler task to terminal configuration. Before
  cutover, list each profile's `SETTLE` tasks for the implementation contact, and leave each one
  running until that merchant's last TranSafe batch has settled, then delete it. After cutover check
  the migrated terminal's `batchClosure`: if `manual`, call `closeBatch` yourself. See
  `references/map-batch-and-reporting.md`.
- **Hosted pages, open invoices and PaymentFrame** have no documented import, and no source says whether
  Payroc moves existing pages or invoices for the merchant, so do not promise it. PaymentFrame
  can also hold a merchant on TranSafe (Step 4). For each page you still need (or retire it): create the Payroc link,
  swap the URL wherever it is published, then delete the TranSafe page so it cannot take a payment
  after the switch. See `references/map-paypages.md`.
- **Transaction webhooks.** Payroc offers no transaction webhooks today; a merchant whose integration
  depends on TranSafe push notifications is not ready to migrate; ask your implementation contact about
  availability. Before cutover, inventory your TranSafe push endpoints,
  including any inherited from parent groups. The only Payroc server notification of a transaction result is Hosted
  Payment Page background validation, for HPP card payments. See `references/map-boarding.md`.
- **Card-present devices and encryption keys.** Data from a device injected under a TranSafe BDK
  cannot be decrypted by Payroc unless the key moves or the device is re-injected or replaced. Which of
  those applies to your devices is **unverified**: ask your implementation contact before cutover. Do not deactivate a TranSafe BDK until every device under it has moved. See
  `references/map-users-and-merchant-config.md`.
- **Running both in parallel.** Settlement and reporting reconciliation spans two platforms for the
  overlap, and Payroc reporting covers only the transactions Payroc processed (**inferred**: history does not move). Flag it as work, and
  export any TranSafe history you need before it is switched off; TranSafe keeps the device journal
  for 30 days only, so export that early (see `references/map-batch-and-reporting.md`).

### Checkpoint

The developer has a per-merchant cutover plan covering open authorizations, historical refunds and the
TranSafe access they need, stored tokens and customers, schedules (with each TranSafe schedule disabled
before its Payroc replacement starts), settlement configuration, pages, push notifications, devices and
keys, and the reconciliation overlap, and nothing on TranSafe is deleted before Payroc confirms the
data move.

---

## Common failure modes

These are migration-specific. For Payroc API errors, use the error taxonomy in the target task skill.
Each row is a summary; the reference file named holds the conditions.

| What happens | Why | Fix |
| --- | --- | --- |
| A partial reversal gives back the part the merchant meant to keep | TranSafe's reversal `amount` is the amount to settle; Payroc's is the amount to reverse | Compute original − kept; see the reversal row in `references/map-card-transactions.md` |
| Declines are booked as approvals | Payroc returns `201` for both; code ported from TranSafe v2 treats success status as approval | Read `transactionResult.status`: approved, declined, or not approved yet (`accepted`, `admin`, `responseCode` `E`: do not fulfil); see `references/map-protocol-auth-and-results.md` |
| Duplicate charges after a TranSafe error | Retry-on-5xx ported from TranSafe v2, where 500 means a parse failure or a duplicate | Remove TranSafe's retry-on-500. On Payroc, retry a timeout or `5xx` with the **same** `Idempotency-Key`, which replays rather than rejects; mint one key per logical payment; a deliberate retry of a declined card needs a new key; see `references/map-protocol-auth-and-results.md` |
| Customers are charged twice for one cycle | A schedule recreated on Payroc while the TranSafe schedule is still active; or a disabled TranSafe schedule re-enabled without SKIPMISSED, which charges every missed cycle | Disable the TranSafe schedule before the Payroc `startDate`; see `references/map-recurring.md` |
| Tips are charged twice, or tax is computed on the tip | TranSafe's `examount` tip is already inside `amount` | Keep `order.amount` as the total and put the tip in `order.breakdown.tip` (`breakdown` then needs `subtotal`); see `references/map-card-transactions.md` |
| A refund returns no `refundId` | The payment's batch was still open, so Payroc reversed it instead: a full refund shows `transactionResult.status` `reversal`, a partial one lowers `order.amount` and stays `ready` | Read the outcome from those two fields; see the refund row in `references/map-card-transactions.md` |
| EBT sales settle as PIN debit | `ebtDetails` was not sent; without it an EBT payment is a valid PIN-debit sale | Send `ebtDetails` from the Payroc API reference (`run-a-card-sale` does not cover it); see `references/map-gift-ebt-check-altpay.md` |
| Installment customers are charged the whole balance every cycle | TranSafe installment `amount` is the total; Payroc's is per payment | See `references/map-recurring.md` |
| Batches "closed" on TranSafe now settle on Payroc | TranSafe close does not send to the processor; Payroc `closeBatch` settles | Never port close as `closeBatch`; see `references/map-batch-and-reporting.md` |
| Token logic keys off the wrong `status` | Both sides return a field named `status` with unrelated meanings: TranSafe's says whether a token may be used, Payroc's is a validation outcome | Never map one to the other; see `references/map-tokens-vault-and-customers.md` |
| Amounts may be surcharged twice | **Inferred** (the Payroc `payment` request side is undocumented): TranSafe's `amount` already includes the surcharge; on a Payroc terminal with surcharging enabled the total may be surcharged again. You cannot send a surcharge amount on Payroc, only `surcharge.bypass` | Confirm which amount to send with Payroc Integrations; see `references/identifier-translation.md` |
| A ticket reused across requests now fails | A `cardshieldticket` (300 s, reusable) became a single-use token (30 min, one use) | Tokenise once and send the secure token; see `references/identifier-translation.md` and `references/map-paypages.md` |
| A capability is reported as lost that isn't | A `config` row read as a `none` row | See Step 4 |
| A mapping was generated for a call not in any reference file | Principle 2 was skipped | Retract it, and ask for a request sample |

---

## Validation checklist

- [ ] Every TranSafe call in the inventory was routed via the routing table, not answered from the action name
- [ ] Every mapping came from a reference file that was actually read — none inferred, none from memory
- [ ] Every v1 / KVS v8 call was read together with its v2 twin row
- [ ] Every `unverified` row (or half) was reported as unverified to the developer before any code was written from it
- [ ] Every `SEMANTIC:`, `LOSS:` and `SEQ:` note was surfaced explicitly, not summarised away
- [ ] Every ` | ` branch row was implemented as a runtime branch with its `IF:` predicate, or, where the predicate is a design choice (which page type, say), resolved once with the reason recorded
- [ ] Every `none` and `config` row was delivered with its alternative or escalation route
- [ ] `config` rows were not reported as lost capabilities
- [ ] Every do-not-migrate-yet condition (gift cards, a customer database, transaction webhooks, PaymentFrame) was named as one, with its options; catalogue and Big Batch were given their alternatives, not treated as blockers
- [ ] Auth code emitted from `references/identity-call.md`, not from memory
- [ ] Results read from the transaction result (including the not-approved-yet states), not the HTTP status; TranSafe's retry-on-5xx removed, and Payroc retries reuse the original `Idempotency-Key`
- [ ] Identifier, amount, currency and expiry conversions read from `references/identifier-translation.md`
- [ ] Open TranSafe authorizations drained and the last batch settled before cutover; historical refund strategy decided
- [ ] Each TranSafe schedule disabled before its Payroc replacement starts; nothing deleted on TranSafe before Payroc confirms the data move
- [ ] Credentials for both platforms sourced from environment variables — never hardcoded
- [ ] Test API key used during testing (same `api.payroc.com` host as production)

---

## Completion

Once the checklist passes:

> **Migration mapping complete.** Here's where you stand:
>
> - **Ports cleanly** — [list]
> - **Ports with a behaviour change** — [list, each with its change]
> - **Do-not-migrate-yet conditions** — [list, each with its options]
> - **No Payroc equivalent** — [list, each with its alternative or escalation]
> - **Configured rather than called** — [list]
> - **Unresolved** — [list, with what's needed to close each]
>
> **Before going live:** swap the test API key for a live one, point the terminal ID at the
> production terminal, and confirm with your implementation contact that the merchant's
> data migration has completed.

Offer next steps:

- **Implement the mapped calls** — hand off to the task skills listed in Step 5
- **Close the unresolved items** — most need the merchant's configuration or the migration plan, which
  the Payroc implementation contact can confirm
- **Check webhook dependencies** — Payroc offers no transaction webhooks today, so an integration that
  depends on TranSafe push notifications is not ready to migrate; ask your implementation contact about availability. Only HPP card payments have a server notification (background validation). Payroc's event
  subscriptions (`set-up-event-subscriptions`) carry boarding events only

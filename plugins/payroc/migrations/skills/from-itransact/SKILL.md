---
name: from-itransact
description: >
  Guides developers through porting an existing iTransact integration to the Payroc API before
  Payroc retires the iTransact gateway. Use this skill when the user wants to: migrate off iTransact;
  find the Payroc equivalent of an xmltrans2 or xmltrans XML request, an ord.cgi or split-form post, a
  direct-call CGI, an api.itransact.com JSON API route, or a gateway
  servlet request; port an iTransact SDK, plugin, client, postback receiver or the itransact.js
  Checkout script; translate xid, token, customer or recipe identifiers, amounts and currency; find out
  whether a capability still exists on Payroc; or plan the cutover of stored cards and
  recurring schedules. Do NOT use this skill when the user is building a new Payroc integration with no
  iTransact code (use the relevant task skill such as run-a-card-sale or integrate-hosted-fields), when
  they are migrating from IBX (use from-ibx) or another provider, or when they already know the Payroc
  operation they need and only want to implement it.
metadata:
  version: "0.1.3"
  category: migration
  status: draft
---

# Migrate from iTransact to the Payroc API

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/migrations/skills/from-itransact/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Migrate from iTransact to the Payroc API**
> Payroc is retiring the iTransact gateway, so this migration is time-critical. I'll work through your iTransact integration call by call, tell you what each one becomes on the Payroc API, and flag the places where the shapes match but the behaviour doesn't. Those are what break a migration.
>
> **How this works:** I look up each iTransact call your code actually makes in a mapping reference. I don't reason about it from the operation name. Where a call has a Payroc equivalent I'll hand you off to the task skill that implements it. Where it doesn't, I'll say so plainly.
>
> If you can share the requests your code sends to iTransact, or the code that builds them, the mapping gets a lot more precise.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
iTransact XML      →  /cgi-bin/rc/xmltrans2.cgi, /cgi-bin/rc/xmltrans.cgi   (rc4 is the same path)
iTransact forms    →  /cgi-bin/rc/ord.cgi, /cgi-bin/mas/split.cgi, buynow.cgi, the direct-call CGIs
iTransact JSON     →  https://api.itransact.com/{transactions|tokens|customers|recipes|subscriptions|payouts}
iTransact servlet  →  /gateway/registered/GatewayServlet   (XML root element picks the request)
iTransact browser  →  js.itransact.com/itransact.js        (Checkout)
Payroc API         →  https://api.payroc.com/v1/...        (test and production; a test API key selects test)
```

iTransact speaks five protocols: XML posts, HTML form posts, JSON REST, a browser script, and listing
URLs with a SOAP service. Payroc speaks one: JSON over HTTPS with a bearer token. Every iTransact
signing scheme goes away. Expect to rewrite requests and response handling, not swap URLs.

Two names appear in the mapping keys and nowhere in your code: **Melia** is the JSON API on
`api.itransact.com` (keys start `MELIA`), and **Fife** is iTransact's merchant API and hosted-page
application, mostly under `/h/` on the web hosts (keys start `FIFE`).

---

## References

Every mapping lives in the local `references/` files below. This skill answers from them, not from
live lookups and not from memory. **There is no general rule for converting an iTransact call to a
Payroc call.** If a call is not in a reference file, this skill does not cover it: say so and ask for a
request sample.

| Source | Local file | Use for |
| --- | --- | --- |
| Protocol, auth and results | `references/map-protocol-auth-and-results.md` | Read first. Transports, the iTransact authentication schemes, outcome signalling, duplicate control, amounts, hostnames, the sunset, and the **URL table** that routes any iTransact URL to its mapping row |
| Identifiers and formats | `references/identifier-translation.md` | `xid` and every other identifier, tokens, customer and recipe IDs, amounts, currency, expiry, dates, and the data that must move at cutover |
| XML API | `references/map-xml-api.md` | The 13 xmltrans2 operations (`AuthTransaction`, `VoidTransaction`, `TranCredTransaction` and the rest) and the deprecated xmltrans `SaleRequest` |
| Direct-call CGIs | `references/map-direct-cgis.md` | `void.cgi`, `credit.cgi`, `postauth.cgi`, `trancred.cgi`, `tranforce.cgi`, `tranretry.cgi`, and the `captcha`, `ccreg` and `mreg` CGIs |
| Browser forms and pages | `references/map-browser-forms-and-pages.md` | `ord.cgi`, the split and buy-now forms, Checkout (`itransact.js`), `nvpairs`, hosted payment-link and invoice pages, receipt pages |
| JSON API | `references/map-json-api.md` | `api.itransact.com` transactions, customers and tokens |
| Recurring | `references/map-recurring.md` | `api.itransact.com` recipes and subscriptions, and the billing-update pages and POSTs |
| Payouts | `references/map-payouts.md` | `api.itransact.com` `/payouts`, and the payouts service routes (`/card_acceptors`, `/terminals`, `/transactions/payout`) |
| Transaction reporting | `references/map-transaction-reporting.md` | The transaction-listing URLs and exports, the `pinauth` SOAP operation, the merchant API `transactions` and `send_receipt` routes |
| Postbacks | `references/map-postbacks.md` | An endpoint your system runs to **receive** an iTransact postback |
| Gateway servlet | `references/map-gateway-servlet.md` | XML requests posted to `/gateway/registered/GatewayServlet`, one row per root element. **Mapped provisionally** |
| SDKs | `references/map-sdks.md` | The official iTransact node, php, php-xml-example and java libraries |
| Plugins and clients | `references/map-plugins-and-clients.md` | osCommerce, RediCart, VirtueMart and the other first-party plugins and samples; third-party clients such as activemerchant and woocommerce-itransact |
| No equivalent or configured | `references/no-equivalent-register.md` | Every "no equivalent" and "configured, not called" verdict in one place, plus iTransact surfaces no merchant code calls |
| Payroc authentication | `references/identity-call.md` | The Payroc Identity Service token exchange: endpoint, header, response |

These are local snapshots, authoritative for this skill. Their provenance and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md), which also explains what each
confidence badge means and how far it goes.

---

## Core Principles

1. **Route from the call the developer's code actually contains, never from the operation name alone.**
   A void exists as xmltrans2 `VoidTransaction`, as `void.cgi`, as `PATCH /transactions/:id/void` on
   `api.itransact.com`, and as a gateway servlet root, with different inputs and different rows.
   Resolve the URL, the XML root or the API path first, using the routing table below.

2. **Never infer a mapping that is not in a reference file.** If the call isn't in the routed file,
   check `references/no-equivalent-register.md`, and if it isn't there either, **say you don't know and
   ask for a request sample.** A plausible-sounding mapping is the most damaging thing this skill can
   produce, because it will look right in review.

3. **A shape match is not a behaviour match.** Two operations that both take a card and an amount and
   return an approval are not equivalent if one captures and the other doesn't. The failure here is
   not an error. It's a request that succeeds and does the wrong thing. Every row tagged `SEMANTIC:` is
   a case where the port compiles, passes review, and behaves differently in production. Surface those
   to the developer explicitly; don't bury them in a summary table.

4. **Read the separators literally.** In every mapping table, ` → ` means **sequence** (do all of
   these, in this order) and ` | ` means **branch** (pick one at runtime, per the row's `IF:`
   predicate). Reading ` | ` as "and" issues a reversal *and* a refund. A branch row always carries an
   `IF:` predicate; if you can't find one, don't guess the condition.
   **Evaluate the predicate before any call, using only what the row's `IF:` names**: the payment
   type, a status, or, where the row names it, `supportedOperations` on a card payment (fact 10 in `references/map-protocol-auth-and-results.md` says which field shows the
   batch state for each payment type). Don't gate an
   arm on a field the row doesn't name for that payment type. Then send only the arm the predicate
   selects. Never send one arm and let its failure choose the other, and never turn a refused reversal
   into a refund: where a late void used to fail on iTransact and move no money (on the processors the
   row names), a refund is a separate decision for the merchant. If a row says a response is not stated
   (for example, what a refused call returns), don't state it as fact in code comments or prose.

5. **Honour the confidence badge, and say it out loud.** `verified` on the iTransact side means
   iTransact's own implementation or configuration agrees with the row; it was not exercised with live
   transactions.
   **No Payroc half is `verified`**: each is `inferred` from Payroc's documentation or `unverified`, so
   test the behaviour a row names in the test environment before going live. **Never turn an `unverified` row into code
   without telling the developer it's unverified**; offer to escalate or ask for a request sample
   instead. A split badge is only as strong as its weaker half.

6. **Keep every hedge at the strength the row states it.** Keep each at exactly the strength stated; stating
   any of them more firmly would be false:
   - The gateway servlet is mapped **provisionally**: which integrations still post to it directly is
     not established.
   - A CGI "not in any tagged iTransact release image since December 2021" is a statement about image
     builds, not about production. Whether production still serves it is not established; keep it at
     exactly that strength.
   - Split-form results are **probably** `ord.cgi` results.
   - Every pairing of an iTransact form or plugin with the Payroc Hosted Payment Page is **inferred**.
     So is `MERCHANTREF` as the `secureTokenId`: inferred, not shown. Don't present either as established.
   - An absence on the Payroc side ("Payroc's documentation describes no ...") reflects what Payroc's
     documentation covers, not a confirmed product limit. Give the row's escalation route; never write
     "Payroc cannot". This holds in summaries and asides too: write "Payroc's documentation describes
     no X", not "Payroc has no X" or "there is no Payroc counterpart".

7. **Deployment questions have one answer: migrate the caller either way.** Whether production
   iTransact still runs a given build, CGI, sender or servlet is not something the developer can look
   up. Don't send them to check. Say it is not established and migrate any caller regardless. Reserve
   "check this in your iTransact account before cutover" for settings a merchant can actually see,
   such as duplicate rejection.

8. **"You can no longer do this" is an answer, and it's the highest-stakes one.** Deliver it plainly,
   with the alternative or the escalation route from the row. Never soften it into a vague equivalent,
   and never pad it with a Payroc operation that doesn't do the same job.

9. **Hand off for the *how*.** This skill owns the delta: what changes, and what breaks. Once a call
   is mapped, send the developer to the task skill that documents the target operation. Don't restate a
   Payroc request schema here; those skills keep theirs current and this one would drift.

10. **Never hardcode credentials.** iTransact API keys, gateway passwords and Payroc API keys all come
    from environment variables or a secrets manager.

---

## Intake

**First, scan the codebase.** The answer is usually in the source:

- iTransact hosts and paths: grep for `itransact.com`, `paymentclearing.com`, `redi-check.com`,
  `xmltrans`, `cgi-bin/rc`, `cgi-bin/mas`, `ord.cgi`, `split.cgi`, `GatewayServlet`, `/h/merchant_api`,
  `translist`
- XML operation elements and root elements: `AuthTransaction`, `VoidTransaction`, `SaleRequest`,
  `CardSaleRequest` and the like
- The browser script: `itransact.js`, `data-api-username`, `itransact-checkout-modal`. A script tag
  ending in `jtlv2.js` is the IBX build of Checkout; send that to the from-ibx skill
- An iTransact SDK, plugin or client in the dependencies (`activemerchant`, `woocommerce-itransact`,
  the node, php or java SDK, an osCommerce or RediCart module)
- A route in the developer's own app that **receives** posts from iTransact (a postback or return URL)
- Stored `xid`, token, customer, recipe or subscription identifiers in the developer's database, and
  what reads them
- Scheduled jobs that call iTransact, which are easy to miss and often carry reconciliation logic

Then ask the developer, skipping anything the scan already answered:

1. **Which iTransact surfaces do you call?** Share the URLs or point me at the client code.
2. **Do you store iTransact identifiers?** No iTransact transaction ID can be passed to a Payroc
   operation, so anything that reads a stored `xid` needs a plan.
3. **Do you have stored cards, bank accounts or recurring schedules on iTransact?** Cards have a
   documented import process with a lead time. Bank accounts and schedules don't move the same way.
4. **Do you receive postbacks from iTransact?** Those receivers get rewritten, not re-pointed.
5. **What has to keep working on day one**, once iTransact switches off?
6. **Do you have a Payroc implementation contact?** Several answers depend on account configuration,
   not on the API.

---

## The routing table

**Always consult this before opening a reference file.** It names the file; it contains no mapping.

| What the developer's code has | Reference file |
| --- | --- |
| An xmltrans2 request (posted to `xmltrans2.cgi`) or an xmltrans `SaleRequest` (posted to `xmltrans.cgi`) | `map-xml-api.md` |
| An XML root such as `CardSaleRequest` posted to `/gateway/registered/GatewayServlet` (or any `/gateway/*` path) | `map-gateway-servlet.md` |
| `/cgi-bin/rc/ord.cgi`, `/cgi-bin/mas/split.cgi`, `buynow.cgi`, `split_old.cgi`, `/scripts/receipt/index`, `/h/cp/public/*`, `nvpairs.cgi` | `map-browser-forms-and-pages.md` |
| Any other `/cgi-bin/rc/<dir>/<name>.cgi` | `map-direct-cgis.md`, or `no-equivalent-register.md` if it is listed there as a surface merchant code doesn't call |
| `/jfe/translist/*`, `/h/merchant_api/*` | `map-transaction-reporting.md` |
| `/h/cp/recurring/*`, `/customers/billing_update/*`, `/merchant_api/billing_update` | `map-recurring.md` |
| `api.itransact.com` `/transactions`, `/tokens`, `/customers` | `map-json-api.md` |
| `api.itransact.com` `/recipes`, `/subscriptions` | `map-recurring.md` |
| `api.itransact.com` `/payouts`; payouts service paths `/card_acceptors`, `/terminals`, `/transactions/payout`, `/transactions/external_reference_id/*` | `map-payouts.md` |
| `js.itransact.com/itransact.js` (Checkout) | `map-browser-forms-and-pages.md` |
| An endpoint in the developer's system that receives a postback from iTransact | `map-postbacks.md` |
| An official iTransact SDK (node, php, java) | `map-sdks.md` |
| A plugin, sample or third-party client library | `map-plugins-and-clients.md` |
| Authentication, signing, response parsing, duplicate handling, hostnames | `map-protocol-auth-and-results.md` |
| Identifiers, amounts, currency, expiry, dates | `identifier-translation.md` |
| "Can I still do X?" / "What have we lost?" | `no-equivalent-register.md` |
| **Anything not matched above** | **Say you don't know, and ask for a request sample. Never infer a mapping that isn't in a reference file.** |

**URLs on any iTransact host**, including `secure.paymentclearing.com`, `staticgateway.itransact.com`
and the `-test` twins: look the exact path up in the URL table in
`references/map-protocol-auth-and-results.md`. It gives the row key and the file for every known URL
spelling, and says which hosts answer each path. `rc4` is the same as `rc`.

---

## Step 1 — Inventory the legacy integration

Produce a list of distinct iTransact calls the codebase makes, keyed the way the mapping tables are
keyed: `<PREFIX> <identifier>`, for example `XML2 AuthTransaction`, `CGI void/void.cgi`,
`MELIA PATCH /transactions/:id/void`, `SERVLET CardSaleRequest`, `POSTBACK perl order postback`. For a
URL, take the key from the URL table rather than building it yourself; a CGI's key is its file path,
not its URL.

Two things to get right, because both cause silent under-scoping:

- **Enumerate every operation the code can send, not the one someone remembers.** If the xmltrans2
  operation element or the form's mode comes from a variable, find every value that can reach it.
- **Include the read, receive and reconciliation paths**, not just the payment path: transaction
  listings and exports, receipt pages, and postback receivers.

### Checkpoint

You have a de-duplicated list of keyed iTransact calls, and the developer agrees it's complete.

---

## Step 2 — Route and look up each call

For each call in the inventory, resolve its reference file from the routing table, then read that file.

> **Before answering any question about what an iTransact call becomes, including in a walkthrough, a
> summary, or a code comment, read the routed `references/*.md` file now.** Do not answer from the
> routing table, from this file's examples, or from memory. The routing table tells you which file to
> open; it does not contain a single mapping itself.

> **Read `references/map-protocol-auth-and-results.md` before the first domain file.** Every other file
> points back to its cross-cutting facts instead of repeating them.

Report each mapping with all four of: the verdict, the Payroc target, the request delta, and the
behaviour change. **A verdict without its behaviour change is an incomplete answer.**

Group the results so the developer can act on them:

- **Ports cleanly**: same operation, same behaviour, only the request shape changes.
- **Ports with a behaviour change**: everything tagged `SEMANTIC:`, `SEQ:` or `LOSS:`. These need a
  decision, not just code.
- **Needs a Payroc enablement**: every `CFG:` note in any row, whatever its verdict (for example pre-authorization on the
  terminal, unreferenced refunds, offline payments, custom fields). Carry these to Step 7.
- **Needs a runtime branch**: rows tagged `IF:`, where one iTransact call becomes two or more Payroc
  paths.
- **No equivalent or configured**: send these to Step 5.
- **Unverified**: say so, and offer to escalate rather than generating code.

SDK, plugin and client rows wrap another row. They carry only what differs; read the wrapped row too.

### Checkpoint

Every call in the inventory has a verdict, and every non-`direct` verdict carries its required cell.
Nothing is answered "probably" unless the row itself says "probably".

---

## Step 3 — Resolve identifiers, amounts and currency

> **Before writing any code that carries an identifier, an amount, a card expiry or a currency across
> from iTransact, read `references/identifier-translation.md` now.** Do not infer any of these from
> field naming.

The ones that reliably bite:

- **No iTransact identifier carries across.** An `xid` can't be passed to any Payroc operation, so a
  follow-on against an old iTransact transaction can't run on Payroc. Plan what reads stored `xid`
  values before writing code.
- **The developer stores more than before.** Payroc assigns `paymentId` and `refundId`; the merchant
  assigns `orderId`, `secureTokenId`, `paymentPlanId` and `subscriptionId`. A legacy integer `xid`
  column can't hold a `paymentId`.
- **Amounts are not one format.** The XML, form and CGI surfaces take decimal dollars; the JSON API
  takes integer cents. Payroc REST takes an integer in the currency's lowest denomination, while the
  Payroc Hosted Payment Page takes a decimal `AMOUNT`.
- **No iTransact request carries a currency, and Payroc requires one.**

### Checkpoint

Every identifier the integration persists has a named Payroc counterpart or an explicit plan, and no
amount or currency conversion is done from assumption.

---

## Step 4 — Replace authentication and response handling

> **Read `references/identity-call.md` before emitting any auth code.** Do not guess the endpoint URL,
> header name, or response shape — use only what the reference documents.

> **Read the AUTH, RESULT and duplicate-control rows in `references/map-protocol-auth-and-results.md`
> before rewriting how a request is signed, how a response is read, or how a retry is sent.**

What changes, in outline (the rows hold the detail):

- **Signing code is removed, not ported.** Payroc REST calls carry a bearer token from the Identity
  Service. The exception is a form moved to the Payroc Hosted Payment Page, which builds and verifies a
  `HASH` of its own.
- **A decline is not an HTTP error on Payroc.** A Payroc payment returns 201 whether the card is
  approved or declined. Read the result fields the row names; never treat a 201 as an approval. The
  RESULT rows list which statuses are successes (`ready`, `pending` and `complete`) and which are not final (`accepted`, `admin`);
  don't treat a success status as a failure either. If you send `acceptPartialAmount: true`, compare `authorizedAmount` with
  `order.amount` before fulfilling.
- **Map statuses, not texts.** iTransact's production decline and error texts are not established.
- **Duplicate control inverts.** Payroc requires an `Idempotency-Key` on the requests the row names.
  Read the retry row before writing retry logic. A deliberate new attempt after a decline needs a new
  `Idempotency-Key` and a new `orderId`, so a later lookup by `orderId` can't find the earlier decline.

### Checkpoint

No iTransact signing code survives in the Payroc path, the token exchange comes from the reference,
and every response handler reads the result fields rather than the HTTP status alone.

---

## Step 5 — Handle the capabilities that don't survive

> **Before telling a developer that a capability is gone, read `references/no-equivalent-register.md`
> now.** It holds every `none` and `config` verdict in one place. Do not assert an absence from a
> domain file alone, and do not assert one from this skill file at all.

Two verdicts that look alike and mean opposite things:

- **`none`**: there is no Payroc equivalent. The feature has to be redesigned or dropped. Say so.
- **`config`**: it isn't an API call any more, but the capability remains; Payroc configures it. The
  developer keeps the feature and raises it with their Payroc implementation contact. **Collapsing
  `config` into `none` tells the developer they've lost something they haven't.**

The register also lists iTransact surfaces no merchant code calls (staff, admin, test and human-UI
pages). Those have nothing to port; don't report them as lost.

For anything `none` or `config`, give the developer the alternative or the escalation route the row
names. "No equivalent, no next step" is not a finished answer.

### Checkpoint

Every `none` and `config` row has been delivered with its alternative or escalation route, and the
developer knows which features need a design decision.

---

## Step 6 — Implement, via the task skills

This skill stops at the delta. For each mapped call, hand off to the skill the row names, and let it
own the request schema, the enums and the error handling:

| Target area | Skill |
| --- | --- |
| Card sales | `run-a-card-sale` |
| Pre-authorization and capture | `run-a-pre-authorization` |
| Refunds and reversals | `refund-a-card-payment`, `refund-an-ach-payment` |
| ACH payments | `take-an-ach-payment`, `verify-bank-account` |
| Stored payment methods | `save-a-payment-method`, `create-single-use-token` |
| Browser-side capture | `integrate-hosted-fields`, `integrate-hosted-payment-pages`, `integrate-payment-links` |
| Recurring billing | `set-up-a-payment-plan`, `manage-subscriptions` |
| Reporting | the skill the row names, such as `view-settled-transactions` or `view-settlement-batches` |
| Boarding | `create-merchant-platform`, `add-processing-account` |
| Card lookups | `look-up-card-details` |
| Webhooks and events | `set-up-event-subscriptions` |

**Payroc's documentation describes no equivalent for iTransact card payouts.** Payroc funding instructions
(`send-funds-to-a-merchant`) move money to a bank account, a different feature. Read
`references/map-payouts.md` before suggesting one as a redesign.

**Carry the behaviour changes across the handoff.** A `SEMANTIC:` hazard found in Step 2 is not the
target skill's job to re-derive. State it as a requirement when you hand off. When handing off to
`integrate-hosted-payment-pages`, carry the row's own hedge with it: the pairing is inferred.

### Checkpoint

Each mapped call is being implemented against a current task skill, with its behaviour changes
recorded as explicit requirements.

---

## Step 7 — Plan the cutover now

> **Read the DATA rows in `references/identifier-translation.md` and
> `references/map-protocol-auth-and-results.md` before planning the cutover.**

Migration work that no task skill covers:

- **Time is short.** Payroc is retiring the iTransact gateway; confirm the timing for your account
  with your Payroc implementation contact. What the iTransact hostnames do after the switch-off is
  not stated, so don't plan on them answering.
- **Stored cards.** Payroc documents a card-token import: started by emailing Payroc's Gateway Team (Step 1 of Payroc's token-import page), then a PGP-encrypted CSV delivered over SFTP. It's a process, not an API call. Payroc quotes about 30 business days from receiving the file, so with the
  switch-off close, a file not already with Payroc cannot be assumed to land before it. Choose the fallback now:
  re-collect cards from cardholders into secure tokens (Hosted Fields, `integrate-hosted-fields` and `save-a-payment-method`; or
  the Hosted Payment Page's Secure Card Page, an inferred pairing), or plan for stored-card and recurring charges to pause until
  the import lands. Raise the timing with your Payroc implementation contact now. Whether iTransact is an accepted import source is not established; confirm it
  first. The developer chooses each card's `merchantref`.
- **Bank accounts.** Payroc's published import covers card data only. Read the row for the
  alternative before promising anything.
- **Recurring schedules** are re-created, not imported: cards first, then payment plans, then one
  subscription per live schedule, and pause or deactivate each schedule on iTransact before its Payroc `startDate`; nothing
  stops both platforms collecting in the overlap. Set each `startDate` (today or later) to the first due date after the last
  iTransact collection so the same number of payments remain, and check whether a plan `setupOrder` collects at once. Read the
  row for the order and the start-date rule.
- **Transaction history** stays on iTransact. Export what the merchant needs before the switch-off;
  refunds of old sales become unreferenced refunds on Payroc, which need the card number or a secure token for the card, run only
  on the `pos` or `moto` channel, and are available only to some merchants (whether Payroc enables them for iTransact merchants
  is not established; ask your Payroc implementation contact). Payroc's documentation describes no refund route without the card
  or a token, so where the merchant holds neither, finish the refund on iTransact while it still runs.
- **Follow-ons against iTransact transactions** (captures, voids, refunds of pre-cutover payments) can
  only run on iTransact. Finish them there, or plan the unreferenced-refund route.
- **Merchant settings** that change behaviour (duplicate rejection, which currency they process):
  check them in the iTransact account before cutover.
- **Payroc enablements.** Send your Payroc implementation contact the `CFG:` list from Step 2 now. A capability a row says
  must be enabled may not work at cutover until it is.
- **Running both in parallel.** The xmltrans2 signature covers the literal request text, so a proxy
  that re-serialises the XML during a dual-run period breaks it. Reconciliation spans two platforms
  for the overlap; flag it as work.

### Checkpoint

The developer has a dated plan covering stored cards, bank accounts, recurring schedules, history
export, in-flight follow-ons, merchant settings and any parallel-running period.

---

## Common failure modes

These are migration-specific. For Payroc API errors, use the error handling in the target task skill.

| What happens | Why | Fix |
| --- | --- | --- |
| Declined payments are recorded as paid | The port treats Payroc's HTTP 201 as approval | Read the result fields from the RESULT rows in `references/map-protocol-auth-and-results.md` |
| Amounts are out by 100× | A decimal-dollar amount sent to Payroc REST, or an integer sent to the Hosted Payment Page | See the amount rows in `references/identifier-translation.md` |
| Every payment returns 400 | No currency sent; no iTransact request carried one | Set the currency; check the iTransact account for the currency the merchant processes |
| A retry charges twice, or a declined card can't be retried | A new `Idempotency-Key` on a resend after a timeout, or the same key after a decline, which Payroc replays | Read the retry row in `references/map-protocol-auth-and-results.md` before writing retry logic |
| A card is charged twice after "try again" | The new attempt reused the declined attempt's `orderId`, so a lookup after a 5xx found the old decline and staff retried again | Give each deliberate attempt its own `orderId` as well as its own `Idempotency-Key` |
| A late "cancel" refunds money that iTransact would have refused to move | A refused reversal was turned into a refund, or the branch was chosen by trying the reversal first | Principle 4: read the payment's state first; a refund is a separate decision, for the remaining refundable amount |
| A postback receiver gets nothing, or can't parse what arrives | The receiver was re-pointed, not rewritten | Read `references/map-postbacks.md`; the payload and the trigger both change |
| A refund of an old sale fails | The `xid` was passed to a Payroc operation | Old transactions stay on iTransact; see the historical rows in `references/identifier-translation.md` |
| A capability is reported as lost that isn't | A `config` row read as a `none` row | See Step 5 |
| The developer is told to "check their account" about whether iTransact still runs something | A deployment question was treated as a setting | Principle 7: migrate the caller either way |
| A mapping was generated for a call not in any reference file | Principle 2 was skipped | Retract it, and ask for a request sample |

---

## Validation checklist

- [ ] Every iTransact call in the inventory was routed via the routing table or the URL table, not
      answered from the operation name
- [ ] Every mapping came from a reference file that was actually read, none inferred, none from memory
- [ ] Every `unverified` row was reported as unverified before any code was written from it
- [ ] Every `SEMANTIC:`, `LOSS:`, `SEQ:` and `CFG:` note was surfaced explicitly, not summarised away
- [ ] Every ` | ` branch row was implemented as a runtime branch with its `IF:` predicate
- [ ] Every `none` and `config` row was delivered with its alternative or escalation route
- [ ] `config` rows were not reported as lost capabilities
- [ ] Hedges kept at the row's strength: servlet provisional, Hosted Payment Page pairings inferred,
      deployment questions not established
- [ ] Auth code built from `references/identity-call.md`; no iTransact signing code in the Payroc path
- [ ] Response handling reads the result fields, not the HTTP status alone
- [ ] Identifier, amount and currency conversions read from `references/identifier-translation.md`
- [ ] Stored-card import started, and a fallback chosen (re-collection, or a planned pause in stored-card and recurring charges)
  for cards the import cannot be assumed to deliver before the switch-off
- [ ] History export and in-flight follow-ons planned before the switch-off
- [ ] Credentials for both platforms sourced from environment variables, never hardcoded
- [ ] Test API key used during testing (same `api.payroc.com` and `identity.payroc.com` hosts as
      production)

---

## Completion

Once the checklist passes:

> **Migration mapping complete.** Here's where you stand:
>
> - **Ports cleanly**: [list]
> - **Ports with a behaviour change**: [list, each with its change]
> - **No Payroc equivalent**: [list, each with its alternative or escalation]
> - **Configured rather than called**: [list]
> - **Unverified or unresolved**: [list, with what's needed to close each]
>
> **Before going live:** swap the test API key for a live one and point the terminal ID at the
> production terminal, confirm the card import has completed or the fallback is in place, and
> finish before iTransact switches off.

Offer next steps:

- **Implement the mapped calls**: hand off to the task skills listed in Step 6
- **Close the unresolved items**: most need the merchant's account configuration, which the Payroc
  implementation contact can confirm
- **Start the card import**: it has a lead time and is usually the critical path

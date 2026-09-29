# IBX → Payroc: identifiers, amounts, expiry, currency and result semantics

> **Local snapshot — authoritative for this skill.** The cross-cutting conversions every other
> mapping file in this skill depends on: what each IBX identifier becomes, and how amounts, card
> expiry, currency and result codes translate. Confidence badges follow the legend in
> [`_sources.md`](./_sources.md). Last synced: 2026-09-04. Read these conversions from here, not
> from field naming — several of them look obvious and are not.

```text
IN:  Cross-cutting facts cited by every other mapping file in this skill -- identifier
     translation (PNRef and every *Key), amount, expiry and currency format rules, result
     semantics, and the two Payroc capability-discovery mechanisms that are easy to conflate.
OUT: Per-operation rows -- the map-*.md files. This is a field reference, not a
     row-per-callable-unit mapping table; it exists to be cited, not grepped for a TransType.
ADJACENT: no-equivalent-register.md indexes every "no equivalent" and "configured, not
     called" verdict by IBX service. This file indexes the facts those verdicts and every
     other row depend on.
```

## Amount format

IBX documents `Amount` as `DDDDD.CC` on most surfaces. **Two questions here have different answers,
and merging them will cost you money in one direction or the other.**

**What the SOAP validator accepts.** Not `DDDDD.CC`. It applies exactly three checks:

1. exactly two characters after the decimal point,
2. digits only before the point,
3. a total length of no more than twelve characters.

There is **no five-integer-digit check**, and the SOAP field is a string. So a larger amount passes
that layer. **This matters for your intake: legacy rows above `99999.99` may well exist, and
validation built on the documented figure will reject legitimate data you have to migrate.**

**What you should send is a different question, and the answer is more conservative.** IBX's own REST
surface declares its card amount as a **single-precision float**, which cannot represent these values
exactly:

| Amount | becomes | error |
|---|---|---|
| `99999.99` | `99999.99` | none, once rounded back |
| `999999.99` | **`1000000.00`** | **a full cent, and a different amount** |
| larger | the next round number | a full cent |

**`99999.99` is the last amount that survives that round-trip cleanly — exactly the documented
ceiling.** So treat `99999.99` as a **recommended ceiling**, not as a debunked myth. The failure mode
above it on the REST path is **silent rounding, not an error**, which is the worse outcome: the
request succeeds and the amount is wrong.

**If you process amounts above `99999.99` today, raise it with your Payroc implementation contact
before you migrate** — ask what the real ceiling is, which layer imposes it, and whether an amount
above it is rejected, truncated or silently rounded. Do not settle it from the validator alone; that
is the loosest layer, not the binding one.

**What survives from the documented format:** the two-decimal guarantee *is* genuinely enforced, so
the conversion from major to minor units is exact, with no rounding ambiguity.

**Convert by ×100 only for two-decimal currencies.** Payroc's `order.amount` is in the currency's
lowest denomination, and its currency enum includes zero-decimal (`JPY`, `KRW`) and three-decimal
(`BHD`, `KWD`) entries. Because currency resolves from configuration rather than from your request
(see below), you cannot assume the terminal is two-decimal. Confirm it first, or the error is 100×.

**One edge case, hedged deliberately.** The two-decimal test measures the distance from the decimal
point to the end of the string, and a string with no decimal point at all appears to satisfy it — so
a bare two-character amount such as `50` may pass validation. What the processor then does with it is
not established. **Do not build on this in either direction**; it is recorded so that a parser
written on the assumption that every legacy amount contains a decimal point is not written blind.
[`unverified`]

**One documented exception.** `ProcessLoyaltyCard` specifically documents its amount as *"in decimal
format"* rather than `DDDDD.CC`. `ProcessGiftCard` does **not** share the exception — it explicitly
documents the standard format. Do not broaden the carve-out beyond loyalty.

## Card expiry

**`MMYY` on both platforms — no digit-pair conversion, in either direction.** Two further facts, both
load-bearing rather than cosmetic:

- **IBX's own runtime caps the expiry year at 39**, so a card expiring in 2040 or later cannot be
  represented in IBX at all. That is a legacy ceiling you may already be running into, not a Payroc
  constraint.
- **Payroc's `expiryDate` pattern is four digits and does not range-check the month.** `9999`
  validates against the schema and is only ever rejected by the issuer, if at all. **Range-check the
  month (01–12) yourself before sending a request** — this is not optional defensive coding, it is
  the only check that exists anywhere in the request path.

## Currency

`order.currency` is required by Payroc and **cannot come from any IBX request on any surface** — IBX
has no currency field anywhere. It resolves from processor or terminal configuration, or from a
question you have to ask. There is no field to read it from on the legacy side, ever.

## Result and status semantics

**Transport success is not approval, on either platform.**

- **IBX SOAP:** a zero result is not "money moved" for every operation. Several rows in this skill are
  tagged `SEMANTIC:` precisely because a zero there means only "accepted for later processing" — the
  `CaptureAll` fabricated queue response is the sharpest example.
- **IBX REST:** the transaction's own result code and result text are the only trustworthy signal.
- **Payroc:** a `200`/`201` confirms the request was well-formed, never that the transaction was
  approved. Branch on `transactionResult.status`.

**Branch on the domain-level result field, never on the transport-level status code, on either
platform.**

## Identifier reference table

Every distinct IBX key concept, what it identifies, and its Payroc counterpart or confirmed absence.
`PNRef` is only one of fourteen.

| IBX key | Type | Identifies | Payroc equivalent |
|---|---|---|---|
| `PNRef` | string | one processed transaction, stored only in **your** database, never IBX's | none directly — bridged via `order.orderId` on write (≤24 chars, uniqueness stated in prose only) and `listPayments?orderId=` / `getPayment` on read. Handle both zero matches and more than one |
| `CustomerKey` | int | a customer record | **none directly — but this is NOT "no customer equivalent".** The nearest identifier is `secureTokenId`, and the gap is precise: it identifies **a stored payment method, not a person.** A `customer` object is embedded in a secure token, which is a persistent, independently addressable resource with full CRUD — so customer data is stored, readable, updatable and deletable. **What has no counterpart is `CustomerKey` itself:** there is no customer id property anywhere, so one person with three stored payment methods becomes three unlinked records each holding its own copy of their details, and "fetch customer X" resolves only through fuzzy name, phone and email filters. A migration cannot translate `CustomerKey` to anything — it has to decide, per customer, which token carries the authoritative details |
| `ContractKey` | int | one recurring-billing enrollment | `subscriptionId` (`getSubscription`/`updateSubscription`/`deactivateSubscription`) — **a structural mismatch, not a rename.** IBX's contract is self-contained; Payroc splits a reusable `paymentPlan` template from a per-customer `subscription` enrollment |
| `CardInfoKey` / `CcInfoKey` (both spellings occur within SOAP — not a REST-vs-SOAP split) | int | a stored card in the **recurring family's own vault**, a separate storage system from the `cardsafe` vault | none directly — nearest is `listSecureTokens` filtered client-side; Payroc's vault has no customer-grouping field to filter by natively |
| `CheckInfoKey` | int | a stored bank account, same recurring vault as above | none directly — nearest is a bank-transfer-sourced secure token |
| `CardToken` | opaque string | a vaulted card in `cardsafe`'s own, **separate** vault | `paymentMethod.secureToken.token` — see dual-key storage below; the Payroc record has a *second* identifier you will also need |
| `CheckToken` | opaque string | vaulted check/ACH details, `cardsafe`'s vault | `paymentMethod.secureToken.token`, bank-transfer-sourced |
| `MerchantKey` | int | a merchant record | none for CRUD. `createMerchant` is an asynchronous, review-gated boarding application, not a synchronous create. **Note that the entire IBX `/merchants` write surface is deprecated and returns HTTP 500** — only the two reads work |
| `RegisterKey` | int | a register record | **no self-service CRUD exists on Payroc's side at all** — only boarding-time `createTerminalOrder` and a read-only `getProcessingTerminal` |
| `UserKey` | int | an API-user or credential record | **not a confirmed absence.** Whether Payroc has a counterpart for this concept is not established. Escalate rather than reporting it as lost |
| `BatchNumber` | string | a settled or settling batch | `batchId` (`GET /batches/{batchId}`) |
| `BatchID` / `BatchStatus` (on `ProcessBatch` specifically — **not the same concept as `BatchNumber`**) | string | nominally batch identity and status, but only one of the two is live | n/a for both. **`BatchID` genuinely is used** — folded into `ExtData` when non-blank. It is **`BatchStatus`** that is cleaned, normalized, and then never referenced again: the actual dead parameter. Do not treat `BatchID` as pointless |
| `SecureToken` (on `recurring.InfoContract` only — a **third**, distinct token concept) | string | an alternate lookup key for a contract, usable interchangeably with `CustomerKey` per the schema | unresolved — see dual-key storage note B below |
| `PaymentInfoKey` | int | the stored payment method inside a contract — likely the same value as `CardInfoKey`/`CheckInfoKey`, not independently confirmed | see the `CardInfoKey`/`CheckInfoKey` rows |
| `MerchantToken` | string | your own credential-lookup value — **not the same concept as `MerchantKey`**, despite the name | target undetermined; escalate. This is unresolved, not a confirmed absence |
| `ResellerKey` | int (implied, not schema-confirmed) | a reseller record | target undetermined; escalate. No ISV or partner-tier management API was found, but this is not settled |

**Do not conflate similarly-named keys.** `CardInfoKey` vs `CardToken`, `MerchantKey` vs
`MerchantToken`, and `BatchNumber` vs `BatchID` are each two genuinely different concepts that share a
root word. This table exists specifically because that confusion is easy to fall into.

## Dual-key storage

**A. On the Payroc side, a secure token carries two live identifiers for one record, serving two
different purposes.** The schema requires both `secureTokenId` (≤200 characters, gateway-generated
unless you supply one, used as the **path parameter** for retrieve, update and delete) and `token`
(12–19 digits with a Luhn check digit, described as the value the merchant uses in future transactions
to represent the customer's payment details). One addresses the resource; the other redeems it in a
payment call. **An IBX `CardToken` maps to the second of these** — but the Payroc record it becomes
also has a `secureTokenId` you will need for any subsequent read, update or delete. [`verified`]

**B. On the IBX side, a probable dual-key pattern that is not confirmed.**
`recurring.InfoContract` accepts either `SecureToken` **or** `CustomerKey` as alternative lookup keys
for the same call — a dual-key pattern by schema. **Whether both actually resolve to the identical
contract is not established**, and whether this `SecureToken` value-space has anything to do with
`cardsafe`'s `CardToken` is also unknown. Ask for a request sample rather than assuming either
reading. [`unverified`]

**C. A key hierarchy, which is a different pattern with a confusable name.**
`AddRecurringCreditCard` returns `CustomerKey`, `ContractKey`, `CcInfoKey`, `CheckInfoKey` and
`PNRef` together from one create call. That is a parent→child hierarchy (customer → contract → stored
payment method), **not** one object addressable two ways. Do not describe it as dual-key storage.

**Checked and ruled out:** IBX's batch has no second live identifier, and Payroc's batch object has
only `batchId`. The `cardsafe` vault and the recurring family's vault are confirmed **separate storage
systems**, not one object reachable two ways — the recurring vault stores raw card number and
expiration with no token field at all.

## `supportedOperations[]` and the boarding-time `features` object

**Two different Payroc mechanisms that are easy to conflate, and only one is a capability list.**

**`supportedOperations[]` is a per-transaction state-machine gate, not a merchant- or terminal-level
capability flag**, despite the name inviting that reading. It is a nine-member enum — `capture`,
`refund`, `fullyReverse`, `partiallyReverse`, `incrementAuthorization`, `adjustTip`, `addSignature`,
`setAsReady`, `setAsPending` — returned inside individual payment and refund **response bodies**. The
intended use, which Payroc's own published workflows follow: read a specific payment's *current*
`supportedOperations`, and only attempt a follow-on call if the matching token is present in **that
transaction's own** array. It answers "has this payment already been captured, partially reversed or
tip-adjusted?", not "is this merchant entitled to capture?".

One behavioural note, deliberately hedged: Payroc's documentation on `processAsSale` says only that
the merchant cannot adjust a transaction that is settled immediately — general non-adjustability,
not a claim about any single token. The safer reading is that `processAsSale: true` likely removes
**all** adjustment-family tokens, not just one. **Do not assume the others survive.** [`inferred`]

**IBX has no equivalent field on any surface.** Every IBX response type in this mapping was checked
and none carries an operations-list field of any kind. The nearest candidate,
`transact.GetInfo{TransType=Setup}`, returns feature-enablement flags only in demo mode; the real
response is opaque and defined by the upstream processor.

**A genuinely separate mechanism exists at boarding time, and it is the better match for "what can
this terminal do".** A boarded processing terminal carries a `features` object — `tips`,
`enhancedProcessing`, `ebt`, `pinDebitCashback`, `recurringPayments`, `paymentLinks` and others. That
is a terminal-wide entitlement set fixed at boarding, not a per-transaction state token. **No IBX-side
equivalent exists for this either** — IBX's capability configuration lives in its merchant and
register administration surfaces, mapped in `map-merchant-admin.md` and
`map-batch-and-settlement.md`.

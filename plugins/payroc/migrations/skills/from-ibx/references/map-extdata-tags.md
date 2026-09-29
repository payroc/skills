# IBX → Payroc: the ten undocumented `ExtData` tags

> **Local snapshot — authoritative for this skill.** Payroc's own mapping for the ten `ExtData`
> tags that IBX's runtime accepts and **no IBX document describes.** Per-row confidence is in the
> `C` column; the legend is in [`_sources.md`](./_sources.md). Last synced: 2026-09-24.
>
> **Why this file exists.** If your code puts one of these tags in `ExtData`, IBX acts on it and
> no IBX documentation told you it would. Four of them change how a transaction is authorised.
> **You will not find these by reading IBX's integration guide** — grep your own request-building
> code for each tag name below.

```text
IN:  The ten undocumented ExtData tags -- QuasiCash, CashAdvance, Presentation,
     CVMResult, QPS, EstimatedAmount, ChipConditionCode, AppInfo, Healthcare_Amount,
     SkipVoidBackup. One row each.
OUT: The documented ExtData tags stay with their operation's file --
     map-card-transactions.md for credit, map-debit-and-ebt.md for debit and EBT,
     map-check-cash-and-stored-value.md for check, cash and stored value. Amounts,
     identifiers and formats are identifier-translation.md.
ADJACENT: no-equivalent-register.md indexes the "no equivalent" verdicts, including the
     six below. If a tag in your ExtData is not in this file and not in your operation's
     file, see the completeness warning directly below -- it is NOT evidence the tag does
     nothing.
```

**Where to implement what you find here:** `run-a-card-sale` and `run-a-pre-authorization` for
the rows with a Payroc target. The `none` rows need a conversation with your implementation
contact, not code.

---

## Before you use this file: no list of `ExtData` tags can be complete

IBX does not reject a tag it does not recognise. It forwards recognised tags individually and
wraps everything else into a single element that it **also** forwards to the processor. So your
integration may be sending tags that appear in no IBX artefact at all, and it works.

**Three consequences for your migration:**

- **A tag missing from every table in this skill is not a tag that does nothing.** It is a tag
  this skill cannot account for. Bring it to your implementation contact.
- **Start from a real request, not from documentation.** Capture an actual `ExtData` payload from
  production traffic and work through it tag by tag.
- **IBX's published tag list is frozen.** The descriptions in its WSDLs are rendered from source
  strings whose changelog stops in 2010, so everything added since is undocumented by
  construction. The ten below are the consequence.

## And two versions of the IBX gateway differ on what they accept

Which tags the credit-card path recognises **is not the same across IBX deployments.** One
version accepts 37 tags; a later one accepts 44, adding seven more and changing how one of them
is matched. Three of these differences are visible to you:

- **`AppInfo` is recognised on one version and not on the other**, because of a defect in how the
  later version's list is written — two tag names were put into a single entry. **Your data is
  not discarded when this happens.** IBX forwards an unrecognised tag to the processor under a
  generic key rather than dropping it, so what changes is the key the processor sees, not whether
  the value travels. **Do not tell the developer IBX drops `AppInfo`.**
- **`SkipVoidBackup` is accepted on the credit-card path on the later version only.**
- **Seven further tags exist on the later version alone** and are not mapped anywhere in
  this skill. If your `ExtData` contains a tag not in this skill, that is one place it may come
  from.

**So: ask your Payroc implementation contact which version serves your merchant before you rely
on any row below that mentions the difference.** Do not assume the newer one.

---

## The tags

` → ` means sequence, ` | ` means branch — see `SKILL.md` Principle 4. Payroc property paths are
on the payment request unless a row says otherwise.

| IBX tag | V | What it does on IBX | Payroc target | Behaviour change | C |
|---|---|---|---|---|---|
| `Presentation` | partial | `<Presentation><CardPresent>True\|False\|Unknown</CardPresent></Presentation>`. On one TSYS path, **anything other than `True` moves a would-be card-present retail transaction onto the card-not-present code path** — card-present is the default assumption and this tag is the override. On another processor path it is validated against the merchant's MOTO/ecommerce profile and the transaction is **rejected** as an invalid card-present flag when the two disagree | `channel` (`pos` \| `web` \| `moto`, **required**) **and** `paymentMethod.cardDetails.entryMethod` (**required**) | `SEMANTIC:` **one optional tag becomes two required fields, and there is no boolean.** IBX's `Unknown` has nowhere to go — Payroc makes you choose. `LOSS:` **the reroute behaviour has no equivalent.** On Payroc the channel is a declaration about the transaction, not a switch that moves it between processing paths, so an integration using `CardPresent=False` to *force* card-not-present handling is relying on something Payroc does not offer. **The request and response enums are not the same set:** you may send `raw`, `icc`, `keyed` or `swiped`; responses may also return `swipedFallback`, `contactlessIcc` or `contactlessMsr`, **so three values you can receive are not values you can send.** Do not reach for `downgradeTo` as the equivalent — that is offline reprocessing | verified (the IBX behaviour and the Payroc fields and enums) / unverified (how a contactless tap is expressed on a request — the spec does not say, so confirm it rather than assuming) |
| `Healthcare_Amount` | partial | A **general** medical sub-amount, separate from the five documented `*_Amount` tags, mapped to the processor's total-medical field. **It overwrites `QHP_Amount` when you send both.** One processor family only | `order.healthcareExpenses[]`, an array of `{type, amount}` | `SEMANTIC:` **an aggregate becomes an itemised array, and your aggregate has no category.** Payroc's `type` is one of `copay`, `clinic`, `dental`, `prescription`, `transit`, `vision` — so `RX_Amount` → `prescription`, `Vision_Amount` → `vision`, `Dental_Amount` → `dental`, `Clinical_Amount` → `clinic`, **and neither `QHP_Amount` nor `Healthcare_Amount` has a member, because both are subtotals rather than kinds of expense.** Decide per merchant how to itemise them; do not invent a category. `copay` and `transit` are capability you gain. **`amount` is an integer in the currency's minor units**, against IBX's decimal string, and **a zero amount cannot be sent at all.** The overwrite rule disappears — Payroc's array has no precedence, so reconcile overlapping IBX amounts before you build the request or you will double-count | verified (the IBX behaviour, and the Payroc schema and enum) |
| `ChipConditionCode` | partial | The EMV fallback service code — the chip read failed and the card was swiped. **Only one of IBX's TSYS paths consults it**; the legacy path hardcodes the value and ignores your tag. In practice only sent by card-present POS integrations doing real EMV fallback | `paymentMethod.cardDetails.swipedData.fallback` (boolean) and `.fallbackReason` (`technical` \| `repeatFallback` \| `emptyCandidateList`) | `SEMANTIC:` **these fields are on the swiped card-data variants only** — not on `cardDetails` itself — so they are unavailable when you send `icc`, `keyed` or `raw` data. Neither is required. `LOSS:` **`fallbackReason` does not come back.** No response carries it; the response collapses the whole thing to the single `entryMethod` value `swipedFallback` with no reason. **If you reconcile or report on fallback reasons today, that data stops being returned** — store it yourself at request time | verified (the IBX behaviour, and the Payroc fields and enum) |
| `AppInfo` | partial | **Nothing reads it.** No processor path and no terminal-data handler consumes it; it is accepted so it can be echoed back, and on one IBX version even the echo is broken by a defect in the tag list. It is the one tag here whose intended purpose cannot be reconstructed | `customFields[]`, an array of `{name, value}` — present on both the request and the payment response, so it round-trips | `SEMANTIC:` **this is not a free-text passthrough, and a direct port loses your data without telling you.** Every custom field must be **provisioned before use**: Payroc activates the feature for your account, then you create the field in the Self Care Portal, and **`name` must match that entry exactly, including case.** On a mismatch **the payment still succeeds and your field is silently dropped from both the request and the response.** `LOSS:` `value` is a string of at most **255 characters** and `name` at most 56, so check your real `AppInfo` payloads for length and for non-string values. **And check this before you use it: a custom field can be configured to act as a dynamic descriptor, which puts its value on the cardholder's statement.** A field that was echo-only on IBX can become cardholder-visible through configuration alone | verified (the IBX behaviour, and the Payroc schema, limits and provisioning requirement) |
| `EstimatedAmount` | none | Sets the Visa and Mastercard **estimated-authorization indicator** — for restaurants, hotels and fuel, where the final amount differs from what was authorised. A manual override for cases IBX's automatic tip and pre-auth detection misses | `—` | **No equivalent, and the thing that looks like one is not one.** Payroc's documented route for a final amount that differs from the authorised amount is a pre-authorization: send the payment with `autoCapture` and `processAsSale` both `false`, optionally adjust the amount upward, then capture. **That covers the workflow and sets no scheme-level indicator**, so the authorisation gets none of the estimated-authorization treatment the card networks give it. `LOSS:` say this precisely — you keep the workflow and lose the indicator. **Two traps on the replacement:** pre-authorization must be **enabled on the account**, and **if it is not, Payroc runs your attempt as a sale with a pending status rather than rejecting it** — so the missing capability fails silently in the direction of taking money. Confirm enablement before you port. **Escalate:** ask whether the indicator can be set by terminal configuration | verified (the IBX behaviour; and the absence on Payroc, swept several ways including the full API reference) |
| `CVMResult` | none | A **fallback carrier for EMV tag 9F34**, the cardholder verification method results. IBX prefers 9F34 from the terminal and uses this tag only when the terminal did not send it, feeding the processor's cardholder-authentication fields. It is part of the standard terminal-data set, so genuine POS integrations are expected to send it alongside EMV data | `—` for the field itself; raw EMV data only, via `paymentMethod.cardDetails.iccData` | **Payroc has no cardholder-verification-method field, on requests or responses.** EMV data is accepted on a request only as an **opaque Tag-Length-Value hex blob**. `LOSS:` **there is no second channel for 9F34.** The structured per-tag form exists only on responses, so **if your terminal omits 9F34 from the TLV, you cannot supply it separately the way you can today.** The fix is at the terminal: make it emit 9F34 inside the EMV data. Raise this with your terminal vendor before cutover, not after | verified (the IBX behaviour; and that Payroc's structured EMV-tag form is response-only, traced through every reference to it) |
| `QPS` | none | TSYS's **Quick Payment Service** — a cardholder-verification exemption for small, fast transactions. When set, and the transaction is not quasi-cash, installment or wallet, it forces the cardholder authentication method to *"not authenticated"* | `—` | **No CVM-exemption mechanism, and no way to force the cardholder authentication method.** `LOSS:` you lose an explicit per-transaction exemption. The only related Payroc behaviour is the contactless CVM limit, which is **terminal behaviour with no API control.** **This is the row most likely to be `config` rather than `none`:** ask your implementation contact whether the equivalent exemption is terminal configuration, because that is where Payroc's own documentation puts CVM limits. Do not tell the developer it is simply gone until that is answered | verified (the IBX behaviour; and the absence of any API-level exemption, swept under eight phrasings) |
| `QuasiCash` | none | The cash-equivalent special-condition code — casino chips, money orders, wire transfers. Sets a special-condition indicator and a cardholder-id override on two TSYS paths. **On one processor it is dead: the handler hardcodes quasi-cash to false whatever you send.** Reads as a specialty-MCC feature | `—` | **No equivalent. Payroc has no transaction-category or special-condition request field at all.** `LOSS:` genuine, and it is an account-level conversation rather than a code change, because quasi-cash handling follows the merchant category. **Two fields you will find while searching and must not mistake for this:** the boarding `transactionTypes` enum is **ACH SEC codes**, not transaction categories; and the `pickUpCard` and `referToCardIssuer` special-condition values are **response statuses**, not request indicators. **Escalate to your implementation contact** | verified (the IBX behaviour including the dead processor path; and the absence across the whole Payroc API reference) |
| `CashAdvance` | none | **It is parsed and then nothing reads it.** An exhaustive search of IBX's processor libraries found no consumer; a dated comment puts it at 2006, so the downstream logic it fed was removed at some point and the tag stayed. **Do not confuse it with** a same-named enum in one processor library, which is an unrelated transaction type | `—` | **No equivalent — and none is needed, because the tag has no effect on IBX either.** `LOSS:` **none. Do not register this as a lost capability.** If your code sends `CashAdvance`, the honest answer is that it does nothing today and will do nothing after the migration; delete it. **Three Payroc fields that are different things:** `order.breakdown.cashbackAmount` and the terminal's PIN-debit cashback feature are **PIN-debit cashback**; the EBT `cashWithdrawal` type is **EBT-specific**. None is a cash advance | verified (that Payroc has none, including the full terminal-feature list) / inferred (that the IBX tag has no effect — it rests on an exhaustive search for a consumer, which is a strong negative but still a negative) |
| `SkipVoidBackup` | none | **An internal guard, not a customer feature.** IBX sets it on itself to stop its own void-and-reversal chain recursing, and it disables the gateway's automatic compensating-void behaviour. On one IBX version it is also accepted from a caller on the credit-card path; on the other it is not | `—` | **No equivalent, and none should be sought** — Payroc exposes no control over its own internal retry or compensation behaviour. `SCOPE:` **if your code sends this tag, that is itself the finding.** It means you were suppressing a gateway safety net, and what depended on that needs establishing before cutover. **Escalate it; do not map it and do not simply drop it.** One limit to respect when you do: **this skill cannot tell you what IBX does when a reversal fails** — that behaviour was not confirmed, so do not build a migration plan on an assumption about it | verified (that IBX sets this tag itself, on both versions) / unverified (what the compensating-void behaviour actually does) / unverified (whether any integration sends it directly) |

---

## Which of these are actually sent

Useful for scoping, and it is **evidence that a tag is used, not a count of how often.** It comes
from historical documentation and test suites, not from traffic.

| | Tags | Why |
| --- | --- | --- |
| **Strong evidence of real use** | `Presentation` · `QPS` · `CVMResult` | Documented in IBX's own older documentation, and present in realistic terminal-data test suites |
| **Real but niche** | `QuasiCash` · `EstimatedAmount` · `Healthcare_Amount` · `ChipConditionCode` | Processor support plus a specific merchant segment — specialty MCCs, hospitality and fuel, healthcare merchants, EMV-capable POS |
| **Mostly internal to IBX** | `SkipVoidBackup` | See its row |
| **No evidence of any effect** | `CashAdvance` · `AppInfo` | No consumer found anywhere. If your code sends either, expect to delete rather than port it |

**Scope this from your own code, not from this table.** A tag in the bottom row may still be in
your payload, and a tag in no row at all may be too.

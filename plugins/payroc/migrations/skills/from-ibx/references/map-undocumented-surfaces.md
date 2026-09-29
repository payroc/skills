# IBX → Payroc: undocumented and unspecced surfaces — hosted pages, `Epic`, `PayWS`/`CryptoWS`, `USAePay`, `TestForms`

> **Local snapshot — authoritative for this skill.** Payroc's own mapping from the IBX surfaces that
> no IBX specification describes — `hostedpagesvc`, `/ws/hosted2`, `Epic.aspx`, `PayWS`/`CryptoWS`,
> `USAePay.asmx` and the `TestForms` pages — to the Payroc API. Per-row confidence is carried in the
> `C` column; the legend is in [`_sources.md`](./_sources.md). Last synced: 2026-09-14. Read mappings
> from this file, not from memory — and read the exception below before reading the table, because
> most of these rows ask you a question rather than answering one.

```text
IN:  SOAP hostedpagesvc.asmx (CreateSession); FORM /ws/hosted2; FORM /vt/ws/Epic.aspx; SOAP
     PayWS.asmx and CryptoWS.asmx; SOAP USAePay.asmx; FORM /ws/TestForms/* and
     /vt/ws/testforms/*.
OUT: the cardsafe and transact payment, token and vaulting operations that several of these
     surfaces forward into internally -- map-card-transactions.md,
     map-check-cash-and-stored-value.md, map-tokens-and-vault.md, map-token-payments.md.
ADJACENT: identifier-translation.md holds the cross-cutting identifier, amount, expiry and
     currency facts, for the few rows below that have enough of a real schema to need them.
     If your call is not in the table below, it is not absent from IBX -- check the sibling
     files above, then SKILL.md's routing table, then ask for a request sample.
```

**Where to implement what you find here:** `integrate-hosted-payment-pages` and
`integrate-payment-links` for a hosted checkout page, `integrate-hosted-fields` and
`create-single-use-token` for the session-token half, and `run-a-card-sale`,
`run-a-pre-authorization` and `refund-a-card-payment` for the `USAePay` proxy rows, whose real
targets are the ordinary card operations. This file owns the delta; those skills own the request
schema.

## Read this before the table: the action on most of these rows is *enumerate*, not *map*

**This file uses a declared exception to the row format the rest of the skill follows.** Every other file keys its rows
`<PROTO> <SERVICE>.<OPERATION>`. Some surfaces here have **no enumerable operation list** —
nothing published describes them, and in one case (`sessionPay.aspx`) the page itself could not be
examined — so their key takes a placeholder form instead: `FORM hosted2.? {op=unknown}`.

**`SOAP CryptoWS.?` and `FORM Epic.?` are exceptions of a different kind: their operations *are*
known.** `CryptoWS`'s row describes the surface as a capability rather than operation by operation
because it is not a payments surface at all, so there is nothing to map field by field. `Epic`
**is** a payments surface, and its row says how many transaction types its handler accepts without
listing them — so if you are on it, ask the developer which ones they send. This skill has no mapping for them. See both rows.

**A placeholder row is not a "no equivalent" verdict and must not be read as one.** It means the
operation list cannot be produced from what describes IBX. So the action on those rows is to
**enumerate**: ask the developer what they actually call — the exact path, the operation or command
name, and one real request and response. This skill has no mapping for it. Do not let this skill guess a sub-operation for a
row whose key is a `?`.

**Why the hosted-page service and the hosted checkout page are filed together.** `hostedpagesvc`'s
`CreateSession` has no operation documentation, and `/ws/hosted2` appears in no specification at all.
**If you run a hosted page, you cannot tell from the outside which of the two you are on** — that
is why they share a file. This is a filing choice about what you can distinguish,
**not** a claim that the two are halves of one flow — see the cross-cutting facts below, where that
specific pairing is ruled out.

**On the order of the rows.** It is **not a traffic ranking — do not size your migration on it.** Take the
volumes from your own logs: only your integration knows which of these surfaces it actually calls,
and the ordering here will not tell you.

## Cross-cutting facts

Stated once here; see `identifier-translation.md` for the full detail.

- **`hosted2` is not `CreateSession`'s render half.** The two look like two halves of one flow and are
  not: the page carries no reference to the session GUID, to `CreateSession`, to `PayMethod` or to
  `ResponseUrl`, and it authenticates with a raw `MerchantKey`/`Username`/`Password` triple instead.
  The word *"Session"* on that page is ASP.NET session state — an unrelated concept with the same
  name. **The likely consumer of `CreateSession`'s GUID is `sessionPay.aspx`, whose contents are not
  known** — so if your integration mints a session and then redeems it, say which page redeems it.
- **A security fact you need to act on, not just note: `/ws/hosted2` accepts `Username` and `Password`
  as query-string parameters.** Credentials in a URL are credentials in every proxy, browser history
  and access log between you and the gateway. **Treat any credential you have used against this
  surface as disclosed and rotate it, and do not carry the pattern across:** Payroc takes its
  credentials in headers and body, never in a query string.
- **`PayWS`'s two operations do not share an implementation.** `XMLPayRequest` and `XMLPayments`
  dispatch into two genuinely different processors. Do not reason from one to the other, and do not
  assume a behaviour observed on one holds on the other.
- **Do not connect `PayWS` to the XMLPay DTD comment in the `transact` service.** That comment
  concerns `transact`'s own internal marshalling and reads identically whether or not `PayWS` exists;
  one legacy service exposing an XMLPay-shaped surface is not evidence that the two are related.
- **A `PayWS` customer sends a raw XMLPay document, not a parameter list.** None of this skill's
  parameter-level rows apply to them. That is a different mapping shape entirely — escalation and a
  redesign conversation, not a field-by-field table.
- **`USAePay.asmx` genuinely mirrors the third-party USAePay gateway's own public SOAP contract** —
  same namespace, same operation signatures — and its implemented operations delegate straight into
  IBX's own credit-card and check processing, the same processing mapped in
  `map-card-transactions.md` and `map-check-cash-and-stored-value.md`. **But it is a thin veneer, not
  a working drop-in replacement.** The service declares roughly 88 overridable operations and **81 of
  them throw not-implemented**, and those 81 are not exposed on the SOAP surface at all — so a client
  generated from USAePay's own contract gets **7 of about 88 operations**, and those seven return
  partly canned response data. If anyone is live on this, they are live on a narrow subset.
- **Whether anyone *is* live on `USAePay` is unconfirmed, and the absence of any mention of it in
  IBX's own documentation does not settle it.** The absence is real; the inference from it is not.
  IBX separately documents a **generic, user-configurable gateway-emulator mechanism**, enabled by a
  reseller-level flag — and a configured emulator is database configuration that would leave no
  documentary trace however many live customers used it. (This purpose-built `USAePay` service is
  *not* an instance of that configurable mechanism — the two are different things, and the point here
  is only that silence in the documentation is near-uninformative about usage.) Escalate the liveness
  question rather than concluding either way.
- **`TestForms` is an internal developer test harness, confirmed against IBX's own description of it:**
  pages that call a web method in-process, bypassing the SOAP layer entirely. It is reachable in
  production but is not a customer-facing contract. Out of scope to map — but if your own integration
  calls it, say so, because it does not exercise the contract your production traffic uses.

## Rows

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP hostedpagesvc.CreateSession` | config | `createSession` (`POST /processing-terminals/{id}/hosted-fields-sessions`) — the same operation `map-tokens-and-vault.md` cites for `TokenMode=jstoken`, but **not a verbatim reuse.** That file's use of it is specifically the *tokenization* scenario; a full hosted-checkout flow may need the *payment* scenario instead, or both, depending on how the merchant configures the page. Treat this as the same underlying Payroc feature, not a confirmed identical call. | `TransType`, `PayMethod`, `Amount`, `InvNum`, `PNRef`, `Zip`, `Street`, `ExtData`, `ResponseUrl` — a full transaction-intent bundle bound to a session, against a Payroc session token that **configures a widget rather than pre-declaring the transaction** | `SEMANTIC:` this operation's entire job is minting a session GUID and persisting it against the request bundle; the GUID comes back in `RespMSG`. **The consumer that redeems that GUID is not established** (see the cross-cutting facts). `CFG:` the migrating unit here is a *configured page* — branding, custom fields, receipt templates, callback URL — not a field-by-field request mapping. Raise the page configuration with your Payroc implementation contact rather than expecting to port it as a request. | verified (the IBX mechanism — interface and handler agree) / inferred (the Payroc pairing; the `scenario` value is unconfirmed) |
| `FORM hosted2.? {op=unknown}` | config/partial | same target family as `CreateSession` above | n/a — **no enumerable field list.** What the page's own controls imply is billing and shipping address, custom fields, a donation amount, and an ACH-versus-card selection; that is an observation about the page, not a schema | `SEMANTIC:` this is a full 133 KB WebForms checkout page — third-party UI controls, ReCaptcha, templated email receipts — **not a thin API call.** Porting it is a page-rebuild conversation, not a request remap. Confirmed **not** `CreateSession`'s render half, and it accepts credentials as query-string parameters — both in the cross-cutting facts above. **Ask the developer for the exact URL they post to and one real form post**, because the operation list cannot be derived from anything that describes IBX. | verified (the page's content and structure) / inferred (the path-to-page mapping, and the Payroc pairing) |
| `FORM Epic.?` | none (target undetermined — escalate) | `—` | n/a | A healthcare-billing (Epic EHR) integration surface, reached by an HTTP form post rather than SOAP — there is no WSDL and there never was one, so do not go looking for one. **No machine-readable IBX interface description covers it:** it is absent from IBX's REST API document, its published Swagger, every one of its service definitions and its operation inventory. **A vendor-held interface specification does exist** — Epic-authored, referenced in IBX's own internal documentation — but this skill does not draw on it, and **asking IBX for it is the shortest route to a complete picture of this surface.** Its request handler **has** been read: it accepts **eight transaction-type values, dispatching to five handler routines.** The values are known to Payroc and are not listed here. On the Payroc side, no healthcare-vertical capability was found, but treat that as unsettled rather than as a confirmed gap, and raise it with your Payroc implementation contact. If you are on this surface, send the requests you actually make — **knowing what the handler accepts is not knowing what you send**, and the mapping still needs that. | verified (the transaction types the handler accepts) / unverified (whether the surface is live, who integrates with it, and the Payroc target) |
| `SOAP PayWS.XMLPayRequest` | none | `—` — **if you post XMLPay documents here, your migration is a different piece of work from the rest of this guide** and none of its field-level mappings apply to a document-shaped integration. Ask your Payroc implementation contact whether this endpoint is still live for your account and what your migration path is; it is not covered by the published IBX documentation, so Payroc will need to confirm it is in scope for you | n/a — a raw XMLPay document in, a document out; there is no parameter list to map | Delegates into one XMLPay document processor. Provenance is inherited 2001–2008 third-party gateway code. **IBX's own platform team reports `payws` as not in use or deployed** — so **if your code calls this endpoint, that discrepancy is itself the finding and needs escalating before anything else in your migration.** Either you are calling something you believe is `payws` and it is not, or a service the platform team considers retired is serving your traffic; both change your plan. Escalate: if you send XMLPay documents, we need a sample document, not a field list. **This statement covers `payws` only — not `CryptoWS` and not `PayXml.aspx`**, which are a separate service and a separate entry point and have no such statement. | verified (the signature and its delegation target) / verified (liveness — IBX's own platform team reports this service as not in use or deployed; no probe was run) |
| `SOAP PayWS.XMLPayments` | none | `—` — **same as `XMLPayRequest` above**: a document-shaped integration that the field-level mappings in this guide do not cover. Ask your Payroc implementation contact whether it is still live for your account and what your migration path is — and **say which of the two XMLPay methods you call**, because they run through different processors internally, so an answer about one is not an answer about the other | n/a — the same document-shaped call, a different processor | Delegates into a **genuinely different** processor from `XMLPayRequest` above. Do not carry a finding from one operation to the other. Same liveness caveat. | verified (the signature and its delegation target) / verified (liveness — IBX's own platform team reports this service as not in use or deployed; no probe was run) |
| `SOAP CryptoWS.?` | none | `—` — **reimplement it in your own application code.** This is not a payments capability and the Payroc API has no equivalent by design | n/a | `SCOPE:` a general-purpose symmetric encode/decode utility sitting alongside `PayWS` — four operations, an encode and a decode over each of two text encodings, with the key supplied by the caller on every call. **It is not a transaction surface**, so nothing about it maps onto a Payroc payments operation and no Payroc operation is the "right" target for it. **Two things to do rather than map it.** Move the encoding and decoding into your own application using a maintained cryptographic library, and treat anything you have protected with it as needing re-protection under that library rather than re-encoded as-is. Then tell your Payroc implementation contact that you call this surface, so its retirement can be sequenced with your migration. | verified (the operations and what they do) / unverified (whether the surface is still live) |
| `SOAP PayXml.? {op=unknown}` | none | `—` — **same document-shaped migration as `PayWS` above, and it needs its own answer.** Ask your Payroc implementation contact whether this entry point is live for your account and what replaces it, and **send one real request you post to it** — its behaviour has not been distinguished from `PayWS.XMLPayRequest`'s, so an answer about `PayWS` does not automatically cover it | n/a | A live, **distinct** entry point into the same XMLPay document-handling processor that `PayWS.XMLPayRequest` reaches — a second door into the same code. **Do not assume it behaves identically to `PayWS.XMLPayRequest`.** | unverified (existence and processor target only; not distinguished from `PayWS`) |
| `SOAP USAePay.runSale` | absorbed (best-supported reading — see the caveat) | same target as `ProcessCreditCard {TransType=Sale}` / `ProcessCheck {TransType=Sale}` — see `map-card-transactions.md` and `map-check-cash-and-stored-value.md` | n/a — this operation translates a USAePay-shaped request into a call against IBX's own payment processing before any Payroc-side question arises | `SCOPE:` a genuine USAePay-shaped compatibility surface, **not a hard `none`** — if it is live, its target is the *same* `payment` operation family already mapped elsewhere, reached through a different legacy contract. It uses a hardcoded decline-code table and hardcoded AVS/CVV text remapping: **the approval-or-decline outcome is live pass-through from the real processor, but the human-readable text is synthesised from static lookup tables, not passed through.** So do not port response-text matching. Liveness is unconfirmed — escalate that before relying on this mapping. | verified (the delegation target) / unverified (liveness; and whether this verdict should be `none` instead) |
| `SOAP USAePay.runAuthOnly` | absorbed — same caveat as `runSale` | same as `ProcessCreditCard {TransType=Auth}` | n/a | The same proxy shape, sending `TransType="Auth"`. | verified (the delegation) / unverified (liveness) |
| `SOAP USAePay.runCredit` | absorbed — same caveat | same as `ProcessCreditCard {TransType=Return}` | n/a | The same proxy shape, sending `TransType="Return"`. | verified (the delegation) / unverified (liveness) |
| `SOAP USAePay.captureTransaction` | absorbed — same caveat | same as `ProcessCreditCard {TransType=Force}` | n/a | The same proxy shape, and **note that it sends `TransType="Force"`, not `"Capture"`, despite the method name.** Map it to the `Force` row, not the `Capture` one. | verified (the delegation) / unverified (liveness) |
| `SOAP USAePay.refundTransaction` | absorbed — same caveat | same as `ProcessCreditCard {TransType=Return}` | n/a | The same proxy, sending `TransType="Return"`, plus extra response post-processing: it blanks several fields and pads the approval code. The response you see is not the processor's response verbatim. | verified (the delegation) / unverified (liveness) |
| `SOAP USAePay.voidTransaction` | absorbed — same caveat | same as `ProcessCreditCard {TransType=Void}` | n/a | The same proxy, sending `TransType="Void"`, returning a boolean derived from a zero result code. | verified (the delegation) / unverified (liveness) |
| `SOAP USAePay.runTransaction` | absorbed — same caveat | dispatches to **five of the six** rows above, per `Command` | n/a | **Mostly a dispatcher** — it switches on `Command` and calls the matching operation above, so map through to whichever row the command selects. **Two cases are not clean pass-throughs.** `VOID` calls `voidTransaction`, which returns only a boolean, and synthesises the response around it — an approval, or a decline carrying a fixed error string and code — so the response you get for `VOID` here is not the one the `voidTransaction` row describes. And `CAPTURE` forwards only the reference number and the amount, not your whole request object, so a request that omits the transaction-detail block faults rather than returning a clean error. **`refundTransaction` is not reachable at all** — no `Command` value selects it. `Command=CREDIT` reaches `runCredit`, which sends the same underlying `Return` and forwards your reference number, so the *effect* is largely reachable even though the method is not — **but do not treat `CREDIT` as a drop-in for it.** `runCredit` post-processes its response too, and differently: it overwrites the approval code unconditionally, where `refundTransaction` only fills one in when the processor returned none. **The five values accepted are `SALE`, `CREDIT`, `VOID`, `AUTHONLY` and `CAPTURE`** — but these are IBX's own comparison labels, not a value set published by USAePay. IBX upper-cases whatever you send before comparing, so the casing you send does not matter — and the upper-case forms shown here are not evidence that USAePay publishes them in upper case. It does **not** trim, so a `Command` with stray whitespace is rejected rather than matched, and any other non-empty value is rejected outright. **If the developer calls this operation, ask for the exact `Command` strings they send** — that is the only thing that establishes their set. | verified (the dispatch logic) / unverified (liveness; whether the five match USAePay's published set) |
| `FORM TestForms.? {op=unknown}` | none | `—` | n/a | An internal developer test harness, confirmed against IBX's own description of it: pages that call a web method in-process, **bypassing the SOAP layer entirely** — so a request made here does not exercise the contract your production integration uses. **One caveat to keep:** that "one page per web method" is stated of a single named example only, and is not confirmed to cover every web method on every service. Reachable in production, but not a customer-facing contract. Treat it as an undocumented bypass of the intended contract rather than a surface to map — and if your integration calls it today, raise that with your Payroc implementation contact, because it will not have a like-for-like replacement. | verified (the characterisation of the pattern; full coverage not confirmed) |
| `sessionPay.aspx` (no operation list) | none (target undetermined — **an open surface, not a confirmed absence**) | `—` — **ask your Payroc implementation contact which page currently serves your hosted payment flow and what replaces it.** This skill has no description of this page, so it cannot tell you what it does or what it maps to, and says so rather than guessing. **Read this as "not yet known", not as "you have lost this."** | n/a | Named as the likely consumer of `hostedpagesvc.CreateSession`'s session GUID. If your hosted-page flow redeems a session GUID, this is the row to raise — it is the shortest route to settling how `CreateSession` completes. | unverified (the entire surface) |

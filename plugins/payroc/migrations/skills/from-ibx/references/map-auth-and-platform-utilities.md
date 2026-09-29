# IBX → Payroc: authentication, card validation, BIN lookup, health and platform utilities

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> IBX's supporting services — `validate`, `bininfo`, `health`, `transact.GetInfo`, and REST `/auth` —
> to the Payroc API. Per-row confidence is carried in the `C` column; the legend is in
> [`_sources.md`](./_sources.md). Last synced: 2026-09-04. Read mappings from this file, not from
> memory — several of these operations have no Payroc counterpart at all, and guessing one is worse
> than reporting the gap.
>
> **How far a badge in this file goes.** For the `validate`, `bininfo` and `health` SOAP services the
> mapping rests on their declared interfaces only, with no confirmation of what the implementations
> actually do — so those rows are `inferred`, and that reflects a limit on the evidence rather than a
> judgement about each operation individually.
>
> **No Payroc pairing anywhere in this file is `verified`.** Some rows carry a split badge whose first
> half reads `verified`; in every case that half is about **IBX's own behaviour**, and the Payroc half
> beside it is `inferred` or `unverified`. Read the halves separately — a `verified` here never means
> the target has been confirmed.

```text
IN:  SOAP /ws/validate.asmx (all 7 operations), /ws/bininfo.asmx, /vt/ws/health.asmx, and
     transact.asmx's GetInfo operation only. REST /auth, /auth/{provider},
     /bininfo/cardinfo.
OUT: transact.asmx's ProcessCreditCard / ProcessSignature / EmailReceipt --
     map-card-transactions.md. ProcessBatch, and the target for GetInfo{BatchInquiry}'s
     batch reads -- map-batch-and-settlement.md. A third, unrouted BIN-lookup surface is
     deliberately NOT mapped here -- see cross-cutting facts.
ADJACENT: identifier-translation.md holds the cross-cutting identifier, amount, expiry and
     currency facts, and the two Payroc capability-discovery mechanisms the Setup row below
     touches. map-merchant-admin.md holds the merchant, register and API-user administration
     surfaces that several rows below point at. If your call is not in the table below, it is
     not absent from IBX -- check the sibling files above, then SKILL.md's routing table,
     then ask for a request sample.
```

**Where to implement what you find here:** `look-up-card-details` for anything that resolves to a BIN
lookup, `order-a-terminal` and `add-processing-account` for terminal and register provisioning. This
file owns the delta; those skills own the request schema.

**Authentication is the one delta a reader will come here for.** IBX authenticates
per call: SOAP operations carry `UserName`/`Password` in the request body, and REST `/auth` exchanges
the same credentials for a bearer token on the gateway itself. **Payroc authenticates with a Bearer
token obtained from a separate identity service, not from the payments API.** That is an architectural
difference, not a documentation gap: no token-issuing operation exists anywhere in the payments API,
because token issuance is not part of it. Every task skill documents how to obtain and present that
token for the call it covers — **do not build a Payroc auth flow from this file.** It records what
changes, not how Payroc auth works.

## Cross-cutting facts

See `identifier-translation.md` for the cross-cutting identifier, amount, expiry and currency detail
the rows below lean on.

- **`validate.asmx`'s four card-format checks (`ValidCard`, `ValidCardLength`, `ValidExpDate`,
  `ValidMod10`) are stateless, credential-free client-side validation utilities** — Luhn, length and
  expiry-format checks with no processor round-trip. Six of the service's seven operations take no
  `UserName`/`Password` at all. **The honest Payroc-side answer for all four is "do this client-side;
  Payroc does not need to be asked."** This is not a capability gap. It is a redundant round-trip IBX
  offered as a convenience, and your client should be performing these checks against the Payroc
  request schema's own constraints regardless.
- **A third, unrouted BIN-lookup surface exists and is deliberately not mapped here.** Separately from
  `bininfo.asmx` (`UserName`/`Password`/`CardNum`/`Amount`, form-encoded) and REST `/bininfo/cardinfo`
  (`CardNumber`/`Amount` query parameters, Bearer auth), there is a batch-capable JSON API at
  `GET {BinInfoServerUrl}Api/BinInfo[/{binNumber}]`, returning `{Dtl,Dt,Entries:[{Num,Dtl,Dt,Vbs}]}` on
  its own server variable. It is not one of the sixteen SOAP services and not a REST tag, and its
  naming suggests a separate internal tool rather than a customer-facing gateway surface — but that is
  not settled. **If your integration calls it, say so and escalate rather than assuming either
  `bininfo` row below covers it.**
- **`transact.GetInfo`'s runtime-accepted token set is six, not the five its published interface
  declares.** The dispatch accepts `Initialize`, `Setup`, `BatchInquiry`, `StatusCheck` and
  `KeyChangeRequest`, plus `MerchantToken`, which an earlier short-circuit handles before the main
  dispatch is reached. **`KeyChangeRequest` appears in no published IBX documentation of any kind** —
  it exists only in the running dispatch. If you are inventorying `GetInfo` traffic from documentation,
  you will miss it.
- **A canned `GetInfo` response is not evidence of live behaviour.** For `Setup`, `BatchInquiry` and
  `StatusCheck`, IBX returns a fixed demo response **only in training mode** — `UserName` and
  `Password` both set to `DEMO`, or the training-mode flag set in `ExtData`. For a real merchant the
  response comes from an opaque upstream processor host and is never constructed by IBX at all. Every
  row below marks this distinction rather than presenting demo values as confirmed live behaviour.
  **Do not size a migration on a demo response body.**
- **`MerchantToken` never touches the processing host.** It is a pure database lookup returning the
  authenticated caller's own merchant token — a credential/identifier-lookup operation, not a payment
  or host-forwarding one.
- **No customer-facing Payroc health or status endpoint is documented.** You can check that claim
  yourself: no health, status or liveness operation appears anywhere in Payroc's public
  documentation, which is consistent with liveness being handled at infrastructure level rather than
  exposed as a customer API operation. **But no Payroc source states outright that no such endpoint
  exists** — this is an absence from the documentation, not a statement in it. Treat it as grounded but not
  positively documented, and do not round it up to "confirmed absent."

## `validate.asmx`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP validate.ValidCard` | config | `—` (do this client-side — see cross-cutting facts) | n/a | `CFG:` Luhn + length + expiry check, no processor round-trip. Result codes `1001`–`1006` map to distinct client-side checks a modern SDK should perform before ever calling Payroc. | inferred (interface schema only — no runtime confirmation) |
| `SOAP validate.ValidCardLength` | config — same as above | `—` | n/a | Length check only, a subset of `ValidCard`. | inferred (interface schema only) |
| `SOAP validate.ValidExpDate` | config — same | `—` | n/a | Validity plus not-expired check. **Reuse `identifier-translation.md`'s `MMYY` month range-check requirement rather than treating this as a separate capability** — Payroc's four-digit expiry pattern does not range-check the month, so that check has to live in your client either way. | inferred (interface schema only) |
| `SOAP validate.ValidMod10` | config — same | `—` | n/a | Luhn check only, a subset of `ValidCard`. | inferred (interface schema only) |
| `SOAP validate.GetCardType` | absorbed | `getBinInformation` (`GET /bin-information/{binNumber}`) | — | Payroc's BIN response includes `issuingNetwork` among 29 required fields — a richer read than a bare brand string, not a narrower one. | inferred (interface schema only) |
| `SOAP validate.IsCommercialCard` | absorbed | `getBinInformation` | — | Best-guess field: `cardClass` or `accountFundSourceSubType` — **not confirmed which, if either, encodes "commercial" specifically. Escalate before asserting an exact field.** | unverified |
| `SOAP validate.GetNetworkID` | none (Payroc target undetermined — escalate) | `—` | n/a | The only operation on this service requiring credentials. Debit-network routing is normally an internal processor decision, and Payroc's BIN-information operations expose no network-code lookup — but whether any other Payroc surface does is not established, so this is not a confirmed absence. | unverified |

## `bininfo.asmx` and REST `/bininfo/cardinfo`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP bininfo.GetCardInfo` | absorbed | `getBinInformation` | **`Amount` has no Payroc equivalent.** It is IBX's own surcharge-calculation parameter; Payroc's BIN lookup takes only a `binNumber`, never an amount. If you compute a surcharge from this response today, that calculation has to move into your own code. | The request shape is confirmed by a real exercised request; the response shape is not — treat the field list as the declared schema, not as observed output. | inferred (the request shape is confirmed; the response shape is schema-only) |
| `REST GET /bininfo/cardinfo {CardNumber,Amount}` | absorbed — same target as the SOAP row above | `getBinInformation` | Same `Amount`-has-no-target caveat. | `Bearer` security is declared on this operation, unlike several IBX REST operations mapped in other files, which declare none. | unverified (no runtime confirmation of either side) |

## `health.asmx`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP health.Check {Username,Password}` | none (Payroc target undetermined — see caveat) | `—` — **if you poll this today to gate traffic or drive a dashboard, plan to drop the poll rather than repoint it.** Ask your Payroc implementation contact how you should be notified of planned maintenance and of an unplanned outage, and whether Payroc publishes a status page you can subscribe to | n/a | `CFG:` no customer-facing Payroc health or status endpoint is documented — see cross-cutting facts for the shape of that absence, which is grounded in the whole of Payroc's public documentation rather than in a positive statement. If you monitor IBX liveness through this call today, that monitoring has no API-level replacement and needs a different design. | unverified |

## `transact.asmx` — `GetInfo`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact.GetInfo {TransType=MerchantToken}` | none (Payroc target undetermined — escalate) | `—` | n/a | A pure database lookup of the caller's own merchant token; never forwarded to a host. **`MerchantToken` is not the same concept as `MerchantKey` despite the name** — see `identifier-translation.md`. **This is unresolved, not a confirmed absence.** It is related to, but distinct from, the API-user and credential-management gap in `map-merchant-admin.md`: that finding concerns CRUD over user accounts, this is a merchant-identifier lookup, and whether Payroc has an equivalent of *this* concept is not established. Do not report it as covered there, and do not report it as lost. | verified (the IBX behaviour) / unverified (the Payroc target — not searched, so undetermined rather than absent) |
| `SOAP transact.GetInfo {TransType=Setup}` | partial | `getProcessingTerminalHostConfiguration` (**conceptual match only** — both read a merchant or terminal's host-processor configuration; no field-by-field comparison has been performed) | — | `SEMANTIC:` the card-brand and feature-enablement flags this call is known for appear **in demo mode only.** The real, non-demo response is opaque and defined entirely by the upstream processor host. **It has never been confirmed to carry anything resembling Payroc's capability concepts** — neither the per-transaction `supportedOperations[]` array nor the boarding-time `features` object described in `identifier-translation.md`. Do not treat this operation as IBX's answer to either one. | inferred (conceptual pairing; the demo response is not live evidence) |
| `SOAP transact.GetInfo {TransType=BatchInquiry}` | absorbed | `getbatches`/`getbatch` — see `map-batch-and-settlement.md` | — | `SEMANTIC:` the per-tender-type open-batch totals (credit and debit sale, return, net amounts and counts) are the **demo-mode** response. | inferred |
| `SOAP transact.GetInfo {TransType=StatusCheck}` | none (Payroc target undetermined — escalate) | `—` | n/a | A connectivity/liveness ping authenticated on the transact channel with merchant credentials — **distinct from `health.asmx`'s system-level ping**, and the two are not interchangeable. The demo-mode response is a bare `ExtData="OK"`; real behaviour is undetermined. No Payroc target is established. | inferred (the demo response) / unverified (the Payroc target) |
| `SOAP transact.GetInfo {TransType=Initialize}` | none (Payroc target undetermined — escalate) | `—` | n/a | A register/terminal host-provisioning action: it initializes the register with the host, and IBX documents it as supported only for TSYS SGMF. **IBX genuinely sends a real request for this token** — the live, non-demo path constructs actual outbound XML for it. It is only the training-mode stand-in that has no case for it and falls through to "Transaction not supported". **What is undetermined is what the upstream host does with that request, not whether one is sent.** On the Payroc side this is the same structural gap `map-merchant-admin.md` records for register write operations: the processing-terminal family has no self-service create or update, only boarding-time `createTerminalOrder`. | verified (the live dispatch builds a real request; the demo-path fallthrough is a separate code path) / unverified (the real host behaviour, and the Payroc target) |
| `SOAP transact.GetInfo {TransType=KeyChangeRequest}` | none (Payroc target undetermined — escalate) | `—` | n/a | **Undocumented anywhere publicly** — it exists only in the running dispatch (see cross-cutting facts). The name suggests a working-key or encryption-key rotation request to the host. As with `Initialize`, the live non-demo path builds a genuine outbound request and only the demo stand-in lacks a case for it, so the upstream host's response is what is undetermined, not whether a request is sent. Same absence of self-service provisioning on the Payroc side. | verified (the token is runtime-accepted and builds a real request) / unverified (the real host behaviour, and the Payroc target) |

### `transact2` delta

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP transact2.GetInfo {TransType=Initialize,Setup,BatchInquiry,MerchantToken,StatusCheck,KeyChangeRequest}` | direct — the same objects running the same code | Same target as the corresponding `GetInfo` row above, for every token listed | Endpoint only: `/ws/transact2.asmx`. | — | inferred (`GetInfo` is among `transact2`'s confirmed operations; the forwarding itself is not independently confirmed) |

## REST `/auth`, `/auth/{provider}`

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `REST POST /auth {UserName,Password}` | config | Payroc's separate identity service (`POST https://identity.payroc.com/authorize`, `x-api-key` header) — **not part of the payments API at all** | Credential exchange for a bearer token: the same general shape, an entirely different mechanism. IBX takes a username and password in a body posted to the gateway itself; Payroc gates a separate service with an `x-api-key`. **Do not build the Payroc side from this row** — the task skill for the call you are making documents the token flow it needs. | In practice this operation is a login step that immediately precedes other REST calls in every flow that uses it. It returns `200` with a bearer token on success, `400` when only a username is supplied, and `401` for any other invalid-credential case. | verified (the IBX behaviour) / inferred (the Payroc-side pairing — same purpose, different mechanism) |
| `REST GET/PUT/POST/DELETE /auth/{provider}` | none — **likely framework infrastructure rather than an IBX business capability**, the same shape as the `/current-requests` finding in `map-rest-transactions.md` | `—` | n/a | `SEMANTIC:` the `Authenticate`/`AuthenticateResponse` schema fields (`oauth_token`, `oauth_verifier`, `qop`/`nc`/`cnonce`, `RememberMe`, `AccessTokenSecret`, `ProfileUrl`) match ServiceStack's own built-in multi-provider auth DTOs closely enough to suggest framework scaffolding rather than a designed IBX operation. **This reading is a pattern match on those field names and is not confirmed** — no provider configuration for it is known. Treat it as a hypothesis, and escalate if your integration genuinely depends on this path. | unverified |

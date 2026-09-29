# IBX → Payroc: recurring billing (SOAP) — `recurring.asmx`

> **Local snapshot — authoritative for this skill.** Payroc's own operation-by-operation mapping from
> the IBX `recurring` SOAP service to the Payroc API, covering all thirteen of its operations.
> Per-row confidence is carried in the `C` column; the legend is in [`_sources.md`](./_sources.md).
> Last synced: 2026-09-10. Read mappings from this file, not from memory — a plausible-sounding
> mapping that isn't here will look correct in review and fail in production.

```text
IN:  SOAP /vt/ws/recurring.asmx -- all 13 operations.
OUT: REST /customers, /contracts, /recurringtransactions -- map-recurring-rest.md, the
     richer and better-evidenced sibling surface for this same capability. Go there
     first for field-level detail.
     order.standingInstructions / mitAgreement (a per-payment MIT flag, NOT a persistent
     contract) -- map-card-transactions.md and map-debit-and-ebt.md.
ADJACENT: identifier-translation.md holds cross-cutting identifier, amount, expiry and
     currency facts. map-tokens-and-vault.md holds the secure-token surface several rows
     below hand off to. If your call is not in the table below, it is not absent from IBX
     -- check map-recurring-rest.md, then SKILL.md's routing table, then ask for a
     request sample.
```

**Read this before you read the table. This service's own definition documents almost nothing.**
It carries two identical service-level sentences — *"This Web Service provides methods that can
manage recurring billing"* — and **zero per-operation documentation**. There is no observed request
against it. That is why most rows below are `unverified` on the Payroc side and why several targets
are named only as a best guess. Treat each row as the starting point of a conversation with your
implementation contact, not as a mapping you can build from unreviewed. The one thing that would
change this file most is a captured request — ask for one.

**What IS established is how the four `Manage*` operations behave**, and it is more important than
the mapping: their `TransType` vocabulary is fixed, but `UPDATE` and `DELETE` mean different things
on different operations, in ways that destroy data if you assume they are uniform. Those rows carry
a split confidence badge — the IBX behaviour is confirmed, the Payroc pairing is not.

**Where to implement what you find here:** `set-up-a-payment-plan` and `manage-subscriptions` for the
contract and billing rows, `save-a-payment-method` for the secure-token and customer rows. This file
owns the delta; those skills own the request schema. For the field-level work on the same capability,
see `map-recurring-rest.md` — the rows below name the Payroc `operationId` and stop rather than
duplicating it.

## Cross-cutting facts

Stated once here; see `identifier-translation.md` for the full detail.

- **`Vendor` appears on exactly 9 of the 13 operations** — `AddRecurringCreditCard`,
  `AddRecurringCheck`, `ProcessCheck`, `ProcessCreditCard`, `ManageCheckInfo`,
  `ManageCreditCardInfo`, `ManageContractAddDaysToNextBillDt`, `ManageContract`, `ManageCustomer`.
  No other IBX SOAP service covered by this skill carries the field at all.
- **`GetContractExpiration` alone spells the credential field `UserName`, with a capital N.** The
  other twelve operations spell it `Username`. A client that binds the credential field once, by
  name, for the whole service will fail on exactly this one operation.
- **`TransType` takes `ADD`, `UPDATE` or `DELETE` — and nothing else.** On all four `Manage*`
  operations (`ManageCheckInfo`, `ManageCreditCardInfo`, `ManageContract`, `ManageCustomer`) IBX
  trims and upper-cases the value before dispatching, so casing and surrounding whitespace do not
  matter, and any other value is rejected as an unsupported transaction type. **Do not generalise
  that tolerance:** `Status`, on the same operations, is matched case-sensitively.

  Two edges worth knowing before you test this. **Omitting `TransType` entirely is not the same as
  sending a bad one** — it produces an internal error rather than a clean "invalid transaction type".
  And on `ManageContract` a bad `TransType` usually surfaces as a date-parsing or argument error
  instead, because other validation runs first. **You cannot reliably probe the accepted set from
  the outside; the values above are the set.**

- **`UPDATE` replaces the record on three of the four operations. It does not patch.** Send the
  complete current record on every update, or you will erase whatever you left out.

  | Operation | What `UPDATE` does |
  |---|---|
  | `ManageCustomer` | Full replace. Omitted fields are written away |
  | `ManageContract` | Full replace, except the bills-to-date counters |
  | `ManageCheckInfo` | Full replace, including the whole address — **and IBX's own documentation does not warn about this one.** Two fields are the exception, and not in your favour: see below |
  | `ManageCreditCardInfo` | **A true merge** — only the fields you supply are changed. Do not carry the warning above onto this operation |

  **On `ManageContract`, the numeric and boolean fields do not blank — they take defaults, which is
  worse than blanking.** Omitted amounts, retry counts and billing intervals become `0`; all four
  notification flags become `false`; and an omitted payment type severs the contract from its
  payment method. The date fields are the safe case: omit them and the call fails outright.

  On `ManageCreditCardInfo`, an expiry date that isn't numeric is **silently ignored** — the stored
  expiry is left as it was and you get no error. Validate expiry before you send it.

  **On `ManageCheckInfo`, `MICR` and `RawMICR` are the two stored check fields `UPDATE` will not
  take from you.** They are accepted and then discarded: the MICR column is not touched at all, and
  the raw-MICR column is rewritten with the value already in the record rather than the one you
  sent. You get no error either way. So these two are the one place the full-replace warning above
  does not apply — and the failure runs the other way. **You cannot correct a wrong MICR line
  through `UPDATE`.**

  **If a wrong MICR is blocking you, do not rebuild the payment method before asking.** Neither of
  the two routes open to you is established. The expensive one is to add a new stored payment method
  and re-point whatever refers to the old one — and **even that is not confirmed to leave you with a
  correct stored MICR**, because `ADD` sends both fields to storage but what storage does with them
  is not established. The cheap one is a REST update IBX publishes against the same stored record,
  `PUT /customers/{customerKey}/recurringpaymentmethods/checks/{checkInfoKey}`, whose declared
  request body carries a `micr` — see `map-recurring-rest.md`, which maps that endpoint family and
  carries its own warning about the declared request shape on it. **Whether that route writes a MICR
  is not established, and a `200` from it would not establish it either**, because its
  declared success response simply hands the check data back. **Take both routes to your Payroc
  implementation contact and get an answer before you pay for a rebuild.**

- **Omitting `Status` on an `UPDATE` reactivates a closed record. This is the one most likely to
  cost a merchant money.** `Status` is optional and undocumented on both `ManageCustomer` and
  `ManageContract`, and leaving it out defaults it to active — so a routine field update against a
  cancelled contract silently resumes billing. **Always send `Status` explicitly on an update.**

- **`DELETE` does not delete, on two of the four operations.** On `ManageCustomer` and
  `ManageContract` it is a reversible status close: the record is marked closed and stays. On
  `ManageCheckInfo` and `ManageCreditCardInfo` it genuinely removes the stored payment method.
  **This is why `ManageCustomer`'s row below does not pair `DELETE` with Payroc's
  `deleteSecureToken`** — Payroc would remove the record IBX only closes. If your migration relies
  on being able to reverse a deletion, that behaviour does not carry over.

  **Check what your own code sends before you migrate:** on the two payment-method operations, a
  `DELETE` with an empty key is not rejected — it removes **every** stored payment method for that
  customer and then returns an error with an empty message, so a caller can see a failure after the
  records are already gone. If your integration has ever sent that, your stored data may not be
  what you expect.

  **Have a real request sample to hand before relying on any answer about how these four operations
  behave, including this file's.**

- **`LOSS:` IBX's retry policy is configured on this surface and has no Payroc equivalent.**
  `MaxFailures`, `FailureInterval` and `FailurePeriod` ride on `AddRecurringCreditCard`,
  `AddRecurringCheck` and `ManageContract`. On IBX, a contract that hits `MaxFailures` **stops and
  blocks behind the failed payment** rather than moving on to the next due date. Payroc has no
  failure, retry or dunning field on subscriptions or payment plans at all, so this policy has to be
  rebuilt in your own code or dropped deliberately — **decide which, and tell the merchant.** Payroc's
  `suspended` subscription status is not a substitute: it is read-only and carries no threshold.
  See `map-recurring-rest.md` for the surface-by-surface detail, including the fact that IBX's own
  two surfaces disagree about the default.
- **The customer entity: the loss is shape, not persistence. Do not state it as "Payroc has no
  customer equivalent", and do not overcorrect to "Payroc has customers".** Customer data on Payroc
  *is* persistent, addressable and full-CRUD: a `customer` object is embedded in a secure token,
  which is an independently addressable resource with create, list, read, update and delete, and
  `updateSecureToken` explicitly covers updating the customer's contact and address details. What is
  missing is the **shape**: customer identity is keyed by *payment instrument*. One secure token
  holds one customer's one payment method with their details copied into it, so there is no parent
  record to hang several payment methods, several subscriptions or a transaction history from; two
  tokens for the same person duplicate their details with no link between the copies. There is no
  `/customers` collection and no customer id property anywhere, so "fetch customer X" and "all
  subscriptions for customer X" resolve only through fuzzy `customerName`, `phone` and `email`
  filters, which may return zero matches or many. **State the loss as: no customer-keyed grouping and
  no id-based customer lookup.**
- **A legacy customer with no stored payment method has no Payroc target record at all.** The
  tokenization request requires a payment method, and the customer object is optional on it — so
  there is no customer-only create. Escalate those records rather than inventing a placeholder
  payment method for them.
- **The Payroc target family for everything below is Repeat Payments** — payment plans and
  subscriptions.

## Rows

| IBX call | V | Payroc target | Request delta | Behaviour change | C |
|---|---|---|---|---|---|
| `SOAP recurring.InfoCustomer` | partial | `getSecureToken` (`GET /secure-tokens/{secureTokenId}`) — reads the `customer` object embedded in the token; `listSecureTokens` filtered by `customerName`/`phone`/`email` where the token id is not known | Read by `secureTokenId`, which is merchant-supplied, not by a customer key. There is no customer id to look up — see `LOSS:`. | `LOSS:` a readable, persistent customer record does exist; what does not exist is **customer-keyed retrieval**. You can read *a* customer's details from a known token, but you cannot fetch a customer by identity, nor get one record covering a customer who has several stored payment methods — each token holds its own unlinked copy. Where the caller has only a name, phone or email, the fuzzy `listSecureTokens` filters are the only route and may return zero matches or many. | inferred (the pairing is a structural read: `getSecureToken` and the embedded `customer` object are confirmed on the Payroc side; whether it is an adequate substitute for this specific IBX operation is not confirmed end to end) |
| `SOAP recurring.InfoContract` | absorbed | `getSubscription` | — | No per-operation documentation exists for this service, so this pairing is a name-level match, not one confirmed against a real IBX field list beyond the bare element names in the service definition. | unverified |
| `SOAP recurring.AddRecurringCreditCard` | absorbed | `createSubscription` (card-based) | 43 IBX request fields against the Payroc subscription request — not field-mapped here; see `map-recurring-rest.md` for the field-level work on the equivalent REST surface | — | unverified |
| `SOAP recurring.AddRecurringCheck` | absorbed (target undetermined, with real uncertainty — see the caveat) | `createSubscription` (check-based, **unconfirmed**) | 50 IBX request fields, not field-mapped here | Whether the Payroc subscription request's `paymentMethod` supports a bank-transfer-sourced secure token **at all** is not established. **Do not assert that check-based recurring billing is achievable on Payroc without confirming this first.** | unverified |
| `SOAP recurring.ProcessCheck` | absorbed | `paySubscription` | — | A one-off charge against a stored recurring check profile — **distinct from the raw `ProcessCheck` in `map-check-cash-and-stored-value.md` and the `cardsafe` `ProcessCheck` in `map-token-payments.md`.** Same operation name, third meaning. Key every reference with the full service name. | unverified |
| `SOAP recurring.ProcessCreditCard` | absorbed | `paySubscription` | — | Same naming caution as `ProcessCheck` above — this is IBX's **third** `ProcessCreditCard`, after `transact` (`map-card-transactions.md`) and `cardsafe` (`map-token-payments.md`). | unverified |
| `SOAP recurring.GetContractExpiration` | partial | `listSubscriptions`, using the `endDate`/`nextDueDate` filter parameters | **This is the one operation that spells the credential field `UserName`** — see cross-cutting facts. | `LOSS:` a plausible partial substitute, not a confirmed equivalent report — Payroc has no dedicated expiry-report operation. | unverified |
| `SOAP recurring.ManageCheckInfo` | absorbed (target undetermined; UPDATE/DELETE not uniform — escalate) | `updateSubscription` (best guess) | `TransType` is `ADD`, `UPDATE` or `DELETE` — see cross-cutting facts | `SEMANTIC:` **`UPDATE` is a full replace, and this is the operation IBX's own documentation fails to warn about.** Every field of the stored check profile, address included, is overwritten with what you send; omit one and it is erased. **`MICR` and `RawMICR` are the exception, and they fail the other way — `UPDATE` accepts them and discards them, so a wrong MICR line cannot be corrected through this operation. See the cross-cutting facts above.** `DELETE` genuinely removes the stored payment method — and with an empty key it removes them all. `SCOPE:` which Payroc operation a given call reaches still cannot be stated without a request sample. | verified (IBX behaviour) / unverified (the Payroc pairing) |
| `SOAP recurring.ManageCreditCardInfo` | absorbed (target undetermined; UPDATE/DELETE not uniform — escalate) | `updateSubscription` (best guess) | `TransType` is `ADD`, `UPDATE` or `DELETE` | `SEMANTIC:` **The one operation whose `UPDATE` is a genuine merge** — only the fields you supply change, so the full-replace warning on the other three does not apply here. A non-numeric expiry date is silently ignored rather than rejected, leaving the stored value unchanged. `DELETE` removes the stored payment method, and with an empty key removes them all. `SCOPE:` as `ManageCheckInfo`. | verified (IBX behaviour) / unverified (the Payroc pairing) |
| `SOAP recurring.ManageContractAddDaysToNextBillDt` | none (target undetermined — escalate rather than reporting the day-shift as available) | `—` | n/a | `LOSS:` `updateSubscription`'s own documentation explicitly forbids patching `currentState`, which is where `nextDueDate` lives, and `pauseCollectionFor` operates in billing-cycle units, not days. **No confirmed Payroc mechanism shifts a next-bill date by a day count.** This is a real, specific gap rather than a guessed one — take it to your implementation contact. | unverified (the absence is checked against `updateSubscription`'s own stated exclusions) |
| `SOAP recurring.GetCustomerPaymentMethods` | partial | `listSecureTokens` (`GET /secure-tokens`) filtered by `customerName`/`phone`/`email` — see `map-tokens-and-vault.md` | Filter by customer *string*, not by customer id. | `LOSS:` **this is the row where the structural gap bites hardest.** The operation's whole purpose is *customer-grouped* payment methods, and grouping is exactly what Payroc's shape does not provide: each secure token is an independent record holding its own copy of the customer's details, with no parent identity linking them. "All payment methods for this customer" is reconstructible only by string-matching `customerName`/`phone`/`email` and trusting the match, with real false-positive and false-negative risk for common names or inconsistently entered data. The route exists; it is not identity-based. This is also the only operation on this service with no `ExtData` field. | inferred (`listSecureTokens` and its customer filters are confirmed on the Payroc side; whether string-grouping is an acceptable substitute for this operation is a judgement, not a confirmed equivalence) |
| `SOAP recurring.ManageContract` | absorbed (target undetermined; UPDATE/DELETE not uniform — escalate) | `createSubscription` / `updateSubscription` / `deactivateSubscription` / `reactivateSubscription` (best guess — likely a single CRUD dispatcher over this whole family) | `TransType` is `ADD`, `UPDATE` or `DELETE`. `FailurePeriod` accepts only `DAY` | `SEMANTIC:` **`UPDATE` is a full replace** apart from the bills-to-date counters, and the non-text fields default rather than blank: omitted amounts, retry counts and billing intervals become `0`, all four notification flags become `false`, and an omitted payment type severs the contract from its payment method. `IF:` **the payment type accepts only upper-case `CC` and `CK`** — lower-case `cc` or `ck` is rejected outright with *"Invalid PaymentType, expecting CC or CK"*, though surrounding whitespace is trimmed and tolerated. **The same check is what lets an omitted value through**: it only runs when the field is non-empty, which is why omitting the payment type severs the contract instead of failing the call. The check runs before the operation branches on `TransType`, so if your existing code normalises this field to lower case anywhere it will error on **every call, `DELETE` included**. Omitted dates fail the call instead, which is the safe case. **Omitting `Status` reactivates a closed contract.** `DELETE` is a reversible status close, not a deletion. `IF:` `FailurePeriod` rejects `WEEK`, `MONTH` and `YEAR` outright, while an empty **or unrecognised** value is silently accepted as `DAY` — so the values that look valid are the only ones that error. `FailureInterval` is silently clamped to 1–28 rather than rejected. `SCOPE:` which Payroc operation a given call reaches still cannot be stated without a request sample. | verified (IBX behaviour) / unverified (the Payroc pairing) |
| `SOAP recurring.ManageCustomer` | partial | `createSecureToken` / `updateSecureToken` / `deleteSecureToken` — the customer's details are managed as the `customer` object embedded in the token | Customer create, update and delete are performed **per stored payment method**, addressed by `secureTokenId`, not by a customer key. A legacy customer with no stored payment method has no target record at all — see cross-cutting facts. | `SEMANTIC:` **usually one of the highest-volume calls in a recurring-billing integration, so plan this one first.** **Customer management is not lost**: create, update and delete all exist, and `updateSecureToken` explicitly covers the customer's contact and address details. `LOSS:` what is lost is the *customer as a unit of management*. Because the details live inside each token, a customer with three stored payment methods has three copies to maintain with nothing linking them — one address change becomes three `updateSecureToken` calls the caller must locate itself, and deleting "the customer" means deleting each token in turn. There is no `/customers` collection and no customer id property. **Treat this as a remodelling task, not a capability loss.** **`UPDATE` is a full replace — send the customer's complete current record or you will erase the fields you left out, and omitting `Status` will reactivate a customer you had closed.** **`DELETE` is a reversible status close, not a deletion**, which makes the pairing with `deleteSecureToken` a known semantic mismatch rather than a guess: Payroc removes what IBX only closes. Establish which verbs your own code actually sends before you map it. | verified (the Payroc-side create, update and delete operations and the embedded `customer` object; and the IBX-side dispatch, full-replace update, status default and soft delete) / unverified (whether per-token customer management is workable at your call volume — a question for your implementation contact, not one this file can answer) |

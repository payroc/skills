# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime.
To refresh a file, re-fetch its source, regenerate it, then update the "Last synced" date here
and in the file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (boarding paths `POST`/`GET /merchant-platforms/{merchantPlatformId}/processing-accounts`, `GET /processing-accounts/{processingAccountId}` + `/pricing`,`/owners`,`/contacts`,`/funding-accounts`, `POST /processing-accounts/{processingAccountId}/reminders`; schemas `createProcessingAccount`, `processingAccount`, `paginatedProcessingAccounts`, `owner`, `ownerRelationship`, `identifier`, `processing`, `createFunding`, `fundingAccount`, `paymentMethods`, `pricing`, `signature`, `contactMethod`, `address`, `createReminder` request/response) | 2026-06-18 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly. The
processing-account schemas are entirely Payroc-owned, so this skill has no
`third-party-derived` references.

## Notes on divergence from the spec / sibling skills

- **Funding payment methods are nested under `value`.** The spec's `paymentMethods` is a
  discriminated array: `{ "type": "ach", "value": { "routingNumber", "accountNumber" } }`. The
  generated SDKs (which back the green UAT functional-test rating for create/retrieve/list)
  use this shape. The older `create-merchant-platform/references/api-schema.md` documents the
  bank numbers **flat** on the payment method; that reference predates this check and should be
  reconciled. `api-schema.md` here follows the spec.
- **Reminders is a `POST` that re-sends the signing email**, not a GET list. The roadmap entry
  ([knowledge/skill-build-order-and-grouping.md](../../../../../knowledge/skill-build-order-and-grouping.md))
  abbreviated it as "reminders"; the real operation is Create Reminder
  (`POST /processing-accounts/{id}/reminders`, body `{ "type": "pricingAgreement" }`) and only
  applies when `signature.type` was `requestedViaEmail`.
- **Processing-account owners are immutable.** `PUT`/`DELETE /owners/{ownerId}` reject
  processing-account owners (they work only for funding-recipient owners). No owner
  update/delete is in scope.

## Live correction (carried from create-pricing-intent, re-verified 2026-06-16)

The OpenAPI `ErrorsItems` schema documents only `message` on each `errors[]` item, but the live
API returns `parameter` + `detail` + `message` (and a top-level `instance`). Verified by
`POST`ing an empty body to boarding endpoints on UAT. The error-schema section of
`api-schema.md` reflects the live shape, not the spec.

## Live corrections (verified 2026-06-19, UAT — end-to-end run)

Found while live-testing the full chain against UAT (pricing intent → merchant platform →
processing account; test-repo PR #25). The references/SKILL guidance was corrected to match:

- **An owner cannot be both control prong and authorized signatory.** Earlier guidance said one
  owner could hold both; UAT rejects it (*"it must be one or the other or neither"*). At least two
  owners are required — one control prong, a different authorized signatory. The ownership rules
  and worked examples now reflect this.
- **`website` is required when `processing.volumeBreakdown.ecommerce > 0`.** UAT rejects the
  account without it (*"Website must be a valid address when Ecommerce volume is greater than
  zero"*), even though `website` is otherwise optional.
- **IDs are opaque integers in UAT** (`merchantPlatformId` `9815`, `processingAccountId`
  `287019`), not the `PA-XXXX`/`MP-XXXX` forms shown in examples.
- **`processing.ach` shape** (verified by posting account `287022`): uses `naics` (not `naicsCode`)
  and requires `estimatedMonthlyTransactions`, `previouslyTerminatedForAch`, `refunds`
  (`{ writtenRefundPolicy }`), and `limits` (`{ singleTransaction, dailyDeposit, monthlyDeposit }`);
  the `transactionTypes` enum excludes `web`/`ppd`. Declaring `processing.ach` requires the pricing
  to include `processor.ach`. The `create-merchant-platform` reference's old `naicsCode`/`web`/`ppd`
  example was rejected by UAT and has been corrected.
- **`processing.cardAcceptance` shape:** uses a `cardsAccepted` enum array (plus `debitOnly`,
  `hsaFsa`), not per-brand booleans. The default `cardsAccepted` includes `amexOptBlue`, which
  requires Amex OptBlue fees in the pricing (and vice versa).

## Live corrections (verified 2026-06-19, UAT — regression re-test)

Re-test of the full boarding chain (INFOARCH-2766) against UAT. Two new findings:

- **Processing account initial `status` may be `"entered"` or `"pending"` depending on timing.**
  Both the create-merchant-platform 201 response and the add-processing-account 201 response
  returned `"status": "entered"` in the 2026-06-19 UAT run, but this is timing-dependent —
  either value is valid. The status enum already documented both; example snippets and prose
  have been updated to show `"entered"` as a representative value with a note that `"pending"`
  is also possible. Don't assert a specific value from the create response.
- **ACH cross-rule is bi-directional.** The rule was previously documented in one direction only
  ("if `processing.ach` is present, pricing must include `processor.ach`"). UAT also enforces the
  reverse: if the pricing intent carries `processor.ach` fees, the processing account MUST declare
  `processing.ach` (UAT error: `"'Processing Ach' cannot be null when 'Pricing Processor Ach' is
  populated."`). Use a card-only pricing intent when the account does not take ACH payments.

## Related guide pages (not snapshotted; fetch if narrative copy is needed)

`https://docs.payroc.com/api/schema/boarding/merchant-platforms/{create-processing-account,list-processing-accounts}`
and `https://docs.payroc.com/api/schema/boarding/processing-accounts/{retrieve,create-reminder}`.

## Full inline pricing agreement

The inline `pricing.agreement` field detail (`baseUs`, `processor`, `gatewayUs5.2`,
`servicesUs5.0`) is **not** re-snapshotted here — it is identical to the agreement documented
in `../../create-pricing-intent/references/api-schema.md`. Reference that file when a caller
needs inline pricing instead of a `pricingIntentId`.

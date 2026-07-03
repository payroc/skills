# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime.
To refresh a file, re-fetch its source, regenerate it, then update the "Last synced" date here
and in the file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (boarding paths `POST /processing-accounts/{processingAccountId}/terminal-orders`, `GET /processing-accounts/{processingAccountId}/terminal-orders`, `GET /terminal-orders/{terminalOrderId}`, `GET /processing-accounts/{processingAccountId}/processing-terminals`, `GET /processing-terminals/{processingTerminalId}` + `/host-configurations`; schemas `createTerminalOrder`, `terminalOrder`, `orderItem`, `solutionSetup`, `automaticBatchClose`/`manualBatchClose`, `paginatedProcessingTerminals`, `processingTerminal`, `hostConfiguration`, `tsys`) | 2026-06-22 | payroc-verbatim (curated slice) |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-06-22 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly. The
terminal-order and processing-terminal schemas are entirely Payroc-owned, so this skill has no
`third-party-derived` references.

## Divergence from spec / UAT

- **`solutionTemplateId` reliably accepted in UAT is `VAR_Only_TSYS`.** The spec lists 25+ device
  templates, but most are environment/config-gated. Live testing found `VAR_Only_TSYS` is reliably
  accepted for create/list/retrieve in UAT. `api-schema.md` documents this as a **testing aid** —
  send the template the merchant actually ordered in production. Don't bake `VAR_Only_TSYS` into
  production guidance.

- **UAT orders don't return a `processingTerminalId`.** Because the UAT rig uses a non-physical
  device, the order's `orderItems[].links` (and the `processingTerminalId` within) is not populated,
  so the three follow-on reads can't be exercised end-to-end in UAT:
  - **Retrieve processing terminal:** even with a valid, known `processingTerminalId`, the retrieve
    currently fails to deserialize `batchClosure`. The cause is a schema mismatch — the
    terminal-side `automaticBatchClose` schema requires **both** `batchCloseType` *and*
    `batchCloseTime`, while the order-create-side `automaticBatchClose` schema requires only
    `batchCloseType`, so a terminal whose batch config omits the time won't deserialize. So this read
    is not merely "untestable in UAT" — it has an open defect. The skill's Step 6 warning reflects
    this.
  - **Retrieve host processor configuration:** not available in the test environment.

  The skill still **documents and can emit** these reads (this is the only skill where the
  provisioned terminal is relevant), but it warns the developer they're unverified / defective and
  offers to include or skip them rather than emitting silently.

- **List Terminal Orders returns a plain array, not a paginated envelope.** Unlike List Processing
  Accounts (`paginatedProcessingAccounts`), `GET /processing-accounts/{id}/terminal-orders` returns a
  bare JSON array of `terminalOrder`, filtered by `status` / `fromDateTime` / `toDateTime` (no
  `limit`/`after`/`before` cursors). The List Processing Terminals follow-on, by contrast, *is*
  paginated (`paginatedProcessingTerminals`). **Note:** the spec is internally inconsistent here —
  the path op's *prose* says "return a paginated list" and a `paginatedTerminalOrders` schema exists,
  but the operation's actual `200` response is `type: array` of `terminalOrder`. The wire schema
  (plain array) is the truth; the `paginatedTerminalOrders` schema is currently unused. Re-check this
  if the operation is ever re-pointed at that schema.

- **`createTerminalOrder.orderItems` description vs constraint.** The schema's prose says "maximum of
  10 order items" but the actual `maxItems` constraint is **20** (matching `terminalOrder.orderItems`).
  `api-schema.md` uses the real constraint, 1–20.

- **IDs are opaque integers in UAT.** Consistent with the sibling boarding skills, UAT returns plain
  integer IDs (e.g. `processingAccountId` `287019`), not the `PA-XXXX` forms used in docs examples.
  Treat all IDs as opaque strings.

## Related guide pages (not snapshotted; fetch if narrative copy is needed)

`https://docs.payroc.com/api/schema/boarding/processing-accounts/{create-terminal-order,list-terminal-orders}`
and `https://docs.payroc.com/api/schema/boarding/{terminal-orders/retrieve,processing-terminals/retrieve}`.

## Prerequisite skill

A terminal order is placed against an **existing** processing account. The `processingAccountId`
comes from the **add-processing-account** (or **create-merchant-platform**) flow.

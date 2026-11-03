# Recovery: unknown outcomes, retries and stored attempts

Source of truth for **what to do when a call's outcome is unknown**: lost connectivity, timeouts,
`5xx`, `401`, or a POS process that died while the Payroc App was in front. Built from Payroc's
idempotency, authentication and payments docs and this skill's other references; each rule names
its source. Last synced: 2026-10-30. Sources: see `_sources.md`.

## The stored attempt

- Before you send the submit, persist the `Idempotency-Key` and the body; once you have it, persist
  the `paymentInstructionId` too, before you switch. Key the stored state by attempt, not by
  `paymentId` or `orderId`.
- **On app start and before each sale, resolve any stored attempt first:** GET its instruction if
  the id is stored, else re-send its POST with the same key and body (below). The POS process can die
  while the Payroc App is in front, and a scope like `viewModelScope` dies with it. What the gateway
  does with a second instruction while one is live on the device isn't documented; Payroc's
  integration team recommends a state flag in the POS that blocks one (SKILL.md, Step 3).
- **Start `PBCService` before re-sending a submit.** The gateway answers the POST only after the
  Payroc App confirms it received the instruction (`android-same-device.md`, How it works).
- **If the resolved instruction is still `inProgress`**, the card prompt may be waiting behind the
  POS. Either switch to the Payroc App so the cardholder can finish and then poll as usual, or, if
  the customer has gone, `DELETE` it (`409`: GET it and handle the status it now has).
- **If the payment's status isn't final** (`accepted`, `admin`), keep the attempt and check the
  payment again later (`api-schema.md`, `transactionResult`).
- Clear the stored attempt once its outcome is definite, failures included, or it blocks the next
  sale. A new `orderId` and a new key are for a **new** attempt, never for a retry of one whose outcome
  you don't know.

## Submit

- **No response, a timeout or a `5xx`.** Retry the same `POST` with the **same** `Idempotency-Key`
  and the **identical** body. If the first request landed, the gateway returns the saved response
  (the original `202`) instead of creating a second instruction; if it didn't, this request creates
  it. Then GET the instruction for its current state. A new key here can put two instructions on the
  device. (Payroc idempotency docs: same key, URI and body return the saved response.)
- **`401`.** Get a new token and retry once with the same key (`identity-call.md`, Token lifetime).
- **A validation `4xx`** is a definite answer: fix the body and send it with a new key. Reusing the
  old key with a changed body is a `409` (`#idempotency-key-in-use`, `error-response-format.md`).

## Poll and payment

- **A failed poll** (`IOException`, timeout, `5xx`) is not an outcome. Retry with backoff
  (`error-response-format.md`: `500`, retry with exponential backoff) and leave the Payroc App in
  front. On a `401`, get a new token and retry once.
- **At the ceiling**, `DELETE` the instruction: `204` means cancelled; `409` means it already left
  `inProgress`, so GET it and handle that status (`api-schema.md`, Cancel). If the `DELETE` fails
  too, the outcome is unknown: show "outcome unknown, don't re-ring" and keep the stored attempt.
- **`completed`, but the GET of `link.href` fails.** Retry it. The payment exists; only its result
  is unknown.

## Instruction id known, outcome never shown

When the network returns, GET the instruction. If it `completed`, retrieve the payment. If the
cashier has already moved on (the sale was never shown as taken), cancel that payment rather than
leave it: check the payment's `supportedOperations`, then `POST /payments/{paymentId}/reverse` (open
batch, `fullyReverse`) or, once settled, a referenced refund (`POST /payments/{paymentId}/refund`).
Both need their own fresh `Idempotency-Key`. Read `narrative-extend.md` for the reverse and refund
calls.

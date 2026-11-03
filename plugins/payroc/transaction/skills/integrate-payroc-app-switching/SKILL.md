---
name: integrate-payroc-app-switching
description: >-
  Guides an Android developer whose POS app runs on the same payment terminal as the Payroc App
  through card-present payments with Payroc Cloud app switching: start the Payroc App service,
  submit the instruction over REST, switch the screen to the Payroc App for the card, poll, read
  the result from the payment, and switch back. Use it whenever someone mentions Payroc app
  switching, switching between their POS app and the Payroc App, launching the Payroc App from
  their own Android app, a POS that runs on the terminal itself, MITCActivity, PBCService,
  wn.pax.mitc, the overlay (draw over other apps) permission for Payroc payments, or putting a POS
  app on the Paxstore. Covers sales, unreferenced refunds and signatures on the same device,
  cancels and timeouts, and recovering a sale after lost connectivity. Do NOT use it for a POS on
  a separate computer, tablet or phone that sends sales to a terminal (integrate-payroc-cloud),
  for Tap to Pay on iPhone, or for online checkouts.
metadata:
  version: "0.1.2"
  category: transaction
  status: draft
---

# Payroc Cloud app switching (Android POS on the payment device)

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/integrate-payroc-app-switching/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

## Is this the right skill?

App switching is for a POS app **on the payment terminal itself**, next to the Payroc App: it sends a
Payroc Cloud instruction, brings the Payroc App to the front for the card, then comes back. Check:

| The developer wants | Use |
| --- | --- |
| An Android POS app on a payment terminal that also runs the Payroc App | **This skill** |
| A POS on a separate computer, tablet, phone or server that sends sales to a terminal, including an Android terminal running the Payroc App | `integrate-payroc-cloud` skill. No app switch: the POS only calls the REST API. |
| An Android POS on a stock phone or tablet, or on a terminal without the Payroc App | Not supported: Payroc documents app switching only for an Android payment device running the Payroc App. Say so, and offer `integrate-payroc-cloud` with a separate terminal. |
| An iPhone app that takes taps on the merchant's iPhone | Not covered by these skills. Say so. |
| Online checkout (Hosted Fields, Hosted Payment Pages, Payment Links) | The skill for that product. Not card-present. |
| Pairing or setting up the terminal hardware itself | Out of scope. This skill starts with a terminal that has the Payroc App and a serial number. |

For a routing case, say why and name the skill; don't write that integration from memory.

**Which terminals.** The docs say "Android payment device", name the components `wn.pax.mitc` and
ship POS apps through the Paxstore. Payroc's integration team knows of app switching only on PAX
terminals, and Payroc supports it only on Android 10 devices today. Confirm the terminal runs
Android 10 and has the Payroc App before you write device code.

---

## Quick reference

```text
Identity:  https://identity.payroc.com/authorize   (same host for test and live)
API:       https://api.payroc.com/v1               (same host for test and live)
           A test API key selects test, a live key selects live. The key, not the URL, decides.

Payroc App package    test: com.payroc.test      production: com.payroc
Service component     wn.pax.mitc.service.PBCService   (start it before you submit)
Activity component    wn.pax.mitc.MITCActivity         (start it to switch to the Payroc App)

POST   /devices/{serialNumber}/payment-instructions   -> 202 { status: "inProgress", paymentInstructionId, link }
GET    /payment-instructions/{id}                      -> 200  (gateway holds the response up to ~60 s)
DELETE /payment-instructions/{id}                      -> 204  (only while inProgress, else 409)
GET    link.href from the completed instruction        -> the payment (approval lives here)
POST   /payments/{paymentId}/reverse                   -> 200  (open batch only)

Headers: Authorization: Bearer <token>, Content-Type: application/json, Idempotency-Key (POSTs)
```

---

## References

Emit from the local `references/` files, not from memory.

| Local file | Use for |
| --- | --- |
| `references/android-same-device.md` | Payroc's device setup page: overlay permission, updating the Payroc App, `singleTask`, boot order, package and component names, both switches, Paxstore |
| `references/api-schema.md` | Every field name, type, enum, limit and status code for the instruction, payment, refund, reverse and device calls |
| `references/narrative-run-a-sale.md` | Order of the REST calls, the long-held poll, cancelling, idempotency |
| `references/narrative-extend.md` | Unreferenced refunds, signatures, referenced refunds and reversals |
| `references/identity-call.md` | Getting the bearer token |
| `references/error-response-format.md` | The error envelope and `errors[]` |
| `references/field-notes.md` | What a test-environment terminal returned for common mistakes (tax 400s, a duplicate screen on switch-back), and Payroc's integration team's answers on devices, the API key, the serial number and concurrent instructions |
| `references/recovery.md` | Unknown outcomes: retries, which answers spend a key, stored attempts after a restart, cancelling a sale never shown |

Source URLs and sync dates are in [`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Inspect before asking.** Match the project's language, HTTP client, threading model, settings
   storage and existing manifest entries.
2. **Read, then emit.** Field names, enums and limits come from `references/api-schema.md`; package
   and component names from `references/android-same-device.md`.
3. **Switch only after `inProgress`.** Anything else from the submit (an error status, a 4xx) means
   there is nothing for the cardholder to pay: show the error and stay in the POS app.
4. **`completed` is not approved.** Approval is on the payment that `link.href` points at, and the
   `paymentInstructionId` is not the `paymentId`: follow the link, don't build the URL.
5. **No secrets in the APK.** Never hardcode the API key or commit it. See Step 2.
6. **Configure, don't hardcode:** Payroc App package and API host (from one environment setting),
   `processingTerminalId`, serial number and tax.

---

## Intake

Scan the project, then ask only what you can't infer:

1. Is the Payroc App installed on the terminal the POS runs on? (If no, route per the table above.)
2. Test or production? This picks the package name and which API key you use. The REST hosts are the same for both.
3. Does the POS app have its own backend, or does it run standalone on the terminal? This decides
   where the API key lives (Step 2).
4. The `processingTerminalId` and the terminal's serial number. Payroc recommends a settings field in
   the POS app, filled in per device at install. `GET /devices` lists serials. The PAX SDK can read the
   device's serial, but it's PAX's SDK, not Payroc's, and Payroc doesn't recommend building on it.
   Don't invent another way.
5. The tax name and rate configured on the terminal, if the merchant charges tax (Step 4).
6. Which device operations: sales only, or also unreferenced refunds and signatures?

---

## Step 1: Android setup

> Read `references/android-same-device.md` before writing any manifest entry, intent or permission
> code. Use its package and component names exactly.

- **Overlay permission.** The Payroc page says to request `SYSTEM_ALERT_WINDOW` on Android 10 so the
  POS can bring itself back to the front; Android 10 is the only version Payroc supports for app
  switching today. Declare it in the manifest. At runtime, on Android 10 or later, check
  `Settings.canDrawOverlays(context)` and, if false, send the user to
  `Settings.ACTION_MANAGE_OVERLAY_PERMISSION` with `package:<your package>`. Check before each sale
  and don't submit until it's granted, or the POS can't come back. Keep the check for later versions
  too: Android limits background activity starts from 10 onward.
- **`singleTask` launcher activity.** Set `android:launchMode="singleTask"` on the activity that has
  the `MAIN`/`LAUNCHER` intent filter, so switching back returns to the same instance.
- **Update the Payroc App** by opening it once from the home screen. Its navigation bar is hidden;
  tap the Payroc logo three times to show it.
- **Optional: start on boot.** If the POS starts on boot, the Payroc App must start first. Set the
  priority of your boot receiver's `BOOT_COMPLETED` intent filter to `0`.
- **Package visibility (Android 11 and later).** Declare
  `<queries><package android:name="..."/></queries>` for the Payroc package you use: Android's
  filtering of other apps also affects starting another app's service (`PBCService`). General Android
  behaviour, not from the Payroc page.
- **Release.** Upload the POS app to the Paxstore; Payroc recommends becoming a sub-reseller on its
  marketplace there (ask your integration specialist).

---

## Step 2: Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

`POST` the API key to the identity service, read `access_token` and `expires_in`, and send
`Authorization: Bearer <token>` on every API call. Reuse the token and refresh it before it expires.

**Keep the key on a backend unless the app can't have one.** Payroc's same-device page has the POS
app call the gateway but doesn't say how it authenticates; Payroc's integration team says it depends
on whether the POS app has a backend:

- **The POS app has its own backend (the default):** keep the key there, as
  `references/identity-call.md` says. The
  backend gets the token and makes the instruction, poll and payment calls (with proxy timeouts above
  60 seconds for the poll), and the terminal app asks the backend and does the app switch. The backend
  must forward the terminal's `Idempotency-Key` and body unchanged (or own the stored attempt itself);
  minting a key per request turns every retry into a second instruction.
- **The POS app runs standalone on the terminal:** the app has to hold the key, the one exception
  to the server-only rule in `references/identity-call.md`. Every terminal then carries a key, and
  Payroc hasn't said whether a key can be limited to one terminal or to Payroc Cloud instructions.
  Until Payroc says otherwise, treat it as full API access, unreferenced refunds included. **Before
  writing any standalone key handling,** tell the developer to confirm the key's scope with Payroc
  (their integration specialist), and to use a backend instead if they can. Once they've confirmed:
  Payroc's integration team points to the Paxstore's parameterised-app configuration to provision the
  key per device, as Payroc does for its own Payroc Cloud app, rather than building it into the app.
  Beyond that, this skill's advice: keep the key in memory or app-private storage and never log it.

Either way, don't ship the key or a bearer token in the APK.

---

## Step 3: The switch flow

> Read `references/narrative-run-a-sale.md` for the call order, and `references/api-schema.md`
> (`paymentInstructionRequest`, the instruction object, Retrieve a payment) as you build each call.
> Read `references/error-response-format.md` before writing error handling.

The REST calls go through whichever component holds the token (your backend, or the terminal app if
it's standalone; Step 2); the terminal app starts the service and does both switches. Run the sequence off the main thread, in
a scope that survives the POS activity being stopped while the Payroc App is in front (a
`ViewModel`'s `viewModelScope`, not `repeatOnLifecycle(STARTED)`, which cancels the block when the
activity stops and starts it again later, re-running the submit).

1. **Start the Payroc App service** (`PBCService`): `startForegroundService` on Android 8 (API 26) and
   later, `startService` before that, so the Payroc App is running when the instruction arrives. A
   `null` return means the service wasn't found: treat it, or an exception, as a failure and don't submit.
   If the Payroc App wasn't running, the start races the instruction: Payroc's integration team has
   seen such a sale go through, and says it can also fail while the app is still starting. Starting
   `PBCService` when the POS app starts as well gives the Payroc App time to come up before the first
   sale.
2. **Submit** `POST /devices/{serialNumber}/payment-instructions` with a fresh UUID v4
   `Idempotency-Key` and the body from Step 4. Persist the `Idempotency-Key`, the body and, once you
   have it, the `paymentInstructionId` before you switch (see Step 6). The gateway answers only after
   the Payroc App confirms it got the instruction, so set the submit's read timeout explicitly too
   (Payroc gives no figure). A timeout or `5xx` here is an unknown outcome (Step 6).
3. **Check the response.** Only `202` with `status: "inProgress"` continues. On a 4xx, read
   `errors[]` (`references/error-response-format.md`), show it, and don't switch.
4. **Switch to the Payroc App:** an explicit intent with
   `ComponentName(payrocPackage, "wn.pax.mitc.MITCActivity")` and `FLAG_ACTIVITY_NEW_TASK`. If
   starting it throws (for example `ActivityNotFoundException`), cancel the instruction (Step 5) and
   show the error.
5. **Poll** `GET /payment-instructions/{id}`. The gateway holds each request up to ~60 seconds
   waiting for the status to change, so don't sleep between polls: issue the GET, wait for it, and
   re-issue only while `status` is `inProgress`. **Set the read timeout above 60 seconds** (90 s is
   reasonable) on whichever component polls and on any hop that relays it; OkHttp's 10-second default
   turns every held poll into a timeout. If a reply comes back still `inProgress` within a second,
   pause about a second so the loop can't spin. A failed poll (`IOException`, timeout, `5xx`, `401`)
   is not an outcome: retry it (Step 6) and leave the Payroc App in front. Put an overall ceiling on
   the loop (Step 5); it's checked between polls, so it can run over by one held request.
6. **On `completed`**, GET `link.href`: that's the payment. Retry that GET if it fails; the payment
   exists, only its result is unknown.
7. **Switch back** with your launcher intent: `packageManager.getLaunchIntentForPackage(packageName)`
   started from the application context. With `singleTask` this returns to the existing activity.
   `moveToFront()` on the POS app's own task also works (`references/field-notes.md`); the launcher
   intent is the documented method. Switch back once the outcome is `completed`, `failure` or `canceled`, or still unknown after the
   ceiling (Step 5), from a `finally` block that still runs when the coroutine is cancelled
   (`withContext(NonCancellable)`), then show it. For an unknown outcome, show "outcome unknown, don't
   re-ring" and keep the stored attempt (Step 6). Any exit that may leave the instruction
   `inProgress` (cancellation, the ceiling, an error you won't retry) sends the `DELETE` (Step 5) first.

```kotlin
// Shape only; names and values come from the references. api = whatever holds the token (Step 2).
suspend fun runSale(order: Order): SaleOutcome = withContext(Dispatchers.IO) {
    val key = UUID.randomUUID().toString()
    val body = buildBody(order)                            // validates first
    startPayrocService()                                   // PBCService; null = not found: stop here
    store.saveAttempt(key, body)                           // before sending (Step 6)
    try {
        val submit = api.submitPaymentInstruction(serial, body, key) // timeout/5xx: retry same key
        if (submit.status != "inProgress") {               // validation 4xx etc.: definite
            store.clearAttempt(key)
            return@withContext SaleOutcome.NotStarted(submit)
        }
        store.saveInstructionId(key, submit.paymentInstructionId)
        try { switchToPayrocApp() }                        // MITCActivity, FLAG_ACTIVITY_NEW_TASK
        catch (e: Exception) { api.cancel(submit.paymentInstructionId); throw e } // DELETE, then report
        val done = pollUntilSettled(submit.paymentInstructionId) // retries; ceiling -> DELETE
        val outcome = when (done.status) {
            "completed" -> {
                val payment = api.getByHref(done.link.href)  // retried
                if (!isFinal(payment.transactionResult))     // accepted, admin, unknown (Step 5)
                    return@withContext SaleOutcome.Pending(payment) // keep the attempt (Step 6)
                SaleOutcome.Finished(payment)
            }
            "failure"   -> SaleOutcome.Failed(done.errorMessage)
            "canceled"  -> SaleOutcome.Canceled
            else        -> return@withContext SaleOutcome.Unknown // keep the attempt (Step 6)
        }
        store.clearAttempt(key)
        outcome
    } finally {
        withContext(NonCancellable) { switchBackToPos() }  // launcher intent, singleTask
    }
}
```

While it runs, show "waiting for card", ignore Back, and disable Pay so a second tap can't submit.

**One live instruction per terminal.** Payroc's integration team recommends a state flag that blocks
concurrent instructions: set it before the submit, clear it only once the outcome is definite or the
stored attempt is resolved (Step 6), and refuse new sales, refunds and signatures while it's set.
A stored attempt that hasn't been cleared can serve as the flag. What the gateway does with a second
live instruction isn't documented.

---

## Step 4: Build the request body

> Read `references/api-schema.md` (`paymentInstructionRequest`, `order`, `breakdown`) as you build
> it. Check every constrained field before you send, and still surface the server's `errors[]`.

- `processingTerminalId` is a **string**, 4 to 50 characters. Once you send `breakdown`, its
  `subtotal` is required.
- `order.orderId` 1 to 24 characters, new for each attempt. `order.amount` is integer cents.
  `order.currency` from the enum. `operator` up to 50 characters.
- **Taxes.** Each `breakdown.taxes` item needs `type: "rate"`, `rate` and `name`. `rate` is a
  percentage: `8` means 8%, not `0.08`. The gateway checks the name and rate against the tax stored
  for the terminal, so take both from configuration that matches the merchant's terminal setup. If
  the merchant charges no tax, leave `taxes` out.
- Keep all money, subtotal and tax included, in integer cents. Round the tax to whole cents yourself,
  as the merchant's receipts do; the docs don't say how the gateway rounds, or whether it checks
  `amount` against subtotal plus tax.
- Build JSON with a serializer (kotlinx.serialization, Moshi, Gson, `JSONObject`), not string
  concatenation. kotlinx.serialization drops a property that still has its default value unless
  `encodeDefaults = true`, so a `val type: String = "rate"` silently brings back the 400.

---

## Step 5: Read the result, and handle cancel and timeout

> Read the "Retrieve a payment" and `transactionResult` sections of `references/api-schema.md`.
> Read `references/field-notes.md` when diagnosing a 400 on submit or a duplicate screen after
> switching back.

- **Approval** is on the payment's `transactionResult`. The spec calls `status` `ready`, `pending`
  and `complete` successful, so `ready` with `responseCode: "A"` is an approval, not only `complete`;
  `P` is a partial approval. Payroc doesn't document which `status` and `responseCode` pairs a device
  sale returns, and `accepted` and `admin` aren't final: don't call those approved or declined, and
  keep the stored attempt so you can check the payment again.
  Otherwise show `responseMessage`, keep the cart, and let the cashier retry or take another tender.
- **Receipt fields:** `paymentId`, `card.type`, `card.cardNumber` (masked), `card.entryMethod`,
  `transactionResult.approvalCode`, `transactionResult.responseMessage`.
- **`failure`:** show `errorMessage`. **`canceled`:** the instruction was cancelled before it
  completed. Both mean no payment to show.
- **Timeout.** Pick an overall ceiling long enough for a real cardholder (minutes, not seconds). If
  it passes while still `inProgress`, `DELETE /payment-instructions/{id}`: `204` means cancelled. A
  `409` means it already left `inProgress`, so GET it again and handle the status it now has; it may
  have completed. What the Payroc App screen shows after the `DELETE` isn't documented, so don't
  wait for it to hand back: switch back yourself, as Step 3 does.

The test environment is reliable for shapes and validation; its timing and statuses may be simulated.

---

## Step 6: Recover after lost connectivity

> Read `references/recovery.md` before writing any retry, timeout, restart or recovery code.

The connection can drop, and the POS process can die while the Payroc App is in front. In short:

- On app start and before each sale, resolve any stored attempt first. Start `PBCService` before
  re-sending a submit; if the instruction is still `inProgress`, switch to the Payroc App so the
  cardholder can finish, or `DELETE` it.
- Retry an unknown outcome (no response, timeout, `5xx`) with the **same** `Idempotency-Key` and the
  **identical** body; a new key can put two instructions on the device. A new key and `orderId` are
  only for a new attempt.
- A completed sale the cashier never saw as taken gets reversed (open batch) or refunded (settled):
  check `supportedOperations`, then `POST /payments/{paymentId}/reverse` or a referenced refund.
- Clear the stored attempt once its outcome is definite, failures included.

---

## Refunds and signatures on the same device

> Read `references/narrative-extend.md` and the refund and signature instruction sections of
> `references/api-schema.md`.

An **unreferenced refund** (`POST /devices/{serialNumber}/refund-instructions`, `order.description`
required) and a **signature** (`POST /devices/{serialNumber}/signature-instructions`) also run on the
Payroc App, so wrap them in the same start service, submit, switch, poll, switch back sequence
(Payroc's integration team expects the switch to work as it does for a sale). The
completed link points at `/refunds/{id}` (read its `transactionResult` as for a payment) or
`/signatures/{id}`.

A **referenced refund** (`POST /payments/{paymentId}/refund`, body `amount` and `description`) and a **reversal**
(`POST /payments/{paymentId}/reverse`) don't touch the device, so don't switch apps for them.

---

## Testing

1. A terminal with the Payroc test app, test credentials, and the terminal's tax (or no `taxes`).
2. Run a sale: the Payroc App opens, the POS returns to the same checkout screen, the result shows.
3. Run a decline, a cancel on the Payroc App, and airplane mode during the poll.
4. The Payroc Cloud Simulator tests the REST calls, not the app switch.

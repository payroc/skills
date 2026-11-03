# Field notes: app switching on a test-environment terminal

Observations from running an app-switching POS on a test-environment payment terminal with the Payroc test app
(`com.payroc.test`), and answers from Payroc's integration team. Use them to diagnose a failure or to fill a gap
the docs leave. They are not documented API behaviour: error text can change, and the test environment may
differ from production. For documented behaviour, use `api-schema.md` and `android-same-device.md`. Last synced:
2026-11-03. Sources: observed on a test-environment terminal, and Payroc's integration team (see `_sources.md`).

## Request validation

- A `breakdown.taxes` item without `type` returned `400` with `'type' must not be null`. The schema
  marks `type` (`"rate"`) as required (`api-schema.md`).
- A tax name and rate that weren't set up for the terminal returned `400` with
  `Tax <NAME> (<rate>%) is not configured`. The gateway checks both against the terminal's tax
  configuration, so take them from the merchant's setup, not from constants.

## Switching back

- With a launcher activity in the default (`standard`) launch mode, starting the launcher intent
  stacked a second home screen on top of the checkout screen. Back then returned to the old one.
  `android:launchMode="singleTask"` on the launcher activity (`android-same-device.md`, Step 3)
  is the documented fix.
- Bringing the existing task forward with
  `(getSystemService(ACTIVITY_SERVICE) as ActivityManager).appTasks.firstOrNull()?.moveToFront()`
  also returned to the same checkout screen. It isn't in the Payroc docs; prefer the launcher intent
  with `singleTask`. Payroc's integration team confirms both methods work.

## From Payroc's integration team (2026-11-03)

Answers to questions the published pages leave open. Where the team hedged, the hedge is kept.

- **Devices.** Payroc supports app switching only on Android 10 devices today; newer Android versions
  are not supported yet. As far as the team knows, the Payroc App runs only on PAX terminals (the
  component names, `wn.pax.mitc.*`, are PAX-specific).
- **Where the API key lives.** It depends on the app. One with its own backend keeps the key there. A
  standalone app on the terminal has to hold the key; the Paxstore's parameterised-app configuration
  can provision it per device, which is how Payroc's own Payroc Cloud app gets its settings. Whether a
  key can be limited to one terminal or to Payroc Cloud instructions was not answered.
- **Serial number and `processingTerminalId`.** Payroc recommends a settings field in the POS app. The
  PAX SDK can read the serial, but Payroc doesn't recommend depending on it.
- **Starting the Payroc App.** If it isn't running, starting it has brought it up in time for the
  instruction, and the team says a sale can also fail while it is still starting up.
- **A second instruction.** Use a state flag in the POS so only one instruction is live at a time.
- **Unreferenced refunds.** Expected to switch the same way as a sale; not reported as tested.
- **POS-side cancel.** The team assumes, without having tested it, that the POS comes back once
  polling sees a final status. What the Payroc App shows after a `DELETE` is still unknown.

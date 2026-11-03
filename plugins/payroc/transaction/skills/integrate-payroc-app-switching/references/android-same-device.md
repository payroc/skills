# Android (POS on the same device): device setup and app switching

Source of truth for **the Android side**: permissions, launch mode, the Payroc App package and
component names, and the two app switches. For the REST calls, use `api-schema.md` and
`narrative-run-a-sale.md`. Last synced: 2026-10-30. Source:
`docs.payroc.com/guides/payments/payroc-cloud/device-setup/android-same-device.md` (see `_sources.md`).

Copied from the published page with three edits: the sequence diagram is dropped (the numbered steps
below carry the same flow), links to other docs pages point at local files instead, and the Kotlin
snippets that the page fences as `xml` are fenced as `kotlin`.

---

Use our Android (POS on same device) configuration to run your POS app and our Payroc App on the same
payment device. Your POS app manages the checkout experience, while our Payroc App securely processes
the payment on the device.

Because both apps run on one device, your integration must manage how they interact. This includes
preparing the Payroc App to receive payment instructions and switching between the two apps when a
transaction is in progress.

## How it works

**Initiate a transaction**

1. Your POS App sends an instruction to our gateway.
2. Our gateway passes the instruction to the Payroc App.
3. The Payroc App confirms that it has received the instruction.
4. Our gateway sends a response to your POS app that contains an identifier for the instruction.
5. You switch from your POS app to the Payroc App.

**Run the transaction**

1. The Payroc App captures the card details.
2. The Payroc App sends the transaction details to our gateway.
3. Our gateway sends the transaction details to the processor.
4. The processor sends a response to our gateway.
5. Our gateway sends the response to the Payroc App.

**Get a link to the transaction**

1. Your POS App sends a request to our gateway to check the status of the instruction.
2. Our gateway sends the response to your POS app that contains a HATEOAS link to view the transaction.

**View the transaction**

1. Your POS App sends a request to our gateway to view the details of the transaction.
2. Our gateway sends a response to your POS App that contains details about the transaction.
3. You switch from the Payroc App to your POS App.
4. Your POS App displays the receipt.

## Integration journey

1. Configure the payment device (below).
2. Use our API to send sale instructions to the payment device (`narrative-run-a-sale.md`).
3. Test your integration with our Payroc Cloud Simulator (`cloud.uat.payroc.com`; see
   `narrative-run-a-sale.md`).

## Configure the payment device

In this configuration, your POS App and the Payroc App are installed on the same Android payment
device. To ensure that both Apps work together correctly, you must configure the device and your POS
App to support background services and App switching.

## Integration steps

1. Adjust the permissions on the payment device.
2. Update the Payroc App.
3. Configure your activity to run a single task.
4. (Optional) Set the Payroc App to start first.
5. Handle App switching.
6. Upload your POS App to the Paxstore.

## Step 1. Adjust the permissions on the payment device

**Note:** This step applies only to Android 10 devices.

To switch back to your POS App from the Payroc App, you need to request the overlay permission at
runtime.

To request the overlay permission, adjust the following permission in your Android manifest:

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

**Example code**

```kotlin
private fun requestPermission() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")
        )
        startActivityForResult(intent, ACTION_MANAGE_OVERLAY_PERMISSION_REQUEST_CODE)
    }
}
```

## Step 2. Update the Payroc App

To confirm that your Payroc App is up to date, open the Payroc App from the home screen. After you
open the Payroc App, it downloads the latest version and settings.

**Note:** The Payroc App doesn't display the navigation bar. To view the navigation bar, tap the
Payroc logo three times.

## Step 3. Configure your activity to run a single task

To return to the same activity instance when you switch back to your POS App, configure the launch
mode to `singleTask`, and then add the following code to your Android manifest:

```xml
<activity
    android:name="com.payroc.appswitching.MainActivity"
    android:exported="true"
    android:label="@string/app_name"
    android:launchMode="singleTask"
    android:theme="@style/Theme.MyApplication.NoActionBar">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```

## Step 4. (Optional) Set the Payroc App to start first

If you want to start your POS App when the device turns on, you need to make sure that the Payroc App
starts first.

To set the Payroc App to start first, set the priority of the intent filter in the boot receiver to
`0`.

```xml
<receiver
    android:name="com.payroc.appswitching.utils.BootReceiver"
    android:exported="true">
    <intent-filter android:priority="0">
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

## Step 5. Handle App switching

Before you can run transactions, you need to:

- Start the Payroc App service.
- Handle switching from your POS App to the Payroc App.
- Handle switching from the Payroc App to your POS App.

### Start the Payroc App service

Before you send instructions to the Payroc App, run a command to start the Payroc App service on the
payment device. If you start this service first, the Payroc App runs in the background before you
send it instructions.

To start the Payroc App service, use the following package name:

| Environment | Package name |
| --- | --- |
| Test | com.payroc.test |
| Production | com.payroc |

```kotlin
val payrocServiceIntent = Intent()
payrocServiceIntent.component = ComponentName(PACKAGE_NAME, "wn.pax.mitc.service.PBCService")
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
    applicationContext.startForegroundService(payrocServiceIntent)
} else {
    applicationContext.startService(payrocServiceIntent)
}
```

### Switch from your POS App to the Payroc App

After you receive a response for a payment instruction with a status of `inProgress`, switch to the
Payroc App on the payment device.

```kotlin
val payrocAppIntent = Intent()
payrocAppIntent.component = ComponentName(PACKAGE_NAME, "wn.pax.mitc.MITCActivity")
payrocAppIntent.flags = FLAG_ACTIVITY_NEW_TASK
applicationContext.startActivity(payrocAppIntent)
```

### Switch from the Payroc App to your POS App

After your POS App receives the details of a transaction or the transaction is canceled, switch back
to your POS App.

```kotlin
val launchIntent = packageManager.getLaunchIntentForPackage(applicationContext.packageName)
applicationContext.startActivity(launchIntent)
```

## Step 6. Upload your POS App to the Paxstore

After you create your POS App, upload it to the Paxstore. We recommend that you become a sub-reseller
on the Payroc marketplace on the Paxstore. For more information about how to set up your sub-reseller
account and upload your app, contact your integration specialist.

## Next steps

Now that you have configured your payment device, program your POS app to submit sale instructions.
For how to submit sale instructions, see `narrative-run-a-sale.md`.

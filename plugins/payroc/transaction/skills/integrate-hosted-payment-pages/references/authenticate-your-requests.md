> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-payment-page/run-a-sale/authenticate-your-requests.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Authenticate your requests

To load the Hosted Payment Page, you need to include a SHA-512 hash in the HASH parameter. The hash authenticates your request and prevents tampering with sensitive values during transit to our gateway.

When the gateway processes your request successfully, it returns the hash in the response. Use the returned hash to verify that the response is legitimate.

**Important:** Build a dynamic hash function instead of hard-coding hash values. The hash string changes depending on the transaction type and optional parameters that you might include.

## Before you begin

You must have credentials for the Self-Care Portal, which is a self-serve portal that you use to configure terminal settings for your merchant. Use this portal to create a terminal secret.

If you don't have credentials for the Self-Care Portal, contact our Integrations Team at [integrationsupport@payroc.com](mailto:integrationsupport@payroc.com).

## Integration steps

1. Create a terminal secret in the Self-Care Portal.
2. Build the hash string and convert it to SHA-512.

## Step 1. Create a terminal secret

The terminal secret is a shared key between your merchant's website and our gateway. Store it securely and rotate it according to your security policy.

**Important:** Never expose the terminal secret on your merchant's website or mobile app.

To create a terminal secret, complete the following steps:

1. Sign in to the Self-Care Portal:
   * Test: [https://payments.uat.payroc.com/merchant/selfcare/](https://payments.uat.payroc.com/merchant/selfcare/)
   * Production: [https://payments.payroc.com/merchant/selfcare/](https://payments.payroc.com/merchant/selfcare/)
2. From the side menu, select **Settings**, and then select **Terminal**.
3. In the Secret field, enter a secret that is between 16 and 48 characters. Use a mixture of letters, numbers, and special characters.
4. In the Confirm Secret field, reenter your secret.
5. Select **UPDATE SETTINGS**.
6. Select **OK** to confirm that you want to change your terminal secret.

**Note:** Enter a terminal secret in both the test and the production environments to ensure that you don't have issues when you complete your testing phase and start to run live transactions.

## Step 2. Build and hash the request string

Create a colon-delimited string from specific request parameter values, append your terminal secret, and then convert the string to a SHA-512 hash.

To create a hash string for a sale, complete the following steps:

1. Build your hash with your parameter values in the following order:
   * `[TERMINALID]:[ORDERID]:[AMOUNT]:[DATETIME]:[SECRET]`
2. Replace the placeholders with actual values:
   * `3204004:HPP744359582:123.45:10-02-2026:09:14:54:058:example_secret_123`
3. Use a hashing library in your programming language to convert the string to a SHA-512 hash:
   * `af306cb3a3dd3c4d5d09f3e04b85da567b0a6c7b65f816cbc11b53a1802be70d277c8fe08bcc3b733303081ed5de2c3ff89c112881bb27004074bb29eb0ca549`

You send this value in the HASH parameter of your request to load the Hosted Payment Page.

## Next steps

* [Load the Hosted Payment Page](load-hosted-payment-page).
> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/guides/take-payments/apple-pay/set-up-apple-pay-for-a-merchant.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Set up Apple Pay for a merchant

After you integrate with the Apple Pay JS API and the Payroc API, you need to set up Apple Pay for each individual merchant. We then generate a unique ID for the merchant's domain that you need to start an Apple Pay session.\
To set up Apple Pay for a merchant, complete the following steps:\
**Step 1.** Add the domain verification file to the merchant's domain.\
**Step 2.** Add the merchant's domain to the Self-Care Portal.

## Before you begin

Add the following subfolder to the merchant's domain:

`/.well-known`

## Step 1. Add the domain verification file to the merchant's domain

1. Log into the [Self-Care Portal](https://payments.payroc.com/).
2. From the side menu, select **Settings**, and then select **Apple Pay Domains**.
3. Select **DOWNLOAD DOMAIN VERIFICATION FILE**.
4. Add the file to the merchant's domain in the following subfolder:\
   `/.well-known/apple-developer-merchantid-domain-association`

**Important:** Do not change the name of the domain verification file. The file name must be `apple-developer-merchantid-domain-association`.

## Step 2. Add the merchant's domain to the Self-Care Portal

1. Select **ADD NEW DOMAIN**.
2. In the **Domain** field, enter the merchant's domain name, for example, website.com.
3. Select **Save**.

The Self-Care Portal redirects you to the Apple Pay Domains page where it displays the unique ID of the merchant's domain.

**Important:** Store the unique ID of the merchant's domain. You need to send the unique ID when you start an Apple Pay Session.
> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/guides/take-payments/3-d-secure.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# 3-D Secure

3-D Secure is a security feature that helps to verify the cardholder’s identity during e-commerce transactions.

Each time the merchant runs a transaction, the issuing bank assesses the transaction. If the risk of fraud is high, the issuing bank uses 3-D Secure to challenge the cardholder to verify their identity.

## How it works

The following diagram shows how 3-D Secure works with your integration.

![3-D Secure diagram diagram](https://files.buildwithfern.com/https://payroc.docs.buildwithfern.com/85f58827cef56226af5a20c418567c7d4717ba5e46052d5de988a14daa5b6033/docs/sections/knowledge/images/landing-page-3ds.png)

### Verify a cardholder

1. Your integration sends a request to the merchant plug-in (MPI) service on our gateway.
2. Our gateway sends the transaction information to the cardholder’s issuing bank.
3. The issuing bank assesses the risk of fraud and challenges the cardholder to verify their identity.
4. The issuing bank returns the verification result to our gateway.
5. Our gateway returns an MPI reference to your integration.

### Run a transaction

1. Your integration sends a payment request to our gateway, which includes the MPI reference.
2. Our gateway returns the transaction result to your integration.

## Guides

Use 3-D Secure to verify a cardholder's identity before you run a sale.
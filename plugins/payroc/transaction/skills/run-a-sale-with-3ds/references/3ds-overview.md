# 3-D Secure — Overview and Flow

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/knowledge/card-payments/3-d-secure.md`
> and `https://docs.payroc.com/guides/take-payments/3-d-secure/run-a-sale-with-3-d-secure.md`.
> Last synced: 2026-06-22.

---

## What 3-D Secure Is

Issuing banks use 3-D Secure to help prevent fraud in e-commerce payments. The service enables merchants to submit payment details for risk assessment by the cardholder's issuing bank.

Also known as: **Visa Secure** / Verified by Visa, **Mastercard Identity Check** / Mastercard SecureCode, **American Express SafeKey**.

---

## How the Flow Works

1. Cardholder submits payment at merchant checkout.
2. Merchant tokenizes the card (Hosted Fields or API tokenization) to get a single-use token.
3. Merchant sends the token and order details to Payroc's MPI (Merchant Plug-In) service.
4. The MPI forwards the details to the cardholder's issuing bank for fraud risk assessment.
5. The bank decides:
   - **Low risk** → approves; no cardholder challenge.
   - **High risk** → prompts the cardholder to verify identity (e.g. log in to banking app).
6. The MPI delivers the authentication result asynchronously to the merchant's **callback URL**.
7. If `result: "A"` (approved) → merchant proceeds to post the payment with the `mpiReference`.
8. If `result: "D"` (declined) → merchant does not submit the payment.

---

## Payroc 3-D Secure Integration Steps

| Step | Action | Who |
| --- | --- | --- |
| 1 | Enable 3-D Secure on the terminal — contact Payroc Integrations (`cs@payroc.com`) and provide your callback URL | Merchant setup |
| 2 | Tokenize the card using Hosted Fields or the API tokenization feature to get a single-use token | Developer |
| 3 | Send a GET request to the MPI service with the token and order details | Developer |
| 4 | Receive the MPI response at your callback URL; check `result`; if `"A"`, post the payment | Developer |

---

## Cardholder Challenge Control

The `cardholderChallenge` query parameter on the MPI request gives the merchant partial control:

| Value | Meaning |
| --- | --- |
| `"REQUIRED"` | Force a cardholder challenge regardless of the bank's risk assessment |
| `"OPTIONAL"` | Allow the bank to decide (default behaviour when the parameter is omitted) |

Omitting `cardholderChallenge` defaults to bank-determined behaviour — some transactions will challenge, others won't.

---

## MPI Result Interpretation

| `result` | `status` | Meaning | Action |
| --- | --- | --- | --- |
| `"A"` | `"Y"` | Cardholder fully authenticated | Proceed to payment — highest confidence |
| `"A"` | `"A"` | Authentication attempted (not enrolled) | Proceed to payment — reduced liability shift |
| `"D"` | `"N"` | Authentication not completed / failed | Do not proceed to payment |
| `"D"` | `"U"` | Unable to authenticate | Do not proceed to payment |

The `eci` field provides the card-scheme indicator:
- `"05"` — fully authenticated
- `"06"` — not enrolled or attempted authentication
- `"07"` — failed authentication

---

## Key Architectural Note

3-D Secure uses two separate Payroc API surfaces with different host names:
- **MPI service** — `payments.uat.payroc.com` / `payments.payroc.com`
- **Payments API** — `api.uat.payroc.com` / `api.payroc.com`

The MPI response is asynchronous — it arrives at the merchant's callback URL, not as a direct response to the MPI GET request. The integration must handle this asynchronous delivery.

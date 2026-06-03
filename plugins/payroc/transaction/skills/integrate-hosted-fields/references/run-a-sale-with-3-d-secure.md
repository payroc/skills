> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/guides/take-payments/3-d-secure/run-a-sale-with-3-d-secure.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Run a sale with 3-D Secure

Use our 3-D Secure feature to verify a cardholder’s identity during an e-Commerce transaction.

## Integration steps

**Step 1.** Sign up for 3-D Secure.\
**Step 2.** Convert the cardholder’s payment details into a single-use token.\
**Step 3.** Send a merchant plug-in (MPI) request.\
**Step 4.** Include the MPI reference in a payment request.

## Before you begin

### Bearer tokens

Use our Identity Service to generate a Bearer token to include in the header of your requests. To generate a Bearer token, complete the following steps:

1. Include your API key in the x-api-key parameter in the header of a POST request.
2. Send your request to [https://identity.payroc.com/authorize](https://identity.payroc.com/authorize).

**Note:** You need to generate a new Bearer token before the previous Bearer token expires.

#### Example request

```sh
curl --location --request POST  'https://identity.payroc.com/authorize' --header 'x-api-key: <api key>'
```

If your request is successful, we return a response that contains your Bearer token, information about its scope, and when it expires.

#### Example response

```json
{
  "access_token": "eyJhbGc....adQssw5c",
  "expires_in": 3600,
  "scope": "service_a service_b",
  "token_type": "Bearer"
}
```

### Headers

To create the header of each POST request, you must include the following parameters:

* **Content-Type:** Include application/json as the value for this parameter.
* **Authorization:** Include your Bearer token in this parameter.
* **Idempotency-Key:** Include a UUID v4 to make the request idempotent.

```sh
curl
  -H "Content-Type: application/json"
  -H "Authorization: <Bearer token>"
  -H "Idempotency-Key: <UUID v4>"
```

### Errors

If your request is unsuccessful, we return an error. For more information about errors, see [Errors](/api/errors).

## Step 1. Sign up for 3-D Secure

To sign up for 3-D Secure, contact our Customer Support team at [cs@payroc.com](mailto:cs@payroc.com).

We use request forwarding to send you the results of the 3-D Secure check. When you sign up for 3-D Secure, provide a URL that we forward the requests to.

## Step 2. Convert the cardholder’s payment details into a single-use token

Before you can send a request to our MPI service, you need to convert the cardholder’s payment details into a single-use token.

To create a single-use token, you can use [Hosted Fields](/guides/take-payments/hosted-fields) or you can use our tokenization feature in our [API](/api).

## Step 3. Send an MPI request

Send the single-use token to our MPI service with information about the transaction in the query parameters.

| Endpoint   | Prefix          | URL                                                                                          |
| :--------- | :-------------- | :------------------------------------------------------------------------------------------- |
| Test       | `payments.uat.` | [https://payments.uat.payroc.com/merchant/mpi](https://payments.uat.payroc.com/merchant/mpi) |
| Production | `payments.`     | [https://payments.payroc.com/merchant/mpi](https://payments.payroc.com/merchant/mpi)         |

### Query parameters

| Parameter            | Type             | Required? | Description                                                                                                                                                                                                                                                                    |
| :------------------- | :--------------- | :-------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| processingTerminalId | string           | Yes       | Unique identifier that we assigned to the terminal.                                                                                                                                                                                                                            |
| singleUseToken       | string           | Yes       | Unique token that the gateway assigned to the payment details.                                                                                                                                                                                                                 |
| email                | string           | Yes       | Cardholder’s email address.                                                                                                                                                                                                                                                    |
| amount               | number \<double> | Yes       | Total amount of the transaction, which includes surcharges. The value is in the currency’s lowest denomination, for example, cents.                                                                                                                                            |
| currency             | string           | Yes       | [ISO-4217](https://www.iso.org/iso-4217-currency-codes.html) currency code of the transaction.                                                                                                                                                                                 |
| orderId              | string           | Yes       | Unique identifier that the merchant assigns to the order.                                                                                                                                                                                                                      |
| cardholderChallenge  | string           | No        | Indicates if the merchant wants the issuing bank to challenge the cardholder. Send one of the following values:<br />• `REQUIRED` - Merchant wants the issuing bank to challenge the cardholder.<br />• `OPTIONAL` - Issuing bank decides whether to challenge the cardholder. |

### Example request

```
https://payments.payroc.com/merchant/mpi?processingTerminalId=4479001&amount=100&currency=EUR&orderId=25&email=joe%40adomain.com&singleUseToken=1a8731f50b02e287ac0529fbce352317c089d4adc1178c1867d65114078791d3c3e13962cbab6b574769dfe9ad5397a5aa67a529ceb0b7be17751f076bbe0e4d
```

### Response fields

If your request is successful, we send a GET request to your MPI receipt URL with the results of the 3-D Secure check and the MPI reference. The response fields are in the query parameters of the GET request.

| Field        | Description                                                                                                                                                                                                                                                                                                                                                                                   |
| :----------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| result       | Indicates the result of the 3-D Secure check. We return one of the following values: <br />• `A` - The issuing bank approved the transaction. <br />• `D` - The issuing bank declined the transaction.                                                                                                                                                                                        |
| mpiReference | MPI reference of the 3-D Secure check.                                                                                                                                                                                                                                                                                                                                                        |
| orderId      | Unique identifier that the merchant assigned to the order.                                                                                                                                                                                                                                                                                                                                    |
| status       | Status of the 3-D Secure check. We return one of the following values: <br />• `A` - Issuing bank attempted to authenticate the cardholder’s identity.<br />• `N` - Issuing bank didn’t attempt to authenticate the cardholder’s identity.<br />• `U` - Issuing bank was unable to authenticate the cardholder’s identity.<br />• `Y` - Issuing bank authenticated the cardholder’s identity. |
| eci          | Response code from 3-D Secure. We return one of the following values:<br />• `05` - Issuing bank used 3-D Secure to authenticate the cardholder.<br />• `06` - Issuing bank or cardholder is not enrolled for 3D Secure.<br />• `07` - 3-D Secure check failed.                                                                                                                               |

### Example response

```
https://{MPI_RECEIPT_URL}?result=A&status=A&eci=06&mpiReference=d01656cf0ec3e62e3754&orderId=25
```

## Step 4. Run a sale

To run a sale, send a POST request to our Payments endpoint.

| Endpoint   | Prefix     | URL                                                                              |
| :--------- | :--------- | :------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/payments](https://api.uat.payroc.com/v1/payments) |
| Production | `api.`     | [https://api.payroc.com/v1/payments](https://api.payroc.com/v1/payments)         |

In your request, send the following parameters in the threeDSecure object:

* **serviceProvider** – Provide a value of gateway.
* **mpiReference** – Provide the MPI reference that we sent your MPI receipt URL in Step 2.

### Request parameters

To create the body of your request, use the following parameters:

### Example request

### Response fields

If your request is successful, we create the payment and return a response. The response contains the following fields:

### Example response
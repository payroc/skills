> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/guides/take-payments/apple-pay/add-apple-pay-to-your-integration.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Add Apple Pay to your integration

Allow your merchants to accept Apple Pay as a payment method.

## Integration steps

**Step 1.** Integrate with the Apple Pay JS API.\
**Step 2.** Integrate with the Payroc API:\
Step 2a - Start an Apple Pay session.\
Step 2b - Run a sale.

## Before you begin

### Bearer tokens

Use our Identity Service to generate a Bearer token to include in the header of your requests. To generate your Bearer token, complete the following steps:

1. Include your API key in the x-api-key parameter in the header of a POST request.
2. Send your request to the identity endpoint for your environment:
   - UAT/test: [https://identity.uat.payroc.com/authorize](https://identity.uat.payroc.com/authorize)
   - Production: [https://identity.payroc.com/authorize](https://identity.payroc.com/authorize)

**Note:** You need to generate a new Bearer token before the previous Bearer token expires.

#### Example request

```sh
# UAT/test
curl --location --request POST  'https://identity.uat.payroc.com/authorize' --header 'x-api-key: <api key>'

# Production
curl --location --request POST  'https://identity.payroc.com/authorize' --header 'x-api-key: <api key>'
```

#### Example response

If your request is successful, we return a response that contains your Bearer token, information about its scope, and when it expires.

```json
{
  "access_token": "eyJhbGc....adQssw5c",
  "expires_in": 3600,
  "scope": "service_a service_b",
  "token_type": "Bearer"
}
```

### Headers

To create the header of each GET request, you must include the following parameters:

* **Content-Type:** Include application/json as the value for this parameter.
* **Authorization:** Include your Bearer token in this parameter.

```sh
curl
  -H "Content-Type: application/json"
  -H "Authorization: <Bearer token>"
```

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

## Step 1. Integrate with the Apple JS API

To integrate with the Apple Pay JS API, go to [https://developer.apple.com/apple-pay/](https://developer.apple.com/apple-pay/).

Your integration with Apple must retrieve the following information:

* **Validation URL** - Apple provides the validation URL that you send to us when you create an Apple Pay session.
* **Encrypted payment details** - Apple encrypts the cardholder's payment details and returns them to your integration. After you receive the encrypted payment details, convert them to hexidecimal.

## Step 2. Integrate with the Payroc API

Use our API to start the merchant session with Apple Pay and retrieve the startSessionResponse object. After you use the Apple Pay JS API to encrypt the cardholder's payment details, use our API to run the sale.

### Step 2a. Start an Apple Pay session

To start an Apple Pay session with Apple, send a request to our Apple Pay sessions endpoint.

| Endpoint   | Prefix     | URL                                                                                                                                                                                            |
| :--------- | :--------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/apple-pay-sessions](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/apple-pay-sessions) |
| Production | `api.`     | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/apple-pay-sessions](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/apple-pay-sessions)         |

In the body of your request, include the following parameters:

* **appleDomainId** - You can view the appleDomainId after you add the merchant's domain to the Self-Care Portal.
* **appleValidationUrl** - Apple provides the validation URL as part of your integration with the Apple Pay JS API.

In the response, we return the startSessionResponse object. Send the content of the startSessionResponse object to Apple to retrieve the cardholder's encrypted payment details.

### Request parameters

To create the body of your request, use the following parameters:

### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/apple-pay-sessions:
    post:
      operationId: create
      summary: Start Apple Pay session
      description: >
        Use this method to start an Apple Pay session for your merchant.  


        In the response, we return the startSessionObject that you send to Apple
        when you retrieve the cardholder's encrypted payment details.  


        **Note:** For more information about how to integrate with Apple Pay, go
        to [Apple Pay](https://docs.payroc.com/guides/take-payments/apple-pay).
      tags:
        - subpackage_applePaySessions
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Successful request. We started the Apple Pay session.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/applePayResponseSession'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/applePaySessions'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    applePaySessions:
      type: object
      properties:
        appleDomainId:
          type: string
          description: >-
            Unique appleDomainId of the merchant's domain that we assigned when
            you added their domain to our Self-Care Portal.
        appleValidationUrl:
          type: string
          description: Validation URL from the Apple Pay JS API.
      required:
        - appleDomainId
        - appleValidationUrl
      title: applePaySessions
    applePayResponseSession:
      type: object
      properties:
        startSessionResponse:
          type: string
          description: >
            Object that Apple returns when they start the merchant's Apple Pay
            session.  


            Send the content in this object to Apple to retrieve the
            cardholder's encrypted payment details.  
      required:
        - startSessionResponse
      title: applePayResponseSession
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems

```

### Example request

### Request

POST [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/apple-pay-sessions](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/apple-pay-sessions)

```curl Apple Pay session response
curl -X POST https://api.payroc.com/v1/processing-terminals/1234001/apple-pay-sessions \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json"
```

```typescript Apple Pay session response
import { PayrocClient } from "payroc";

async function main() {
    const client = new PayrocClient();
    await client.applePaySessions.create("1234001", {});
}
main();

```

```python Apple Pay session response
from payroc import Payroc

client = Payroc()

client.apple_pay_sessions.create(
    processing_terminal_id="1234001",
)

```

```java Apple Pay session response
package com.example.usage;

import com.payroc.api.PayrocApiClient;
import com.payroc.api.resources.applepaysessions.requests.ApplePaySessions;

public class Example {
    public static void main(String[] args) {
        PayrocApiClient client = PayrocApiClient
            .builder()
            .build();

        client.applePaySessions().create(
            "1234001",
            ApplePaySessions
                .builder()
                .build()
        );
    }
}
```

```ruby Apple Pay session response
require "payroc"

client = Payroc::Client.new

client.apple_pay_sessions.create(processing_terminal_id: "1234001")

```

```csharp Apple Pay session response
using Payroc;
using System.Threading.Tasks;
using Payroc.ApplePaySessions;

namespace Usage;

public class Example
{
    public async Task Do() {
        var client = new PayrocClient();

        await client.ApplePaySessions.CreateAsync(
            new ApplePaySessions {
                ProcessingTerminalId = "1234001"
            }
        );
    }

}

```

```go Apple Pay session response
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/processing-terminals/1234001/apple-pay-sessions"

	req, _ := http.NewRequest("POST", url, nil)

	req.Header.Add("Authorization", "Bearer <token>")
	req.Header.Add("Content-Type", "application/json")

	res, _ := http.DefaultClient.Do(req)

	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)

	fmt.Println(res)
	fmt.Println(string(body))

}
```

```php Apple Pay session response
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('POST', 'https://api.payroc.com/v1/processing-terminals/1234001/apple-pay-sessions', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
  ],
]);

echo $response->getBody();
```

```swift Apple Pay session response
import Foundation

let headers = [
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/processing-terminals/1234001/apple-pay-sessions")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "POST"
request.allHTTPHeaderFields = headers

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
  if (error != nil) {
    print(error as Any)
  } else {
    let httpResponse = response as? HTTPURLResponse
    print(httpResponse)
  }
})

dataTask.resume()
```

### Response fields

If your request is successful, our gateway starts the merchant session with Apple and returns the following fields:

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/apple-pay-sessions:
    post:
      operationId: create
      summary: Start Apple Pay session
      description: >
        Use this method to start an Apple Pay session for your merchant.  


        In the response, we return the startSessionObject that you send to Apple
        when you retrieve the cardholder's encrypted payment details.  


        **Note:** For more information about how to integrate with Apple Pay, go
        to [Apple Pay](https://docs.payroc.com/guides/take-payments/apple-pay).
      tags:
        - subpackage_applePaySessions
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Successful request. We started the Apple Pay session.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/applePayResponseSession'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/applePaySessions'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    applePaySessions:
      type: object
      properties:
        appleDomainId:
          type: string
          description: >-
            Unique appleDomainId of the merchant's domain that we assigned when
            you added their domain to our Self-Care Portal.
        appleValidationUrl:
          type: string
          description: Validation URL from the Apple Pay JS API.
      required:
        - appleDomainId
        - appleValidationUrl
      title: applePaySessions
    applePayResponseSession:
      type: object
      properties:
        startSessionResponse:
          type: string
          description: >
            Object that Apple returns when they start the merchant's Apple Pay
            session.  


            Send the content in this object to Apple to retrieve the
            cardholder's encrypted payment details.  
      required:
        - startSessionResponse
      title: applePayResponseSession
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems

```

### Example response

### Response (200)

```json
{
  "startSessionResponse": "{\n  \"epochTimestamp\": 1736264582447,\n  \"expiresAt\": 1736268182447,\n  \"merchantSessionIdentifier\": \"SSHE464E2B91B714F18BFD19D46D0F582BF_916523AAED1343F5BC5815E12BEE9250AFFDC1A17C46B0DE5A943F0F94927C24\",\n  \"nonce\": \"e5775127\",\n  \"merchantIdentifier\": \"BFB110EE83BE2AF4AA7468926C926CCFC57F4A541CCE6E7F3BEFD05002ECE503\",\n  \"domainName\": \"store.com\",\n  \"displayName\": \"Store One\",\n  \"signature\": \"a1b1c012345678a000b000c0012345d0e0f010g10061a031i001j071k0a1b0c1d0e1234567890120f1g0h1i0j1k0a1b0123451c012d0e1f0g1h0i1j123k1a1b1c1d1e1f1g123h1i1j1k1a1b1c1d1e1f1g123h123i1j123k12340a120a12345b012c0123012d0d1e0f1g0h1i123j123k10000\",\n  \"operationalAnalyticsIdentifier\": \"Store One:BFB110EE83BE2AF4AA7468926C926CCFC57F4A541CCE6E7F3BEFD05002ECE503\",\n  \"retries\": 0,\n  \"pspId\": \"17D4AAA8D9357D26D771ABA0DAA0B9D3BB462AD1585492E1FE688AF8BB9558E5\"\n}\n"
}
```

### Step 2b. Run a sale

After you retrieve the cardholder's encrypted payment details from Apple, use our payments endpoint to run a sale.

| Endpoint   | Prefix     | URL                                                                              |
| :--------- | :--------- | :------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/payments](https://api.uat.payroc.com/v1/payments) |
| Production | `api.`     | [https://api.payroc.com/v1/payments](https://api.payroc.com/v1/payments)         |

In your request, send the following parameters in the paymentMethod object:

**type** - Provide a value of `digitalWallet`.\
**serviceProvider** - Provide a value of `apple`.\
**encryptedData** - Provide the encrypted payment details that you retrieved from the Apple Pay JS API. The payment details must be in hexadecimal format.

### Request parameters

To create the body of your request, use the following parameters:

### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /payments:
    post:
      operationId: create
      summary: Create payment
      description: "Use this method to run a sale or a pre-authorization with a customer's payment card. \n\nIn the response, our gateway returns information about the card payment and a paymentId, which you need for the following methods:\n\n-\t[Retrieve payment](https://docs.payroc.com/api/schema/card-payments/payments/retrieve) - View the details of the card payment.\n-\t[Adjust payment](https://docs.payroc.com/api/schema/card-payments/payments/adjust) - Update the details of the card payment.\n-\t[Capture payment](https://docs.payroc.com/api/schema/card-payments/payments/capture)  - Capture the pre-authorization.\n-\t[Reverse payment](https://docs.payroc.com/api/schema/card-payments/refunds/reverse)  - Cancel the card payment if it's in an open batch.\n-\t[Refund payment](https://docs.payroc.com/api/schema/card-payments/refunds/create-referenced-refund)  - Run a referenced refund to return funds to the payment card.\n\n**Payment methods** \n\n- **Cards** - Credit, debit, and EBT\n- **Digital wallets** - [Apple Pay®](https://docs.payroc.com/guides/take-payments/apple-pay) and [Google Pay®](https://docs.payroc.com/guides/take-payments/google-pay) \n- **Tokens** - Secure tokens and single-use tokens\n\n**Features** \n\nOur Create Payment method also supports the following features: \n\n- [Repeat payments](https://docs.payroc.com/guides/take-payments/repeat-payments/use-your-own-software) - Run multiple payments as part of a payment schedule that you manage with your own software. \n- **Offline sales** - Run a sale or a pre-authorization if the terminal loses its connection to our gateway. \n- [Tokenization](https://docs.payroc.com/guides/take-payments/save-payment-details) - Save card details to use in future transactions. \n- [3-D Secure](https://docs.payroc.com/guides/take-payments/3-d-secure) - Verify the identity of the cardholder. \n- [Custom fields](https://docs.payroc.com/guides/take-payments/add-custom-fields) - Add your own data to a payment. \n- **Tips** - Add tips to the card payment.  \n- **Taxes** - Add local taxes to the card payment. \n- **Surcharging** - Add a surcharge to the card payment. \n- **Dual pricing** - Offer different prices based on payment method, for example, if you use our RewardPay Choice pricing program. \n- **Healthcare** - Accept payments from Health Savings Accounts (HSA) and Flexible Spending Accounts (FSA). \n"
      tags:
        - subpackage_cardPayments.subpackage_cardPayments/payments
      parameters:
        - name: Idempotency-Key
          in: header
          description: >-
            Unique identifier that you generate for each request. You must use
            the [UUID v4 format](https://www.rfc-editor.org/rfc/rfc4122) for the
            identifier. For more information about the idempotency key, go to
            [Idempotency](https://docs.payroc.com/api/idempotency).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '201':
          description: Successful request. We processed the transaction.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/payment'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '401':
          description: Identity could not be verified
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/401'
        '403':
          description: Do not have permissions to perform this action
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/403'
        '406':
          description: Not acceptable
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/406'
        '409':
          description: Conflict
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/409'
        '415':
          description: Unsupported media type
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/415'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/paymentRequest'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '401':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '401'
    '403':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path the action was attempted on
        resource:
          type: string
          description: Resource the action was attempted on
      required:
        - type
        - title
        - status
        - detail
      title: '403'
    '406':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '406'
    '409':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path to the existing resource
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
        link:
          $ref: '#/components/schemas/link'
      required:
        - type
        - title
        - status
        - detail
      title: '409'
    '415':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '415'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    PaymentRequestChannel:
      type: string
      enum:
        - pos
        - web
        - moto
      description: Channel that the merchant used to receive the payment details.
      title: PaymentRequestChannel
    currency:
      type: string
      enum:
        - AED
        - AFN
        - ALL
        - AMD
        - ANG
        - AOA
        - ARS
        - AUD
        - AWG
        - AZN
        - BAM
        - BBD
        - BDT
        - BGN
        - BHD
        - BIF
        - BMD
        - BND
        - BOB
        - BOV
        - BRL
        - BSD
        - BTN
        - BWP
        - BYR
        - BZD
        - CAD
        - CDF
        - CHE
        - CHF
        - CHW
        - CLF
        - CLP
        - CNY
        - COP
        - COU
        - CRC
        - CUC
        - CUP
        - CVE
        - CZK
        - DJF
        - DKK
        - DOP
        - DZD
        - EGP
        - ERN
        - ETB
        - EUR
        - FJD
        - FKP
        - GBP
        - GEL
        - GHS
        - GIP
        - GMD
        - GNF
        - GTQ
        - GYD
        - HKD
        - HNL
        - HRK
        - HTG
        - HUF
        - IDR
        - ILS
        - INR
        - IQD
        - IRR
        - ISK
        - JMD
        - JOD
        - JPY
        - KES
        - KGS
        - KHR
        - KMF
        - KPW
        - KRW
        - KWD
        - KYD
        - KZT
        - LAK
        - LBP
        - LKR
        - LRD
        - LSL
        - LTL
        - LVL
        - LYD
        - MAD
        - MDL
        - MGA
        - MKD
        - MMK
        - MNT
        - MOP
        - MRO
        - MRU
        - MUR
        - MVR
        - MWK
        - MXN
        - MXV
        - MYR
        - MZN
        - NAD
        - NGN
        - NIO
        - NOK
        - NPR
        - NZD
        - OMR
        - PAB
        - PEN
        - PGK
        - PHP
        - PKR
        - PLN
        - PYG
        - QAR
        - RON
        - RSD
        - RUB
        - RWF
        - SAR
        - SBD
        - SCR
        - SDG
        - SEK
        - SGD
        - SHP
        - SLL
        - SOS
        - SRD
        - SSP
        - STD
        - STN
        - SVC
        - SYP
        - SZL
        - THB
        - TJS
        - TMT
        - TND
        - TOP
        - TRY
        - TTD
        - TWD
        - TZS
        - UAH
        - UGX
        - USD
        - USN
        - USS
        - UYI
        - UYU
        - UZS
        - VEF
        - VES
        - VND
        - VUV
        - WST
        - XAF
        - XCD
        - XOF
        - XPF
        - YER
        - ZAR
        - ZMW
        - ZWL
      description: >-
        Currency of the transaction. The value for the currency follows the [ISO
        4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
      title: currency
    dccOffer:
      type: object
      properties:
        accepted:
          type: boolean
          description: Indicates if the cardholder accepted DCC offer.
        offerReference:
          type: string
          description: Unique identifier of the DCC offer.
        fxAmount:
          type: integer
          format: int64
          description: >-
            Amount in the cardholder’s currency in the currency’s lowest
            denomination, for example, cents.
        fxCurrency:
          $ref: '#/components/schemas/currency'
          description: >-
            Currency of the transaction in the card’s currency. The value for
            the currency follows the [ISO
            4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
        fxCurrencyCode:
          type: string
          description: >-
            Three-digit currency code for the card. This code follows the [ISO
            4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
        fxCurrencyExponent:
          type: integer
          description: >
            Number of decimal places between the smallest currency unit and a
            whole currency unit. 


            For example, for GBP, the smallest currency unit is 1p and it is
            equal to £0.01. 

            If you use GBP, the value for **fxCurrencyExponent** is 2.
        fxRate:
          type: number
          format: double
          description: Foreign exchange rate for the card's currency.
        markup:
          type: number
          format: double
          description: >-
            Markup percentage rate that the DCC provider applies to the foreign
            exchange rate.
        markupText:
          type: string
          description: Supporting text for the markup rate.
        provider:
          type: string
          description: Name of the DCC provider.
        source:
          type: string
          description: Source that the DCC provider used to get the foreign exchange rates.
      required:
        - fxAmount
        - fxCurrency
        - fxRate
        - markup
      description: >
        Object that contains information about the dynamic currency conversion
        (DCC) offer.  
          
        For more information about DCC, go to [Dynamic Currency
        Conversion](https://docs.payroc.com/knowledge/card-payments/dynamic-currency-conversion).
      title: dccOffer
    StandingInstructionsSequence:
      type: string
      enum:
        - first
        - subsequent
      description: Position of the transaction in the payment plan sequence.
      title: StandingInstructionsSequence
    StandingInstructionsProcessingModel:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      description: >
        Indicates the type of payment instruction.


        - 'unscheduled' – The payment is not part of a regular billing cycle.

        - 'recurring' – The payment is part of a regular billing cycle with no
        end date.

        - 'installment' – The payment is part of a regular billing cycle with an
        end date.
      title: StandingInstructionsProcessingModel
    firstTxnReferenceData:
      type: object
      properties:
        paymentId:
          type: string
          description: >
            Unique identifier of the first payment.  

            **Note:** We recommend that you always send a value for
            **paymentId**.
        cardSchemeReferenceId:
          type: string
          description: Identifier that the card brand assigns to the payment instruction.
      description: >-
        Object that contains information about the initial payment for the
        payment instruction.
      title: firstTxnReferenceData
    standingInstructions:
      type: object
      properties:
        sequence:
          $ref: '#/components/schemas/StandingInstructionsSequence'
          description: Position of the transaction in the payment plan sequence.
        processingModel:
          $ref: '#/components/schemas/StandingInstructionsProcessingModel'
          description: >
            Indicates the type of payment instruction.


            - 'unscheduled' – The payment is not part of a regular billing
            cycle.

            - 'recurring' – The payment is part of a regular billing cycle with
            no end date.

            - 'installment' – The payment is part of a regular billing cycle
            with an end date.
        referenceDataOfFirstTxn:
          $ref: '#/components/schemas/firstTxnReferenceData'
          description: >-
            Object that contains information about the initial payment for the
            payment instruction.
      required:
        - sequence
        - processingModel
      description: >-
        If you don't use our Subscriptions mechanism, include this section to
        configure your standing/recurring orders.
      title: standingInstructions
    TipType:
      type: string
      enum:
        - percentage
        - fixedAmount
      description: >
        Indicates if the tip is a fixed amount or a percentage.  

        **Note:** Our gateway applies the percentage tip to the total amount of
        the transaction after tax.
      title: TipType
    TipMode:
      type: string
      enum:
        - prompted
        - adjusted
      description: >
        Indicates how the tip was added to the transaction.

        - `prompted` – The customer was prompted to add a tip during payment.

        - `adjusted` – The customer added a tip on the receipt for the merchant
        to adjust post-transaction.
      title: TipMode
    tip:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/TipType'
          description: >
            Indicates if the tip is a fixed amount or a percentage.  

            **Note:** Our gateway applies the percentage tip to the total amount
            of the transaction after tax.
        mode:
          $ref: '#/components/schemas/TipMode'
          description: >
            Indicates how the tip was added to the transaction.

            - `prompted` – The customer was prompted to add a tip during
            payment.

            - `adjusted` – The customer added a tip on the receipt for the
            merchant to adjust post-transaction.
        amount:
          type: integer
          format: int64
          description: >
            If the value for type is `fixedAmount`, this value is the tip amount
            in the currency's lowest denomination, for example,
            cents.            
        percentage:
          type: number
          format: double
          description: >-
            If the value for type is `percentage`, this value is the tip as a
            percentage.
      required:
        - type
      description: Object that contains information about the tip.
      title: tip
    surcharge:
      type: object
      properties:
        bypass:
          type: boolean
          description: >
            Indicates if the merchant wants to remove the surcharge fee from the
            transaction.  

            - `true` - Gateway removes the surcharge fee from the transaction.  

            - `false` - Gateway adds the fee to the transaction.   
        amount:
          type: integer
          format: int64
          description: >
            If the merchant added a surcharge fee, this value indicates the
            amount of the surcharge fee

            in the currency’s lowest denomination, for example, cents.
        percentage:
          type: number
          format: double
          description: >-
            If the merchant added a surcharge fee, this value indicates the
            surcharge percentage.
      description: |
        Object that contains information about the surcharge.
      title: surcharge
    choiceRate:
      type: object
      properties:
        applied:
          type: boolean
          default: false
          description: >
            Indicates if the merchant applies a choice rate to the transaction
            amount. 


            Our gateway adds a choice rate to the transaction when the merchant
            offers an alternative payment type, but the customer chooses to pay
            by card.
        rate:
          type: number
          format: double
          description: >
            If the customer used a card to pay for the transaction, this value
            indicates the percentage that our gateway added to the transaction
            amount.  

            **Note:** Our gateway returns a value for **rate** only if the value
            for **applied** in the request is `true`.
        amount:
          type: integer
          format: int64
          description: >
            If the customer used a card to pay for the transaction, this value
            indicates the amount that our gateway added to the transaction
            amount. This value is in the currency’s lowest denomination, for
            example, cents.  

            **Note:** Our gateway returns a value for **amount** only if the
            value for **applied** in the request is `true`.
      required:
        - applied
        - rate
        - amount
      description: >
        Object that contains information about the choice rate. We return this
        only if the value for offered was `true`.
      title: choiceRate
    DualPricingAlternativeTender:
      type: string
      enum:
        - card
        - cash
        - bankTransfer
      description: >
        Payment method that the merchant presented to the customer as an
        alternative to their chosen method.  

        **Note:** For requests, if the value for **offered** is `true`, you must
        send a value for **alternativeTender** in the request.
      title: DualPricingAlternativeTender
    dualPricing:
      type: object
      properties:
        offered:
          type: boolean
          description: Indicates if the merchant offered dual pricing to the customer.
        choiceRate:
          $ref: '#/components/schemas/choiceRate'
          description: >
            Object that contains information about the choice rate.  

            **Note:** For requests, if the value for **offered** is `true`, you
            must send this object in the request.
        alternativeTender:
          $ref: '#/components/schemas/DualPricingAlternativeTender'
          description: >
            Payment method that the merchant presented to the customer as an
            alternative to their chosen method.  

            **Note:** For requests, if the value for **offered** is `true`, you
            must send a value for **alternativeTender** in the request.
      required:
        - offered
      description: Object that contains information about dual pricing.
      title: dualPricing
    HealthcareExpenseType:
      type: string
      enum:
        - copay
        - clinic
        - dental
        - prescription
        - transit
        - vision
      description: Type of healthcare expense.
      title: HealthcareExpenseType
    healthcareExpense:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/HealthcareExpenseType'
          description: Type of healthcare expense.
        amount:
          type: integer
          format: int64
          description: >-
            Amount of the healthcare expense. The value is in the currency's
            lowest denomination, for example, cents.
      required:
        - type
        - amount
      description: Object that contains information about a healthcare expense.
      title: healthcareExpense
    tax:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - amount
              description: 'Discriminator value: amount'
            amount:
              type: integer
              format: int64
              description: >-
                Tax amount for the transaction. The value is in the currency's
                lowest denomination, for example, cents.
            name:
              type: string
              description: Name of the tax.
          required:
            - type
            - amount
            - name
          description: amount variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - rate
              description: 'Discriminator value: rate'
            rate:
              type: number
              format: double
              description: Tax percentage for the transaction.
            name:
              type: string
              description: >-
                Name of the tax. A tax validation on the stored rate for the tax
                name is performed.
          required:
            - type
            - rate
            - name
          description: rate variant
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains tax details.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`amount` - Tax is a fixed amount.\n-\t`rate` - Tax is a percentage.\n"
      title: tax
    convenienceFee:
      type: object
      properties:
        amount:
          type: integer
          format: int64
          description: >
            If the merchant added a convenience fee, this value indicates the
            amount of the convenience fee

            in the currency’s lowest denomination, for example, cents.
      required:
        - amount
      description: >-
        Object that contains information about the convenience fee for the
        transaction.
      title: convenienceFee
    unitOfMeasure:
      type: string
      enum:
        - ACR
        - AMH
        - AMP
        - APZ
        - ARE
        - ASM
        - ASV
        - ATM
        - ATT
        - BAR
        - BFT
        - BHP
        - BHX
        - BIL
        - BLD
        - BLL
        - BQL
        - BTU
        - BUA
        - BUI
        - BX
        - CCT
        - CDL
        - CEL
        - CEN
        - CGM
        - CKG
        - CLF
        - CLT
        - CMK
        - CMT
        - CNP
        - CNT
        - COU
        - CS
        - CTM
        - CUR
        - CWA
        - DAA
        - DAD
        - DAY
        - DEC
        - DLT
        - DMK
        - DMQ
        - DMT
        - DPC
        - DPT
        - DRA
        - DRI
        - DRL
        - DRM
        - DTH
        - DTN
        - DWT
        - DZN
        - DZP
        - DZR
        - EA
        - EAC
        - FAH
        - FAR
        - FOT
        - FTK
        - FTQ
        - GBQ
        - GFI
        - GGR
        - GII
        - GLD
        - GLI
        - GLL
        - GRM
        - GRN
        - GRO
        - GRT
        - GWH
        - HAR
        - HBA
        - HGM
        - HIU
        - HLT
        - HMQ
        - HMT
        - HPA
        - HTZ
        - HUR
        - INH
        - INK
        - INQ
        - ITM
        - JOU
        - KBA
        - KEL
        - KGM
        - KGS
        - KHZ
        - KJO
        - KMH
        - KMK
        - KMQ
        - KMT
        - KNI
        - KNS
        - KNT
        - KPA
        - KPH
        - KPO
        - KPP
        - KSD
        - KSH
        - KTN
        - KUR
        - KVA
        - KVR
        - KVT
        - KWH
        - KWT
        - LBR
        - LBS
        - LEF
        - LPA
        - LTN
        - LTR
        - LUM
        - LUX
        - MAL
        - MAM
        - MAW
        - MBE
        - MBF
        - MBR
        - MCU
        - MGM
        - MHZ
        - MIK
        - MIL
        - MIN
        - MIO
        - MIU
        - MLD
        - MLT
        - MMK
        - MMQ
        - MMT
        - MON
        - MPA
        - MQH
        - MQS
        - MSK
        - MTK
        - MTQ
        - MTR
        - MTS
        - MVA
        - MWH
        - NAR
        - NBB
        - NCL
        - NEW
        - NIU
        - NMB
        - NMI
        - NMP
        - NMR
        - NPL
        - NPT
        - NRL
        - NTT
        - OHM
        - ONZ
        - OZA
        - OZI
        - PAL
        - PCB
        - PCE
        - PGL
        - PK
        - PSC
        - PTD
        - PTI
        - PTL
        - QAN
        - QTD
        - QTI
        - QTL
        - QTR
        - RPM
        - RPS
        - SAN
        - SCO
        - SCR
        - SEC
        - SET
        - SHT
        - SIE
        - SMI
        - SST
        - ST
        - STI
        - TAH
        - TNE
        - TPR
        - TQD
        - TRL
        - TSD
        - TSH
        - VLT
        - WCD
        - WEB
        - WEE
        - WHR
        - WSD
        - WTT
        - YDK
        - YDQ
      description: >-
        Unit of measurement for the item. For more information about units of
        measurement, go to [Units of
        measurement](https://docs.payroc.com/knowledge/basic-concepts/units-of-measurement).
      title: unitOfMeasure
    lineItemRequest:
      type: object
      properties:
        commodityCode:
          type: string
          description: Commodity code of the item.
        productCode:
          type: string
          description: Product code of the item.
        description:
          type: string
          description: Description of the item.
        unitOfMeasure:
          $ref: '#/components/schemas/unitOfMeasure'
        unitPrice:
          type: integer
          format: int64
          description: Price of each unit.
        quantity:
          type: number
          format: double
          description: Number of units.
        discountRate:
          type: number
          format: double
          description: Discount rate that the merchant applies to the item.
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/tax'
          description: >-
            Array of objects that contain information about each tax that
            applies to the item.
      required:
        - unitPrice
        - quantity
      description: List of line items.
      title: lineItemRequest
    itemizedBreakdownRequest:
      type: object
      properties:
        subtotal:
          type: integer
          format: int64
          description: >-
            Amount of the transaction before tax and fees. The value is in the
            currency’s lowest denomination, for example, cents.
        cashbackAmount:
          type: integer
          format: int64
          description: Amount of cashback for the transaction.
        tip:
          $ref: '#/components/schemas/tip'
          description: Object that contains tip information for the transaction.
        surcharge:
          $ref: '#/components/schemas/surcharge'
          description: Object that contains surcharge information for the transaction.
        dualPricing:
          $ref: '#/components/schemas/dualPricing'
          description: Object that contains dual pricing information for the transaction.
        healthcareExpenses:
          type: array
          items:
            $ref: '#/components/schemas/healthcareExpense'
          description: >-
            Array of healthcareExpense objects that contain information about
            healthcare expenses.
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/tax'
          description: "Array of polymorphic tax objects, which contain information about a tax.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`amount` - Tax is a fixed amount.\n-\t`rate` - Tax is a percentage.\n"
        dutyAmount:
          type: integer
          format: int64
          description: >
            Amount of duties or fees that apply to the order. The value is in
            the currency's lowest denomination, for example, cents. 
        freightAmount:
          type: integer
          format: int64
          description: >
            Amount for shipping in the currency's lowest denomination, for
            example, cents.
        convenienceFee:
          $ref: '#/components/schemas/convenienceFee'
        items:
          type: array
          items:
            $ref: '#/components/schemas/lineItemRequest'
          description: >-
            Array of objects that contain information about each item that the
            customer purchased.
      required:
        - subtotal
      description: Object that contains information about the breakdown of the transaction.
      title: itemizedBreakdownRequest
    paymentOrderRequest:
      type: object
      properties:
        orderId:
          type: string
          description: A unique identifier assigned by the merchant.
        dateTime:
          type: string
          format: date-time
          description: >-
            Date and time that the processor processed the transaction. Our
            gateway returns this value in the ISO 8601 format.
        description:
          type: string
          description: Description of the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction. The value is in the currency’s
            lowest denomination, for example, cents.
        currency:
          $ref: '#/components/schemas/currency'
        dccOffer:
          $ref: '#/components/schemas/dccOffer'
        standingInstructions:
          $ref: '#/components/schemas/standingInstructions'
        acceptPartialAmount:
          type: boolean
          default: false
          description: >
            Indicates if the merchant accepts a partial authorization for this
            payment. The value is one of the following:


            - `true` - If the cardholder doesn't have the full amount available
            in their account, our gateway processes a partial payment.

            - `false` - If the cardholder doesn't have the full amount available
            in their account, our gateway declines the payment.
        breakdown:
          $ref: '#/components/schemas/itemizedBreakdownRequest'
      required:
        - orderId
        - amount
        - currency
      description: Object that contains information about the payment.
      title: paymentOrderRequest
    address:
      type: object
      properties:
        address1:
          type: string
          description: Address line 1.
        address2:
          type: string
          description: Address line 2.
        address3:
          type: string
          description: Address line 3.
        city:
          type: string
          description: City.
        state:
          type: string
          description: Name of the state or state abbreviation.
        country:
          type: string
          description: >-
            Two-digit country code for the country that the business operates
            in. The format follows the
            [ISO-3166-1](https://www.iso.org/iso-3166-country-codes.html)
            standard.
        postalCode:
          type: string
          description: Zip code or postal code.
      required:
        - address1
        - city
        - state
        - country
        - postalCode
      description: Object that contains information about the address.
      title: address
    shipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/address'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: shipping
    contactMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - email
              description: 'Discriminator value: email'
            value:
              type: string
              description: Email address.
          required:
            - type
            - value
          description: email variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - phone
              description: 'Discriminator value: phone'
            value:
              type: string
              description: Phone number.
          required:
            - type
            - value
          description: phone variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - mobile
              description: 'Discriminator value: mobile'
            value:
              type: string
              description: Mobile number.
          required:
            - type
            - value
          description: mobile variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - fax
              description: 'Discriminator value: fax'
            value:
              type: string
              description: Fax number.
          required:
            - type
            - value
          description: fax variant
      discriminator:
        propertyName: type
      title: contactMethod
    CustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: CustomerNotificationLanguage
    customer:
      type: object
      properties:
        firstName:
          type: string
          description: Customer's first name.
        lastName:
          type: string
          description: Customer's last name.
        dateOfBirth:
          type: string
          format: date
          description: >-
            Customer's date of birth. The format for this value is
            **YYYY-MM-DD**.
        referenceNumber:
          type: string
          description: >
            Identifier of the transaction, also known as a customer code. 


            For requests, you must send a value for **referenceNumber** if the
            customer provides one. 
        billingAddress:
          $ref: '#/components/schemas/address'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/shipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/CustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: customer
    IpAddressType:
      type: string
      enum:
        - ipv4
        - ipv6
      description: Internet protocol version of the IP address.
      title: IpAddressType
    ipAddress:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/IpAddressType'
          description: Internet protocol version of the IP address.
        value:
          type: string
          description: IP address of the device.
      required:
        - type
        - value
      description: Object that contains the IP address of the device that sent the request.
      title: ipAddress
    FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** Send a value for accountType only for bank account details.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method.

        For example, an Integrated Circuit Card (ICC) transaction can be
        downgraded to a swiped transaction or to a keyed transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo
    DeviceModel:
      type: string
      enum:
        - bbposChp
        - bbposChp2x
        - bbposChp3x
        - bbposRambler
        - bbposWp
        - bbposWp2
        - bbposWp3
        - genericCtlsMsr
        - genericMsr
        - idtechAugusta
        - idtechMinismart
        - idtechSredkey
        - idtechVp3300
        - idtechVp5300
        - idtechVp6300
        - idtechVp6800
        - ingenicoAxiumDx4000
        - ingenicoAxiumDx8000
        - ingenicoAxiumEx8000
        - ingenicoIct220
        - ingenicoIpp320
        - ingenicoIpp350
        - ingenicoIuc285
        - ingenicoL3000
        - ingenicoL7000
        - ingenicoS2000
        - ingenicoS3000
        - ingenicoS4000
        - ingenicoS5000
        - ingenicoS7000
        - paxA80
        - paxA920
        - paxA920Pro
        - paxA920Max
        - paxE500
        - paxE700
        - paxE800
        - paxIm30
        - uic680
        - uicBezel8
      description: Model of the device that the merchant used to process the transaction.
      title: DeviceModel
    DeviceCategory:
      type: string
      enum:
        - attended
        - unattended
      default: attended
      description: Indicates if the device is attended or unattended.
      title: DeviceCategory
    deviceConfig:
      type: object
      properties:
        quickChip:
          type: boolean
          default: false
          description: Indicates if Quick Chip mode is active on a merchant’s POS terminal.
      required:
        - quickChip
      description: >-
        Object that contains information about the configuration of the POS
        terminal.
      title: deviceConfig
    device:
      type: object
      properties:
        model:
          $ref: '#/components/schemas/DeviceModel'
          description: >-
            Model of the device that the merchant used to process the
            transaction.
        category:
          $ref: '#/components/schemas/DeviceCategory'
          default: attended
          description: Indicates if the device is attended or unattended.
        serialNumber:
          type: string
          description: Serial number of the physical device.
        firmwareVersion:
          type: string
          description: Firmware version of the physical device.
        config:
          $ref: '#/components/schemas/deviceConfig'
      required:
        - model
        - serialNumber
      description: >-
        Object that contains information about the physical device the merchant
        used to capture the customer’s card details.
      title: device
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method. 

        For example, an Integrated Circuit Card (ICC) transaction can be
        downgraded to a swiped transaction or a keyed transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo
    EncryptionCapableDeviceModel:
      type: string
      enum:
        - bbposChp
        - bbposChp2x
        - bbposChp3x
        - bbposRambler
        - bbposWp
        - bbposWp2
        - bbposWp3
        - genericCtlsMsr
        - genericMsr
        - idtechAugusta
        - idtechMinismart
        - idtechSredkey
        - idtechVp3300
        - idtechVp5300
        - idtechVp6300
        - idtechVp6800
        - ingenicoAxiumDx4000
        - ingenicoAxiumDx8000
        - ingenicoAxiumEx8000
        - ingenicoIct220
        - ingenicoIpp320
        - ingenicoIpp350
        - ingenicoIuc285
        - ingenicoL3000
        - ingenicoL7000
        - ingenicoS2000
        - ingenicoS3000
        - ingenicoS4000
        - ingenicoS5000
        - ingenicoS7000
        - paxA80
        - paxA920
        - paxA920Pro
        - paxA920Max
        - paxE500
        - paxE700
        - paxE800
        - paxIm30
        - uic680
        - uicBezel8
      description: Model of the device that the merchant used to process the transaction.
      title: EncryptionCapableDeviceModel
    EncryptionCapableDeviceCategory:
      type: string
      enum:
        - attended
        - unattended
      default: attended
      description: Indicates if the device is attended or unattended.
      title: EncryptionCapableDeviceCategory
    encryptionCapableDevice:
      type: object
      properties:
        model:
          $ref: '#/components/schemas/EncryptionCapableDeviceModel'
          description: >-
            Model of the device that the merchant used to process the
            transaction.
        category:
          $ref: '#/components/schemas/EncryptionCapableDeviceCategory'
          default: attended
          description: Indicates if the device is attended or unattended.
        serialNumber:
          type: string
          description: Serial number of the physical device.
        firmwareVersion:
          type: string
          description: Firmware version of the physical device.
        config:
          $ref: '#/components/schemas/deviceConfig'
        dataKsn:
          type: string
          format: hexadecimal
          description: Key serial number.
      required:
        - model
        - serialNumber
        - dataKsn
      description: >-
        Object that contains information about the encryption details of the POS
        terminal.
      title: encryptionCapableDevice
    EbtDetailsWithVoucherBenefitCategory:
      type: string
      enum:
        - cash
        - foodStamp
      description: >
        Indicates if the balance relates to an EBT Cash account or an EBT SNAP
        account.  
         - `cash` – EBT Cash  
         - `foodStamp` – EBT SNAP
      title: EbtDetailsWithVoucherBenefitCategory
    voucher:
      type: object
      properties:
        approvalCode:
          type: string
          description: Authorization code that the processor issued for the transaction.
        serialNumber:
          type: string
          description: Serial number of the voucher.
      required:
        - approvalCode
        - serialNumber
      description: |
        Object that contains information about the EBT voucher.  

        **Note:** Vouchers are available only for EBT SNAP payments.
      title: voucher
    ebtDetailsWithVoucher:
      type: object
      properties:
        benefitCategory:
          $ref: '#/components/schemas/EbtDetailsWithVoucherBenefitCategory'
          description: >
            Indicates if the balance relates to an EBT Cash account or an EBT
            SNAP account.  
             - `cash` – EBT Cash  
             - `foodStamp` – EBT SNAP
        withdrawal:
          type: boolean
          description: >
            Indicates whether the customer wants to withdraw cash.  


            **Note:** Cash withdrawals are available only from EBT Cash
            accounts.
        voucher:
          $ref: '#/components/schemas/voucher'
      required:
        - benefitCategory
      description: >-
        Object that contains information about the Electronic Benefit Transfer
        (EBT) transaction.
      title: ebtDetailsWithVoucher
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - fullyEncrypted
              description: 'Discriminator value: fullyEncrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedData:
              type: string
              format: hexadecimal
              description: Encrypted card data.
            firstDigitOfPan:
              type: string
              description: First digit of the customer’s card number.
          required:
            - dataFormat
            - device
            - encryptedData
          description: >-
            Object that contains information about the encrypted card data for
            keyed transactions.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - partiallyEncrypted
              description: 'Discriminator value: partiallyEncrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedPan:
              type: string
              format: hexadecimal
              description: Encrypted card number.
            maskedPan:
              type: string
              description: >
                Masked card number. 

                The gateway shows only the first six digits and the last four
                digits of the account number. For example, `453985******7062`.
            expiryDate:
              type: string
              description: Expiry date of the customer’s card.
            cvv:
              type: string
              description: Security code of the customer’s card.
            cvvEncrypted:
              type: string
              format: hexadecimal
              description: Encrypted security code data.
            issueNumber:
              type: string
              description: Issue number of the customer’s card.
          required:
            - dataFormat
            - device
            - encryptedPan
            - maskedPan
            - expiryDate
          description: >-
            Object that contains information about the partially-encrypted card
            data for keyed transactions.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - plainText
              description: 'Discriminator value: plainText'
            device:
              $ref: '#/components/schemas/device'
            cardNumber:
              type: string
              description: Customer’s card number.
            expiryDate:
              type: string
              description: >
                Expiry date of the customer’s card.  

                **Note:** We require you to send an expiry date for most BIN
                lookups and electronic voucher transactions.
            cvv:
              type: string
              description: Security code of the customer’s card.
            issueNumber:
              type: string
              description: Issue number of the customer’s card.
          required:
            - dataFormat
            - cardNumber
          description: >-
            Object that contains information about the plain-text card data for
            keyed transactions.
      discriminator:
        propertyName: dataFormat
      description: "Polymorphic object that contains payment card details that the merchant manually entered into the device.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`fullyEncrypted` - All payment card details are encrypted.\n-\t`partiallyEncrypted` - Some payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: Polymorphic object that contains information about the customer's PIN.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method. 

        For example, a swiped transaction can be downgraded to a keyed
        transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason:
      type: string
      enum:
        - technical
        - repeatFallback
        - emptyCandidateList
      description: Reason for the fallback.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason:
      type: string
      enum:
        - technical
        - repeatFallback
        - emptyCandidateList
      description: Reason for the fallback.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - encrypted
              description: 'Discriminator value: encrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedData:
              type: string
              format: hexadecimal
              description: Encrypted data received from the magnetic stripe reader.
            firstDigitOfPan:
              type: string
              description: First digit of the of the card number.
            fallback:
              type: boolean
              description: >-
                Indicates that this is a fallback transaction. For example, if
                there was a technical issue with the chip on the customer's card
                and the merchant then swiped the card.
            fallbackReason:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason
              description: Reason for the fallback.
          required:
            - dataFormat
            - device
            - encryptedData
          description: >-
            Object that contains information about the encrypted swiped card
            data.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - plainText
              description: 'Discriminator value: plainText'
            device:
              $ref: '#/components/schemas/device'
            trackData:
              type: string
              description: Customer’s card data from the swiped transaction.
            fallback:
              type: boolean
              description: >-
                Indicates that this is a fallback transaction. For example, if
                there was a technical issue with the chip on the customer's card
                and the merchant then swiped the card.
            fallbackReason:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason
              description: Reason for the fallback.
          required:
            - dataFormat
            - device
            - trackData
          description: Object that contains information about plain-text swiped card data.
      discriminator:
        propertyName: dataFormat
      description: "Polymorphic object that contains payment card details that a device captured from the magnetic strip.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`encrypted` - Payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: Polymorphic object that contains information about the customer's PIN.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails:
      oneOf:
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - raw
              description: 'Discriminator value: raw'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method.

                For example, an Integrated Circuit Card (ICC) transaction can be
                downgraded to a swiped transaction or to a keyed transaction.
            device:
              $ref: '#/components/schemas/device'
            rawData:
              type: string
              format: hexadecimal
              description: Unencrypted data from the POS terminal.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
          required:
            - entryMethod
            - device
            - rawData
          description: Object that contains information about the unencrypted card details.
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - icc
              description: 'Discriminator value: icc'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method. 

                For example, an Integrated Circuit Card (ICC) transaction can be
                downgraded to a swiped transaction or a keyed transaction.
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            iccData:
              type: string
              format: hexadecimal
              description: >-
                Cardholder data from the ICC. The data consists of EMV tags in
                Tag-Length-Value (TLV) format.
            firstDigitOfPan:
              type: string
              description: First digit of the card number.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - device
            - iccData
          description: >-
            Object that contains information about the Integrated Circuit Card
            (ICC).
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - keyed
              description: 'Discriminator value: keyed'
            keyedData:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData
              description: "Polymorphic object that contains payment card details that the merchant manually entered into the device.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`fullyEncrypted` - All payment card details are encrypted.\n-\t`partiallyEncrypted` - Some payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
            cardholderName:
              type: string
              description: Cardholder’s name.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            pinDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails
              description: >-
                Polymorphic object that contains information about the
                customer's PIN.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - keyedData
          description: Object that contains information about the keyed card details.
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - swiped
              description: 'Discriminator value: swiped'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method. 

                For example, a swiped transaction can be downgraded to a keyed
                transaction.
            swipedData:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData
              description: "Polymorphic object that contains payment card details that a device captured from the magnetic strip.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`encrypted` - Payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
            cardholderName:
              type: string
              description: Cardholder’s name.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            pinDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails
              description: >-
                Polymorphic object that contains information about the
                customer's PIN.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - swipedData
          description: >-
            Object that contains information about the customer’s card details
            for swiped transactions.
      discriminator:
        propertyName: entryMethod
      description: >
        Polymorphic object that contains payment card information.  


        The value of the entryMethod parameter determines which variant you
        should use:  

        - `raw` - Unencrypted payment data directly from the device.

        - `icc` - Payment data that the device captured from the chip.

        - `keyed` - Payment data that the merchant entered manually.

        - `swiped` - Payment data that the device captured from the magnetic
        strip.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails
    BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenAccountType:
      type: string
      enum:
        - checking
        - savings
      description: >
        Indicates the customer’s account type.  


        **Note:** Send a value for accountType only if the secure token
        represents bank account details.
      title: >-
        BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenAccountType
    BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: >
        Indicates how the customer authorized the ACH transaction. Send one of
        the following values:


        - `web` – Online transaction.

        - `tel` – Telephone transaction.

        - `ccd` – Corporate credit card or debit card transaction.

        - `ppd` – Pre-arranged transaction.


        **Note:** This field is mandatory when the secure token represents ACH
        bank account details.
      title: >-
        BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenSecCode
    FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** Send a value for accountType only for bank account details.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletAccountType
    FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletServiceProvider:
      type: string
      enum:
        - apple
        - google
      description: >
        Provider of the digital wallet. Send one of the following values:

        - `apple` - For more information about how to integrate with Apple Pay,
        go to [Apple
        Pay®](https://docs.payroc.com/guides/take-payments/apple-pay).

        - `google` - For more information about how to integrate with google
        Pay, go to [Google
        Pay®](https://docs.payroc.com/guides/take-payments/google-pay).
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletServiceProvider
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType:
      type: string
      enum:
        - checking
        - savings
      description: >
        Indicates the customer’s account type.  


        **Note:** Send a value for accountType only if the single-use token
        represents bank account details.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - raw
              description: 'Discriminator value: raw'
            pin:
              type: string
              description: Customer’s unencrypted PIN.
          required:
            - dataFormat
            - pin
          description: Object that contains information about the unencrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: >
        Polymorphic object that contains information about a customer's PIN.  


        The value of the dataFormat parameter determines which variant you
        should use:  

        - `dukpt` - PIN information is encrypted.

        - `raw` - PIN information is unencrypted.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: >
        Indicates how the customer authorized the ACH transaction. Send one of
        the following values:


        - `web` – Online transaction.

        - `tel` – Telephone transaction.

        - `ccd` – Corporate credit card or debit card transaction.

        - `ppd` – Pre-arranged transaction.


        **Note:** This field is mandatory when the single-use token represents
        ACH bank account details.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode
    PaymentRequestPaymentMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - card
              description: 'Discriminator value: card'
            accountType:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only for bank account
                details.
            cardDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails
              description: >
                Polymorphic object that contains payment card information.  


                The value of the entryMethod parameter determines which variant
                you should use:  

                - `raw` - Unencrypted payment data directly from the device.

                - `icc` - Payment data that the device captured from the chip.

                - `keyed` - Payment data that the merchant entered manually.

                - `swiped` - Payment data that the device captured from the
                magnetic strip.
          required:
            - type
            - cardDetails
          description: Object that contains information about the customer’s payment card.
        - type: object
          properties:
            type:
              type: string
              enum:
                - secureToken
              description: 'Discriminator value: secureToken'
            accountType:
              $ref: >-
                #/components/schemas/BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only if the secure token
                represents bank account details.
            token:
              type: string
              description: Unique token that the gateway assigned to the payment details.
            secCode:
              $ref: >-
                #/components/schemas/BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory when the secure token
                represents ACH bank account details.
          required:
            - type
            - token
          description: >-
            Object that contains information about the secure token that
            represents the customer’s payment details.
        - type: object
          properties:
            type:
              type: string
              enum:
                - digitalWallet
              description: 'Discriminator value: digitalWallet'
            accountType:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only for bank account
                details.
            serviceProvider:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletServiceProvider
              description: >
                Provider of the digital wallet. Send one of the following
                values:

                - `apple` - For more information about how to integrate with
                Apple Pay, go to [Apple
                Pay®](https://docs.payroc.com/guides/take-payments/apple-pay).

                - `google` - For more information about how to integrate with
                google Pay, go to [Google
                Pay®](https://docs.payroc.com/guides/take-payments/google-pay).
            cardholderName:
              type: string
              description: Cardholder’s name.
            encryptedData:
              type: string
              description: Encrypted data of the digital wallet.
          required:
            - type
            - serviceProvider
            - encryptedData
          description: >-
            Object that contains information about the payment details in the
            customer’s digital wallet.
        - type: object
          properties:
            type:
              type: string
              enum:
                - singleUseToken
              description: 'Discriminator value: singleUseToken'
            accountType:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only if the single-use
                token represents bank account details.
            token:
              type: string
              description: Unique token that the gateway assigned to the payment details.
            pinDetails:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails
              description: >
                Polymorphic object that contains information about a customer's
                PIN.  


                The value of the dataFormat parameter determines which variant
                you should use:  

                - `dukpt` - PIN information is encrypted.

                - `raw` - PIN information is unencrypted.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
            secCode:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory when the single-use token
                represents ACH bank account details.
          required:
            - type
            - token
          description: >-
            Object that contains information about the single-use token, which
            represents the customer’s payment details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains payment details.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`card` - Payment card details\n-\t`secureToken` - Secure token details\n-\t`digitalWallet` - Digital wallet details\n-\t`singleUseToken` - Single-use token details\n"
      title: PaymentRequestPaymentMethod
    PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci:
      type: string
      enum:
        - fullyAuthenticated
        - attemptedAuthentication
      description: E-commerce indicator (ECI) result of a the 3-D Secure check.
      title: PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci
    PaymentRequestThreeDSecure:
      oneOf:
        - type: object
          properties:
            serviceProvider:
              type: string
              enum:
                - gateway
              description: 'Discriminator value: gateway'
            mpiReference:
              type: string
              description: >-
                Reference that our gateway assigned to the 3-D Secure
                authentication response.
          required:
            - serviceProvider
            - mpiReference
          description: Object that contains the 3-D Secure information from our gateway.
        - type: object
          properties:
            serviceProvider:
              type: string
              enum:
                - thirdParty
              description: 'Discriminator value: thirdParty'
            eci:
              $ref: >-
                #/components/schemas/PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci
              description: E-commerce indicator (ECI) result of a the 3-D Secure check.
            xid:
              type: string
              description: >-
                Unique transaction identifier that the merchant assigned to the
                transaction and sent in the authentication request.
            cavv:
              type: string
              description: >-
                Cardholder Authentication Verification Value (CAVV) that the
                card issuer provided to prove that they authorized the online
                payment.
            dsTransactionId:
              type: string
              description: >-
                Directory Server Transaction ID that the processor assigned to
                the request.
          required:
            - serviceProvider
            - eci
          description: Object that contains the 3-D Secure information from a third party.
      discriminator:
        propertyName: serviceProvider
      description: "Polymorphic object that contains authentication information from 3-D Secure.  \n\nThe value of the serviceProvider parameter determines which variant you should use:  \n-\t`gateway` - Use our gateway to run a 3-D Secure check.\n-\t`thirdParty` - Use a third party to run a 3-D Secure check.\n"
      title: PaymentRequestThreeDSecure
    SchemasCredentialOnFileMitAgreement:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      description: >
        Indicates how the merchant can use the customer’s card details, as
        agreed by the customer:  


        - `unscheduled` - Transactions for a fixed or variable amount that are
        run at a certain pre-defined event.  

        - `recurring` - Transactions for a fixed amount that are run at regular
        intervals, for example, monthly. Recurring transactions don’t have a
        fixed duration and run until the customer cancels the agreement.  

        - `installment` - Transactions for a fixed amount that are run at
        regular intervals, for example, monthly. Installment transactions have a
        fixed duration.  
          
        **Note:** If you send a value for **mitAgreement**, you must send the
        **standingInstructions** object in the **paymentOrder** object.
      title: SchemasCredentialOnFileMitAgreement
    schemas-credentialOnFile:
      type: object
      properties:
        externalVault:
          type: boolean
          default: false
          description: >-
            Indicates if the merchant uses a third-party vault to store the
            customer’s payment details.
        tokenize:
          type: boolean
          description: >-
            Indicates if our gateway should tokenize the customer’s payment
            details as part of the transaction.
        secureTokenId:
          type: string
          description: >
            Unique identifier that the merchant creates for the secure token
            that represents the customer’s payment details.  

            **Note:** If you do not send a value for the **secureTokenId**, our
            gateway generates a unique identifier for the token.
        mitAgreement:
          $ref: '#/components/schemas/SchemasCredentialOnFileMitAgreement'
          description: >
            Indicates how the merchant can use the customer’s card details, as
            agreed by the customer:  


            - `unscheduled` - Transactions for a fixed or variable amount that
            are run at a certain pre-defined event.  

            - `recurring` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Recurring transactions
            don’t have a fixed duration and run until the customer cancels the
            agreement.  

            - `installment` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Installment transactions
            have a fixed duration.  
              
            **Note:** If you send a value for **mitAgreement**, you must send
            the **standingInstructions** object in the **paymentOrder** object.
      description: >-
        Object that contains information about saving the customer’s payment
        details.
      title: schemas-credentialOnFile
    OfflineProcessingOperation:
      type: string
      enum:
        - offlineDecline
        - offlineApproval
        - deferredAuthorization
      description: Status of the transaction.
      title: OfflineProcessingOperation
    offlineProcessing:
      type: object
      properties:
        operation:
          $ref: '#/components/schemas/OfflineProcessingOperation'
          description: Status of the transaction.
        approvalCode:
          type: string
          description: Approval code for the transaction from the processor.
        dateTime:
          type: string
          format: date-time
          description: >-
            Date and time that the merchant ran the transaction. The date
            follows the ISO 8601 standard.
      required:
        - operation
      description: >-
        Object that contains information about the transaction if the merchant
        ran it when the terminal was offline.
      title: offlineProcessing
    customField:
      type: object
      properties:
        name:
          type: string
          description: Name of the custom field.
        value:
          type: string
          description: Value for the custom field.
      required:
        - name
        - value
      title: customField
    paymentRequest:
      type: object
      properties:
        channel:
          $ref: '#/components/schemas/PaymentRequestChannel'
          description: Channel that the merchant used to receive the payment details.
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        operator:
          type: string
          description: Operator who ran the transaction.
        order:
          $ref: '#/components/schemas/paymentOrderRequest'
        customer:
          $ref: '#/components/schemas/customer'
        ipAddress:
          $ref: '#/components/schemas/ipAddress'
        paymentMethod:
          $ref: '#/components/schemas/PaymentRequestPaymentMethod'
          description: "Polymorphic object that contains payment details.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`card` - Payment card details\n-\t`secureToken` - Secure token details\n-\t`digitalWallet` - Digital wallet details\n-\t`singleUseToken` - Single-use token details\n"
        threeDSecure:
          $ref: '#/components/schemas/PaymentRequestThreeDSecure'
          description: "Polymorphic object that contains authentication information from 3-D Secure.  \n\nThe value of the serviceProvider parameter determines which variant you should use:  \n-\t`gateway` - Use our gateway to run a 3-D Secure check.\n-\t`thirdParty` - Use a third party to run a 3-D Secure check.\n"
        credentialOnFile:
          $ref: '#/components/schemas/schemas-credentialOnFile'
        offlineProcessing:
          $ref: '#/components/schemas/offlineProcessing'
        autoCapture:
          type: boolean
          default: true
          description: >
            Indicates if we should automatically capture the payment amount.  


            - `true` - Run a sale and automatically capture the transaction.

            - `false`- Run a pre-authorization and capture the transaction
            later.  
              
            **Note:** If you send `false` and the terminal doesn't support
            pre-authorization, we set the transaction's status to pending. The
            merchant must capture the transaction to take payment from the
            customer.
        processAsSale:
          type: boolean
          default: false
          description: >
            Indicates if we should immediately settle the sale transaction. The
            merchant cannot adjust the transaction if we immediately settle
            it.  


            **Note:** If the value for **processAsSale** is `true`, the gateway
            ignores the value in **autoCapture**.
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - channel
        - processingTerminalId
        - order
        - paymentMethod
      title: paymentRequest
    retrievedTax:
      type: object
      properties:
        name:
          type: string
          description: Name of the tax.
        rate:
          type: number
          format: double
          description: Tax percentage for the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            Amount of tax that was applied to the transaction. The value is in
            the currency's lowest denomination, for example, cents.
      required:
        - name
        - rate
      title: retrievedTax
    lineItem:
      type: object
      properties:
        commodityCode:
          type: string
          description: Commodity code of the item.
        productCode:
          type: string
          description: Product code of the item.
        description:
          type: string
          description: Description of the item.
        unitOfMeasure:
          $ref: '#/components/schemas/unitOfMeasure'
        unitPrice:
          type: integer
          format: int64
          description: Price of each unit.
        quantity:
          type: number
          format: double
          description: Number of units.
        discountRate:
          type: number
          format: double
          description: Discount rate that the merchant applies to the item.
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/retrievedTax'
          description: >-
            Array of objects that contain information about each tax that
            applies to the item.
      required:
        - unitPrice
        - quantity
      description: List of line items.
      title: lineItem
    itemizedBreakdown:
      type: object
      properties:
        subtotal:
          type: integer
          format: int64
          description: >-
            Amount of the transaction before tax and fees. The value is in the
            currency’s lowest denomination, for example, cents.
        cashbackAmount:
          type: integer
          format: int64
          description: Amount of cashback for the transaction.
        tip:
          $ref: '#/components/schemas/tip'
          description: Object that contains tip information for the transaction.
        surcharge:
          $ref: '#/components/schemas/surcharge'
          description: Object that contains surcharge information for the transaction.
        dualPricing:
          $ref: '#/components/schemas/dualPricing'
          description: Object that contains dual pricing information for the transaction.
        healthcareExpenses:
          type: array
          items:
            $ref: '#/components/schemas/healthcareExpense'
          description: >-
            Array of healthcareExpense objects that contain information about
            healthcare expenses.
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/retrievedTax'
          description: List of taxes.
        dutyAmount:
          type: integer
          format: int64
          description: >
            Amount of duties or fees that apply to the order. The value is in
            the currency's lowest denomination, for example, cents. 
        freightAmount:
          type: integer
          format: int64
          description: >
            Amount for shipping in the currency's lowest denomination, for
            example, cents.
        convenienceFee:
          $ref: '#/components/schemas/convenienceFee'
        items:
          type: array
          items:
            $ref: '#/components/schemas/lineItem'
          description: >-
            Array of objects that contain information about each item that the
            customer purchased.
      required:
        - subtotal
      description: Object that contains information about the breakdown of the transaction.
      title: itemizedBreakdown
    paymentOrder:
      type: object
      properties:
        orderId:
          type: string
          description: A unique identifier assigned by the merchant.
        dateTime:
          type: string
          format: date-time
          description: >-
            Date and time that the processor processed the transaction. Our
            gateway returns this value in the ISO 8601 format.
        description:
          type: string
          description: Description of the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction. The value is in the currency’s
            lowest denomination, for example, cents.
        currency:
          $ref: '#/components/schemas/currency'
        dccOffer:
          $ref: '#/components/schemas/dccOffer'
        standingInstructions:
          $ref: '#/components/schemas/standingInstructions'
        breakdown:
          $ref: '#/components/schemas/itemizedBreakdown'
      required:
        - orderId
        - amount
        - currency
      description: Object that contains information about the payment.
      title: paymentOrder
    retrievedAddress:
      type: object
      properties:
        address1:
          type: string
          description: Address line 1.
        address2:
          type: string
          description: Address line 2.
        address3:
          type: string
          description: Address line 3.
        city:
          type: string
          description: City.
        state:
          type: string
          description: Name of the state or state abbreviation.
        country:
          type: string
          description: >-
            Two-digit country code for the country that the business operates
            in. The format follows the
            [ISO-3166-1](https://www.iso.org/iso-3166-country-codes.html)
            standard.
        postalCode:
          type: string
          description: Zip code or postal code.
      description: Object that contains information about the address.
      title: retrievedAddress
    retrievedShipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/retrievedAddress'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: retrievedShipping
    RetrievedCustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: RetrievedCustomerNotificationLanguage
    retrievedCustomer:
      type: object
      properties:
        firstName:
          type: string
          description: Customer's first name.
        lastName:
          type: string
          description: Customer's last name.
        dateOfBirth:
          type: string
          format: date
          description: >-
            Customer's date of birth. The format for this value is
            **YYYY-MM-DD**.
        referenceNumber:
          type: string
          description: >
            Identifier of the transaction, also known as a customer code. 


            For requests, you must send a value for **referenceNumber** if the
            customer provides one. 
        billingAddress:
          $ref: '#/components/schemas/retrievedAddress'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/retrievedShipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/RetrievedCustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: retrievedCustomer
    CardEntryMethod:
      type: string
      enum:
        - icc
        - keyed
        - swiped
        - swipedFallback
        - contactlessIcc
        - contactlessMsr
      description: Method that the device used to capture the card details.
      title: CardEntryMethod
    SecureTokenSummaryStatus:
      type: string
      enum:
        - notValidated
        - cvvValidated
        - validationFailed
        - issueNumberValidated
        - cardNumberValidated
        - bankAccountValidated
      description: >
        Status of the customer's bank account. The processor performs a security
        check on the customer's bank account and returns the status of the
        account.  

        **Note:** Depending on the merchant's account settings, this feature may
        be unavailable.
      title: SecureTokenSummaryStatus
    link:
      type: object
      properties:
        rel:
          type: string
          description: >-
            Indicates the relationship between the current resource and the
            target resource.
        method:
          type: string
          description: HTTP method that you need to use with the target resource.
        href:
          type: string
          description: URL of the target resource.
      required:
        - rel
        - method
        - href
      description: Object that contains HATEOAS links for the resource.
      title: link
    secureTokenSummary:
      type: object
      properties:
        secureTokenId:
          type: string
          description: Unique identifier that the merchant assigned to the secure token.
        customerName:
          type: string
          description: Customer's name.
        token:
          type: string
          description: >
            Token that the merchant can use in future transactions to represent
            the customer's payment details. The token:  

            - Begins with the six-digit identification number **296753**.  

            - Contains up to 12 digits.  

            - Contains a single check digit that we calculate using the Luhn
            algorithm.  
        status:
          $ref: '#/components/schemas/SecureTokenSummaryStatus'
          description: >
            Status of the customer's bank account. The processor performs a
            security check on the customer's bank account and returns the status
            of the account.  

            **Note:** Depending on the merchant's account settings, this feature
            may be unavailable.
        link:
          $ref: '#/components/schemas/link'
      required:
        - secureTokenId
        - customerName
        - token
        - status
      description: Object that contains information about the secure token.
      title: secureTokenSummary
    SecurityCheckCvvResult:
      type: string
      enum:
        - M
        - 'N'
        - P
        - U
      description: >
        Indicates if the card verification value (CVV) that the customer
        provided in the request matches the CVV on the card.  

        - `M` – The CVV matches the card’s CVV.  

        - `N` – The CVV doesn’t match the card’s CVV.  

        - `P` – The CVV wasn’t processed.  

        - `U` – The CVV isn’t registered.  


        **Note:** Our gateway doesn’t automatically decline transactions when
        the CVV doesn’t match the card’s CVV, unless the merchant selects this
        setting in their account.
      title: SecurityCheckCvvResult
    SecurityCheckAvsResult:
      type: string
      enum:
        - 'Y'
        - A
        - Z
        - 'N'
        - U
        - R
        - G
        - S
        - F
        - W
        - X
      description: >
        Indicates if the address that the customer provided in the request
        matches the address linked to the card.


        - `Y` – The address in the request matches the address linked to the
        card.  

        - `N` – The address in the request doesn’t match the address linked to
        the card.  

        - `A` – The street address matches, but ZIP code or postal code doesn’t
        match.  

        - `Z` - The ZIP code or postal code matches, but street address doesn’t
        match.  

        - `U` – The address information is unavailable.  

        - `G` – The issuer or card brand doesn’t support the Address
        Verification Service (AVS).  

        - `R` – The AVS is currently unavailable. Try again later.  

        - `S` – There was no AVS data in the request, or it was sent in the
        wrong format.  

        - `F` - For UK addresses, the address in the request matches the address
        linked to the card.  

        - `W` – For US addresses, the nine-digit ZIP code or postal code in the
        request matches the address linked to the card but the street address
        doesn’t.  

        - `X` – For US addresses, the nine-digit ZIP code or postal code and the
        street address matches the address linked to the card.  
          
        **Note:** Our gateway doesn’t automatically decline transactions when
        the address doesn’t match the address linked to the card, 

        unless the merchant selects this setting in their account.
      title: SecurityCheckAvsResult
    securityCheck:
      type: object
      properties:
        cvvResult:
          $ref: '#/components/schemas/SecurityCheckCvvResult'
          description: >
            Indicates if the card verification value (CVV) that the customer
            provided in the request matches the CVV on the card.  

            - `M` – The CVV matches the card’s CVV.  

            - `N` – The CVV doesn’t match the card’s CVV.  

            - `P` – The CVV wasn’t processed.  

            - `U` – The CVV isn’t registered.  


            **Note:** Our gateway doesn’t automatically decline transactions
            when the CVV doesn’t match the card’s CVV, unless the merchant
            selects this setting in their account.
        avsResult:
          $ref: '#/components/schemas/SecurityCheckAvsResult'
          description: >
            Indicates if the address that the customer provided in the request
            matches the address linked to the card.


            - `Y` – The address in the request matches the address linked to the
            card.  

            - `N` – The address in the request doesn’t match the address linked
            to the card.  

            - `A` – The street address matches, but ZIP code or postal code
            doesn’t match.  

            - `Z` - The ZIP code or postal code matches, but street address
            doesn’t match.  

            - `U` – The address information is unavailable.  

            - `G` – The issuer or card brand doesn’t support the Address
            Verification Service (AVS).  

            - `R` – The AVS is currently unavailable. Try again later.  

            - `S` – There was no AVS data in the request, or it was sent in the
            wrong format.  

            - `F` - For UK addresses, the address in the request matches the
            address linked to the card.  

            - `W` – For US addresses, the nine-digit ZIP code or postal code in
            the request matches the address linked to the card but the street
            address doesn’t.  

            - `X` – For US addresses, the nine-digit ZIP code or postal code and
            the street address matches the address linked to the card.  
              
            **Note:** Our gateway doesn’t automatically decline transactions
            when the address doesn’t match the address linked to the card, 

            unless the merchant selects this setting in their account.
      description: >-
        Object that contains information about card verification and security
        checks.
      title: securityCheck
    emvTag:
      type: object
      properties:
        hex:
          type: string
          description: Hex code of the EMV tag.
        value:
          type: string
          description: Value of the EMV tag.
      required:
        - hex
        - value
      description: Object that contains information about the EMV tag.
      title: emvTag
    CardBalanceBenefitCategory:
      type: string
      enum:
        - cash
        - foodStamp
      description: >
        Indicates if the balance relates to an EBT Cash account or EBT SNAP
        account.  

        - `cash` – EBT Cash  

        - `foodStamp` – EBT SNAP
      title: CardBalanceBenefitCategory
    cardBalance:
      type: object
      properties:
        benefitCategory:
          $ref: '#/components/schemas/CardBalanceBenefitCategory'
          description: >
            Indicates if the balance relates to an EBT Cash account or EBT SNAP
            account.  

            - `cash` – EBT Cash  

            - `foodStamp` – EBT SNAP
        amount:
          type: integer
          format: int64
          description: >-
            Current balance of the account. This value is in the currency's
            lowest denomination, for example, cents.
        currency:
          $ref: '#/components/schemas/currency'
      required:
        - benefitCategory
        - amount
        - currency
      description: >-
        Object that contains information about the total funds available in the
        card.
      title: cardBalance
    card:
      type: object
      properties:
        type:
          type: string
          description: Card brand of the card, for example, Visa.
        entryMethod:
          $ref: '#/components/schemas/CardEntryMethod'
          description: Method that the device used to capture the card details.
        cardholderName:
          type: string
          description: Cardholder’s name.
        cardholderSignature:
          type: string
          description: Cardholder’s signature.
        cardNumber:
          type: string
          description: >
            Card number. In the response, our gateway shows only the first six
            digits and the last four digits of the card number, for example,
            500165******0000.
        expiryDate:
          type: string
          description: Expiry date of the customer's card. The format is in **MMYY**.
        secureToken:
          $ref: '#/components/schemas/secureTokenSummary'
        securityChecks:
          $ref: '#/components/schemas/securityCheck'
        emvTags:
          type: array
          items:
            $ref: '#/components/schemas/emvTag'
          description: Array of emvTag objects.
        balances:
          type: array
          items:
            $ref: '#/components/schemas/cardBalance'
          description: >-
            Array of cardBalance objects. Our gateway returns this array only
            when the customer uses an Electronic Benefit Transfer (EBT) card.
      required:
        - type
        - entryMethod
        - cardNumber
        - expiryDate
      description: Object that contains the details of the payment card.
      title: card
    RefundSummaryStatus:
      type: string
      enum:
        - ready
        - pending
        - declined
        - complete
        - referral
        - pickup
        - reversal
        - returned
        - admin
        - expired
        - accepted
      description: Current status of the refund.
      title: RefundSummaryStatus
    RefundSummaryResponseCode:
      type: string
      enum:
        - A
        - D
        - E
        - P
        - R
        - C
      description: >
        Response from the processor.  

        - `A` - The processor approved the transaction.  

        - `D` - The processor declined the transaction.  

        - `E` - The processor received the transaction but will process the
        transaction later.  

        - `P` - The processor authorized a portion of the original amount of the
        transaction.  

        - `R` - The issuer declined the transaction and indicated that the
        customer should contact their bank.  

        - `C` - The issuer declined the transaction and indicated that the
        merchant should keep the card as it was reported lost or stolen.
      title: RefundSummaryResponseCode
    refundSummary:
      type: object
      properties:
        refundId:
          type: string
          description: Unique identifier of the refund.
        dateTime:
          type: string
          format: date-time
          description: Date and time that the refund was processed.
        currency:
          $ref: '#/components/schemas/currency'
        amount:
          type: integer
          format: int64
          description: >-
            Amount of the refund. This value is in the currency’s lowest
            denomination, for example, cents.
        status:
          $ref: '#/components/schemas/RefundSummaryStatus'
          description: Current status of the refund.
        responseCode:
          $ref: '#/components/schemas/RefundSummaryResponseCode'
          description: >
            Response from the processor.  

            - `A` - The processor approved the transaction.  

            - `D` - The processor declined the transaction.  

            - `E` - The processor received the transaction but will process the
            transaction later.  

            - `P` - The processor authorized a portion of the original amount of
            the transaction.  

            - `R` - The issuer declined the transaction and indicated that the
            customer should contact their bank.  

            - `C` - The issuer declined the transaction and indicated that the
            merchant should keep the card as it was reported lost or stolen.
        responseMessage:
          type: string
          description: Description of the response from the processor.
        link:
          $ref: '#/components/schemas/link'
      required:
        - refundId
        - dateTime
        - currency
        - amount
        - status
        - responseCode
        - responseMessage
      description: Object that contains information about a refund.
      title: refundSummary
    SupportedOperationsItems:
      type: string
      enum:
        - capture
        - refund
        - fullyReverse
        - partiallyReverse
        - incrementAuthorization
        - adjustTip
        - addSignature
        - setAsReady
        - setAsPending
      title: SupportedOperationsItems
    supportedOperations:
      type: array
      items:
        $ref: '#/components/schemas/SupportedOperationsItems'
      description: |
        Array of operations that you can perform on the transaction.
        - `capture`                - Capture the payment.
        - `refund`                 - Refund the payment.
        - `fullyReverse`           - Fully reverse the transaction.
        - `partiallyReverse`       - Partially reverse the payment.
        - `incrementAuthorization` - Increase the amount of the authorization.
        - `adjustTip`              - Adjust the tip post-payment.
        - `addSignature`           - Add a signature to the payment.
        - `setAsReady`             - Set the transaction’s status to `ready`.
        - `setAsPending`           - Set the transaction’s status to `pending`.
      title: supportedOperations
    TransactionResultType:
      type: string
      enum:
        - sale
        - refund
        - preAuthorization
        - preAuthorizationCompletion
      description: Transaction type.
      title: TransactionResultType
    TransactionResultEbtType:
      type: string
      enum:
        - cashPurchase
        - cashPurchaseWithCashback
        - foodStampPurchase
        - foodStampVoucherPurchase
        - foodStampReturn
        - foodStampVoucherReturn
        - cashBalanceInquiry
        - foodStampBalanceInquiry
        - cashWithdrawal
      description: Indicates the subtype of EBT in the transaction.
      title: TransactionResultEbtType
    TransactionResultStatus:
      type: string
      enum:
        - ready
        - pending
        - declined
        - complete
        - referral
        - pickup
        - reversal
        - admin
        - expired
        - accepted
      description: Current status of the transaction.
      title: TransactionResultStatus
    TransactionResultResponseCode:
      type: string
      enum:
        - A
        - D
        - E
        - P
        - R
        - C
      description: >
        Response from the processor.  

        - `A` - The processor approved the transaction.  

        - `D` - The processor declined the transaction.  

        - `E` - The processor received the transaction but will process the
        transaction later.  

        - `P` - The processor authorized a portion of the original amount of the
        transaction.  

        - `R` - The issuer declined the transaction and indicated that the
        customer should contact their bank.  

        - `C` - The issuer declined the transaction and indicated that the
        merchant should keep the card as it was reported lost or stolen.
      title: TransactionResultResponseCode
    TransactionResultHealthcareIndicator:
      type: string
      enum:
        - 'Y'
        - 'N'
        - C
        - R
      description: >
        Indicates if we processed the payment as a healthcare expense. The value
        is one of the following:  

        - `Y` - We processed the payment as a healthcare expense.  

        - `N` - We processed the payment but it didn't contain any healthcare
        expenses. 

        - `C` - We processed the payment but the card isn't linked to a Flexible
        Spending Account (FSA) or a Health Savings Account (HSA). 

        - `R` - We processed the payment but the card doesn't support healthcare
        expenses. 
      title: TransactionResultHealthcareIndicator
    transactionResult:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/TransactionResultType'
          description: Transaction type.
        ebtType:
          $ref: '#/components/schemas/TransactionResultEbtType'
          description: Indicates the subtype of EBT in the transaction.
        status:
          $ref: '#/components/schemas/TransactionResultStatus'
          description: Current status of the transaction.
        approvalCode:
          type: string
          description: Authorization code that the processor assigned to the transaction.
        authorizedAmount:
          type: integer
          format: int64
          description: >
            Amount that the processor authorized for the transaction. This value
            is in the currency’s lowest denomination, for example, cents.  


            **Notes:**  

            - For partial authorizations, this amount is lower than the amount
            in the request.

            - If the value for **authorizedAmount** is negative, this indicates
            that the merchant sent funds to the customer.
        currency:
          $ref: '#/components/schemas/currency'
        responseCode:
          $ref: '#/components/schemas/TransactionResultResponseCode'
          description: >
            Response from the processor.  

            - `A` - The processor approved the transaction.  

            - `D` - The processor declined the transaction.  

            - `E` - The processor received the transaction but will process the
            transaction later.  

            - `P` - The processor authorized a portion of the original amount of
            the transaction.  

            - `R` - The issuer declined the transaction and indicated that the
            customer should contact their bank.  

            - `C` - The issuer declined the transaction and indicated that the
            merchant should keep the card as it was reported lost or stolen.
        responseMessage:
          type: string
          description: Response description from the processor.
        processorResponseCode:
          type: string
          description: Original response code that the processor sent.
        cardSchemeReferenceId:
          type: string
          description: Identifier that the card brand assigns to the payment instruction.
        healthcareIndicator:
          $ref: '#/components/schemas/TransactionResultHealthcareIndicator'
          description: >
            Indicates if we processed the payment as a healthcare expense. The
            value is one of the following:  

            - `Y` - We processed the payment as a healthcare expense.  

            - `N` - We processed the payment but it didn't contain any
            healthcare expenses. 

            - `C` - We processed the payment but the card isn't linked to a
            Flexible Spending Account (FSA) or a Health Savings Account (HSA). 

            - `R` - We processed the payment but the card doesn't support
            healthcare expenses. 
      required:
        - status
        - responseCode
      description: Object that contains information about the transaction response details.
      title: transactionResult
    payment:
      type: object
      properties:
        paymentId:
          type: string
          description: Unique identifier that our gateway assigned to the transaction.
        processingTerminalId:
          type: string
          description: Unique identifier of the terminal that initiated the transaction.
        operator:
          type: string
          description: Operator who initiated the request.
        order:
          $ref: '#/components/schemas/paymentOrder'
        customer:
          $ref: '#/components/schemas/retrievedCustomer'
        card:
          $ref: '#/components/schemas/card'
        refunds:
          type: array
          items:
            $ref: '#/components/schemas/refundSummary'
          description: >
            Array of refundSummary objects. 

            Each object contains information about refunds linked to the
            transaction.
        supportedOperations:
          $ref: '#/components/schemas/supportedOperations'
        transactionResult:
          $ref: '#/components/schemas/transactionResult'
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - paymentId
        - processingTerminalId
        - order
        - card
        - transactionResult
      title: payment
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems

```

### Example request

### Request

POST [https://api.payroc.com/v1/payments](https://api.payroc.com/v1/payments)

```curl Apple Pay Payment
curl -X POST https://api.payroc.com/v1/payments \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{
  "channel": "web",
  "processingTerminalId": "1234001",
  "order": {
    "orderId": "1234567890W",
    "amount": 4999,
    "currency": "USD",
    "description": "Card Transaction (APPLE)"
  },
  "paymentMethod": {
    "type": "digitalWallet",
    "encryptedData": "7b2262696c6c696e67436f6e74616374223a7b2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c227368697070696e67436f6e74616374223a7b22656d61696c41646472657373223a227465737440646f6d61696e2e636f6d222c2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c22746f6b656e223a7b227061796d656e7444617461223a7b2264617461223a2259314b37626731573479755568587473335941627a6150756c384d31795057304c724637734e2f70415950456d3871647969716c6257777356792b7732334c666c74344e6932525a684c2f6a52727563356f69496235537437763248543739682b74702f78517838496b6a5631485354594d747156644c6a413977686379774f654f70326575556d306e56386b50726569564273726a596c355931437a30576371495648595134424e737a4b5876675063686a497a6f4d4b456336425650744c7335777654667a434b51574a496a646b62516161306265685958524b422b7941773872537a6a4a476f3758523061467a414b4e70346c6f436e69484e564838373244504e4a77364b30336e544d69724b37725a615566485356754d477544473348366e4d78336c48436e6b517478764551474771754132676c416434424f427943414976483541566671655173534137776a4459702f494c6c66614e64307469467478344d6235566f6952513249387379384548547670307736667861316973613874636f484855614b32353857486474673d3d222c227369676e6174757265223a224d494147435371475349623344514548417143414d494143415145784454414c42676c67686b67425a514d45416745776741594a4b6f5a496876634e415163424141436767444343412b517767674f4c6f414d434151494343466e596f627971394f504e4d416f4743437147534d343942414d434d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730794d5441304d6a41784f544d334d444261467730794e6a41304d546b784f544d324e546c614d4749784b44416d42674e5642414d4d4832566a5979317a62584174596e4a76613256794c584e705a32356656554d304c564e42546b5243543167784644415342674e564241734d43326c505579425465584e305a57317a4d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941424949772f6176446e50646549437851325a74464575593334716b423357797a344c484e53314a6e6d506a505472336f4769576f7768354d4d39334f6a697157777661766f5a4d445263546f656b516d7a7055624570576a676749524d4949434454414d42674e5648524d4241663845416a41414d42384741315564497751594d42614146435079536352506b2b54764a2b62453969687350364b372f53354c4d45554743437347415155464277454242446b774e7a4131426767724267454642516377415959706148523063446f764c32396a633341755958427762475575593239744c32396a633341774e433168634842735a5746705932457a4d4449776767456442674e5648534145676745554d4949424544434341517747435371475349623359325146415443422f6a4342777759494b77594242515548416749776762594d67624e535a5778705957356a5a5342766269423061476c7a49474e6c636e52705a6d6c6a5958526c49474a35494746756553427759584a306553426863334e316257567a4947466a593256776447467559325567623259676447686c4948526f5a5734675958427762476c6a59574a735a53427a644746755a4746795a4342305a584a7463794268626d5167593239755a476c3061573975637942765a6942316332557349474e6c636e52705a6d6c6a5958526c4948427662476c6a65534268626d51675932567964476c6d61574e6864476c7662694277636d466a64476c6a5a53427a644746305a57316c626e527a4c6a4132426767724267454642516343415259716148523063446f764c33643364793568634842735a53356a623230765932567964476c6d61574e68644756686458526f62334a7064486b764d44514741315564487751744d4373774b61416e6f43574749326830644841364c79396a636d77755958427762475575593239744c3246776347786c59576c6a59544d7559334a734d4230474131556444675157424251434a44414c6d753774526a4758704b5a614b5a3543635949635254414f42674e56485138424166384542414d43423441774477594a4b6f5a496876646a5a415964424149464144414b42676771686b6a4f5051514441674e4841444245416942306f624d6b32304a4a517733544a307851644d53416a5a6f6653413436686358424e69566d4d6c2b386f7749676154615155367631433170532b6659415463574b725778517039594961446551344b63363042354b3259457767674c754d49494364614144416745434167684a62532b2f4f706a616c7a414b42676771686b6a4f50515144416a426e4d527377475159445651514444424a42634842735a5342536232393049454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730784e4441314d4459794d7a51324d7a4261467730794f5441314d4459794d7a51324d7a42614d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941425041584559515a31325346315270654a594548647569416f752f656536354e34493338533550684d3162565a6c733172694c516c33594e496b353775676a396468664f694d743275325a7776736a6f4b59542f5645576a6766637767665177526759494b77594242515548415145454f6a41344d4459474343734741515546427a41426869706f644852774f69387662324e7a63433568634842735a53356a6232307662324e7a634441304c5746776347786c636d397664474e685a7a4d77485159445652304f4242594546435079536352506b2b54764a2b62453969687350364b372f53354c4d41384741315564457745422f7751464d414d4241663877487759445652306a42426777466f4155753744656f56677a694a716b69706e65767233727239724c4a4b73774e77594456523066424441774c6a41736f4371674b49596d6148523063446f764c324e7962433568634842735a53356a623230765958427762475679623239305932466e4d79356a636d777744675944565230504151482f42415144416745474d42414743697147534962335932514741673445416755414d416f4743437147534d343942414d43413263414d4751434d447250636f4e5246706d78687673317731624b59722f30462b335a4433564e6f6f362b385a7942586b4b33696669593935745a6e356a56515132506e656e432f6749774d693356524347776f7756336246337a4f4475515a2f305866437768625a5a50786e4a7067684a76565068366652755a7935734a6953466842706b50435a4964414141786767474a4d4949426851494241544342686a42364d5334774c4159445651514444435642634842735a5342426348427361574e6864476c766269424a626e526c5a334a6864476c7662694244515341744945637a4d5359774a4159445651514c44423142634842735a5342445a584a3061575a7059324630615739754945463164476876636d6c30655445544d424547413155454367774b51584277624755675357356a4c6a454c4d416b474131554542684d4356564d4343466e596f627971394f504e4d417347435743475341466c41775143416143426b7a415942676b71686b69473977304243514d784377594a4b6f5a496876634e415163424d42774743537147534962334451454a42544550467730794e4445794d5449784e6a51774d5452614d43674743537147534962334451454a4e4445624d426b774377594a59495a4941575544424149426f516f4743437147534d343942414d434d43384743537147534962334451454a4244456942434335615768366c647944637435626844536b62345835494a612b576f746d6d74344a624c74386949754a6b6a414b42676771686b6a4f50515144416752494d45594349514437637561364c6430697a6148716d5371713747303433476770363467484d6b514e523577757a32736137674968414e44643730585a6639432f412b58774e716a75672b76684c39534c4c4966465159746f6745377842534c774141414141414141222c22686561646572223a7b227075626c69634b657948617368223a225542347255754d6b7044627054564b7448636a6452525a496f643465766562754d4f696b7a4156556441593d222c22657068656d6572616c5075626c69634b6579223a224d466b77457759484b6f5a497a6a3043415159494b6f5a497a6a3044415163445167414557556a70324f663878427449432f354335535349544e443554736f75564c423831464547383847504b7243394e394d753365534e72586c32636564757533552f504f53652f616f75384477556a674e6670584d7831673d3d222c227472616e73616374696f6e4964223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d2c2276657273696f6e223a2245435f7631227d2c227061796d656e744d6574686f64223a7b22646973706c61794e616d65223a224d6173746572436172642031343731222c226e6574776f726b223a224d617374657243617264222c2274797065223a226465626974227d2c227472616e73616374696f6e4964656e746966696572223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d7d",
    "serviceProvider": "apple"
  },
  "operator": "Jane"
}'
```

```typescript Apple Pay Payment
import { PayrocClient } from "payroc";

async function main() {
    const client = new PayrocClient();
    await client.cardPayments.payments.create({
        idempotencyKey: "8e03978e-40d5-43e8-bc93-6894a57f9324",
        channel: "web",
        processingTerminalId: "1234001",
        order: {
            orderId: "1234567890W",
            amount: 4999,
            currency: "USD",
            description: "Card Transaction (APPLE)",
        },
        paymentMethod: {
            type: "digitalWallet",
            encryptedData: "7b2262696c6c696e67436f6e74616374223a7b2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c227368697070696e67436f6e74616374223a7b22656d61696c41646472657373223a227465737440646f6d61696e2e636f6d222c2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c22746f6b656e223a7b227061796d656e7444617461223a7b2264617461223a2259314b37626731573479755568587473335941627a6150756c384d31795057304c724637734e2f70415950456d3871647969716c6257777356792b7732334c666c74344e6932525a684c2f6a52727563356f69496235537437763248543739682b74702f78517838496b6a5631485354594d747156644c6a413977686379774f654f70326575556d306e56386b50726569564273726a596c355931437a30576371495648595134424e737a4b5876675063686a497a6f4d4b456336425650744c7335777654667a434b51574a496a646b62516161306265685958524b422b7941773872537a6a4a476f3758523061467a414b4e70346c6f436e69484e564838373244504e4a77364b30336e544d69724b37725a615566485356754d477544473348366e4d78336c48436e6b517478764551474771754132676c416434424f427943414976483541566671655173534137776a4459702f494c6c66614e64307469467478344d6235566f6952513249387379384548547670307736667861316973613874636f484855614b32353857486474673d3d222c227369676e6174757265223a224d494147435371475349623344514548417143414d494143415145784454414c42676c67686b67425a514d45416745776741594a4b6f5a496876634e415163424141436767444343412b517767674f4c6f414d434151494343466e596f627971394f504e4d416f4743437147534d343942414d434d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730794d5441304d6a41784f544d334d444261467730794e6a41304d546b784f544d324e546c614d4749784b44416d42674e5642414d4d4832566a5979317a62584174596e4a76613256794c584e705a32356656554d304c564e42546b5243543167784644415342674e564241734d43326c505579425465584e305a57317a4d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941424949772f6176446e50646549437851325a74464575593334716b423357797a344c484e53314a6e6d506a505472336f4769576f7768354d4d39334f6a697157777661766f5a4d445263546f656b516d7a7055624570576a676749524d4949434454414d42674e5648524d4241663845416a41414d42384741315564497751594d42614146435079536352506b2b54764a2b62453969687350364b372f53354c4d45554743437347415155464277454242446b774e7a4131426767724267454642516377415959706148523063446f764c32396a633341755958427762475575593239744c32396a633341774e433168634842735a5746705932457a4d4449776767456442674e5648534145676745554d4949424544434341517747435371475349623359325146415443422f6a4342777759494b77594242515548416749776762594d67624e535a5778705957356a5a5342766269423061476c7a49474e6c636e52705a6d6c6a5958526c49474a35494746756553427759584a306553426863334e316257567a4947466a593256776447467559325567623259676447686c4948526f5a5734675958427762476c6a59574a735a53427a644746755a4746795a4342305a584a7463794268626d5167593239755a476c3061573975637942765a6942316332557349474e6c636e52705a6d6c6a5958526c4948427662476c6a65534268626d51675932567964476c6d61574e6864476c7662694277636d466a64476c6a5a53427a644746305a57316c626e527a4c6a4132426767724267454642516343415259716148523063446f764c33643364793568634842735a53356a623230765932567964476c6d61574e68644756686458526f62334a7064486b764d44514741315564487751744d4373774b61416e6f43574749326830644841364c79396a636d77755958427762475575593239744c3246776347786c59576c6a59544d7559334a734d4230474131556444675157424251434a44414c6d753774526a4758704b5a614b5a3543635949635254414f42674e56485138424166384542414d43423441774477594a4b6f5a496876646a5a415964424149464144414b42676771686b6a4f5051514441674e4841444245416942306f624d6b32304a4a517733544a307851644d53416a5a6f6653413436686358424e69566d4d6c2b386f7749676154615155367631433170532b6659415463574b725778517039594961446551344b63363042354b3259457767674c754d49494364614144416745434167684a62532b2f4f706a616c7a414b42676771686b6a4f50515144416a426e4d527377475159445651514444424a42634842735a5342536232393049454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730784e4441314d4459794d7a51324d7a4261467730794f5441314d4459794d7a51324d7a42614d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941425041584559515a31325346315270654a594548647569416f752f656536354e34493338533550684d3162565a6c733172694c516c33594e496b353775676a396468664f694d743275325a7776736a6f4b59542f5645576a6766637767665177526759494b77594242515548415145454f6a41344d4459474343734741515546427a41426869706f644852774f69387662324e7a63433568634842735a53356a6232307662324e7a634441304c5746776347786c636d397664474e685a7a4d77485159445652304f4242594546435079536352506b2b54764a2b62453969687350364b372f53354c4d41384741315564457745422f7751464d414d4241663877487759445652306a42426777466f4155753744656f56677a694a716b69706e65767233727239724c4a4b73774e77594456523066424441774c6a41736f4371674b49596d6148523063446f764c324e7962433568634842735a53356a623230765958427762475679623239305932466e4d79356a636d777744675944565230504151482f42415144416745474d42414743697147534962335932514741673445416755414d416f4743437147534d343942414d43413263414d4751434d447250636f4e5246706d78687673317731624b59722f30462b335a4433564e6f6f362b385a7942586b4b33696669593935745a6e356a56515132506e656e432f6749774d693356524347776f7756336246337a4f4475515a2f305866437768625a5a50786e4a7067684a76565068366652755a7935734a6953466842706b50435a4964414141786767474a4d4949426851494241544342686a42364d5334774c4159445651514444435642634842735a5342426348427361574e6864476c766269424a626e526c5a334a6864476c7662694244515341744945637a4d5359774a4159445651514c44423142634842735a5342445a584a3061575a7059324630615739754945463164476876636d6c30655445544d424547413155454367774b51584277624755675357356a4c6a454c4d416b474131554542684d4356564d4343466e596f627971394f504e4d417347435743475341466c41775143416143426b7a415942676b71686b69473977304243514d784377594a4b6f5a496876634e415163424d42774743537147534962334451454a42544550467730794e4445794d5449784e6a51774d5452614d43674743537147534962334451454a4e4445624d426b774377594a59495a4941575544424149426f516f4743437147534d343942414d434d43384743537147534962334451454a4244456942434335615768366c647944637435626844536b62345835494a612b576f746d6d74344a624c74386949754a6b6a414b42676771686b6a4f50515144416752494d45594349514437637561364c6430697a6148716d5371713747303433476770363467484d6b514e523577757a32736137674968414e44643730585a6639432f412b58774e716a75672b76684c39534c4c4966465159746f6745377842534c774141414141414141222c22686561646572223a7b227075626c69634b657948617368223a225542347255754d6b7044627054564b7448636a6452525a496f643465766562754d4f696b7a4156556441593d222c22657068656d6572616c5075626c69634b6579223a224d466b77457759484b6f5a497a6a3043415159494b6f5a497a6a3044415163445167414557556a70324f663878427449432f354335535349544e443554736f75564c423831464547383847504b7243394e394d753365534e72586c32636564757533552f504f53652f616f75384477556a674e6670584d7831673d3d222c227472616e73616374696f6e4964223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d2c2276657273696f6e223a2245435f7631227d2c227061796d656e744d6574686f64223a7b22646973706c61794e616d65223a224d6173746572436172642031343731222c226e6574776f726b223a224d617374657243617264222c2274797065223a226465626974227d2c227472616e73616374696f6e4964656e746966696572223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d7d",
            serviceProvider: "apple",
        },
        operator: "Jane",
    });
}
main();

```

```python Apple Pay Payment
from payroc import Payroc, PaymentOrderRequest
from payroc.card_payments.payments import PaymentRequestPaymentMethod_DigitalWallet

client = Payroc()

client.card_payments.payments.create(
    idempotency_key="8e03978e-40d5-43e8-bc93-6894a57f9324",
    channel="web",
    processing_terminal_id="1234001",
    order=PaymentOrderRequest(
        order_id="1234567890W",
        amount=4999,
        currency="USD",
        description="Card Transaction (APPLE)",
    ),
    payment_method=PaymentRequestPaymentMethod_DigitalWallet(
        encrypted_data="7b2262696c6c696e67436f6e74616374223a7b2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c227368697070696e67436f6e74616374223a7b22656d61696c41646472657373223a227465737440646f6d61696e2e636f6d222c2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c22746f6b656e223a7b227061796d656e7444617461223a7b2264617461223a2259314b37626731573479755568587473335941627a6150756c384d31795057304c724637734e2f70415950456d3871647969716c6257777356792b7732334c666c74344e6932525a684c2f6a52727563356f69496235537437763248543739682b74702f78517838496b6a5631485354594d747156644c6a413977686379774f654f70326575556d306e56386b50726569564273726a596c355931437a30576371495648595134424e737a4b5876675063686a497a6f4d4b456336425650744c7335777654667a434b51574a496a646b62516161306265685958524b422b7941773872537a6a4a476f3758523061467a414b4e70346c6f436e69484e564838373244504e4a77364b30336e544d69724b37725a615566485356754d477544473348366e4d78336c48436e6b517478764551474771754132676c416434424f427943414976483541566671655173534137776a4459702f494c6c66614e64307469467478344d6235566f6952513249387379384548547670307736667861316973613874636f484855614b32353857486474673d3d222c227369676e6174757265223a224d494147435371475349623344514548417143414d494143415145784454414c42676c67686b67425a514d45416745776741594a4b6f5a496876634e415163424141436767444343412b517767674f4c6f414d434151494343466e596f627971394f504e4d416f4743437147534d343942414d434d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730794d5441304d6a41784f544d334d444261467730794e6a41304d546b784f544d324e546c614d4749784b44416d42674e5642414d4d4832566a5979317a62584174596e4a76613256794c584e705a32356656554d304c564e42546b5243543167784644415342674e564241734d43326c505579425465584e305a57317a4d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941424949772f6176446e50646549437851325a74464575593334716b423357797a344c484e53314a6e6d506a505472336f4769576f7768354d4d39334f6a697157777661766f5a4d445263546f656b516d7a7055624570576a676749524d4949434454414d42674e5648524d4241663845416a41414d42384741315564497751594d42614146435079536352506b2b54764a2b62453969687350364b372f53354c4d45554743437347415155464277454242446b774e7a4131426767724267454642516377415959706148523063446f764c32396a633341755958427762475575593239744c32396a633341774e433168634842735a5746705932457a4d4449776767456442674e5648534145676745554d4949424544434341517747435371475349623359325146415443422f6a4342777759494b77594242515548416749776762594d67624e535a5778705957356a5a5342766269423061476c7a49474e6c636e52705a6d6c6a5958526c49474a35494746756553427759584a306553426863334e316257567a4947466a593256776447467559325567623259676447686c4948526f5a5734675958427762476c6a59574a735a53427a644746755a4746795a4342305a584a7463794268626d5167593239755a476c3061573975637942765a6942316332557349474e6c636e52705a6d6c6a5958526c4948427662476c6a65534268626d51675932567964476c6d61574e6864476c7662694277636d466a64476c6a5a53427a644746305a57316c626e527a4c6a4132426767724267454642516343415259716148523063446f764c33643364793568634842735a53356a623230765932567964476c6d61574e68644756686458526f62334a7064486b764d44514741315564487751744d4373774b61416e6f43574749326830644841364c79396a636d77755958427762475575593239744c3246776347786c59576c6a59544d7559334a734d4230474131556444675157424251434a44414c6d753774526a4758704b5a614b5a3543635949635254414f42674e56485138424166384542414d43423441774477594a4b6f5a496876646a5a415964424149464144414b42676771686b6a4f5051514441674e4841444245416942306f624d6b32304a4a517733544a307851644d53416a5a6f6653413436686358424e69566d4d6c2b386f7749676154615155367631433170532b6659415463574b725778517039594961446551344b63363042354b3259457767674c754d49494364614144416745434167684a62532b2f4f706a616c7a414b42676771686b6a4f50515144416a426e4d527377475159445651514444424a42634842735a5342536232393049454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730784e4441314d4459794d7a51324d7a4261467730794f5441314d4459794d7a51324d7a42614d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941425041584559515a31325346315270654a594548647569416f752f656536354e34493338533550684d3162565a6c733172694c516c33594e496b353775676a396468664f694d743275325a7776736a6f4b59542f5645576a6766637767665177526759494b77594242515548415145454f6a41344d4459474343734741515546427a41426869706f644852774f69387662324e7a63433568634842735a53356a6232307662324e7a634441304c5746776347786c636d397664474e685a7a4d77485159445652304f4242594546435079536352506b2b54764a2b62453969687350364b372f53354c4d41384741315564457745422f7751464d414d4241663877487759445652306a42426777466f4155753744656f56677a694a716b69706e65767233727239724c4a4b73774e77594456523066424441774c6a41736f4371674b49596d6148523063446f764c324e7962433568634842735a53356a623230765958427762475679623239305932466e4d79356a636d777744675944565230504151482f42415144416745474d42414743697147534962335932514741673445416755414d416f4743437147534d343942414d43413263414d4751434d447250636f4e5246706d78687673317731624b59722f30462b335a4433564e6f6f362b385a7942586b4b33696669593935745a6e356a56515132506e656e432f6749774d693356524347776f7756336246337a4f4475515a2f305866437768625a5a50786e4a7067684a76565068366652755a7935734a6953466842706b50435a4964414141786767474a4d4949426851494241544342686a42364d5334774c4159445651514444435642634842735a5342426348427361574e6864476c766269424a626e526c5a334a6864476c7662694244515341744945637a4d5359774a4159445651514c44423142634842735a5342445a584a3061575a7059324630615739754945463164476876636d6c30655445544d424547413155454367774b51584277624755675357356a4c6a454c4d416b474131554542684d4356564d4343466e596f627971394f504e4d417347435743475341466c41775143416143426b7a415942676b71686b69473977304243514d784377594a4b6f5a496876634e415163424d42774743537147534962334451454a42544550467730794e4445794d5449784e6a51774d5452614d43674743537147534962334451454a4e4445624d426b774377594a59495a4941575544424149426f516f4743437147534d343942414d434d43384743537147534962334451454a4244456942434335615768366c647944637435626844536b62345835494a612b576f746d6d74344a624c74386949754a6b6a414b42676771686b6a4f50515144416752494d45594349514437637561364c6430697a6148716d5371713747303433476770363467484d6b514e523577757a32736137674968414e44643730585a6639432f412b58774e716a75672b76684c39534c4c4966465159746f6745377842534c774141414141414141222c22686561646572223a7b227075626c69634b657948617368223a225542347255754d6b7044627054564b7448636a6452525a496f643465766562754d4f696b7a4156556441593d222c22657068656d6572616c5075626c69634b6579223a224d466b77457759484b6f5a497a6a3043415159494b6f5a497a6a3044415163445167414557556a70324f663878427449432f354335535349544e443554736f75564c423831464547383847504b7243394e394d753365534e72586c32636564757533552f504f53652f616f75384477556a674e6670584d7831673d3d222c227472616e73616374696f6e4964223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d2c2276657273696f6e223a2245435f7631227d2c227061796d656e744d6574686f64223a7b22646973706c61794e616d65223a224d6173746572436172642031343731222c226e6574776f726b223a224d617374657243617264222c2274797065223a226465626974227d2c227472616e73616374696f6e4964656e746966696572223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d7d",
        service_provider="apple",
    ),
    operator="Jane",
)

```

```java Apple Pay Payment
package com.example.usage;

import com.payroc.api.PayrocApiClient;
import com.payroc.api.resources.cardpayments.payments.requests.PaymentRequest;
import com.payroc.api.resources.cardpayments.payments.types.PaymentRequestChannel;
import com.payroc.api.resources.cardpayments.payments.types.PaymentRequestPaymentMethod;
import com.payroc.api.types.Currency;
import com.payroc.api.types.DigitalWalletPayload;
import com.payroc.api.types.DigitalWalletPayloadServiceProvider;
import com.payroc.api.types.PaymentOrderRequest;

public class Example {
    public static void main(String[] args) {
        PayrocApiClient client = PayrocApiClient
            .builder()
            .build();

        client.cardPayments().payments().create(
            PaymentRequest
                .builder()
                .idempotencyKey("8e03978e-40d5-43e8-bc93-6894a57f9324")
                .channel(PaymentRequestChannel.WEB)
                .processingTerminalId("1234001")
                .order(
                    PaymentOrderRequest
                        .builder()
                        .orderId("1234567890W")
                        .amount(4999L)
                        .currency(Currency.USD)
                        .description("Card Transaction (APPLE)")
                        .build()
                )
                .paymentMethod(
                    PaymentRequestPaymentMethod.digitalWallet(
                        DigitalWalletPayload
                            .builder()
                            .serviceProvider(DigitalWalletPayloadServiceProvider.APPLE)
                            .encryptedData("7b2262696c6c696e67436f6e74616374223a7b2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c227368697070696e67436f6e74616374223a7b22656d61696c41646472657373223a227465737440646f6d61696e2e636f6d222c2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c22746f6b656e223a7b227061796d656e7444617461223a7b2264617461223a2259314b37626731573479755568587473335941627a6150756c384d31795057304c724637734e2f70415950456d3871647969716c6257777356792b7732334c666c74344e6932525a684c2f6a52727563356f69496235537437763248543739682b74702f78517838496b6a5631485354594d747156644c6a413977686379774f654f70326575556d306e56386b50726569564273726a596c355931437a30576371495648595134424e737a4b5876675063686a497a6f4d4b456336425650744c7335777654667a434b51574a496a646b62516161306265685958524b422b7941773872537a6a4a476f3758523061467a414b4e70346c6f436e69484e564838373244504e4a77364b30336e544d69724b37725a615566485356754d477544473348366e4d78336c48436e6b517478764551474771754132676c416434424f427943414976483541566671655173534137776a4459702f494c6c66614e64307469467478344d6235566f6952513249387379384548547670307736667861316973613874636f484855614b32353857486474673d3d222c227369676e6174757265223a224d494147435371475349623344514548417143414d494143415145784454414c42676c67686b67425a514d45416745776741594a4b6f5a496876634e415163424141436767444343412b517767674f4c6f414d434151494343466e596f627971394f504e4d416f4743437147534d343942414d434d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730794d5441304d6a41784f544d334d444261467730794e6a41304d546b784f544d324e546c614d4749784b44416d42674e5642414d4d4832566a5979317a62584174596e4a76613256794c584e705a32356656554d304c564e42546b5243543167784644415342674e564241734d43326c505579425465584e305a57317a4d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941424949772f6176446e50646549437851325a74464575593334716b423357797a344c484e53314a6e6d506a505472336f4769576f7768354d4d39334f6a697157777661766f5a4d445263546f656b516d7a7055624570576a676749524d4949434454414d42674e5648524d4241663845416a41414d42384741315564497751594d42614146435079536352506b2b54764a2b62453969687350364b372f53354c4d45554743437347415155464277454242446b774e7a4131426767724267454642516377415959706148523063446f764c32396a633341755958427762475575593239744c32396a633341774e433168634842735a5746705932457a4d4449776767456442674e5648534145676745554d4949424544434341517747435371475349623359325146415443422f6a4342777759494b77594242515548416749776762594d67624e535a5778705957356a5a5342766269423061476c7a49474e6c636e52705a6d6c6a5958526c49474a35494746756553427759584a306553426863334e316257567a4947466a593256776447467559325567623259676447686c4948526f5a5734675958427762476c6a59574a735a53427a644746755a4746795a4342305a584a7463794268626d5167593239755a476c3061573975637942765a6942316332557349474e6c636e52705a6d6c6a5958526c4948427662476c6a65534268626d51675932567964476c6d61574e6864476c7662694277636d466a64476c6a5a53427a644746305a57316c626e527a4c6a4132426767724267454642516343415259716148523063446f764c33643364793568634842735a53356a623230765932567964476c6d61574e68644756686458526f62334a7064486b764d44514741315564487751744d4373774b61416e6f43574749326830644841364c79396a636d77755958427762475575593239744c3246776347786c59576c6a59544d7559334a734d4230474131556444675157424251434a44414c6d753774526a4758704b5a614b5a3543635949635254414f42674e56485138424166384542414d43423441774477594a4b6f5a496876646a5a415964424149464144414b42676771686b6a4f5051514441674e4841444245416942306f624d6b32304a4a517733544a307851644d53416a5a6f6653413436686358424e69566d4d6c2b386f7749676154615155367631433170532b6659415463574b725778517039594961446551344b63363042354b3259457767674c754d49494364614144416745434167684a62532b2f4f706a616c7a414b42676771686b6a4f50515144416a426e4d527377475159445651514444424a42634842735a5342536232393049454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730784e4441314d4459794d7a51324d7a4261467730794f5441314d4459794d7a51324d7a42614d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941425041584559515a31325346315270654a594548647569416f752f656536354e34493338533550684d3162565a6c733172694c516c33594e496b353775676a396468664f694d743275325a7776736a6f4b59542f5645576a6766637767665177526759494b77594242515548415145454f6a41344d4459474343734741515546427a41426869706f644852774f69387662324e7a63433568634842735a53356a6232307662324e7a634441304c5746776347786c636d397664474e685a7a4d77485159445652304f4242594546435079536352506b2b54764a2b62453969687350364b372f53354c4d41384741315564457745422f7751464d414d4241663877487759445652306a42426777466f4155753744656f56677a694a716b69706e65767233727239724c4a4b73774e77594456523066424441774c6a41736f4371674b49596d6148523063446f764c324e7962433568634842735a53356a623230765958427762475679623239305932466e4d79356a636d777744675944565230504151482f42415144416745474d42414743697147534962335932514741673445416755414d416f4743437147534d343942414d43413263414d4751434d447250636f4e5246706d78687673317731624b59722f30462b335a4433564e6f6f362b385a7942586b4b33696669593935745a6e356a56515132506e656e432f6749774d693356524347776f7756336246337a4f4475515a2f305866437768625a5a50786e4a7067684a76565068366652755a7935734a6953466842706b50435a4964414141786767474a4d4949426851494241544342686a42364d5334774c4159445651514444435642634842735a5342426348427361574e6864476c766269424a626e526c5a334a6864476c7662694244515341744945637a4d5359774a4159445651514c44423142634842735a5342445a584a3061575a7059324630615739754945463164476876636d6c30655445544d424547413155454367774b51584277624755675357356a4c6a454c4d416b474131554542684d4356564d4343466e596f627971394f504e4d417347435743475341466c41775143416143426b7a415942676b71686b69473977304243514d784377594a4b6f5a496876634e415163424d42774743537147534962334451454a42544550467730794e4445794d5449784e6a51774d5452614d43674743537147534962334451454a4e4445624d426b774377594a59495a4941575544424149426f516f4743437147534d343942414d434d43384743537147534962334451454a4244456942434335615768366c647944637435626844536b62345835494a612b576f746d6d74344a624c74386949754a6b6a414b42676771686b6a4f50515144416752494d45594349514437637561364c6430697a6148716d5371713747303433476770363467484d6b514e523577757a32736137674968414e44643730585a6639432f412b58774e716a75672b76684c39534c4c4966465159746f6745377842534c774141414141414141222c22686561646572223a7b227075626c69634b657948617368223a225542347255754d6b7044627054564b7448636a6452525a496f643465766562754d4f696b7a4156556441593d222c22657068656d6572616c5075626c69634b6579223a224d466b77457759484b6f5a497a6a3043415159494b6f5a497a6a3044415163445167414557556a70324f663878427449432f354335535349544e443554736f75564c423831464547383847504b7243394e394d753365534e72586c32636564757533552f504f53652f616f75384477556a674e6670584d7831673d3d222c227472616e73616374696f6e4964223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d2c2276657273696f6e223a2245435f7631227d2c227061796d656e744d6574686f64223a7b22646973706c61794e616d65223a224d6173746572436172642031343731222c226e6574776f726b223a224d617374657243617264222c2274797065223a226465626974227d2c227472616e73616374696f6e4964656e746966696572223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d7d")
                            .build()
                    )
                )
                .operator("Jane")
                .build()
        );
    }
}
```

```ruby Apple Pay Payment
require "payroc"

client = Payroc::Client.new

client.card_payments.payments.create(
  idempotency_key: "8e03978e-40d5-43e8-bc93-6894a57f9324",
  channel: "web",
  processing_terminal_id: "1234001",
  order: {
    order_id: "1234567890W",
    amount: 4999,
    currency: "USD",
    description: "Card Transaction (APPLE)"
  },
  operator: "Jane"
)

```

```csharp Apple Pay Payment
using Payroc;
using System.Threading.Tasks;
using Payroc.CardPayments.Payments;

namespace Usage;

public class Example
{
    public async Task Do() {
        var client = new PayrocClient();

        await client.CardPayments.Payments.CreateAsync(
            new PaymentRequest {
                IdempotencyKey = "8e03978e-40d5-43e8-bc93-6894a57f9324",
                Channel = PaymentRequestChannel.Web,
                ProcessingTerminalId = "1234001",
                Order = new PaymentOrderRequest {
                    OrderId = "1234567890W",
                    Amount = 4999L,
                    Currency = Currency.Usd,
                    Description = "Card Transaction (APPLE)"
                },
                PaymentMethod = new PaymentRequestPaymentMethod(
                    new DigitalWalletPayload {
                        EncryptedData = "7b2262696c6c696e67436f6e74616374223a7b2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c227368697070696e67436f6e74616374223a7b22656d61696c41646472657373223a227465737440646f6d61696e2e636f6d222c2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c22746f6b656e223a7b227061796d656e7444617461223a7b2264617461223a2259314b37626731573479755568587473335941627a6150756c384d31795057304c724637734e2f70415950456d3871647969716c6257777356792b7732334c666c74344e6932525a684c2f6a52727563356f69496235537437763248543739682b74702f78517838496b6a5631485354594d747156644c6a413977686379774f654f70326575556d306e56386b50726569564273726a596c355931437a30576371495648595134424e737a4b5876675063686a497a6f4d4b456336425650744c7335777654667a434b51574a496a646b62516161306265685958524b422b7941773872537a6a4a476f3758523061467a414b4e70346c6f436e69484e564838373244504e4a77364b30336e544d69724b37725a615566485356754d477544473348366e4d78336c48436e6b517478764551474771754132676c416434424f427943414976483541566671655173534137776a4459702f494c6c66614e64307469467478344d6235566f6952513249387379384548547670307736667861316973613874636f484855614b32353857486474673d3d222c227369676e6174757265223a224d494147435371475349623344514548417143414d494143415145784454414c42676c67686b67425a514d45416745776741594a4b6f5a496876634e415163424141436767444343412b517767674f4c6f414d434151494343466e596f627971394f504e4d416f4743437147534d343942414d434d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730794d5441304d6a41784f544d334d444261467730794e6a41304d546b784f544d324e546c614d4749784b44416d42674e5642414d4d4832566a5979317a62584174596e4a76613256794c584e705a32356656554d304c564e42546b5243543167784644415342674e564241734d43326c505579425465584e305a57317a4d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941424949772f6176446e50646549437851325a74464575593334716b423357797a344c484e53314a6e6d506a505472336f4769576f7768354d4d39334f6a697157777661766f5a4d445263546f656b516d7a7055624570576a676749524d4949434454414d42674e5648524d4241663845416a41414d42384741315564497751594d42614146435079536352506b2b54764a2b62453969687350364b372f53354c4d45554743437347415155464277454242446b774e7a4131426767724267454642516377415959706148523063446f764c32396a633341755958427762475575593239744c32396a633341774e433168634842735a5746705932457a4d4449776767456442674e5648534145676745554d4949424544434341517747435371475349623359325146415443422f6a4342777759494b77594242515548416749776762594d67624e535a5778705957356a5a5342766269423061476c7a49474e6c636e52705a6d6c6a5958526c49474a35494746756553427759584a306553426863334e316257567a4947466a593256776447467559325567623259676447686c4948526f5a5734675958427762476c6a59574a735a53427a644746755a4746795a4342305a584a7463794268626d5167593239755a476c3061573975637942765a6942316332557349474e6c636e52705a6d6c6a5958526c4948427662476c6a65534268626d51675932567964476c6d61574e6864476c7662694277636d466a64476c6a5a53427a644746305a57316c626e527a4c6a4132426767724267454642516343415259716148523063446f764c33643364793568634842735a53356a623230765932567964476c6d61574e68644756686458526f62334a7064486b764d44514741315564487751744d4373774b61416e6f43574749326830644841364c79396a636d77755958427762475575593239744c3246776347786c59576c6a59544d7559334a734d4230474131556444675157424251434a44414c6d753774526a4758704b5a614b5a3543635949635254414f42674e56485138424166384542414d43423441774477594a4b6f5a496876646a5a415964424149464144414b42676771686b6a4f5051514441674e4841444245416942306f624d6b32304a4a517733544a307851644d53416a5a6f6653413436686358424e69566d4d6c2b386f7749676154615155367631433170532b6659415463574b725778517039594961446551344b63363042354b3259457767674c754d49494364614144416745434167684a62532b2f4f706a616c7a414b42676771686b6a4f50515144416a426e4d527377475159445651514444424a42634842735a5342536232393049454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730784e4441314d4459794d7a51324d7a4261467730794f5441314d4459794d7a51324d7a42614d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941425041584559515a31325346315270654a594548647569416f752f656536354e34493338533550684d3162565a6c733172694c516c33594e496b353775676a396468664f694d743275325a7776736a6f4b59542f5645576a6766637767665177526759494b77594242515548415145454f6a41344d4459474343734741515546427a41426869706f644852774f69387662324e7a63433568634842735a53356a6232307662324e7a634441304c5746776347786c636d397664474e685a7a4d77485159445652304f4242594546435079536352506b2b54764a2b62453969687350364b372f53354c4d41384741315564457745422f7751464d414d4241663877487759445652306a42426777466f4155753744656f56677a694a716b69706e65767233727239724c4a4b73774e77594456523066424441774c6a41736f4371674b49596d6148523063446f764c324e7962433568634842735a53356a623230765958427762475679623239305932466e4d79356a636d777744675944565230504151482f42415144416745474d42414743697147534962335932514741673445416755414d416f4743437147534d343942414d43413263414d4751434d447250636f4e5246706d78687673317731624b59722f30462b335a4433564e6f6f362b385a7942586b4b33696669593935745a6e356a56515132506e656e432f6749774d693356524347776f7756336246337a4f4475515a2f305866437768625a5a50786e4a7067684a76565068366652755a7935734a6953466842706b50435a4964414141786767474a4d4949426851494241544342686a42364d5334774c4159445651514444435642634842735a5342426348427361574e6864476c766269424a626e526c5a334a6864476c7662694244515341744945637a4d5359774a4159445651514c44423142634842735a5342445a584a3061575a7059324630615739754945463164476876636d6c30655445544d424547413155454367774b51584277624755675357356a4c6a454c4d416b474131554542684d4356564d4343466e596f627971394f504e4d417347435743475341466c41775143416143426b7a415942676b71686b69473977304243514d784377594a4b6f5a496876634e415163424d42774743537147534962334451454a42544550467730794e4445794d5449784e6a51774d5452614d43674743537147534962334451454a4e4445624d426b774377594a59495a4941575544424149426f516f4743437147534d343942414d434d43384743537147534962334451454a4244456942434335615768366c647944637435626844536b62345835494a612b576f746d6d74344a624c74386949754a6b6a414b42676771686b6a4f50515144416752494d45594349514437637561364c6430697a6148716d5371713747303433476770363467484d6b514e523577757a32736137674968414e44643730585a6639432f412b58774e716a75672b76684c39534c4c4966465159746f6745377842534c774141414141414141222c22686561646572223a7b227075626c69634b657948617368223a225542347255754d6b7044627054564b7448636a6452525a496f643465766562754d4f696b7a4156556441593d222c22657068656d6572616c5075626c69634b6579223a224d466b77457759484b6f5a497a6a3043415159494b6f5a497a6a3044415163445167414557556a70324f663878427449432f354335535349544e443554736f75564c423831464547383847504b7243394e394d753365534e72586c32636564757533552f504f53652f616f75384477556a674e6670584d7831673d3d222c227472616e73616374696f6e4964223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d2c2276657273696f6e223a2245435f7631227d2c227061796d656e744d6574686f64223a7b22646973706c61794e616d65223a224d6173746572436172642031343731222c226e6574776f726b223a224d617374657243617264222c2274797065223a226465626974227d2c227472616e73616374696f6e4964656e746966696572223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d7d",
                        ServiceProvider = DigitalWalletPayloadServiceProvider.Apple
                    }
                ),
                Operator = "Jane"
            }
        );
    }

}

```

```go Apple Pay Payment
package main

import (
	"fmt"
	"strings"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/payments"

	payload := strings.NewReader("{\n  \"channel\": \"web\",\n  \"processingTerminalId\": \"1234001\",\n  \"order\": {\n    \"orderId\": \"1234567890W\",\n    \"amount\": 4999,\n    \"currency\": \"USD\",\n    \"description\": \"Card Transaction (APPLE)\"\n  },\n  \"paymentMethod\": {\n    \"type\": \"digitalWallet\",\n    \"encryptedData\": \"7b2262696c6c696e67436f6e74616374223a7b2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c227368697070696e67436f6e74616374223a7b22656d61696c41646472657373223a227465737440646f6d61696e2e636f6d222c2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c22746f6b656e223a7b227061796d656e7444617461223a7b2264617461223a2259314b37626731573479755568587473335941627a6150756c384d31795057304c724637734e2f70415950456d3871647969716c6257777356792b7732334c666c74344e6932525a684c2f6a52727563356f69496235537437763248543739682b74702f78517838496b6a5631485354594d747156644c6a413977686379774f654f70326575556d306e56386b50726569564273726a596c355931437a30576371495648595134424e737a4b5876675063686a497a6f4d4b456336425650744c7335777654667a434b51574a496a646b62516161306265685958524b422b7941773872537a6a4a476f3758523061467a414b4e70346c6f436e69484e564838373244504e4a77364b30336e544d69724b37725a615566485356754d477544473348366e4d78336c48436e6b517478764551474771754132676c416434424f427943414976483541566671655173534137776a4459702f494c6c66614e64307469467478344d6235566f6952513249387379384548547670307736667861316973613874636f484855614b32353857486474673d3d222c227369676e6174757265223a224d494147435371475349623344514548417143414d494143415145784454414c42676c67686b67425a514d45416745776741594a4b6f5a496876634e415163424141436767444343412b517767674f4c6f414d434151494343466e596f627971394f504e4d416f4743437147534d343942414d434d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730794d5441304d6a41784f544d334d444261467730794e6a41304d546b784f544d324e546c614d4749784b44416d42674e5642414d4d4832566a5979317a62584174596e4a76613256794c584e705a32356656554d304c564e42546b5243543167784644415342674e564241734d43326c505579425465584e305a57317a4d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941424949772f6176446e50646549437851325a74464575593334716b423357797a344c484e53314a6e6d506a505472336f4769576f7768354d4d39334f6a697157777661766f5a4d445263546f656b516d7a7055624570576a676749524d4949434454414d42674e5648524d4241663845416a41414d42384741315564497751594d42614146435079536352506b2b54764a2b62453969687350364b372f53354c4d45554743437347415155464277454242446b774e7a4131426767724267454642516377415959706148523063446f764c32396a633341755958427762475575593239744c32396a633341774e433168634842735a5746705932457a4d4449776767456442674e5648534145676745554d4949424544434341517747435371475349623359325146415443422f6a4342777759494b77594242515548416749776762594d67624e535a5778705957356a5a5342766269423061476c7a49474e6c636e52705a6d6c6a5958526c49474a35494746756553427759584a306553426863334e316257567a4947466a593256776447467559325567623259676447686c4948526f5a5734675958427762476c6a59574a735a53427a644746755a4746795a4342305a584a7463794268626d5167593239755a476c3061573975637942765a6942316332557349474e6c636e52705a6d6c6a5958526c4948427662476c6a65534268626d51675932567964476c6d61574e6864476c7662694277636d466a64476c6a5a53427a644746305a57316c626e527a4c6a4132426767724267454642516343415259716148523063446f764c33643364793568634842735a53356a623230765932567964476c6d61574e68644756686458526f62334a7064486b764d44514741315564487751744d4373774b61416e6f43574749326830644841364c79396a636d77755958427762475575593239744c3246776347786c59576c6a59544d7559334a734d4230474131556444675157424251434a44414c6d753774526a4758704b5a614b5a3543635949635254414f42674e56485138424166384542414d43423441774477594a4b6f5a496876646a5a415964424149464144414b42676771686b6a4f5051514441674e4841444245416942306f624d6b32304a4a517733544a307851644d53416a5a6f6653413436686358424e69566d4d6c2b386f7749676154615155367631433170532b6659415463574b725778517039594961446551344b63363042354b3259457767674c754d49494364614144416745434167684a62532b2f4f706a616c7a414b42676771686b6a4f50515144416a426e4d527377475159445651514444424a42634842735a5342536232393049454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730784e4441314d4459794d7a51324d7a4261467730794f5441314d4459794d7a51324d7a42614d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941425041584559515a31325346315270654a594548647569416f752f656536354e34493338533550684d3162565a6c733172694c516c33594e496b353775676a396468664f694d743275325a7776736a6f4b59542f5645576a6766637767665177526759494b77594242515548415145454f6a41344d4459474343734741515546427a41426869706f644852774f69387662324e7a63433568634842735a53356a6232307662324e7a634441304c5746776347786c636d397664474e685a7a4d77485159445652304f4242594546435079536352506b2b54764a2b62453969687350364b372f53354c4d41384741315564457745422f7751464d414d4241663877487759445652306a42426777466f4155753744656f56677a694a716b69706e65767233727239724c4a4b73774e77594456523066424441774c6a41736f4371674b49596d6148523063446f764c324e7962433568634842735a53356a623230765958427762475679623239305932466e4d79356a636d777744675944565230504151482f42415144416745474d42414743697147534962335932514741673445416755414d416f4743437147534d343942414d43413263414d4751434d447250636f4e5246706d78687673317731624b59722f30462b335a4433564e6f6f362b385a7942586b4b33696669593935745a6e356a56515132506e656e432f6749774d693356524347776f7756336246337a4f4475515a2f305866437768625a5a50786e4a7067684a76565068366652755a7935734a6953466842706b50435a4964414141786767474a4d4949426851494241544342686a42364d5334774c4159445651514444435642634842735a5342426348427361574e6864476c766269424a626e526c5a334a6864476c7662694244515341744945637a4d5359774a4159445651514c44423142634842735a5342445a584a3061575a7059324630615739754945463164476876636d6c30655445544d424547413155454367774b51584277624755675357356a4c6a454c4d416b474131554542684d4356564d4343466e596f627971394f504e4d417347435743475341466c41775143416143426b7a415942676b71686b69473977304243514d784377594a4b6f5a496876634e415163424d42774743537147534962334451454a42544550467730794e4445794d5449784e6a51774d5452614d43674743537147534962334451454a4e4445624d426b774377594a59495a4941575544424149426f516f4743437147534d343942414d434d43384743537147534962334451454a4244456942434335615768366c647944637435626844536b62345835494a612b576f746d6d74344a624c74386949754a6b6a414b42676771686b6a4f50515144416752494d45594349514437637561364c6430697a6148716d5371713747303433476770363467484d6b514e523577757a32736137674968414e44643730585a6639432f412b58774e716a75672b76684c39534c4c4966465159746f6745377842534c774141414141414141222c22686561646572223a7b227075626c69634b657948617368223a225542347255754d6b7044627054564b7448636a6452525a496f643465766562754d4f696b7a4156556441593d222c22657068656d6572616c5075626c69634b6579223a224d466b77457759484b6f5a497a6a3043415159494b6f5a497a6a3044415163445167414557556a70324f663878427449432f354335535349544e443554736f75564c423831464547383847504b7243394e394d753365534e72586c32636564757533552f504f53652f616f75384477556a674e6670584d7831673d3d222c227472616e73616374696f6e4964223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d2c2276657273696f6e223a2245435f7631227d2c227061796d656e744d6574686f64223a7b22646973706c61794e616d65223a224d6173746572436172642031343731222c226e6574776f726b223a224d617374657243617264222c2274797065223a226465626974227d2c227472616e73616374696f6e4964656e746966696572223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d7d\",\n    \"serviceProvider\": \"apple\"\n  },\n  \"operator\": \"Jane\"\n}")

	req, _ := http.NewRequest("POST", url, payload)

	req.Header.Add("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324")
	req.Header.Add("Authorization", "Bearer <token>")
	req.Header.Add("Content-Type", "application/json")

	res, _ := http.DefaultClient.Do(req)

	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)

	fmt.Println(res)
	fmt.Println(string(body))

}
```

```php Apple Pay Payment
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('POST', 'https://api.payroc.com/v1/payments', [
  'body' => '{
  "channel": "web",
  "processingTerminalId": "1234001",
  "order": {
    "orderId": "1234567890W",
    "amount": 4999,
    "currency": "USD",
    "description": "Card Transaction (APPLE)"
  },
  "paymentMethod": {
    "type": "digitalWallet",
    "encryptedData": "7b2262696c6c696e67436f6e74616374223a7b2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c227368697070696e67436f6e74616374223a7b22656d61696c41646472657373223a227465737440646f6d61696e2e636f6d222c2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c22746f6b656e223a7b227061796d656e7444617461223a7b2264617461223a2259314b37626731573479755568587473335941627a6150756c384d31795057304c724637734e2f70415950456d3871647969716c6257777356792b7732334c666c74344e6932525a684c2f6a52727563356f69496235537437763248543739682b74702f78517838496b6a5631485354594d747156644c6a413977686379774f654f70326575556d306e56386b50726569564273726a596c355931437a30576371495648595134424e737a4b5876675063686a497a6f4d4b456336425650744c7335777654667a434b51574a496a646b62516161306265685958524b422b7941773872537a6a4a476f3758523061467a414b4e70346c6f436e69484e564838373244504e4a77364b30336e544d69724b37725a615566485356754d477544473348366e4d78336c48436e6b517478764551474771754132676c416434424f427943414976483541566671655173534137776a4459702f494c6c66614e64307469467478344d6235566f6952513249387379384548547670307736667861316973613874636f484855614b32353857486474673d3d222c227369676e6174757265223a224d494147435371475349623344514548417143414d494143415145784454414c42676c67686b67425a514d45416745776741594a4b6f5a496876634e415163424141436767444343412b517767674f4c6f414d434151494343466e596f627971394f504e4d416f4743437147534d343942414d434d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730794d5441304d6a41784f544d334d444261467730794e6a41304d546b784f544d324e546c614d4749784b44416d42674e5642414d4d4832566a5979317a62584174596e4a76613256794c584e705a32356656554d304c564e42546b5243543167784644415342674e564241734d43326c505579425465584e305a57317a4d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941424949772f6176446e50646549437851325a74464575593334716b423357797a344c484e53314a6e6d506a505472336f4769576f7768354d4d39334f6a697157777661766f5a4d445263546f656b516d7a7055624570576a676749524d4949434454414d42674e5648524d4241663845416a41414d42384741315564497751594d42614146435079536352506b2b54764a2b62453969687350364b372f53354c4d45554743437347415155464277454242446b774e7a4131426767724267454642516377415959706148523063446f764c32396a633341755958427762475575593239744c32396a633341774e433168634842735a5746705932457a4d4449776767456442674e5648534145676745554d4949424544434341517747435371475349623359325146415443422f6a4342777759494b77594242515548416749776762594d67624e535a5778705957356a5a5342766269423061476c7a49474e6c636e52705a6d6c6a5958526c49474a35494746756553427759584a306553426863334e316257567a4947466a593256776447467559325567623259676447686c4948526f5a5734675958427762476c6a59574a735a53427a644746755a4746795a4342305a584a7463794268626d5167593239755a476c3061573975637942765a6942316332557349474e6c636e52705a6d6c6a5958526c4948427662476c6a65534268626d51675932567964476c6d61574e6864476c7662694277636d466a64476c6a5a53427a644746305a57316c626e527a4c6a4132426767724267454642516343415259716148523063446f764c33643364793568634842735a53356a623230765932567964476c6d61574e68644756686458526f62334a7064486b764d44514741315564487751744d4373774b61416e6f43574749326830644841364c79396a636d77755958427762475575593239744c3246776347786c59576c6a59544d7559334a734d4230474131556444675157424251434a44414c6d753774526a4758704b5a614b5a3543635949635254414f42674e56485138424166384542414d43423441774477594a4b6f5a496876646a5a415964424149464144414b42676771686b6a4f5051514441674e4841444245416942306f624d6b32304a4a517733544a307851644d53416a5a6f6653413436686358424e69566d4d6c2b386f7749676154615155367631433170532b6659415463574b725778517039594961446551344b63363042354b3259457767674c754d49494364614144416745434167684a62532b2f4f706a616c7a414b42676771686b6a4f50515144416a426e4d527377475159445651514444424a42634842735a5342536232393049454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730784e4441314d4459794d7a51324d7a4261467730794f5441314d4459794d7a51324d7a42614d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941425041584559515a31325346315270654a594548647569416f752f656536354e34493338533550684d3162565a6c733172694c516c33594e496b353775676a396468664f694d743275325a7776736a6f4b59542f5645576a6766637767665177526759494b77594242515548415145454f6a41344d4459474343734741515546427a41426869706f644852774f69387662324e7a63433568634842735a53356a6232307662324e7a634441304c5746776347786c636d397664474e685a7a4d77485159445652304f4242594546435079536352506b2b54764a2b62453969687350364b372f53354c4d41384741315564457745422f7751464d414d4241663877487759445652306a42426777466f4155753744656f56677a694a716b69706e65767233727239724c4a4b73774e77594456523066424441774c6a41736f4371674b49596d6148523063446f764c324e7962433568634842735a53356a623230765958427762475679623239305932466e4d79356a636d777744675944565230504151482f42415144416745474d42414743697147534962335932514741673445416755414d416f4743437147534d343942414d43413263414d4751434d447250636f4e5246706d78687673317731624b59722f30462b335a4433564e6f6f362b385a7942586b4b33696669593935745a6e356a56515132506e656e432f6749774d693356524347776f7756336246337a4f4475515a2f305866437768625a5a50786e4a7067684a76565068366652755a7935734a6953466842706b50435a4964414141786767474a4d4949426851494241544342686a42364d5334774c4159445651514444435642634842735a5342426348427361574e6864476c766269424a626e526c5a334a6864476c7662694244515341744945637a4d5359774a4159445651514c44423142634842735a5342445a584a3061575a7059324630615739754945463164476876636d6c30655445544d424547413155454367774b51584277624755675357356a4c6a454c4d416b474131554542684d4356564d4343466e596f627971394f504e4d417347435743475341466c41775143416143426b7a415942676b71686b69473977304243514d784377594a4b6f5a496876634e415163424d42774743537147534962334451454a42544550467730794e4445794d5449784e6a51774d5452614d43674743537147534962334451454a4e4445624d426b774377594a59495a4941575544424149426f516f4743437147534d343942414d434d43384743537147534962334451454a4244456942434335615768366c647944637435626844536b62345835494a612b576f746d6d74344a624c74386949754a6b6a414b42676771686b6a4f50515144416752494d45594349514437637561364c6430697a6148716d5371713747303433476770363467484d6b514e523577757a32736137674968414e44643730585a6639432f412b58774e716a75672b76684c39534c4c4966465159746f6745377842534c774141414141414141222c22686561646572223a7b227075626c69634b657948617368223a225542347255754d6b7044627054564b7448636a6452525a496f643465766562754d4f696b7a4156556441593d222c22657068656d6572616c5075626c69634b6579223a224d466b77457759484b6f5a497a6a3043415159494b6f5a497a6a3044415163445167414557556a70324f663878427449432f354335535349544e443554736f75564c423831464547383847504b7243394e394d753365534e72586c32636564757533552f504f53652f616f75384477556a674e6670584d7831673d3d222c227472616e73616374696f6e4964223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d2c2276657273696f6e223a2245435f7631227d2c227061796d656e744d6574686f64223a7b22646973706c61794e616d65223a224d6173746572436172642031343731222c226e6574776f726b223a224d617374657243617264222c2274797065223a226465626974227d2c227472616e73616374696f6e4964656e746966696572223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d7d",
    "serviceProvider": "apple"
  },
  "operator": "Jane"
}',
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```swift Apple Pay Payment
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]
let parameters = [
  "channel": "web",
  "processingTerminalId": "1234001",
  "order": [
    "orderId": "1234567890W",
    "amount": 4999,
    "currency": "USD",
    "description": "Card Transaction (APPLE)"
  ],
  "paymentMethod": [
    "type": "digitalWallet",
    "encryptedData": "7b2262696c6c696e67436f6e74616374223a7b2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c227368697070696e67436f6e74616374223a7b22656d61696c41646472657373223a227465737440646f6d61696e2e636f6d222c2266616d696c794e616d65223a22222c22676976656e4e616d65223a22222c2270686f6e6574696346616d696c794e616d65223a22222c2270686f6e65746963476976656e4e616d65223a22227d2c22746f6b656e223a7b227061796d656e7444617461223a7b2264617461223a2259314b37626731573479755568587473335941627a6150756c384d31795057304c724637734e2f70415950456d3871647969716c6257777356792b7732334c666c74344e6932525a684c2f6a52727563356f69496235537437763248543739682b74702f78517838496b6a5631485354594d747156644c6a413977686379774f654f70326575556d306e56386b50726569564273726a596c355931437a30576371495648595134424e737a4b5876675063686a497a6f4d4b456336425650744c7335777654667a434b51574a496a646b62516161306265685958524b422b7941773872537a6a4a476f3758523061467a414b4e70346c6f436e69484e564838373244504e4a77364b30336e544d69724b37725a615566485356754d477544473348366e4d78336c48436e6b517478764551474771754132676c416434424f427943414976483541566671655173534137776a4459702f494c6c66614e64307469467478344d6235566f6952513249387379384548547670307736667861316973613874636f484855614b32353857486474673d3d222c227369676e6174757265223a224d494147435371475349623344514548417143414d494143415145784454414c42676c67686b67425a514d45416745776741594a4b6f5a496876634e415163424141436767444343412b517767674f4c6f414d434151494343466e596f627971394f504e4d416f4743437147534d343942414d434d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730794d5441304d6a41784f544d334d444261467730794e6a41304d546b784f544d324e546c614d4749784b44416d42674e5642414d4d4832566a5979317a62584174596e4a76613256794c584e705a32356656554d304c564e42546b5243543167784644415342674e564241734d43326c505579425465584e305a57317a4d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941424949772f6176446e50646549437851325a74464575593334716b423357797a344c484e53314a6e6d506a505472336f4769576f7768354d4d39334f6a697157777661766f5a4d445263546f656b516d7a7055624570576a676749524d4949434454414d42674e5648524d4241663845416a41414d42384741315564497751594d42614146435079536352506b2b54764a2b62453969687350364b372f53354c4d45554743437347415155464277454242446b774e7a4131426767724267454642516377415959706148523063446f764c32396a633341755958427762475575593239744c32396a633341774e433168634842735a5746705932457a4d4449776767456442674e5648534145676745554d4949424544434341517747435371475349623359325146415443422f6a4342777759494b77594242515548416749776762594d67624e535a5778705957356a5a5342766269423061476c7a49474e6c636e52705a6d6c6a5958526c49474a35494746756553427759584a306553426863334e316257567a4947466a593256776447467559325567623259676447686c4948526f5a5734675958427762476c6a59574a735a53427a644746755a4746795a4342305a584a7463794268626d5167593239755a476c3061573975637942765a6942316332557349474e6c636e52705a6d6c6a5958526c4948427662476c6a65534268626d51675932567964476c6d61574e6864476c7662694277636d466a64476c6a5a53427a644746305a57316c626e527a4c6a4132426767724267454642516343415259716148523063446f764c33643364793568634842735a53356a623230765932567964476c6d61574e68644756686458526f62334a7064486b764d44514741315564487751744d4373774b61416e6f43574749326830644841364c79396a636d77755958427762475575593239744c3246776347786c59576c6a59544d7559334a734d4230474131556444675157424251434a44414c6d753774526a4758704b5a614b5a3543635949635254414f42674e56485138424166384542414d43423441774477594a4b6f5a496876646a5a415964424149464144414b42676771686b6a4f5051514441674e4841444245416942306f624d6b32304a4a517733544a307851644d53416a5a6f6653413436686358424e69566d4d6c2b386f7749676154615155367631433170532b6659415463574b725778517039594961446551344b63363042354b3259457767674c754d49494364614144416745434167684a62532b2f4f706a616c7a414b42676771686b6a4f50515144416a426e4d527377475159445651514444424a42634842735a5342536232393049454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a4165467730784e4441314d4459794d7a51324d7a4261467730794f5441314d4459794d7a51324d7a42614d486f784c6a417342674e5642414d4d4a5546776347786c4945467763477870593246306157397549456c756447566e636d46306157397549454e4249433067527a4d784a6a416b42674e564241734d485546776347786c49454e6c636e52705a6d6c6a59585270623234675158563061473979615852354d524d77455159445651514b44417042634842735a53424a626d4d754d517377435159445651514745774a56557a425a4d424d4742797147534d34394167454743437147534d34394177454841304941425041584559515a31325346315270654a594548647569416f752f656536354e34493338533550684d3162565a6c733172694c516c33594e496b353775676a396468664f694d743275325a7776736a6f4b59542f5645576a6766637767665177526759494b77594242515548415145454f6a41344d4459474343734741515546427a41426869706f644852774f69387662324e7a63433568634842735a53356a6232307662324e7a634441304c5746776347786c636d397664474e685a7a4d77485159445652304f4242594546435079536352506b2b54764a2b62453969687350364b372f53354c4d41384741315564457745422f7751464d414d4241663877487759445652306a42426777466f4155753744656f56677a694a716b69706e65767233727239724c4a4b73774e77594456523066424441774c6a41736f4371674b49596d6148523063446f764c324e7962433568634842735a53356a623230765958427762475679623239305932466e4d79356a636d777744675944565230504151482f42415144416745474d42414743697147534962335932514741673445416755414d416f4743437147534d343942414d43413263414d4751434d447250636f4e5246706d78687673317731624b59722f30462b335a4433564e6f6f362b385a7942586b4b33696669593935745a6e356a56515132506e656e432f6749774d693356524347776f7756336246337a4f4475515a2f305866437768625a5a50786e4a7067684a76565068366652755a7935734a6953466842706b50435a4964414141786767474a4d4949426851494241544342686a42364d5334774c4159445651514444435642634842735a5342426348427361574e6864476c766269424a626e526c5a334a6864476c7662694244515341744945637a4d5359774a4159445651514c44423142634842735a5342445a584a3061575a7059324630615739754945463164476876636d6c30655445544d424547413155454367774b51584277624755675357356a4c6a454c4d416b474131554542684d4356564d4343466e596f627971394f504e4d417347435743475341466c41775143416143426b7a415942676b71686b69473977304243514d784377594a4b6f5a496876634e415163424d42774743537147534962334451454a42544550467730794e4445794d5449784e6a51774d5452614d43674743537147534962334451454a4e4445624d426b774377594a59495a4941575544424149426f516f4743437147534d343942414d434d43384743537147534962334451454a4244456942434335615768366c647944637435626844536b62345835494a612b576f746d6d74344a624c74386949754a6b6a414b42676771686b6a4f50515144416752494d45594349514437637561364c6430697a6148716d5371713747303433476770363467484d6b514e523577757a32736137674968414e44643730585a6639432f412b58774e716a75672b76684c39534c4c4966465159746f6745377842534c774141414141414141222c22686561646572223a7b227075626c69634b657948617368223a225542347255754d6b7044627054564b7448636a6452525a496f643465766562754d4f696b7a4156556441593d222c22657068656d6572616c5075626c69634b6579223a224d466b77457759484b6f5a497a6a3043415159494b6f5a497a6a3044415163445167414557556a70324f663878427449432f354335535349544e443554736f75564c423831464547383847504b7243394e394d753365534e72586c32636564757533552f504f53652f616f75384477556a674e6670584d7831673d3d222c227472616e73616374696f6e4964223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d2c2276657273696f6e223a2245435f7631227d2c227061796d656e744d6574686f64223a7b22646973706c61794e616d65223a224d6173746572436172642031343731222c226e6574776f726b223a224d617374657243617264222c2274797065223a226465626974227d2c227472616e73616374696f6e4964656e746966696572223a2231363431326566383238303362633133356338333165396235663732376432366165623661616130363364633138353861313562323734386666346636333739227d7d",
    "serviceProvider": "apple"
  ],
  "operator": "Jane"
] as [String : Any]

let postData = JSONSerialization.data(withJSONObject: parameters, options: [])

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/payments")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "POST"
request.allHTTPHeaderFields = headers
request.httpBody = postData as Data

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
  if (error != nil) {
    print(error as Any)
  } else {
    let httpResponse = response as? HTTPURLResponse
    print(httpResponse)
  }
})

dataTask.resume()
```

### Response fields

If your request is successful, our gateway uses the card details to run a sale. The response contains the following fields:

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /payments:
    post:
      operationId: create
      summary: Create payment
      description: "Use this method to run a sale or a pre-authorization with a customer's payment card. \n\nIn the response, our gateway returns information about the card payment and a paymentId, which you need for the following methods:\n\n-\t[Retrieve payment](https://docs.payroc.com/api/schema/card-payments/payments/retrieve) - View the details of the card payment.\n-\t[Adjust payment](https://docs.payroc.com/api/schema/card-payments/payments/adjust) - Update the details of the card payment.\n-\t[Capture payment](https://docs.payroc.com/api/schema/card-payments/payments/capture)  - Capture the pre-authorization.\n-\t[Reverse payment](https://docs.payroc.com/api/schema/card-payments/refunds/reverse)  - Cancel the card payment if it's in an open batch.\n-\t[Refund payment](https://docs.payroc.com/api/schema/card-payments/refunds/create-referenced-refund)  - Run a referenced refund to return funds to the payment card.\n\n**Payment methods** \n\n- **Cards** - Credit, debit, and EBT\n- **Digital wallets** - [Apple Pay®](https://docs.payroc.com/guides/take-payments/apple-pay) and [Google Pay®](https://docs.payroc.com/guides/take-payments/google-pay) \n- **Tokens** - Secure tokens and single-use tokens\n\n**Features** \n\nOur Create Payment method also supports the following features: \n\n- [Repeat payments](https://docs.payroc.com/guides/take-payments/repeat-payments/use-your-own-software) - Run multiple payments as part of a payment schedule that you manage with your own software. \n- **Offline sales** - Run a sale or a pre-authorization if the terminal loses its connection to our gateway. \n- [Tokenization](https://docs.payroc.com/guides/take-payments/save-payment-details) - Save card details to use in future transactions. \n- [3-D Secure](https://docs.payroc.com/guides/take-payments/3-d-secure) - Verify the identity of the cardholder. \n- [Custom fields](https://docs.payroc.com/guides/take-payments/add-custom-fields) - Add your own data to a payment. \n- **Tips** - Add tips to the card payment.  \n- **Taxes** - Add local taxes to the card payment. \n- **Surcharging** - Add a surcharge to the card payment. \n- **Dual pricing** - Offer different prices based on payment method, for example, if you use our RewardPay Choice pricing program. \n- **Healthcare** - Accept payments from Health Savings Accounts (HSA) and Flexible Spending Accounts (FSA). \n"
      tags:
        - subpackage_cardPayments.subpackage_cardPayments/payments
      parameters:
        - name: Idempotency-Key
          in: header
          description: >-
            Unique identifier that you generate for each request. You must use
            the [UUID v4 format](https://www.rfc-editor.org/rfc/rfc4122) for the
            identifier. For more information about the idempotency key, go to
            [Idempotency](https://docs.payroc.com/api/idempotency).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '201':
          description: Successful request. We processed the transaction.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/payment'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '401':
          description: Identity could not be verified
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/401'
        '403':
          description: Do not have permissions to perform this action
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/403'
        '406':
          description: Not acceptable
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/406'
        '409':
          description: Conflict
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/409'
        '415':
          description: Unsupported media type
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/415'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/paymentRequest'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '401':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '401'
    '403':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path the action was attempted on
        resource:
          type: string
          description: Resource the action was attempted on
      required:
        - type
        - title
        - status
        - detail
      title: '403'
    '406':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '406'
    '409':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path to the existing resource
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
        link:
          $ref: '#/components/schemas/link'
      required:
        - type
        - title
        - status
        - detail
      title: '409'
    '415':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '415'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    PaymentRequestChannel:
      type: string
      enum:
        - pos
        - web
        - moto
      description: Channel that the merchant used to receive the payment details.
      title: PaymentRequestChannel
    currency:
      type: string
      enum:
        - AED
        - AFN
        - ALL
        - AMD
        - ANG
        - AOA
        - ARS
        - AUD
        - AWG
        - AZN
        - BAM
        - BBD
        - BDT
        - BGN
        - BHD
        - BIF
        - BMD
        - BND
        - BOB
        - BOV
        - BRL
        - BSD
        - BTN
        - BWP
        - BYR
        - BZD
        - CAD
        - CDF
        - CHE
        - CHF
        - CHW
        - CLF
        - CLP
        - CNY
        - COP
        - COU
        - CRC
        - CUC
        - CUP
        - CVE
        - CZK
        - DJF
        - DKK
        - DOP
        - DZD
        - EGP
        - ERN
        - ETB
        - EUR
        - FJD
        - FKP
        - GBP
        - GEL
        - GHS
        - GIP
        - GMD
        - GNF
        - GTQ
        - GYD
        - HKD
        - HNL
        - HRK
        - HTG
        - HUF
        - IDR
        - ILS
        - INR
        - IQD
        - IRR
        - ISK
        - JMD
        - JOD
        - JPY
        - KES
        - KGS
        - KHR
        - KMF
        - KPW
        - KRW
        - KWD
        - KYD
        - KZT
        - LAK
        - LBP
        - LKR
        - LRD
        - LSL
        - LTL
        - LVL
        - LYD
        - MAD
        - MDL
        - MGA
        - MKD
        - MMK
        - MNT
        - MOP
        - MRO
        - MRU
        - MUR
        - MVR
        - MWK
        - MXN
        - MXV
        - MYR
        - MZN
        - NAD
        - NGN
        - NIO
        - NOK
        - NPR
        - NZD
        - OMR
        - PAB
        - PEN
        - PGK
        - PHP
        - PKR
        - PLN
        - PYG
        - QAR
        - RON
        - RSD
        - RUB
        - RWF
        - SAR
        - SBD
        - SCR
        - SDG
        - SEK
        - SGD
        - SHP
        - SLL
        - SOS
        - SRD
        - SSP
        - STD
        - STN
        - SVC
        - SYP
        - SZL
        - THB
        - TJS
        - TMT
        - TND
        - TOP
        - TRY
        - TTD
        - TWD
        - TZS
        - UAH
        - UGX
        - USD
        - USN
        - USS
        - UYI
        - UYU
        - UZS
        - VEF
        - VES
        - VND
        - VUV
        - WST
        - XAF
        - XCD
        - XOF
        - XPF
        - YER
        - ZAR
        - ZMW
        - ZWL
      description: >-
        Currency of the transaction. The value for the currency follows the [ISO
        4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
      title: currency
    dccOffer:
      type: object
      properties:
        accepted:
          type: boolean
          description: Indicates if the cardholder accepted DCC offer.
        offerReference:
          type: string
          description: Unique identifier of the DCC offer.
        fxAmount:
          type: integer
          format: int64
          description: >-
            Amount in the cardholder’s currency in the currency’s lowest
            denomination, for example, cents.
        fxCurrency:
          $ref: '#/components/schemas/currency'
          description: >-
            Currency of the transaction in the card’s currency. The value for
            the currency follows the [ISO
            4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
        fxCurrencyCode:
          type: string
          description: >-
            Three-digit currency code for the card. This code follows the [ISO
            4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
        fxCurrencyExponent:
          type: integer
          description: >
            Number of decimal places between the smallest currency unit and a
            whole currency unit. 


            For example, for GBP, the smallest currency unit is 1p and it is
            equal to £0.01. 

            If you use GBP, the value for **fxCurrencyExponent** is 2.
        fxRate:
          type: number
          format: double
          description: Foreign exchange rate for the card's currency.
        markup:
          type: number
          format: double
          description: >-
            Markup percentage rate that the DCC provider applies to the foreign
            exchange rate.
        markupText:
          type: string
          description: Supporting text for the markup rate.
        provider:
          type: string
          description: Name of the DCC provider.
        source:
          type: string
          description: Source that the DCC provider used to get the foreign exchange rates.
      required:
        - fxAmount
        - fxCurrency
        - fxRate
        - markup
      description: >
        Object that contains information about the dynamic currency conversion
        (DCC) offer.  
          
        For more information about DCC, go to [Dynamic Currency
        Conversion](https://docs.payroc.com/knowledge/card-payments/dynamic-currency-conversion).
      title: dccOffer
    StandingInstructionsSequence:
      type: string
      enum:
        - first
        - subsequent
      description: Position of the transaction in the payment plan sequence.
      title: StandingInstructionsSequence
    StandingInstructionsProcessingModel:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      description: >
        Indicates the type of payment instruction.


        - 'unscheduled' – The payment is not part of a regular billing cycle.

        - 'recurring' – The payment is part of a regular billing cycle with no
        end date.

        - 'installment' – The payment is part of a regular billing cycle with an
        end date.
      title: StandingInstructionsProcessingModel
    firstTxnReferenceData:
      type: object
      properties:
        paymentId:
          type: string
          description: >
            Unique identifier of the first payment.  

            **Note:** We recommend that you always send a value for
            **paymentId**.
        cardSchemeReferenceId:
          type: string
          description: Identifier that the card brand assigns to the payment instruction.
      description: >-
        Object that contains information about the initial payment for the
        payment instruction.
      title: firstTxnReferenceData
    standingInstructions:
      type: object
      properties:
        sequence:
          $ref: '#/components/schemas/StandingInstructionsSequence'
          description: Position of the transaction in the payment plan sequence.
        processingModel:
          $ref: '#/components/schemas/StandingInstructionsProcessingModel'
          description: >
            Indicates the type of payment instruction.


            - 'unscheduled' – The payment is not part of a regular billing
            cycle.

            - 'recurring' – The payment is part of a regular billing cycle with
            no end date.

            - 'installment' – The payment is part of a regular billing cycle
            with an end date.
        referenceDataOfFirstTxn:
          $ref: '#/components/schemas/firstTxnReferenceData'
          description: >-
            Object that contains information about the initial payment for the
            payment instruction.
      required:
        - sequence
        - processingModel
      description: >-
        If you don't use our Subscriptions mechanism, include this section to
        configure your standing/recurring orders.
      title: standingInstructions
    TipType:
      type: string
      enum:
        - percentage
        - fixedAmount
      description: >
        Indicates if the tip is a fixed amount or a percentage.  

        **Note:** Our gateway applies the percentage tip to the total amount of
        the transaction after tax.
      title: TipType
    TipMode:
      type: string
      enum:
        - prompted
        - adjusted
      description: >
        Indicates how the tip was added to the transaction.

        - `prompted` – The customer was prompted to add a tip during payment.

        - `adjusted` – The customer added a tip on the receipt for the merchant
        to adjust post-transaction.
      title: TipMode
    tip:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/TipType'
          description: >
            Indicates if the tip is a fixed amount or a percentage.  

            **Note:** Our gateway applies the percentage tip to the total amount
            of the transaction after tax.
        mode:
          $ref: '#/components/schemas/TipMode'
          description: >
            Indicates how the tip was added to the transaction.

            - `prompted` – The customer was prompted to add a tip during
            payment.

            - `adjusted` – The customer added a tip on the receipt for the
            merchant to adjust post-transaction.
        amount:
          type: integer
          format: int64
          description: >
            If the value for type is `fixedAmount`, this value is the tip amount
            in the currency's lowest denomination, for example,
            cents.            
        percentage:
          type: number
          format: double
          description: >-
            If the value for type is `percentage`, this value is the tip as a
            percentage.
      required:
        - type
      description: Object that contains information about the tip.
      title: tip
    surcharge:
      type: object
      properties:
        bypass:
          type: boolean
          description: >
            Indicates if the merchant wants to remove the surcharge fee from the
            transaction.  

            - `true` - Gateway removes the surcharge fee from the transaction.  

            - `false` - Gateway adds the fee to the transaction.   
        amount:
          type: integer
          format: int64
          description: >
            If the merchant added a surcharge fee, this value indicates the
            amount of the surcharge fee

            in the currency’s lowest denomination, for example, cents.
        percentage:
          type: number
          format: double
          description: >-
            If the merchant added a surcharge fee, this value indicates the
            surcharge percentage.
      description: |
        Object that contains information about the surcharge.
      title: surcharge
    choiceRate:
      type: object
      properties:
        applied:
          type: boolean
          default: false
          description: >
            Indicates if the merchant applies a choice rate to the transaction
            amount. 


            Our gateway adds a choice rate to the transaction when the merchant
            offers an alternative payment type, but the customer chooses to pay
            by card.
        rate:
          type: number
          format: double
          description: >
            If the customer used a card to pay for the transaction, this value
            indicates the percentage that our gateway added to the transaction
            amount.  

            **Note:** Our gateway returns a value for **rate** only if the value
            for **applied** in the request is `true`.
        amount:
          type: integer
          format: int64
          description: >
            If the customer used a card to pay for the transaction, this value
            indicates the amount that our gateway added to the transaction
            amount. This value is in the currency’s lowest denomination, for
            example, cents.  

            **Note:** Our gateway returns a value for **amount** only if the
            value for **applied** in the request is `true`.
      required:
        - applied
        - rate
        - amount
      description: >
        Object that contains information about the choice rate. We return this
        only if the value for offered was `true`.
      title: choiceRate
    DualPricingAlternativeTender:
      type: string
      enum:
        - card
        - cash
        - bankTransfer
      description: >
        Payment method that the merchant presented to the customer as an
        alternative to their chosen method.  

        **Note:** For requests, if the value for **offered** is `true`, you must
        send a value for **alternativeTender** in the request.
      title: DualPricingAlternativeTender
    dualPricing:
      type: object
      properties:
        offered:
          type: boolean
          description: Indicates if the merchant offered dual pricing to the customer.
        choiceRate:
          $ref: '#/components/schemas/choiceRate'
          description: >
            Object that contains information about the choice rate.  

            **Note:** For requests, if the value for **offered** is `true`, you
            must send this object in the request.
        alternativeTender:
          $ref: '#/components/schemas/DualPricingAlternativeTender'
          description: >
            Payment method that the merchant presented to the customer as an
            alternative to their chosen method.  

            **Note:** For requests, if the value for **offered** is `true`, you
            must send a value for **alternativeTender** in the request.
      required:
        - offered
      description: Object that contains information about dual pricing.
      title: dualPricing
    HealthcareExpenseType:
      type: string
      enum:
        - copay
        - clinic
        - dental
        - prescription
        - transit
        - vision
      description: Type of healthcare expense.
      title: HealthcareExpenseType
    healthcareExpense:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/HealthcareExpenseType'
          description: Type of healthcare expense.
        amount:
          type: integer
          format: int64
          description: >-
            Amount of the healthcare expense. The value is in the currency's
            lowest denomination, for example, cents.
      required:
        - type
        - amount
      description: Object that contains information about a healthcare expense.
      title: healthcareExpense
    tax:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - amount
              description: 'Discriminator value: amount'
            amount:
              type: integer
              format: int64
              description: >-
                Tax amount for the transaction. The value is in the currency's
                lowest denomination, for example, cents.
            name:
              type: string
              description: Name of the tax.
          required:
            - type
            - amount
            - name
          description: amount variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - rate
              description: 'Discriminator value: rate'
            rate:
              type: number
              format: double
              description: Tax percentage for the transaction.
            name:
              type: string
              description: >-
                Name of the tax. A tax validation on the stored rate for the tax
                name is performed.
          required:
            - type
            - rate
            - name
          description: rate variant
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains tax details.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`amount` - Tax is a fixed amount.\n-\t`rate` - Tax is a percentage.\n"
      title: tax
    convenienceFee:
      type: object
      properties:
        amount:
          type: integer
          format: int64
          description: >
            If the merchant added a convenience fee, this value indicates the
            amount of the convenience fee

            in the currency’s lowest denomination, for example, cents.
      required:
        - amount
      description: >-
        Object that contains information about the convenience fee for the
        transaction.
      title: convenienceFee
    unitOfMeasure:
      type: string
      enum:
        - ACR
        - AMH
        - AMP
        - APZ
        - ARE
        - ASM
        - ASV
        - ATM
        - ATT
        - BAR
        - BFT
        - BHP
        - BHX
        - BIL
        - BLD
        - BLL
        - BQL
        - BTU
        - BUA
        - BUI
        - BX
        - CCT
        - CDL
        - CEL
        - CEN
        - CGM
        - CKG
        - CLF
        - CLT
        - CMK
        - CMT
        - CNP
        - CNT
        - COU
        - CS
        - CTM
        - CUR
        - CWA
        - DAA
        - DAD
        - DAY
        - DEC
        - DLT
        - DMK
        - DMQ
        - DMT
        - DPC
        - DPT
        - DRA
        - DRI
        - DRL
        - DRM
        - DTH
        - DTN
        - DWT
        - DZN
        - DZP
        - DZR
        - EA
        - EAC
        - FAH
        - FAR
        - FOT
        - FTK
        - FTQ
        - GBQ
        - GFI
        - GGR
        - GII
        - GLD
        - GLI
        - GLL
        - GRM
        - GRN
        - GRO
        - GRT
        - GWH
        - HAR
        - HBA
        - HGM
        - HIU
        - HLT
        - HMQ
        - HMT
        - HPA
        - HTZ
        - HUR
        - INH
        - INK
        - INQ
        - ITM
        - JOU
        - KBA
        - KEL
        - KGM
        - KGS
        - KHZ
        - KJO
        - KMH
        - KMK
        - KMQ
        - KMT
        - KNI
        - KNS
        - KNT
        - KPA
        - KPH
        - KPO
        - KPP
        - KSD
        - KSH
        - KTN
        - KUR
        - KVA
        - KVR
        - KVT
        - KWH
        - KWT
        - LBR
        - LBS
        - LEF
        - LPA
        - LTN
        - LTR
        - LUM
        - LUX
        - MAL
        - MAM
        - MAW
        - MBE
        - MBF
        - MBR
        - MCU
        - MGM
        - MHZ
        - MIK
        - MIL
        - MIN
        - MIO
        - MIU
        - MLD
        - MLT
        - MMK
        - MMQ
        - MMT
        - MON
        - MPA
        - MQH
        - MQS
        - MSK
        - MTK
        - MTQ
        - MTR
        - MTS
        - MVA
        - MWH
        - NAR
        - NBB
        - NCL
        - NEW
        - NIU
        - NMB
        - NMI
        - NMP
        - NMR
        - NPL
        - NPT
        - NRL
        - NTT
        - OHM
        - ONZ
        - OZA
        - OZI
        - PAL
        - PCB
        - PCE
        - PGL
        - PK
        - PSC
        - PTD
        - PTI
        - PTL
        - QAN
        - QTD
        - QTI
        - QTL
        - QTR
        - RPM
        - RPS
        - SAN
        - SCO
        - SCR
        - SEC
        - SET
        - SHT
        - SIE
        - SMI
        - SST
        - ST
        - STI
        - TAH
        - TNE
        - TPR
        - TQD
        - TRL
        - TSD
        - TSH
        - VLT
        - WCD
        - WEB
        - WEE
        - WHR
        - WSD
        - WTT
        - YDK
        - YDQ
      description: >-
        Unit of measurement for the item. For more information about units of
        measurement, go to [Units of
        measurement](https://docs.payroc.com/knowledge/basic-concepts/units-of-measurement).
      title: unitOfMeasure
    lineItemRequest:
      type: object
      properties:
        commodityCode:
          type: string
          description: Commodity code of the item.
        productCode:
          type: string
          description: Product code of the item.
        description:
          type: string
          description: Description of the item.
        unitOfMeasure:
          $ref: '#/components/schemas/unitOfMeasure'
        unitPrice:
          type: integer
          format: int64
          description: Price of each unit.
        quantity:
          type: number
          format: double
          description: Number of units.
        discountRate:
          type: number
          format: double
          description: Discount rate that the merchant applies to the item.
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/tax'
          description: >-
            Array of objects that contain information about each tax that
            applies to the item.
      required:
        - unitPrice
        - quantity
      description: List of line items.
      title: lineItemRequest
    itemizedBreakdownRequest:
      type: object
      properties:
        subtotal:
          type: integer
          format: int64
          description: >-
            Amount of the transaction before tax and fees. The value is in the
            currency’s lowest denomination, for example, cents.
        cashbackAmount:
          type: integer
          format: int64
          description: Amount of cashback for the transaction.
        tip:
          $ref: '#/components/schemas/tip'
          description: Object that contains tip information for the transaction.
        surcharge:
          $ref: '#/components/schemas/surcharge'
          description: Object that contains surcharge information for the transaction.
        dualPricing:
          $ref: '#/components/schemas/dualPricing'
          description: Object that contains dual pricing information for the transaction.
        healthcareExpenses:
          type: array
          items:
            $ref: '#/components/schemas/healthcareExpense'
          description: >-
            Array of healthcareExpense objects that contain information about
            healthcare expenses.
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/tax'
          description: "Array of polymorphic tax objects, which contain information about a tax.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`amount` - Tax is a fixed amount.\n-\t`rate` - Tax is a percentage.\n"
        dutyAmount:
          type: integer
          format: int64
          description: >
            Amount of duties or fees that apply to the order. The value is in
            the currency's lowest denomination, for example, cents. 
        freightAmount:
          type: integer
          format: int64
          description: >
            Amount for shipping in the currency's lowest denomination, for
            example, cents.
        convenienceFee:
          $ref: '#/components/schemas/convenienceFee'
        items:
          type: array
          items:
            $ref: '#/components/schemas/lineItemRequest'
          description: >-
            Array of objects that contain information about each item that the
            customer purchased.
      required:
        - subtotal
      description: Object that contains information about the breakdown of the transaction.
      title: itemizedBreakdownRequest
    paymentOrderRequest:
      type: object
      properties:
        orderId:
          type: string
          description: A unique identifier assigned by the merchant.
        dateTime:
          type: string
          format: date-time
          description: >-
            Date and time that the processor processed the transaction. Our
            gateway returns this value in the ISO 8601 format.
        description:
          type: string
          description: Description of the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction. The value is in the currency’s
            lowest denomination, for example, cents.
        currency:
          $ref: '#/components/schemas/currency'
        dccOffer:
          $ref: '#/components/schemas/dccOffer'
        standingInstructions:
          $ref: '#/components/schemas/standingInstructions'
        acceptPartialAmount:
          type: boolean
          default: false
          description: >
            Indicates if the merchant accepts a partial authorization for this
            payment. The value is one of the following:


            - `true` - If the cardholder doesn't have the full amount available
            in their account, our gateway processes a partial payment.

            - `false` - If the cardholder doesn't have the full amount available
            in their account, our gateway declines the payment.
        breakdown:
          $ref: '#/components/schemas/itemizedBreakdownRequest'
      required:
        - orderId
        - amount
        - currency
      description: Object that contains information about the payment.
      title: paymentOrderRequest
    address:
      type: object
      properties:
        address1:
          type: string
          description: Address line 1.
        address2:
          type: string
          description: Address line 2.
        address3:
          type: string
          description: Address line 3.
        city:
          type: string
          description: City.
        state:
          type: string
          description: Name of the state or state abbreviation.
        country:
          type: string
          description: >-
            Two-digit country code for the country that the business operates
            in. The format follows the
            [ISO-3166-1](https://www.iso.org/iso-3166-country-codes.html)
            standard.
        postalCode:
          type: string
          description: Zip code or postal code.
      required:
        - address1
        - city
        - state
        - country
        - postalCode
      description: Object that contains information about the address.
      title: address
    shipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/address'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: shipping
    contactMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - email
              description: 'Discriminator value: email'
            value:
              type: string
              description: Email address.
          required:
            - type
            - value
          description: email variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - phone
              description: 'Discriminator value: phone'
            value:
              type: string
              description: Phone number.
          required:
            - type
            - value
          description: phone variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - mobile
              description: 'Discriminator value: mobile'
            value:
              type: string
              description: Mobile number.
          required:
            - type
            - value
          description: mobile variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - fax
              description: 'Discriminator value: fax'
            value:
              type: string
              description: Fax number.
          required:
            - type
            - value
          description: fax variant
      discriminator:
        propertyName: type
      title: contactMethod
    CustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: CustomerNotificationLanguage
    customer:
      type: object
      properties:
        firstName:
          type: string
          description: Customer's first name.
        lastName:
          type: string
          description: Customer's last name.
        dateOfBirth:
          type: string
          format: date
          description: >-
            Customer's date of birth. The format for this value is
            **YYYY-MM-DD**.
        referenceNumber:
          type: string
          description: >
            Identifier of the transaction, also known as a customer code. 


            For requests, you must send a value for **referenceNumber** if the
            customer provides one. 
        billingAddress:
          $ref: '#/components/schemas/address'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/shipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/CustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: customer
    IpAddressType:
      type: string
      enum:
        - ipv4
        - ipv6
      description: Internet protocol version of the IP address.
      title: IpAddressType
    ipAddress:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/IpAddressType'
          description: Internet protocol version of the IP address.
        value:
          type: string
          description: IP address of the device.
      required:
        - type
        - value
      description: Object that contains the IP address of the device that sent the request.
      title: ipAddress
    FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** Send a value for accountType only for bank account details.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method.

        For example, an Integrated Circuit Card (ICC) transaction can be
        downgraded to a swiped transaction or to a keyed transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo
    DeviceModel:
      type: string
      enum:
        - bbposChp
        - bbposChp2x
        - bbposChp3x
        - bbposRambler
        - bbposWp
        - bbposWp2
        - bbposWp3
        - genericCtlsMsr
        - genericMsr
        - idtechAugusta
        - idtechMinismart
        - idtechSredkey
        - idtechVp3300
        - idtechVp5300
        - idtechVp6300
        - idtechVp6800
        - ingenicoAxiumDx4000
        - ingenicoAxiumDx8000
        - ingenicoAxiumEx8000
        - ingenicoIct220
        - ingenicoIpp320
        - ingenicoIpp350
        - ingenicoIuc285
        - ingenicoL3000
        - ingenicoL7000
        - ingenicoS2000
        - ingenicoS3000
        - ingenicoS4000
        - ingenicoS5000
        - ingenicoS7000
        - paxA80
        - paxA920
        - paxA920Pro
        - paxA920Max
        - paxE500
        - paxE700
        - paxE800
        - paxIm30
        - uic680
        - uicBezel8
      description: Model of the device that the merchant used to process the transaction.
      title: DeviceModel
    DeviceCategory:
      type: string
      enum:
        - attended
        - unattended
      default: attended
      description: Indicates if the device is attended or unattended.
      title: DeviceCategory
    deviceConfig:
      type: object
      properties:
        quickChip:
          type: boolean
          default: false
          description: Indicates if Quick Chip mode is active on a merchant’s POS terminal.
      required:
        - quickChip
      description: >-
        Object that contains information about the configuration of the POS
        terminal.
      title: deviceConfig
    device:
      type: object
      properties:
        model:
          $ref: '#/components/schemas/DeviceModel'
          description: >-
            Model of the device that the merchant used to process the
            transaction.
        category:
          $ref: '#/components/schemas/DeviceCategory'
          default: attended
          description: Indicates if the device is attended or unattended.
        serialNumber:
          type: string
          description: Serial number of the physical device.
        firmwareVersion:
          type: string
          description: Firmware version of the physical device.
        config:
          $ref: '#/components/schemas/deviceConfig'
      required:
        - model
        - serialNumber
      description: >-
        Object that contains information about the physical device the merchant
        used to capture the customer’s card details.
      title: device
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method. 

        For example, an Integrated Circuit Card (ICC) transaction can be
        downgraded to a swiped transaction or a keyed transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo
    EncryptionCapableDeviceModel:
      type: string
      enum:
        - bbposChp
        - bbposChp2x
        - bbposChp3x
        - bbposRambler
        - bbposWp
        - bbposWp2
        - bbposWp3
        - genericCtlsMsr
        - genericMsr
        - idtechAugusta
        - idtechMinismart
        - idtechSredkey
        - idtechVp3300
        - idtechVp5300
        - idtechVp6300
        - idtechVp6800
        - ingenicoAxiumDx4000
        - ingenicoAxiumDx8000
        - ingenicoAxiumEx8000
        - ingenicoIct220
        - ingenicoIpp320
        - ingenicoIpp350
        - ingenicoIuc285
        - ingenicoL3000
        - ingenicoL7000
        - ingenicoS2000
        - ingenicoS3000
        - ingenicoS4000
        - ingenicoS5000
        - ingenicoS7000
        - paxA80
        - paxA920
        - paxA920Pro
        - paxA920Max
        - paxE500
        - paxE700
        - paxE800
        - paxIm30
        - uic680
        - uicBezel8
      description: Model of the device that the merchant used to process the transaction.
      title: EncryptionCapableDeviceModel
    EncryptionCapableDeviceCategory:
      type: string
      enum:
        - attended
        - unattended
      default: attended
      description: Indicates if the device is attended or unattended.
      title: EncryptionCapableDeviceCategory
    encryptionCapableDevice:
      type: object
      properties:
        model:
          $ref: '#/components/schemas/EncryptionCapableDeviceModel'
          description: >-
            Model of the device that the merchant used to process the
            transaction.
        category:
          $ref: '#/components/schemas/EncryptionCapableDeviceCategory'
          default: attended
          description: Indicates if the device is attended or unattended.
        serialNumber:
          type: string
          description: Serial number of the physical device.
        firmwareVersion:
          type: string
          description: Firmware version of the physical device.
        config:
          $ref: '#/components/schemas/deviceConfig'
        dataKsn:
          type: string
          format: hexadecimal
          description: Key serial number.
      required:
        - model
        - serialNumber
        - dataKsn
      description: >-
        Object that contains information about the encryption details of the POS
        terminal.
      title: encryptionCapableDevice
    EbtDetailsWithVoucherBenefitCategory:
      type: string
      enum:
        - cash
        - foodStamp
      description: >
        Indicates if the balance relates to an EBT Cash account or an EBT SNAP
        account.  
         - `cash` – EBT Cash  
         - `foodStamp` – EBT SNAP
      title: EbtDetailsWithVoucherBenefitCategory
    voucher:
      type: object
      properties:
        approvalCode:
          type: string
          description: Authorization code that the processor issued for the transaction.
        serialNumber:
          type: string
          description: Serial number of the voucher.
      required:
        - approvalCode
        - serialNumber
      description: |
        Object that contains information about the EBT voucher.  

        **Note:** Vouchers are available only for EBT SNAP payments.
      title: voucher
    ebtDetailsWithVoucher:
      type: object
      properties:
        benefitCategory:
          $ref: '#/components/schemas/EbtDetailsWithVoucherBenefitCategory'
          description: >
            Indicates if the balance relates to an EBT Cash account or an EBT
            SNAP account.  
             - `cash` – EBT Cash  
             - `foodStamp` – EBT SNAP
        withdrawal:
          type: boolean
          description: >
            Indicates whether the customer wants to withdraw cash.  


            **Note:** Cash withdrawals are available only from EBT Cash
            accounts.
        voucher:
          $ref: '#/components/schemas/voucher'
      required:
        - benefitCategory
      description: >-
        Object that contains information about the Electronic Benefit Transfer
        (EBT) transaction.
      title: ebtDetailsWithVoucher
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - fullyEncrypted
              description: 'Discriminator value: fullyEncrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedData:
              type: string
              format: hexadecimal
              description: Encrypted card data.
            firstDigitOfPan:
              type: string
              description: First digit of the customer’s card number.
          required:
            - dataFormat
            - device
            - encryptedData
          description: >-
            Object that contains information about the encrypted card data for
            keyed transactions.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - partiallyEncrypted
              description: 'Discriminator value: partiallyEncrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedPan:
              type: string
              format: hexadecimal
              description: Encrypted card number.
            maskedPan:
              type: string
              description: >
                Masked card number. 

                The gateway shows only the first six digits and the last four
                digits of the account number. For example, `453985******7062`.
            expiryDate:
              type: string
              description: Expiry date of the customer’s card.
            cvv:
              type: string
              description: Security code of the customer’s card.
            cvvEncrypted:
              type: string
              format: hexadecimal
              description: Encrypted security code data.
            issueNumber:
              type: string
              description: Issue number of the customer’s card.
          required:
            - dataFormat
            - device
            - encryptedPan
            - maskedPan
            - expiryDate
          description: >-
            Object that contains information about the partially-encrypted card
            data for keyed transactions.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - plainText
              description: 'Discriminator value: plainText'
            device:
              $ref: '#/components/schemas/device'
            cardNumber:
              type: string
              description: Customer’s card number.
            expiryDate:
              type: string
              description: >
                Expiry date of the customer’s card.  

                **Note:** We require you to send an expiry date for most BIN
                lookups and electronic voucher transactions.
            cvv:
              type: string
              description: Security code of the customer’s card.
            issueNumber:
              type: string
              description: Issue number of the customer’s card.
          required:
            - dataFormat
            - cardNumber
          description: >-
            Object that contains information about the plain-text card data for
            keyed transactions.
      discriminator:
        propertyName: dataFormat
      description: "Polymorphic object that contains payment card details that the merchant manually entered into the device.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`fullyEncrypted` - All payment card details are encrypted.\n-\t`partiallyEncrypted` - Some payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: Polymorphic object that contains information about the customer's PIN.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method. 

        For example, a swiped transaction can be downgraded to a keyed
        transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason:
      type: string
      enum:
        - technical
        - repeatFallback
        - emptyCandidateList
      description: Reason for the fallback.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason:
      type: string
      enum:
        - technical
        - repeatFallback
        - emptyCandidateList
      description: Reason for the fallback.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - encrypted
              description: 'Discriminator value: encrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedData:
              type: string
              format: hexadecimal
              description: Encrypted data received from the magnetic stripe reader.
            firstDigitOfPan:
              type: string
              description: First digit of the of the card number.
            fallback:
              type: boolean
              description: >-
                Indicates that this is a fallback transaction. For example, if
                there was a technical issue with the chip on the customer's card
                and the merchant then swiped the card.
            fallbackReason:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason
              description: Reason for the fallback.
          required:
            - dataFormat
            - device
            - encryptedData
          description: >-
            Object that contains information about the encrypted swiped card
            data.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - plainText
              description: 'Discriminator value: plainText'
            device:
              $ref: '#/components/schemas/device'
            trackData:
              type: string
              description: Customer’s card data from the swiped transaction.
            fallback:
              type: boolean
              description: >-
                Indicates that this is a fallback transaction. For example, if
                there was a technical issue with the chip on the customer's card
                and the merchant then swiped the card.
            fallbackReason:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason
              description: Reason for the fallback.
          required:
            - dataFormat
            - device
            - trackData
          description: Object that contains information about plain-text swiped card data.
      discriminator:
        propertyName: dataFormat
      description: "Polymorphic object that contains payment card details that a device captured from the magnetic strip.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`encrypted` - Payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: Polymorphic object that contains information about the customer's PIN.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails:
      oneOf:
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - raw
              description: 'Discriminator value: raw'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method.

                For example, an Integrated Circuit Card (ICC) transaction can be
                downgraded to a swiped transaction or to a keyed transaction.
            device:
              $ref: '#/components/schemas/device'
            rawData:
              type: string
              format: hexadecimal
              description: Unencrypted data from the POS terminal.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
          required:
            - entryMethod
            - device
            - rawData
          description: Object that contains information about the unencrypted card details.
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - icc
              description: 'Discriminator value: icc'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method. 

                For example, an Integrated Circuit Card (ICC) transaction can be
                downgraded to a swiped transaction or a keyed transaction.
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            iccData:
              type: string
              format: hexadecimal
              description: >-
                Cardholder data from the ICC. The data consists of EMV tags in
                Tag-Length-Value (TLV) format.
            firstDigitOfPan:
              type: string
              description: First digit of the card number.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - device
            - iccData
          description: >-
            Object that contains information about the Integrated Circuit Card
            (ICC).
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - keyed
              description: 'Discriminator value: keyed'
            keyedData:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData
              description: "Polymorphic object that contains payment card details that the merchant manually entered into the device.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`fullyEncrypted` - All payment card details are encrypted.\n-\t`partiallyEncrypted` - Some payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
            cardholderName:
              type: string
              description: Cardholder’s name.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            pinDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails
              description: >-
                Polymorphic object that contains information about the
                customer's PIN.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - keyedData
          description: Object that contains information about the keyed card details.
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - swiped
              description: 'Discriminator value: swiped'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method. 

                For example, a swiped transaction can be downgraded to a keyed
                transaction.
            swipedData:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData
              description: "Polymorphic object that contains payment card details that a device captured from the magnetic strip.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`encrypted` - Payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
            cardholderName:
              type: string
              description: Cardholder’s name.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            pinDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails
              description: >-
                Polymorphic object that contains information about the
                customer's PIN.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - swipedData
          description: >-
            Object that contains information about the customer’s card details
            for swiped transactions.
      discriminator:
        propertyName: entryMethod
      description: >
        Polymorphic object that contains payment card information.  


        The value of the entryMethod parameter determines which variant you
        should use:  

        - `raw` - Unencrypted payment data directly from the device.

        - `icc` - Payment data that the device captured from the chip.

        - `keyed` - Payment data that the merchant entered manually.

        - `swiped` - Payment data that the device captured from the magnetic
        strip.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails
    BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenAccountType:
      type: string
      enum:
        - checking
        - savings
      description: >
        Indicates the customer’s account type.  


        **Note:** Send a value for accountType only if the secure token
        represents bank account details.
      title: >-
        BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenAccountType
    BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: >
        Indicates how the customer authorized the ACH transaction. Send one of
        the following values:


        - `web` – Online transaction.

        - `tel` – Telephone transaction.

        - `ccd` – Corporate credit card or debit card transaction.

        - `ppd` – Pre-arranged transaction.


        **Note:** This field is mandatory when the secure token represents ACH
        bank account details.
      title: >-
        BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenSecCode
    FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** Send a value for accountType only for bank account details.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletAccountType
    FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletServiceProvider:
      type: string
      enum:
        - apple
        - google
      description: >
        Provider of the digital wallet. Send one of the following values:

        - `apple` - For more information about how to integrate with Apple Pay,
        go to [Apple
        Pay®](https://docs.payroc.com/guides/take-payments/apple-pay).

        - `google` - For more information about how to integrate with google
        Pay, go to [Google
        Pay®](https://docs.payroc.com/guides/take-payments/google-pay).
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletServiceProvider
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType:
      type: string
      enum:
        - checking
        - savings
      description: >
        Indicates the customer’s account type.  


        **Note:** Send a value for accountType only if the single-use token
        represents bank account details.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - raw
              description: 'Discriminator value: raw'
            pin:
              type: string
              description: Customer’s unencrypted PIN.
          required:
            - dataFormat
            - pin
          description: Object that contains information about the unencrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: >
        Polymorphic object that contains information about a customer's PIN.  


        The value of the dataFormat parameter determines which variant you
        should use:  

        - `dukpt` - PIN information is encrypted.

        - `raw` - PIN information is unencrypted.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: >
        Indicates how the customer authorized the ACH transaction. Send one of
        the following values:


        - `web` – Online transaction.

        - `tel` – Telephone transaction.

        - `ccd` – Corporate credit card or debit card transaction.

        - `ppd` – Pre-arranged transaction.


        **Note:** This field is mandatory when the single-use token represents
        ACH bank account details.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode
    PaymentRequestPaymentMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - card
              description: 'Discriminator value: card'
            accountType:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only for bank account
                details.
            cardDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails
              description: >
                Polymorphic object that contains payment card information.  


                The value of the entryMethod parameter determines which variant
                you should use:  

                - `raw` - Unencrypted payment data directly from the device.

                - `icc` - Payment data that the device captured from the chip.

                - `keyed` - Payment data that the merchant entered manually.

                - `swiped` - Payment data that the device captured from the
                magnetic strip.
          required:
            - type
            - cardDetails
          description: Object that contains information about the customer’s payment card.
        - type: object
          properties:
            type:
              type: string
              enum:
                - secureToken
              description: 'Discriminator value: secureToken'
            accountType:
              $ref: >-
                #/components/schemas/BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only if the secure token
                represents bank account details.
            token:
              type: string
              description: Unique token that the gateway assigned to the payment details.
            secCode:
              $ref: >-
                #/components/schemas/BankTransferUnreferencedRefundRefundMethodDiscriminatorMappingSecureTokenSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory when the secure token
                represents ACH bank account details.
          required:
            - type
            - token
          description: >-
            Object that contains information about the secure token that
            represents the customer’s payment details.
        - type: object
          properties:
            type:
              type: string
              enum:
                - digitalWallet
              description: 'Discriminator value: digitalWallet'
            accountType:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only for bank account
                details.
            serviceProvider:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingDigitalWalletServiceProvider
              description: >
                Provider of the digital wallet. Send one of the following
                values:

                - `apple` - For more information about how to integrate with
                Apple Pay, go to [Apple
                Pay®](https://docs.payroc.com/guides/take-payments/apple-pay).

                - `google` - For more information about how to integrate with
                google Pay, go to [Google
                Pay®](https://docs.payroc.com/guides/take-payments/google-pay).
            cardholderName:
              type: string
              description: Cardholder’s name.
            encryptedData:
              type: string
              description: Encrypted data of the digital wallet.
          required:
            - type
            - serviceProvider
            - encryptedData
          description: >-
            Object that contains information about the payment details in the
            customer’s digital wallet.
        - type: object
          properties:
            type:
              type: string
              enum:
                - singleUseToken
              description: 'Discriminator value: singleUseToken'
            accountType:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only if the single-use
                token represents bank account details.
            token:
              type: string
              description: Unique token that the gateway assigned to the payment details.
            pinDetails:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails
              description: >
                Polymorphic object that contains information about a customer's
                PIN.  


                The value of the dataFormat parameter determines which variant
                you should use:  

                - `dukpt` - PIN information is encrypted.

                - `raw` - PIN information is unencrypted.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
            secCode:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory when the single-use token
                represents ACH bank account details.
          required:
            - type
            - token
          description: >-
            Object that contains information about the single-use token, which
            represents the customer’s payment details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains payment details.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`card` - Payment card details\n-\t`secureToken` - Secure token details\n-\t`digitalWallet` - Digital wallet details\n-\t`singleUseToken` - Single-use token details\n"
      title: PaymentRequestPaymentMethod
    PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci:
      type: string
      enum:
        - fullyAuthenticated
        - attemptedAuthentication
      description: E-commerce indicator (ECI) result of a the 3-D Secure check.
      title: PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci
    PaymentRequestThreeDSecure:
      oneOf:
        - type: object
          properties:
            serviceProvider:
              type: string
              enum:
                - gateway
              description: 'Discriminator value: gateway'
            mpiReference:
              type: string
              description: >-
                Reference that our gateway assigned to the 3-D Secure
                authentication response.
          required:
            - serviceProvider
            - mpiReference
          description: Object that contains the 3-D Secure information from our gateway.
        - type: object
          properties:
            serviceProvider:
              type: string
              enum:
                - thirdParty
              description: 'Discriminator value: thirdParty'
            eci:
              $ref: >-
                #/components/schemas/PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci
              description: E-commerce indicator (ECI) result of a the 3-D Secure check.
            xid:
              type: string
              description: >-
                Unique transaction identifier that the merchant assigned to the
                transaction and sent in the authentication request.
            cavv:
              type: string
              description: >-
                Cardholder Authentication Verification Value (CAVV) that the
                card issuer provided to prove that they authorized the online
                payment.
            dsTransactionId:
              type: string
              description: >-
                Directory Server Transaction ID that the processor assigned to
                the request.
          required:
            - serviceProvider
            - eci
          description: Object that contains the 3-D Secure information from a third party.
      discriminator:
        propertyName: serviceProvider
      description: "Polymorphic object that contains authentication information from 3-D Secure.  \n\nThe value of the serviceProvider parameter determines which variant you should use:  \n-\t`gateway` - Use our gateway to run a 3-D Secure check.\n-\t`thirdParty` - Use a third party to run a 3-D Secure check.\n"
      title: PaymentRequestThreeDSecure
    SchemasCredentialOnFileMitAgreement:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      description: >
        Indicates how the merchant can use the customer’s card details, as
        agreed by the customer:  


        - `unscheduled` - Transactions for a fixed or variable amount that are
        run at a certain pre-defined event.  

        - `recurring` - Transactions for a fixed amount that are run at regular
        intervals, for example, monthly. Recurring transactions don’t have a
        fixed duration and run until the customer cancels the agreement.  

        - `installment` - Transactions for a fixed amount that are run at
        regular intervals, for example, monthly. Installment transactions have a
        fixed duration.  
          
        **Note:** If you send a value for **mitAgreement**, you must send the
        **standingInstructions** object in the **paymentOrder** object.
      title: SchemasCredentialOnFileMitAgreement
    schemas-credentialOnFile:
      type: object
      properties:
        externalVault:
          type: boolean
          default: false
          description: >-
            Indicates if the merchant uses a third-party vault to store the
            customer’s payment details.
        tokenize:
          type: boolean
          description: >-
            Indicates if our gateway should tokenize the customer’s payment
            details as part of the transaction.
        secureTokenId:
          type: string
          description: >
            Unique identifier that the merchant creates for the secure token
            that represents the customer’s payment details.  

            **Note:** If you do not send a value for the **secureTokenId**, our
            gateway generates a unique identifier for the token.
        mitAgreement:
          $ref: '#/components/schemas/SchemasCredentialOnFileMitAgreement'
          description: >
            Indicates how the merchant can use the customer’s card details, as
            agreed by the customer:  


            - `unscheduled` - Transactions for a fixed or variable amount that
            are run at a certain pre-defined event.  

            - `recurring` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Recurring transactions
            don’t have a fixed duration and run until the customer cancels the
            agreement.  

            - `installment` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Installment transactions
            have a fixed duration.  
              
            **Note:** If you send a value for **mitAgreement**, you must send
            the **standingInstructions** object in the **paymentOrder** object.
      description: >-
        Object that contains information about saving the customer’s payment
        details.
      title: schemas-credentialOnFile
    OfflineProcessingOperation:
      type: string
      enum:
        - offlineDecline
        - offlineApproval
        - deferredAuthorization
      description: Status of the transaction.
      title: OfflineProcessingOperation
    offlineProcessing:
      type: object
      properties:
        operation:
          $ref: '#/components/schemas/OfflineProcessingOperation'
          description: Status of the transaction.
        approvalCode:
          type: string
          description: Approval code for the transaction from the processor.
        dateTime:
          type: string
          format: date-time
          description: >-
            Date and time that the merchant ran the transaction. The date
            follows the ISO 8601 standard.
      required:
        - operation
      description: >-
        Object that contains information about the transaction if the merchant
        ran it when the terminal was offline.
      title: offlineProcessing
    customField:
      type: object
      properties:
        name:
          type: string
          description: Name of the custom field.
        value:
          type: string
          description: Value for the custom field.
      required:
        - name
        - value
      title: customField
    paymentRequest:
      type: object
      properties:
        channel:
          $ref: '#/components/schemas/PaymentRequestChannel'
          description: Channel that the merchant used to receive the payment details.
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        operator:
          type: string
          description: Operator who ran the transaction.
        order:
          $ref: '#/components/schemas/paymentOrderRequest'
        customer:
          $ref: '#/components/schemas/customer'
        ipAddress:
          $ref: '#/components/schemas/ipAddress'
        paymentMethod:
          $ref: '#/components/schemas/PaymentRequestPaymentMethod'
          description: "Polymorphic object that contains payment details.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`card` - Payment card details\n-\t`secureToken` - Secure token details\n-\t`digitalWallet` - Digital wallet details\n-\t`singleUseToken` - Single-use token details\n"
        threeDSecure:
          $ref: '#/components/schemas/PaymentRequestThreeDSecure'
          description: "Polymorphic object that contains authentication information from 3-D Secure.  \n\nThe value of the serviceProvider parameter determines which variant you should use:  \n-\t`gateway` - Use our gateway to run a 3-D Secure check.\n-\t`thirdParty` - Use a third party to run a 3-D Secure check.\n"
        credentialOnFile:
          $ref: '#/components/schemas/schemas-credentialOnFile'
        offlineProcessing:
          $ref: '#/components/schemas/offlineProcessing'
        autoCapture:
          type: boolean
          default: true
          description: >
            Indicates if we should automatically capture the payment amount.  


            - `true` - Run a sale and automatically capture the transaction.

            - `false`- Run a pre-authorization and capture the transaction
            later.  
              
            **Note:** If you send `false` and the terminal doesn't support
            pre-authorization, we set the transaction's status to pending. The
            merchant must capture the transaction to take payment from the
            customer.
        processAsSale:
          type: boolean
          default: false
          description: >
            Indicates if we should immediately settle the sale transaction. The
            merchant cannot adjust the transaction if we immediately settle
            it.  


            **Note:** If the value for **processAsSale** is `true`, the gateway
            ignores the value in **autoCapture**.
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - channel
        - processingTerminalId
        - order
        - paymentMethod
      title: paymentRequest
    retrievedTax:
      type: object
      properties:
        name:
          type: string
          description: Name of the tax.
        rate:
          type: number
          format: double
          description: Tax percentage for the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            Amount of tax that was applied to the transaction. The value is in
            the currency's lowest denomination, for example, cents.
      required:
        - name
        - rate
      title: retrievedTax
    lineItem:
      type: object
      properties:
        commodityCode:
          type: string
          description: Commodity code of the item.
        productCode:
          type: string
          description: Product code of the item.
        description:
          type: string
          description: Description of the item.
        unitOfMeasure:
          $ref: '#/components/schemas/unitOfMeasure'
        unitPrice:
          type: integer
          format: int64
          description: Price of each unit.
        quantity:
          type: number
          format: double
          description: Number of units.
        discountRate:
          type: number
          format: double
          description: Discount rate that the merchant applies to the item.
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/retrievedTax'
          description: >-
            Array of objects that contain information about each tax that
            applies to the item.
      required:
        - unitPrice
        - quantity
      description: List of line items.
      title: lineItem
    itemizedBreakdown:
      type: object
      properties:
        subtotal:
          type: integer
          format: int64
          description: >-
            Amount of the transaction before tax and fees. The value is in the
            currency’s lowest denomination, for example, cents.
        cashbackAmount:
          type: integer
          format: int64
          description: Amount of cashback for the transaction.
        tip:
          $ref: '#/components/schemas/tip'
          description: Object that contains tip information for the transaction.
        surcharge:
          $ref: '#/components/schemas/surcharge'
          description: Object that contains surcharge information for the transaction.
        dualPricing:
          $ref: '#/components/schemas/dualPricing'
          description: Object that contains dual pricing information for the transaction.
        healthcareExpenses:
          type: array
          items:
            $ref: '#/components/schemas/healthcareExpense'
          description: >-
            Array of healthcareExpense objects that contain information about
            healthcare expenses.
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/retrievedTax'
          description: List of taxes.
        dutyAmount:
          type: integer
          format: int64
          description: >
            Amount of duties or fees that apply to the order. The value is in
            the currency's lowest denomination, for example, cents. 
        freightAmount:
          type: integer
          format: int64
          description: >
            Amount for shipping in the currency's lowest denomination, for
            example, cents.
        convenienceFee:
          $ref: '#/components/schemas/convenienceFee'
        items:
          type: array
          items:
            $ref: '#/components/schemas/lineItem'
          description: >-
            Array of objects that contain information about each item that the
            customer purchased.
      required:
        - subtotal
      description: Object that contains information about the breakdown of the transaction.
      title: itemizedBreakdown
    paymentOrder:
      type: object
      properties:
        orderId:
          type: string
          description: A unique identifier assigned by the merchant.
        dateTime:
          type: string
          format: date-time
          description: >-
            Date and time that the processor processed the transaction. Our
            gateway returns this value in the ISO 8601 format.
        description:
          type: string
          description: Description of the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction. The value is in the currency’s
            lowest denomination, for example, cents.
        currency:
          $ref: '#/components/schemas/currency'
        dccOffer:
          $ref: '#/components/schemas/dccOffer'
        standingInstructions:
          $ref: '#/components/schemas/standingInstructions'
        breakdown:
          $ref: '#/components/schemas/itemizedBreakdown'
      required:
        - orderId
        - amount
        - currency
      description: Object that contains information about the payment.
      title: paymentOrder
    retrievedAddress:
      type: object
      properties:
        address1:
          type: string
          description: Address line 1.
        address2:
          type: string
          description: Address line 2.
        address3:
          type: string
          description: Address line 3.
        city:
          type: string
          description: City.
        state:
          type: string
          description: Name of the state or state abbreviation.
        country:
          type: string
          description: >-
            Two-digit country code for the country that the business operates
            in. The format follows the
            [ISO-3166-1](https://www.iso.org/iso-3166-country-codes.html)
            standard.
        postalCode:
          type: string
          description: Zip code or postal code.
      description: Object that contains information about the address.
      title: retrievedAddress
    retrievedShipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/retrievedAddress'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: retrievedShipping
    RetrievedCustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: RetrievedCustomerNotificationLanguage
    retrievedCustomer:
      type: object
      properties:
        firstName:
          type: string
          description: Customer's first name.
        lastName:
          type: string
          description: Customer's last name.
        dateOfBirth:
          type: string
          format: date
          description: >-
            Customer's date of birth. The format for this value is
            **YYYY-MM-DD**.
        referenceNumber:
          type: string
          description: >
            Identifier of the transaction, also known as a customer code. 


            For requests, you must send a value for **referenceNumber** if the
            customer provides one. 
        billingAddress:
          $ref: '#/components/schemas/retrievedAddress'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/retrievedShipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/RetrievedCustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: retrievedCustomer
    CardEntryMethod:
      type: string
      enum:
        - icc
        - keyed
        - swiped
        - swipedFallback
        - contactlessIcc
        - contactlessMsr
      description: Method that the device used to capture the card details.
      title: CardEntryMethod
    SecureTokenSummaryStatus:
      type: string
      enum:
        - notValidated
        - cvvValidated
        - validationFailed
        - issueNumberValidated
        - cardNumberValidated
        - bankAccountValidated
      description: >
        Status of the customer's bank account. The processor performs a security
        check on the customer's bank account and returns the status of the
        account.  

        **Note:** Depending on the merchant's account settings, this feature may
        be unavailable.
      title: SecureTokenSummaryStatus
    link:
      type: object
      properties:
        rel:
          type: string
          description: >-
            Indicates the relationship between the current resource and the
            target resource.
        method:
          type: string
          description: HTTP method that you need to use with the target resource.
        href:
          type: string
          description: URL of the target resource.
      required:
        - rel
        - method
        - href
      description: Object that contains HATEOAS links for the resource.
      title: link
    secureTokenSummary:
      type: object
      properties:
        secureTokenId:
          type: string
          description: Unique identifier that the merchant assigned to the secure token.
        customerName:
          type: string
          description: Customer's name.
        token:
          type: string
          description: >
            Token that the merchant can use in future transactions to represent
            the customer's payment details. The token:  

            - Begins with the six-digit identification number **296753**.  

            - Contains up to 12 digits.  

            - Contains a single check digit that we calculate using the Luhn
            algorithm.  
        status:
          $ref: '#/components/schemas/SecureTokenSummaryStatus'
          description: >
            Status of the customer's bank account. The processor performs a
            security check on the customer's bank account and returns the status
            of the account.  

            **Note:** Depending on the merchant's account settings, this feature
            may be unavailable.
        link:
          $ref: '#/components/schemas/link'
      required:
        - secureTokenId
        - customerName
        - token
        - status
      description: Object that contains information about the secure token.
      title: secureTokenSummary
    SecurityCheckCvvResult:
      type: string
      enum:
        - M
        - 'N'
        - P
        - U
      description: >
        Indicates if the card verification value (CVV) that the customer
        provided in the request matches the CVV on the card.  

        - `M` – The CVV matches the card’s CVV.  

        - `N` – The CVV doesn’t match the card’s CVV.  

        - `P` – The CVV wasn’t processed.  

        - `U` – The CVV isn’t registered.  


        **Note:** Our gateway doesn’t automatically decline transactions when
        the CVV doesn’t match the card’s CVV, unless the merchant selects this
        setting in their account.
      title: SecurityCheckCvvResult
    SecurityCheckAvsResult:
      type: string
      enum:
        - 'Y'
        - A
        - Z
        - 'N'
        - U
        - R
        - G
        - S
        - F
        - W
        - X
      description: >
        Indicates if the address that the customer provided in the request
        matches the address linked to the card.


        - `Y` – The address in the request matches the address linked to the
        card.  

        - `N` – The address in the request doesn’t match the address linked to
        the card.  

        - `A` – The street address matches, but ZIP code or postal code doesn’t
        match.  

        - `Z` - The ZIP code or postal code matches, but street address doesn’t
        match.  

        - `U` – The address information is unavailable.  

        - `G` – The issuer or card brand doesn’t support the Address
        Verification Service (AVS).  

        - `R` – The AVS is currently unavailable. Try again later.  

        - `S` – There was no AVS data in the request, or it was sent in the
        wrong format.  

        - `F` - For UK addresses, the address in the request matches the address
        linked to the card.  

        - `W` – For US addresses, the nine-digit ZIP code or postal code in the
        request matches the address linked to the card but the street address
        doesn’t.  

        - `X` – For US addresses, the nine-digit ZIP code or postal code and the
        street address matches the address linked to the card.  
          
        **Note:** Our gateway doesn’t automatically decline transactions when
        the address doesn’t match the address linked to the card, 

        unless the merchant selects this setting in their account.
      title: SecurityCheckAvsResult
    securityCheck:
      type: object
      properties:
        cvvResult:
          $ref: '#/components/schemas/SecurityCheckCvvResult'
          description: >
            Indicates if the card verification value (CVV) that the customer
            provided in the request matches the CVV on the card.  

            - `M` – The CVV matches the card’s CVV.  

            - `N` – The CVV doesn’t match the card’s CVV.  

            - `P` – The CVV wasn’t processed.  

            - `U` – The CVV isn’t registered.  


            **Note:** Our gateway doesn’t automatically decline transactions
            when the CVV doesn’t match the card’s CVV, unless the merchant
            selects this setting in their account.
        avsResult:
          $ref: '#/components/schemas/SecurityCheckAvsResult'
          description: >
            Indicates if the address that the customer provided in the request
            matches the address linked to the card.


            - `Y` – The address in the request matches the address linked to the
            card.  

            - `N` – The address in the request doesn’t match the address linked
            to the card.  

            - `A` – The street address matches, but ZIP code or postal code
            doesn’t match.  

            - `Z` - The ZIP code or postal code matches, but street address
            doesn’t match.  

            - `U` – The address information is unavailable.  

            - `G` – The issuer or card brand doesn’t support the Address
            Verification Service (AVS).  

            - `R` – The AVS is currently unavailable. Try again later.  

            - `S` – There was no AVS data in the request, or it was sent in the
            wrong format.  

            - `F` - For UK addresses, the address in the request matches the
            address linked to the card.  

            - `W` – For US addresses, the nine-digit ZIP code or postal code in
            the request matches the address linked to the card but the street
            address doesn’t.  

            - `X` – For US addresses, the nine-digit ZIP code or postal code and
            the street address matches the address linked to the card.  
              
            **Note:** Our gateway doesn’t automatically decline transactions
            when the address doesn’t match the address linked to the card, 

            unless the merchant selects this setting in their account.
      description: >-
        Object that contains information about card verification and security
        checks.
      title: securityCheck
    emvTag:
      type: object
      properties:
        hex:
          type: string
          description: Hex code of the EMV tag.
        value:
          type: string
          description: Value of the EMV tag.
      required:
        - hex
        - value
      description: Object that contains information about the EMV tag.
      title: emvTag
    CardBalanceBenefitCategory:
      type: string
      enum:
        - cash
        - foodStamp
      description: >
        Indicates if the balance relates to an EBT Cash account or EBT SNAP
        account.  

        - `cash` – EBT Cash  

        - `foodStamp` – EBT SNAP
      title: CardBalanceBenefitCategory
    cardBalance:
      type: object
      properties:
        benefitCategory:
          $ref: '#/components/schemas/CardBalanceBenefitCategory'
          description: >
            Indicates if the balance relates to an EBT Cash account or EBT SNAP
            account.  

            - `cash` – EBT Cash  

            - `foodStamp` – EBT SNAP
        amount:
          type: integer
          format: int64
          description: >-
            Current balance of the account. This value is in the currency's
            lowest denomination, for example, cents.
        currency:
          $ref: '#/components/schemas/currency'
      required:
        - benefitCategory
        - amount
        - currency
      description: >-
        Object that contains information about the total funds available in the
        card.
      title: cardBalance
    card:
      type: object
      properties:
        type:
          type: string
          description: Card brand of the card, for example, Visa.
        entryMethod:
          $ref: '#/components/schemas/CardEntryMethod'
          description: Method that the device used to capture the card details.
        cardholderName:
          type: string
          description: Cardholder’s name.
        cardholderSignature:
          type: string
          description: Cardholder’s signature.
        cardNumber:
          type: string
          description: >
            Card number. In the response, our gateway shows only the first six
            digits and the last four digits of the card number, for example,
            500165******0000.
        expiryDate:
          type: string
          description: Expiry date of the customer's card. The format is in **MMYY**.
        secureToken:
          $ref: '#/components/schemas/secureTokenSummary'
        securityChecks:
          $ref: '#/components/schemas/securityCheck'
        emvTags:
          type: array
          items:
            $ref: '#/components/schemas/emvTag'
          description: Array of emvTag objects.
        balances:
          type: array
          items:
            $ref: '#/components/schemas/cardBalance'
          description: >-
            Array of cardBalance objects. Our gateway returns this array only
            when the customer uses an Electronic Benefit Transfer (EBT) card.
      required:
        - type
        - entryMethod
        - cardNumber
        - expiryDate
      description: Object that contains the details of the payment card.
      title: card
    RefundSummaryStatus:
      type: string
      enum:
        - ready
        - pending
        - declined
        - complete
        - referral
        - pickup
        - reversal
        - returned
        - admin
        - expired
        - accepted
      description: Current status of the refund.
      title: RefundSummaryStatus
    RefundSummaryResponseCode:
      type: string
      enum:
        - A
        - D
        - E
        - P
        - R
        - C
      description: >
        Response from the processor.  

        - `A` - The processor approved the transaction.  

        - `D` - The processor declined the transaction.  

        - `E` - The processor received the transaction but will process the
        transaction later.  

        - `P` - The processor authorized a portion of the original amount of the
        transaction.  

        - `R` - The issuer declined the transaction and indicated that the
        customer should contact their bank.  

        - `C` - The issuer declined the transaction and indicated that the
        merchant should keep the card as it was reported lost or stolen.
      title: RefundSummaryResponseCode
    refundSummary:
      type: object
      properties:
        refundId:
          type: string
          description: Unique identifier of the refund.
        dateTime:
          type: string
          format: date-time
          description: Date and time that the refund was processed.
        currency:
          $ref: '#/components/schemas/currency'
        amount:
          type: integer
          format: int64
          description: >-
            Amount of the refund. This value is in the currency’s lowest
            denomination, for example, cents.
        status:
          $ref: '#/components/schemas/RefundSummaryStatus'
          description: Current status of the refund.
        responseCode:
          $ref: '#/components/schemas/RefundSummaryResponseCode'
          description: >
            Response from the processor.  

            - `A` - The processor approved the transaction.  

            - `D` - The processor declined the transaction.  

            - `E` - The processor received the transaction but will process the
            transaction later.  

            - `P` - The processor authorized a portion of the original amount of
            the transaction.  

            - `R` - The issuer declined the transaction and indicated that the
            customer should contact their bank.  

            - `C` - The issuer declined the transaction and indicated that the
            merchant should keep the card as it was reported lost or stolen.
        responseMessage:
          type: string
          description: Description of the response from the processor.
        link:
          $ref: '#/components/schemas/link'
      required:
        - refundId
        - dateTime
        - currency
        - amount
        - status
        - responseCode
        - responseMessage
      description: Object that contains information about a refund.
      title: refundSummary
    SupportedOperationsItems:
      type: string
      enum:
        - capture
        - refund
        - fullyReverse
        - partiallyReverse
        - incrementAuthorization
        - adjustTip
        - addSignature
        - setAsReady
        - setAsPending
      title: SupportedOperationsItems
    supportedOperations:
      type: array
      items:
        $ref: '#/components/schemas/SupportedOperationsItems'
      description: |
        Array of operations that you can perform on the transaction.
        - `capture`                - Capture the payment.
        - `refund`                 - Refund the payment.
        - `fullyReverse`           - Fully reverse the transaction.
        - `partiallyReverse`       - Partially reverse the payment.
        - `incrementAuthorization` - Increase the amount of the authorization.
        - `adjustTip`              - Adjust the tip post-payment.
        - `addSignature`           - Add a signature to the payment.
        - `setAsReady`             - Set the transaction’s status to `ready`.
        - `setAsPending`           - Set the transaction’s status to `pending`.
      title: supportedOperations
    TransactionResultType:
      type: string
      enum:
        - sale
        - refund
        - preAuthorization
        - preAuthorizationCompletion
      description: Transaction type.
      title: TransactionResultType
    TransactionResultEbtType:
      type: string
      enum:
        - cashPurchase
        - cashPurchaseWithCashback
        - foodStampPurchase
        - foodStampVoucherPurchase
        - foodStampReturn
        - foodStampVoucherReturn
        - cashBalanceInquiry
        - foodStampBalanceInquiry
        - cashWithdrawal
      description: Indicates the subtype of EBT in the transaction.
      title: TransactionResultEbtType
    TransactionResultStatus:
      type: string
      enum:
        - ready
        - pending
        - declined
        - complete
        - referral
        - pickup
        - reversal
        - admin
        - expired
        - accepted
      description: Current status of the transaction.
      title: TransactionResultStatus
    TransactionResultResponseCode:
      type: string
      enum:
        - A
        - D
        - E
        - P
        - R
        - C
      description: >
        Response from the processor.  

        - `A` - The processor approved the transaction.  

        - `D` - The processor declined the transaction.  

        - `E` - The processor received the transaction but will process the
        transaction later.  

        - `P` - The processor authorized a portion of the original amount of the
        transaction.  

        - `R` - The issuer declined the transaction and indicated that the
        customer should contact their bank.  

        - `C` - The issuer declined the transaction and indicated that the
        merchant should keep the card as it was reported lost or stolen.
      title: TransactionResultResponseCode
    TransactionResultHealthcareIndicator:
      type: string
      enum:
        - 'Y'
        - 'N'
        - C
        - R
      description: >
        Indicates if we processed the payment as a healthcare expense. The value
        is one of the following:  

        - `Y` - We processed the payment as a healthcare expense.  

        - `N` - We processed the payment but it didn't contain any healthcare
        expenses. 

        - `C` - We processed the payment but the card isn't linked to a Flexible
        Spending Account (FSA) or a Health Savings Account (HSA). 

        - `R` - We processed the payment but the card doesn't support healthcare
        expenses. 
      title: TransactionResultHealthcareIndicator
    transactionResult:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/TransactionResultType'
          description: Transaction type.
        ebtType:
          $ref: '#/components/schemas/TransactionResultEbtType'
          description: Indicates the subtype of EBT in the transaction.
        status:
          $ref: '#/components/schemas/TransactionResultStatus'
          description: Current status of the transaction.
        approvalCode:
          type: string
          description: Authorization code that the processor assigned to the transaction.
        authorizedAmount:
          type: integer
          format: int64
          description: >
            Amount that the processor authorized for the transaction. This value
            is in the currency’s lowest denomination, for example, cents.  


            **Notes:**  

            - For partial authorizations, this amount is lower than the amount
            in the request.

            - If the value for **authorizedAmount** is negative, this indicates
            that the merchant sent funds to the customer.
        currency:
          $ref: '#/components/schemas/currency'
        responseCode:
          $ref: '#/components/schemas/TransactionResultResponseCode'
          description: >
            Response from the processor.  

            - `A` - The processor approved the transaction.  

            - `D` - The processor declined the transaction.  

            - `E` - The processor received the transaction but will process the
            transaction later.  

            - `P` - The processor authorized a portion of the original amount of
            the transaction.  

            - `R` - The issuer declined the transaction and indicated that the
            customer should contact their bank.  

            - `C` - The issuer declined the transaction and indicated that the
            merchant should keep the card as it was reported lost or stolen.
        responseMessage:
          type: string
          description: Response description from the processor.
        processorResponseCode:
          type: string
          description: Original response code that the processor sent.
        cardSchemeReferenceId:
          type: string
          description: Identifier that the card brand assigns to the payment instruction.
        healthcareIndicator:
          $ref: '#/components/schemas/TransactionResultHealthcareIndicator'
          description: >
            Indicates if we processed the payment as a healthcare expense. The
            value is one of the following:  

            - `Y` - We processed the payment as a healthcare expense.  

            - `N` - We processed the payment but it didn't contain any
            healthcare expenses. 

            - `C` - We processed the payment but the card isn't linked to a
            Flexible Spending Account (FSA) or a Health Savings Account (HSA). 

            - `R` - We processed the payment but the card doesn't support
            healthcare expenses. 
      required:
        - status
        - responseCode
      description: Object that contains information about the transaction response details.
      title: transactionResult
    payment:
      type: object
      properties:
        paymentId:
          type: string
          description: Unique identifier that our gateway assigned to the transaction.
        processingTerminalId:
          type: string
          description: Unique identifier of the terminal that initiated the transaction.
        operator:
          type: string
          description: Operator who initiated the request.
        order:
          $ref: '#/components/schemas/paymentOrder'
        customer:
          $ref: '#/components/schemas/retrievedCustomer'
        card:
          $ref: '#/components/schemas/card'
        refunds:
          type: array
          items:
            $ref: '#/components/schemas/refundSummary'
          description: >
            Array of refundSummary objects. 

            Each object contains information about refunds linked to the
            transaction.
        supportedOperations:
          $ref: '#/components/schemas/supportedOperations'
        transactionResult:
          $ref: '#/components/schemas/transactionResult'
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - paymentId
        - processingTerminalId
        - order
        - card
        - transactionResult
      title: payment
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems

```

### Example response

### Response (201)

```json
{
  "paymentId": "M2MJOG6O2Y",
  "processingTerminalId": "1234001",
  "order": {
    "orderId": "OrderRef6543",
    "amount": 4999,
    "currency": "USD",
    "dateTime": "2024-07-02T15:30:00Z",
    "description": "Large Pepperoni Pizza"
  },
  "card": {
    "type": "MasterCard",
    "entryMethod": "keyed",
    "cardNumber": "453985******7062",
    "expiryDate": "1230",
    "securityChecks": {
      "cvvResult": "M",
      "avsResult": "Y"
    }
  },
  "transactionResult": {
    "status": "ready",
    "responseCode": "A",
    "type": "sale",
    "approvalCode": "OK3",
    "authorizedAmount": 4999,
    "currency": "USD",
    "responseMessage": "OK3"
  },
  "operator": "Jane",
  "customer": {
    "firstName": "Sarah",
    "lastName": "Hopper",
    "billingAddress": {
      "address1": "1 Example Ave.",
      "address2": "Example Address Line 2",
      "address3": "Example Address Line 3",
      "city": "Chicago",
      "state": "Illinois",
      "country": "US",
      "postalCode": "60056"
    },
    "shippingAddress": {
      "recipientName": "Sarah Hopper",
      "address": {
        "address1": "1 Example Ave.",
        "address2": "Example Address Line 2",
        "address3": "Example Address Line 3",
        "city": "Chicago",
        "state": "Illinois",
        "country": "US",
        "postalCode": "60056"
      }
    }
  },
  "supportedOperations": [
    "capture",
    "fullyReverse",
    "partiallyReverse",
    "incrementAuthorization",
    "adjustTip",
    "setAsPending"
  ],
  "customFields": [
    {
      "name": "yourCustomField",
      "value": "abc123"
    }
  ]
}
```

## Next steps

After you integrate with the Apple Pay JS API and the Payroc API, complete the following steps:

* **Set up Apple Pay for each merchant** - To set up Apple Pay for a merchant to run transactions, go to [Set up Apple Pay for a Merchant](/guides/take-payments/apple-pay/set-up-apple-pay-for-a-merchant).
* **Set up a Sandbox Apple Account** - To run test transactions with Apple Pay, set up a Sandbox Apple Account. To set up a Sandbox Apple Account, contact our Integrations Team at [integrationsupport@payroc.com](mailto:integrationsupport@payroc.com).
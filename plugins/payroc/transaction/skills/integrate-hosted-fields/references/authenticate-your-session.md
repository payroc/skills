> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Authenticate your session

To authenticate your access to the Payroc gateway, include a session token every time you run the Hosted Fields script on a webpage.

## Before you begin

* Make sure you have your API key for both the test environment and the production environment.
* Make sure that your integration can handle errors. If a request is unsuccessful, we return an error that follows the [RFC 7807 format](https://datatracker.ietf.org/doc/html/rfc7807). For more information about errors, go to [Errors](/api/errors).

## Integration steps

**Step 1.**	Generate a Bearer token.\
**Step 2.**	Generate a session token from the Bearer token.

## Step 1. Generate a Bearer token

To authenticate your integration, you need to use a Bearer token. To generate a Bearer token, send your API key in a request to our Identity Service.

**Note:** You need to generate a new Bearer token before the previous Bearer token expires.

### Request

To generate a Bearer token, Include your API key in a x-api-key header in a POST request to our Identity endpoint.

| Endpoint   | Prefix          | URL                                                                                    |
| :--------- | :-------------- | :------------------------------------------------------------------------------------- |
| Test       | `identity.uat.` | [https://identity.uat.payroc.com/authorize](https://identity.uat.payroc.com/authorize) |
| Production | `identity.`     | [https://identity.payroc.com/authorize](https://identity.payroc.com/authorize)         |

### Example request

```bash
curl --location --request POST  'https://identity.payroc.com/authorize' --header 'x-api-key: <api key>'
```

### Response

If your request is successful, we return a response that contains your Bearer token, information about its scope, and when it expires.

| Field         | Description                                                                              |
| :------------ | :--------------------------------------------------------------------------------------- |
| access\_token | Value for the Bearer token. Use this value in the Authorization header of your requests. |
| expires\_in   | Number of seconds that the token expires in.                                             |
| scope         | Indicates which services that the token covers.                                          |
| token\_type   | Type of access token.                                                                    |

### Example response

If your request is successful, we return a response that contains your Bearer token, information about its scope, and when it expires.

```json
{
  "access_token": "eyJhbGc....adQssw5c",
  "expires_in": 3600,
  "scope": "service_a service_b",
  "token_type": "Bearer"
}
```

## Step 2. Generate a session token from the Bearer token

You must use our Hosted Fields Sessions endpoint to generate a new session token each time you initialize Hosted Fields. A session token expires after 10 minutes.

When you generate a session token, you need to specify the version of the Hosted Fields JavaScript library that you are using. Include the version number in the libVersion parameter in the body of your request.

| Environment | Version      |
| ----------- | ------------ |
| Test        | 1.7.0.261457 |
| Production  | 1.7.0.261471 |

### Request

To generate a session token, send a POST request to our Processing Terminals endpoint.

| Endpoint   | Prefix     | URL                                                                                                                                                                                                    |
| :--------- | :--------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions) |
| Production | `api.`     | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions)         |

Include the following headers in your request:

* **Content-Type:** Include `application/json` as the value for this parameter.
* **Authorization:** Include your Bearer token in this parameter.
* **Idempotency-Key:** Include a UUID v4 to make the request idempotent.

To create the body of your request, use the following parameters:

### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/hosted-fields-sessions:
    post:
      operationId: create
      summary: Create Hosted Fields session
      description: >
        Use this method to create a Hosted Fields session token. You need to
        generate a new session token each time you load Hosted Fields on a
        webpage.  


        In your request, you need to indicate whether the merchant is using
        Hosted Fields to run a sale, save payment details, or update saved
        payment details.  


        In the response, our gateway returns the session token and the time that
        it expires. You need the session token when you configure the JavaScript
        for Hosted Fields.  


        For more information about adding Hosted Fields to a webpage, go to
        [Hosted
        Fields](https://docs.payroc.com/guides/take-payments/hosted-fields). 
      tags:
        - subpackage_hostedFields
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
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
          description: >-
            Successful request. We created the session and returned a session
            token.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/hostedFieldsCreateSessionResponse'
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
              $ref: '#/components/schemas/hostedFieldsCreateSessionRequest'
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
    HostedFieldsCreateSessionRequestScenario:
      type: string
      enum:
        - payment
        - tokenization
      description: >
        Indicates if a merchant wants to take a payment or tokenize a customer's
        payment details:  


        - `payment` - The merchant wants to run a sale or run a sale and
        tokenize in the same transaction.  

        - `tokenization` - The merchant wants to save the customer's payment
        details to take a payment later or to update a customer's payment
        details that they've already saved.  
      title: HostedFieldsCreateSessionRequestScenario
    hostedFieldsCreateSessionRequest:
      type: object
      properties:
        libVersion:
          type: string
          description: >
            Version of the Hosted Fields JavaScript library that you are
            using.  


            The current production version is `1.7.0.261471`.
        scenario:
          $ref: '#/components/schemas/HostedFieldsCreateSessionRequestScenario'
          description: >
            Indicates if a merchant wants to take a payment or tokenize a
            customer's payment details:  


            - `payment` - The merchant wants to run a sale or run a sale and
            tokenize in the same transaction.  

            - `tokenization` - The merchant wants to save the customer's payment
            details to take a payment later or to update a customer's payment
            details that they've already saved.  
        secureTokenId:
          type: string
          description: >
            Unique identifier that represents a customer's payment details.  


            If a merchant wants to update a customer's payment details that are
            linked to a secure token, include the secureTokenId in your
            request.  
      required:
        - libVersion
        - scenario
      description: >-
        Object that contains information about Hosted Fields initialization
        request.
      title: hostedFieldsCreateSessionRequest
    hostedFieldsCreateSessionResponse:
      type: object
      properties:
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        token:
          type: string
          description: |
            Token that our gateway assigned to the Hosted Fields session.  

            Include this session token in the config file for Hosted Fields.  

            The session token expires after 10 minutes.
        expiresAt:
          type: string
          format: date-time
          description: >-
            Date and time that the token expires. We return this value in the
            [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html)
            format.
      required:
        - processingTerminalId
        - token
        - expiresAt
      title: hostedFieldsCreateSessionResponse
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems
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

```

### Example request

### Request

POST [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions)

```curl Create session response
curl -X POST https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json"
```

```typescript Create session response
import { PayrocClient } from "payroc";

async function main() {
    const client = new PayrocClient();
    await client.hostedFields.create("1234001", {
        idempotencyKey: "8e03978e-40d5-43e8-bc93-6894a57f9324",
    });
}
main();

```

```python Create session response
from payroc import Payroc

client = Payroc()

client.hosted_fields.create(
    processing_terminal_id="1234001",
    idempotency_key="8e03978e-40d5-43e8-bc93-6894a57f9324",
)

```

```java Create session response
package com.example.usage;

import com.payroc.api.PayrocApiClient;
import com.payroc.api.resources.hostedfields.requests.HostedFieldsCreateSessionRequest;

public class Example {
    public static void main(String[] args) {
        PayrocApiClient client = PayrocApiClient
            .builder()
            .build();

        client.hostedFields().create(
            "1234001",
            HostedFieldsCreateSessionRequest
                .builder()
                .idempotencyKey("8e03978e-40d5-43e8-bc93-6894a57f9324")
                .build()
        );
    }
}
```

```ruby Create session response
require "payroc"

client = Payroc::Client.new

client.hosted_fields.create(
  processing_terminal_id: "1234001",
  idempotency_key: "8e03978e-40d5-43e8-bc93-6894a57f9324"
)

```

```csharp Create session response
using Payroc;
using System.Threading.Tasks;
using Payroc.HostedFields;

namespace Usage;

public class Example
{
    public async Task Do() {
        var client = new PayrocClient();

        await client.HostedFields.CreateAsync(
            new HostedFieldsCreateSessionRequest {
                ProcessingTerminalId = "1234001",
                IdempotencyKey = "8e03978e-40d5-43e8-bc93-6894a57f9324"
            }
        );
    }

}

```

```go Create session response
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions"

	req, _ := http.NewRequest("POST", url, nil)

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

```php Create session response
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('POST', 'https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```swift Create session response
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions")! as URL,
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

If your request is successful, our gateway generates a session token. The response contains the following fields:

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/hosted-fields-sessions:
    post:
      operationId: create
      summary: Create Hosted Fields session
      description: >
        Use this method to create a Hosted Fields session token. You need to
        generate a new session token each time you load Hosted Fields on a
        webpage.  


        In your request, you need to indicate whether the merchant is using
        Hosted Fields to run a sale, save payment details, or update saved
        payment details.  


        In the response, our gateway returns the session token and the time that
        it expires. You need the session token when you configure the JavaScript
        for Hosted Fields.  


        For more information about adding Hosted Fields to a webpage, go to
        [Hosted
        Fields](https://docs.payroc.com/guides/take-payments/hosted-fields). 
      tags:
        - subpackage_hostedFields
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
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
          description: >-
            Successful request. We created the session and returned a session
            token.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/hostedFieldsCreateSessionResponse'
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
              $ref: '#/components/schemas/hostedFieldsCreateSessionRequest'
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
    HostedFieldsCreateSessionRequestScenario:
      type: string
      enum:
        - payment
        - tokenization
      description: >
        Indicates if a merchant wants to take a payment or tokenize a customer's
        payment details:  


        - `payment` - The merchant wants to run a sale or run a sale and
        tokenize in the same transaction.  

        - `tokenization` - The merchant wants to save the customer's payment
        details to take a payment later or to update a customer's payment
        details that they've already saved.  
      title: HostedFieldsCreateSessionRequestScenario
    hostedFieldsCreateSessionRequest:
      type: object
      properties:
        libVersion:
          type: string
          description: >
            Version of the Hosted Fields JavaScript library that you are
            using.  


            The current production version is `1.7.0.261471`.
        scenario:
          $ref: '#/components/schemas/HostedFieldsCreateSessionRequestScenario'
          description: >
            Indicates if a merchant wants to take a payment or tokenize a
            customer's payment details:  


            - `payment` - The merchant wants to run a sale or run a sale and
            tokenize in the same transaction.  

            - `tokenization` - The merchant wants to save the customer's payment
            details to take a payment later or to update a customer's payment
            details that they've already saved.  
        secureTokenId:
          type: string
          description: >
            Unique identifier that represents a customer's payment details.  


            If a merchant wants to update a customer's payment details that are
            linked to a secure token, include the secureTokenId in your
            request.  
      required:
        - libVersion
        - scenario
      description: >-
        Object that contains information about Hosted Fields initialization
        request.
      title: hostedFieldsCreateSessionRequest
    hostedFieldsCreateSessionResponse:
      type: object
      properties:
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        token:
          type: string
          description: |
            Token that our gateway assigned to the Hosted Fields session.  

            Include this session token in the config file for Hosted Fields.  

            The session token expires after 10 minutes.
        expiresAt:
          type: string
          format: date-time
          description: >-
            Date and time that the token expires. We return this value in the
            [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html)
            format.
      required:
        - processingTerminalId
        - token
        - expiresAt
      title: hostedFieldsCreateSessionResponse
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems
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

```

### Example response

### Response (201)

```json
{
  "processingTerminalId": "1234001",
  "token": "abcdef1234567890abcdef1234567890",
  "expiresAt": "2025-07-02T15:30:00.000+02:00"
}
```
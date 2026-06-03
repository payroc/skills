> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-fields/run-a-sale.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Run a sale

After a customer enters their payment details into Hosted Fields, we tokenize them and return a single-use token. To run a sale, use the single-use token with our API.

The API method that you need to use depends on the payment type that the single-use token represents, for example, card details or bank account details.

## Before you begin

### Single-use token

Make sure that your integration can handle submissionSuccess events to receive a single-use token when a customer submits their payment details.

### Headers

To create the header of each POST request, you must include the following parameters:

* **Content-Type:** Include application/json as the value for this parameter.
* **Authorization:** Include your Bearer token in this parameter.
* **Idempotency-Key:** Include a UUID v4 to make the request idempotent.

```curl
-H "Content-Type: application/json"
-H "Authorization: <Bearer token>"
-H "Idempotency-Key: <UUID v4>"
```

### Errors

Make sure that your integration can handle errors. If a request is unsuccessful, we return an error that follows the [RFC 7807 format](https://www.rfc-editor.org/rfc/rfc7807). For more information about errors, go to [Errors](/api/errors).

## Integration steps

The method that you need to use to run the sale depends on the customer's payment type:

* If the single-use token represents card details, go to [Run a sale with card details](#run-a-sale-with-card-details).
* If the single-use token represents ACH or PAD details, go to [Run a sale with bank account details](#run-a-sale-with-bank-account-details).

## Run a sale with card details

To run a sale with card details, send a POST request to our Payments endpoint.

| Endpoint   | Prefix     | URL                                                                              |
| :--------- | :--------- | :------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/payments](https://api.uat.payroc.com/v1/payments) |
| Production | `api.`     | [https://api.payroc.com/v1/payments](https://api.payroc.com/v1/payments)         |

### Request parameters

**Important:** The request includes parameters for functions and features that we don't cover in this guide. These functions and features might require additional integration effort and cost. For more information, contact our Integrations Team at [integrationsupport@payroc.com](mailto:integrationsupport@payroc.com).

For the paymentMethod object, send values for the following parameters:

* **type:** Send a value of `singleUseToken`.
* **token:** Send the single-use token that you received in the submissionSuccess event.

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

```curl Payment
curl -X POST https://api.payroc.com/v1/payments \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json"
```

```typescript Payment
import { PayrocClient } from "payroc";

async function main() {
    const client = new PayrocClient();
    await client.cardPayments.payments.create({
        idempotencyKey: "8e03978e-40d5-43e8-bc93-6894a57f9324",
    });
}
main();

```

```python Payment
from payroc import Payroc

client = Payroc()

client.card_payments.payments.create(
    idempotency_key="8e03978e-40d5-43e8-bc93-6894a57f9324",
)

```

```java Payment
package com.example.usage;

import com.payroc.api.PayrocApiClient;
import com.payroc.api.resources.cardpayments.payments.requests.PaymentRequest;

public class Example {
    public static void main(String[] args) {
        PayrocApiClient client = PayrocApiClient
            .builder()
            .build();

        client.cardPayments().payments().create(
            PaymentRequest
                .builder()
                .idempotencyKey("8e03978e-40d5-43e8-bc93-6894a57f9324")
                .build()
        );
    }
}
```

```ruby Payment
require "payroc"

client = Payroc::Client.new

client.card_payments.payments.create(idempotency_key: "8e03978e-40d5-43e8-bc93-6894a57f9324")

```

```csharp Payment
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
                IdempotencyKey = "8e03978e-40d5-43e8-bc93-6894a57f9324"
            }
        );
    }

}

```

```go Payment
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/payments"

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

```php Payment
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('POST', 'https://api.payroc.com/v1/payments', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```swift Payment
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/payments")! as URL,
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

## Run a sale with bank account details

To run a sale with bank account details, send a POST request to our Bank Transfer Payments endpoint.

| Endpoint   | Prefix     | URL                                                                                                          |
| :--------- | :--------- | :----------------------------------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/bank-transfer-payments](https://api.uat.payroc.com/v1/bank-transfer-payments) |
| Production | `api.`     | [https://api.payroc.com/v1/bank-transfer-payments](https://api.payroc.com/v1/bank-transfer-payments)         |

### Request parameters

**Important:** The request includes parameters for functions and features that we don't cover in this guide. These functions and features might require additional integration effort and cost. For more information, contact our Integrations Team at [integrationsupport@payroc.com](mailto:integrationsupport@payroc.com).

For the paymentMethod object, send values for the following parameters:

* **type:** Send a value of `singleUseToken`.
* **token:** Send the single-use token that you received in the submissionSuccess event.
* **accountType:** Indicate if the bank account is a savings account or a checking account.
* **secCode:** If the single-use token represents ACH details, indicate how the customer authorized the payment.

### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /bank-transfer-payments:
    post:
      operationId: create
      summary: Create payment
      description: "Use this method to run a sale with a customer's bank account details.  \n\nIn the response, our gateway returns information about the bank transfer payment and a paymentId, which you need for the following methods:  \n-\t[Retrieve payment](https://docs.payroc.com/api/schema/bank-transfer-payments/payments/retrieve) - View the details of the bank transfer payment.\n-\t[Reverse payment](https://docs.payroc.com/api/schema/bank-transfer-payments/refunds/reverse-payment) - Cancel the bank transfer payment if it's an open batch.\n-\t[Refund payment](https://docs.payroc.com/api/schema/bank-transfer-payments/refunds/refund) - Run a referenced refund to return funds to the customer's bank account.\n\n**Payment methods**  \n\nOur gateway accepts the following payment methods:  \n-\tAutomated clearing house (ACH) details\n-\tPre-authorized debit (PAD) details  \n\nYou can also use [secure tokens](https://docs.payroc.com/api/schema/payments/secure-tokens/overview) and [single-use tokens](https://docs.payroc.com/api/schema/tokenization/single-use-tokens/create) that you created from ACH details or PAD details. \n"
      tags:
        - >-
          subpackage_bankTransferPayments.subpackage_bankTransferPayments/payments
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
          description: Successful request. We processed the sale.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/bankTransferPayment'
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
              $ref: '#/components/schemas/bankTransferPaymentRequest'
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
    taxRate:
      type: object
      properties:
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
        - rate
        - name
      title: taxRate
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
    bankTransferRequestBreakdown:
      type: object
      properties:
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/taxRate'
          description: Array of tax objects.
        subtotal:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction before tax and tip. The value is in
            the currency's lowest denomination, for example, cents.
        tip:
          $ref: '#/components/schemas/tip'
          description: Object that contains tip information for the transaction.
      required:
        - subtotal
      description: Object that contains information about the transaction.
      title: bankTransferRequestBreakdown
    bankTransferPaymentRequestOrder:
      type: object
      properties:
        orderId:
          type: string
          description: A unique identifier assigned by the merchant.
        dateTime:
          type: string
          format: date-time
          description: >-
            The processing date and time of the transaction represented as per
            [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard.
        description:
          type: string
          description: A brief description of the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            The total amount in the currency's lowest denomination. For example,
            cents.
        currency:
          $ref: '#/components/schemas/currency'
        breakdown:
          $ref: '#/components/schemas/bankTransferRequestBreakdown'
      required:
        - orderId
        - amount
        - currency
      description: Object that contains information about the transaction.
      title: bankTransferPaymentRequestOrder
    BankTransferCustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >-
        Customer's preferred notification language. This code follows the [ISO
        639-1](https://www.iso.org/iso-639-language-code) standard.
      title: BankTransferCustomerNotificationLanguage
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
    bankTransferCustomer:
      type: object
      properties:
        notificationLanguage:
          $ref: '#/components/schemas/BankTransferCustomerNotificationLanguage'
          description: >-
            Customer's preferred notification language. This code follows the
            [ISO 639-1](https://www.iso.org/iso-639-language-code) standard.
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
      description: Object that contains information about the customer.
      title: bankTransferCustomer
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
    BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** For bank account details, send a value for accountType.
      title: >-
        BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType
    BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode:
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


        **Note:** This field is mandatory for ACH payments and unreferenced
        refunds.
      title: BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode
    BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  
        **Note:** For bank account details, send a value for accountType.
      title: >-
        BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType
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
    BankTransferPaymentRequestPaymentMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - ach
              description: 'Discriminator value: ach'
            accountType:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** For bank account details, send a value for
                accountType.
            secCode:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory for ACH payments and
                unreferenced refunds.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >
                Customer’s bank account number.  

                **Note:** In responses, our gateway shows only the last four
                digits of the account number, for example, `*****5929`.
            routingNumber:
              type: string
              description: Nine-digit number that identifies the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: >-
            Object that contains information about the payment details for the
            customer’s automated clearing house (ACH) transactions.
        - type: object
          properties:
            type:
              type: string
              enum:
                - pad
              description: 'Discriminator value: pad'
            accountType:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType
              description: >
                Indicates the customer’s account type.  

                **Note:** For bank account details, send a value for
                accountType.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >
                Customer's account number.  

                **Note:** In responses, our gateway shows only the last four
                digits of the account number, for example, `*****5929`.
            transitNumber:
              type: string
              description: Five-digit number that identifies the customer's bank branch.
            institutionNumber:
              type: string
              description: Three-digit number that identifies the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: >-
            Object that contains information about the payment details for the
            customer’s preauthorized electronic debit (PAD) transactions.
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
      description: "Polymorphic object that contains payment detail information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`secureToken` - Secure token details\n-\t`singleUseToken` - Single-use token details\n"
      title: BankTransferPaymentRequestPaymentMethod
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
    bankTransferPaymentRequest:
      type: object
      properties:
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        order:
          $ref: '#/components/schemas/bankTransferPaymentRequestOrder'
        customer:
          $ref: '#/components/schemas/bankTransferCustomer'
        credentialOnFile:
          $ref: '#/components/schemas/schemas-credentialOnFile'
        paymentMethod:
          $ref: '#/components/schemas/BankTransferPaymentRequestPaymentMethod'
          description: "Polymorphic object that contains payment detail information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`secureToken` - Secure token details\n-\t`singleUseToken` - Single-use token details\n"
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - processingTerminalId
        - order
        - paymentMethod
      description: >-
        Object that contains information about the sale and the customer's bank
        details.
      title: bankTransferPaymentRequest
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
    bankTransferBreakdown:
      type: object
      properties:
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/retrievedTax'
          description: Array of tax objects.
        subtotal:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction before tax and tip. The value is in
            the currency's lowest denomination, for example, cents.
        tip:
          $ref: '#/components/schemas/tip'
          description: Object that contains tip information for the transaction.
      required:
        - subtotal
      description: Object that contains information about the transaction.
      title: bankTransferBreakdown
    bankTransferPaymentOrder:
      type: object
      properties:
        orderId:
          type: string
          description: A unique identifier assigned by the merchant.
        dateTime:
          type: string
          format: date-time
          description: >-
            The processing date and time of the transaction represented as per
            [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard.
        description:
          type: string
          description: A brief description of the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            The total amount in the currency's lowest denomination. For example,
            cents.
        currency:
          $ref: '#/components/schemas/currency'
        breakdown:
          $ref: '#/components/schemas/bankTransferBreakdown'
      required:
        - orderId
        - amount
        - currency
      description: Object that contains information about the transaction.
      title: bankTransferPaymentOrder
    BankTransferRefundBankAccountDiscriminatorMappingAchSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: |
        Indicates the type of authorization for the transaction.  

        **Note:** The field is mandatory for ACH secure token.  

        - `web` – Online transaction.  
        - `tel` – Telephone transaction.  
        - `ccd` – Corporate credit card or debit card transaction.  
        - `ppd` – Pre-arranged transaction.
      title: BankTransferRefundBankAccountDiscriminatorMappingAchSecCode
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
    BankTransferPaymentBankAccount:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - ach
              description: 'Discriminator value: ach'
            secCode:
              $ref: >-
                #/components/schemas/BankTransferRefundBankAccountDiscriminatorMappingAchSecCode
              description: |
                Indicates the type of authorization for the transaction.  

                **Note:** The field is mandatory for ACH secure token.  

                - `web` – Online transaction.  
                - `tel` – Telephone transaction.  
                - `ccd` – Corporate credit card or debit card transaction.  
                - `ppd` – Pre-arranged transaction.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >-
                Customer's bank account number. We mask all digits except the
                last four digits.
            routingNumber:
              type: string
              description: >
                Routing number of the customer’s account.


                **Note:** In responses, our gateway shows only the last four
                digits of the account's routing number, for example, *****4162. 
            secureToken:
              $ref: '#/components/schemas/secureTokenSummary'
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: Object that contains the customer's account details.
        - type: object
          properties:
            type:
              type: string
              enum:
                - pad
              description: 'Discriminator value: pad'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >-
                Customer's bank account number. We mask all digits except the
                last four digits.
            transitNumber:
              type: string
              description: Five-digit code that represents the customer's banking branch.
            institutionNumber:
              type: string
              description: Three-digit code that represents the customer's bank.
            secureToken:
              $ref: '#/components/schemas/secureTokenSummary'
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: Object that contains the customer's account details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains bank account information.\n\nThe value of the type field determines which variant you should use:\n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n"
      title: BankTransferPaymentBankAccount
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
    bankTransferReturnSummary:
      type: object
      properties:
        paymentId:
          type: string
          description: Unique identifier that our gateway assigned to the payment.
        date:
          type: string
          format: date
          description: The date that the check was returned.
        returnCode:
          type: string
          description: The NACHA return code.
        returnReason:
          type: string
          description: The reason why the check was returned.
        represented:
          type: boolean
          description: Indicates whether the return has been re-presented.
        link:
          $ref: '#/components/schemas/link'
      required:
        - paymentId
        - date
        - returnCode
        - returnReason
        - represented
      description: Object that contains information about a return.
      title: bankTransferReturnSummary
    PaymentSummaryStatus:
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
      description: Current status of the payment.
      title: PaymentSummaryStatus
    PaymentSummaryResponseCode:
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
      title: PaymentSummaryResponseCode
    paymentSummary:
      type: object
      properties:
        paymentId:
          type: string
          description: Unique identifier of the payment.
        dateTime:
          type: string
          format: date-time
          description: Date and time that the payment was processed.
        currency:
          $ref: '#/components/schemas/currency'
        amount:
          type: integer
          format: int64
          description: >-
            Amount of the payment. This value is in the currency’s lowest
            denomination, for example, cents.
        status:
          $ref: '#/components/schemas/PaymentSummaryStatus'
          description: Current status of the payment.
        responseCode:
          $ref: '#/components/schemas/PaymentSummaryResponseCode'
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
        link:
          $ref: '#/components/schemas/link'
      required:
        - paymentId
        - dateTime
        - currency
        - amount
        - status
        - responseCode
      description: Object that contains information about a payment.
      title: paymentSummary
    BankTransferResultType:
      type: string
      enum:
        - payment
        - refund
        - unreferencedRefund
        - accountVerification
      description: Type of transaction.
      title: BankTransferResultType
    BankTransferResultStatus:
      type: string
      enum:
        - ready
        - pending
        - declined
        - complete
        - admin
        - reversal
        - returned
      description: Status of the transaction.
      title: BankTransferResultStatus
    bankTransferResult:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/BankTransferResultType'
          description: Type of transaction.
        status:
          $ref: '#/components/schemas/BankTransferResultStatus'
          description: Status of the transaction.
        authorizedAmount:
          type: integer
          format: int64
          description: |
            Amount of the transaction.  
            **Note:** The amount is negative for a refund.
        currency:
          $ref: '#/components/schemas/currency'
        responseCode:
          type: string
          description: |
            Response from the processor.  
            - `A` - The processor approved the transaction.  
            - `D` - The processor declined the transaction.  
        responseMessage:
          type: string
          description: Description of the response from the processor.
        processorResponseCode:
          type: string
          description: Original response code that the processor sent.
      required:
        - type
        - status
        - responseCode
      description: Object that contains information about the transaction.
      title: bankTransferResult
    bankTransferPayment:
      type: object
      properties:
        paymentId:
          type: string
          description: Unique identifier that we assigned to the payment.
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        order:
          $ref: '#/components/schemas/bankTransferPaymentOrder'
        customer:
          $ref: '#/components/schemas/bankTransferCustomer'
        bankAccount:
          $ref: '#/components/schemas/BankTransferPaymentBankAccount'
          description: "Polymorphic object that contains bank account information.\n\nThe value of the type field determines which variant you should use:\n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n"
        refunds:
          type: array
          items:
            $ref: '#/components/schemas/refundSummary'
          description: List of refunds issued against the payment.
        returns:
          type: array
          items:
            $ref: '#/components/schemas/bankTransferReturnSummary'
          description: List of returns issued against the payment.
        representment:
          $ref: '#/components/schemas/paymentSummary'
          description: List of re-presented payments linked to the return.
        transactionResult:
          $ref: '#/components/schemas/bankTransferResult'
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
        - bankAccount
        - transactionResult
      description: >-
        Object that contains information about the sale and the customer's bank
        details.
      title: bankTransferPayment
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

POST [https://api.payroc.com/v1/bank-transfer-payments](https://api.payroc.com/v1/bank-transfer-payments)

```curl Store Token Bank Transfer Payment
curl -X POST https://api.payroc.com/v1/bank-transfer-payments \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{
  "processingTerminalId": "1234001",
  "order": {
    "amount": 4999,
    "currency": "USD",
    "orderId": "OrderRef6543",
    "breakdown": {
      "subtotal": 4347,
      "taxes": [
        {
          "rate": 5,
          "name": "Sales Tax",
          "type": "rate"
        }
      ],
      "tip": {
        "type": "percentage",
        "percentage": 10
      }
    },
    "description": "Large Pepperoni Pizza"
  },
  "paymentMethod": {
    "type": "ach",
    "accountNumber": "11101010",
    "nameOnAccount": "Sarah Hazel Hopper",
    "routingNumber": "053200983",
    "accountType": "checking",
    "secCode": "web"
  },
  "customer": {
    "notificationLanguage": "en",
    "contactMethods": [
      {
        "type": "email",
        "value": "joe@blogssoftware.com"
      }
    ]
  },
  "credentialOnFile": {
    "tokenize": true
  },
  "customFields": [
    {
      "name": "yourCustomField",
      "value": "abc123"
    }
  ]
}'
```

```typescript Store Token Bank Transfer Payment
import { PayrocClient } from "payroc";

async function main() {
    const client = new PayrocClient();
    await client.bankTransferPayments.payments.create({
        idempotencyKey: "8e03978e-40d5-43e8-bc93-6894a57f9324",
        processingTerminalId: "1234001",
        order: {
            amount: 4999,
            currency: "USD",
            orderId: "OrderRef6543",
            breakdown: {
                subtotal: 4347,
                taxes: [
                    {
                        rate: 5,
                        name: "Sales Tax",
                        type: "rate",
                    },
                ],
                tip: {
                    type: "percentage",
                    percentage: 10,
                },
            },
            description: "Large Pepperoni Pizza",
        },
        paymentMethod: {
            type: "ach",
            accountNumber: "11101010",
            nameOnAccount: "Sarah Hazel Hopper",
            routingNumber: "053200983",
            accountType: "checking",
            secCode: "web",
        },
        customer: {
            notificationLanguage: "en",
            contactMethods: [
                {
                    type: "email",
                    value: "joe@blogssoftware.com",
                },
            ],
        },
        credentialOnFile: {
            tokenize: true,
        },
        customFields: [
            {
                name: "yourCustomField",
                value: "abc123",
            },
        ],
    });
}
main();

```

```python Store Token Bank Transfer Payment
from payroc import Payroc, BankTransferPaymentRequestOrder, BankTransferRequestBreakdown, TaxRate, Tip, BankTransferCustomer, ContactMethod_Email, SchemasCredentialOnFile, CustomField
from payroc.bank_transfer_payments.payments import BankTransferPaymentRequestPaymentMethod_Ach

client = Payroc()

client.bank_transfer_payments.payments.create(
    idempotency_key="8e03978e-40d5-43e8-bc93-6894a57f9324",
    processing_terminal_id="1234001",
    order=BankTransferPaymentRequestOrder(
        amount=4999,
        currency="USD",
        order_id="OrderRef6543",
        breakdown=BankTransferRequestBreakdown(
            subtotal=4347,
            taxes=[
                TaxRate(
                    rate=5,
                    name="Sales Tax",
                    type="rate",
                )
            ],
            tip=Tip(
                type="percentage",
                percentage=10,
            ),
        ),
        description="Large Pepperoni Pizza",
    ),
    payment_method=BankTransferPaymentRequestPaymentMethod_Ach(
        account_number="11101010",
        name_on_account="Sarah Hazel Hopper",
        routing_number="053200983",
        account_type="checking",
        sec_code="web",
    ),
    customer=BankTransferCustomer(
        notification_language="en",
        contact_methods=[
            ContactMethod_Email(
                value="joe@blogssoftware.com",
            )
        ],
    ),
    credential_on_file=SchemasCredentialOnFile(
        tokenize=True,
    ),
    custom_fields=[
        CustomField(
            name="yourCustomField",
            value="abc123",
        )
    ],
)

```

```java Store Token Bank Transfer Payment
package com.example.usage;

import com.payroc.api.PayrocApiClient;
import com.payroc.api.resources.banktransferpayments.payments.requests.BankTransferPaymentRequest;
import com.payroc.api.resources.banktransferpayments.payments.types.BankTransferPaymentRequestPaymentMethod;
import com.payroc.api.types.AchPayload;
import com.payroc.api.types.AchPayloadAccountType;
import com.payroc.api.types.AchPayloadSecCode;
import com.payroc.api.types.BankTransferCustomer;
import com.payroc.api.types.BankTransferCustomerNotificationLanguage;
import com.payroc.api.types.BankTransferPaymentRequestOrder;
import com.payroc.api.types.BankTransferRequestBreakdown;
import com.payroc.api.types.ContactMethod;
import com.payroc.api.types.ContactMethodEmail;
import com.payroc.api.types.Currency;
import com.payroc.api.types.CustomField;
import com.payroc.api.types.SchemasCredentialOnFile;
import com.payroc.api.types.TaxRate;
import com.payroc.api.types.TaxRateType;
import com.payroc.api.types.Tip;
import com.payroc.api.types.TipType;
import java.util.Arrays;
import java.util.Optional;

public class Example {
    public static void main(String[] args) {
        PayrocApiClient client = PayrocApiClient
            .builder()
            .build();

        client.bankTransferPayments().payments().create(
            BankTransferPaymentRequest
                .builder()
                .idempotencyKey("8e03978e-40d5-43e8-bc93-6894a57f9324")
                .processingTerminalId("1234001")
                .order(
                    BankTransferPaymentRequestOrder
                        .builder()
                        .orderId("OrderRef6543")
                        .amount(4999L)
                        .currency(Currency.USD)
                        .description("Large Pepperoni Pizza")
                        .breakdown(
                            BankTransferRequestBreakdown
                                .builder()
                                .subtotal(4347L)
                                .tip(
                                    Tip
                                        .builder()
                                        .type(TipType.PERCENTAGE)
                                        .percentage(10.0)
                                        .build()
                                )
                                .taxes(
                                    Optional.of(
                                        Arrays.asList(
                                            TaxRate
                                                .builder()
                                                .type(TaxRateType.RATE)
                                                .rate(5.0)
                                                .name("Sales Tax")
                                                .build()
                                        )
                                    )
                                )
                                .build()
                        )
                        .build()
                )
                .paymentMethod(
                    BankTransferPaymentRequestPaymentMethod.ach(
                        AchPayload
                            .builder()
                            .nameOnAccount("Sarah Hazel Hopper")
                            .accountNumber("11101010")
                            .routingNumber("053200983")
                            .accountType(AchPayloadAccountType.CHECKING)
                            .secCode(AchPayloadSecCode.WEB)
                            .build()
                    )
                )
                .customer(
                    BankTransferCustomer
                        .builder()
                        .notificationLanguage(BankTransferCustomerNotificationLanguage.EN)
                        .contactMethods(
                            Optional.of(
                                Arrays.asList(
                                    ContactMethod.email(
                                        ContactMethodEmail
                                            .builder()
                                            .value("joe@blogssoftware.com")
                                            .build()
                                    )
                                )
                            )
                        )
                        .build()
                )
                .credentialOnFile(
                    SchemasCredentialOnFile
                        .builder()
                        .tokenize(true)
                        .build()
                )
                .customFields(
                    Optional.of(
                        Arrays.asList(
                            CustomField
                                .builder()
                                .name("yourCustomField")
                                .value("abc123")
                                .build()
                        )
                    )
                )
                .build()
        );
    }
}
```

```ruby Store Token Bank Transfer Payment
require "payroc"

client = Payroc::Client.new

client.bank_transfer_payments.payments.create(
  idempotency_key: "8e03978e-40d5-43e8-bc93-6894a57f9324",
  processing_terminal_id: "1234001",
  order: {
    amount: 4999,
    currency: "USD",
    order_id: "OrderRef6543",
    breakdown: {
      subtotal: 4347,
      taxes: [{
        rate: 5,
        name: "Sales Tax",
        type: "rate"
      }],
      tip: {
        type: "percentage",
        percentage: 10
      }
    },
    description: "Large Pepperoni Pizza"
  },
  customer: {
    notification_language: "en",
    contact_methods: []
  },
  credential_on_file: {
    tokenize: true
  },
  custom_fields: [{
    name: "yourCustomField",
    value: "abc123"
  }]
)

```

```csharp Store Token Bank Transfer Payment
using Payroc;
using System.Threading.Tasks;
using Payroc.BankTransferPayments.Payments;
using System.Collections.Generic;

namespace Usage;

public class Example
{
    public async Task Do() {
        var client = new PayrocClient();

        await client.BankTransferPayments.Payments.CreateAsync(
            new BankTransferPaymentRequest {
                IdempotencyKey = "8e03978e-40d5-43e8-bc93-6894a57f9324",
                ProcessingTerminalId = "1234001",
                Order = new BankTransferPaymentRequestOrder {
                    Amount = 4999L,
                    Currency = Currency.Usd,
                    OrderId = "OrderRef6543",
                    Breakdown = new BankTransferRequestBreakdown {
                        Subtotal = 4347L,
                        Taxes = new List<TaxRate>(){
                            new TaxRate {
                                Rate = 5,
                                Name = "Sales Tax",
                                Type = TaxRateType.Rate
                            },
                        }
                        ,
                        Tip = new Tip {
                            Type = TipType.Percentage,
                            Percentage = 10
                        }
                    },
                    Description = "Large Pepperoni Pizza"
                },
                PaymentMethod = new BankTransferPaymentRequestPaymentMethod(
                    new AchPayload {
                        AccountNumber = "11101010",
                        NameOnAccount = "Sarah Hazel Hopper",
                        RoutingNumber = "053200983",
                        AccountType = AchPayloadAccountType.Checking,
                        SecCode = AchPayloadSecCode.Web
                    }
                ),
                Customer = new BankTransferCustomer {
                    NotificationLanguage = BankTransferCustomerNotificationLanguage.En,
                    ContactMethods = new List<ContactMethod>(){
                        new ContactMethod(
                            new ContactMethodEmail {
                                Value = "joe@blogssoftware.com"
                            }
                        ),
                    }

                },
                CredentialOnFile = new SchemasCredentialOnFile {
                    Tokenize = true
                },
                CustomFields = new List<CustomField>(){
                    new CustomField {
                        Name = "yourCustomField",
                        Value = "abc123"
                    },
                }

            }
        );
    }

}

```

```go Store Token Bank Transfer Payment
package main

import (
	"fmt"
	"strings"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/bank-transfer-payments"

	payload := strings.NewReader("{\n  \"processingTerminalId\": \"1234001\",\n  \"order\": {\n    \"amount\": 4999,\n    \"currency\": \"USD\",\n    \"orderId\": \"OrderRef6543\",\n    \"breakdown\": {\n      \"subtotal\": 4347,\n      \"taxes\": [\n        {\n          \"rate\": 5,\n          \"name\": \"Sales Tax\",\n          \"type\": \"rate\"\n        }\n      ],\n      \"tip\": {\n        \"type\": \"percentage\",\n        \"percentage\": 10\n      }\n    },\n    \"description\": \"Large Pepperoni Pizza\"\n  },\n  \"paymentMethod\": {\n    \"type\": \"ach\",\n    \"accountNumber\": \"11101010\",\n    \"nameOnAccount\": \"Sarah Hazel Hopper\",\n    \"routingNumber\": \"053200983\",\n    \"accountType\": \"checking\",\n    \"secCode\": \"web\"\n  },\n  \"customer\": {\n    \"notificationLanguage\": \"en\",\n    \"contactMethods\": [\n      {\n        \"type\": \"email\",\n        \"value\": \"joe@blogssoftware.com\"\n      }\n    ]\n  },\n  \"credentialOnFile\": {\n    \"tokenize\": true\n  },\n  \"customFields\": [\n    {\n      \"name\": \"yourCustomField\",\n      \"value\": \"abc123\"\n    }\n  ]\n}")

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

```php Store Token Bank Transfer Payment
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('POST', 'https://api.payroc.com/v1/bank-transfer-payments', [
  'body' => '{
  "processingTerminalId": "1234001",
  "order": {
    "amount": 4999,
    "currency": "USD",
    "orderId": "OrderRef6543",
    "breakdown": {
      "subtotal": 4347,
      "taxes": [
        {
          "rate": 5,
          "name": "Sales Tax",
          "type": "rate"
        }
      ],
      "tip": {
        "type": "percentage",
        "percentage": 10
      }
    },
    "description": "Large Pepperoni Pizza"
  },
  "paymentMethod": {
    "type": "ach",
    "accountNumber": "11101010",
    "nameOnAccount": "Sarah Hazel Hopper",
    "routingNumber": "053200983",
    "accountType": "checking",
    "secCode": "web"
  },
  "customer": {
    "notificationLanguage": "en",
    "contactMethods": [
      {
        "type": "email",
        "value": "joe@blogssoftware.com"
      }
    ]
  },
  "credentialOnFile": {
    "tokenize": true
  },
  "customFields": [
    {
      "name": "yourCustomField",
      "value": "abc123"
    }
  ]
}',
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```swift Store Token Bank Transfer Payment
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]
let parameters = [
  "processingTerminalId": "1234001",
  "order": [
    "amount": 4999,
    "currency": "USD",
    "orderId": "OrderRef6543",
    "breakdown": [
      "subtotal": 4347,
      "taxes": [
        [
          "rate": 5,
          "name": "Sales Tax",
          "type": "rate"
        ]
      ],
      "tip": [
        "type": "percentage",
        "percentage": 10
      ]
    ],
    "description": "Large Pepperoni Pizza"
  ],
  "paymentMethod": [
    "type": "ach",
    "accountNumber": "11101010",
    "nameOnAccount": "Sarah Hazel Hopper",
    "routingNumber": "053200983",
    "accountType": "checking",
    "secCode": "web"
  ],
  "customer": [
    "notificationLanguage": "en",
    "contactMethods": [
      [
        "type": "email",
        "value": "joe@blogssoftware.com"
      ]
    ]
  ],
  "credentialOnFile": ["tokenize": true],
  "customFields": [
    [
      "name": "yourCustomField",
      "value": "abc123"
    ]
  ]
] as [String : Any]

let postData = JSONSerialization.data(withJSONObject: parameters, options: [])

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/bank-transfer-payments")! as URL,
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

If your request is successful, our gateway uses the bank account details to run a sale. The response contains the following fields:

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /bank-transfer-payments:
    post:
      operationId: create
      summary: Create payment
      description: "Use this method to run a sale with a customer's bank account details.  \n\nIn the response, our gateway returns information about the bank transfer payment and a paymentId, which you need for the following methods:  \n-\t[Retrieve payment](https://docs.payroc.com/api/schema/bank-transfer-payments/payments/retrieve) - View the details of the bank transfer payment.\n-\t[Reverse payment](https://docs.payroc.com/api/schema/bank-transfer-payments/refunds/reverse-payment) - Cancel the bank transfer payment if it's an open batch.\n-\t[Refund payment](https://docs.payroc.com/api/schema/bank-transfer-payments/refunds/refund) - Run a referenced refund to return funds to the customer's bank account.\n\n**Payment methods**  \n\nOur gateway accepts the following payment methods:  \n-\tAutomated clearing house (ACH) details\n-\tPre-authorized debit (PAD) details  \n\nYou can also use [secure tokens](https://docs.payroc.com/api/schema/payments/secure-tokens/overview) and [single-use tokens](https://docs.payroc.com/api/schema/tokenization/single-use-tokens/create) that you created from ACH details or PAD details. \n"
      tags:
        - >-
          subpackage_bankTransferPayments.subpackage_bankTransferPayments/payments
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
          description: Successful request. We processed the sale.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/bankTransferPayment'
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
              $ref: '#/components/schemas/bankTransferPaymentRequest'
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
    taxRate:
      type: object
      properties:
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
        - rate
        - name
      title: taxRate
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
    bankTransferRequestBreakdown:
      type: object
      properties:
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/taxRate'
          description: Array of tax objects.
        subtotal:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction before tax and tip. The value is in
            the currency's lowest denomination, for example, cents.
        tip:
          $ref: '#/components/schemas/tip'
          description: Object that contains tip information for the transaction.
      required:
        - subtotal
      description: Object that contains information about the transaction.
      title: bankTransferRequestBreakdown
    bankTransferPaymentRequestOrder:
      type: object
      properties:
        orderId:
          type: string
          description: A unique identifier assigned by the merchant.
        dateTime:
          type: string
          format: date-time
          description: >-
            The processing date and time of the transaction represented as per
            [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard.
        description:
          type: string
          description: A brief description of the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            The total amount in the currency's lowest denomination. For example,
            cents.
        currency:
          $ref: '#/components/schemas/currency'
        breakdown:
          $ref: '#/components/schemas/bankTransferRequestBreakdown'
      required:
        - orderId
        - amount
        - currency
      description: Object that contains information about the transaction.
      title: bankTransferPaymentRequestOrder
    BankTransferCustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >-
        Customer's preferred notification language. This code follows the [ISO
        639-1](https://www.iso.org/iso-639-language-code) standard.
      title: BankTransferCustomerNotificationLanguage
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
    bankTransferCustomer:
      type: object
      properties:
        notificationLanguage:
          $ref: '#/components/schemas/BankTransferCustomerNotificationLanguage'
          description: >-
            Customer's preferred notification language. This code follows the
            [ISO 639-1](https://www.iso.org/iso-639-language-code) standard.
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
      description: Object that contains information about the customer.
      title: bankTransferCustomer
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
    BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** For bank account details, send a value for accountType.
      title: >-
        BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType
    BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode:
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


        **Note:** This field is mandatory for ACH payments and unreferenced
        refunds.
      title: BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode
    BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  
        **Note:** For bank account details, send a value for accountType.
      title: >-
        BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType
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
    BankTransferPaymentRequestPaymentMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - ach
              description: 'Discriminator value: ach'
            accountType:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** For bank account details, send a value for
                accountType.
            secCode:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory for ACH payments and
                unreferenced refunds.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >
                Customer’s bank account number.  

                **Note:** In responses, our gateway shows only the last four
                digits of the account number, for example, `*****5929`.
            routingNumber:
              type: string
              description: Nine-digit number that identifies the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: >-
            Object that contains information about the payment details for the
            customer’s automated clearing house (ACH) transactions.
        - type: object
          properties:
            type:
              type: string
              enum:
                - pad
              description: 'Discriminator value: pad'
            accountType:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType
              description: >
                Indicates the customer’s account type.  

                **Note:** For bank account details, send a value for
                accountType.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >
                Customer's account number.  

                **Note:** In responses, our gateway shows only the last four
                digits of the account number, for example, `*****5929`.
            transitNumber:
              type: string
              description: Five-digit number that identifies the customer's bank branch.
            institutionNumber:
              type: string
              description: Three-digit number that identifies the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: >-
            Object that contains information about the payment details for the
            customer’s preauthorized electronic debit (PAD) transactions.
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
      description: "Polymorphic object that contains payment detail information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`secureToken` - Secure token details\n-\t`singleUseToken` - Single-use token details\n"
      title: BankTransferPaymentRequestPaymentMethod
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
    bankTransferPaymentRequest:
      type: object
      properties:
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        order:
          $ref: '#/components/schemas/bankTransferPaymentRequestOrder'
        customer:
          $ref: '#/components/schemas/bankTransferCustomer'
        credentialOnFile:
          $ref: '#/components/schemas/schemas-credentialOnFile'
        paymentMethod:
          $ref: '#/components/schemas/BankTransferPaymentRequestPaymentMethod'
          description: "Polymorphic object that contains payment detail information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`secureToken` - Secure token details\n-\t`singleUseToken` - Single-use token details\n"
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - processingTerminalId
        - order
        - paymentMethod
      description: >-
        Object that contains information about the sale and the customer's bank
        details.
      title: bankTransferPaymentRequest
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
    bankTransferBreakdown:
      type: object
      properties:
        taxes:
          type: array
          items:
            $ref: '#/components/schemas/retrievedTax'
          description: Array of tax objects.
        subtotal:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction before tax and tip. The value is in
            the currency's lowest denomination, for example, cents.
        tip:
          $ref: '#/components/schemas/tip'
          description: Object that contains tip information for the transaction.
      required:
        - subtotal
      description: Object that contains information about the transaction.
      title: bankTransferBreakdown
    bankTransferPaymentOrder:
      type: object
      properties:
        orderId:
          type: string
          description: A unique identifier assigned by the merchant.
        dateTime:
          type: string
          format: date-time
          description: >-
            The processing date and time of the transaction represented as per
            [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard.
        description:
          type: string
          description: A brief description of the transaction.
        amount:
          type: integer
          format: int64
          description: >-
            The total amount in the currency's lowest denomination. For example,
            cents.
        currency:
          $ref: '#/components/schemas/currency'
        breakdown:
          $ref: '#/components/schemas/bankTransferBreakdown'
      required:
        - orderId
        - amount
        - currency
      description: Object that contains information about the transaction.
      title: bankTransferPaymentOrder
    BankTransferRefundBankAccountDiscriminatorMappingAchSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: |
        Indicates the type of authorization for the transaction.  

        **Note:** The field is mandatory for ACH secure token.  

        - `web` – Online transaction.  
        - `tel` – Telephone transaction.  
        - `ccd` – Corporate credit card or debit card transaction.  
        - `ppd` – Pre-arranged transaction.
      title: BankTransferRefundBankAccountDiscriminatorMappingAchSecCode
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
    BankTransferPaymentBankAccount:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - ach
              description: 'Discriminator value: ach'
            secCode:
              $ref: >-
                #/components/schemas/BankTransferRefundBankAccountDiscriminatorMappingAchSecCode
              description: |
                Indicates the type of authorization for the transaction.  

                **Note:** The field is mandatory for ACH secure token.  

                - `web` – Online transaction.  
                - `tel` – Telephone transaction.  
                - `ccd` – Corporate credit card or debit card transaction.  
                - `ppd` – Pre-arranged transaction.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >-
                Customer's bank account number. We mask all digits except the
                last four digits.
            routingNumber:
              type: string
              description: >
                Routing number of the customer’s account.


                **Note:** In responses, our gateway shows only the last four
                digits of the account's routing number, for example, *****4162. 
            secureToken:
              $ref: '#/components/schemas/secureTokenSummary'
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: Object that contains the customer's account details.
        - type: object
          properties:
            type:
              type: string
              enum:
                - pad
              description: 'Discriminator value: pad'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >-
                Customer's bank account number. We mask all digits except the
                last four digits.
            transitNumber:
              type: string
              description: Five-digit code that represents the customer's banking branch.
            institutionNumber:
              type: string
              description: Three-digit code that represents the customer's bank.
            secureToken:
              $ref: '#/components/schemas/secureTokenSummary'
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: Object that contains the customer's account details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains bank account information.\n\nThe value of the type field determines which variant you should use:\n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n"
      title: BankTransferPaymentBankAccount
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
    bankTransferReturnSummary:
      type: object
      properties:
        paymentId:
          type: string
          description: Unique identifier that our gateway assigned to the payment.
        date:
          type: string
          format: date
          description: The date that the check was returned.
        returnCode:
          type: string
          description: The NACHA return code.
        returnReason:
          type: string
          description: The reason why the check was returned.
        represented:
          type: boolean
          description: Indicates whether the return has been re-presented.
        link:
          $ref: '#/components/schemas/link'
      required:
        - paymentId
        - date
        - returnCode
        - returnReason
        - represented
      description: Object that contains information about a return.
      title: bankTransferReturnSummary
    PaymentSummaryStatus:
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
      description: Current status of the payment.
      title: PaymentSummaryStatus
    PaymentSummaryResponseCode:
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
      title: PaymentSummaryResponseCode
    paymentSummary:
      type: object
      properties:
        paymentId:
          type: string
          description: Unique identifier of the payment.
        dateTime:
          type: string
          format: date-time
          description: Date and time that the payment was processed.
        currency:
          $ref: '#/components/schemas/currency'
        amount:
          type: integer
          format: int64
          description: >-
            Amount of the payment. This value is in the currency’s lowest
            denomination, for example, cents.
        status:
          $ref: '#/components/schemas/PaymentSummaryStatus'
          description: Current status of the payment.
        responseCode:
          $ref: '#/components/schemas/PaymentSummaryResponseCode'
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
        link:
          $ref: '#/components/schemas/link'
      required:
        - paymentId
        - dateTime
        - currency
        - amount
        - status
        - responseCode
      description: Object that contains information about a payment.
      title: paymentSummary
    BankTransferResultType:
      type: string
      enum:
        - payment
        - refund
        - unreferencedRefund
        - accountVerification
      description: Type of transaction.
      title: BankTransferResultType
    BankTransferResultStatus:
      type: string
      enum:
        - ready
        - pending
        - declined
        - complete
        - admin
        - reversal
        - returned
      description: Status of the transaction.
      title: BankTransferResultStatus
    bankTransferResult:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/BankTransferResultType'
          description: Type of transaction.
        status:
          $ref: '#/components/schemas/BankTransferResultStatus'
          description: Status of the transaction.
        authorizedAmount:
          type: integer
          format: int64
          description: |
            Amount of the transaction.  
            **Note:** The amount is negative for a refund.
        currency:
          $ref: '#/components/schemas/currency'
        responseCode:
          type: string
          description: |
            Response from the processor.  
            - `A` - The processor approved the transaction.  
            - `D` - The processor declined the transaction.  
        responseMessage:
          type: string
          description: Description of the response from the processor.
        processorResponseCode:
          type: string
          description: Original response code that the processor sent.
      required:
        - type
        - status
        - responseCode
      description: Object that contains information about the transaction.
      title: bankTransferResult
    bankTransferPayment:
      type: object
      properties:
        paymentId:
          type: string
          description: Unique identifier that we assigned to the payment.
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        order:
          $ref: '#/components/schemas/bankTransferPaymentOrder'
        customer:
          $ref: '#/components/schemas/bankTransferCustomer'
        bankAccount:
          $ref: '#/components/schemas/BankTransferPaymentBankAccount'
          description: "Polymorphic object that contains bank account information.\n\nThe value of the type field determines which variant you should use:\n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n"
        refunds:
          type: array
          items:
            $ref: '#/components/schemas/refundSummary'
          description: List of refunds issued against the payment.
        returns:
          type: array
          items:
            $ref: '#/components/schemas/bankTransferReturnSummary'
          description: List of returns issued against the payment.
        representment:
          $ref: '#/components/schemas/paymentSummary'
          description: List of re-presented payments linked to the return.
        transactionResult:
          $ref: '#/components/schemas/bankTransferResult'
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
        - bankAccount
        - transactionResult
      description: >-
        Object that contains information about the sale and the customer's bank
        details.
      title: bankTransferPayment
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
    "amount": 4999,
    "currency": "USD",
    "orderId": "OrderRef6543",
    "breakdown": {
      "subtotal": 4347,
      "taxes": [
        {
          "name": "Sales Tax",
          "rate": 5,
          "amount": 217
        }
      ],
      "tip": {
        "type": "percentage",
        "amount": 435,
        "percentage": 10
      }
    },
    "dateTime": "2024-07-02T15:30:00Z",
    "description": "Large Pepperoni Pizza"
  },
  "bankAccount": {
    "type": "ach",
    "accountNumber": "****3159",
    "nameOnAccount": "Sarah Hazel Hopper",
    "routingNumber": "053200983",
    "secCode": "web",
    "secureToken": {
      "secureTokenId": "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
      "customerName": "Sarah Hazel Hopper",
      "token": "296753123456",
      "status": "notValidated",
      "link": {
        "rel": "self",
        "method": "GET",
        "href": "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa"
      }
    }
  },
  "transactionResult": {
    "type": "payment",
    "status": "ready",
    "responseCode": "A",
    "authorizedAmount": 4999,
    "currency": "USD",
    "responseMessage": "NoError",
    "processorResponseCode": "0"
  },
  "customer": {
    "notificationLanguage": "en",
    "contactMethods": [
      {
        "type": "email",
        "value": "sarah.hopper@example.com"
      }
    ]
  },
  "customFields": [
    {
      "name": "yourCustomField",
      "value": "abc123"
    }
  ]
}
```
> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-fields/extend-your-integration/close-a-session.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Close a Hosted Fields session

**Important:** To call the destroy method, you must be using one of the following versions of our Hosted Fields JavaScript library:

* **Test** - 1.7.0.261457
* **Production** - 1.7.0.261471

To close an idle session of Hosted Fields, call the destroy method in your JavaScript.

```js
const hostedFields = new Payroc.hostedFields(options);
hostedFields.destroy(); 
```

After calling the destroy method, you must start a new Hosted Fields session before you can take payment from the customer. For more information about how to generate a session token, go to [Authenticate your Hosted Fields session](../authenticate-your-session).

**Note:** You don't need to use this method for every integration, but it is considered good practice in scenarios where Hosted Fields might run on more than one session, for example, in single-page applications.

## What does the destroy method do?

* Removes our event listener associated with the session, so that we don't receive messages from more than one session.
* Prevents further communication between the Hosted Fields JavaScript library and your Hosted Fields.
* Helps to avoid memory leaks and duplicate event handling.
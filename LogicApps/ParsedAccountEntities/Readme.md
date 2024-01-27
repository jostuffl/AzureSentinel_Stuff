# Parsed Account Entities
----

This logic app is meant to serve as a base configuration for other automations when you are working with Accounts in the various entity types from Sentinel.
Most of the template logic apps for sentinel expect that the account be an account entity, but you may find sometimes that the account you want to run
your automation on is not an actual Account Entity, but rather part of an Email Entity, or a Mailbox Entity. Most (if not all) template logic apps in Sentinel will break
if you try and run them on an incident with an Email Entity or Mailbox Entity, because the account doesn't match the format expected.

So the goal of this logic app is to provide a base configuration that will extract out all Accounts from the various entity types (Account, Email, Mailbox),
and even resolve user's AAD ID to their upn.

The output of this logic app is an array variable with a deduplicated list of all Accounts present in the Sentinel Entities. From there you
can add in what ever other steps you want the automation to perform. Such as resetting a user's session, or password.

Deploy the logic app by clicking the blue button below:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Fmain%2FLogicApps%2FParsedAccountEntities%2FParsedAccountEntities.json)

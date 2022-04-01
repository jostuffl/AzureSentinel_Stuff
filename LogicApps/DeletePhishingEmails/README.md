# Delete Phishing Emails

This logic app was made for the use case that an internal user account has been compromised and used to send out phishing emails to other internal users.
There is also an azure automation runbook that is paired with this logic app, but it is optional. If you do not use the runbook all you need to do is submit a post
request to the url of the trigger in the logic app with a sender and either an internetmessageid or subject (or both).

You could use this to remediate phishing emails sent from external sources, but for the **Sender** parameter you would still need to put an
internal user. This is so the logic app has an initial user to gather the internetmessageid(s) from. 


Deploy it to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Fmain%2FLogicApps%2FDeletePhishingEmails%2Fazuredeploy.json)

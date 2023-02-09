# Delete Phishing Emails

This is another logic app I created to delete phishing emails from internal user's inboxes. It does require the ingestion of the EmailEvents advanced hunting data from M365 Defender.
The KQL used in the logic app to grab the phishing email details
could probably be tuned a little bit more, but should serve the function. This is paired with an analytic rule (That is similar to the kql in the logic app, if not the same),
to generate an incident with the necessary entities for this to run. That's not to say you couldn't create your own analytic rule, so long as it provides
the account entity needed to perform the steps in the logic app.

It should be pretty clear from the title, but out of caution I'll say it anyway.

**THIS WILL DELETE ALL EMAILS THAT MATCH THE CRITERIA IN ALL USERS INBOXES THAT ARE RETURNED BY THE KQL.**
**YOU ARE RESPONSIBLE FOR VALIDATING, TESTING, AND MAKING SURE THIS LOGIC APP PERFORMS AS EXPECTED.**
**I AM NOT RESPONSIBLE FOR ANY DAMAGE DONE BY YOU RUNNING THIS IN YOUR ENVIRONMENT. YOU HAVE BEEN WARNED.**

With that being said, the logic app should perform a **soft** delete of any emails that it deletes.
Meaning that a user should be able to recover them by going to their trash and clicking "Recover Deleted Items".

By default the query looks back at the last 2 hours, you may want to adjust this.
It also has the threshold set to 100 emails sent, again you may want to increase that.


Deploy it to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Fmain%2FLogicApps%2FPhishingDeleteImproved%2Fazuredeploy.json)

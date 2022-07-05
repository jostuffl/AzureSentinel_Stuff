# Logic App to revoke / reset a user account based on a Microsoft Sentinel Alert

This logic app is triggered when an Azure Sentinel Alert is created.
It parses out the account entities, and for each account it disables the account on-prem / in azure ad,
resets tokens, revokes mfa, and resets the users password. 
It is paired with two Azure Automation runbooks:
[MFA_Runbook](https://github.com/jostuffl/AzureSentinel_Stuff/blob/main/Scripts/ResetMFA.ps1)
[DisableUserOnPrem](https://github.com/jostuffl/AzureSentinel_Stuff/blob/main/Scripts/DisableUserOnPrem.ps1)

You will need to change the automation account information in the "Create Job" and Create Job 2" blocks 
to your automation account / runbook / hybrid worker.
You will also need to update the API connections for each block (Should see a yellow triangle with an exclamation point)

----

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Fmain%2FLogicApps%2FReset-Revoke-User%2Fazuredeploy.json)

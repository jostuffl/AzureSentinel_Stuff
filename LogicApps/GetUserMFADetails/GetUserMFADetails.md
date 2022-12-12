# Get User MFA Details - Watchlist
----

This logic app was created for the purpose of retrieving all Azure AD user's MFA details and putting that information into a Microsoft Sentinel Watchlist. There is an accompanying powershell script that pairs with this to do the actual MFA details retrieving. The powershell script is meant to be run as a runbook (or hybrid runbook worker if you have a lot of users), however it could be modified to run on-prem or somewhere else. Link to the powershell folder where the script is stored: [Powershell Script Folder](https://github.com/jostuffl/AzureSentinel_Stuff/tree/main/Scripts/GetUserMFADetails)

To deploy the logic app simply click the blue **Deploy To Azure** button and input the required information.

The logic app uses a managed identity for the Sentinel API connection, and must be granted **Sentinel Contributor** permissions to the resource group where your Sentinel instance is located.


**Deploy:**

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2Fjostuffl%2FAzureSentinel_Stuff%2Fblob%2Fmain%2FLogicApps%2FGetUserMFADetails%2FGetUserMFADetails.json)

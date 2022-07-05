# This Logic App is for creating / updating a Microsoft Sentinel watchlist for conditional Access Exclusions

The Logic App takes a webhook of data, parses it, deletes the watchlist (if already created), waits 2 minutes for the delete to go through, then recreates it with the new data.
The reason I chose to delete the watchlist vs updating is it was less complicated and allows the watchlist to still function correctly.
To deploy simply click the deploy to azure button. You will also need the accompanying powershell script, which can be found in the scripts section of my github.

----

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Fmain%2FLogicApps%2FConditionalAccessExclusions_Watchlist%2Fazuredeploy.json)

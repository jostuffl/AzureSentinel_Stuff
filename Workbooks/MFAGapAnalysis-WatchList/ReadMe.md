# MFA Gap Analysis - Watchlist edition

The workbook in this folder is meant to be paired with a powershell script and logic app.

The Powershell script can be found here: [Powershell_Script](https://github.com/jostuffl/AzureSentinel_Stuff/blob/main/Scripts/ConditionalAccessExclusions_Watchlist.ps1)

The Logic App can be found here: [Logic_App](https://github.com/jostuffl/AzureSentinel_Stuff/tree/main/LogicApps/ConditionalAccessExclusions_Watchlist)

To use the workbook simply select the json file in this folder, click "Raw" on the new page that opens, copy all the code, go to Microsoft Sentinel, go to workbooks,
create new workbook, hit Edit, select the "</>" icon, remove all code from the new page, paste in workbook code, hit apply.

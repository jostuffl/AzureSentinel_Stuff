# Delete Phishing Emails Webhook Powershell Script
___

The script below is meant to be paired with the Logic App "DeletePhishingEmails" (which I will upload at some point).
This can be run locally with powershell, or in an Azure Automation account as a runbook.
Make sure you change the $Uri variable "**YOUR-LOGIC-APP-WEBHOOK**"




```Powershell
param (

[Parameter(Mandatory)]
[string]$Sender,

[Parameter(Mandatory)]
[string]$Subject,

[Parameter(HelpMessage="Optional, can leave blank")]
[String]$InternetMessageId

)

$Uri = 'YOUR-LOGIC-APP-WEBHOOK'


$Body = @{
"Sender"= "$Sender"
"Subject"= "$Subject"
"InternetMessageId"= "$InternetMessageId"
}

Invoke-WebRequest -uri $Uri -Body ($Body|ConvertTo-Json) -ContentType "application/json" -usebasicparsing -Method POST -verbose
```

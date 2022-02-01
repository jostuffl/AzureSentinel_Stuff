<#  Created by Jonathon Stufflebeam
    jostuffl@microsoft.com
    2-1-2022
    
    This is the Azure Runbook edition of the script, and is meant to be run in Azure automation using a Managed Identity.

    This powershell script is meant to close duplicate alerts that have already previously been closed in Microsoft Sentinel.
    To best use this script your Analytic Rules should have unique titles using custom entity data.
    Such as "Unfamiliar Sign-in Properties - <USERUPN>" - Where USERUPN would be the upn of the user that triggered the alert.
    You can add custom data to your Alert Titles in the Analytic Rule under Custom Details.

    While this script was meant to be used as an Azure Runbook set on a schedule, it can be used standalone as well.
    The script currently closes the Incidents as "BenignPositive" and "SuspiciousButExpected". Feel free to change this to feet your needs.
    It also only looks at incidents within the last 1 day.
#>

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

#Change these values to match your environment
$Resourcegroup = "YourSentinelWorkspaceResourceGroup"
$workspace = "YourSentinelWorkspaceName"

$GetIncidents = Get-AzSentinelIncident -resourcegroup $Resourcegroup -workspace $workspace

#Change the "Test IP Alert" to match the Incident title you want to match against.
$LastDayIncidents = $GetIncidents | where {$_.Title -like "Test IP Alert*"} | select IncidentNumber, Title, ClassificationComment, Status , Id, CreatedTimeUTC | where {$_.CreatedTimeUTC -gt (get-date).AddDays(-1)}

$ClosedIncidents = $LastDayIncidents | where {$_.Status -eq "Closed"}
$OpenIncidents = $GetIncidents | where {$_.Status -ne "Closed"}

foreach($ClosedIncident in $ClosedIncidents){
    foreach($OpenIncident in $OpenIncidents){
        if($OpenIncident.Title -eq $ClosedIncident.Title){
            write-host "Closing duplicate incident $($OpenIncident.Title)" -BackgroundColor Black -ForegroundColor Yellow
           $OpenIncident | Update-AzSentinelIncident -Classification BenignPositive -ClassificationReason SuspiciousButExpected -ClassificationComment "Closing Duplicate Incident" -Status Closed
        }
    }
}

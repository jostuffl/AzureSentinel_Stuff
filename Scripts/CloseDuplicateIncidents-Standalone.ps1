<#  Created by Jonathon Stufflebeam
    jostuffl@microsoft.com
    2-1-2022
    
    This is the Standalone version of this script.

    This powershell script is meant to close duplicate alerts that have already previously been closed in Microsoft Sentinel.
    To best use this script your Analytic Rules should have unique titles using custom entity data.
    Such as "Unfamiliar Sign-in Properties - <USERUPN>" - Where USERUPN would be the upn of the user that triggered the alert.
    You can add custom data to your Alert Titles in the Analytic Rule under Custom Details.

    The script currently closes the Incidents as "BenignPositive" and "SuspiciousButExpected". Feel free to change this to feet your needs.
    It also only looks at incidents within the last 1 day.
#>

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

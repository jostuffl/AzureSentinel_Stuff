# You may want to change what the incidents are closed as for classification and classification reason
Import-Module Az.Accounts
Connect-AzAccount
$Workspace = "YOUR SENTINEL WORKSPACE NAME"
$ResourceGroup = "YOUR SENTINEL RESOURCE GROUP"
$incidents = get-azsentinelincident -WorkspaceName $Workspace -ResourceGroupName $ResouruceGroup

foreach($incident in $incidents){

$i = ([string]$incident.id -split '/')[-1]

    Write-Host "Closing Incident $($incident.id)"

    Update-AzSentinelIncident -ResourceGroupName $ResourceGroup -WorkspaceName $Workspace -Severity $Incident.Severity -IncidentID $i -Status Closed -Title $incident.Title -Classification BenignPositive -ClassificationReason SuspiciousButExpected -Verbose

}

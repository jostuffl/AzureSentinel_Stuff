# Make sure to change where it says "YOUR TENANT ID" and "YOUR LOGIC APP NAME"
# You will also need to change the part where it says "YOUR PERMISSIONS" to match the permissions you want to grant.
# I did not build this script, but can't remember where I pulled it from.

Import-Module -Name 'Microsoft.Graph'
$DestinationTenantId = "YOUR TENANT ID"
$MsiName = "YOUR LOGIC APP NAME" # Name of system-assigned or user-assigned managed service identity. (System-assigned use same name as resource).
$oPermissions = @(
  "YOUR PERMISSIONS"
)
$GraphAppId = "00000003-0000-0000-c000-000000000000" # Don't change this.
Connect-AzAccount
Connect-MgGraph -TenantId $DestinationTenantId -scope ("AppRoleAssignment.ReadWrite.All","Application.Read.All","Directory.Read.All")

$oMsi = Get-AzADServicePrincipal -DisplayName "$MsiName"
$oGraphSpn = Get-AzADServicePrincipal -ApplicationId "$GraphAppId"
$oAppRole = $oGraphSpn.AppRole | Where-Object {($_.Value -in $oPermissions) -and ($_.AllowedMemberType -contains "Application")}

foreach($AppRole in $oAppRole)
{
  $oAppRoleAssignment = @{
    "PrincipalId" = $oMSI.Id
    "ResourceId" = $oGraphSpn.Id
    "AppRoleId" = $AppRole.Id
  }
  New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $oAppRoleAssignment.PrincipalId `
    -BodyParameter $oAppRoleAssignment `
    -Verbose
}

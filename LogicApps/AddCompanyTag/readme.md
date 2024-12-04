# Add the Company property of a user to an incident as a tag

This adds a tag to an incident with the each user's Company name, which is a property in both Entra ID and AD. In this instance it retrieves it from Entra ID using the Graph Api and a managed identity.
you will need to grant the managed identity Sentinel permissions and Graph permissions (See below). To deploy click the blue button below.


[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Frefs%2Fheads%2Fmain%2FLogicApps%2FAddCompanyTag%2Fazuredeploy.json)

|Type Of Permission | HTML 
|----------------|-------------------------------
|Sentinel |`Sentinel Responder`
|Entra ID   |`User.Read.All`
| Entra ID   | `Directory.Read.All`

## How To Grant Entra ID Permissions for Managed Identity

```Powershell
# I did not create this powershell script. I pulled it from a template logic app from the Sentinel Github. I can't remember which one, but credit goes to them for making it.

Import-Module -Name 'Microsoft.Graph'
Import-Module -Name 'Az'
# Uncomment the line below if you run into issues authenticating to azure.
# Update-AzConfig -EnableLoginByWam $false
$DestinationTenantId = "Your Tenant ID"
$MsiName = "Your Logic app Name"

$oPermissions = @(
  "Directory.Read.All",
  "User.Read.All
)

$GraphAppId = "00000003-0000-0000-c000-000000000000" # Don't change this.
Connect-AzAccount -DeviceCode -TenantId $DestinationTenantId 
Connect-MgGraph -scope ("AppRoleAssignment.ReadWrite.All","Application.Read.All","Directory.Read.All") -TenantId $DestinationTenantId

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
```

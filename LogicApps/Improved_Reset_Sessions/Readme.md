# Improved Reset Sessions Automation
----

I created this improved version of Reset Sessions automation because of a frequent and common issue I experience with people. The template
Logic Apps for resetting sessions do not function if the account is part of an Email Entity or Mailbox Entity. So I created my base template that
extracts accounts from all 3 entity types and added in resetting the user's sessions to form this logic app.

## Steps to Deploy
1. Click the big blue button to open the deployment wizard
2. Fill out the required information. (Make sure you put your domain in the UPN Suffix parameter, e.g. jostuffl.com)
3. Deploy the Logic App
4. Grant the managed identity Sentinel Responder permissions
5. Grant the managed identity User.ReadWrite.All permissions (see powershell below)
6. Profit

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Fmain%2FLogicApps%2FImproved_Reset_Sessions%2FParse_and_Revoke.json)

The code below is meant to be run in powershell. It grants the managed identity graph permissions for resetting sessions.
Replace where it says "YOUR TENANT ID" with your tenant id.
Replace where it says "THE NAME OF YOUR LOGIC APP" with the name you saved the logic app as
Then run the script. Important to note that I did not create this script, but modified it to work in this use-case


```
$DestinationTenantId = "YOUR TENANT ID"

$MsiName = "THE NAME OF THE LOGIC APP" # Name of system-assigned or user-assigned managed service identity. (System-assigned use same name as resource).

Connect-AzAccount -AuthScope MicrosoftGraphEndpointResourceId

$oPermissions = @(
  "User.ReadWrite.All"
)

$GraphAppId = "00000003-0000-0000-c000-000000000000" # Don't change this.

$oMsi = Get-AzADServicePrincipal -Filter "displayName eq '$MsiName'"
$oGraphSpn = Get-AzADServicePrincipal -Filter "appId eq '$GraphAppId'"

$oAppRole = $oGraphSpn.AppRole | Where-Object {($_.Value -in $oPermissions) -and ($_.AllowedMemberType -contains "Application")}

Connect-MgGraph -TenantId $DestinationTenantId 

foreach($AppRole in $oAppRole)
{
  $oAppRoleAssignment = @{
    "PrincipalId" = $oMSI.Id
    #"ResourceId" = $GraphAppId
    "ResourceId" = $oGraphSpn.Id
    "AppRoleId" = $AppRole.Id
  }
  
  New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $oAppRoleAssignment.PrincipalId `
    -BodyParameter $oAppRoleAssignment `
    -Verbose
}
```

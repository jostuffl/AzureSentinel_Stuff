<# 
Created by Jonathon Stufflebeam 6-10-22

This powershell script is meant to be run as an azure runbook.
It pulls down all Conditional Access Policies that have exclusions,
iterates through each, looking for excluded groups / users, and adds them to an array.
It then creates a csv file with the exclusions and uploads it to azure blog storage.

The script uses Cert based App authentication, so you will need to have
an App Registration in Azure AD with the correct Graph Permissions (Group.Read.All, Policy.Read.All,User.Read.All),
and you will also need to have uploaded a certificate to the App Registration. Then you upload the
private key to Azure Automation and put the thumbprint for it in the script variables.
#>

# Modules to Import
Import-Module ("Microsoft.Graph.Identity.SignIns","Microsoft.Graph.Users","Microsoft.Graph.Groups","Az.Storage")

#Variables
$SasToken = "Your Sas Token"
$StorageAccName = "Your Storage Account Name"
$StorageContainer= "Your Blob container name"
#$Cert = Get-AutomationCertificate -Name "Your automation certificate"
$TenantId = "Tenant ID"
$AppId = "App (also known as client) ID"
$CertificateThumbPrint = "Certificate Thumbprint of your cert"


# Connect to Graph with App Cert based auth
Connect-MgGraph -TenantId "$TenantId" -AppId "$AppId" -CertificateThumbprint "$CertificateThumbPrint"

# Get Conditional Access Policies and store in variable
$CAPs = Get-MgIdentityConditionalAccessPolicy

#Initialize array variables
[System.Collections.ArrayList]$PolicyArray = @()

# For each Conditional Access Policy, for each group excluded, create custom object and add to our array
foreach ($Policy in $CAPs){
    foreach($GroupExclusion in $Policy.Conditions.Users.ExcludeGroups){
        $GetGroup = (Get-mggroup -groupid ($GroupExclusion).tostring())
        $PolicyObject = [PSCustomObject]@{
            PolicyName = $Policy.DisplayName
            PolicyId = $Policy.Id
            ExcludedGroups = $GetGroup.DisplayName
            ExcludedUsers = $null
        }

        $PolicyArray.Add($PolicyObject) | out-null
    }


# For each Conditional Access Policy, for each user excluded, create custom object and add to our array
    foreach($UserExclusion in $Policy.Conditions.Users.ExcludeUsers){
        if($UserExclusion -eq "GuestsOrExternalUsers"){
            
            $GetUser = "GuestsOrExternalUsers"

            $PolicyObject = [PSCustomObject]@{
            PolicyName = $Policy.DisplayName
            PolicyId = $Policy.Id
            ExcludedGroups = $null
            ExcludedUsers = $GetUser

            }
        }
        else{

            $GetUser = Get-mguser -userid $UserExclusion

            $PolicyObject = [PSCustomObject]@{
            PolicyName = $Policy.DisplayName
            PolicyId = $Policy.Id
            ExcludedGroups = $null
            ExcludedUsers = $GetUser.UserPrincipalName
            }
        }
        $PolicyArray.Add($PolicyObject) | out-null        
    
    }

}

# Export array to CSV
$PolicyArray | export-csv .\ConditionalAccessPolicyExclusions.csv -NoTypeInformation

# Upload to azure blog storage
$AzStorage = New-AzStorageContext -StorageAccountName "$StorageAccName" -SasToken "$SasToken"
Set-AzStorageBlobContent -File ".\ConditionalAccessPolicyExclusions.csv" -Container "$StorageContainer" -Context $AzStorage -force

# Clean up by removing csv
Remove-Item "ConditionalAccessPolicyExclusions.csv"

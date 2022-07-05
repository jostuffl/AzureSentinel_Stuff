<#
	For this runbook to function properly you will have to setup a couple of things beforehand.
	1. You will need to create an Azure App Registration with the following Graph "Application" permissions:
		Group.Read.All
		Policy.Read.All (Might be able to get away with Policy.Read.ConditionalAccess)
		User.Read.All
	1.5 Make a note of the Application/Client ID of the application and your TenantID (Found on the overview page of the app registration)

	2. Next you need to create a certificate for the app registration and upload it to the app in the certificates section.
		(Make sure to take note of the Thumbprint for the certificate)

	3. Upload the private key to the automation account where you will run this runbook
		(Make note of the name you gave the private key as you will need this for the runbook)

	4. Deploy the Logic App that pairs with this runbook (named "ConditionalAccessExclusionsWatchlist" on my github), save it, then copy the webhook url in the first block of the logic app
		(Webhook url is used in this runbook to post the conditionalaccess data to the logic app) 

	5. For the Logic App either give the managed Identity for it "Sentinel Contributor" permissions or authenticate the Sentinel blocks
		with a user account that has the correct permissions.

#>

# Modules to Import
Import-Module ("Microsoft.Graph.Identity.SignIns","Microsoft.Graph.Users","Microsoft.Graph.Groups")

#Variables
# Automation cert seems unnecessary, up to you.
$Cert = Get-AutomationCertificate -Name "your cert that is uploaded to azure automation"
$TenantId = "YOUR TENANT ID"
$AppId = "YOUR APPLICATION ID"
$CertificateThumbPrint = "YOUR CERTIFICATE THUMBPRINT"
$WebhookURL = "YOUR LOGIC APP WEBHOOK URL"


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
            ExcludedUsers = "NA"
        }

        $PolicyArray.Add($PolicyObject) | out-null
    }


# For each Conditional Access Policy, for each user excluded, create custom object and add to our array
# Also if the 'Guest or External User' exclusion policy is set, assign that to the ExcludedUsers field
    foreach($UserExclusion in $Policy.Conditions.Users.ExcludeUsers){
        if($UserExclusion -eq "GuestsOrExternalUsers"){
            
            $GetUser = "GuestsOrExternalUsers"

            $PolicyObject = [PSCustomObject]@{
            PolicyName = $Policy.DisplayName
            PolicyId = $Policy.Id
            ExcludedGroups = "NA"
            ExcludedUsers = $GetUser

            }
        }
        else{

            $GetUser = Get-mguser -userid $UserExclusion

            $PolicyObject = [PSCustomObject]@{
            PolicyName = $Policy.DisplayName
            PolicyId = $Policy.Id
            ExcludedGroups = "NA"
            ExcludedUsers = $GetUser.UserPrincipalName
            }
        }
        $PolicyArray.Add($PolicyObject) | out-null        
    
    }

}

# Convert CSV to JSON
$Json = $PolicyArray | ConvertTo-Json

# POST request to azure logic app to create watchlist
Invoke-WebRequest -Uri $WebhookURL -Method Post -Body $Json -ContentType "application/json" -UseBasicParsing


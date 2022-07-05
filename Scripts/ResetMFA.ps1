<#
  Meant to be run as an Azure Automation Runbook and called from the accompanying logic app
#>

param (
[Parameter(Mandatory)]
[string]$UserAccounts
)

$GACred = Get-AutomationPSCredential -Name "EnterYourAutomationUserAccountName" #Automation Account needs to be GA

Import-Module MSOnline
Connect-MsolService -Credential $GACred


 ForEach($User in $UserAccounts) {
	 try {

		write-output "Resetting $User's MFA..."
		Reset-MsolStrongAuthenticationMethodByUpn -UserPrincipalName $User -verbose
	 
	 }

	catch {
		Write-Output "Error resetting $User's MFA...`n"
		throw $_
    	break
	}
	
	Write-Output "Successfully reset $User's MFA...`n"
 }

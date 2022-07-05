<#
  This is meant to run as an Azure Automation Runbook on a Hybrid Runbook worker, and it is paired with the Reset-Revoke-User Logic App.

#>

Param (

[string] $UserAccounts

)

$myCredential = Get-AutomationPSCredential -Name 'Your Hybrid Worker Credential Name'

Import-Module ActiveDirectory 

foreach($User in $UserAccounts){
try {

	#Get SAM account name
	$SAMAccountName = Get-ADUser -Credential $myCredential -Filter {UserPrincipalName -eq $User}

	Write-Output "Finding and disabling user $SAMAccountName"

	#Create Random Password
	Write-Output "Creating random password..."
	$Password = -join ((33..126) | Get-Random -Count 15 | ForEach-Object { [char]$_ })
	

    #Convert the password to secure string.
	Write-Output "Converting to secure string"
    $NewPwd = ConvertTo-SecureString $Password -AsPlainText -Force
    
	#Assign the new password to the user.
	Write-Output "Resetting password.."
    Set-ADAccountPassword -identity $SAMAccountName -NewPassword $NewPwd -Reset 

    #Disable the user
	Write-Output "Disabling User"
	$SAMAccountName	| Disable-ADAccount 

	Write-Output "Successfully disabled user account $SAMAccountName"
}
catch {
    Write-Error "Error disabling user account $SAMAccountName"
	write-error "$_"
    throw $_
    break
}

}

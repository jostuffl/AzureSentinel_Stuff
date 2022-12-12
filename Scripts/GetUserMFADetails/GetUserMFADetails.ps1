<#
Original Author of most of this script is found in the comments below. Link to original script is included as well.
=============================================================================================
Name:           Export Office 365 users' MFA status using Microsoft Graph PowerShell
Description:    This script exports O365 users MFA status report to CSV file
Version:        1.0
Website:        o365reports.com
Script by:      O365Reports Team
For detailed script execution: https://o365reports.com/2022/04/27/get-mfa-status-of-office-365-users-using-microsoft-graph-powershell
============================================================================================
#>
Param
(
    [Parameter(Mandatory = $false)]
    [switch]$CreateSession,
    [switch]$MFAEnabled,
    [switch]$MFADisabled,
    [switch]$LicensedUsersOnly,
    [switch]$SignInAllowedUsersOnly

)

install-module -name "Microsoft.Graph" -Confirm:$False -Force -Verbose
install-module -name "Microsoft.Graph.Authentication" -Confirm:$False -Force
Import-module -name "Microsoft.Graph.Users" -Global
Import-module -name "Microsoft.Graph.Authentication" -Global

 #Connecting to MgGraph beta
 Select-MgProfile -Name beta
 $WebhookURL = "Your Webhook from your logic app"
 $TenantId = "Your Tenant Id"
 $AppId = "Your App Id"
 $CertificateThumbPrint = "Your certificate thumbprint"

 write-output "This is before connecting"

 # This is using Option 2 as explained in the Readme.md
$password= "Your certificate password"
$passwordSecure = ConvertTo-SecureString -AsPlainText -Force $password

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("Your path to your certificate on the local machine", $passwordSecure)
Connect-Graph -Certificate $cert -TenantId $TenantId -ClientId $AppId

 write-output "This is after connecting"


$ProcessedUserCount=0
$ExportCount=0
 #Set output file 
 $ExportCSV=".\MfaStatusReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"
  $Result=""  
 [System.Collections.ArrayList]$Results=@()

Get-MgUser -All -Filter "UserType eq 'Member'" -top 10 | foreach {

 $ProcessedUserCount++
# $CreationDate = $_.CreatedDateTime
 $Name= $_.DisplayName
 $UPN=$_.UserPrincipalName
 $Department=$_.Department
 if($_.AccountEnabled -eq $true)
 {
  $SigninStatus="Allowed"
 }
 else
 {
  $SigninStatus="Blocked"
 }
 if(($_.AssignedLicenses).Count -ne 0)
 {
  $LicenseStatus="Licensed"
 }
 else
 {
  $LicenseStatus="Unlicensed"
 }   
 $Is3rdPartyAuthenticatorUsed="False"
 $MFAPhone="-"
 $MicrosoftAuthenticatorDevice="-"
 Write-Progress -Activity "`n     Processed users count: $ProcessedUserCount "`n"  Currently processing user: $Name"
 [array]$MFAData=Get-MgUserAuthenticationMethod -UserId $UPN
 $AuthenticationMethod=@()
 $AdditionalDetails=@()
 
 foreach($MFA in $MFAData)
 { 
   Switch ($MFA.AdditionalProperties["@odata.type"]) 
   { 
    "#microsoft.graph.passwordAuthenticationMethod"
    {
     $AuthMethod     = 'PasswordAuthentication'
     $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
    } 
    "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod"  
    { # Microsoft Authenticator App
     $AuthMethod     = 'AuthenticatorApp'
     $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
     $MicrosoftAuthenticatorDevice=$MFA.AdditionalProperties["displayName"]
    }
    "#microsoft.graph.phoneAuthenticationMethod"                  
    { # Phone authentication
     $AuthMethod     = 'PhoneAuthentication'
     $AuthMethodDetails = $MFA.AdditionalProperties["phoneType", "phoneNumber"] -join '-' 
     $MFAPhone=$MFA.AdditionalProperties["phoneNumber"]
    } 
    "#microsoft.graph.fido2AuthenticationMethod"                   
    { # FIDO2 key
     $AuthMethod     = 'Fido2'
     $AuthMethodDetails = $MFA.AdditionalProperties["model"] 
    }  
    "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" 
    { # Windows Hello
     $AuthMethod     = 'WindowsHelloForBusiness'
     $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
    }                        
    "#microsoft.graph.emailAuthenticationMethod"        
    { # Email Authentication
     $AuthMethod     = 'EmailAuthentication'
     $AuthMethodDetails = $MFA.AdditionalProperties["emailAddress"] 
    }               
    "microsoft.graph.temporaryAccessPassAuthenticationMethod"   
    { # Temporary Access pass
     $AuthMethod     = 'TemporaryAccessPass'
     $AuthMethodDetails = 'Access pass lifetime (minutes): ' + $MFA.AdditionalProperties["lifetimeInMinutes"] 
    }
    "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod" 
    { # Passwordless
     $AuthMethod     = 'PasswordlessMSAuthenticator'
     $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
    }      
    "#microsoft.graph.softwareOathAuthenticationMethod"
    { 
      $AuthMethod     = 'SoftwareOath'
      $Is3rdPartyAuthenticatorUsed="True"            
    }
    
   }
   $AuthenticationMethod +=$AuthMethod
   if($AuthMethodDetails -ne $null)
   {
    $AdditionalDetails +="$AuthMethod : $AuthMethodDetails"
   }
  }
  #To remove duplicate authentication methods
  $AuthenticationMethod =$AuthenticationMethod | Sort-Object | Get-Unique
  $AuthenticationMethods= $AuthenticationMethod  -join "-"
  $AdditionalDetail=$AdditionalDetails -join "-"
  $Print=1
  #Determine MFA status
  [array]$StrongMFAMethods=("Fido2","PhoneAuthentication","PasswordlessMSAuthenticator","AuthenticatorApp","WindowsHelloForBusiness")
  $MFAStatus="Disabled"
 

  foreach($StrongMFAMethod in $StrongMFAMethods)
  {
   if($AuthenticationMethod -contains $StrongMFAMethod)
   {
    $MFAStatus="Strong"
    break
   }
  }

  if(($MFAStatus -ne "Strong") -and ($AuthenticationMethod -contains "SoftwareOath"))
  {
   $MFAStatus="Weak"
  }
 
  $ExportCount++
  $Result= [PSCustomObject]@{'Name'=$Name;'UPN'=$UPN;'Department'=$Department;'License Status'=$LicenseStatus;'SignIn Status'=$SigninStatus;'Authentication Methods'=$AuthenticationMethods;'MFA Status'=$MFAStatus;'MFA Phone'=$MFAPhone;'Microsoft Authenticator Configured Device'=$MicrosoftAuthenticatorDevice;'Is 3rd-Party Authenticator Used'=$Is3rdPartyAuthenticatorUsed;'Additional Details'=$AdditionalDetail} 
  $Results.Add($Result) | out-null
  #$Results= New-Object PSObject -Property $Result 
  write-output $Result.Name
 }

   $Results | Select-Object 'Name','UPN','Department','License Status','SignIn Status','Authentication Methods','MFA Status','MFA Phone','Microsoft Authenticator Configured Device','Is 3rd-Party Authenticator Used','Additional Details' | Export-Csv -Path $ExportCSV -Notype -Append
  

# Convert CSV to JSON
 $Json = $Results  | ConvertTo-Json

# POST request to azure logic app to create watchlist
Invoke-WebRequest -Uri $WebhookURL -Method Post -Body $Json -ContentType "application/json" -UseBasicParsing

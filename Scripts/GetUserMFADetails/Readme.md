# Get User MFA Details - Powershell Script
----

This powershell script is meant to be paired with the **GetUserMFADetails-LogicApp** which can be found in: **/LogicApps/GetMFADetails/** section of this repository.

This is meant to run as an Azure Runbook, but could be run on-prem as long as you have the certificate used for authentication installed on the machine.

An Azure App registration is required for this powershell script to run. Once you create your app registration you will need to upload a certificate to it and grant **User.Read.All** and **UserAuthenticationMethod.Read.All** Graph API permissions. You will then need to upload the certificate to your Azure Automation account in the **Certificates** tab.

Make sure to install the **Microsoft.Graph.Users** and **Microsoft.Graph.Authentication** module in your Azure Automation Account. (I have included the module installation in the script in case you run it in a hybrid runbook worker.)

----

**NOTE:** I did not create this powershell script. I did modify some of it to fit the use case that I had, and I adjusted it to work in a runbook with an app registration using certificate based authentication, but the bulk of the script was pulled from: [Original Author's Blog Post / Script](https://o365reports.com/2022/04/27/get-mfa-status-of-office-365-users-using-microsoft-graph-powershell)

I did not remove the original parameters in case they were needed in future, and I also did not remove the part that generates a csv of the data. Leaving those pieces in does not hinder the script or accompanying logic app, but if desired they can be removed.

----
### Hybrid Worker Certificate Workaround
So there is an issue with hybrid runbook workers detecting the certificate being installed locally. Make sure your certificate is either installed to the local machine certificate store, or you have it saved on the machine somewhere. Then use one of the options below (replace the line in the script that starts with **connect-mggraph**):

```powershell
# Option 1
$cert = Get-ChildItem Cert:\LocalMachine\My\$CertificateThumbPrint
Connect-Graph -Certificate $cert -TenantId $TenantId -ClientId $AppId

# Option 2
# Replace SomePassword with the password you used when you exported the certificate
# Replace C:\Certificates\mycert.pfx with the full path to your certificate
$password= "SomePassword"
$passwordSecure = ConvertTo-SecureString -AsPlainText -Force $password
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("C:\Certificates\mycert.pfx", $passwordSecure)
Connect-Graph -Certificate $cert -TenantId $TenantId -ClientId $AppId
```

  # Entra Audit + SigninLogs to Sentinel / Log Analytics Custom Logs (_CL)

  Pre-requisites:
  * An Azure Subscription
  * Existing Resource Group
  * Existing Log Analytics Workspace
  * Permissions on the resource group your workspace is in

    
  The arm template linked via the 'Deploy To Azure' button below deploys the following:
   * 1 New Data Collection Endpoint
   * 1 New Data Collection Rule
   * 2 New Custom Logs
     * EntraAuditLogs_CL
     * EntraSigninLogs_CL

**NOTE For Sentinel Deployments:**
  > This solution is not eligible for the sentinel A5/E5/G5/F5 5mb/day data grant since they are _CL tables. Additionally, native Sentinel UEBA Entra functionality does not apply to the tables either for the same reason.
> This solution is for specific instances where Entra logs are routed through Event Hubs via diagnostic settings -> Cribl -> Sentinel/Log Analytics.
> I have not tested other pipelines. 

Planned Additions to this folder / solution:
* PowerShell script that updates existing Entra Sentinel content to use the custom logs, such as the content hub detections/workbooks/etc
* Asim integration
* Additional Entra log sources (NonInteractiveUserSigninLogs, etc)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Frefs%2Fheads%2Fmain%2FData%2520Connectors%2FEntra%2FEntra-Audit_Signin.json)

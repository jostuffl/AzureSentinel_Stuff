<# 
This powershell script is meant to be run as a runbook in Azure Automation.
You must enabled the managed identity on the automation account and assign permissions.
It requires these permissions be assigned to the Automation Account Managed Identity 
(Although the read permissions might be redundant.Even with the permissions below I 
was running into issues detecting the Azure Arc Machines in the resource groups.
I added straight Read permissions to the subscription, which fixed it.
I don't necessarily recommend giving the managed identity Read permissions
to all of your subscriptions. I'm sure the permissions can be narrowed down further to be more
Zero Trust aligned.)

Microsoft.HybridCompute/machines/extensions/read
Microsoft.HybridCompute/machine/extensions/delete
Microsoft.Resources/subscriptions/resourceGroups/read
Microsoft.Resources/resources/read
Microsoft.Resources/subscriptions/resourcegroup/resources/read
Microsoft.Resources/subscriptions/resources/read
Read (On the subscriptions where the machines are located)


#>


Import-Module -Name "Az.ConnectedMachine"

Connect-AzAccount -Identity

# Get all Azure subscriptions for the logged-in user
$subscriptions = Get-AzSubscription

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Select the current subscription
    Write-Output "In Subscription $Subscription"
    Select-AzSubscription -SubscriptionId $subscription.Id

    # Get all resource groups in the current subscription
    $resourceGroups = Get-AzResourceGroup

    # Loop through each resource group
    foreach ($resourceGroup in $resourceGroups) {
        # Get all Azure Arc machines in the resource group
        Write-Output "In resource group $($resourceGroup.ResourceGroupName)"
        $arcMachines = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName -ResourceType "Microsoft.HybridCompute/machines" -ExpandProperties 
    
        # Loop through each Azure Arc machine
        foreach ($arcMachine in $arcMachines) {
            # Remove the MMA extension from the Azure Arc machine
            Write-Output "Acting on arc machine $($arcMachine.Name)"
    
            $Extension = Get-AzConnectedMachineExtension -ResourceGroupName $resourceGroup.ResourceGroupName -MachineName $arcMachine.Name 
            $Extension | Where-Object {($_.Name -eq "MicrosoftMonitoringAgent") -or ($_.Name -eq "MSMonitoringAgent") -or ($_.Name -eq "OmsAgentForLinux")} | Remove-AzConnectedMachineExtension
            Write-Output "Removed MMA from $($arcMachine.Name)" 
        }
    }
}

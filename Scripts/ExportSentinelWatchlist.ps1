# Original Script found at: https://github.com/ge-wijayanto/AZ-Sentinel-WatchlistExporter
# Tested with an account that had at least Sentinel Contributor on the resource group where Sentinel Lives. 
# This script retrieves all items for a given watchlist, converts it to csv, and finally outputs it to a file.
# This can be modified to run in an azure Automation Runbook and send the data as a json payload to a logic app that can then send it as a csv attachment in an email.
# I am not the original author of this script. See first line for author.

$SubscriptionId = "YOUR SUBSCRIPTION" # SubscriptionId, found in the Azure Portal (https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id)
$ResourceGroupName = "YOUR SENTINEL RESOURCE GROUP" # Resource Group Name with the Workspace containing the Watchlist 
$WorkspaceName = "YOUR SENTINEL WORKSPACE NAME" # Workspace Name from which the watchlist is going to be extracted 
$WatchlistName = "YOUR SENTINEL WATCHLIST NAME" # Name of the watchlist to be exported
$ApiVersion = "2022-12-01-preview" # Leave as is
$OutputFilePath = "YOUR OUTPUT FILE NAME" # Name of the JSON export files

Connect-AzAccount

# Get Azure access token
$accessToken = (Get-AzAccessToken -ResourceUrl https://management.azure.com).Token

$uriBase = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/providers/Microsoft.SecurityInsights/watchlists/$WatchlistName/watchlistItems"
$Array = @()

do {
    $uriBuilder = [System.UriBuilder]::new($uriBase)
    $uriBuilder.Query = "api-version=$ApiVersion"

    try {
        # Invoke the Azure REST method and include the Authorization header
        $response = Invoke-RestMethod -Method Get -Uri $uriBuilder.Uri -Headers @{ Authorization = "Bearer $accessToken" } -ErrorAction Stop

        # Check if the 'value' property is present in the response
        if ($response.value) {
            foreach ($item in $response.value) {
                # Access the 'properties' property and append to the output file
                $properties = $item.properties.itemsKeyValue

                #For each watchlist item add it to the array
                foreach($Property in $properties){
                    $Array += $Property
                }

            }

            # Check if there is a 'nextLink' property indicating more data
            $nextLink = $response.nextLink
            if ($nextLink) {
                $uriBase = $nextLink
            }
        } else {
            # If 'value' is not present, exit the loop
            $nextLink = $null
        }
    } catch {
        Write-Host "Error invoking Azure REST method: $_"
        $nextLink = $null
    }
} while ($nextLink)

#Uncomment below if you want to save the watchlist as a local file
$Array | ConvertTo-Csv | Out-File $OutputFilePath

Write-Host "Data retrieval complete. Results have been appended to $OutputFilePath"

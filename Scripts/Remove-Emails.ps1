<#
.SYNOPSIS
    Deletes phishing emails from user mailboxes based on InternetMessageId.

.DESCRIPTION
    This script queries Microsoft Sentinel (Log Analytics) to find all recipients of a 
    phishing email by InternetMessageId, then uses Microsoft Graph API to locate and 
    delete the email from each user's mailbox. Includes retry logic with exponential 
    backoff for API throttling and batch processing to handle large recipient lists.

    I originally have this paired with a Logic App that triggers on a Sentinel incident
    that is generated when X number of users report the same email as phishing. However,
    the logic app is not required for this script to function. As long as you pass in
    an InternetMessageId of a valid email that exists in user mailboxes, it will attempt
    to delete it from all found recipients.

    WARNING: THIS SCRIPT WILL DELETE / REMOVE EMAILS FROM USER MAILBOXES. USE AT YOUR OWN
    RISK! TEST THOROUGHLY IN A NON-PRODUCTION ENVIRONMENT FIRST! That being said, the
    emails are not permanently deleted as the script uses Remove-MgUserMessage which
    moves the email to the Deleted Items folder. You can recover from there if needed.

.PARAMETER InternetMessageId
    The InternetMessageId of the phishing email to delete. This is a unique identifier 
    for the email message.

.PARAMETER BatchSize
    The number of recipients to process before pausing. Default is 50.

.PARAMETER BatchDelaySeconds
    The number of seconds to pause between batches to avoid API throttling. Default is 2.

.PARAMETER ResourceGroupName
    The name of the Azure Resource Group containing the Log Analytics workspace.

.PARAMETER WorkspaceName
    The name of the Log Analytics (Sentinel) workspace to query for email recipients.

.PARAMETER WhatIf
    When set to $true (default), shows what would happen without actually deleting emails.
    Set to $false to perform actual email deletions.

.EXAMPLE
    .\DeletePhishing.ps1 -InternetMessageId "<abc123@contoso.com>" -ResourceGroupName "sentinel-rg" -WorkspaceName "sentinel"
    
    Runs in WhatIf mode (default). Shows what emails would be deleted without actually 
    removing them. Use this to verify the script targets the correct emails.

.EXAMPLE
    .\DeletePhishing.ps1 -InternetMessageId "<abc123@contoso.com>" -ResourceGroupName "sentinel-rg" -WorkspaceName "sentinel" -WhatIf $false
    
    Actually deletes the phishing email from all recipient mailboxes. The -WhatIf $false 
    parameter is required to perform real deletions.

.EXAMPLE
    .\DeletePhishing.ps1 -InternetMessageId "<abc123@contoso.com>" -ResourceGroupName "sentinel-rg" -WorkspaceName "sentinel" -BatchSize 100 -BatchDelaySeconds 5
    
    Runs in WhatIf mode with custom batch settings. Processes recipients in batches of 100 
    with a 5-second delay between batches to avoid API throttling.

.EXAMPLE
    .\DeletePhishing.ps1 -InternetMessageId "<abc123@contoso.com>" -ResourceGroupName "sentinel-rg" -WorkspaceName "sentinel" -WhatIf $false -BatchSize 25 -BatchDelaySeconds 3
    
    Deletes emails with conservative batch settings for environments with strict rate limits.

.NOTES
    Author:         Jonathon Stufflebeam
    Date:           January 28, 2026
    Version:        1.0
    
    Prerequisites:
    - Az.OperationalInsights module
    - Microsoft.Graph.Authentication module
    - Microsoft.Graph.Mail module
    - Managed Identity or appropriate authentication configured. Using a user account will only allow email deletion from that user's mailbox.
    - Appropriate permissions for Microsoft Graph (Mail.ReadWrite) and Azure Log Analytics assigned to the managed identity

    IMPORTANT: WhatIf defaults to $true for safety. Set -WhatIf $false to enable actual 
    email deletion.

.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.mail/remove-mgusermessage
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$InternetMessageId,
    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 50,
    [Parameter(Mandatory = $false)]
    [int]$BatchDelaySeconds = 2,
    [Parameter(Mandatory = $false)]
    [bool]$WhatIf = $true,
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceName,
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName
) 
# Ensure required modules are available
$modules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Mail", "Az.OperationalInsights")
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module -Name $module -Force
}

# Retry function with exponential backoff for Graph API throttling (429 errors)
function Invoke-WithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 5,
        [Parameter(Mandatory = $false)]
        [int]$InitialDelaySeconds = 5
    )
    
    $retryCount = 0
    $delay = $InitialDelaySeconds
    
    while ($retryCount -lt $MaxRetries) {
        try {
            return & $ScriptBlock
        }
        catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            
            if ($statusCode -eq 429) {
                $retryAfter = $null
                if ($_.Exception.Response.Headers) {
                    $retryAfter = $_.Exception.Response.Headers["Retry-After"]
                }
                if ($retryAfter) {
                    $delay = [int]$retryAfter
                }
                write-output "Rate limited (429). Waiting $delay seconds before retry ($($retryCount + 1)/$MaxRetries)..."
                Start-Sleep -Seconds $delay
                $retryCount++
                $delay = [math]::Min($delay * 2, 120)  # Exponential backoff, max 2 minutes
            }
            elseif ($statusCode -ge 500 -and $statusCode -lt 600) {
                # Server errors - retry with backoff
                write-output "Server error ($statusCode). Waiting $delay seconds before retry ($($retryCount + 1)/$MaxRetries)..."
                Start-Sleep -Seconds $delay
                $retryCount++
                $delay = [math]::Min($delay * 2, 120)
            }
            else {
                # Non-retryable error - throw immediately
                throw $_
            }
        }
    }
    throw "Max retries ($MaxRetries) exceeded. Last error: $_"
}

if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
    write-output "Connecting to Microsoft Graph..." 
    try {
        Connect-MgGraph -Identity
        write-output "Connected successfully to Microsoft Graph." 

        Connect-AzAccount -Identity
        write-output "Connected Successfully to Azure."
    }
    catch {
        write-output "Failed to connect to Microsoft Graph. Error: $_"
        exit
    }
}

$RecipientsArray = @()

# Consolidated tracking objects
$EmailRetrieval = [PSCustomObject]@{
    SuccessCount      = 0
    FailedCount       = 0
    NotFoundCount     = 0
    SuccessUsers      = @()
    FailedUsers       = @()
    NotFoundUsers     = @()
}

$EmailDeletion = [PSCustomObject]@{
    SuccessCount  = 0
    FailedCount   = 0
    SkippedCount  = 0
    SuccessUsers  = @()
    FailedUsers   = @()
    SkippedUsers  = @()
}

$Workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName        

write-output "Retrieving all recent recipients for InternetMessageId: $InternetMessageId"

try {
    # KQL query with retry for Log Analytics API throttling
    $kqlQuery = @"
EmailEvents 
| where TimeGenerated > ago(30d) 
| where InternetMessageId contains "$InternetMessageId" 
| distinct RecipientEmailAddress, InternetMessageId
"@

    $GetRecipientsQueryResults = Invoke-WithRetry -ScriptBlock {
        (Invoke-AzOperationalInsightsQuery -Workspace $Workspace -Query $kqlQuery).Results
    } -MaxRetries 3 -InitialDelaySeconds 10

    foreach ($Row in $GetRecipientsQueryResults) {
        write-output "Found Recipient: $($Row.RecipientEmailAddress)"
        $RecipientObject = [PSCustomObject]@{
            EmailAddress      = $Row.RecipientEmailAddress
            InternetMessageId = $Row.InternetMessageId
        }
        $RecipientsArray += $RecipientObject
    }
}
catch {
    write-output "Error gathering recipients from KQL query against workspace $WorkspaceName"
    write-output "Error $_"
    exit
}

write-output "Total Recipients found: $($RecipientsArray.Count)"

# Check if we have recipients to process
if ($RecipientsArray.Count -eq 0) {
    write-output "No recipients found. Exiting."
    exit
}

# Estimate time for large batches
if ($RecipientsArray.Count -gt 100) {
    $estimatedMinutes = [math]::Ceiling(($RecipientsArray.Count / $BatchSize) * ($BatchDelaySeconds / 60) + ($RecipientsArray.Count * 0.05))
    write-output "Processing $($RecipientsArray.Count) recipients. Estimated time: ~$estimatedMinutes minutes"
}

# Initialize timing before try block so it's available in summary
$startTime = Get-Date
$batchCount = 0

try {
    # Delete the message with batch throttling
    
    foreach ($Recipient in $RecipientsArray) {
        $batchCount++
        
        # Batch delay to avoid throttling
        if ($batchCount % $BatchSize -eq 0) {
            $elapsed = (Get-Date) - $startTime
            $rate = $batchCount / $elapsed.TotalMinutes
            write-output "Processed $batchCount/$($RecipientsArray.Count) recipients (~$([math]::Round($rate, 1))/min). Pausing $BatchDelaySeconds seconds..."
            Start-Sleep -Seconds $BatchDelaySeconds
        }
        
        write-output "Retrieving email id from recipient $($Recipient.EmailAddress) mailbox for InternetMessageId $($Recipient.InternetMessageId).."
        $filterQuery = "internetMessageId eq '$($Recipient.InternetMessageId)'"
        $currentRecipient = $Recipient  # Capture for scriptblock scope

        try {
            $UserEmail = Invoke-WithRetry -ScriptBlock {
                Get-MgUserMessage -UserId $currentRecipient.EmailAddress -Filter $filterQuery -ErrorAction Stop
            }

            if ($UserEmail) {
                write-output "Successfully retrieved email from user's mailbox!"
                $EmailRetrieval.SuccessCount++
                $EmailRetrieval.SuccessUsers += $Recipient.EmailAddress

                write-output "Attempting to remove email from user's mailbox..."
                try {
                    $currentMessageId = $UserEmail.Id  # Capture for scriptblock scope
                    $isWhatIf = $WhatIf  # Capture for scriptblock scope
                    Invoke-WithRetry -ScriptBlock {
                        if ($isWhatIf) {
                            Remove-MgUserMessage -UserId $currentRecipient.EmailAddress -MessageId $currentMessageId -WhatIf -ErrorAction Stop
                        } else {
                            Remove-MgUserMessage -UserId $currentRecipient.EmailAddress -MessageId $currentMessageId -ErrorAction Stop
                        }
                    }
                    if ($WhatIf) {
                        write-output "[WHATIF] Would delete email from user's mailbox (no action taken)"
                    } else {
                        write-output "SUCCESSFULLY deleted email from user's mailbox!"
                    }
                    $EmailDeletion.SuccessCount++
                    $EmailDeletion.SuccessUsers += $Recipient.EmailAddress
                }
                catch {
                    write-output "FAILED to delete email for user: $($Recipient.EmailAddress). Error: $_"
                    $EmailDeletion.FailedCount++
                    $EmailDeletion.FailedUsers += $Recipient.EmailAddress
                }
            }
            else {
                write-output "NO EMAIL FOUND for user $($Recipient.EmailAddress) for InternetMessageId $($Recipient.InternetMessageId)!"
                $EmailRetrieval.NotFoundCount++
                $EmailRetrieval.NotFoundUsers += $Recipient.EmailAddress
                $EmailDeletion.SkippedCount++
                $EmailDeletion.SkippedUsers += $Recipient.EmailAddress
            }
        }
        catch {
            write-output "FAILED to retrieve email for user: $($Recipient.EmailAddress). Error: $_"
            $EmailRetrieval.FailedCount++
            $EmailRetrieval.FailedUsers += $Recipient.EmailAddress
        }
    }
}
catch {
    write-output "Error during processing loop."
    write-output "$_"
    write-error "$_"
}

# Calculate elapsed time
$totalElapsed = (Get-Date) - $startTime

# Output summary
write-output "`n========== SUMMARY =========="
write-output "Total Processing Time: $([math]::Round($totalElapsed.TotalMinutes, 2)) minutes"
write-output "`nEmail Retrieval Results:"
write-output "  Success: $($EmailRetrieval.SuccessCount) | Failed: $($EmailRetrieval.FailedCount) | Not Found in Mailbox: $($EmailRetrieval.NotFoundCount)"

if ($EmailRetrieval.SuccessUsers.Count -gt 0) {
    write-output "`n  Successfully Retrieved Users:"
    foreach ($user in $EmailRetrieval.SuccessUsers) {
        write-output "    - $user"
    }
}

if ($EmailRetrieval.FailedUsers.Count -gt 0) {
    write-output "`n  Failed Retrieval Users:"
    foreach ($user in $EmailRetrieval.FailedUsers) {
        write-output "    - $user"
    }
}

if ($EmailRetrieval.NotFoundUsers.Count -gt 0) {
    write-output "`n  Not Found in Mailbox Users:"
    foreach ($user in $EmailRetrieval.NotFoundUsers) {
        write-output "    - $user"
    }
}

write-output "`nEmail Deletion Results:"
write-output "  Success: $($EmailDeletion.SuccessCount) | Failed: $($EmailDeletion.FailedCount) | Skipped: $($EmailDeletion.SkippedCount)"

if ($EmailDeletion.SuccessUsers.Count -gt 0) {
    write-output "`n  Successfully Deleted Users:"
    foreach ($user in $EmailDeletion.SuccessUsers) {
        write-output "    - $user"
    }
}

if ($EmailDeletion.FailedUsers.Count -gt 0) {
    write-output "`n  Failed Deletion Users:"
    foreach ($user in $EmailDeletion.FailedUsers) {
        write-output "    - $user"
    }
}

if ($EmailDeletion.SkippedUsers.Count -gt 0) {
    write-output "`n  Skipped Deletion Users:"
    foreach ($user in $EmailDeletion.SkippedUsers) {
        write-output "    - $user"
    }
}

write-output "`n=============================="

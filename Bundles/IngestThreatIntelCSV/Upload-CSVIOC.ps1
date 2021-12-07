#Do note that this was originally meant to be run manually for 1 csv at a time
#However you could modify it to loop through a folder, but I leave that to you.
#Anything marked as "Optional" means insert your own value if desired. Otherwise "Optional" will show in that field instead.

$mypath = 'InsertPathToCSV'

#The -replace '[][]',"" may not be needed, the original csv I was working with had those surrounding ips.
$MyTI = (Get-Content $mypath) -replace '[][]', "" | convertfrom-csv -Delimiter ',' 

#Used for expiration time of TI in Sentinel
$mykeeptime = (Get-Date -asutc).adddays(365).tostring("o")

#Loop through each indicator
foreach($i in $MyTI){


    #Set the comment and indicator value variables based on the current record values in the "COMMENT" and "INDICATOR_VALUE" columns.
    $Comment = (($i).COMMENT)
    $Indicator = (($i).INDICATOR_VALUE)
    
    # Check to see if the 'Type' column contains 'FQDN'. If it does, create a $TIRecord json object of it.
    # You will need to adjust the "FQDN" to fit the value you want to filter on (based on the column) for each of the "if statements", which there are 3.
    if ($i.Type -eq "FQDN"){

    $TIRecord = @"
{
    "action": "alert",
    "additionalInformation": "$Comment",
    "confidence": 100,
    "description": "Domain",
    "expirationDateTime": "$mykeeptime",
    "indicatorProvider": "Optional",
    "indicator": "$Indicator",
    "severity": 0,
    "threatType": "WatchList",
    "tlpLevel": "Optional"
}
"@
Invoke-RestMethod -Uri "INSERT_WEBHOOK_LINK_FROM_LOGIC_APP" -ContentType "application/json" -Body $TIRecord -Method Post
    }

    if($i.Type -eq "MD5"){
        
        $TIRecord = @"
{
    "action": "alert",
    "additionalInformation": "$Comment",
    "confidence": 100,
    "description": "MD5",
    "expirationDateTime": "$mykeeptime",
    "indicatorProvider": "Optional",
    "indicator": "$Indicator",
    "severity": 0,
    "threatType": "WatchList",
    "tlpLevel": "Optional"
}
"@
Invoke-RestMethod -Uri "INSERT_WEBHOOK_LINK_FROM_LOGIC_APP" -ContentType "application/json" -Body $TIRecord -Method Post
    }

    if($i.Type -eq "IPV4ADDR"){
        $TIRecord = @"
{
    "action": "alert",
    "additionalInformation": "$Comment",
    "confidence": 100,
    "description": "IPv4",
    "expirationDateTime": "$mykeeptime",
    "indicatorProvider": "Optional",
    "indicator": "$Indicator",
    "severity": 0,
    "threatType": "WatchList",
    "tlpLevel": "Optional"
}
"@
    }
    Invoke-RestMethod -Uri "INSERT_WEBHOOK_LINK_FROM_LOGIC_APP" -ContentType "application/json" -Body $TIRecord -Method Post
}

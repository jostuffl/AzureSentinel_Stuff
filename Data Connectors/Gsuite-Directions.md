# Azure Sentinel Gsuit Dataconnector Directions
	• Make Oauth Credentials and give redirect url 
        • Go to: https://console.cloud.google.com/apis/credentials?
        • Create Oauth credentials
		    • For redirect url enter: http://localhost:8081/
		
    • Download Credentials
        • Rename credentials.json

    • Create local quickstart.py
        • Use this quickconfig: 
        https://developers.google.com/gmail/postmaster/quickstart/python?hl=en

        • Change port to 8081 in quickconfig
        • line 30: creds = flow.run_local_server(port=8081)

    • Install google apis for python
        •   pip install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib

    • Run quick start
    • Login and authenticate
    • Download and Run Picklestring Script
        • https://aka.ms/sentinel-GWorkspaceReportsAPI-functioncode
        • Copy Picklestring
        • NOTE! Remove b' and trailing ' from pickle string!
	    • Pickle String Example: b'************************'
	
	• Deploy function
	• save Kusto function
		https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Parsers/GWorkspaceReports/GWorkspaceActivityReports

	• Fix WorkspaceID, WorkspaceKey, GooglePickleString
        • Manually Enter the values in the Azure function under configuration
	• Remove LogAnalyticsUri value
	

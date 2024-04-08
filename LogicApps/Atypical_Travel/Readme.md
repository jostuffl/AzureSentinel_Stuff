# Atypical Travel Automation

This is an automation to help with the scenario where users are triggering multiple Atypical Travel Sentinel incidents.
It checks to see if they have triggered the incident 5 or more times, and depending on that either proceeds with the automation,
or stops and leaves the incident alone. You can change the threshold from 5 to what ever number you want.

The automation checks to see if the user has signed in from the ips in the incident in the last 30 days (excluding the last 24 hours),
based on that it either updates and closes the incident, or continues. If it continues it grabs the GeoIp data for each ip, sends it as a table
in a teams message to a channel, then sends a teams card to a channel with 3 options. 

- Email the user asking if the sign-in was them
  - If they say it was them it auto updates the incident and closes it
- Offers the option to close it as a false positive
- The last option provides the ability to force password change on next login, and revoke the user's sessions
  - This last part is not technically in this logic app. Instead it calls another logic app that is dedicated for this purpose.
  - That logic app is called "ATypical_Travel_FPR" and it can be found under the Logicapps section in this repository.
 

  You will need to authorize the api connections for the various services in the logic app. I recommend using a managed identity for any service that supports it.
  If a managed identity is not supported by a service / api connection, use a dedicated account specifically meant for authorizing api connections rather than your own
  user account.

  Deploy it to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Fmain%2FLogicApps%2FAtypical_Travel%2FAtypical_Travel.json)

#!/bin/bash

#Specific plists with required info if Jamf Connect Sync is not the application used are:
#com.jamf.connect.sync = Jamf connect Sync
#com.jamf.connect.verify = Jamf Connect Verify
#com.trusourcelabs.NoMAD = NoMAD/ NoMad Pro

#Get useful info about the machine and User
loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
Useremail=$(su - $loggedInUser -c "defaults read com.jamf.connect.sync UserLoginName")
UserLoginFName=$(su - $loggedInUser -c "defaults read com.jamf.connect.sync UserFirstName")
UserLoginLName=$(su - $loggedInUser -c "defaults read com.jamf.connect.sync UserLastName")
UserLoginFullName=$(echo "$UserLoginFName $UserLoginLName")
Hostname=$(hostname)
Serial=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep "Serial Number" | /usr/bin/awk -F ": " '{ print $2 }')
UUID=$(/usr/sbin/system_profiler SPHardwareDataType | awk '/UUID/ { print $3; }')

#Druva specific variables which can be obtained from the console and filled in here
DRV_CLIENT_ID=eCVGmexIUKaQcojFa6BmdvCoiFQKOjpg
DRV_CLIENT_SECRET=jJgtMkq2cNXWuFqv7EptDmR4E8CSiSEQ
DRV_Token=11266-aa6e8f0d1b72bd0c389e22c9efc56bf0be61c92a97a23f0ec726b77275c6842f

#Get the Oauth2 token
Oauth2=$(curl -u $DRV_CLIENT_ID:$DRV_CLIENT_SECRET -d 'grant_type=client_credentials&scope=read' https://apis.druva.com/token | cut -c 19-155)

#Arranging nicely for the curl command and Pushing info to Druva API to create device mapping
curl -v -H "Authorization: Bearer ${Oauth2}"  --header 'accept: application/json' --header 'content-type: application/json' --url https://apis.druva.com/insync/endpoints/v1/devicemappings --data "$(cat <<EOF
{
  "emailID":"${Useremail}",
  "userName":"${loggedInUser}",
  "deviceName":"${Hostname}",
  "deviceIdentifierType":"uuid",
  "deviceIdentifier":"${UUID}"
    }
EOF
)"


# Echo info for Jamf logs
Echo $loggedInUser
Echo $Useremail
Echo $UserLoginFName
Echo $UserLoginLName
Echo $UserLoginFullName
Echo $Hostname
Echo $Serial
Echo $UUID
Echo $Oauth2



#Activating using the V4 token
sleep 100


/Applications/Druva\ inSync/inSync.app/Contents/MacOS/inSync --tokenv4 "$DRV_Token" --master "cloud.druva.com:443"





exit 0

#!/usr/bin/env sh
#test server verification
# Example:
#REGISTER +41791111111:
curl -k -X POST --header "Content-Length: 0" https://gcm.textsecure.whispersystems.org/v1/accounts/sms/+41795994505
# AUTHORIZE:
curl -k -X PUT -i -H "Authorization: Basic KzQxNzk5NjI0NDk5OjI1OTNlNWZhZTdiNzUxODYxYzcxOTE4YjRhNGU5YTE5" -H "Content-Type:application/json" --data "{\"signalingKey\" : \"Ti71M5PR63/SOnrermsyZMlrl2WrwAMD/5cH5Z/bjKEG1e3jjKzUBf1zI0bPt4ai\"}"  https://gcm.textsecure.whispersystems.org/v1/accounts/code/111111
# with 111111 being the verification code the phone number recieved by SMS

#NOTE: k means ignoring the SSL warning, what we should be doing rather is using Moxie's cert
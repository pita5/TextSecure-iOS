#!/usr/bin/env sh
#test server verification
curl -X PUT -i -H "Content-Type:application/json" --data "{\"verificationCode\" : \"269536762\", \"authenticationToken\" :
\"1234\" , \"gcmRegistrationId\" : \"12345\"}" https://textsecure-gcm.appspot.com/v1/accounts/+41799624499
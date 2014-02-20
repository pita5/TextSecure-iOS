# protoc supported for iOS via cocoapods. 
added to Podfile
```pod 'GoogleProtobuf', 		'~> 2.5.0'```
ran
```pod install```

# protobuffer format from:
https://github.com/WhisperSystems/TextSecure/blob/push-library/library/protobuf/IncomingPushMessageSignal.proto

#protoc compiler generate from pod
run with 
```../../Pods/GoogleProtobuf/bin/protoc -I=`pwd` --cpp_out=`pwd` `pwd`/IncomingPushMessageSignal.proto ```

# Objective-C++ code wrapper code written
code that includes this header is itself objective C++ and must be named accordingly (.hh/.mm extension) to compile




####
# ProtocolBuffer PreKeyWhisperMessage
##
# "preKeyId". The ID of the client's prekey that was retrieved by the sender.
# "baseKey". The base Curve25519 key exchange ephemeral. This corresponds to A0 in the axolotl protocol description.
# "identityKey". The Curve25519 identity key of the sender. This corresponds to A in the axolotl protocol description.
# "message". This corresponds to a full serialized TextSecure_WhisperMessage that contains the actual encrypted message.
##
####

####
# "version". A one byte version identifier, with the high 4 bits representing the current version of the message and the low 4 bits representing the #maximum protocol version the client knows how to speak.
# "PreKeyWhisperMessage". A serialized PreKeyWhisperMessage protocol buffer (above).
# WHY doesn't this include hmac of the two? 
####
# struct {
#  opaque version[1];
#  opaque PreKeyWhisperMessage[...];
# } TextSecure_PreKeyWhisperMessage;


####
# Protocol Buffer WhisperMessage
##
# "ephemeralKey". This is an ephemeral Curve25519 key for the message's current DH ratchet. This corresponds to DHR in the axolotl protocol description.
# "counter". This is a monotonically incrementing counter for each message transmitted under the same "ephemeralKey". This corresponds to N in the axolotl protocol description.
# "previousCounter". This is the max value of the counter that was transmitted under the sender's last "ephemeralKey." This corresponds to PN in the axolotl protocol description.
# "ciphertext". This is the ciphertext body of the message, encrypted with a message key derived according to axolotl using a 256bit AES cipher in CTR mode with the high 4 bytes of the counter corresponding to the "counter" value transmitted with this message.  # use the key derived in axolotl
##
####

####
#"version". A one byte version identifier, with the high 4 bits representing the current version of the message and the low 4 bits representing the maximum protocol version the client knows how to speak.
#"WhisperMessage". A serialized WhisperMessage protocol buffer (above).
# "mac". An HMAC-SHA256 of both version and WhisperMessage concatenated, then truncated to 8 bytes.
#struct {
#  opaque version[1];
#  opaque WhisperMessage[...]; #see above
#  opaque mac[8]; #hmac(version||WhisperMessage) #but with what key?
# } TextSecure_WhisperMessage;

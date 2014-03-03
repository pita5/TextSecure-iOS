//
//  TSPrekeyWhisperMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSPrekeyWhisperMessage.hh"
#import "PreKeyWhisperMessage.pb.hh"
#import "TSEncryptedWhisperMessage.hh"
#import "TSECKeyPair.h"
#import "TSUserKeysDatabase.h"
#import "NSData+Base64.h"
@implementation TSPreKeyWhisperMessage

-(id)initWithPreKeyId:(NSNumber*)prekeyId  senderPrekey:(NSData*)prekey senderIdentityKey:(NSData*)identityKey message:(NSData*)messageContents withVersion:(NSData*)version{
    if(self=[super init]) {
        self.preKeyId = prekeyId;
        self.baseKey = prekey;
        self.identityKey = identityKey;
        self.message = messageContents;
        self.version = version;
    }
    return self;
}
-(id) initWithTextSecure_PreKeyWhisperMessage:(NSData*) data {
    /*
     struct {
     opaque version[1];
     opaque PreKeyWhisperMessage[...];
     } TextSecure_PreKeyWhisperMessage;

     # ProtocolBuffer
     message PreKeyWhisperMessage {
     optional uint32 preKeyId    = 1;
     optional bytes  baseKey     = 2;
     optional bytes  identityKey = 3;
     optional bytes  message     = 4;
     }
     
     */
    if(self = [super init]) {
        self.version = [data subdataWithRange:NSMakeRange(0, 1)];
        // c++
        textsecure::PreKeyWhisperMessage *prekeyWhisperMessage = [self deserializeProtocolBuffer:[data subdataWithRange:NSMakeRange(1, [data length]-1)]];
        uint32_t cppPreKeyId =  prekeyWhisperMessage->prekeyid();
        const std::string cppBaseKey = prekeyWhisperMessage->basekey();
        const std::string cppIdentityKey = prekeyWhisperMessage->identitykey();
        const std::string cppMessage = prekeyWhisperMessage->message();
        // c++->objective C
        self.preKeyId = [self cppUInt32ToNSNumber:cppPreKeyId];
        self.baseKey = [self cppStringToObjcData:cppBaseKey];
        self.identityKey = [self cppStringToObjcData:cppIdentityKey];
        self.message = [self cppStringToObjcData:cppMessage];
    }
    return self; // super is abstract class
}


-(const std::string) serializedProtocolBufferAsString {
    textsecure::PreKeyWhisperMessage *preKeyMessage = new textsecure::PreKeyWhisperMessage;
    // objective c->c++
    uint32_t cppPreKeyId =  [self objcNumberToCppUInt32:self.preKeyId];
    const std::string cppBaseKey = [self objcDataToCppString:self.baseKey];
    const std::string cppIdentityKey = [self objcDataToCppString:self.identityKey];
    const std::string cppMessage = [self objcDataToCppString:self.message];
    // c++->protocol buffer
    preKeyMessage->set_prekeyid(cppPreKeyId);
    preKeyMessage->set_basekey(cppBaseKey);
    preKeyMessage->set_identitykey(cppIdentityKey);
    preKeyMessage->set_message(cppMessage);
    std::string ps = preKeyMessage->SerializeAsString();
    return ps;
}

#pragma mark private methods
- (textsecure::PreKeyWhisperMessage *)deserializeProtocolBuffer:(NSData *)data {
    int len = [data length];
    char raw[len];
    textsecure::PreKeyWhisperMessage *messageSignal = new textsecure::PreKeyWhisperMessage;
    [data getBytes:raw length:len];
    messageSignal->ParseFromArray(raw, len);
    return messageSignal;
}




+(NSData*) constructFirstMessage:(NSData*)ciphertext theirPrekeyId:(NSNumber*) theirPrekeyId myCurrentEphemeral:(TSECKeyPair*) currentEphemeral myNextEphemeral:(TSECKeyPair*)myNextEphemeral  withVersion:(NSData*)version withMac:(NSData*)mac{
    
    TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc]
                                                          initWithEphemeralKey:[myNextEphemeral publicKey]
                                                          previousCounter:[NSNumber numberWithInt:0]
                                                          counter:[NSNumber numberWithInt:0]
                                                          encryptedMessage:ciphertext
                                                          withVersion:version withMac:mac];
    TSECKeyPair *identityKey = [TSUserKeysDatabase identityKey];
    
    TSPreKeyWhisperMessage *prekeyMessage = [[TSPreKeyWhisperMessage alloc]
                                             initWithPreKeyId:theirPrekeyId
                                             senderPrekey:[currentEphemeral publicKey]
                                             senderIdentityKey:[identityKey publicKey]
                                             message:[encryptedWhisperMessage serializedProtocolBuffer]];
    
    return [prekeyMessage serializedProtocolBuffer];
}

@end

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
#import "NSData+TSKeyVersion.h"
#import "NSData+Base64.h"

@interface TSPreKeyWhisperMessage ()

@property (nonatomic,strong) NSData *protocolData;
@property (nonatomic,strong) NSData* version;

@property (nonatomic,strong) NSNumber* preKeyId;
@property (nonatomic,strong) NSData* baseKey; // base Curve25519 key exchange ephemeral: A0 in axolotl
@property (nonatomic,strong) NSData* identityKey; //Curve25519 identity key of the sender: A in axolotl
@property (nonatomic,strong) NSData* message;


@end


@implementation TSPreKeyWhisperMessage
-(instancetype)initWithPreKeyId:(NSNumber*)prekeyId  senderPrekey:(NSData*)prekey senderIdentityKey:(NSData*)identityKey message:(NSData*)messageContents forVersion:(NSData*)vers{
    if(self=[super init]) {
        self.version = vers;
        self.preKeyId = prekeyId;
        self.baseKey = prekey;
        self.identityKey = identityKey;
        self.message = messageContents;
        self.protocolData = [self getTextSecure_PreKeyWhisperMessage];
    }
    return self;
}


-(instancetype) initWithTextSecureProtocolData:(NSData*) data {
    return [self initWithTextSecure_PreKeyWhisperMessage:data];
}

-(NSData*) getTextSecureProtocolData {
    return self.protocolData;
}


-(instancetype) initWithTextSecure_PreKeyWhisperMessage:(NSData*) data {
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
        // c++
        textsecure::PreKeyWhisperMessage *prekeyWhisperMessage = [self deserializeProtocolBuffer:[data subdataWithRange:NSMakeRange(1, [data length]-1)]];
        uint32_t cppPreKeyId =  prekeyWhisperMessage->prekeyid();
        const std::string cppBaseKey = prekeyWhisperMessage->basekey();
        const std::string cppIdentityKey = prekeyWhisperMessage->identitykey();
        const std::string cppMessage = prekeyWhisperMessage->message();

        // c++->objective C
        self.protocolData = data;
        self.version = [data subdataWithRange:NSMakeRange(0, 1)];
        self.preKeyId = [self cppUInt32ToNSNumber:cppPreKeyId];
        self.baseKey = [[self cppStringToObjcData:cppBaseKey] removeVersionByte];
        self.identityKey = [[self cppStringToObjcData:cppIdentityKey] removeVersionByte];
        self.message = [self cppStringToObjcData:cppMessage];
    }
    return self; // super is abstract class
}


-(const std::string) serializedProtocolBufferAsString {
    textsecure::PreKeyWhisperMessage *preKeyMessage = new textsecure::PreKeyWhisperMessage;
    // objective c->c++
    uint32_t cppPreKeyId =  [self objcNumberToCppUInt32:self.preKeyId];
    const std::string cppBaseKey = [self objcDataToCppString:[self.baseKey prependVersionByte]];
    const std::string cppIdentityKey = [self objcDataToCppString:[self.identityKey prependVersionByte]];
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



-(NSData*) getTextSecure_PreKeyWhisperMessage {
    NSMutableData *serialized = [NSMutableData data];
    [serialized appendData:self.version];
    [serialized appendData:[self serializedProtocolBuffer]];
    return serialized;
}


- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"PreKeyWhisperMessage:\n prekeyId: %@\n baseKey: %@\n identityKey: %@\n message: %@\n version: %@",self.preKeyId,self.baseKey,self.identityKey,self.message,self.version];
}

#pragma mark public static methods
+(TSPreKeyWhisperMessage *) constructFirstMessage:(NSData*)ciphertext theirPrekeyId:(NSNumber*) theirPrekeyId myCurrentEphemeral:(NSData*) currentEphemeral myNextEphemeral:(NSData*)myNextEphemeral  forVersion:(NSData*)version withHMACKey:(NSData*)hmac {
    NSLog(@"encryption sending: myCurrentEphemeral (A0): %@ \n myNextEphemeral (A1): %@",currentEphemeral,myNextEphemeral);
    
    TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc]
                                                          initWithEphemeralKey:myNextEphemeral
                                                          previousCounter:[NSNumber numberWithInt:0]
                                                          counter:[NSNumber numberWithInt:0]
                                                          encryptedMessage:ciphertext
                                                          forVersion:version
                                                          HMACKey:hmac];
    
    TSECKeyPair *identityKey = [TSUserKeysDatabase identityKey];
    
    TSPreKeyWhisperMessage *prekeyMessage = [[TSPreKeyWhisperMessage alloc]
                                             initWithPreKeyId:theirPrekeyId
                                             senderPrekey:currentEphemeral
                                             senderIdentityKey:[identityKey publicKey]
                                             message:[encryptedWhisperMessage getTextSecureProtocolData]
                                             forVersion:version];
    return prekeyMessage;
}

@end

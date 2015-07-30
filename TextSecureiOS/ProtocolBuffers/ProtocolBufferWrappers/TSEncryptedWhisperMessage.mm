//
//  TSWhisperMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSEncryptedWhisperMessage.hh"
#import "WhisperMessage.pb.hh"
#import "Cryptography.h"
#import "NSData+TSKeyVersion.h"


@interface TSEncryptedWhisperMessage ()

@property (nonatomic,strong) NSData* ephemeralKey;
@property (nonatomic,strong) NSNumber* counter;
@property (nonatomic,strong) NSNumber* previousCounter;
@property (nonatomic,strong) NSData* hmac;
@property (nonatomic,strong) NSData* message;
@property (nonatomic,strong) NSData* version;
@property (nonatomic,strong) NSData *protocolData;


@end


@implementation TSEncryptedWhisperMessage

-(instancetype) initWithEphemeralKey:(NSData*)ephemeral previousCounter:(NSNumber*)prevCounter counter:(NSNumber*)ctr encryptedPushMessageContent:(NSData*)ciphertext forVersion:(NSData*)version HMACKey:(NSData*)hmacKey{
    if(self = [super init]) {
        self.ephemeralKey = ephemeral;
        self.previousCounter = prevCounter;
        self.counter = ctr;
        self.message=ciphertext;
        self.version = version;
        self.hmac = [self hMacWithKey:hmacKey];
        self.protocolData = [self getTextSecure_WhisperMessage];
    }
    return self;
}


-(instancetype) initWithTextSecureProtocolData:(NSData*) data {
    return [self initWithTextSecure_WhisperMessage:data];
}

-(NSData*) getTextSecureProtocolData {
    return self.protocolData;
}

-(instancetype) initWithTextSecure_WhisperMessage:(NSData*) data {
    /* Protocol v2
     struct {
     opaque version[1];
     opaque WhisperMessage[...];
     opaque mac[8];
     } TextSecure_WhisperMessage;
     message WhisperMessage {
     optional bytes  ephemeralKey    = 1;
     optional uint32 counter         = 2;
     optional uint32 previousCounter = 3;
     optional bytes  ciphertext      = 4;
     }
     
     */
    if(self = [super init]) {
        // 1st extract out version and mac
        self.version = [data subdataWithRange:NSMakeRange(0, 1)];
        self.hmac = [data subdataWithRange:NSMakeRange([data length]-8, 8)];
        NSData* whisperMessageProtobuf = [data subdataWithRange:NSMakeRange(1, [data length] -8-1)];
        // c++
        textsecure::WhisperMessage *whisperMessage = [self deserializeProtocolBuffer:whisperMessageProtobuf];
        const std::string cppEphemeralKey =  whisperMessage->ephemeralkey();
        const uint32_t cppCounter = whisperMessage->counter();
        const uint32_t cppPreviousCounter = whisperMessage->previouscounter();
        const std::string cppMessage = whisperMessage->ciphertext();
        
        // c++->objective C
        self.protocolData = data;
        
        self.ephemeralKey = [[self cppStringToObjcData:cppEphemeralKey] removeVersionByte]; // this crashes on first receive from group send. this MUST be a protobuf + group issue in the context of a prekeywhispermessage. that's why it does work without groups, or if a session is already started.
        self.counter = [self cppUInt32ToNSNumber:cppCounter];
        self.previousCounter = [self cppUInt32ToNSNumber:cppPreviousCounter];
        self.message = [self cppStringToObjcData:cppMessage];
    }
    return self; // super is abstract class
}


-(NSData*) getTextSecure_WhisperMessage{
    
    NSMutableData *serialized = [NSMutableData data];
    [serialized appendData:self.version];
    [serialized appendData:[self serializedProtocolBuffer]];
    [serialized appendData:self.hmac];
    return serialized;
}


-(NSString*) debugDescription {
    return [NSString stringWithFormat:@"WhisperMessage:\n ephemeralKey: %@\n previousCounter: %@\n counter: %@\n message: %@\n version: %@\n hmac:%@\n",self.ephemeralKey,self.previousCounter,self.counter,self.message,self.version,self.hmac];
}


-(const std::string) serializedProtocolBufferAsString {
    textsecure::WhisperMessage *whisperMessage = new textsecure::WhisperMessage;
    // objective c->c++
    const std::string cppEphemeralKey = [self objcDataToCppString:[self.ephemeralKey prependVersionByte]];
    const uint32_t cppCounter = [self objcNumberToCppUInt32:self.counter];
    const uint32_t cppPreviousCounter = [self objcNumberToCppUInt32:self.previousCounter];
    const std::string cppMessage =  [self objcDataToCppString:self.message];
    
    
    // c++->protocol buffer
    whisperMessage->set_ephemeralkey(cppEphemeralKey);
    whisperMessage->set_counter(cppCounter);
    whisperMessage->set_previouscounter(cppPreviousCounter);
    whisperMessage->set_ciphertext(cppMessage);
    std::string ps = whisperMessage->SerializeAsString();
    
    return ps;
}

#pragma mark private methods
- (textsecure::WhisperMessage *)deserializeProtocolBuffer:(NSData *)data {
    int len = [data length];
    char raw[len];
    textsecure::WhisperMessage *messageSignal = new textsecure::WhisperMessage;
    [data getBytes:raw length:len];
    messageSignal->ParseFromArray(raw, len);

    return messageSignal;
}

- (BOOL)verifyHMAC:(NSData*)hmacKey{
    NSData *ourHmac = [self hMacWithKey:hmacKey];
    
    if ([ourHmac isEqualToData:self.hmac]) {
        return YES;
    }
    
    return NO;
}

- (NSData*)hMacWithKey:(NSData*)hmacKey{
    NSMutableData *hmacData = [NSMutableData data];
    [hmacData appendData:self.version];
    [hmacData appendData:[self serializedProtocolBuffer]];
    
    return [[self class] hmacWithKey:hmacKey data:hmacData];
}

+ (NSData*)hmacWithKey:(NSData*)macKey data:(NSData*)data{
    NSData *hash = [Cryptography computeSHA256HMAC:data withHMACKey:macKey];
    return [hash subdataWithRange:NSMakeRange(0, 8)];
}
@end

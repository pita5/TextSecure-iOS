//
//  TSWhisperMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSEncryptedWhisperMessage.hh"
#import "WhisperMessage.pb.hh"
@implementation TSEncryptedWhisperMessage
@synthesize ephemeralKey;
@synthesize counter;
@synthesize previousCounter;
@synthesize message;
@synthesize hmac;

-(id) initWithEphemeralKey:(NSData*)ephemeral previousCounter:(NSNumber*)prevCounter counter:(NSNumber*)ctr encryptedMessage:(NSData*)ciphertext forVersion:(NSData*)version withHMAC:(NSData*)mac{
    if(self = [super init]) {
        self.ephemeralKey = ephemeral;
        self.previousCounter = prevCounter;
        self.counter = ctr;
        self.message=ciphertext;
        self.version = version;
        self.hmac = mac;
    }
    return self;
}

-(id) initWithTextSecure_WhisperMessage:(NSData*) data {
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
        self.ephemeralKey = [self cppStringToObjcData:cppEphemeralKey];
        self.counter = [self cppUInt32ToNSNumber:cppCounter];
        self.previousCounter = [self cppUInt32ToNSNumber:cppPreviousCounter];
        self.message = [self cppStringToObjcData:cppMessage];
    }
    return self; // super is abstract class
}



-(NSData*) serializedTextSecureBuffer{
    NSMutableData *serialized = [NSMutableData data];
    [serialized appendData:[super serializedTextSecureBuffer:self.version]];
    [serialized appendData:self.hmac];
    return serialized;
}



-(const std::string) serializedProtocolBufferAsString {
    textsecure::WhisperMessage *whisperMessage = new textsecure::WhisperMessage;
    // objective c->c++
    const std::string cppEphemeralKey = [self objcDataToCppString:self.ephemeralKey];
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
    NSLog(@" Length when deserializing %lu",(unsigned long)[[self cppStringToObjcData:messageSignal->ephemeralkey()] length]);
    return messageSignal;
}

@end

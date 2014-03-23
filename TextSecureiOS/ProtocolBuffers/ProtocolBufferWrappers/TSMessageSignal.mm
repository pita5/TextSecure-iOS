//
//  TSMessageSignal.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessageSignal.h"

#import "TSEncryptedWhisperMessage.hh"
#import "TSPreKeyWhisperMessage.hh"
#import "IncomingPushMessageSignal.pb.hh"

@implementation TSMessageSignal

-(id) initWithData:(NSData*) data {

    if(self = [super init]) {
        // c++
        textsecure::IncomingPushMessageSignal *incomingPushMessageSignal = [self deserialize:data];
        const uint32_t cppType = incomingPushMessageSignal->type();
        const std::string cppSource = incomingPushMessageSignal->source();
        const uint32_t cppSourceDevice = incomingPushMessageSignal->sourcedevice();
        const uint64_t cppTimestamp = incomingPushMessageSignal->timestamp();
        const std::string cppMessage = incomingPushMessageSignal->message();
        // c++->objective C
        self.contentType = (TSWhisperMessageType)cppType;
        self.source = [self cppStringToObjc:cppSource];
        self.sourceDevice = [self cppUInt32ToNSNumber:cppSourceDevice];
        self.timestamp = [self cppDateToObjc:cppTimestamp];
        self.message = [self getWhisperMessageForData:[self cppStringToObjcData:cppMessage]];
    }
    return self;
}

-(const std::string) serializedProtocolBufferAsString {
    textsecure::IncomingPushMessageSignal *messageSignal = new textsecure::IncomingPushMessageSignal;
    // objective c->c++
    const textsecure::IncomingPushMessageSignal_Type cppType = (textsecure::IncomingPushMessageSignal_Type)self.contentType;
    const std::string cppSource = [self objcStringToCpp:self.source];
    const uint32_t cppSourceDevice = [self objcNumberToCppUInt32:self.sourceDevice];
    const uint64_t cppTimestamp = [self objcDateToCpp:self.timestamp];
    const std::string cppMessage = [self objcDataToCppString:[self.message getTextSecureProtocolData]];
    // c++->protocol buffer
    messageSignal->set_type(cppType);
    messageSignal->set_source(cppSource);
    messageSignal->set_sourcedevice(cppSourceDevice);
    messageSignal->set_timestamp(cppTimestamp);
    messageSignal->set_message(cppMessage);

    std::string ps = messageSignal->SerializeAsString();
    return ps;
}

#pragma mark private methods
- (textsecure::IncomingPushMessageSignal *)deserialize:(NSData *)data {
    int len = [data length];
    char raw[len];
    textsecure::IncomingPushMessageSignal *messageSignal = new textsecure::IncomingPushMessageSignal;
    [data getBytes:raw length:len];
    messageSignal->ParseFromArray(raw, len);
    return messageSignal;
}

-(TSWhisperMessage*) getWhisperMessageForData:(NSData*) data {
  switch (self.contentType) {
    case TSEncryptedWhisperMessageType:
          return [[TSEncryptedWhisperMessage alloc] initWithTextSecureProtocolData:data];
      break;
    case TSPreKeyWhisperMessageType:
          return [[TSPreKeyWhisperMessage alloc] initWithTextSecureProtocolData:data];
      break;
    default:
      return nil;
      break;
  }
}

@end

//
//  TSMessageSignal.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessageSignal.h"
#import "IncomingPushMessageSignal.pb.hh"
@implementation TSMessageSignal

-(id) initWithBuffer:(NSData*) buffer {
  textsecure::IncomingPushMessageSignal *incomingPushMessageSignal = [self getIncomingPushMessageSignalForData:buffer]
  const uint32_t cppType = incomingPushMessageSignal->type();
  const std::string cppSource = incomingPushMessageSignal->source();
  const uint64_t cppTimestamp = incomingPushMessageSignal->timestamp();
  const std::string cppMesssage = incomingPushMessageSignal->message();
  /* testing conversion to objective c objects */
  self.type = [NSNumber numberWithInteger:cppType];
  self.source = [NSString stringWithCString:cppSource.c_str() encoding:NSASCIIStringEncoding];
  self.timestamp = [NSNumber numberWithInteger:cppTimestamp];
  self.message = [self getWhisperMessageForData:[NSData dataWithBytes:cppMessage.c_str() length:cppMessage.size()]];
 
}

// private
- (textsecure::IncomingPushMessageSignal *)getIncomingPushMessageSignalForData:(NSData *)data {
    int len = [data length];
    char raw[len];
    textsecure::IncomingPushMessageSignal *incomingPushMessage = new textsecure::IncomingPushMessageSignal;
    [data getBytes:raw length:len];
    incomingPushMessage->ParseFromArray(raw, len);
    return incomingPushMessage;
}

-(TSWhisperMessage*) getWhisperMessageForData:(NSData*) data {
  switch (self.type) {
    case PrekeyWhisperMessage:
      
      break;
    case UnencryptedWhisperMessage:
      break;
    case WhisperMessage:
      break;
    default:
      break;
  }
}
@end

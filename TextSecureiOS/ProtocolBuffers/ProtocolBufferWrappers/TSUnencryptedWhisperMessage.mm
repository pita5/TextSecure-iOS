//
//  TSUnencryptedWhisperMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSUnencryptedWhisperMessage.hh"
#import "TSPushMessageContent.hh"
@implementation TSUnencryptedWhisperMessage
-(id) initWithData:(NSData*) buffer {
  if(self=[super init]) {
    self.message =  [[[TSPushMessageContent alloc] initWithData:buffer] serializedProtocolBuffer];
  }
  return self;
}

-(NSData*) serializedProtocolBuffer {
  return self.message;
}

// TODO: implement
// serializedProtocolBufferAsString

-(const std::string) serializedProtocolBufferAsString {
  return [[[TSPushMessageContent alloc] initWithData:self.message] serializedProtocolBufferAsString];
}

@end

//
//  TSPushMessageContent.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSPushMessageContent.hh"
#import "PushMessageContent.pb.hh"

@implementation TSPushMessageContent


-(id) initWithData:(NSData*) data {
  
  if(self = [super init]) {
    // c++
    textsecure::PushMessageContent *pushMessageContent = [self deserialize:data];
    const std::string cppMessage = pushMessageContent->body();

    // c++->objective C
    self.body = [self cppStringToObjc:cppMessage];
  
  }
  return self;
}


-(const std::string) serializedProtocolBufferAsString {
  textsecure::PushMessageContent *messageSignal = new textsecure::PushMessageContent;
  // objective c->c++
  const std::string cppMessage = [self objcStringToCpp:self.body];
  
  // c++->protocol buffer
  messageSignal->set_body(cppMessage);
  
  std::string ps = messageSignal->SerializeAsString();
  return ps;
}

- (textsecure::PushMessageContent *)deserialize:(NSData *)data {
  int len = [data length];
  char raw[len];
  textsecure::PushMessageContent *messageSignal = new textsecure::PushMessageContent;
  [data getBytes:raw length:len];
  messageSignal->ParseFromArray(raw, len);
  return messageSignal;
}

@end

//
//  IncomingPushMessageSignal.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "IncomingPushMessageSignal.h"
#import "IncomingPushMessageSignal.pb.h"

@implementation IncomingPushMessageSignal


-(id) init {
  // Testing things out
  if(self = [super init]) {
    // Creating message
    textsecure::IncomingPushMessageSignal *incomingPushMessage = new textsecure::IncomingPushMessageSignal;
    incomingPushMessage->set_type(0); // 0=plaintext,1=ciphertext,3=prekeybundle
    incomingPushMessage->set_allocated_source("+41000000000");
    //incomingPushMessage->set_destinations(<#int index#>, <#const ::std::string &value#>); //leaving empty, not a group message.
    incomingPushMessage->set_timestamp((uint64_t)[[NSDate date] timeIntervalSince1970]);
    incomingPushMessage->set_allocated_message("Hey, what's up. I'm using TextSecure.");
    // Printing message
    [self prettyPrint:incomingPushMessage];
    // Serializing message
    NSData* serializedIncomingPushMessage;
    
    // Deserializing message
    textsecure::IncomingPushMessageSignal *deserializedIncomingPushMessage = [self getIncomingPushMessageSignalForData:serializedIncomingPushMessage];
    // Printing deserialized message
    [self deserializedIncomingPushMessage prettyPrint:deserializedIncomingPushMessage];
  }
  return self;
}

// Serialize to NSData.
- (NSData *)getDataForIncomingPushMessageSignal:(textsecure::IncomingPushMessageSignal *)incomingPushMessage {
  std::string ps = incomingPushMessage->SerializeAsString();
  return [NSData dataWithBytes:ps.c_str() length:ps.size()];
}

// De-serialize from an NSData object.
- (textsecure::IncomingPushMessageSignal *)getIncomingPushMessageSignalForData:(NSData *)data {
  int len = [data length];
  char raw[len];
  textsecure::IncomingPushMessageSignal *incomingPushMessage = new textsecure::IncomingPushMessageSignal;
  [data getBytes:raw length:len];
  incomingPushMessage->ParseFromArray(raw, len);
  return incomingPushMessage;
}

// Dlog
- (void)prettyPrint:(textsecure::IncomingPushMessageSignal *)incomingPushMessage {
  
}
@end

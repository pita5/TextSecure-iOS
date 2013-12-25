//
//  IncomingPushMessageSignal.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "IncomingPushMessageSignal.hh"


@implementation IncomingPushMessageSignal



// Serialize IncomingPushMessageSignal to NSData.
+ (NSData *)getDataForIncomingPushMessageSignal:(textsecure::IncomingPushMessageSignal *)incomingPushMessage {
  std::string ps = incomingPushMessage->SerializeAsString();
  return [NSData dataWithBytes:ps.c_str() length:ps.size()];
}

// De-serialize IncomingPushMessageSignal from an NSData object.
+ (textsecure::IncomingPushMessageSignal *)getIncomingPushMessageSignalForData:(NSData *)data {
  int len = [data length];
  char raw[len];
  textsecure::IncomingPushMessageSignal *incomingPushMessage = new textsecure::IncomingPushMessageSignal;
  [data getBytes:raw length:len];
  incomingPushMessage->ParseFromArray(raw, len);
  return incomingPushMessage;
}

// Serialize PushMessageContent to NSData.
+ (NSData *)getDataForPushMessageContent:(textsecure::PushMessageContent *)pushMessageContent {
  std::string ps = pushMessageContent->SerializeAsString();
  return [NSData dataWithBytes:ps.c_str() length:ps.size()];
}


// De-serialize PushMessageContent from an NSData object.
+ (textsecure::PushMessageContent *)getPushMessageContentForData:(NSData *)data {
  int len = [data length];
  char raw[len];
  textsecure::PushMessageContent *pushMessageContent = new textsecure::PushMessageContent;
  [data getBytes:raw length:len];
  pushMessageContent->ParseFromArray(raw, len);
  return pushMessageContent;
}

// Create PushMessageContent from it's Objective C contents
+ (NSData *)createSerializedPushMessageContent:(NSString*) message withAttachments:(NSArray*) attachments {
#warning no attachments suppoart yet
  textsecure::PushMessageContent *pushMessageContent = new textsecure::PushMessageContent();
  const std::string body([message cStringUsingEncoding:NSASCIIStringEncoding]);
  pushMessageContent->set_body(body);
  NSData *serializedPushMessageContent = [IncomingPushMessageSignal getDataForPushMessageContent:pushMessageContent];
  delete pushMessageContent;
  return serializedPushMessageContent;
}


+ (NSString*) getMessageBody:(textsecure::IncomingPushMessageSignal *)incomingPushMessageSignal {
  const std::string cppMessage = incomingPushMessageSignal->message();
  NSData *messageData =[NSData dataWithBytes:cppMessage.c_str() length:cppMessage.size()];
  textsecure::PushMessageContent *messageContent = [IncomingPushMessageSignal getPushMessageContentForData:messageData];
  return [IncomingPushMessageSignal prettyPrintPushMessageContent:messageContent];
}

+ (NSString*)prettyPrint:(textsecure::IncomingPushMessageSignal *)incomingPushMessageSignal {
  /*
   Type
   Allowed source
   Destinations
   Timestamp
   Allocated Message
   */
  
  const uint32_t cppType = incomingPushMessageSignal->type();
  const std::string cppSource = incomingPushMessageSignal->source();
  const uint64_t cppTimestamp = incomingPushMessageSignal->timestamp();
  /* testing conversion to objective c objects */
  NSNumber* type = [NSNumber numberWithInteger:cppType];
  NSString* source = [NSString stringWithCString:cppSource.c_str() encoding:NSASCIIStringEncoding];
  NSNumber* timestamp = [NSNumber numberWithInteger:cppTimestamp];
  
  NSString* message = [IncomingPushMessageSignal getMessageBody:incomingPushMessageSignal];
  NSString *fullInfo = [NSString stringWithFormat:@"Type: %@ \n source: %@ \n message: %@",
                        type,source,message];
  return fullInfo;
}
// Dlog
+ (NSString*)prettyPrintPushMessageContent:(textsecure::PushMessageContent *)pushMessageContent {
  const std::string cppBody = pushMessageContent->body();
  NSString* body = [NSString stringWithCString:cppBody.c_str() encoding:NSASCIIStringEncoding];
  NSLog(@"recieved message %@",body);
  return  body;
#warning doesn't handle attachments yet
  
}

@end

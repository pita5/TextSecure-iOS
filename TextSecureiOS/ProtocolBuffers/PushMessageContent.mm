//
//  PushMessageContent.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "PushMessageContent.hh"
#import "IncomingPushMessageSignal.pb.hh"
#import "TSThread.h"
@implementation PushMessageContent

// Dlog
+ (NSString*)prettyPrintPushMessageContent:(textsecure::PushMessageContent *)pushMessageContent {
  const std::string cppBody = pushMessageContent->body();
  NSString* body = [NSString stringWithCString:cppBody.c_str() encoding:NSASCIIStringEncoding];
  return  body;
#warning doesn't handle attachments yet
  
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
  
  NSData *serializedPushMessageContent = [PushMessageContent getDataForPushMessageContent:pushMessageContent];
  delete pushMessageContent;
  return serializedPushMessageContent;
}

+ (NSString*) getMessageBody:(textsecure::IncomingPushMessageSignal *)incomingPushMessageSignal {
  const std::string cppMessage = incomingPushMessageSignal->message();
  NSData *messageData =[NSData dataWithBytes:cppMessage.c_str() length:cppMessage.size()];
  textsecure::PushMessageContent *messageContent = [PushMessageContent getPushMessageContentForData:messageData];
  return [PushMessageContent prettyPrintPushMessageContent:messageContent];
}





@end

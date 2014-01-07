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


+(TSMessage*)getTSMessage:(textsecure::PushMessageContent *)pushMessageContent forIncomingPushMessageSignal:(textsecure::IncomingPushMessageSignal *)incomingPushMessageSignal onThread:(TSThread*)thread {
  const uint32_t cppType = incomingPushMessageSignal->type();
  const std::string cppSource = incomingPushMessageSignal->source();
  const uint64_t cppTimestamp = incomingPushMessageSignal->timestamp();
  /* testing conversion to objective c objects */
  NSNumber* type = [NSNumber numberWithInteger:cppType];
  NSString* source = [NSString stringWithCString:cppSource.c_str() encoding:NSASCIIStringEncoding];
  
  NSNumber* timestamp = [NSNumber numberWithInteger:cppTimestamp];
  //[[NSDate alloc] initWithTimeIntervalSince1970:[timestamp longLongValue]]
  NSString* message = [IncomingPushMessageSignal getMessageBody:incomingPushMessageSignal];
#warning ignoring timestamp sent, setting to now, fix issue with timestamp received being incorrectly interpreted (a few years off). currently behavior is when received.
  // this phone is the recipient of the message
  TSMessage *tsMessage = [[TSMessage alloc] initWithMessage:message sender:source recipients:[[NSArray alloc] initWithObjects:[TSKeyManager getUsernameToken], nil] sentOnDate:[NSDate date]];
  return tsMessage;
}


@end

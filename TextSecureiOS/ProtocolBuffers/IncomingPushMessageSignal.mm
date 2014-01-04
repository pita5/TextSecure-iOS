//
//  IncomingPushMessageSignal.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "IncomingPushMessageSignal.hh"
#import "TSMessage.h"
#import "TSAttachment.h"
#import "NSData+Base64.h"
#include <stdlib.h>

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

// Serialize TSAttachment to AttachmentPointer

// De-Serialize AttachmentPointer to TSAttachment

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
+ (NSData *)createSerializedPushMessageContent:(TSMessage*) message  {
#warning no attachments suppoart yet
  textsecure::PushMessageContent *pushMessageContent = new textsecure::PushMessageContent();
  const std::string body([message.message cStringUsingEncoding:NSASCIIStringEncoding]);

  pushMessageContent->set_body(body);
  if([message.attachment readyForUpload]) {
    textsecure::PushMessageContent_AttachmentPointer *attachmentPointer = pushMessageContent->add_attachments();
#warning attachment_id
    const std::string cppAttachmentId([message.attachment.attachmentId cStringUsingEncoding:NSASCIIStringEncoding]);
 
    //const uint64_t attachment_id = [message.attachment.attachmentId integerValue]; // this is incorrect
    size_t idx;
    const uint64_t attachment_id =  stoull(cppAttachmentId,&idx,10);
    
    attachmentPointer->set_id(attachment_id);
    const std::string attachment_encryption_key([[message.attachment.attachmentDecryptionKey base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength] cStringUsingEncoding:NSASCIIStringEncoding]);
    attachmentPointer->set_key(attachment_encryption_key);
    std::string attachment_contenttype([[message.attachment getMIMEContentType]  cStringUsingEncoding:NSASCIIStringEncoding]);
    attachmentPointer->set_contenttype(attachment_contenttype);
  }
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

+ (TSAttachment*) getMessageAttachmentData:(textsecure::IncomingPushMessageSignal *)incomingPushMessageSignal {
  const std::string cppMessage = incomingPushMessageSignal->message();
  NSData *messageData =[NSData dataWithBytes:cppMessage.c_str() length:cppMessage.size()];
  textsecure::PushMessageContent *messageContent = [IncomingPushMessageSignal getPushMessageContentForData:messageData];
  if(messageContent->attachments_size()>0) {
    const textsecure::PushMessageContent_AttachmentPointer *attachmentPointer = messageContent->mutable_attachments(0);

    const std::string cppContentType = attachmentPointer->contenttype();
    NSString *contentType = [NSString stringWithCString:cppContentType.c_str() encoding:NSASCIIStringEncoding];
    const std::string cppKey = attachmentPointer->key();
    NSData *decryptionKey = [NSData dataFromBase64String:[NSString stringWithCString:cppKey.c_str() encoding:NSASCIIStringEncoding]];
    const uint64_t cppId = attachmentPointer->id();
    NSString *attachmentId = [NSString stringWithFormat:@"%" PRIu64 @"\n",cppId];
//    NSData *attachmentData = [NSData dataWithBytes:attachmentPointer-> length:<#(NSUInteger)#>]
    
//   return [[TSAttachment alloc] initWithAttachmentData:<#(NSData *)#> withType:<#(TSAttachmentType)#> withThumbnailImage:<#(UIImage *)#>]'
    return nil;
  }
  else {
    return nil;
  }

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
  return  body;
#warning doesn't handle attachments yet
  
}

+(TSMessage*)getTSMessageForIncomingPushMessageSignal:(textsecure::IncomingPushMessageSignal *)incomingPushMessageSignal {
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
//  TSAttachment *tsAttachment = [IncomingPushMessageSignal getMessageAttachmentData:incomingPushMessageSignal]; // not implemented
  // this phone is the recipient of the message
  TSMessage *tsMessage = [[TSMessage alloc] initWithMessage:message sender:source recipients:[[NSArray alloc] initWithObjects:[TSKeyManager getUsernameToken], nil] sentOnDate:[NSDate date] attachment:nil];
  return tsMessage;
}

@end

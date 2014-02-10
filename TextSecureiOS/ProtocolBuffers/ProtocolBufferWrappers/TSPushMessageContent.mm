//
//  TSPushMessageContent.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSPushMessageContent.hh"
#import "PushMessageContent.pb.hh"
#import "TSMessage.h"
#import "TSAttachment.h"
@implementation TSPushMessageContent


-(id) initWithData:(NSData*) data {
  
  if(self = [super init]) {
    // c++
    textsecure::PushMessageContent *pushMessageContent = [self deserialize:data];
    const std::string cppMessage = pushMessageContent->body();
    
    NSMutableArray *messageAttachments= [[NSMutableArray alloc] init];
    for(int i=0; i<pushMessageContent->attachments_size();i++) {

      const textsecure::PushMessageContent_AttachmentPointer *attachmentPointer = pushMessageContent->mutable_attachments(i);
      // c++
      const std::string cppContentType = attachmentPointer->contenttype();
      const std::string cppKey = attachmentPointer->key();
      const uint64_t cppId = attachmentPointer->id();
      // Objc
      NSString *contentType = [self cppStringToObjc:cppContentType];
      NSData *decryptionKey = [self cppStringToObjcData:cppKey];
      NSNumber *attachmentId = [self cppUInt64ToNSNumber:cppId];
      TSAttachment *tsAttachment = [[TSAttachment alloc] initWithAttachmentId:attachmentId contentMIMEType:contentType decryptionKey:decryptionKey];
      [messageAttachments addObject:tsAttachment];
    }
    // c++->objective C
    self.body = [self cppStringToObjc:cppMessage];
    self.attachments = messageAttachments;
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


+ (NSData *)serializedPushMessageContent:(TSMessage*) message  {
  TSPushMessageContent* tsPushMessageContent = [[TSPushMessageContent alloc] init];
  tsPushMessageContent.body = message.message;
  tsPushMessageContent.attachments = @[message.attachment];
  textsecure::PushMessageContent *pushMessageContent = new textsecure::PushMessageContent();
  pushMessageContent->set_body([tsPushMessageContent objcStringToCpp:tsPushMessageContent.body]);

  for(TSAttachment* attachment in tsPushMessageContent.attachments) {
    textsecure::PushMessageContent_AttachmentPointer *attachmentPointer = pushMessageContent->add_attachments();
    const uint64_t attachment_id =  [tsPushMessageContent objcNumberToCppUInt64:attachment.attachmentId];
    const std::string attachment_encryption_key = [tsPushMessageContent objcDataToCppString:attachment.attachmentDecryptionKey];
    std::string attachment_contenttype = [tsPushMessageContent objcStringToCpp:[attachment getMIMEContentType]];
    attachmentPointer->set_id(attachment_id);
    attachmentPointer->set_key(attachment_encryption_key);
    attachmentPointer->set_contenttype(attachment_contenttype);
  }
  
  return [tsPushMessageContent serializedProtocolBuffer];
}


@end

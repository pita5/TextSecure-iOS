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

-(instancetype) initWithTextSecureProtocolData:(NSData*) data {
    return [self initWithData:data];
}
-(NSData*) getTextSecureProtocolData {
    return [self serializedProtocolBuffer];
}


-(instancetype) initWithData:(NSData*) data {
  
    if(self = [super init]) {
        // c++
        textsecure::PushMessageContent *pushMessageContent = [self deserialize:data];
        const std::string cppMessage = pushMessageContent->body();
        const uint32_t cppFlags = pushMessageContent->flags();
        if(pushMessageContent->has_group()) {
            
            const textsecure::PushMessageContent_GroupContext groupContext = pushMessageContent->group();
            // c++ assumed
            const std::string cppGroupId = groupContext.id();
            const textsecure::PushMessageContent_GroupContext_Type cppGroupType = groupContext.type();
            NSMutableArray *groupMembers = [[NSMutableArray alloc] init];
            for(int i=0; i < groupContext.members_size(); i++) {
                const std::string cppMember = groupContext.members(i);
                [groupMembers addObject:[self cppStringToObjc:cppMember]];
            }
            NSData* groupId = [self cppStringToObjcData:cppGroupId];
            TSGroupContextType groupType = (TSGroupContextType) cppGroupType;
            
            // c++ optional
            NSString* groupName = nil;
            TSAttachment *groupAvatar = nil;
            if(groupContext.has_name()) {
                const std::string cppName = groupContext.name();
                groupName = [self cppStringToObjc:cppName];
            }
            if(groupContext.has_avatar()) {
                const textsecure::PushMessageContent_AttachmentPointer attachmentPointer = groupContext.avatar();
                // c++
                const std::string cppContentType = attachmentPointer.contenttype();
                const std::string cppKey = attachmentPointer.key();
                const uint64_t cppId = attachmentPointer.id();
                // Objc
                NSString *contentType = [self cppStringToObjc:cppContentType];
                NSData *decryptionKey = [self cppStringToObjcData:cppKey];
                NSNumber *attachmentId = [self cppUInt64ToNSNumber:cppId];
                groupAvatar = [[TSAttachment alloc] initWithAttachmentId:attachmentId contentMIMEType:contentType decryptionKey:decryptionKey];

            }
            self.groupContext = [[TSGroupContext alloc] initWithId:groupId withType:groupType withName:groupName withMembers:groupMembers withAvatar:groupAvatar];
        }
          
          
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
        self.messageFlags = (TSPushMessageFlags)cppFlags;
    }
    return self;
}


-(const std::string) serializedProtocolBufferAsString {
  textsecure::PushMessageContent *pushMessageContent = new textsecure::PushMessageContent;
  // objective c->c++
  const std::string cppMessage = [self objcStringToCpp:self.body];
  // c++->protocol buffer
  pushMessageContent->set_body(cppMessage);
  for(TSAttachment* attachment in self.attachments) {
    textsecure::PushMessageContent_AttachmentPointer *attachmentPointer = pushMessageContent->add_attachments();
    const uint64_t attachment_id =  [self objcNumberToCppUInt64:attachment.attachmentId];
    const std::string attachment_encryption_key = [self objcDataToCppString:attachment.attachmentDecryptionKey];
    std::string attachment_contenttype = [self objcStringToCpp:[attachment getMIMEContentType]];
    attachmentPointer->set_id(attachment_id);
    attachmentPointer->set_key(attachment_encryption_key);
    attachmentPointer->set_contenttype(attachment_contenttype);
      
  }
    
  if(self.groupContext!=nil) {
    textsecure::PushMessageContent_GroupContext *serializedGroupContext = new textsecure::PushMessageContent_GroupContext;
    serializedGroupContext->set_id([self objcDataToCppString:self.groupContext.gid]);
    serializedGroupContext->set_type((textsecure::PushMessageContent_GroupContext_Type)self.groupContext.type);
    serializedGroupContext->set_name([self objcStringToCpp:self.groupContext.name]);
    for(NSString* member  in self.groupContext.members) {
        serializedGroupContext->add_members([self objcStringToCpp:member]);
    }
    
    if(self.groupContext.avatar!=nil) {
      textsecure::PushMessageContent_AttachmentPointer *avatar = new textsecure::PushMessageContent_AttachmentPointer;
      const uint64_t attachment_id =  [self objcNumberToCppUInt64:self.groupContext.avatar.attachmentId];
      const std::string attachment_encryption_key = [self objcDataToCppString:self.groupContext.avatar.attachmentDecryptionKey];
      std::string attachment_contenttype = [self objcStringToCpp:[self.groupContext.avatar getMIMEContentType]];
      avatar->set_id(attachment_id);
      avatar->set_key(attachment_encryption_key);
      avatar->set_contenttype(attachment_contenttype);
      serializedGroupContext->set_allocated_avatar(avatar);
    }
    pushMessageContent->set_allocated_group(serializedGroupContext);
    
  }
  if(self.messageFlags) {
    pushMessageContent->set_flags(self.messageFlags);
  }
  std::string ps = pushMessageContent->SerializeAsString();
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


+ (NSData *)serializedPushMessageContentForMessage:(TSMessage*) message  withGroupContect:(TSGroupContext*)groupContext{
  TSPushMessageContent* tsPushMessageContent = [[TSPushMessageContent alloc] init];
  tsPushMessageContent.body = message.content;
  tsPushMessageContent.attachments = message.attachments;
  tsPushMessageContent.groupContext = groupContext;
  return [tsPushMessageContent getTextSecureProtocolData];
}


@end

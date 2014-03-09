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


//message PushMessageContent {
//    message AttachmentPointer {
//        optional fixed64 id          = 1;
//        optional string  contentType = 2;
//        optional bytes   key         = 3;
//    }
//    
//    message GroupContext {
//        enum Type {
//            UNKNOWN = 0;
//            UPDATE  = 1;
//            DELIVER = 2;
//            QUIT    = 3;
//        }
//        optional bytes             id      = 1;
//        optional Type              type    = 2;
//        optional string            name    = 3;
//        repeated string            members = 4;
//        optional AttachmentPointer avatar  = 5;
//    }
//    
//    enum Flags {
//        END_SESSION = 1;
//    }
//    
//    optional string            body        = 1;
//    repeated AttachmentPointer attachments = 2;
//    optional GroupContext      group       = 3;
//    optional uint32            flags       = 4;
//}

-(id) initWithData:(NSData*) data {
  
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
  tsPushMessageContent.body = message.content;
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

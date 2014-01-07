//
//  PushMessageContent.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PushMessageContent.pb.hh"
@interface PushMessageContent : NSObject
+ (textsecure::PushMessageContent *)getPushMessageContentForData:(NSData *)data;
+ (NSString*)prettyPrintPushMessageContent:(textsecure::PushMessageContent *)pushMessageContent;
+ (NSData *)createSerializedPushMessageContent:(NSString*) message withAttachments:(NSArray*) attachments;

@end

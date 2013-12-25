//
//  IncomingPushMessageSignal.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.

// NOTE THAT ANY FILE WHICH INCLUDES THIS IS THEREBY OBJECTIVE-C++
// That means to compile correctly, it needs an .hh/.mm extension

#import <Foundation/Foundation.h>
#import "IncomingPushMessageSignal.pb.hh"

@interface IncomingPushMessageSignal : NSObject
+ (NSData *)getDataForIncomingPushMessageSignal:(textsecure::IncomingPushMessageSignal *)incomingPushMessage;
+ (textsecure::IncomingPushMessageSignal *)getIncomingPushMessageSignalForData:(NSData *)data;
+ (textsecure::PushMessageContent *)getPushMessageContentForData:(NSData *)data;
+ (NSString*)prettyPrint:(textsecure::IncomingPushMessageSignal *)incomingPushMessageSignal;
+ (NSString*)prettyPrintPushMessageContent:(textsecure::PushMessageContent *)pushMessageContent;
+ (NSData *)createSerializedPushMessageContent:(NSString*) message withAttachments:(NSArray*) attachments;
+ (NSString*) getMessageBody:(textsecure::IncomingPushMessageSignal *)incomingPushMessageSignal;
@end

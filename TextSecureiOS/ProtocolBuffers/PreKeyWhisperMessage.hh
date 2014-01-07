//
//  PreKeyWhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreKeyWhisperMessage.pb.hh"
#import "TSPreKeyWhisperMessage.h"

@interface PreKeyWhisperMessage : NSObject
// Serialize PreKeyWhisperMessage to NSData.
+ (NSData *)getDataForPreKeyWhisperMessage:(textsecure::PreKeyWhisperMessage *)incomingPushMessage;
+ (textsecure::PreKeyWhisperMessage *)getPreKeyWhisperMessageForData:(NSData *)data;

// Convert between protocol buffers and TSPreKeyWhisperMessage
+ (NSData *)createSerializedPreKeyWhisperMessage:(TSPreKeyWhisperMessage*)message;
+(TSPreKeyWhisperMessage*)getTSPreKeyWhisperMessageForPreKeyWhisperMessage:(textsecure::PreKeyWhisperMessage *)whisperMessage;

@end

//
//  WhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WhisperMessage.pb.hh"
#import "TSWhisperMessage.h"
@interface WhisperMessage : NSObject
// Serialize WhisperMessage to NSData.
+ (NSData *)getDataForWhisperMessage:(textsecure::WhisperMessage *)incomingPushMessage;
+ (textsecure::WhisperMessage *)getWhisperMessageForData:(NSData *)data;

// Convert between protocol buffers and TSWhisperMessage
+ (NSData *)createSerializedWhisperMessage:(TSWhisperMessage*) message;
+(TSWhisperMessage*)getTSWhisperMessageForWhisperMessage:(textsecure::WhisperMessage *)whisperMessage;
@end
